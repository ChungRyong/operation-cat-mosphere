extends Node2D

const STAGE_NAMES: Array[String] = ["Tutorial", "Mass", "Gimmick", "Counter", "Mini-Boss"]
const PATH_WIDTH: float = 48.0
const SCRAP_SPAWN_COUNT: int = 8
const SCRAP_PER_PICKUP: int = 10

@export var tower_scene: PackedScene
@export var bullet_scene: PackedScene

var _scrap_pickup_scene: PackedScene = preload("res://scenes/pickup/scrap_pickup.tscn")

@onready var hud: CanvasLayer = %HUD
@onready var wave_manager: Node = %WaveManager
@onready var hero: CharacterBody2D = %Hero
@onready var path_container: Node2D = %PathContainer
@onready var tower_container: Node2D = %TowerContainer
@onready var pickup_container: Node2D = %PickupContainer

var _paths: Array[Path2D] = []
var _placing_tower: TowerData = null
var _ghost_pos: Vector2 = Vector2.ZERO
var _current_stage: int = 0


func _ready() -> void:
	hud.tower_selected.connect(_on_tower_selected)
	hud.dawn_card_picked.connect(_on_dawn_card_picked)
	hud.stage_chosen.connect(_on_stage_chosen)
	hud.retry_requested.connect(_on_retry)
	hud.menu_requested.connect(_on_menu)
	wave_manager.wave_finished.connect(_on_wave_finished)
	GameManager.game_over.connect(_on_game_over)
	GameManager.all_stages_cleared.connect(_on_all_stages_cleared)
	GameManager.stage_started.connect(_on_stage_started)
	hero.health_changed.connect(func(hp: float) -> void: hud.update_hero_hp(hp))
	_show_stage_select()


func _on_stage_started(stage_index: int) -> void:
	_current_stage = stage_index
	_clear_enemies()
	_build_paths(stage_index)
	wave_manager.paths = _paths
	wave_manager.setup_stage(stage_index)
	hud.set_stage_name("Stage %d: %s" % [stage_index + 1, STAGE_NAMES[stage_index]])
	hud.update_hero_hp(hero.current_hp)
	hero.global_position = Vector2(640, 360)
	_spawn_day_scrap()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if GameManager.current_phase == GameManager.GamePhase.MENU:
		return
	if event is InputEventMouseMotion and _placing_tower != null:
		_ghost_pos = event.position
		queue_redraw()
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _placing_tower != null:
			_try_place_tower(event.position)
		else:
			hero.move_to(event.position)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		if _placing_tower != null:
			_placing_tower = null
			queue_redraw()
	if event.is_action_pressed("next_wave"):
		if GameManager.current_phase == GameManager.GamePhase.DAY:
			_transition_to_night()


func _transition_to_night() -> void:
	_placing_tower = null
	_clear_pickups()
	GameManager.start_night()
	wave_manager.start()
	queue_redraw()


func _spawn_day_scrap() -> void:
	_clear_pickups()
	for i in SCRAP_SPAWN_COUNT:
		var pickup: Area2D = _scrap_pickup_scene.instantiate()
		pickup.amount = SCRAP_PER_PICKUP
		pickup.global_position = _random_field_position()
		pickup_container.add_child(pickup)


func _random_field_position() -> Vector2:
	for attempt in 30:
		var pos := Vector2(randf_range(60, 1220), randf_range(60, 660))
		var too_close: bool = false
		for p in _paths:
			if p.curve == null:
				continue
			var closest: Vector2 = p.curve.get_closest_point(pos)
			if pos.distance_to(closest) < PATH_WIDTH + 30.0:
				too_close = true
				break
		if not too_close:
			return pos
	return Vector2(randf_range(60, 1220), randf_range(60, 660))


func _clear_pickups() -> void:
	for child in pickup_container.get_children():
		child.queue_free()


func _clear_enemies() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()


func _on_wave_finished() -> void:
	GameManager.complete_night()
	var cards: Array[Dictionary] = BuffLibrary.pick_random_cards(3)
	hud.show_dawn_cards(cards)


func _on_dawn_card_picked(buff: Dictionary) -> void:
	_apply_buff(buff)
	GameManager.advance_to_next_stage()


func _apply_buff(buff: Dictionary) -> void:
	GameManager.apply_buff(buff)
	match buff["type"]:
		"hero_hp":
			hero.max_hp += buff["value"]
			hero.current_hp = hero.max_hp
			hud.update_hero_hp(hero.current_hp)
		"scrap_bonus":
			ResourceManager.add_scrap(int(buff["value"]))
		"base_hp":
			GameManager.base_hp += buff["value"]


func _on_all_stages_cleared() -> void:
	hud.show_all_clear()


func _on_game_over() -> void:
	wave_manager.stop()


func _show_stage_select() -> void:
	GameManager.set_phase(GameManager.GamePhase.MENU)
	hud.show_stage_select(GameManager.highest_unlocked_stage)


func _on_stage_chosen(stage_index: int) -> void:
	_reset_gameplay()
	GameManager.start_stage(stage_index)


func _on_retry() -> void:
	_reset_gameplay()
	GameManager.start_stage(_current_stage)


func _on_menu() -> void:
	_reset_gameplay()
	_show_stage_select()


func _reset_gameplay() -> void:
	_placing_tower = null
	_clear_enemies()
	_clear_pickups()
	wave_manager.stop()
	for tower in tower_container.get_children():
		tower.queue_free()
	GameManager.active_buffs.clear()
	hero.reset_stats()
	hud.reset_speed()


