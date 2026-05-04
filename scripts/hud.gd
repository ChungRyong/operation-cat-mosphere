extends CanvasLayer

signal tower_selected(tower_data: TowerData)
signal dawn_card_picked(buff: Dictionary)
signal map_chosen(map_index: int)
signal retry_requested
signal menu_requested
signal tower_add_floor_requested(floor_data: TowerData)
signal tower_repair_requested
signal tower_sell_requested
signal hero_levelup_requested(stat: String)
signal lobby_play_requested
signal lobby_map_select_requested
signal lobby_upgrade_requested

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
var _map_status_labels: Array[Label] = []
var _map_back_btn: Button
var _retry_button: Button
var _menu_button: Button
var _tower_info_panel: Panel
var _tower_info_name: Label
var _tower_info_stats: Label
var _tower_floor_btns: Array[Button] = []
var _floor_tower_datas: Array[TowerData] = []
var _tower_repair_btn: Button
var _tower_sell_btn: Button
var _hero_panel: Panel
var _hero_stat_labels: Dictionary = {}
var _hero_stat_btns: Dictionary = {}
var _lobby_panel: Panel
var _lobby_gold_label: Label
var _upgrade_panel: Panel
var _upgrade_gold_label: Label
var _upgrade_items_container: VBoxContainer
var _upgrade_tab_buttons: Array[Button] = []
var _current_upgrade_tab: UpgradeManager.Category = UpgradeManager.Category.TOWER
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
	ResourceManager.gold_can_changed.connect(_on_gold_can_changed)
	_setup_tower_buttons()
	_setup_tower_info_panel()
	_setup_hero_panel()
	_setup_lobby_panel()
	_setup_upgrade_panel()
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


func set_build_mode(enabled: bool) -> void:
	tower_panel.visible = enabled
	_tower_info_panel.visible = _tower_info_panel.visible and enabled
	day_hint_label.text = "[B] Build Mode ON" if enabled else "[B] Build Mode"


func show_dawn_cards(cards: Array[Dictionary]) -> void:
	for child in dawn_cards.get_children():
		child.queue_free()
	for card in cards:
		var btn := Button.new()
		var stacks: int = BuffLibrary._get_buff_count(card["id"])
		var max_s: int = card["max_stacks"]
		btn.text = "%s (%d/%d)\n%s" % [card["name"], stacks, max_s, card["desc"]]
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
		var locked: bool = i > highest_unlocked
		_map_buttons[i].disabled = locked
		if locked:
			_map_status_labels[i].text = "LOCKED"
			_map_status_labels[i].label_settings.font_color = Color(0.5, 0.5, 0.5, 1.0)
		elif i < highest_unlocked:
			_map_status_labels[i].text = "CLEAR"
			_map_status_labels[i].label_settings.font_color = Color(0.3, 1.0, 0.3, 1.0)
		else:
			_map_status_labels[i].text = "NEW"
			_map_status_labels[i].label_settings.font_color = Color(1.0, 0.85, 0.3, 1.0)
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
			day_hint_label.text = "[B] Build Mode ON"
			dawn_panel.visible = false
			game_over_panel.visible = false
			_map_select_panel.visible = false
		GameManager.GamePhase.NIGHT:
			phase_label.text = "[ NIGHT ]"
			tower_panel.visible = false
			day_hint_label.visible = false
			_tower_info_panel.visible = false
			_hero_panel.visible = false
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
		int(tower.current_health), int(tower.get_effective_max_hp()),
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
	_tower_repair_btn.disabled = tower.current_health >= tower.get_effective_max_hp() or not ResourceManager.can_afford_scrap(tower.data.repair_cost)
	_tower_sell_btn.text = "Sell (%d)" % tower.get_sell_value()


func _setup_tower_info_panel() -> void:
	_tower_info_panel = Panel.new()
	_tower_info_panel.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	_tower_info_panel.offset_left = -310.0
	_tower_info_panel.offset_top = -120.0
	_tower_info_panel.offset_right = -20.0
	_tower_info_panel.offset_bottom = 120.0
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


