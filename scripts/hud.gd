extends CanvasLayer

@onready var scrap_label: Label = %ScrapLabel
@onready var essence_label: Label = %EssenceLabel
@onready var timer_label: Label = %TimerLabel
@onready var base_hp_label: Label = %BaseHpLabel
@onready var hero_hp_label: Label = %HeroHpLabel
@onready var stage_label: Label = %StageLabel
@onready var tower_panel: HBoxContainer = %TowerPanel
@onready var game_over_panel: Panel = %GameOverPanel
@onready var result_label: Label = %ResultLabel

var _tower_buttons: Array[Button] = []

signal tower_selected(tower_data: TowerData)


func _ready() -> void:
	ResourceManager.scrap_changed.connect(_on_scrap_changed)
	ResourceManager.essence_changed.connect(_on_essence_changed)
	GameManager.base_damaged.connect(_on_base_damaged)
	GameManager.game_over.connect(_on_game_over)
	game_over_panel.visible = false
	_setup_tower_buttons()


func _process(_delta: float) -> void:
	if GameManager.current_phase == GameManager.GamePhase.NIGHT:
		var remaining: float = max(GameManager.NIGHT_DURATION - GameManager.night_timer, 0.0)
		timer_label.text = "TIME: %d" % ceili(remaining)


func set_stage_name(name: String) -> void:
	stage_label.text = name


func update_hero_hp(hp: float) -> void:
	hero_hp_label.text = "HERO: %d" % int(hp)


func _on_scrap_changed(amount: int) -> void:
	scrap_label.text = "SCRAP: %d" % amount


func _on_essence_changed(amount: int) -> void:
	essence_label.text = "ESSENCE: %d" % amount


func _on_base_damaged(remaining: float) -> void:
	base_hp_label.text = "BASE: %d" % int(remaining)


func _on_game_over() -> void:
	game_over_panel.visible = true
	result_label.text = "GAME OVER"


func show_victory() -> void:
	game_over_panel.visible = true
	result_label.text = "STAGE CLEAR!"


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
