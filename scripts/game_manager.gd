extends Node

signal phase_changed(new_phase: GamePhase)
signal stage_started(stage_index: int)
signal game_over
signal base_damaged(remaining_hp: float)
signal stage_cleared(stage_index: int)
signal all_stages_cleared

enum GamePhase { DAY, NIGHT, DAWN, MENU }

const NIGHT_DURATION: float = 120.0
const BASE_HP: float = 100.0
const TOTAL_STAGES: int = 5

var current_phase: GamePhase = GamePhase.MENU
var current_stage: int = 0
var night_timer: float = 0.0
var base_hp: float = BASE_HP
var is_game_over: bool = false
var active_buffs: Array[Dictionary] = []
var highest_unlocked_stage: int = 0


func start_stage(stage_index: int) -> void:
	current_stage = stage_index
	is_game_over = false
	base_hp = BASE_HP
	ResourceManager.reset_for_stage(stage_index)
	stage_started.emit(stage_index)
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
	highest_unlocked_stage = maxi(highest_unlocked_stage, current_stage + 1)
	stage_cleared.emit(current_stage)
	set_phase(GamePhase.DAWN)


func advance_to_next_stage() -> void:
	if current_stage + 1 >= TOTAL_STAGES:
		all_stages_cleared.emit()
		return
	start_stage(current_stage + 1)


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


func _process(delta: float) -> void:
	if current_phase == GamePhase.NIGHT and not is_game_over:
		night_timer += delta
