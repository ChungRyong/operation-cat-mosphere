extends Area2D

var _target: Node2D = null
var _damage: float = 0.0
var _speed: float = 500.0
var _attack_type: TowerData.AttackType = TowerData.AttackType.LOW_TECH
var _is_crit: bool = false
var _stun_duration: float = 0.0
var _source_tower: Node2D = null


func launch(target: Node2D, damage: float, speed: float, attack_type: TowerData.AttackType, is_crit: bool, stun_duration: float = 0.0, source: Node2D = null) -> void:
	_target = target
	_damage = damage
	_speed = speed
	_attack_type = attack_type
	_is_crit = is_crit
	_stun_duration = stun_duration
	_source_tower = source


func _process(delta: float) -> void:
	if not is_instance_valid(_target) or not _target.is_inside_tree():
		queue_free()
		return
	var dir: Vector2 = global_position.direction_to(_target.global_position)
	global_position += dir * _speed * delta
	if global_position.distance_to(_target.global_position) < 10.0:
		_hit_target()


func _hit_target() -> void:
	if not is_instance_valid(_target) or not _target.is_inside_tree():
		queue_free()
		return

	if _target.has_method("take_damage"):
		if _target.data != null and DamageCalculator.is_reflected(_attack_type, _target.data.defense_type):
			var reflect_dmg: float = DamageCalculator.get_reflect_damage(_damage, _attack_type, _target.data.defense_type)
			if is_instance_valid(_source_tower) and _source_tower.has_method("take_damage"):
				_source_tower.take_damage(reflect_dmg)
		else:
			_target.take_damage(_damage, _attack_type)
			if _stun_duration > 0.0 and _target.has_method("apply_stun"):
				_target.apply_stun(_stun_duration)
	queue_free()


func _draw() -> void:
	var color: Color
	match _attack_type:
		TowerData.AttackType.LOW_TECH:
			color = Color(0.8, 0.6, 0.3, 1.0)
		TowerData.AttackType.HI_TECH:
			color = Color(0.3, 0.7, 1.0, 1.0)
		TowerData.AttackType.MYSTIC:
			color = Color(0.8, 0.4, 1.0, 1.0)
		_:
			color = Color.WHITE
	var size: float = 6.0 if _is_crit else 4.0
	draw_circle(Vector2.ZERO, size, color)
