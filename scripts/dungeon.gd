extends Node

## Dungeon System - Reward tables, exploration processing

class_name Dungeon

# Dungeon rewards by difficulty
var dungeon_rewards: Dictionary = {
	1: {
		"min_gold": 10,
		"max_gold": 30,
		"common_items": 3.0,
		"min_quantity": 1, "max_quantity": 3,
		"artifact_chance": 0.08,
		"possible_artifacts": ["cursed_ring"]
	},
	2: {
		"min_gold": 30,
		"max_gold": 70,
		"common_items": 4.0,
		"min_quantity": 1, "max_quantity": 3,
		"artifact_chance": 0.12,
		"possible_artifacts": ["cursed_ring", "golden_amulet", "dragon_scale", "shadow_cloak"]
	},
	3: {
		"min_gold": 70,
		"max_gold": 150,
		"common_items": 5.0,
		"min_quantity": 2, "max_quantity": 4,
		"artifact_chance": 0.15,
		"possible_artifacts": ["golden_amulet", "dragon_scale", "holy_grail", "eternal_blade", "shadow_cloak"]
	},
	4: {
		"min_gold": 150,
		"max_gold": 250,
		"common_items": 6.0,
		"min_quantity": 2, "max_quantity": 5,
		"artifact_chance": 0.18,
		"possible_artifacts": ["golden_amulet", "dragon_scale", "holy_grail", "eternal_blade", "shadow_cloak"]
	},
	5: {
		"min_gold": 250,
		"max_gold": 400,
		"common_items": 7.0,
		"min_quantity": 3, "max_quantity": 6,
		"artifact_chance": 0.20,
		"possible_artifacts": ["holy_grail", "eternal_blade", "dragon_scale"]
	}
}

var artifact_data: Dictionary = {}
var dungeon_data: Dictionary = {}

func _ready() -> void:
	_load_artifact_data()
	_load_dungeon_data()


func _load_artifact_data() -> void:
	var artifact_file = FileAccess.open("res://resources/data/artifacts.json", FileAccess.READ)
	if artifact_file:
		artifact_data = JSON.parse_string(artifact_file.get_as_text())
		artifact_file.close()


func _load_dungeon_data() -> void:
	var file = FileAccess.open("res://resources/data/dungeons.json", FileAccess.READ)
	if file:
		dungeon_data = JSON.parse_string(file.get_as_text())
		file.close()


## Calculate dungeon exploration rewards (including EXP)
## attack_power/defense from equipped items; ability_bonuses from unlocked abilities
func generate_rewards(dungeon_tier: int, adventurer_level: int = 1,
		character_class: String = "", pickaxe_level: int = 1,
		attack_power: int = 0, defense: int = 0,
		ability_bonuses: Dictionary = {}) -> Dictionary:
	if not dungeon_rewards.has(dungeon_tier):
		dungeon_tier = 1

	var reward_config = dungeon_rewards[dungeon_tier]
	var rewards = {
		"gold": 0,
		"items": [],  # Common items (ores)
		"artifacts": [],  # Artifacts
		"experience": 0  # Experience
	}

	# Gold (boosted by attack power)
	var base_gold = randi_range(reward_config["min_gold"], reward_config["max_gold"])
	var gold_mult = 1.0 + attack_power * GameConfig.ATTACK_GOLD_BONUS_PER_POINT
	gold_mult *= (1.0 + ability_bonuses.get("reward_increase", 0.0))
	rewards["gold"] = int(base_gold * gold_mult)

	# Ore quantity bonus from class, pickaxe, and attack power
	var class_bonus = GameConfig.CLASS_ORE_BONUS.get(character_class, 1.0)
	var pickaxe_bonus = 1.0 + (pickaxe_level - 1) * GameConfig.PICKAXE_ORE_BONUS_PER_LEVEL
	var attack_ore_bonus = 1.0 + attack_power * GameConfig.ATTACK_ORE_BONUS_PER_POINT
	var ore_multiplier = class_bonus * pickaxe_bonus * attack_ore_bonus

	# Common item count (average)
	var item_count = int(reward_config["common_items"])
	if randf() < (reward_config["common_items"] - int(reward_config["common_items"])):
		item_count += 1

	var min_qty = reward_config.get("min_quantity", 1)
	var max_qty = reward_config.get("max_quantity", 3)

	for i in range(item_count):
		var ore_id = _get_random_ore_for_tier(dungeon_tier)
		var quantity = int(randi_range(min_qty, max_qty) * ore_multiplier)
		quantity = max(quantity, 1)
		rewards["items"].append({"ore_id": ore_id, "quantity": quantity})

	# Artifacts
	if randf() < reward_config["artifact_chance"]:
		var artifact_id = _get_random_artifact(reward_config["possible_artifacts"])
		if artifact_data.has(artifact_id):
			var artifact = artifact_data[artifact_id].duplicate()
			artifact["is_artifact"] = true
			artifact["acquired_tier"] = dungeon_tier
			rewards["artifacts"].append(artifact)

	# Experience (boosted by defense = surviving better)
	var base_exp = 40 + dungeon_tier * 30
	var level_scaling = 1.0 - (max(0, adventurer_level - dungeon_tier) * 0.02)
	level_scaling = max(level_scaling, 0.5)
	var defense_exp_bonus = 1.0 + defense * GameConfig.DEFENSE_EXP_BONUS_PER_POINT

	rewards["experience"] = int(base_exp * level_scaling * defense_exp_bonus)

	return rewards


