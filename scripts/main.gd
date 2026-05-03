extends Node2D

const PATH_WIDTH: float = 48.0
const SLOT_SNAP_RANGE: float = 50.0
const SLOT_RADIUS: float = 22.0

@export var tower_scene: PackedScene
@export var bullet_scene: PackedScene

@onready var hud: CanvasLayer = %HUD
@onready var wave_manager: Node = %WaveManager
@onready var hero: CharacterBody2D = %Hero
@onready var path_container: Node2D = %PathContainer
@onready var tower_container: Node2D = %TowerContainer
var _paths: Array[Path2D] = []
var _placing_tower: TowerData = null
var _ghost_pos: Vector2 = Vector2.ZERO
var _current_map_data: MapData = null
var _available_slots: Array[Vector2] = []
var _selected_tower: Node2D = null


func _ready() -> void:
	hud.tower_selected.connect(_on_tower_selected)
	hud.dawn_card_picked.connect(_on_dawn_card_picked)
	hud.map_chosen.connect(_on_map_chosen)
	hud.retry_requested.connect(_on_retry)
	hud.menu_requested.connect(_on_menu)
	hud.tower_add_floor_requested.connect(_on_tower_add_floor)
	hud.tower_repair_requested.connect(_on_tower_repair)
	hud.tower_sell_requested.connect(_on_tower_sell)
	wave_manager.wave_finished.connect(_on_wave_finished)
	GameManager.game_over.connect(_on_game_over)
	GameManager.map_cleared.connect(_on_map_cleared)
	GameManager.day_started.connect(_on_day_started)
	hero.health_changed.connect(func(hp: float) -> void: hud.update_hero_hp(hp))
	_show_map_select()


func _on_day_started(day: int) -> void:
	_clear_enemies()
	_current_map_data = MapLibrary.get_map(GameManager.current_map)
	_build_paths_for_day(day)
	wave_manager.paths = _paths
	if _current_map_data != null:
		var day_data: DayData = _current_map_data.get_day_data(day)
		wave_manager.setup_day(day_data)
		_available_slots = _current_map_data.get_available_slots(day)
	var map_name: String = _current_map_data.map_name if _current_map_data else "???"
	hud.set_day_label("Day %d/%d — %s" % [day, GameManager.DAYS_PER_MAP, map_name])
	hud.update_hero_hp(hero.current_hp)
	if day == 1:
		hero.global_position = Vector2(640, 360)
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if GameManager.current_phase == GameManager.GamePhase.MENU:
		return
	if event is InputEventMouseMotion and _placing_tower != null:
		var snap: Vector2 = _find_nearest_available_slot(event.position)
		_ghost_pos = snap if snap != Vector2.ZERO else event.position
		queue_redraw()
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _placing_tower != null:
			_try_place_tower(event.position)
		elif GameManager.current_phase == GameManager.GamePhase.DAY:
			var clicked: Node2D = _find_tower_at(event.position)
			if clicked != null:
				_select_tower(clicked)
			else:
				_deselect_tower()
				hero.move_to(event.position)
		else:
			hero.move_to(event.position)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		if _placing_tower != null:
			_placing_tower = null
			queue_redraw()
		elif _selected_tower != null:
			_deselect_tower()
	if event.is_action_pressed("next_wave"):
		if GameManager.current_phase == GameManager.GamePhase.DAY:
			_transition_to_night()


func _transition_to_night() -> void:
	_placing_tower = null
	_deselect_tower()
	GameManager.start_night()
	wave_manager.start()
	queue_redraw()


func _clear_enemies() -> void:
	EnemyPool.return_all_active()


func _on_wave_finished() -> void:
	GameManager.complete_night()
	var cards: Array[Dictionary] = BuffLibrary.pick_random_cards(3)
	hud.show_dawn_cards(cards)


func _on_dawn_card_picked(buff: Dictionary) -> void:
	_apply_buff(buff)
	GameManager.advance_to_next_day()


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


func _on_map_cleared(_map_index: int) -> void:
	hud.show_map_clear()


func _on_game_over() -> void:
	wave_manager.stop()


func _show_map_select() -> void:
	GameManager.set_phase(GameManager.GamePhase.MENU)
	hud.show_map_select(GameManager.highest_unlocked_map)


func _on_map_chosen(map_index: int) -> void:
	_reset_gameplay()
	GameManager.start_map(map_index)


func _on_retry() -> void:
	_reset_gameplay()
	GameManager.start_map(GameManager.current_map)


func _on_menu() -> void:
	_reset_gameplay()
	_show_map_select()


func _reset_gameplay() -> void:
	_placing_tower = null
	_deselect_tower()
	_clear_enemies()
	wave_manager.stop()
	for tower in tower_container.get_children():
		tower.queue_free()
	GameManager.active_buffs.clear()
	hero.reset_stats()
	hud.reset_speed()


func _find_tower_at(pos: Vector2) -> Node2D:
	var nearest: Node2D = null
	var nearest_dist: float = 40.0
	for tower in tower_container.get_children():
		if not is_instance_valid(tower):
			continue
		var dist: float = pos.distance_to(tower.global_position)
		if dist < nearest_dist:
			nearest = tower
			nearest_dist = dist
	return nearest


func _select_tower(tower: Node2D) -> void:
	if _selected_tower == tower:
		return
	_deselect_tower()
	_selected_tower = tower
	tower.set_selected(true)
	hud.show_tower_info(tower)


