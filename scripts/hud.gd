extends CanvasLayer

signal tower_selected(tower_data: TowerData)
signal dawn_card_picked(buff: Dictionary)
signal map_chosen(map_index: int)
signal retry_requested
signal menu_requested
signal tower_add_floor_requested(floor_data: TowerData)
signal tower_repair_requested
signal tower_sell_requested

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
var _map_select_panel: Panel
var _map_buttons: Array[Button] = []
var _retry_button: Button
var _menu_button: Button
var _tower_info_panel: Panel
var _tower_info_name: Label
var _tower_info_stats: Label
var _tower_floor_btns: Array[Button] = []
var _floor_tower_datas: Array[TowerData] = []
var _tower_repair_btn: Button
var _tower_sell_btn: Button
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
	_setup_tower_info_panel()
	_setup_map_select_panel()
	_setup_gameover_buttons()


func _process(_delta: float) -> void:
	if GameManager.current_phase == GameManager.GamePhase.NIGHT:
		var remaining: float = max(GameManager.NIGHT_DURATION - GameManager.night_timer, 0.0)
		timer_label.text = "TIME: %d" % ceili(remaining)
	elif GameManager.current_phase == GameManager.GamePhase.DAY:
		timer_label.text = "PREP"


func set_day_label(text: String) -> void:
	stage_label.text = text


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


func show_map_clear() -> void:
	game_over_panel.visible = true
	result_label.text = "MAP CLEAR!"
	_retry_button.visible = false
	_menu_button.visible = true


func show_map_select(highest_unlocked: int) -> void:
	for i in _map_buttons.size():
		_map_buttons[i].disabled = i > highest_unlocked
	_map_select_panel.visible = true
	game_over_panel.visible = false
	dawn_panel.visible = false
	tower_panel.visible = false
	day_hint_label.visible = false


func _on_phase_changed(phase: GameManager.GamePhase) -> void:
	match phase:
		GameManager.GamePhase.MENU:
			phase_label.text = ""
			tower_panel.visible = false
			day_hint_label.visible = false
			dawn_panel.visible = false
			game_over_panel.visible = false
		GameManager.GamePhase.DAY:
			phase_label.text = "[ DAY ]"
			tower_panel.visible = true
			day_hint_label.visible = true
			dawn_panel.visible = false
			game_over_panel.visible = false
			_map_select_panel.visible = false
		GameManager.GamePhase.NIGHT:
			phase_label.text = "[ NIGHT ]"
			tower_panel.visible = false
			day_hint_label.visible = false
			_tower_info_panel.visible = false
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
	result_label.text = "GAME OVER — Day %d/%d" % [GameManager.current_day, GameManager.DAYS_PER_MAP]
	_retry_button.visible = true
	_menu_button.visible = true


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


func show_tower_info(tower: Node2D) -> void:
	_tower_info_panel.visible = true
	update_tower_info(tower)


func hide_tower_info() -> void:
	_tower_info_panel.visible = false


func update_tower_info(tower: Node2D) -> void:
	if tower == null or tower.data == null:
		return
	_tower_info_name.text = "%s  Floor: %d/5" % [tower.data.tower_name, tower.floor_level]
	_tower_info_stats.text = "HP: %d/%d   DPS: %.1f   Range: %d" % [
		int(tower.current_health), int(tower.data.max_health),
		tower.get_total_dps(),
		int(tower.get_max_range())]
	if tower.floor_level < 5:
		for i in _tower_floor_btns.size():
			var td: TowerData = _floor_tower_datas[i]
			var cost: int = tower.get_add_floor_cost(td)
			_tower_floor_btns[i].text = "+%s (%d)" % [td.tower_name, cost]
			_tower_floor_btns[i].disabled = not ResourceManager.can_afford_scrap(cost)
			_tower_floor_btns[i].visible = true
	else:
		for btn in _tower_floor_btns:
			btn.visible = false
	_tower_repair_btn.text = "Repair (%d)" % tower.data.repair_cost
	_tower_repair_btn.disabled = tower.current_health >= tower.data.max_health or not ResourceManager.can_afford_scrap(tower.data.repair_cost)
	_tower_sell_btn.text = "Sell (%d)" % tower.get_sell_value()


