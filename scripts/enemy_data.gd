extends Resource
class_name EnemyData

enum EnemyClass { SWARM, GIMMICK, COUNTER, ELITE }
enum DefenseType { NORMAL, MIRROR, STEEL_CAN }

@export var enemy_name: String = ""
@export var enemy_class: EnemyClass = EnemyClass.SWARM
@export var defense_type: DefenseType = DefenseType.NORMAL
@export var max_health: float = 20.0
@export var speed: float = 2.5
@export var essence_reward: int = 1
@export var color: Color = Color(0.3, 0.9, 0.3, 1.0)
@export var radius: float = 16.0
@export var texture: Texture2D = null
@export var spawn_on_death: EnemyData = null
@export var spawn_count: int = 0
@export var attacks_towers: bool = false
@export var tower_damage: float = 0.0
