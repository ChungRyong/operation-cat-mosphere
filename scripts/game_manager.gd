extends Node

signal phase_changed(new_phase: GamePhase)
signal day_started(day: int)
signal game_over
signal base_damaged(remaining_hp: float)
signal day_cleared(day: int)
signal map_cleared(map_index: int)

enum GamePhase { DAY, NIGHT, DAWN, MENU }

const NIGHT_DURATION: float = 120.0
const BASE_HP: float = 100.0
const DAYS_PER_MAP: int = 20

var current_phase: GamePhase = GamePhase.MENU
var current_map: int = 0
var current_day: int = 1
var night_timer: float = 0.0
var base_hp: float = BASE_HP
var is_game_over: bool = false
var active_buffs: Array[Dictionary] = []
const SAVE_PATH: String = "user://progress.cfg"

var highest_unlocked_map: int = 0


func _ready() -> void:
	_load_progress()


func start_map(map_index: int) -> void:
	current_map = map_index
	current_day = 1
	is_game_over = false
	base_hp = BASE_HP
	active_buffs.clear()
	var map_data: MapData = MapLibrary.get_map(map_index)
	if map_data != null:
		ResourceManager.reset_for_map(map_data.starting_scrap)
	else:
		ResourceManager.reset_for_map(200)
	day_started.emit(current_day)
	set_phase(GamePhase.DAY)


func start_day(day: int) -> void:
	current_day = day
	is_game_over = false
	base_hp = BASE_HP
	var map_data: MapData = MapLibrary.get_map(current_map)
	if map_data != null:
		var day_data: DayData = map_data.get_day_data(day)
		if day_data != null:
			ResourceManager.add_daily_scrap(day_data.daily_scrap)
	day_started.emit(current_day)
	set_phase(GamePhase.DAY)


func set_phase(phase: GamePhase) -> void:
	current_phase = phase
	if phase == GamePhase.NIGHT:
		night_timer = 0.0
	phase_changed.emit(phase)


func start_night() -> void:
	set_phase(GamePhase.NIGHT)


func complete_night() -> void:
	ResourceManager.add_wave_clear_bonus()
	ResourceManager.add_gold_can(ResourceManager.GOLD_PER_DAY_CLEAR)
	save_progress()
	day_cleared.emit(current_day)
	set_phase(GamePhase.DAWN)


func advance_to_next_day() -> void:
	if current_day >= DAYS_PER_MAP:
		highest_unlocked_map = maxi(highest_unlocked_map, current_map + 1)
		ResourceManager.add_gold_can(ResourceManager.GOLD_PER_MAP_CLEAR)
		save_progress()
		map_cleared.emit(current_map)
		return
	start_day(current_day + 1)


func apply_buff(buff: Dictionary) -> void:
	active_buffs.append(buff)


func damage_base(amount: float) -> void:
	if is_game_over:
		return
	base_hp -= amount
	base_damaged.emit(base_hp)
	if base_hp <= 0.0:
		base_hp = 0.0
		is_game_over = true
		game_over.emit()


func save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "highest_unlocked_map", highest_unlocked_map)
	cfg.set_value("progress", "gold_can", ResourceManager.gold_can)
	cfg.save(SAVE_PATH)


func _load_progress() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	highest_unlocked_map = cfg.get_value("progress", "highest_unlocked_map", 0)
	ResourceManager.gold_can = cfg.get_value("progress", "gold_can", 0)


func _process(delta: float) -> void:
	if current_phase == GamePhase.NIGHT and not is_game_over:
		night_timer += delta
