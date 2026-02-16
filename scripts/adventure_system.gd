extends Node

## Adventure System - Phase 3 expansion: Level-up, Experience, Special Abilities

class_name AdventureSystem

# Experience required per level
const EXP_PER_LEVEL = {
	1: 0,
	2: 100,
	3: 250,
	4: 450,
	5: 700,
	6: 1000,
	7: 1350,
	8: 1750,
	9: 2200,
	10: 2700,
	11: 3250,
	12: 3850,
	13: 4500,
	14: 5200,
	15: 6000
}

# Adventurer class
class Adventurer:
	var id: String
	var name: String
	var description: String
	var character_class: String  # warrior, rogue, mage, paladin
	var base_hp: int
	var base_speed: float
	var portrait: String
	
	# Runtime state
	var current_hp: int
	var is_exploring: bool = false
	var exploration_start_time: float = 0.0
	var exploration_duration: float = 0.0  # in seconds
	var current_dungeon_tier: int = 1
	
	# Level & Experience
	var level: int = 1
	var experience: int = 0
	var hired: bool = false
	
	# Equipped items
	var equipped_items: Array[Dictionary] = []  # max 3 (weapon, armor, accessory)
	
	# Unlocked abilities
	var unlocked_abilities: Array[String] = []  # ability ID array
	
	func _init(p_id: String, p_name: String, p_description: String, p_class: String, p_hp: int, p_speed: float, p_portrait: String, p_level: int = 1, p_exp: int = 0, p_hired: bool = false) -> void:
		id = p_id
		name = p_name
		description = p_description
		character_class = p_class
		base_hp = p_hp
		current_hp = p_hp
		base_speed = p_speed
		portrait = p_portrait
		level = p_level
		experience = p_exp
		hired = p_hired
	
	## Calculate current exploration speed multiplier (including equipped items)
	func get_speed_multiplier() -> float:
		var multiplier = base_speed
		for item in equipped_items:
			if item.has("speed_bonus"):
				multiplier *= item["speed_bonus"]
		return multiplier
	
	## Calculate exploration time (in seconds)
	func calculate_exploration_time(dungeon_tier: int) -> float:
		# Base time: 30s ~ 180s depending on difficulty
		var base_time = 30.0 + (dungeon_tier - 1) * 30.0
		
		# Apply speed multiplier (higher = faster)
		var speed_mult = get_speed_multiplier()
		return base_time / speed_mult
	
	## Experience needed from current level to next level
	func get_exp_to_next_level() -> int:
		if not EXP_PER_LEVEL.has(level + 1):
			return 999999  # Max level reached
		var next_level_exp = EXP_PER_LEVEL[level + 1]
		var current_level_exp = EXP_PER_LEVEL.get(level, 0)
		return next_level_exp - current_level_exp
	
	## Experience progress at current level (0.0 ~ 1.0)
	func get_exp_progress() -> float:
		var current_level_exp = EXP_PER_LEVEL.get(level, 0)
		var next_level_exp = EXP_PER_LEVEL.get(level + 1, 999999)
		
		if experience >= next_level_exp:
			return 1.0
		
		var exp_in_level = experience - current_level_exp
		var exp_needed = next_level_exp - current_level_exp
		
		return float(exp_in_level) / float(exp_needed)
	
	## Add experience and return number of possible level-ups (no actual level change, count only)
	func add_experience(amount: int) -> int:
		experience += amount
		push_error("[EXP] Adventurer.add_experience(%d): total exp now %d" % [amount, experience])
		
		# Count all reachable level-ups (without actually changing level)
		var levels_gained = 0
		var next_level = level + 1
		while EXP_PER_LEVEL.has(next_level) and experience >= EXP_PER_LEVEL[next_level]:
			levels_gained += 1
			next_level += 1
		
		push_error("  [STAT] Levels available to gain: %d" % levels_gained)
		# Return number of levels gained at once (0 = no level-up, 1+ = level-up count)
		return levels_gained
	
	## Process level-up
	func level_up() -> Dictionary:
		if not EXP_PER_LEVEL.has(level + 1):
			push_error("  [X] level_up(): Max level reached!")
			return {}  # Max level reached
		
		level += 1
		push_error("  [ROLL] level_up(): Now level %d" % level)
		
		# Stat increase
		var hp_increase = 10 + (level - 1) * 2  # +2 per level
		base_hp += hp_increase
		current_hp = base_hp
		
		var speed_increase = 0.02  # +2% per level
		base_speed *= (1.0 + speed_increase)
		
		return {
			"level": level,
			"hp_increase": hp_increase,
			"new_hp": base_hp,
			"new_speed": base_speed
		}
	
	## Equip item
	func equip_item(item: Dictionary) -> bool:
		# Remove existing item in the same slot
		var item_type = item.get("type", "")
		var item_subtype = item.get("subtype", "")
		
		for i in range(equipped_items.size()):
			if equipped_items[i].get("type") == item_type and equipped_items[i].get("subtype") == item_subtype:
				equipped_items.remove_at(i)
				break
		
		# Max 3 items limit (weapon 1, armor 1, accessory 1)
		if equipped_items.size() >= 3:
			equipped_items.pop_back()
		
		equipped_items.append(item)
		return true
	
	## Unequip item
	func unequip_item(item_index: int) -> Dictionary:
		if item_index < 0 or item_index >= equipped_items.size():
			return {}
		var item = equipped_items[item_index]
		equipped_items.remove_at(item_index)
		return item
	
	## Start exploration
	func start_exploration(tier: int) -> void:
		if is_exploring:
			return
		is_exploring = true
		current_dungeon_tier = tier
		exploration_start_time = Time.get_ticks_msec() / 1000.0
		exploration_duration = calculate_exploration_time(tier)
	
	## Exploration progress (0.0 ~ 1.0)
	func get_exploration_progress() -> float:
		if not is_exploring:
			return 0.0
		var elapsed = (Time.get_ticks_msec() / 1000.0) - exploration_start_time
		return minf(elapsed / exploration_duration, 1.0)
	
	## Check if exploration is complete
	func is_exploration_complete() -> bool:
		if not is_exploring:
			return false
		return get_exploration_progress() >= 1.0
	
	## Finish exploration
	func finish_exploration() -> Dictionary:
		if not is_exploring:
			return {}
		
		is_exploring = false
		
		var result = {
			"adventurer_id": id,
			"tier": current_dungeon_tier,
			"timestamp": Time.get_ticks_msec()
		}
		
		return result


