extends Node2D

signal defeated(boss_data: BossData)

@export var data: BossData

var current_health: float = 0.0
var _phase: int = 1
var _charge_timer: float = 3.0
var _summon_timer: float = 6.0
var _aoe_timer: float = 8.0
var _charging: bool = false
var _charge_target: Vector2 = Vector2.ZERO
var _charge_origin: Vector2 = Vector2.ZERO
var _charge_progress: float = 0.0
var _aoe_flash: float = 0.0
var _aoe_center: Vector2 = Vector2.ZERO
var _idle_timer: float = 0.0
var _home_pos: Vector2 = Vector2.ZERO


func _ready() -> void:
	if data == null:
		return
	current_health = data.max_health
	_home_pos = global_position
	add_to_group("boss")
	queue_redraw()


func init_boss(boss_data: BossData, pos: Vector2) -> void:
	data = boss_data
	current_health = boss_data.max_health
	global_position = pos
	_home_pos = pos
	_phase = 1
	_charge_timer = 3.0
	_summon_timer = 6.0
	_aoe_timer = 8.0
	_charging = false
	_aoe_flash = 0.0
	add_to_group("boss")
	add_to_group("enemies")
	queue_redraw()


func _process(delta: float) -> void:
	if data == null or current_health <= 0.0:
		return
	if GameManager.current_phase != GameManager.GamePhase.NIGHT:
		return

	if _aoe_flash > 0.0:
		_aoe_flash -= delta
		queue_redraw()

	if _charging:
		_update_charge(delta)
		return

	_charge_timer -= delta
	_summon_timer -= delta
	if _phase >= 2:
		_aoe_timer -= delta

	if _charge_timer <= 0.0:
		_start_charge()
	elif _phase >= 2 and _aoe_timer <= 0.0:
		_do_aoe()
	elif _summon_timer <= 0.0:
		_do_summon()

	_idle_timer += delta
	if _idle_timer > 1.0:
		_idle_timer = 0.0
		var sway := Vector2(randf_range(-20, 20), randf_range(-20, 20))
		global_position = _home_pos + sway
		queue_redraw()


func take_damage(amount: float, attack_type: TowerData.AttackType) -> void:
	if data == null or current_health <= 0.0:
		return
	var final_dmg: float = DamageCalculator.calculate(amount, attack_type, data.defense_type, false)
	if final_dmg <= 0.0:
		return
	current_health -= final_dmg
	queue_redraw()
	if _phase == 1 and current_health <= data.max_health * data.phase2_threshold:
		_phase = 2
		_aoe_timer = 2.0
		_summon_timer = min(_summon_timer, 3.0)
	if current_health <= 0.0:
		current_health = 0.0
		_on_defeated()


func apply_stun(duration: float) -> void:
	pass


func _on_defeated() -> void:
	ResourceManager.add_gold_can(data.gold_reward)
	defeated.emit(data)
	queue_free()


func _start_charge() -> void:
	_charging = true
	_charge_origin = global_position
	var target: Node2D = _pick_charge_target()
	_charge_target = target.global_position if target != null else Vector2(randf_range(200, 1080), randf_range(100, 600))
	_charge_progress = 0.0
	_charge_timer = data.charge_cooldown if _phase == 1 else data.charge_cooldown * 0.6


func _update_charge(delta: float) -> void:
	var speed: float = data.charge_speed * (1.3 if _phase >= 2 else 1.0)
	var total_dist: float = _charge_origin.distance_to(_charge_target)
	if total_dist < 1.0:
		_finish_charge()
		return
	_charge_progress += speed * delta / total_dist
	global_position = _charge_origin.lerp(_charge_target, min(_charge_progress, 1.0))
	queue_redraw()

	for tower in get_tree().get_nodes_in_group("towers"):
		if not is_instance_valid(tower):
			continue
		if global_position.distance_to(tower.global_position) < data.radius + 24.0:
			tower.take_damage(data.charge_damage)

	var hero: CharacterBody2D = _get_hero()
	if hero != null and global_position.distance_to(hero.global_position) < data.radius + 20.0:
		hero.take_damage(data.charge_damage * 0.5)

	if _charge_progress >= 1.0:
		_finish_charge()


