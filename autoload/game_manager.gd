extends Node

## Global game state manager
## Uses GameConfig to remove magic numbers, minimize coupling
## Level 1 refactor: all state access via methods

# ===============================================
# Signals (grouped by purpose)
# ===============================================

# Currency
signal gold_changed(amount: int)
signal reputation_changed(amount: int)

# Inventory
signal ore_changed(ore_id: String, amount: int)
signal bar_changed(ore_id: String, amount: int)
signal inventory_changed()
signal item_crafted(item_name: String, grade: String)
signal item_equipped(adventurer_id: String, item: Dictionary)
signal item_unequipped(adventurer_id: String, item: Dictionary)

# Adventure
signal exploration_started(adventurer_id: String, tier: int)
signal exploration_completed(adventurer_id: String, rewards: Dictionary)
signal adventurer_hired(adventurer_id: String, cost: int)
signal experience_gained(adventurer_id: String, amount: int)
signal adventurer_leveled_up(adventurer_id: String, new_level: int, stat_changes: Dictionary)

# System progression
signal tier_unlocked(tier: int)

# Currency
var gold: int = 0 :
	set(value):
		gold = value
		gold_changed.emit(gold)

var reputation: int = 0 :
	set(value):
		reputation = value
		reputation_changed.emit(reputation)

# Inventory - ores, bars, crafted items
var ores: Dictionary = {}
var bars: Dictionary = {}
var inventory: Array[Dictionary] = []

# Upgrades
var pickaxe_level: int = 1
var anvil_level: int = 1
var auto_mine_speed: float = 0.0  # 0 = no auto mining

# Mastery (craft count per recipe)
var mastery: Dictionary = {}

# Unlocked world tier
var max_unlocked_tier: int = 1

# Data
var ore_data: Dictionary = {}
var recipe_data: Dictionary = {}
var artifact_data: Dictionary = {}
var adventurer_data: Dictionary = {}
var abilities_data: Dictionary = {}

# Systems
var adventure_system: AdventureSystem
var dungeon: Dungeon


# ===============================================
# State Access Methods (Level 1 refactor)
# ===============================================

# ----- Ore -----

## Add ore
func add_ore(ore_id: String, amount: int = 1) -> bool:
	if not ores.has(ore_id) or amount <= 0:
		return false
	ores[ore_id] += amount
	ore_changed.emit(ore_id, ores[ore_id])
	return true

## Remove ore
func remove_ore(ore_id: String, amount: int) -> bool:
	if not ores.has(ore_id) or amount <= 0 or ores[ore_id] < amount:
		return false
	ores[ore_id] -= amount
	ore_changed.emit(ore_id, ores[ore_id])
	return true

## Set ore count
func set_ore(ore_id: String, amount: int) -> bool:
	if not ores.has(ore_id) or amount < 0:
		return false
	ores[ore_id] = amount
	ore_changed.emit(ore_id, ores[ore_id])
	return true

## Get ore count
func get_ore_count(ore_id: String) -> int:
	return ores.get(ore_id, 0)

## Get all ore counts
func get_all_ores() -> Dictionary:
	return ores.duplicate()


# ----- Bars -----

## Add bar
func add_bar(ore_id: String, amount: int = 1) -> bool:
	if not bars.has(ore_id) or amount <= 0:
		return false
	bars[ore_id] += amount
	bar_changed.emit(ore_id, bars[ore_id])
	return true

## Remove bar
func remove_bar(ore_id: String, amount: int) -> bool:
	if not bars.has(ore_id) or amount <= 0 or bars[ore_id] < amount:
		return false
	bars[ore_id] -= amount
	bar_changed.emit(ore_id, bars[ore_id])
	return true

## Get bar count
func get_bar_count(ore_id: String) -> int:
	return bars.get(ore_id, 0)


# ----- Inventory (items) -----

## Add item
func add_item(item: Dictionary) -> bool:
	if item.is_empty():
		return false
	inventory.append(item)
	inventory_changed.emit()
	return true

## Remove item (index-based)
func remove_item(item_index: int) -> bool:
	if item_index < 0 or item_index >= inventory.size():
		return false
	inventory.remove_at(item_index)
	inventory_changed.emit()
	return true