func _on_tower_selected(tower_data: TowerData) -> void:
	if GameManager.is_game_over:
		return
	if GameManager.current_phase != GameManager.GamePhase.DAY:
		return
	_placing_tower = tower_data


func _try_place_tower(pos: Vector2) -> void:
	if _placing_tower == null:
		return
	if not _is_valid_placement(pos):
		return
	if not ResourceManager.spend_scrap(_placing_tower.build_cost):
		return
	var tower: Node2D = tower_scene.instantiate()
	tower.data = _placing_tower
	tower.bullet_scene = bullet_scene
	tower.global_position = pos
	tower_container.add_child(tower)
	_placing_tower = null
	queue_redraw()


func _is_valid_placement(pos: Vector2) -> bool:
	for p in _paths:
		var curve: Curve2D = p.curve
		var closest: Vector2 = curve.get_closest_point(pos)
		if pos.distance_to(closest) < PATH_WIDTH + 20.0:
			return false
	for tower in tower_container.get_children():
		if pos.distance_to(tower.global_position) < 50.0:
			return false
	return true


func _on_enemy_died(_enemy: Node, _reward: int) -> void:
	pass


func _on_enemy_reached_end(damage: float) -> void:
	GameManager.damage_base(damage)


func _build_paths(stage_index: int) -> void:
	for child in path_container.get_children():
		child.queue_free()
	_paths.clear()

	var all_path_data: Array = _get_stage_paths(stage_index)
	for points in all_path_data:
		var p := Path2D.new()
		var curve := Curve2D.new()
		for pt in points:
			curve.add_point(pt)
		p.curve = curve
		path_container.add_child(p)
		_paths.append(p)


func _get_stage_paths(stage_index: int) -> Array:
	match stage_index:
		0:
			return [[Vector2(0, 360), Vector2(400, 360), Vector2(400, 200), Vector2(880, 200), Vector2(880, 500), Vector2(1280, 500)]]
		1:
			return [[Vector2(0, 300), Vector2(320, 300), Vector2(640, 500), Vector2(960, 300), Vector2(1280, 300)]]
		2:
			return [[Vector2(0, 360), Vector2(250, 180), Vector2(500, 540), Vector2(750, 180), Vector2(1000, 540), Vector2(1280, 360)]]
		3:
			return [[Vector2(0, 360), Vector2(350, 360), Vector2(640, 200), Vector2(930, 360), Vector2(1280, 360)]]
		4:
			return [
				[Vector2(0, 200), Vector2(400, 200), Vector2(640, 360), Vector2(1000, 360), Vector2(1280, 360)],
				[Vector2(0, 520), Vector2(400, 520), Vector2(640, 360), Vector2(1000, 360), Vector2(1280, 360)],
			]
	return [[Vector2(0, 360), Vector2(1280, 360)]]


func _draw() -> void:
	_draw_background()
	_draw_paths()
	_draw_base()
	if _placing_tower != null:
		_draw_ghost()


func _draw_background() -> void:
	var bg_color: Color
	match GameManager.current_phase:
		GameManager.GamePhase.DAY:
			bg_color = Color(0.12, 0.1, 0.18, 1.0)
		GameManager.GamePhase.NIGHT:
			bg_color = Color(0.05, 0.03, 0.08, 1.0)
		GameManager.GamePhase.DAWN:
			bg_color = Color(0.15, 0.1, 0.12, 1.0)
		_:
			bg_color = Color(0.08, 0.06, 0.12, 1.0)
	draw_rect(Rect2(0, 0, 1280, 720), bg_color)
	var tile_color := bg_color.lightened(0.05)
	for x in range(0, 1280, 64):
		for y in range(0, 720, 64):
			if (x / 64 + y / 64) % 2 == 0:
				draw_rect(Rect2(x, y, 64, 64), tile_color)


func _draw_paths() -> void:
	for p in _paths:
		if p.curve == null or p.curve.point_count < 2:
			continue
		var points: PackedVector2Array = p.curve.tessellate()
		for i in range(points.size() - 1):
			draw_line(points[i], points[i + 1], Color(0.25, 0.2, 0.35, 1.0), PATH_WIDTH)
		for i in range(points.size() - 1):
			draw_line(points[i], points[i + 1], Color(0.35, 0.3, 0.45, 1.0), PATH_WIDTH - 8.0)


func _draw_base() -> void:
	if _paths.is_empty():
		return
	var last_curve: Curve2D = _paths[0].curve
	var base_pos := Vector2(1240, last_curve.get_point_position(last_curve.point_count - 1).y)
	draw_rect(Rect2(base_pos.x - 30, base_pos.y - 30, 60, 60), Color(0.9, 0.7, 0.2, 1.0))
	draw_rect(Rect2(base_pos.x - 30, base_pos.y - 30, 60, 60), Color(1.0, 0.85, 0.3, 1.0), false, 2.0)


func _draw_ghost() -> void:
	var valid: bool = _is_valid_placement(_ghost_pos)
	var color := Color(0.3, 1.0, 0.3, 0.4) if valid else Color(1.0, 0.3, 0.3, 0.4)
	draw_circle(_ghost_pos, 24.0, color)
	var range_val: float = _placing_tower.attack_range if _placing_tower != null else 100.0
	draw_arc(_ghost_pos, range_val, 0.0, TAU, 48, Color(1.0, 1.0, 1.0, 0.2), 1.0)
