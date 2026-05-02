extends Node2D

signal destroyed

@export var data: TowerData
@export var bullet_scene: PackedScene

var floor_level: int = 1
var current_health: float = 0.0
var total_invested: int = 0
var is_selected: bool = false

var _effective_range: float = 0.0
var _crit_chance: float = 0.0
var _stun_cd_timer: float = 0.0
var _collapsing: bool = false
var _collapse_timer: float = 0.0

@onready var fire_timer: Timer = %FireTimer


func _ready() -> void:
	if data == null:
		return
	current_health = data.max_health
	total_invested = data.build_cost
	_update_floor_stats()
	fire_timer.wait_time = 1.0 / max(get_buffed_fire_rate(), 0.01)
	fire_timer.one_shot = false
	fire_timer.timeout.connect(_on_fire_timer_timeout)
	fire_timer.start()
	queue_redraw()


func _process(delta: float) -> void:
	if _stun_cd_timer > 0.0:
		_stun_cd_timer -= delta
	if _collapsing:
		_collapse_timer -= delta
		if _collapse_timer <= 0.0 and floor_level > 1:
			floor_level -= 1
			_update_floor_stats()
			queue_redraw()
			if current_health > data.max_health * TowerData.COLLAPSE_THRESHOLD:
				_collapsing = false
			else:
				_collapse_timer = 2.0


func add_floor() -> bool:
	if floor_level >= 5:
		return false
	var cost: int = data.get_floor_cost(floor_level + 1)
	if not ResourceManager.spend_scrap(cost):
		return false
	floor_level += 1
	total_invested += cost
	_update_floor_stats()
	queue_redraw()
	return true


func repair() -> bool:
	if current_health >= data.max_health:
		return false
	if not ResourceManager.spend_scrap(data.repair_cost):
		return false
	current_health = data.max_health
	_collapsing = false
	queue_redraw()
	return true


func take_damage(amount: float) -> void:
	current_health -= amount
	queue_redraw()
	if current_health <= 0.0:
		destroyed.emit()
		queue_free()
		return
	if not _collapsing and current_health <= data.max_health * TowerData.COLLAPSE_THRESHOLD and floor_level > 1:
		_collapsing = true
		_collapse_timer = 2.0


func get_sell_value() -> int:
	return int(total_invested * 0.5)


func set_selected(value: bool) -> void:
	is_selected = value
	queue_redraw()


func _update_floor_stats() -> void:
	_effective_range = data.get_effective_range(floor_level)
	_crit_chance = data.get_crit_chance(floor_level)
	for buff in GameManager.active_buffs:
		match buff["type"]:
			"tower_range":
				_effective_range *= (1.0 + buff["value"])
			"tower_crit":
				_crit_chance += buff["value"]


func get_buffed_damage() -> float:
	var dmg: float = data.damage
	for buff in GameManager.active_buffs:
		if buff["type"] == "tower_atk":
			dmg *= (1.0 + buff["value"])
	return dmg


func get_buffed_fire_rate() -> float:
	var rate: float = data.fire_rate
	for buff in GameManager.active_buffs:
		if buff["type"] == "tower_rate":
			rate *= (1.0 + buff["value"])
	return rate


func _on_fire_timer_timeout() -> void:
	if GameManager.current_phase != GameManager.GamePhase.NIGHT:
		return
	var target: Node2D = _find_target()
	if target == null:
		return
	_shoot(target)


func _find_target() -> Node2D:
	var enemies: Array = get_tree().get_nodes_in_group("enemies")
	var closest: Node2D = null
	var closest_dist: float = _effective_range

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if enemy is PathFollow2D and enemy.data != null and enemy.is_gimmick_distractor():
			var dist: float = global_position.distance_to(enemy.global_position)
			if dist <= _effective_range:
				return enemy

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var dist: float = global_position.distance_to(enemy.global_position)
		if dist <= closest_dist:
			closest = enemy
			closest_dist = dist
	return closest


func _shoot(target: Node2D) -> void:
	if bullet_scene == null:
		return
	var is_crit: bool = randf() < _crit_chance
	var bullet: Node2D = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = global_position
	bullet.launch(target, get_buffed_damage(), data.projectile_speed, data.attack_type, is_crit, data.stun_duration if _stun_cd_timer <= 0.0 else 0.0, self)
	if data.stun_duration > 0.0 and _stun_cd_timer <= 0.0:
		_stun_cd_timer = data.stun_cooldown


func _draw() -> void:
	if data == null:
		return
	var floor_scale: float = 1.0 + (floor_level - 1) * 0.1
	var half: float = 24.0 * floor_scale
	for i in floor_level:
		var y_offset: float = -i * 12.0
		var floor_color: Color = data.color
		if i == floor_level - 1 and floor_level == 5:
			floor_color = floor_color.lightened(0.3)
		draw_rect(Rect2(-half, y_offset - 12.0, half * 2.0, 12.0), floor_color)
		draw_rect(Rect2(-half, y_offset - 12.0, half * 2.0, 12.0), Color(0.0, 0.0, 0.0, 0.5), false, 1.0)

	var range_alpha: float = 0.3 if is_selected else 0.1
	draw_arc(Vector2.ZERO, _effective_range, 0.0, TAU, 48, Color(1.0, 1.0, 1.0, range_alpha), 1.0)

	if is_selected:
		draw_rect(Rect2(-half - 2, -(floor_level * 12.0) - 2, (half + 2) * 2.0, floor_level * 12.0 + 4), Color(1.0, 1.0, 1.0, 0.6), false, 2.0)

	var hp_ratio: float = clamp(current_health / data.max_health, 0.0, 1.0)
	var bar_w: float = half * 2.0
	var bar_y: float = 6.0
	draw_rect(Rect2(-half, bar_y, bar_w, 3.0), Color(0.3, 0.0, 0.0, 1.0))
	draw_rect(Rect2(-half, bar_y, bar_w * hp_ratio, 3.0), Color(0.0, 0.8, 0.0, 1.0))
