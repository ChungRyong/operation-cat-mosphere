extends CharacterBody2D

signal health_changed(hp: float)

const BASE_MOVE_SPEED: float = 300.0
const BASE_ATK: float = 10.0
const ATTACK_SPEED: float = 1.2
const ATTACK_RANGE: float = 60.0
const PUNCH_MULTIPLIER: float = 2.0
const PUNCH_COOLDOWN: float = 0.5
const PARRY_WINDOW: float = 0.3
const PARRY_REFLECT_MULT: float = 1.5
const PARRY_COOLDOWN: float = 3.0
const ULTIMATE_DAMAGE: float = 100.0
const ULTIMATE_INVINCIBLE: float = 5.0

var max_hp: float = 100.0
var current_hp: float = 100.0
var ultimate_available: bool = true

var _attack_timer: float = 0.0
var _punch_cd: float = 0.0
var _parry_cd: float = 0.0
var _parry_active: float = 0.0
var _invincible_timer: float = 0.0


func _ready() -> void:
	current_hp = max_hp
	add_to_group("hero")


func _physics_process(delta: float) -> void:
	var input_dir := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	velocity = input_dir.normalized() * _get_move_speed()
	move_and_slide()

	_attack_timer -= delta
	_punch_cd -= delta
	_parry_cd -= delta
	_invincible_timer -= delta

	if _parry_active > 0.0:
		_parry_active -= delta

	if Input.is_action_just_pressed("attack") and _punch_cd <= 0.0:
		_punch()
	if Input.is_action_just_pressed("parry") and _parry_cd <= 0.0:
		_start_parry()
	if Input.is_action_just_pressed("ultimate") and ultimate_available:
		_use_ultimate()

	queue_redraw()


func _punch() -> void:
	_punch_cd = PUNCH_COOLDOWN
	var damage: float = _get_atk() * PUNCH_MULTIPLIER
	var enemies: Array = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if global_position.distance_to(enemy.global_position) <= ATTACK_RANGE:
			if enemy.has_method("take_damage"):
				enemy.take_damage(damage, TowerData.AttackType.LOW_TECH)


func _start_parry() -> void:
	_parry_cd = PARRY_COOLDOWN
	_parry_active = PARRY_WINDOW


func is_parrying() -> bool:
	return _parry_active > 0.0


func take_damage(amount: float) -> void:
	if _invincible_timer > 0.0:
		return
	if is_parrying():
		return
	current_hp -= amount
	health_changed.emit(current_hp)
	if current_hp <= 0.0:
		current_hp = 0.0


func _use_ultimate() -> void:
	ultimate_available = false
	_invincible_timer = ULTIMATE_INVINCIBLE
	var enemies: Array = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.has_method("take_damage"):
			enemy.take_damage(ULTIMATE_DAMAGE, TowerData.AttackType.MYSTIC)


func _draw() -> void:
	var body_color := Color(1.0, 0.85, 0.3, 1.0)
	if _invincible_timer > 0.0:
		body_color = Color(1.0, 1.0, 0.8, 0.7 + sin(Time.get_ticks_msec() * 0.01) * 0.3)
	draw_circle(Vector2.ZERO, 18.0, body_color)
	draw_circle(Vector2(0, -6), 8.0, Color(1.0, 1.0, 1.0, 1.0))
	draw_circle(Vector2(-6, 6), 5.0, Color(1.0, 1.0, 1.0, 1.0))
	draw_circle(Vector2(6, 6), 5.0, Color(1.0, 1.0, 1.0, 1.0))

	if _parry_active > 0.0:
		draw_arc(Vector2.ZERO, 28.0, 0.0, TAU, 24, Color(0.3, 0.8, 1.0, 0.6), 3.0)

	var bar_w: float = 40.0
	var bar_pos := Vector2(-bar_w * 0.5, -34.0)
	draw_rect(Rect2(bar_pos, Vector2(bar_w, 4.0)), Color(0.3, 0.0, 0.0, 1.0))
	var hp_ratio: float = clamp(current_hp / max_hp, 0.0, 1.0)
	draw_rect(Rect2(bar_pos, Vector2(bar_w * hp_ratio, 4.0)), Color(0.9, 0.2, 0.2, 1.0))


func _get_atk() -> float:
	var atk: float = BASE_ATK
	for buff in GameManager.active_buffs:
		if buff["type"] == "hero_atk":
			atk *= (1.0 + buff["value"])
	return atk


func _get_move_speed() -> float:
	var spd: float = BASE_MOVE_SPEED
	for buff in GameManager.active_buffs:
		if buff["type"] == "hero_spd":
			spd *= (1.0 + buff["value"])
	return spd
