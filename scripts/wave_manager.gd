extends Node

signal wave_finished
signal all_enemies_dead

const JELLY_SLIME: EnemyData = preload("res://resources/enemies/jelly_slime.tres")
const JELLY_CARRIER: EnemyData = preload("res://resources/enemies/jelly_carrier.tres")
const LASER_POINTER: EnemyData = preload("res://resources/enemies/laser_pointer.tres")
const MIRROR_CRAFT: EnemyData = preload("res://resources/enemies/mirror_craft.tres")
const STEEL_CAN_GATE: EnemyData = preload("res://resources/enemies/steel_can_gate.tres")

var paths: Array[Path2D] = []
var _spawn_queue: Array = []
var _spawning: bool = false
var _stopped: bool = false
var _pending_groups: int = 0
var _elapsed: float = 0.0


func setup_stage(stage_index: int) -> void:
	_spawn_queue.clear()
	_spawning = false
	_stopped = false
	_pending_groups = 0

	match stage_index:
		0: _build_stage_1()
		1: _build_stage_2()
		2: _build_stage_3()
		3: _build_stage_4()
		4: _build_stage_5()


func start() -> void:
	_spawning = true
	_elapsed = 0.0
	_process_queue()


func _process(delta: float) -> void:
	if _spawning:
		_elapsed += delta


func stop() -> void:
	_stopped = true
	_spawning = false
	_pending_groups = 0


func _build_stage_1() -> void:
	_q(0.0, JELLY_SLIME, 20, 3.0, 0)
	_q(65.0, JELLY_SLIME, 20, 2.75, 0)


func _build_stage_2() -> void:
	_q(0.0, JELLY_SLIME, 25, 2.0, 0)
	_q(55.0, JELLY_SLIME, 15, 1.3, 0)
	_q(80.0, JELLY_CARRIER, 2, 3.0, 0)
	_q(90.0, JELLY_SLIME, 10, 3.0, 0)


func _build_stage_3() -> void:
	_q(0.0, JELLY_SLIME, 15, 1.7, 0)
	_q(30.0, LASER_POINTER, 2, 1.0, 0)
	_q(35.0, JELLY_SLIME, 25, 2.0, 0)
	_q(90.0, LASER_POINTER, 3, 1.0, 0)
	_q(95.0, JELLY_SLIME, 10, 2.5, 0)


func _build_stage_4() -> void:
	_q(0.0, JELLY_SLIME, 15, 2.0, 0)
	_q(35.0, MIRROR_CRAFT, 5, 5.0, 0)
	_q(65.0, MIRROR_CRAFT, 3, 4.0, 0)
	_q(65.0, JELLY_SLIME, 15, 1.7, 0)
	_q(95.0, MIRROR_CRAFT, 4, 6.0, 0)


func _build_stage_5() -> void:
	_q(0.0, JELLY_SLIME, 20, 2.0, -1)
	_q(45.0, JELLY_CARRIER, 3, 8.0, 0)
	_q(45.0, MIRROR_CRAFT, 4, 6.0, 1)
	_q(75.0, LASER_POINTER, 3, 7.0, -1)
	_q(100.0, STEEL_CAN_GATE, 3, 4.0, 1)
	_q(105.0, JELLY_SLIME, 10, 1.5, -1)


func _q(time: float, enemy: EnemyData, count: int, interval: float, path_index: int) -> void:
	_spawn_queue.append({
		"time": time,
		"enemy": enemy,
		"count": count,
		"interval": interval,
		"path_index": path_index,
	})


func _process_queue() -> void:
	var sorted_queue: Array = _spawn_queue.duplicate()
	sorted_queue.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["time"] < b["time"])

	for entry in sorted_queue:
		var wait_until: float = entry["time"]
		while _elapsed < wait_until:
			if _stopped:
				return
			await get_tree().process_frame
		_pending_groups += 1
		_spawn_group(entry)

	while _pending_groups > 0:
		if _stopped:
			return
		await get_tree().process_frame

	while not get_tree().get_nodes_in_group("enemies").is_empty():
		if _stopped:
			return
		await get_tree().process_frame

	_spawning = false
	wave_finished.emit()


func _spawn_group(entry: Dictionary) -> void:
	var enemy_data: EnemyData = entry["enemy"]
	var count: int = entry["count"]
	var interval: float = entry["interval"]
	var path_idx: int = entry["path_index"]

	for i in count:
		if _stopped:
			_pending_groups -= 1
			return
		_spawn_one(enemy_data, path_idx)
		if interval > 0.0 and i < count - 1:
			await get_tree().create_timer(interval).timeout
			if _stopped:
				_pending_groups -= 1
				return
	_pending_groups -= 1


func _spawn_one(enemy_data: EnemyData, path_index: int) -> void:
	var target_path: Path2D = _get_path(path_index)
	if target_path == null:
		return
	var enemy: PathFollow2D = EnemyPool.get_enemy()
	enemy.init_pooled(enemy_data)
	target_path.add_child(enemy)
	enemy.add_to_group("enemies")
	enemy.died.connect(_on_enemy_died)
	enemy.reached_end.connect(_on_enemy_reached_end)


func _get_path(index: int) -> Path2D:
	if paths.is_empty():
		return null
	if index < 0:
		return paths[randi() % paths.size()]
	if index < paths.size():
		return paths[index]
	return paths[0]


func _on_enemy_died(_enemy: Node, _reward: int) -> void:
	pass


func _on_enemy_reached_end(damage: float) -> void:
	GameManager.damage_base(damage)