## Generate rewards for a party dungeon run
## avg_level: average level of party members
func generate_party_rewards(dungeon_id: String, avg_level: int,
		total_attack: int, total_defense: int, party_size: int,
		pickaxe_level: int = 1, ability_bonuses: Dictionary = {}) -> Dictionary:

	var dg = dungeon_data.get(dungeon_id, {})
	var dungeon_tier = dg.get("tier", 1)

	# Use base generate_rewards for gold/ores/artifacts/exp
	var rewards = generate_rewards(dungeon_tier, avg_level, "", pickaxe_level,
		total_attack, total_defense, ability_bonuses)

	# Scale rewards by party size
	rewards["gold"] = int(rewards["gold"] * (1.0 + (party_size - 1) * 0.15))

	# Dungeon-exclusive material drops
	rewards["dungeon_materials"] = []
	var exclusive = dg.get("exclusive_materials", [])
	var drop_chance = GameConfig.DUNGEON_MATERIAL_DROP_CHANCE.get(dungeon_tier, 0.5)
	var min_qty = GameConfig.DUNGEON_MATERIAL_MIN_QTY.get(dungeon_tier, 1)
	var max_qty = GameConfig.DUNGEON_MATERIAL_MAX_QTY.get(dungeon_tier, 2)
	var size_bonus = GameConfig.PARTY_SIZE_MATERIAL_BONUS.get(party_size, 1.0)

	for mat_id in exclusive:
		if randf() < drop_chance:
			var qty = int(randi_range(min_qty, max_qty) * size_bonus)
			qty = max(qty, 1)
			rewards["dungeon_materials"].append({"material_id": mat_id, "quantity": qty})

	return rewards


## Tier-weighted ore selection
## Current tier ores: 50%, one tier below: 30%, rest: 20%
func _get_random_ore_for_tier(tier: int) -> String:
	# Build weighted list: current tier 50%, previous 30%, rest 20%
	var weighted: Array = []  # [{ore, weight}]
	var current_ores: Array = GameConfig.ORE_SPAWN_CHANCES.get(tier, GameConfig.ORE_SPAWN_CHANCES[1]).keys()
	var prev_ores: Array = []
	var rest_ores: Array = []

	for t in GameConfig.ORE_SPAWN_CHANCES:
		if t > tier:
			continue
		if t == tier:
			pass  # already set above
		elif t == tier - 1:
			prev_ores.append_array(GameConfig.ORE_SPAWN_CHANCES[t].keys())
		else:
			rest_ores.append_array(GameConfig.ORE_SPAWN_CHANCES[t].keys())

	# Assign weights
	var current_weight = 50.0 / max(current_ores.size(), 1)
	for ore in current_ores:
		weighted.append({"ore": ore, "weight": current_weight})

	if not prev_ores.is_empty():
		var prev_weight = 30.0 / prev_ores.size()
		for ore in prev_ores:
			weighted.append({"ore": ore, "weight": prev_weight})
	elif not rest_ores.is_empty():
		# No previous tier (tier 1): merge into rest
		pass
	# If tier 1, only current_ores exist so 50% covers everything

	if not rest_ores.is_empty():
		var rest_weight = 20.0 / rest_ores.size()
		for ore in rest_ores:
			weighted.append({"ore": ore, "weight": rest_weight})

	# Normalize for tier 1 (only current tier exists)
	if weighted.is_empty():
		return "copper"

	var total = 0.0
	for entry in weighted:
		total += entry["weight"]

	var roll = randf() * total
	var cumulative = 0.0
	for entry in weighted:
		cumulative += entry["weight"]
		if roll <= cumulative:
			return entry["ore"]

	return weighted[0]["ore"]


## Random from available artifacts
func _get_random_artifact(possible_artifacts: Array) -> String:
	if possible_artifacts.is_empty():
		return ""
	return possible_artifacts[randi() % possible_artifacts.size()]


## Estimated exploration time by difficulty (seconds)
func get_estimated_exploration_time(tier: int, speed_multiplier: float = 1.0) -> float:
	var base_time = GameConfig.EXPLORATION_BASE_TIME + (tier - 1) * GameConfig.EXPLORATION_TIME_PER_TIER
	return base_time / speed_multiplier
