extends Node

signal scrap_changed(amount: int)
signal essence_changed(amount: int)
signal catnip_changed(amount: int)

const WAVE_CLEAR_BONUS: int = 20

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


func add_essence(amount: int) -> void:
	essence += amount


func add_wave_clear_bonus() -> void:
	scrap += WAVE_CLEAR_BONUS
