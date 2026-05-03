extends Resource
class_name MapData

@export var map_name: String = ""
@export var map_id: int = 0
@export var starting_scrap: int = 200

@export var paths: Array[PackedVector2Array] = []
@export var path_unlock_days: Array[int] = [1, 5, 11, 16]

@export var slot_positions: Array[Vector2] = []
@export var slot_unlock_days: Array[int] = []

@export var days: Array[DayData] = []


func get_active_path_count(day: int) -> int:
	var n: int = 0
	for unlock_day in path_unlock_days:
		if day >= unlock_day:
			n += 1
	return n


func get_active_paths(day: int) -> Array[PackedVector2Array]:
	var active: Array[PackedVector2Array] = []
	for i in paths.size():
		if i < path_unlock_days.size() and day >= path_unlock_days[i]:
			active.append(paths[i])
	return active


func get_available_slots(day: int) -> Array[Vector2]:
	var available: Array[Vector2] = []
	for i in slot_positions.size():
		if i < slot_unlock_days.size() and day >= slot_unlock_days[i]:
			available.append(slot_positions[i])
	return available


func get_day_data(day: int) -> DayData:
	if day >= 1 and day <= days.size():
		return days[day - 1]
	return null