func _setup_hero_panel() -> void:
	_hero_panel = Panel.new()
	_hero_panel.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	_hero_panel.offset_left = 20.0
	_hero_panel.offset_top = -90.0
	_hero_panel.offset_right = 220.0
	_hero_panel.offset_bottom = 90.0
	_hero_panel.visible = false
	add_child(_hero_panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 8.0
	vbox.offset_top = 8.0
	vbox.offset_right = -8.0
	vbox.offset_bottom = -8.0
	vbox.add_theme_constant_override("separation", 4)
	_hero_panel.add_child(vbox)

	var title := Label.new()
	title.text = "Hero Level Up"
	title.add_theme_font_size_override("font_size", 14)
	vbox.add_child(title)

	for stat in ["hp", "atk", "spd"]:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 6)
		vbox.add_child(hbox)
		var lbl := Label.new()
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.custom_minimum_size = Vector2(110, 0)
		hbox.add_child(lbl)
		_hero_stat_labels[stat] = lbl
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(70, 28)
		btn.add_theme_font_size_override("font_size", 11)
		var s: String = stat
		btn.pressed.connect(func() -> void: hero_levelup_requested.emit(s))
		hbox.add_child(btn)
		_hero_stat_btns[stat] = btn


func show_hero_panel(hero: CharacterBody2D) -> void:
	_hero_panel.visible = true
	update_hero_panel(hero)


func hide_hero_panel() -> void:
	_hero_panel.visible = false


func update_hero_panel(hero: CharacterBody2D) -> void:
	if hero == null:
		return
	var max_lv: int = hero.MAX_STAT_LEVEL
	_hero_stat_labels["hp"].text = "HP: %d  Lv %d/%d" % [int(hero.max_hp), hero.hp_level, max_lv]
	_hero_stat_labels["atk"].text = "ATK: %.0f  Lv %d/%d" % [hero._get_atk(), hero.atk_level, max_lv]
	_hero_stat_labels["spd"].text = "SPD: %.0f  Lv %d/%d" % [hero._get_move_speed(), hero.spd_level, max_lv]
	for stat in ["hp", "atk", "spd"]:
		var lv: int = hero.get(stat + "_level")
		if lv >= max_lv:
			_hero_stat_btns[stat].text = "MAX"
			_hero_stat_btns[stat].disabled = true
		else:
			var cost: int = hero.get_level_cost(lv)
			_hero_stat_btns[stat].text = "+(%d)" % cost
			_hero_stat_btns[stat].disabled = not ResourceManager.can_afford_essence(cost)


