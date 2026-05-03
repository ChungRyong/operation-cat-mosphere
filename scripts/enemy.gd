extends PathFollow2D

signal died(enemy: Node, reward: int)
signal reached_end(damage: float)

@export var data: EnemyData

const MELEE_DAMAGE: float = 3.0
const MELEE_INTERVAL: float = 1.5

var current_health: float = 0.0
var _stun_timer: float = 0.0
var _distract_active: bool = false
var _engaged: bool = false
var _melee_timer: float = 0.0


func _ready() -> void:
	rotates = false
	loop = false
	if data == null:
		return
	current_health = data.max_health
	queue_redraw()


func _process(delta: float) -> void:
	if data == null:
		return
	if _stun_timer > 0.0:
		_stun_timer -= delta
		return
	if _update_engagement(delta):
		return
	var effective_speed: float = data.speed * 60.0
	progress += effective_speed * delta
	if progress_ratio >= 1.0:
		reached_end.emit(10.0)
		queue_free()


func take_damage(amount: float, attack_type: TowerData.AttackType) -> void:
	if data == null:
		return
	var is_crit: bool = false
	var final_dmg: float = DamageCalculator.calculate(amount, attack_type, data.defense_type, is_crit)
	if final_dmg <= 0.0:
		return
	current_health -= final_dmg
	queue_redraw()
	if current_health <= 0.0:
		_on_die()


func apply_stun(duration: float) -> void:
	if duration > _stun_timer:
		_stun_timer = duration


func is_gimmick_distractor() -> bool:
	return data != null and data.enemy_class == EnemyData.EnemyClass.GIMMICK


func _on_die() -> void:
	_cleanup_engagement()
	if data.spawn_on_death != null and data.spawn_count > 0:
		_spawn_children()
	ResourceManager.add_essence(data.essence_reward)
	died.emit(self, data.essence_reward)
	queue_free()


func _spawn_children() -> void:
	var parent_path: Path2D = get_parent() as Path2D
	if parent_path == null:
		return
	for i in data.spawn_count:
		var child: PathFollow2D = load("res://scenes/enemy/enemy.tscn").instantiate()
		child.data = data.spawn_on_death
		child.progress = progress + randf_range(-20.0, 20.0)
		parent_path.add_child(child)
		child.add_to_group("enemies")
		if child.has_signal("died"):
			child.died.connect(get_tree().current_scene._on_enemy_died)
		if child.has_signal("reached_end"):
			child.reached_end.connect(get_tree().current_scene._on_enemy_reached_end)


func _draw() -> void:
	if data == null:
		return
	if data.texture != null:
		var tex_size: Vector2 = data.texture.get_size()
		var scale_factor: float = (data.radius * 2.0) / max(tex_size.x, tex_size.y)
		var draw_size: Vector2 = tex_size * scale_factor
		draw_texture_rect(data.texture, Rect2(-draw_size * 0.5, draw_size), false)
	else:
		draw_circle(Vector2.ZERO, data.radius, data.color)
	if _stun_timer > 0.0:
		draw_circle(Vector2.ZERO, data.radius + 2, Color(1.0, 1.0, 0.0, 0.3))
	if _engaged:
		draw_arc(Vector2.ZERO, data.radius + 4.0, 0.0, TAU, 16, Color(1.0, 0.3, 0.2, 0.5), 2.0)
	var bar_width: float = data.radius * 2.2
	var bar_height: float = 4.0
	var bar_pos: Vector2 = Vector2(-bar_width * 0.5, -data.radius - 10.0)
	draw_rect(Rect2(bar_pos, Vector2(bar_width, bar_height)), Color(0.2, 0.0, 0.0, 1.0))
	var ratio: float = clamp(current_health / data.max_health, 0.0, 1.0)
	draw_rect(Rect2(bar_pos, Vector2(bar_width * ratio, bar_height)), Color(0.2, 0.9, 0.2, 1.0))


func _update_engagement(delta: float) -> bool:
	var hero_node: CharacterBody2D = _get_hero()
	if hero_node == null:
		if _engaged:
			_engaged = false
			_melee_timer = 0.0
			queue_redraw()
		return false

	var dist: float = global_position.distance_to(hero_node.global_position)

	if _engaged:
		if hero_node.current_hp <= 0.0 or dist > hero_node.DISENGAGE_RANGE:
			_engaged = false
			_melee_timer = 0.0
			hero_node.remove_blocked()
			queue_redraw()
			return false
		_melee_timer -= delta
		if _melee_timer <= 0.0:
			_melee_timer = MELEE_INTERVAL
			hero_node.take_damage(MELEE_DAMAGE)
		return true
	else:
		if dist <= hero_node.BLOCK_RANGE and hero_node.can_block():
			_engaged = true
			_melee_timer = MELEE_INTERVAL
			hero_node.add_blocked()
			queue_redraw()
			return true
		return false


func _get_hero() -> CharacterBody2D:
	var heroes: Array = get_tree().get_nodes_in_group("hero")
	if heroes.is_empty():
		return null
	return heroes[0] as CharacterBody2D


func _cleanup_engagement() -> void:
	if _engaged:
		_engaged = false
		var hero_node: CharacterBody2D = _get_hero()
		if hero_node != null:
			hero_node.remove_blocked()


func _exit_tree() -> void:
	_cleanup_engagement()