## Get all inventory items
func get_inventory_items() -> Array[Dictionary]:
	return inventory

## Get items by type
func get_items_by_type(item_type: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item in inventory:
		if item.get("type", "") == item_type:
			result.append(item)
	return result


# ----- Gold -----

## Add gold
func add_gold(amount: int) -> void:
	gold += amount

## Remove gold (fails if insufficient)
func remove_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	return true

## Get gold
func get_gold() -> int:
	return gold


# ----- Reputation -----

## Add reputation
func add_reputation(amount: int) -> void:
	reputation += amount

## Get reputation
func get_reputation() -> int:
	return reputation


# ----- Upgrade Levels -----

func get_pickaxe_level() -> int:
	return pickaxe_level

func set_pickaxe_level(level: int) -> void:
	pickaxe_level = level

func get_anvil_level() -> int:
	return anvil_level

func set_anvil_level(level: int) -> void:
	anvil_level = level

# ----- Other State Getters -----

## Get mastery count
func get_mastery_count(recipe_id: String) -> int:
	return mastery.get(recipe_id, 0)

## Get max unlocked tier
func get_max_unlocked_tier() -> int:
	return max_unlocked_tier

## Get auto mine speed
func get_auto_mine_speed() -> float:
	return auto_mine_speed


# ===============================================
# Game Logic
# ===============================================

## Random ore selection (normalized probability per tier)
## Reads from GameConfig.ORE_SPAWN_CHANCES (low coupling)
func get_random_ore() -> String:
	# Available unlocked tiers
	var available_tiers = []
	for tier in range(1, max_unlocked_tier + 1):
		if GameConfig.ORE_SPAWN_CHANCES.has(tier):
			available_tiers.append(tier)
	
	if available_tiers.is_empty():
		return "copper"  # fallback
	
	# Step 1: Select tier (equal probability among unlocked)
	var selected_tier = available_tiers[randi() % available_tiers.size()]
	
	# Step 2: Select ore from chosen tier
	var tier_ores = GameConfig.ORE_SPAWN_CHANCES[selected_tier]
	var roll = randf() * 100.0
	var current = 0.0
	for ore_id in tier_ores:
		current += tier_ores[ore_id]
		if roll <= current:
			return ore_id
	
	# Fallback (first ore)
	var ore_keys = tier_ores.keys()
	return ore_keys[0] if ore_keys.size() > 0 else "copper"


func _ready() -> void:
	push_error("[Game] GameManager._ready() called")
	_load_data()
	push_error("[Game] GameManager._ready() completed")


func _load_data() -> void:
	# Load ore data
	var ore_file = FileAccess.open("res://resources/data/ores.json", FileAccess.READ)
	if ore_file:
		ore_data = JSON.parse_string(ore_file.get_as_text())
		ore_file.close()
		# Initialize ore and bar inventories
		for ore_id in ore_data:
			ores[ore_id] = 0
			bars[ore_id] = 0

	# Load recipe data
	var recipe_file = FileAccess.open("res://resources/data/recipes.json", FileAccess.READ)
	if recipe_file:
		recipe_data = JSON.parse_string(recipe_file.get_as_text())
		recipe_file.close()
	
	# Load artifact data
	var artifact_file = FileAccess.open("res://resources/data/artifacts.json", FileAccess.READ)
	if artifact_file:
		artifact_data = JSON.parse_string(artifact_file.get_as_text())
		artifact_file.close()
	
	# Load adventurer data
	var adventurer_file = FileAccess.open("res://resources/data/adventurers.json", FileAccess.READ)
	if adventurer_file:
		adventurer_data = JSON.parse_string(adventurer_file.get_as_text())
		adventurer_file.close()
	
	# Load abilities data
	var abilities_file = FileAccess.open("res://resources/data/abilities.json", FileAccess.READ)
	if abilities_file:
		abilities_data = JSON.parse_string(abilities_file.get_as_text())
		abilities_file.close()
	
	# Initialize systems
	push_error("[Adventure] GameManager._load_data(): Creating AdventureSystem...")
	adventure_system = AdventureSystem.new()
	push_error("[Adventure] GameManager._load_data(): Adding AdventureSystem as child...")
	add_child(adventure_system)
	push_error("[Adventure] GameManager._load_data(): Calling adventure_system._load_data()...")
	adventure_system._load_data()
	push_error("[Adventure] GameManager._load_data(): adventure_system initialized with %d adventurers" % adventure_system.adventurers.size())
	
	dungeon = Dungeon.new()
	add_child(dungeon)
	
	# Initial resources (first run)
	if ores.get("copper", 0) == 0:
		gold = GameConfig.INITIAL_GOLD
		ores["copper"] = GameConfig.INITIAL_COPPER
		ores["tin"] = GameConfig.INITIAL_TIN
		bars["copper"] = GameConfig.INITIAL_COPPER_BAR
		bars["tin"] = GameConfig.INITIAL_TIN_BAR
	
	# Auto mine speed init
	auto_mine_speed = 0.05  # slow background mining


## Smelt ore -> bar
func smelt_ore(ore_id: String) -> bool:
	if not ore_data.has(ore_id):
		return false
	var needed = ore_data[ore_id]["ore_per_bar"]
	if get_ore_count(ore_id) >= needed:
		remove_ore(ore_id, needed)
		add_bar(ore_id)
		return true
	return false


## Check if recipe can be crafted
func can_craft(recipe_id: String) -> bool:
	if not recipe_data.has(recipe_id):
		return false
	var recipe = recipe_data[recipe_id]
	if not recipe.get("unlocked", false):
		return false
	for mat_id in recipe["materials"]:
		if get_bar_count(mat_id) < recipe["materials"][mat_id]:
			return false
	return true


## Craft item (random grade)
func craft_item(recipe_id: String) -> Dictionary:
	if not can_craft(recipe_id):
		return {}

	var recipe = recipe_data[recipe_id]

	# Consume materials
	for mat_id in recipe["materials"]:
		remove_bar(mat_id, recipe["materials"][mat_id])

	# Determine grade
	var grade = _roll_grade(recipe_id)
	var grade_info = GameConfig.GRADES[grade]

	# Create item
	var item = {
		"recipe_id": recipe_id,
		"name": recipe["name"],
		"type": recipe["type"],
		"subtype": recipe.get("subtype", ""),
		"grade": grade,
		"grade_name": grade_info["name"],
		"grade_color": grade_info["color"],
		"grade_emoji": GameConfig.GRADE_EMOJIS.get(grade, ""),
		"price": int(recipe["base_price"] * grade_info["multiplier"]),
		"tier": recipe["tier"],
		"is_artifact": false  # normal item
	}

	add_item(item)

	# Increase mastery
	mastery[recipe_id] = mastery.get(recipe_id, 0) + 1

	item_crafted.emit(item["name"], grade)
	return item


## Roll grade (with enhancement bonuses)
## Uses GameConfig constants so balance changes only need one edit (low coupling)
func _roll_grade(recipe_id: String) -> String:
	var chances = GameConfig.BASE_GRADE_CHANCES.duplicate()

	# Anvil bonus: increases per level
	var anvil_bonus = (get_anvil_level() - 1) * GameConfig.ANVIL_BONUS_PER_LEVEL
	chances["rare"] += anvil_bonus * GameConfig.ANVIL_RARE_WEIGHT
	chances["epic"] += anvil_bonus * GameConfig.ANVIL_EPIC_WEIGHT
	chances["legendary"] += anvil_bonus * GameConfig.ANVIL_LEGENDARY_WEIGHT
	chances["common"] -= anvil_bonus

	# Mastery bonus: increases per threshold
	var craft_count = get_mastery_count(recipe_id)
	var mastery_bonus = floor(float(craft_count) / GameConfig.MASTERY_CRAFT_COUNT_THRESHOLD) * GameConfig.MASTERY_BONUS_PER_THRESHOLD
	mastery_bonus = min(mastery_bonus, GameConfig.MASTERY_MAX_BONUS)
	
	chances["uncommon"] += mastery_bonus * GameConfig.MASTERY_UNCOMMON_WEIGHT
	chances["rare"] += mastery_bonus * GameConfig.MASTERY_RARE_WEIGHT
	chances["epic"] += mastery_bonus * GameConfig.MASTERY_EPIC_WEIGHT
	chances["legendary"] += mastery_bonus * GameConfig.MASTERY_LEGENDARY_WEIGHT
	chances["common"] -= mastery_bonus

	# Ensure common grade doesn't go negative
	chances["common"] = max(chances["common"], GameConfig.ANVIL_COMMON_MIN)

	# Normalize probabilities
	var total = 0.0
	for g in chances:
		total += chances[g]

	var roll = randf() * total
	var cumulative = 0.0
	for g in ["legendary", "epic", "rare", "uncommon", "common"]:
		cumulative += chances[g]
		if roll <= cumulative:
			return g

	return "common"


## Sell item
func sell_item(index: int) -> int:
	if index < 0 or index >= inventory.size():
		return 0
	var item = inventory[index]
	var price = item["price"]
	add_gold(price)
	add_reputation(1)
	remove_item(index)
	return price


## Calculate mining power (uses GameConfig constants)
func get_mine_power() -> float:
	return GameConfig.PICKAXE_POWER_BASE + (get_pickaxe_level() - 1) * GameConfig.PICKAXE_POWER_PER_LEVEL


## ===== Adventurer System =====

## Get all adventurers
func get_adventurers() -> Array:
	if not adventure_system:
		push_error("[X] GameManager.get_adventurers(): adventure_system is null!")
		return []
	return adventure_system.get_all_adventurers()


## Get specific adventurer
func get_adventurer(adventurer_id: String):
	if not adventure_system:
		return null
	return adventure_system.get_adventurer(adventurer_id)


## Equip item to adventurer
func equip_item_to_adventurer(adventurer_id: String, inventory_index: int) -> bool:
	if inventory_index < 0 or inventory_index >= inventory.size():
		return false
	
	var item = inventory[inventory_index]
	if not adventure_system or not adventure_system.equip_to_adventurer(adventurer_id, item):
		return false
	
	# Remove from inventory
	remove_item(inventory_index)
	item_equipped.emit(adventurer_id, item)
	return true


## Unequip item from adventurer
func unequip_item_from_adventurer(adventurer_id: String, item_index: int) -> bool:
	if not adventure_system:
		return false
	
	var item = adventure_system.unequip_from_adventurer(adventurer_id, item_index)
	if item.is_empty():
		return false
	
	# Add back to inventory
	add_item(item)
	item_unequipped.emit(adventurer_id, item)
	return true


## Start adventurer exploration
func start_exploration(adventurer_id: String, dungeon_tier: int) -> bool:
	if not adventure_system:
		return false
	
	var success = adventure_system.start_adventure(adventurer_id, dungeon_tier)
	if success:
		exploration_started.emit(adventurer_id, dungeon_tier)
	return success


## Check and complete exploration with rewards
func check_and_complete_exploration(adventurer_id: String) -> Dictionary:
	if not adventure_system or not dungeon:
		return {}
	
	if not adventure_system.check_exploration_complete(adventurer_id):
		return {}
	
	var adv = adventure_system.get_adventurer(adventurer_id)
	if not adv:
		return {}
	
	# Finish exploration
	var exploration_data = adv.finish_exploration()
	if exploration_data.is_empty():
		return {}
	
	# Generate rewards
	var rewards = dungeon.generate_rewards(adv.current_dungeon_tier, adv.level)
	
	# Apply rewards
	add_gold(rewards["gold"])
	
	# Add ores
	for ore_reward in rewards["items"]:
		add_ore(ore_reward["ore_id"], ore_reward["quantity"])
	
	# Add artifacts to inventory
	for artifact in rewards["artifacts"]:
		add_item(artifact)
	
	# Process experience (Phase 3)
	if rewards.has("experience"):
		_process_experience(adventurer_id, rewards["experience"])
	
	# Check tier unlock after exploration
	_check_tier_unlock()
	
	exploration_data["rewards"] = rewards
	exploration_completed.emit(adventurer_id, exploration_data)
	
	return exploration_data


## ===== Phase 3: Adventurer Hiring & Leveling System =====

## Hire adventurer
func hire_adventurer(adventurer_id: String) -> bool:
	var adv = adventure_system.get_adventurer(adventurer_id)
	if not adv or adv.hired:
		return false
	
	var hire_data = adventurer_data.get(adventurer_id, {})
	var hire_cost = hire_data.get("hire_cost", 100)
	
	if not remove_gold(hire_cost):
		return false
	
	adventure_system.hire_adventurer(adventurer_id)
	adventurer_hired.emit(adventurer_id, hire_cost)
	
	# Check for new tier unlock
	_check_tier_unlock()
	
	return true


## Get hired adventurers only
func get_hired_adventurers() -> Array:
	if not adventure_system:
		return []
	return adventure_system.get_hired_adventurers()


## Get unhired adventurers
func get_available_adventurers() -> Array:
	if not adventure_system:
		return []
	return adventure_system.get_available_adventurers()


## Get adventurer hire cost (default from GameConfig)
func get_hire_cost(adventurer_id: String) -> int:
	var data = adventurer_data.get(adventurer_id, {})
	return data.get("hire_cost", GameConfig.ADVENTURER_HIRE_COST_DEFAULT)


## Process experience and level up
func _process_experience(adventurer_id: String, amount: int) -> void:
	if not adventure_system:
		return
	
	var adv = adventure_system.get_adventurer(adventurer_id)
	if not adv:
		return
	
	# Add experience and check level ups
	var levels_gained = adventure_system.add_experience(adventurer_id, amount)
	experience_gained.emit(adventurer_id, amount)
	
	# Process level ups (supports consecutive leveling)
	if levels_gained > 0:
		for i in range(levels_gained):
			var level_up_result = adventure_system.level_up(adventurer_id)
			if not level_up_result.is_empty():
				var new_level = level_up_result.get("level", adv.level)
				adventurer_leveled_up.emit(adventurer_id, new_level, level_up_result)
		
		# Check for new tier unlock
		_check_tier_unlock()


## Auto tier unlock
## Reads from GameConfig.TIER_UNLOCK_CONDITIONS (low coupling)
## Only GameConfig.gd needs editing for balance changes
func _check_tier_unlock() -> void:
	var hired_adventurers = adventure_system.get_hired_adventurers()
	if hired_adventurers.is_empty():
		return
	
	# Use unlock conditions defined in GameConfig
	for tier in GameConfig.TIER_UNLOCK_CONDITIONS:
		if max_unlocked_tier >= tier:
			continue
		
		var condition = GameConfig.TIER_UNLOCK_CONDITIONS[tier]
		
		# Condition 1: Required number of hired adventurers
		if hired_adventurers.size() < condition["min_adventurers"]:
			continue
		
		# Condition 2: Minimum level requirement
		var meets_level = true
		for adv in hired_adventurers:
			if adv.level < condition["min_level"]:
				meets_level = false
				break
		
		if meets_level:
			max_unlocked_tier = tier
			tier_unlocked.emit(tier)


## Calculate average adventurer level
func get_average_adventurer_level() -> float:
	var hired_adventurers = adventure_system.get_hired_adventurers()
	if hired_adventurers.is_empty():
		return 1.0
	
	var total_level = 0
	for adv in hired_adventurers:
		total_level += adv.level
	
	return float(total_level) / float(hired_adventurers.size())


## Get adventurer's unlocked abilities
func get_unlocked_abilities(adventurer_id: String) -> Array:
	if not adventure_system:
		return []
	return adventure_system.get_unlocked_abilities(adventurer_id)


## Get all class abilities for adventurer
func get_all_class_abilities(adventurer_id: String) -> Array:
	if not adventure_system:
		return []
	return adventure_system.get_all_class_abilities(adventurer_id)


## ===== Debug =====

## GameManager status check
func get_debug_status() -> String:
	var status = "=== GameManager Debug Status ===\n"
	status += "adventure_system: %s\n" % ("[OK] exists" if adventure_system else "[X] null")
	
	if adventure_system:
		var debug_info = adventure_system.get_debug_info()
		status += "\nAdventure System:\n"
		status += "  Adventurers: %d\n" % debug_info["adventurers_count"]
		status += "  Adventurer Data: %d\n" % debug_info["adventurer_data_count"]
		status += "  Abilities Data: %d\n" % debug_info["abilities_data_count"]
		status += "  IDs: %s\n" % str(debug_info["adventurer_ids"])
		status += "  Names: %s\n" % str(debug_info["adventurer_names"])
	
	return status
