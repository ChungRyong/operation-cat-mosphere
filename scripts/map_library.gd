extends Node

const DAYS_PER_MAP: int = 20

var maps: Array[MapData] = []


func _ready() -> void:
	maps.append(_build_map_01())


func get_map(index: int) -> MapData:
	if index >= 0 and index < maps.size():
		return maps[index]
	return null


func get_map_count() -> int:
	return maps.size()


func _build_map_01() -> MapData:
	var m := MapData.new()
	m.map_name = "Living Room"
	m.map_id = 0
	m.starting_scrap = 200

	# 4 horizontal lanes converging to base at (1280,500)
	# P1 y≈300, P2 y≈120, P3 y≈500, P4 y≈650
	m.paths = [
		PackedVector2Array([Vector2(0, 300), Vector2(400, 260), Vector2(800, 300), Vector2(1280, 500)]),
		PackedVector2Array([Vector2(0, 120), Vector2(400, 90), Vector2(800, 120), Vector2(1280, 500)]),
		PackedVector2Array([Vector2(0, 500), Vector2(400, 530), Vector2(800, 500), Vector2(1280, 500)]),
		PackedVector2Array([Vector2(0, 650), Vector2(400, 670), Vector2(800, 650), Vector2(1280, 500)]),
	]
	m.path_unlock_days = [1, 5, 11, 16]

	# Slots placed ~100px above/below each path's lane
	m.slot_positions = [
		# Zone 1 (Day 1): flanking Path 1 (y≈300)
		Vector2(200, 200), Vector2(400, 200), Vector2(600, 200),  # above P1
		Vector2(200, 400), Vector2(400, 400), Vector2(600, 400),  # below P1
		# Zone 2 (Day 5): flanking Path 2 (y≈120)
		Vector2(150, 50), Vector2(400, 50),                       # above P2
		Vector2(800, 200), Vector2(1000, 200),                    # below P2, right side
		# Zone 3 (Day 11): flanking Path 3 (y≈500)
		Vector2(800, 400), Vector2(1000, 400),                    # above P3, right side
		Vector2(200, 580), Vector2(400, 580),                     # below P3
		# Zone 4 (Day 16): flanking Path 4 (y≈650)
		Vector2(600, 580), Vector2(800, 580),                     # above P4
		Vector2(400, 690),                                        # below P4
	]
	m.slot_unlock_days = [
		1, 1, 1, 1, 1, 1,
		5, 5, 5, 5,
		11, 11, 11, 11,
		16, 16, 16,
	]

	var BOSS_01: BossData = preload("res://resources/bosses/jelly_king.tres")
	var J: EnemyData = preload("res://resources/enemies/jelly_slime.tres")
	var C: EnemyData = preload("res://resources/enemies/jelly_carrier.tres")
	var L: EnemyData = preload("res://resources/enemies/laser_pointer.tres")
	var MR: EnemyData = preload("res://resources/enemies/mirror_craft.tres")
	var S: EnemyData = preload("res://resources/enemies/steel_can_gate.tres")

	# --- Days 1-4: Single path, introductory ---
	m.days.append(_day(100, [
		_wg(0, J, 15, 3.0, 0), _wg(50, J, 10, 2.5, 0)]))
	m.days.append(_day(100, [
		_wg(0, J, 20, 2.5, 0), _wg(55, J, 15, 2.0, 0)]))
	m.days.append(_day(110, [
		_wg(0, J, 20, 2.0, 0), _wg(45, C, 2, 5.0, 0), _wg(60, J, 10, 2.0, 0)]))
	m.days.append(_day(110, [
		_wg(0, J, 20, 2.0, 0), _wg(35, L, 3, 3.0, 0), _wg(50, J, 18, 1.7, 0)]))

	# --- Days 5-10: Two paths, mixed enemies ---
	m.days.append(_day(120, [
		_wg(0, J, 20, 2.0, 0), _wg(0, J, 15, 2.5, 1)]))
	m.days.append(_day(120, [
		_wg(0, J, 20, 2.0, 0), _wg(0, J, 15, 2.0, 1), _wg(45, C, 3, 4.0, 0)]))
	m.days.append(_day(130, [
		_wg(0, J, 15, 1.8, 0), _wg(0, J, 15, 1.8, 1), _wg(35, MR, 5, 5.0, 0)]))
	m.days.append(_day(130, [
		_wg(0, J, 20, 1.8, 0), _wg(0, J, 15, 2.0, 1),
		_wg(40, L, 3, 3.0, 1), _wg(60, S, 3, 4.0, 0)]))
	m.days.append(_day(140, [
		_wg(0, J, 25, 1.5, 0), _wg(0, J, 20, 1.5, 1),
		_wg(40, MR, 5, 4.0, 0), _wg(40, C, 3, 5.0, 1),
		_wg(80, S, 1, 0.0, 0)]))
	m.days.append(_day(140, [
		_wg(0, J, 25, 1.5, 0), _wg(0, J, 20, 1.5, 1),
		_wg(50, L, 5, 3.0, -1), _wg(70, S, 3, 4.0, 0)]))

	# --- Days 11-15: Three paths, heavy pressure ---
	m.days.append(_day(150, [
		_wg(0, J, 20, 1.5, 0), _wg(0, J, 15, 1.5, 1),
		_wg(0, J, 15, 2.0, 2), _wg(45, MR, 5, 4.0, -1)]))
	m.days.append(_day(150, [
		_wg(0, J, 20, 1.3, -1), _wg(30, C, 5, 4.0, 0),
		_wg(30, L, 5, 3.0, 1), _wg(60, J, 15, 1.5, 2)]))
	m.days.append(_day(160, [
		_wg(0, J, 25, 1.3, -1), _wg(35, MR, 5, 4.0, 0),
		_wg(35, S, 5, 4.0, 1), _wg(60, J, 15, 1.3, 2)]))
	m.days.append(_day(160, [
		_wg(0, J, 25, 1.2, -1), _wg(30, MR, 8, 3.0, 0),
		_wg(30, L, 5, 3.0, 1), _wg(55, J, 15, 1.2, 2),
		_wg(60, S, 2, 5.0, -1)]))
	m.days.append(_day(170, [
		_wg(0, J, 30, 1.2, -1), _wg(40, C, 5, 4.0, 0),
		_wg(40, S, 5, 4.0, 1), _wg(40, L, 3, 3.0, 2)]))

	# --- Days 16-20: Four paths, maximum intensity ---
	m.days.append(_day(180, [
		_wg(0, J, 20, 1.2, -1), _wg(30, MR, 5, 3.0, 0),
		_wg(30, L, 5, 3.0, 1), _wg(30, S, 5, 3.0, 2),
		_wg(30, C, 3, 4.0, 3)]))
	m.days.append(_day(180, [
		_wg(0, J, 30, 1.0, -1), _wg(35, MR, 8, 3.0, -1),
		_wg(60, S, 5, 3.0, 0), _wg(60, C, 5, 4.0, 1)]))
	m.days.append(_day(200, [
		_wg(0, J, 40, 1.0, -1), _wg(40, MR, 10, 2.5, -1),
		_wg(70, L, 5, 2.0, 2), _wg(70, S, 5, 3.0, 3)]))
	m.days.append(_day(200, [
		_wg(0, J, 30, 0.8, -1), _wg(30, MR, 8, 2.5, -1),
		_wg(30, C, 5, 4.0, -1), _wg(60, L, 5, 2.0, -1),
		_wg(60, S, 5, 3.0, -1)]))
	# Day 20: Boss wave
	var day20 := _day(220, [
		_wg(0, J, 30, 0.8, -1), _wg(20, MR, 8, 2.0, -1),
		_wg(20, S, 5, 3.0, -1)])
	day20.boss = BOSS_01
	m.days.append(day20)

	return m


func _day(scrap: int, groups: Array) -> DayData:
	var d := DayData.new()
	d.daily_scrap = scrap
	for g in groups:
		d.wave_groups.append(g)
	return d


func _wg(time: float, enemy: EnemyData, count: int, interval: float, path_idx: int) -> WaveGroupData:
	var w := WaveGroupData.new()
	w.spawn_time = time
	w.enemy = enemy
	w.count = count
	w.interval = interval
	w.path_index = path_idx
	return w