func _setup_lobby_panel() -> void:
	_lobby_panel = Panel.new()
	_lobby_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.08, 0.06, 0.14, 1.0)
	_lobby_panel.add_theme_stylebox_override("panel", bg_style)
	add_child(_lobby_panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.offset_left = -300.0
	vbox.offset_top = -160.0
	vbox.offset_right = 300.0
	vbox.offset_bottom = 160.0
	vbox.grow_horizontal = Control.GROW_DIRECTION_BOTH
	vbox.grow_vertical = Control.GROW_DIRECTION_BOTH
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	_lobby_panel.add_child(vbox)

	var title := Label.new()
	title.text = "CAT HQ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var title_settings := LabelSettings.new()
	title_settings.font_size = 36
	title_settings.font_color = Color(1.0, 0.85, 0.3, 1.0)
	title.label_settings = title_settings
	vbox.add_child(title)

	_lobby_gold_label = Label.new()
	_lobby_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var gold_settings := LabelSettings.new()
	gold_settings.font_size = 20
	gold_settings.font_color = Color(1.0, 0.75, 0.2, 1.0)
	_lobby_gold_label.label_settings = gold_settings
	vbox.add_child(_lobby_gold_label)

	var desc := Label.new()
	desc.text = "Gold Cans are earned by clearing days and maps.\nSpend them on permanent upgrades!"
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var desc_settings := LabelSettings.new()
	desc_settings.font_size = 14
	desc_settings.font_color = Color(0.7, 0.7, 0.7, 1.0)
	desc.label_settings = desc_settings
	vbox.add_child(desc)

	var btn_box := HBoxContainer.new()
	btn_box.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_box.add_theme_constant_override("separation", 16)
	vbox.add_child(btn_box)

	var play_btn := Button.new()
	play_btn.text = "Continue"
	play_btn.custom_minimum_size = Vector2(140, 50)
	play_btn.add_theme_font_size_override("font_size", 18)
	play_btn.pressed.connect(func() -> void: lobby_play_requested.emit())
	btn_box.add_child(play_btn)

	var map_btn := Button.new()
	map_btn.text = "Map Select"
	map_btn.custom_minimum_size = Vector2(140, 50)
	map_btn.add_theme_font_size_override("font_size", 18)
	map_btn.pressed.connect(func() -> void: lobby_map_select_requested.emit())
	btn_box.add_child(map_btn)

	var upgrade_btn := Button.new()
	upgrade_btn.text = "Upgrades"
	upgrade_btn.custom_minimum_size = Vector2(140, 50)
	upgrade_btn.add_theme_font_size_override("font_size", 18)
	upgrade_btn.pressed.connect(func() -> void: lobby_upgrade_requested.emit())
	btn_box.add_child(upgrade_btn)

	_lobby_panel.visible = false


func show_lobby() -> void:
	_lobby_panel.visible = true
	_lobby_gold_label.text = "Gold Cans: %d" % ResourceManager.gold_can
	game_over_panel.visible = false
	dawn_panel.visible = false
	tower_panel.visible = false
	_map_select_panel.visible = false
	_hero_panel.visible = false
	_tower_info_panel.visible = false
	_upgrade_panel.visible = false


func hide_lobby() -> void:
	_lobby_panel.visible = false


func _on_gold_can_changed(_amount: int) -> void:
	if _lobby_panel.visible:
		_lobby_gold_label.text = "Gold Cans: %d" % ResourceManager.gold_can
	if _upgrade_panel.visible:
		_upgrade_gold_label.text = "Gold Cans: %d" % ResourceManager.gold_can


func show_upgrade_panel() -> void:
	_upgrade_panel.visible = true
	_lobby_panel.visible = false
	_upgrade_gold_label.text = "Gold Cans: %d" % ResourceManager.gold_can
	_refresh_upgrade_items()


func hide_upgrade_panel() -> void:
	_upgrade_panel.visible = false


func _setup_upgrade_panel() -> void:
	_upgrade_panel = Panel.new()
	_upgrade_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.06, 0.05, 0.12, 1.0)
	_upgrade_panel.add_theme_stylebox_override("panel", bg_style)
	add_child(_upgrade_panel)

	var outer := VBoxContainer.new()
	outer.set_anchors_preset(Control.PRESET_CENTER)
	outer.offset_left = -350.0
	outer.offset_top = -240.0
	outer.offset_right = 350.0
	outer.offset_bottom = 240.0
	outer.grow_horizontal = Control.GROW_DIRECTION_BOTH
	outer.grow_vertical = Control.GROW_DIRECTION_BOTH
	outer.alignment = BoxContainer.ALIGNMENT_BEGIN
	outer.add_theme_constant_override("separation", 12)
	_upgrade_panel.add_child(outer)

	var title := Label.new()
	title.text = "UPGRADES"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var title_settings := LabelSettings.new()
	title_settings.font_size = 28
	title_settings.font_color = Color(1.0, 0.85, 0.3, 1.0)
	title.label_settings = title_settings
	outer.add_child(title)

	_upgrade_gold_label = Label.new()
	_upgrade_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var gold_settings := LabelSettings.new()
	gold_settings.font_size = 18
	gold_settings.font_color = Color(1.0, 0.75, 0.2, 1.0)
	_upgrade_gold_label.label_settings = gold_settings
	outer.add_child(_upgrade_gold_label)

	var tab_box := HBoxContainer.new()
	tab_box.alignment = BoxContainer.ALIGNMENT_CENTER
	tab_box.add_theme_constant_override("separation", 8)
	outer.add_child(tab_box)

	var tab_names: Array[String] = ["Tower", "Hero", "Economy"]
	var tab_cats: Array[UpgradeManager.Category] = [
		UpgradeManager.Category.TOWER,
		UpgradeManager.Category.HERO,
		UpgradeManager.Category.ECONOMY,
	]
	for i in tab_names.size():
		var btn := Button.new()
		btn.text = tab_names[i]
		btn.custom_minimum_size = Vector2(100, 36)
		btn.add_theme_font_size_override("font_size", 14)
		var cat: UpgradeManager.Category = tab_cats[i]
		btn.pressed.connect(func() -> void: _on_upgrade_tab(cat))
		tab_box.add_child(btn)
		_upgrade_tab_buttons.append(btn)

	_upgrade_items_container = VBoxContainer.new()
	_upgrade_items_container.add_theme_constant_override("separation", 8)
	outer.add_child(_upgrade_items_container)

	var back_box := HBoxContainer.new()
	back_box.alignment = BoxContainer.ALIGNMENT_CENTER
	outer.add_child(back_box)

	var back_btn := Button.new()
	back_btn.text = "Back to HQ"
	back_btn.custom_minimum_size = Vector2(140, 40)
	back_btn.add_theme_font_size_override("font_size", 14)
	back_btn.pressed.connect(func() -> void:
		_upgrade_panel.visible = false
		show_lobby()
	)
	back_box.add_child(back_btn)

	_upgrade_panel.visible = false


