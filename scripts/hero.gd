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
const BLOCK_RANGE: float = 50.0
const DISENGAGE_RANGE: float = 70.0
const AUTO_ATK_INTERVAL: float = 1.0
const AUTO_ATK_DAMAGE_MULT: float = 0.5
const MAX_BLOCK_COUNT: int = 3
const HIT_IFRAME: float = 0.5

const MAX_STAT_LEVEL: int = 5
const LEVEL_COST_BASE: int = 10
const LEVEL_COST_SCALE: int = 5
const HP_PER_LEVEL: float = 20.0
const ATK_PER_LEVEL: float = 3.0
const SPD_PER_LEVEL: float = 30.0

var max_hp: float = 100.0
var current_hp: float = 100.0
var ultimate_available: bool = true
var hp_level: int = 0
var atk_level: int = 0
var spd_level: int = 0

var _attack_timer: float = 0.0
var _punch_cd: float = 0.0
var _parry_cd: float = 0.0
var _parry_active: float = 0.0
var _invincible_timer: float = 0.0
var _auto_atk_timer: float = 0.0
var _blocked_count: int = 0
var _move_target: Vector2 = Vector2.ZERO
var _moving: bool = false
var _sprite: AnimatedSprite2D
var _current_anim: String = "idle"
const ARRIVAL_DISTANCE: float = 5.0

const SPRITE_DATA: Dictionary = {
	"idle": {"path": "res://assets/sprites/hero/cheese_cat_idle.png", "frames": 4, "fps": 4.0},
	"walk": {"path": "res://assets/sprites/hero/cheese_cat_walk.png", "frames": 3, "fps": 6.0},
	"punch": {"path": "res://assets/sprites/hero/cheese_cat_punch.png", "frames": 4, "fps": 12.0},
}


func _ready() -> void:
	current_hp = max_hp
	add_to_group("hero")
	GameManager.phase_changed.connect(_on_phase_changed)
	_setup_sprite()


func _physics_process(delta: float) -> void:
	if _moving and current_hp > 0.0:
		var diff: Vector2 = _move_target - global_position
		var speed: float = _get_move_speed()
		var step: float = speed * delta
		if diff.length() <= max(step, ARRIVAL_DISTANCE):
			_moving = false
			velocity = Vector2.ZERO
			global_position = _move_target
		else:
			velocity = diff.normalized() * speed
			if velocity.x != 0.0 and _sprite:
				_sprite.flip_h = velocity.x < 0.0
			move_and_slide()
	else:
		velocity = Vector2.ZERO

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

	if GameManager.current_phase == GameManager.GamePhase.NIGHT and current_hp > 0.0:
		_auto_atk_timer -= delta
		if _auto_atk_timer <= 0.0:
			if _auto_attack():
				_auto_atk_timer = AUTO_ATK_INTERVAL

	_update_animation()
	_update_sprite_modulate()
	queue_redraw()


func _punch() -> void:
	_punch_cd = PUNCH_COOLDOWN
	SfxManager.play("punch")
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
	SfxManager.play("parry")


func is_parrying() -> bool:
	return _parry_active > 0.0


func take_damage(amount: float) -> void:
	if _invincible_timer > 0.0:
		return
	if is_parrying():
		return
	current_hp -= amount
	_invincible_timer = HIT_IFRAME
	SfxManager.play("hero_hit")
	health_changed.emit(current_hp)
	if current_hp <= 0.0:
		current_hp = 0.0


func _use_ultimate() -> void:
	ultimate_available = false
	_invincible_timer = ULTIMATE_INVINCIBLE
	SfxManager.play("ultimate")
	var enemies: Array = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.has_method("take_damage"):
			enemy.take_damage(ULTIMATE_DAMAGE, TowerData.AttackType.MYSTIC)


func _setup_sprite() -> void:
	_sprite = $Sprite as AnimatedSprite2D
	if _sprite == null:
		return
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	for anim_name: String in SPRITE_DATA:
		var info: Dictionary = SPRITE_DATA[anim_name]
		sf.add_animation(anim_name)
		sf.set_animation_speed(anim_name, info["fps"])
		sf.set_animation_loop(anim_name, true)
		var tex: Texture2D = load(info["path"])
		var frame_count: int = info["frames"]
		var frame_w: int = 64
		var frame_h: int = 64
		for i in frame_count:
			var atlas := AtlasTexture.new()
			atlas.atlas = tex
			atlas.region = Rect2(i * frame_w, 0, frame_w, frame_h)
			sf.add_frame(anim_name, atlas)
	_sprite.sprite_frames = sf
	_sprite.play("idle")