# Adventurer management
var adventurers: Dictionary[String, Adventurer] = {}
var adventurer_data: Dictionary = {}
var abilities_data: Dictionary = {}

func _ready() -> void:
	push_error("[OK] AdventureSystem._ready() called")
	_load_data()
	push_error("[OK] AdventureSystem._ready() - _load_data() completed, adventurers: %d" % adventurers.size())


func _load_data() -> void:
	push_error("[LOAD] AdventureSystem._load_data() START - adventurers.size(): %d" % adventurers.size())
	
	# Skip if already loaded (prevent duplicate loading)
	if not adventurers.is_empty() and not adventurer_data.is_empty():
		push_error("[SKIP]  AdventureSystem._load_data(): Already loaded, skipping")
		return
	
	# TEST: Hardcoded 1 adventurer for testing (initial verification)
	push_error("[TEST] TEST MODE: Adding hardcoded adventurer (verification)")
	var test_adv = Adventurer.new(
		"test_adventurer",
		"Test Warrior",
		"Hardcoded test adventurer",
		"warrior",
		100,
		1.0,
		"res://resources/assets/dungeon-crawl/player/player_m_idle_anim_f0.png",
		1,
		0,
		false
	)
	adventurers["test_adventurer"] = test_adv
	push_error("[OK] TEST: Test adventurer added - current adventurers.size(): %d" % adventurers.size())
	
	# Load adventurer data
	var adventurer_file = FileAccess.open("res://resources/data/adventurers.json", FileAccess.READ)
	if adventurer_file:
		push_error("[FILE] Successfully opened adventurers.json")
		var json_text = adventurer_file.get_as_text()
		push_error("[DOC] JSON content length: %d chars" % json_text.length())
		
		var parsed = JSON.parse_string(json_text)
		push_error("  Parsed type: %s" % typeof(parsed))
		push_error("  Parsed is null: %s" % ("[OK]" if parsed == null else "[X]"))
		push_error("  Parsed is Array: %s" % ("[OK]" if parsed is Array else "[X]"))
		push_error("  Parsed is Dictionary: %s" % ("[OK]" if parsed is Dictionary else "[X]"))
		
		if parsed != null and parsed is Dictionary:
			adventurer_data = parsed
			push_error("[DATA] Successfully assigned adventurer_data: %d entries" % adventurer_data.size())
		else:
			push_error("[X] Failed to parse JSON as Dictionary! Got: %s" % typeof(parsed))
			adventurer_file.close()
			return
		
		adventurer_file.close()
		
		# Create initial adventurers
		var created_count = 0
		for adv_id in adventurer_data:
			var data = adventurer_data[adv_id]
			push_error("  [ADD] Creating adventurer: %s (name: %s)" % [adv_id, data.get("name", "?")])
			
			# Validate data
			if not data.has("name"):
				push_error("    [X] Missing 'name' field!")
				continue
			if not data.has("base_hp"):
				push_error("    [X] Missing 'base_hp' field!")
				continue
			if not data.has("base_speed"):
				push_error("    [X] Missing 'base_speed' field!")
				continue
			if not data.has("portrait"):
				push_error("    [X] Missing 'portrait' field!")
				continue
			
			var adv = Adventurer.new(
				adv_id,
				data["name"],
				data["description"],
				data.get("class", "warrior"),
				data["base_hp"],
				data["base_speed"],
				data["portrait"],
				data.get("level", 1),
				data.get("experience", 0),
				data.get("hired", false)
			)
			adventurers[adv_id] = adv
			created_count += 1
			push_error("    [OK] Successfully created, total adventurers now: %d" % adventurers.size())
		
		push_error("[OK] AdventureSystem: Created %d adventurers (final dict size: %d)" % [created_count, adventurers.size()])
	else:
		push_error("[X] AdventureSystem: Could not find adventurers.json!")
	
	# Load abilities data
	var abilities_file = FileAccess.open("res://resources/data/abilities.json", FileAccess.READ)
	if abilities_file:
		push_error("[FILE] Successfully opened abilities.json")
		var abilities_text = abilities_file.get_as_text()
		var parsed_abilities = JSON.parse_string(abilities_text)
		
		if parsed_abilities != null and parsed_abilities is Dictionary:
			abilities_data = parsed_abilities
			push_error("[DATA] Successfully loaded abilities_data with %d classes" % abilities_data.size())
		else:
			push_error("[X] Failed to parse abilities.json!")
		
		abilities_file.close()
		
		# Unlock initial abilities (find abilities that unlock at level 1)
		_unlock_initial_abilities()
	else:
		push_error("[WARN]  Could not open abilities.json - continuing without abilities")


