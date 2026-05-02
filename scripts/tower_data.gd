extends Resource
class_name TowerData

enum AttackType { LOW_TECH, HI_TECH, MYSTIC }

@export var tower_name: String = ""
@export var attack_type: AttackType = AttackType.LOW_TECH
@export var max_health: float = 150.0
@export var damage: float = 5.0
@export var fire_rate: float = 2.0
@export var attack_range: float = 10.0
@export var build_cost: int = 60
@export var repair_cost: int = 20
@export var projectile_speed: float = 500.0
@export var color: Color = Color(0.6, 0.4, 0.2, 1.0)
@export var stun_duration: float = 0.0
@export var stun_cooldown: float = 0.0
@export var base_texture: Texture2D = null
@export var weapon_texture: Texture2D = null

const RANGE_BONUS_PER_FLOOR: float = 0.15
const CRIT_BASE: float = 0.05
const CRIT_PER_FLOOR: float = 0.05
const CRIT_MULTIPLIER: float = 2.0
const COLLAPSE_THRESHOLD: float = 0.4


func get_dps() -> float:
	return damage * fire_rate


func get_effective_range(floor_level: int) -> float:
	return attack_range * (1.0 + (floor_level - 1) * RANGE_BONUS_PER_FLOOR)


func get_crit_chance(floor_level: int) -> float:
	return CRIT_BASE + (floor_level - 1) * CRIT_PER_FLOOR


func get_floor_cost(floor_level: int) -> int:
	if floor_level == 1:
		return build_cost
	if floor_level == 5:
		return build_cost * 2
	return build_cost * floor_level
