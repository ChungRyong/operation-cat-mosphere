extends Node

var _pool: Array[Node] = []
var _enemy_scene: PackedScene = preload("res://scenes/enemy/enemy.tscn")


func get_enemy() -> PathFollow2D:
	if not _pool.is_empty():
		return _pool.pop_back()
	return _enemy_scene.instantiate()


func return_enemy(enemy: PathFollow2D) -> void:
	if not is_instance_valid(enemy):
		return
	if enemy.has_method("_cleanup_for_pool"):
		enemy._cleanup_for_pool()
	if enemy.is_in_group("enemies"):
		enemy.remove_from_group("enemies")
	enemy.set_process(false)
	if enemy.get_parent() != null:
		enemy.get_parent().remove_child(enemy)
	_pool.append(enemy)


func return_all_active() -> void:
	var enemies: Array = get_tree().get_nodes_in_group("enemies").duplicate()
	for enemy in enemies:
		return_enemy(enemy)