func _on_upgrade_tab(cat: UpgradeManager.Category) -> void:
	_current_upgrade_tab = cat
	_refresh_upgrade_items()


func _refresh_upgrade_items() -> void:
	for child in _upgrade_items_container.get_children():
		child.queue_free()

	var upgrades: Array = UpgradeManager.get_upgrades_for_category(_current_upgrade_tab)
	for upg in upgrades:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 12)
		_upgrade_items_container.add_child(hbox)

		var info := Label.new()
		var lv: int = UpgradeManager.get_level(upg["id"])
		var max_lv: int = UpgradeManager.MAX_LEVEL
		info.text = "%s  (%s)  Lv %d/%d" % [upg["name"], upg["desc"], lv, max_lv]
		info.custom_minimum_size = Vector2(320, 0)
		var info_settings := LabelSettings.new()
		info_settings.font_size = 15
		info_settings.font_color = Color(0.9, 0.9, 0.9, 1.0)
		info.label_settings = info_settings
		hbox.add_child(info)

		var bar := _create_level_bar(lv, max_lv)
		hbox.add_child(bar)

		var btn := Button.new()
		btn.custom_minimum_size = Vector2(110, 32)
		btn.add_theme_font_size_override("font_size", 13)
		var cost: int = UpgradeManager.get_cost(upg["id"])
		if cost < 0:
			btn.text = "MAX"
			btn.disabled = true
		else:
			btn.text = "Buy (%d)" % cost
			btn.disabled = not ResourceManager.can_afford_gold(cost)
		var uid: String = upg["id"]
		btn.pressed.connect(func() -> void: _on_upgrade_buy(uid))
		hbox.add_child(btn)

	for i in _upgrade_tab_buttons.size():
		var cat_val: int = [
			UpgradeManager.Category.TOWER,
			UpgradeManager.Category.HERO,
			UpgradeManager.Category.ECONOMY,
		][i]
		_upgrade_tab_buttons[i].disabled = (cat_val == _current_upgrade_tab)