func _deselect_tower() -> void:
	if _selected_tower != null and is_instance_valid(_selected_tower):
		_selected_tower.set_selected(false)
	_selected_tower = null
	hud.hide_tower_info()


func _on_tower_add_floor(floor_data: TowerData) -> void:
	if _selected_tower == null or not is_instance_valid(_selected_tower):
		return
	if _selected_tower.add_floor(floor_data):
		hud.update_tower_info(_selected_tower)


func _on_tower_repair() -> void:
	if _selected_tower == null or not is_instance_valid(_selected_tower):
		return
	if _selected_tower.repair():
		hud.update_tower_info(_selected_tower)


func _on_tower_sell() -> void:
	if _selected_tower == null or not is_instance_valid(_selected_tower):
		return
	var refund: int = _selected_tower.get_sell_value()
	ResourceManager.add_scrap(refund)
	_selected_tower.queue_free()
	_selected_tower = null
	hud.hide_tower_info()
	queue_redraw()


func _on_tower_selected(tower_data: TowerData) -> void:
	if GameManager.is_game_over:
		return
	if GameManager.current_phase != GameManager.GamePhase.DAY:
		return
	_deselect_tower()
	_placing_tower = tower_data


func _try_place_tower(click_pos: Vector2) -> void:
	if _placing_tower == null:
		return
	var snap_pos: Vector2 = _find_nearest_available_slot(click_pos)
	if snap_pos == Vector2.ZERO:
		return
	if click_pos.distance_to(snap_pos) > SLOT_SNAP_RANGE:
		return
	if not ResourceManager.spend_scrap(_placing_tower.build_cost):
		return
	var tower: Node2D = tower_scene.instantiate()
	tower.data = _placing_tower
	tower.bullet_scene = bullet_scene
	tower.global_position = snap_pos
	tower_container.add_child(tower)
	_placing_tower = null
	queue_redraw()


func _find_nearest_available_slot(pos: Vector2) -> Vector2:
	var nearest: Vector2 = Vector2.ZERO
	var nearest_dist: float = INF
	for slot in _available_slots:
		if _is_slot_occupied(slot):
			continue
		var dist: float = pos.distance_to(slot)
		if dist < nearest_dist:
			nearest = slot
			nearest_dist = dist
	return nearest


func _is_slot_occupied(slot_pos: Vector2) -> bool:
	for tower in tower_container.get_children():
		if not is_instance_valid(tower):
			continue
		if tower.global_position.distance_to(slot_pos) < SLOT_RADIUS:
			return true
	return false


func _on_enemy_died(_enemy: Node, _reward: int) -> void:
	pass


func _on_enemy_reached_end(damage: float) -> void:
	GameManager.damage_base(damage)


func _build_paths_for_day(day: int) -> void:
	for child in path_container.get_children():
		child.queue_free()
	_paths.clear()

	if _current_map_data == null:
		return
	var active: Array[PackedVector2Array] = _current_map_data.get_active_paths(day)
	for points in active:
		var p := Path2D.new()
		var curve := Curve2D.new()
		for pt in points:
			curve.add_point(pt)
		p.curve = curve
		path_container.add_child(p)
		_paths.append(p)


func _draw() -> void:
	_draw_background()
	_draw_paths()
	_draw_slots()
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


func _draw_slots() -> void:
	if GameManager.current_phase != GameManager.GamePhase.DAY:
		return
	for slot in _available_slots:
		var occupied: bool = _is_slot_occupied(slot)
		if occupied:
			draw_arc(slot, SLOT_RADIUS, 0.0, TAU, 24, Color(0.5, 0.5, 0.5, 0.2), 1.5)
		else:
			draw_arc(slot, SLOT_RADIUS, 0.0, TAU, 24, Color(0.3, 1.0, 0.5, 0.4), 2.0)
			draw_arc(slot, SLOT_RADIUS - 4.0, 0.0, TAU, 24, Color(0.3, 1.0, 0.5, 0.15), 1.0)


func _draw_base() -> void:
	if _paths.is_empty():
		return
	var base_pos := Vector2(1240, 500)
	draw_rect(Rect2(base_pos.x - 30, base_pos.y - 30, 60, 60), Color(0.9, 0.7, 0.2, 1.0))
	draw_rect(Rect2(base_pos.x - 30, base_pos.y - 30, 60, 60), Color(1.0, 0.85, 0.3, 1.0), false, 2.0)


func _draw_ghost() -> void:
	var snap: Vector2 = _find_nearest_available_slot(_ghost_pos)
	var draw_pos: Vector2 = snap if snap != Vector2.ZERO and _ghost_pos.distance_to(snap) <= SLOT_SNAP_RANGE else _ghost_pos
	var valid: bool = snap != Vector2.ZERO and _ghost_pos.distance_to(snap) <= SLOT_SNAP_RANGE
	var color := Color(0.3, 1.0, 0.3, 0.4) if valid else Color(1.0, 0.3, 0.3, 0.4)
	draw_circle(draw_pos, 24.0, color)
	var range_val: float = _placing_tower.attack_range if _placing_tower != null else 100.0
	draw_arc(draw_pos, range_val, 0.0, TAU, 48, Color(1.0, 1.0, 1.0, 0.2), 1.0)