## Unlock initial abilities (level 1 abilities for all adventurers)
func _unlock_initial_abilities() -> void:
	for adv_id in adventurers:
		var adv = adventurers[adv_id]
		var class_abilities = _get_class_abilities(adv.character_class)
		
		for ability in class_abilities:
			if ability.get("unlock_level", 1) == 1:
				var ability_id = ability.get("id", "")
				if not ability_id.is_empty() and not ability_id in adv.unlocked_abilities:
					adv.unlocked_abilities.append(ability_id)


## Get abilities by adventurer class
func _get_class_abilities(character_class: String) -> Array:
	var class_key = character_class + "_abilities"
	if abilities_data.has(class_key):
		var result = abilities_data[class_key]
		if result is Array:
			push_error("  [OK] _get_class_abilities(%s): Found %d abilities" % [character_class, result.size()])
			return result as Array
		else:
			push_error("  [X] _get_class_abilities(%s): NOT an Array! Type: %s" % [character_class, typeof(result)])
			return []
	push_error("  [WARN]  _get_class_abilities(%s): Key not found in abilities_data" % character_class)
	return []


## Get adventurer
func get_adventurer(adventurer_id: String) -> Adventurer:
	return adventurers.get(adventurer_id)


## Get all adventurers
func get_all_adventurers() -> Array[Adventurer]:
	push_error("[LOAD] get_all_adventurers() called")
	push_error("  adventurers.size() = %d" % adventurers.size())
	push_error("  adventurers.values().size() = %d" % adventurers.values().size())
	
	var result: Array[Adventurer] = []
	for adv_id in adventurers:
		var adv = adventurers[adv_id]
		push_error("  Adding: %s (id: %s)" % [adv.name if adv else "NULL", adv_id])
		result.append(adv)
	
	push_error("[OK] get_all_adventurers() returning %d adventurers" % result.size())
	return result


