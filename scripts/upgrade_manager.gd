extends Node

signal upgrade_changed

const MAX_LEVEL: int = 5
const SAVE_PATH: String = "user://upgrades.cfg"

enum Category { TOWER, HERO, ECONOMY }

var _upgrades: Dictionary = {}
var _levels: Dictionary = {}


func _ready() -> void:
	_define_upgrades()
	_load()


func _define_upgrades() -> void:
	_register("tower_hp", Category.TOWER, "Tower HP", "+10%/lv", 0.10, [10, 20, 30, 40, 50])
	_register("tower_atk", Category.TOWER, "Tower ATK", "+8%/lv", 0.08, [10, 20, 30, 40, 50])
	_register("tower_range", Category.TOWER, "Tower Range", "+5%/lv", 0.05, [15, 25, 35, 45, 55])
	_register("hero_hp", Category.HERO, "Hero HP", "+15/lv", 15.0, [10, 20, 30, 40, 50])
	_register("hero_atk", Category.HERO, "Hero ATK", "+2/lv", 2.0, [10, 20, 30, 40, 50])
	_register("hero_spd", Category.HERO, "Hero SPD", "+20/lv", 20.0, [15, 25, 35, 45, 55])
	_register("econ_scrap", Category.ECONOMY, "Start Scrap", "+20/lv", 20.0, [10, 15, 20, 25, 30])
	_register("econ_wave", Category.ECONOMY, "Wave Bonus", "+5/lv", 5.0, [15, 25, 35, 45, 55])


func _register(id: String, cat: Category, display_name: String, desc: String, per_level: float, costs: Array) -> void:
	_upgrades[id] = {
		"id": id,
		"category": cat,
		"name": display_name,
		"desc": desc,
		"per_level": per_level,
		"costs": costs,
	}
	_levels[id] = 0


func get_level(id: String) -> int:
	return _levels.get(id, 0)


func get_cost(id: String) -> int:
	var lv: int = get_level(id)
	if lv >= MAX_LEVEL:
		return -1
	var costs: Array = _upgrades[id]["costs"]
	return costs[lv]


func get_bonus(id: String) -> float:
	return _upgrades[id]["per_level"] * get_level(id)


func get_mult_bonus(id: String) -> float:
	return 1.0 + _upgrades[id]["per_level"] * get_level(id)


func get_upgrades_for_category(cat: Category) -> Array:
	var result: Array = []
	for id in _upgrades:
		if _upgrades[id]["category"] == cat:
			result.append(_upgrades[id])
	return result


func purchase(id: String) -> bool:
	var cost: int = get_cost(id)
	if cost < 0:
		return false
	if not ResourceManager.spend_gold(cost):
		return false
	_levels[id] += 1
	_save()
	GameManager.save_progress()
	upgrade_changed.emit()
	return true


func _save() -> void:
	var cfg := ConfigFile.new()
	for id in _levels:
		cfg.set_value("upgrades", id, _levels[id])
	cfg.save(SAVE_PATH)


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	for id in _levels:
		if cfg.has_section_key("upgrades", id):
			_levels[id] = cfg.get_value("upgrades", id, 0)
