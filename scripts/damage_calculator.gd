extends Node

const MULTIPLIER_TABLE: Dictionary = {
	TowerData.AttackType.LOW_TECH: {
		EnemyData.DefenseType.NORMAL: 1.0,
		EnemyData.DefenseType.MIRROR: 1.5,
		EnemyData.DefenseType.STEEL_CAN: 0.5,
	},
	TowerData.AttackType.HI_TECH: {
		EnemyData.DefenseType.NORMAL: 1.5,
		EnemyData.DefenseType.MIRROR: -1.0,
		EnemyData.DefenseType.STEEL_CAN: 0.2,
	},
	TowerData.AttackType.MYSTIC: {
		EnemyData.DefenseType.NORMAL: 1.0,
		EnemyData.DefenseType.MIRROR: 1.2,
		EnemyData.DefenseType.STEEL_CAN: 1.5,
	},
}


func calculate(base_damage: float, attack_type: TowerData.AttackType, defense_type: EnemyData.DefenseType, is_crit: bool) -> float:
	var mult: float = MULTIPLIER_TABLE[attack_type][defense_type]
	var dmg: float = base_damage * mult
	if is_crit and mult > 0.0:
		dmg *= TowerData.CRIT_MULTIPLIER
	return dmg


func is_reflected(attack_type: TowerData.AttackType, defense_type: EnemyData.DefenseType) -> bool:
	return MULTIPLIER_TABLE[attack_type][defense_type] < 0.0


func get_reflect_damage(base_damage: float, attack_type: TowerData.AttackType, defense_type: EnemyData.DefenseType) -> float:
	var mult: float = MULTIPLIER_TABLE[attack_type][defense_type]
	if mult >= 0.0:
		return 0.0
	return base_damage * absf(mult)
