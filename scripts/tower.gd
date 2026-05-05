extends Node2D

signal destroyed

@export var data: TowerData
@export var bullet_scene: PackedScene

var floors: Array[TowerData] = []
var floor_level: int = 1
var current_health: float = 0.0
var total_invested: int = 0
var is_selected: bool = false

var _floor_timers: Array[float] = []
var _floor_stun_cds: Array[float] = []
var _floor_ranges: Array[float] = []
var _floor_crits: Array[float] = []
var _collapsing: bool = false
var _collapse_timer: float = 0.0
var _damage_flash: float = 0.0
var _sfx_cooldown: float = 0.0


func _ready() -> void:
	add_to_group("towers")
	if data == null:
		return
	current_health = data.max_health * UpgradeManager.get_mult_bonus("tower_hp")
	total_invested = data.build_cost
	floors.append(data)
	_floor_timers.append(0.0)
	_floor_stun_cds.append(0.0)
	_update_floor_stats()
	queue_redraw()


func _process(delta: float) -> void:
	if data == null:
		return
	for i in _floor_stun_cds.size():
		if _floor_stun_cds[i] > 0.0:
			_floor_stun_cds[i] -= delta
	if _sfx_cooldown > 0.0:
		_sfx_cooldown -= delta
	if _damage_flash > 0.0:
		_damage_flash -= delta
		queue_redraw()

	if _collapsing:
		_collapse_timer -= delta
		if _collapse_timer <= 0.0 and floors.size() > 1:
			floors.pop_back()
			_floor_timers.pop_back()
			_floor_stun_cds.pop_back()
			_floor_ranges.pop_back()
			_floor_crits.pop_back()
			floor_level = floors.size()
			queue_redraw()
			if current_health > get_effective_max_hp() * TowerData.COLLAPSE_THRESHOLD:
				_collapsing = false
			else:
				_collapse_timer = 2.0

	if GameManager.current_phase != GameManager.GamePhase.NIGHT:
		return
	for i in floors.size():
		_floor_timers[i] -= delta
		if _floor_timers[i] <= 0.0:
			var fd: TowerData = floors[i]
			_floor_timers[i] = 1.0 / max(_get_buffed_fire_rate(fd), 0.01)
			var target: Node2D = _find_target(i)
			if target != null:
				_shoot(i, target)


func add_floor(floor_data: TowerData) -> bool:
	if floors.size() >= 5:
		return false
	var cost: int = get_add_floor_cost(floor_data)
	if not ResourceManager.spend_scrap(cost):
		return false
	floors.append(floor_data)
	_floor_timers.append(randf_range(0.1, 0.3))
	_floor_stun_cds.append(0.0)
	total_invested += cost
	floor_level = floors.size()
	_update_floor_stats()
	queue_redraw()
	return true


func get_add_floor_cost(floor_data: TowerData) -> int:
	return floor_data.build_cost


func get_effective_max_hp() -> float:
	return data.max_health * UpgradeManager.get_mult_bonus("tower_hp")


func repair() -> bool:
	var eff_max: float = get_effective_max_hp()
	if current_health >= eff_max:
		return false
	if not ResourceManager.spend_scrap(data.repair_cost):
		return false
	current_health = eff_max
	_collapsing = false
	queue_redraw()
	return true


func take_damage(amount: float) -> void:
	current_health -= amount
	_damage_flash = 0.2
	SfxManager.play("tower_hit")
	queue_redraw()
	if current_health <= 0.0:
		SfxManager.play("collapse")
		destroyed.emit()
		queue_free()
		return
	if not _collapsing and current_health <= get_effective_max_hp() * TowerData.COLLAPSE_THRESHOLD and floors.size() > 1:
		_collapsing = true
		_collapse_timer = 2.0
		SfxManager.play("collapse")


func get_sell_value() -> int:
	return int(total_invested * 0.5)


func set_selected(value: bool) -> void:
	is_selected = value
	queue_redraw()


func get_total_dps() -> float:
	var total: float = 0.0
	for fd in floors:
		total += _get_buffed_damage(fd) * _get_buffed_fire_rate(fd)
	return total


func get_max_range() -> float:
	var max_r: float = 0.0
	for r in _floor_ranges:
		if r > max_r:
			max_r = r
	return max_r


