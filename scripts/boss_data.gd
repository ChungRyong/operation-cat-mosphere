extends Resource
class_name BossData

enum AttackPattern { CHARGE, SUMMON, AOE }

@export var boss_name: String = ""
@export var max_health: float = 2000.0
@export var defense_type: EnemyData.DefenseType = EnemyData.DefenseType.NORMAL
@export var phase2_threshold: float = 0.5
@export var color: Color = Color(0.9, 0.2, 0.3, 1.0)
@export var radius: float = 40.0
@export var gold_reward: int = 100

@export var charge_damage: float = 30.0
@export var charge_speed: float = 400.0
@export var charge_cooldown: float = 5.0

@export var summon_enemy: EnemyData
@export var summon_count: int = 8
@export var summon_cooldown: float = 10.0

@export var aoe_damage: float = 20.0
@export var aoe_radius: float = 120.0
@export var aoe_cooldown: float = 7.0
