extends CanvasLayer

signal tower_selected(tower_data: TowerData)
signal dawn_card_picked(buff: Dictionary)
signal night_requested

@onready var scrap_label: Label = %ScrapLabel
@onready var essence_label: Label = %EssenceLabel
@onready var timer_label: Label = %TimerLabel
@onready var base_hp_label: Label = %BaseHpLabel
@onready var hero_hp_label: Label = %HeroHpLabel
@onready var stage_label: Label = %StageLabel
@onready var phase_label: Label = %PhaseLabel
@onready var tower_panel: HBoxContainer = %TowerPanel
@onready var game_over_panel: Panel = %GameOverPanel
@onready var result_label: Label = %ResultLabel
@onready var dawn_panel: Panel = %DawnPanel
@onready var dawn_cards: HBoxContainer = %DawnCards
@onready var day_hint_label: Label = %DayHintLabel
@onready var speed_button: Button = %SpeedButton

var _tower_buttons: Array[Button] = []
const SPEED_STEPS: Array[float] = [1.0, 2.0, 4.0]
var _speed_index: int = 0


func _ready() -> void:
	ResourceManager.scrap_changed.connect(_on_scrap_changed)
	ResourceManager.essence_changed.connect(_on_essence_changed)
	GameManager.base_damaged.connect(_on_base_damaged)
	GameManager.game_over.connect(_on_game_over)
	GameManager.phase_changed.connect(_on_phase_changed)
	game_over_panel.visible = false
	dawn_panel.visible = false
	day_hint_label.visible = false
	speed_button.pressed.connect(_on_speed_pressed)
	_setup_tower_buttons()


func _process(_delta: float) -> void:
	if GameManager.current_phase == GameManager.GamePhase.NIGHT:
		var remaining: float = max(GameManager.NIGHT_DURATION - GameManager.night_timer, 0.0)
		timer_label.text = "TIME: %d" % ceili(remaining)
	elif GameManager.current_phase == GameManager.GamePhase.DAY:
		timer_label.text = "PREP"


func set_stage_name(stage_name: String) -> void:
	stage_label.text = stage_name


func update_hero_hp(hp: float) -> void:
	hero_hp_label.text = "HERO: %d" % int(hp)


func show_dawn_cards(cards: Array[Dictionary]) -> void:
	for child in dawn_cards.get_children():
		child.queue_free()
	for card in cards:
		var btn := Button.new()
		btn.text = "%s\n%s" % [card["name"], card["desc"]]
		btn.custom_minimum_size = Vector2(180, 100)
		btn.add_theme_font_size_override("font_size", 14)
		var c: Dictionary = card
		btn.pressed.connect(func() -> void: _on_dawn_card_selected(c))
		dawn_cards.add_child(btn)
	dawn_panel.visible = true


func show_all_clear() -> void:
	game_over_panel.visible = true
	result_label.text = "ALL STAGES CLEAR!"


func _on_phase_changed(phase: GameManager.GamePhase) -> void:
	match phase:
		GameManager.GamePhase.DAY:
			phase_label.text = "[ DAY ]"
			tower_panel.visible = true
			day_hint_label.visible = true
			dawn_panel.visible = false
			game_over_panel.visible = false
		GameManager.GamePhase.NIGHT:
			phase_label.text = "[ NIGHT ]"
			tower_panel.visible = false
			day_hint_label.visible = false
		GameManager.GamePhase.DAWN:
			phase_label.text = "[ DAWN ]"
			tower_panel.visible = false
			day_hint_label.visible = false
			reset_speed()


func _on_dawn_card_selected(card: Dictionary) -> void:
	dawn_panel.visible = false
	dawn_card_picked.emit(card)


func _on_scrap_changed(amount: int) -> void:
	scrap_label.text = "SCRAP: %d" % amount


func _on_essence_changed(amount: int) -> void:
	essence_label.text = "ESSENCE: %d" % amount


func _on_base_damaged(remaining: float) -> void:
	base_hp_label.text = "BASE: %d" % int(remaining)


func _on_game_over() -> void:
	game_over_panel.visible = true
	result_label.text = "GAME OVER"


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
		_on_speed_pressed()


func _on_speed_pressed() -> void:
	_speed_index = (_speed_index + 1) % SPEED_STEPS.size()
	var spd: float = SPEED_STEPS[_speed_index]
	Engine.time_scale = spd
	speed_button.text = "x%d" % int(spd)


func reset_speed() -> void:
	_speed_index = 0
	Engine.time_scale = 1.0
	speed_button.text = "x1"


func _setup_tower_buttons() -> void:
	var towers: Array[Dictionary] = [
		{"name": "Fish Bone\n60", "path": "res://resources/towers/fish_bone.tres"},
		{"name": "Plasma\n80", "path": "res://resources/towers/plasma_laser.tres"},
		{"name": "Mjolnir\n100", "path": "res://resources/towers/mjolnir_coil.tres"},
	]
	for t in towers:
		var btn := Button.new()
		btn.text = t["name"]
		btn.custom_minimum_size = Vector2(90, 60)
		var tower_res: TowerData = load(t["path"])
		btn.pressed.connect(func() -> void: tower_selected.emit(tower_res))
		tower_panel.add_child(btn)
		_tower_buttons.append(btn)
