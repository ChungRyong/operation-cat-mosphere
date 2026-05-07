extends PathFollow2D

signal died(enemy: Node, reward: int)
signal reached_end(damage: float)

@export var data: EnemyData

const MELEE_DAMAGE: float = 3.0
const MELEE_INTERVAL: float = 1.5
const TOWER_ATTACK_RANGE: float = 80.0
const TOWER_ATTACK_INTERVAL: float = 2.0
const DISTRACT_RANGE: float = 200.0

var current_health: float = 0.0
var _stun_timer: float = 0.0
var _distract_active: bool = false
var _engaged: bool = false
var _melee_timer: float = 0.0
var _tower_target: Node2D = null
var _tower_atk_timer: float = 0.0
var _tower_attack_flash: float = 0.0
var _returning: bool = false
var _idle_scale: Vector2 = Vector2.ONE
var _idle_tween: Tween


func _ready() -> void:
	rotates = false
	loop = false
	if data == null:
		return
	current_health = data.max_health
	if data.texture != null:
		_start_idle_animation()
	queue_redraw()


func init_pooled(enemy_data: EnemyData) -> void:
	data = enemy_data
	current_health = enemy_data.max_health
	_stun_timer = 0.0
	_distract_active = false
	_engaged = false
	_melee_timer = 0.0
	_tower_target = null
	_tower_atk_timer = 0.0
	_tower_attack_flash = 0.0
	_returning = false
	_idle_scale = Vector2.ONE
	progress = 0.0
	set_process(true)
	if data.texture != null:
		_start_idle_animation()


func _cleanup_for_pool() -> void:
	_stop_idle_animation()
	_cleanup_engagement()
	for conn in died.get_connections():
		died.disconnect(conn["callable"])
	for conn in reached_end.get_connections():
		reached_end.disconnect(conn["callable"])


func _return_to_pool() -> void:
	if _returning:
		return
	_returning = true
	EnemyPool.return_enemy(self)


func _process(delta: float) -> void:
	if data == null:
		return
	if _idle_tween and _idle_tween.is_valid():
		queue_redraw()
	if _stun_timer > 0.0:
		_stun_timer -= delta
		return
	if _update_tower_attack(delta):
		return
	if _update_engagement(delta):
		return
	if data.enemy_class == EnemyData.EnemyClass.GIMMICK:
		_update_distract()
	var effective_speed: float = data.speed * 60.0
	progress += effective_speed * delta
	if progress_ratio >= 1.0:
		reached_end.emit(10.0)
		_return_to_pool()


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
		SfxManager.play("enemy_die")
		_on_die()


func apply_stun(duration: float) -> void:
	if duration > _stun_timer:
		_stun_timer = duration


func is_gimmick_distractor() -> bool:
	return data != null and data.enemy_class == EnemyData.EnemyClass.GIMMICK


func _on_die() -> void:
	VFX.spawn(get_tree().current_scene, global_position, VFX.Type.EXPLOSION, data.color)
	if data.spawn_on_death != null and data.spawn_count > 0:
		_spawn_children()
	ResourceManager.add_essence(data.essence_reward)
	died.emit(self, data.essence_reward)
	_return_to_pool()


func _spawn_children() -> void:
	var parent_path: Path2D = get_parent() as Path2D
	if parent_path == null:
		return
	for i in data.spawn_count:
		var child: PathFollow2D = EnemyPool.get_enemy()
		child.init_pooled(data.spawn_on_death)
		parent_path.add_child(child)
		child.progress = progress + randf_range(-20.0, 20.0)
		child.add_to_group("enemies")
		child.died.connect(get_tree().current_scene._on_enemy_died)
		child.reached_end.connect(get_tree().current_scene._on_enemy_reached_end)
		child.queue_redraw()


