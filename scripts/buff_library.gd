extends Node

const ALL_BUFFS: Array[Dictionary] = [
	{
		"id": "atk_up",
		"name": "Sharp Claws",
		"desc": "Hero ATK +20%",
		"type": "hero_atk",
		"value": 0.2,
		"max_stacks": 3,
		"color": Color(1.0, 0.4, 0.3),
	},
	{
		"id": "hp_up",
		"name": "Thick Fur",
		"desc": "Hero Max HP +30",
		"type": "hero_hp",
		"value": 30.0,
		"max_stacks": 3,
		"color": Color(0.3, 0.9, 0.3),
	},
	{
		"id": "spd_up",
		"name": "Light Paws",
		"desc": "Hero Speed +15%",
		"type": "hero_spd",
		"value": 0.15,
		"max_stacks": 3,
		"color": Color(0.3, 0.7, 1.0),
	},
	{
		"id": "tower_dmg",
		"name": "Catnip Ammo",
		"desc": "All Tower ATK +15%",
		"type": "tower_atk",
		"value": 0.15,
		"max_stacks": 3,
		"color": Color(1.0, 0.6, 0.2),
	},
	{
		"id": "tower_range",
		"name": "Eagle Eye",
		"desc": "All Tower Range +20%",
		"type": "tower_range",
		"value": 0.2,
		"max_stacks": 2,
		"color": Color(0.6, 0.4, 1.0),
	},
	{
		"id": "tower_rate",
		"name": "Quick Paws",
		"desc": "All Tower Fire Rate +15%",
		"type": "tower_rate",
		"value": 0.15,
		"max_stacks": 3,
		"color": Color(1.0, 1.0, 0.3),
	},
	{
		"id": "scrap_bonus",
		"name": "Scavenger",
		"desc": "Bonus Scrap +40",
		"type": "scrap_bonus",
		"value": 40.0,
		"max_stacks": 5,
		"color": Color(0.8, 0.65, 0.3),
	},
	{
		"id": "base_hp",
		"name": "Reinforced Walls",
		"desc": "Base HP +50",
		"type": "base_hp",
		"value": 50.0,
		"max_stacks": 3,
		"color": Color(0.5, 0.5, 0.5),
	},
	{
		"id": "crit_up",
		"name": "Lucky Whiskers",
		"desc": "All Tower Crit +5%",
		"type": "tower_crit",
		"value": 0.05,
		"max_stacks": 3,
		"color": Color(1.0, 0.85, 0.0),
	},
]


func _get_buff_count(buff_id: String) -> int:
	var count: int = 0
	for buff in GameManager.active_buffs:
		if buff["id"] == buff_id:
			count += 1
	return count


func pick_random_cards(count: int = 3) -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	for buff in ALL_BUFFS:
		if _get_buff_count(buff["id"]) < buff["max_stacks"]:
			pool.append(buff)
	pool.shuffle()
	var result: Array[Dictionary] = []
	for i in mini(count, pool.size()):
		result.append(pool[i])
	return result