func _update_floor_stats() -> void:
	_floor_ranges.clear()
	_floor_crits.clear()
	for i in floors.size():
		var fd: TowerData = floors[i]
		var r: float = fd.attack_range * (1.0 + i * TowerData.RANGE_BONUS_PER_FLOOR) * UpgradeManager.get_mult_bonus("tower_range")
		var c: float = TowerData.CRIT_BASE + i * TowerData.CRIT_PER_FLOOR
		for buff in GameManager.active_buffs:
			match buff["type"]:
				"tower_range": r *= (1.0 + buff["value"])
				"tower_crit": c += buff["value"]
		_floor_ranges.append(r)
		_floor_crits.append(c)


func _get_buffed_damage(floor_data: TowerData) -> float:
	var dmg: float = floor_data.damage * UpgradeManager.get_mult_bonus("tower_atk")
	for buff in GameManager.active_buffs:
		if buff["type"] == "tower_atk":
			dmg *= (1.0 + buff["value"])
	return dmg


func _get_buffed_fire_rate(floor_data: TowerData) -> float:
	var rate: float = floor_data.fire_rate
	for buff in GameManager.active_buffs:
		if buff["type"] == "tower_rate":
			rate *= (1.0 + buff["value"])
	return rate


func _find_target(floor_index: int) -> Node2D:
	var enemies: Array = get_tree().get_nodes_in_group("enemies")
	var effective_range: float = _floor_ranges[floor_index]
	var closest_distractor: Node2D = null
	var closest_distractor_dist: float = effective_range
	var closest: Node2D = null
	var closest_dist: float = effective_range

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var dist: float = global_position.distance_to(enemy.global_position)
		if dist > effective_range:
			continue
		if enemy is PathFollow2D and enemy._distract_active and enemy.is_gimmick_distractor():
			if dist < closest_distractor_dist:
				closest_distractor = enemy
				closest_distractor_dist = dist
		if dist < closest_dist:
			closest = enemy
			closest_dist = dist

	return closest_distractor if closest_distractor != null else closest


func _shoot(floor_index: int, target: Node2D) -> void:
	if bullet_scene == null:
		return
	var fd: TowerData = floors[floor_index]
	var is_crit: bool = randf() < _floor_crits[floor_index]
	var can_stun: bool = fd.stun_duration > 0.0 and _floor_stun_cds[floor_index] <= 0.0
	var stun_val: float = fd.stun_duration if can_stun else 0.0

	var bullet: Node2D = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = global_position + Vector2(0, -floor_index * 12.0)
	bullet.launch(target, _get_buffed_damage(fd), fd.projectile_speed, fd.attack_type, is_crit, stun_val, self)
	if _sfx_cooldown <= 0.0:
		SfxManager.play("shoot")
		_sfx_cooldown = 0.15

	if can_stun:
		_floor_stun_cds[floor_index] = fd.stun_cooldown


func _draw() -> void:
	if data == null:
		return
	var floor_scale: float = 1.0 + (floors.size() - 1) * 0.1
	var half: float = 24.0 * floor_scale
	for i in floors.size():
		var y_offset: float = -i * 12.0
		var floor_color: Color = floors[i].color
		if i == floors.size() - 1 and floors.size() == 5:
			floor_color = floor_color.lightened(0.3)
		if _damage_flash > 0.0:
			floor_color = floor_color.lerp(Color(1.0, 0.2, 0.1), _damage_flash / 0.2)
		draw_rect(Rect2(-half, y_offset - 12.0, half * 2.0, 12.0), floor_color)
		draw_rect(Rect2(-half, y_offset - 12.0, half * 2.0, 12.0), Color(0.0, 0.0, 0.0, 0.5), false, 1.0)

	var max_range: float = get_max_range()
	var range_alpha: float = 0.3 if is_selected else 0.1
	draw_arc(Vector2.ZERO, max_range, 0.0, TAU, 48, Color(1.0, 1.0, 1.0, range_alpha), 1.0)

	if is_selected:
		draw_rect(Rect2(-half - 2, -(floors.size() * 12.0) - 2, (half + 2) * 2.0, floors.size() * 12.0 + 4), Color(1.0, 1.0, 1.0, 0.6), false, 2.0)

	var hp_ratio: float = clamp(current_health / get_effective_max_hp(), 0.0, 1.0)
	var bar_w: float = half * 2.0
	var bar_y: float = 6.0
	draw_rect(Rect2(-half, bar_y, bar_w, 3.0), Color(0.3, 0.0, 0.0, 1.0))
	draw_rect(Rect2(-half, bar_y, bar_w * hp_ratio, 3.0), Color(0.0, 0.8, 0.0, 1.0))