func _create_level_bar(current: int, max_val: int) -> HBoxContainer:
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 3)
	for i in max_val:
		var block := ColorRect.new()
		block.custom_minimum_size = Vector2(16, 16)
		if i < current:
			block.color = Color(0.3, 1.0, 0.5, 1.0)
		else:
			block.color = Color(0.3, 0.3, 0.3, 0.5)
		bar.add_child(block)
	return bar


func _on_upgrade_buy(id: String) -> void:
	UpgradeManager.purchase(id)
	_upgrade_gold_label.text = "Gold Cans: %d" % ResourceManager.gold_can
	_refresh_upgrade_items()


func _setup_map_select_panel() -> void:
	_map_select_panel = Panel.new()
	_map_select_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.06, 0.04, 0.1, 1.0)
	_map_select_panel.add_theme_stylebox_override("panel", bg_style)
	add_child(_map_select_panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.offset_left = -400.0
	vbox.offset_top = -200.0
	vbox.offset_right = 400.0
	vbox.offset_bottom = 200.0
	vbox.grow_horizontal = Control.GROW_DIRECTION_BOTH
	vbox.grow_vertical = Control.GROW_DIRECTION_BOTH
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	_map_select_panel.add_child(vbox)

	var title := Label.new()
	title.text = "WORLD MAP"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var title_settings := LabelSettings.new()
	title_settings.font_size = 28
	title_settings.font_color = Color(1.0, 0.85, 0.3, 1.0)
	title.label_settings = title_settings
	vbox.add_child(title)

	var gold_label := Label.new()
	gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var gold_settings := LabelSettings.new()
	gold_settings.font_size = 16
	gold_settings.font_color = Color(1.0, 0.75, 0.2, 1.0)
	gold_label.label_settings = gold_settings
	gold_label.text = "Gold Cans: %d" % ResourceManager.gold_can
	ResourceManager.gold_can_changed.connect(func(amt: int) -> void:
		gold_label.text = "Gold Cans: %d" % amt)
	vbox.add_child(gold_label)

	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	vbox.add_child(grid)

	var map_names: Array[String] = [
		"Living Room", "Backyard", "Basement", "Cat Tower Lab",
		"Kitchen", "Playground", "Rainy Roof", "Cat Cafe",
		"Subway", "Convenience Store", "Alien Mothership", "Moon Base",
	]
	var map_count: int = maxi(MapLibrary.get_map_count(), map_names.size())
	for i in map_count:
		var map_data: MapData = MapLibrary.get_map(i)
		var map_name: String = map_data.map_name if map_data else map_names[i] if i < map_names.size() else "???"

		var card := VBoxContainer.new()
		card.add_theme_constant_override("separation", 4)
		grid.add_child(card)

		var btn := Button.new()
		btn.text = "Map %d\n%s" % [i + 1, map_name]
		btn.custom_minimum_size = Vector2(160, 60)
		btn.add_theme_font_size_override("font_size", 13)
		var idx: int = i
		btn.pressed.connect(func() -> void:
			_map_select_panel.visible = false
			map_chosen.emit(idx)
		)
		card.add_child(btn)
		_map_buttons.append(btn)

		var status := Label.new()
		status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var status_settings := LabelSettings.new()
		status_settings.font_size = 11
		status.label_settings = status_settings
		card.add_child(status)
		_map_status_labels.append(status)

	var back_box := HBoxContainer.new()
	back_box.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(back_box)

	_map_back_btn = Button.new()
	_map_back_btn.text = "Back to HQ"
	_map_back_btn.custom_minimum_size = Vector2(140, 40)
	_map_back_btn.add_theme_font_size_override("font_size", 14)
	_map_back_btn.pressed.connect(func() -> void:
		_map_select_panel.visible = false
		menu_requested.emit()
	)
	back_box.add_child(_map_back_btn)

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