func _finish_charge() -> void:
	_charging = false
	global_position = _charge_target
	_home_pos = global_position


func _do_summon() -> void:
	if data.summon_enemy == null:
		_summon_timer = data.summon_cooldown
		return
	var paths_group: Array = get_tree().get_nodes_in_group("enemies")
	var path_nodes: Array[Path2D] = []
	for child in get_tree().current_scene.get_node("%PathContainer").get_children():
		if child is Path2D:
			path_nodes.append(child)

	var count: int = data.summon_count if _phase == 1 else int(data.summon_count * 1.5)
	for i in count:
		if path_nodes.is_empty():
			break
		var target_path: Path2D = path_nodes[randi() % path_nodes.size()]
		var enemy: PathFollow2D = EnemyPool.get_enemy()
		enemy.init_pooled(data.summon_enemy)
		target_path.add_child(enemy)
		enemy.progress = randf_range(0, target_path.curve.get_baked_length() * 0.3)
		enemy.add_to_group("enemies")
		enemy.died.connect(get_tree().current_scene._on_enemy_died)
		enemy.reached_end.connect(get_tree().current_scene._on_enemy_reached_end)
	_summon_timer = data.summon_cooldown if _phase == 1 else data.summon_cooldown * 0.6


func _do_aoe() -> void:
	_aoe_center = global_position + Vector2(randf_range(-80, 80), randf_range(-80, 80))
	_aoe_flash = 0.5

	for tower in get_tree().get_nodes_in_group("towers"):
		if not is_instance_valid(tower):
			continue
		if _aoe_center.distance_to(tower.global_position) < data.aoe_radius:
			tower.take_damage(data.aoe_damage)

	var hero: CharacterBody2D = _get_hero()
	if hero != null and _aoe_center.distance_to(hero.global_position) < data.aoe_radius:
		hero.take_damage(data.aoe_damage * 0.5)

	_aoe_timer = data.aoe_cooldown if _phase == 1 else data.aoe_cooldown * 0.6


func _pick_charge_target() -> Node2D:
	var towers: Array = get_tree().get_nodes_in_group("towers")
	if towers.is_empty():
		return _get_hero()
	return towers[randi() % towers.size()]


func _get_hero() -> CharacterBody2D:
	var heroes: Array = get_tree().get_nodes_in_group("hero")
	if heroes.is_empty():
		return null
	return heroes[0] as CharacterBody2D


func _draw() -> void:
	if data == null:
		return
	var phase_color: Color = data.color if _phase == 1 else data.color.lightened(0.2)
	draw_circle(Vector2.ZERO, data.radius, phase_color)
	draw_arc(Vector2.ZERO, data.radius, 0.0, TAU, 32, Color(1.0, 1.0, 1.0, 0.4), 2.0)
	if _phase >= 2:
		draw_arc(Vector2.ZERO, data.radius + 6.0, 0.0, TAU, 32, Color(1.0, 0.3, 0.1, 0.5), 2.0)

	if _charging:
		var dir: Vector2 = (_charge_target - global_position).normalized()
		draw_line(Vector2.ZERO, dir * (data.radius + 20.0), Color(1.0, 0.5, 0.1, 0.8), 3.0)

	if _aoe_flash > 0.0:
		var local_center: Vector2 = _aoe_center - global_position
		var alpha: float = _aoe_flash / 0.5
		draw_circle(local_center, data.aoe_radius, Color(1.0, 0.2, 0.1, alpha * 0.25))
		draw_arc(local_center, data.aoe_radius, 0.0, TAU, 32, Color(1.0, 0.3, 0.1, alpha * 0.6), 2.0)