func _update_animation() -> void:
	if _sprite == null:
		return
	var target_anim: String = "idle"
	if _punch_cd > PUNCH_COOLDOWN - 0.3:
		target_anim = "punch"
	elif _moving:
		target_anim = "walk"
	if target_anim != _current_anim:
		_current_anim = target_anim
		_sprite.play(_current_anim)


func _update_sprite_modulate() -> void:
	if _sprite == null:
		return
	if _invincible_timer > 0.0:
		_sprite.modulate.a = 0.7 + sin(Time.get_ticks_msec() * 0.01) * 0.3
	else:
		_sprite.modulate.a = 1.0


func _draw() -> void:
	if _parry_active > 0.0:
		draw_arc(Vector2.ZERO, 28.0, 0.0, TAU, 24, Color(0.3, 0.8, 1.0, 0.6), 3.0)

	if _blocked_count > 0:
		draw_arc(Vector2.ZERO, BLOCK_RANGE, 0.0, TAU, 24, Color(1.0, 0.4, 0.2, 0.3), 2.0)

	var bar_w: float = 40.0
	var bar_pos := Vector2(-bar_w * 0.5, -50.0)
	draw_rect(Rect2(bar_pos, Vector2(bar_w, 4.0)), Color(0.3, 0.0, 0.0, 1.0))
	var hp_ratio: float = clamp(current_hp / max_hp, 0.0, 1.0)
	draw_rect(Rect2(bar_pos, Vector2(bar_w * hp_ratio, 4.0)), Color(0.9, 0.2, 0.2, 1.0))


func get_level_cost(current_level: int) -> int:
	return LEVEL_COST_BASE + current_level * LEVEL_COST_SCALE


func level_up_hp() -> bool:
	if hp_level >= MAX_STAT_LEVEL:
		return false
	if not ResourceManager.spend_essence(get_level_cost(hp_level)):
		return false
	hp_level += 1
	max_hp = 100.0 + hp_level * HP_PER_LEVEL
	current_hp = max_hp
	health_changed.emit(current_hp)
	return true


func level_up_atk() -> bool:
	if atk_level >= MAX_STAT_LEVEL:
		return false
	if not ResourceManager.spend_essence(get_level_cost(atk_level)):
		return false
	atk_level += 1
	return true


func level_up_spd() -> bool:
	if spd_level >= MAX_STAT_LEVEL:
		return false
	if not ResourceManager.spend_essence(get_level_cost(spd_level)):
		return false
	spd_level += 1
	return true


func _get_atk() -> float:
	var atk: float = BASE_ATK + atk_level * ATK_PER_LEVEL + UpgradeManager.get_bonus("hero_atk")
	for buff in GameManager.active_buffs:
		if buff["type"] == "hero_atk":
			atk *= (1.0 + buff["value"])
	return atk


func _get_move_speed() -> float:
	var spd: float = BASE_MOVE_SPEED + spd_level * SPD_PER_LEVEL + UpgradeManager.get_bonus("hero_spd")
	for buff in GameManager.active_buffs:
		if buff["type"] == "hero_spd":
			spd *= (1.0 + buff["value"])
	return spd


func _auto_attack() -> bool:
	var enemies: Array = get_tree().get_nodes_in_group("enemies")
	var nearest: Node = null
	var nearest_dist: float = BLOCK_RANGE + 10.0
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var dist: float = global_position.distance_to(enemy.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy
	if nearest != null and nearest.has_method("take_damage"):
		var damage: float = _get_atk() * AUTO_ATK_DAMAGE_MULT
		nearest.take_damage(damage, TowerData.AttackType.LOW_TECH)
		return true
	return false


func move_to(target: Vector2) -> void:
	_move_target = target
	_moving = true


func can_block() -> bool:
	return current_hp > 0.0 and _blocked_count < MAX_BLOCK_COUNT


func add_blocked() -> void:
	_blocked_count += 1


func remove_blocked() -> void:
	_blocked_count = max(_blocked_count - 1, 0)


func reset_blocked() -> void:
	_blocked_count = 0


func reset_stats() -> void:
	hp_level = 0
	atk_level = 0
	spd_level = 0
	max_hp = 100.0 + UpgradeManager.get_bonus("hero_hp")
	current_hp = max_hp
	ultimate_available = true
	_attack_timer = 0.0
	_punch_cd = 0.0
	_parry_cd = 0.0
	_parry_active = 0.0
	_invincible_timer = 0.0
	_auto_atk_timer = 0.0
	_blocked_count = 0
	_moving = false
	velocity = Vector2.ZERO
	health_changed.emit(current_hp)


func _on_phase_changed(_phase: GameManager.GamePhase) -> void:
	if _phase != GameManager.GamePhase.NIGHT:
		reset_blocked()
