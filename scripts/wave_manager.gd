extends Node

signal wave_finished

var paths: Array[Path2D] = []
var _spawn_queue: Array = []
var _spawning: bool = false
var _stopped: bool = false
var _pending_groups: int = 0
var _elapsed: float = 0.0


func setup_day(day_data: DayData) -> void:
	_spawn_queue.clear()
	_spawning = false
	_stopped = false
	_pending_groups = 0
	if day_data == null:
		return
	for wg in day_data.wave_groups:
		_spawn_queue.append({
			"time": wg.spawn_time,
			"enemy": wg.enemy,
			"count": wg.count,
			"interval": wg.interval,
			"path_index": wg.path_index,
		})


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