func _draw() -> void:
	if data == null:
		return
	if data.texture != null:
		var tex_size: Vector2 = data.texture.get_size()
		var scale_factor: float = (data.radius * 2.0) / max(tex_size.x, tex_size.y)
		var base_size: Vector2 = tex_size * scale_factor
		var draw_size: Vector2 = base_size * _idle_scale
		var anchor_y: float = base_size.y * (1.0 - _idle_scale.y) * 0.5
		draw_texture_rect(data.texture, Rect2(Vector2(-draw_size.x * 0.5, -draw_size.y * 0.5 + anchor_y), draw_size), false)
	else:
		draw_circle(Vector2.ZERO, data.radius, data.color)
	if _stun_timer > 0.0:
		draw_circle(Vector2.ZERO, data.radius + 2, Color(1.0, 1.0, 0.0, 0.3))
	if _engaged:
		draw_arc(Vector2.ZERO, data.radius + 4.0, 0.0, TAU, 16, Color(1.0, 0.3, 0.2, 0.5), 2.0)
	if data.attacks_towers and _tower_target != null and is_instance_valid(_tower_target):
		draw_arc(Vector2.ZERO, data.radius + 4.0, 0.0, TAU, 16, Color(0.8, 0.5, 0.1, 0.5), 2.0)
		if _tower_attack_flash > 0.0:
			var to_tower: Vector2 = _tower_target.global_position - global_position
			var flash_alpha: float = _tower_attack_flash / 0.25
			draw_line(Vector2.ZERO, to_tower, Color(1.0, 0.4, 0.1, flash_alpha * 0.8), 2.0)
			draw_circle(to_tower, 8.0 * flash_alpha, Color(1.0, 0.6, 0.2, flash_alpha * 0.5))
	var bar_width: float = data.radius * 2.2
	var bar_height: float = 4.0
	var bar_pos: Vector2 = Vector2(-bar_width * 0.5, -data.radius - 10.0)
	draw_rect(Rect2(bar_pos, Vector2(bar_width, bar_height)), Color(0.2, 0.0, 0.0, 1.0))
	var ratio: float = clamp(current_health / data.max_health, 0.0, 1.0)
	draw_rect(Rect2(bar_pos, Vector2(bar_width * ratio, bar_height)), Color(0.2, 0.9, 0.2, 1.0))


func _update_tower_attack(delta: float) -> bool:
	if not data.attacks_towers:
		return false
	if _tower_target != null and not is_instance_valid(_tower_target):
		_tower_target = null
	if _tower_target == null:
		_tower_target = _find_nearest_tower()
	if _tower_target == null:
		return false
	var dist: float = global_position.distance_to(_tower_target.global_position)
	if dist > TOWER_ATTACK_RANGE:
		_tower_target = null
		return false
	if _tower_attack_flash > 0.0:
		_tower_attack_flash -= delta
		queue_redraw()
	_tower_atk_timer -= delta
	if _tower_atk_timer <= 0.0:
		_tower_atk_timer = TOWER_ATTACK_INTERVAL
		_tower_attack_flash = 0.25
		_tower_target.take_damage(data.tower_damage)
		queue_redraw()
	return true


func _find_nearest_tower() -> Node2D:
	var towers: Array = get_tree().get_nodes_in_group("towers")
	var nearest: Node2D = null
	var nearest_dist: float = TOWER_ATTACK_RANGE
	for tower in towers:
		if not is_instance_valid(tower):
			continue
		var dist: float = global_position.distance_to(tower.global_position)
		if dist < nearest_dist:
			nearest = tower
			nearest_dist = dist
	return nearest


func _update_distract() -> void:
	var towers: Array = get_tree().get_nodes_in_group("towers")
	_distract_active = false
	for tower in towers:
		if not is_instance_valid(tower):
			continue
		if global_position.distance_to(tower.global_position) <= DISTRACT_RANGE:
			_distract_active = true
			return


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


func _start_idle_animation() -> void:
	_stop_idle_animation()
	_idle_tween = create_tween().set_loops()
	var squash := Vector2(1.15, 0.85)
	var stretch := Vector2(0.92, 1.08)
	var base := Vector2.ONE
	var dur := 0.3
	_idle_tween.tween_property(self, "_idle_scale", squash, dur).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_idle_tween.tween_property(self, "_idle_scale", base, dur).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_idle_tween.tween_property(self, "_idle_scale", stretch, dur).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_idle_tween.tween_property(self, "_idle_scale", base, dur).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


func _stop_idle_animation() -> void:
	if _idle_tween and _idle_tween.is_valid():
		_idle_tween.kill()
		_idle_tween = null
	_idle_scale = Vector2.ONE


func _cleanup_engagement() -> void:
	if _engaged:
		_engaged = false
		var hero_node: CharacterBody2D = _get_hero()
		if hero_node != null:
			hero_node.remove_blocked()


func _exit_tree() -> void:
	_cleanup_engagement()