func _setup_tower_info_panel() -> void:
	_tower_info_panel = Panel.new()
	_tower_info_panel.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	_tower_info_panel.offset_left = -280.0
	_tower_info_panel.offset_top = -110.0
	_tower_info_panel.offset_right = -10.0
	_tower_info_panel.offset_bottom = 110.0
	_tower_info_panel.visible = false
	add_child(_tower_info_panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 8.0
	vbox.offset_top = 8.0
	vbox.offset_right = -8.0
	vbox.offset_bottom = -8.0
	vbox.add_theme_constant_override("separation", 6)
	_tower_info_panel.add_child(vbox)

	_tower_info_name = Label.new()
	_tower_info_name.add_theme_font_size_override("font_size", 14)
	vbox.add_child(_tower_info_name)

	_tower_info_stats = Label.new()
	_tower_info_stats.add_theme_font_size_override("font_size", 12)
	vbox.add_child(_tower_info_stats)

	var floor_label := Label.new()
	floor_label.text = "Add Floor:"
	floor_label.add_theme_font_size_override("font_size", 11)
	vbox.add_child(floor_label)

	var floor_box := HBoxContainer.new()
	floor_box.add_theme_constant_override("separation", 4)
	vbox.add_child(floor_box)

	var tower_paths: Array[String] = [
		"res://resources/towers/fish_bone.tres",
		"res://resources/towers/plasma_laser.tres",
		"res://resources/towers/mjolnir_coil.tres",
	]
	for path in tower_paths:
		var tower_res: TowerData = load(path)
		_floor_tower_datas.append(tower_res)
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(80, 30)
		btn.add_theme_font_size_override("font_size", 10)
		var td: TowerData = tower_res
		btn.pressed.connect(func() -> void: tower_add_floor_requested.emit(td))
		floor_box.add_child(btn)
		_tower_floor_btns.append(btn)

	var action_box := HBoxContainer.new()
	action_box.add_theme_constant_override("separation", 6)
	vbox.add_child(action_box)

	_tower_repair_btn = Button.new()
	_tower_repair_btn.custom_minimum_size = Vector2(80, 30)
	_tower_repair_btn.add_theme_font_size_override("font_size", 12)
	_tower_repair_btn.pressed.connect(func() -> void: tower_repair_requested.emit())
	action_box.add_child(_tower_repair_btn)

	_tower_sell_btn = Button.new()
	_tower_sell_btn.custom_minimum_size = Vector2(80, 30)
	_tower_sell_btn.add_theme_font_size_override("font_size", 12)
	_tower_sell_btn.pressed.connect(func() -> void: tower_sell_requested.emit())
	action_box.add_child(_tower_sell_btn)


func _setup_map_select_panel() -> void:
	_map_select_panel = Panel.new()
	_map_select_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.06, 0.04, 0.1, 1.0)
	_map_select_panel.add_theme_stylebox_override("panel", bg_style)
	add_child(_map_select_panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.offset_left = -320.0
	vbox.offset_top = -120.0
	vbox.offset_right = 320.0
	vbox.offset_bottom = 120.0
	vbox.grow_horizontal = Control.GROW_DIRECTION_BOTH
	vbox.grow_vertical = Control.GROW_DIRECTION_BOTH
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 24)
	_map_select_panel.add_child(vbox)

	var title := Label.new()
	title.text = "OPERATION CAT-MOSPHERE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var title_settings := LabelSettings.new()
	title_settings.font_size = 32
	title_settings.font_color = Color(1.0, 0.85, 0.3, 1.0)
	title.label_settings = title_settings
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Select Battlefield"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var sub_settings := LabelSettings.new()
	sub_settings.font_size = 18
	sub_settings.font_color = Color(0.8, 0.8, 0.8, 1.0)
	subtitle.label_settings = sub_settings
	vbox.add_child(subtitle)

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 12)
	vbox.add_child(hbox)

	var map_count: int = MapLibrary.get_map_count()
	for i in map_count:
		var map_data: MapData = MapLibrary.get_map(i)
		var btn := Button.new()
		btn.text = "Map %d\n%s" % [i + 1, map_data.map_name if map_data else "???"]
		btn.custom_minimum_size = Vector2(140, 60)
		btn.add_theme_font_size_override("font_size", 14)
		var idx: int = i
		btn.pressed.connect(func() -> void:
			_map_select_panel.visible = false
			map_chosen.emit(idx)
		)
		hbox.add_child(btn)
		_map_buttons.append(btn)

	_map_select_panel.visible = false


func _setup_gameover_buttons() -> void:
	game_over_panel.offset_left = -160.0
	game_over_panel.offset_top = -80.0
	game_over_panel.offset_right = 160.0
	game_over_panel.offset_bottom = 80.0

	result_label.anchor_bottom = 0.55

	var hbox := HBoxContainer.new()
	hbox.layout_mode = 1
	hbox.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hbox.offset_top = -48.0
	hbox.offset_left = 10.0
	hbox.offset_right = -10.0
	hbox.offset_bottom = -10.0
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 12)
	game_over_panel.add_child(hbox)

	_retry_button = Button.new()
	_retry_button.text = "Retry"
	_retry_button.custom_minimum_size = Vector2(110, 36)
	_retry_button.pressed.connect(func() -> void: retry_requested.emit())
	hbox.add_child(_retry_button)

	_menu_button = Button.new()
	_menu_button.text = "Map Select"
	_menu_button.custom_minimum_size = Vector2(110, 36)
	_menu_button.pressed.connect(func() -> void: menu_requested.emit())
	hbox.add_child(_menu_button)
