extends Node

signal scrap_changed(amount: int)
signal essence_changed(amount: int)
signal catnip_changed(amount: int)
signal gold_can_changed(amount: int)

const WAVE_CLEAR_BONUS: int = 20
const GOLD_PER_DAY_CLEAR: int = 5
const GOLD_PER_MAP_CLEAR: int = 50

var scrap: int = 0:
	set(value):
		scrap = value
		scrap_changed.emit(scrap)

var essence: int = 0:
	set(value):
		essence = value
		essence_changed.emit(essence)

var catnip: int = 0:
	set(value):
		catnip = value
		catnip_changed.emit(catnip)

var gold_can: int = 0:
	set(value):
		gold_can = value
		gold_can_changed.emit(gold_can)


func reset_for_map(starting_scrap_amount: int) -> void:
	scrap = starting_scrap_amount
	essence = 0


func add_daily_scrap(amount: int) -> void:
	scrap += amount


func can_afford_scrap(cost: int) -> bool:
	return scrap >= cost


func spend_scrap(amount: int) -> bool:
	if not can_afford_scrap(amount):
		return false
	scrap -= amount
	return true


func add_scrap(amount: int) -> void:
	scrap += amount


func can_afford_essence(cost: int) -> bool:
	return essence >= cost


func spend_essence(amount: int) -> bool:
	if not can_afford_essence(amount):
		return false
	essence -= amount
	return true


func add_essence(amount: int) -> void:
	essence += amount


func add_gold_can(amount: int) -> void:
	gold_can += amount


func can_afford_gold(cost: int) -> bool:
	return gold_can >= cost


func spend_gold(amount: int) -> bool:
	if not can_afford_gold(amount):
		return false
	gold_can -= amount
	return true


func add_wave_clear_bonus() -> void:
	scrap += WAVE_CLEAR_BONUS