## Get hired adventurers only
func get_hired_adventurers() -> Array[Adventurer]:
	var result: Array[Adventurer] = []
	for adv in adventurers.values():
		if adv.hired:
			result.append(adv)
	return result


## Get available (unhired) adventurers
func get_available_adventurers() -> Array[Adventurer]:
	var result: Array[Adventurer] = []
	for adv in adventurers.values():
		if not adv.hired:
			result.append(adv)
	return result


## Hire adventurer
func hire_adventurer(adventurer_id: String) -> bool:
	var adv = get_adventurer(adventurer_id)
	if not adv or adv.hired:
		return false
	
	adv.hired = true
	return true


## Equip item to adventurer
func equip_to_adventurer(adventurer_id: String, item: Dictionary) -> bool:
	var adv = get_adventurer(adventurer_id)
	if not adv:
		return false
	return adv.equip_item(item)


## Unequip item from adventurer
func unequip_from_adventurer(adventurer_id: String, item_index: int) -> Dictionary:
	var adv = get_adventurer(adventurer_id)
	if not adv:
		return {}
	return adv.unequip_item(item_index)


## Start adventurer exploration
func start_adventure(adventurer_id: String, dungeon_tier: int) -> bool:
	var adv = get_adventurer(adventurer_id)
	if not adv or adv.is_exploring:
		return false
	adv.start_exploration(dungeon_tier)
	return true


## Check if adventurer exploration is complete
func check_exploration_complete(adventurer_id: String) -> bool:
	var adv = get_adventurer(adventurer_id)
	if not adv:
		return false
	return adv.is_exploration_complete()


## Add experience and check for level-up
func add_experience(adventurer_id: String, amount: int) -> int:
	var adv = get_adventurer(adventurer_id)
	if not adv:
		return 0
	
	return adv.add_experience(amount)


## Process level-up
func level_up(adventurer_id: String) -> Dictionary:
	var adv = get_adventurer(adventurer_id)
	if not adv:
		return {}
	
	var level_up_result = adv.level_up()
	
	# Check for newly unlocked abilities at the new level
	var class_abilities = _get_class_abilities(adv.character_class)
	var new_abilities: Array[String] = []
	for ability in class_abilities:
		var ability_id = ability.get("id", "")
		if ability.get("unlock_level") == adv.level:
			if not ability_id.is_empty() and not ability_id in adv.unlocked_abilities:
				adv.unlocked_abilities.append(ability_id)
				new_abilities.append(ability_id)
	if not new_abilities.is_empty():
		level_up_result["new_abilities"] = new_abilities
	
	return level_up_result


## Get unlocked abilities for adventurer
func get_unlocked_abilities(adventurer_id: String) -> Array[Dictionary]:
	var adv = get_adventurer(adventurer_id)
	if not adv:
		return []
	
	var result: Array[Dictionary] = []
	var class_abilities = _get_class_abilities(adv.character_class)
	
	# Create map to index abilities by ID
	var ability_map: Dictionary = {}
	for ability in class_abilities:
		var ability_id = ability.get("id", "")
		if not ability_id.is_empty():
			ability_map[ability_id] = ability
	
	# Add only unlocked abilities to result
	for ability_id in adv.unlocked_abilities:
		if ability_map.has(ability_id):
			result.append(ability_map[ability_id])
	
	return result


## Get all class abilities for adventurer (including lock state)
func get_all_class_abilities(adventurer_id: String) -> Array[Dictionary]:
	var adv = get_adventurer(adventurer_id)
	if not adv:
		return []
	
	var result: Array[Dictionary] = []
	var class_abilities = _get_class_abilities(adv.character_class)
	
	for ability in class_abilities:
		var ability_with_lock = ability.duplicate()
		ability_with_lock["is_unlocked"] = ability.get("id") in adv.unlocked_abilities
		result.append(ability_with_lock)
	
	return result


## ===== Debug helper methods =====

## Current state diagnostics
func get_debug_info() -> Dictionary:
	var info = {
		"adventurers_count": adventurers.size(),
		"adventurer_data_count": adventurer_data.size(),
		"abilities_data_count": abilities_data.size(),
		"adventurer_ids": [],
		"adventurer_names": []
	}
	
	for adv_id in adventurers:
		info["adventurer_ids"].append(adv_id)
		var adv = adventurers[adv_id]
		if adv:
			info["adventurer_names"].append(adv.name)
	
	return info
