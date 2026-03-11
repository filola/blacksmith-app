extends Node

## GameConfig.gd - Game balance constants management
## Centralized magic numbers to reduce coupling
## Note: class_name removed to avoid conflict with autoload singleton

# ============================================
# Mining System
# ============================================
const PICKAXE_POWER_BASE = 1.0
const PICKAXE_POWER_PER_LEVEL = 0.5  # Increase per level


# ============================================
# Anvil Enhancement System
# ============================================
const ANVIL_BONUS_PER_LEVEL = 0.5  # Bonus percent per level
const ANVIL_RARE_WEIGHT = 0.5
const ANVIL_EPIC_WEIGHT = 0.3
const ANVIL_LEGENDARY_WEIGHT = 0.2
const ANVIL_COMMON_MIN = 5.0  # Common grade minimum value


# ============================================
# Mastery Enhancement System
# ============================================
const MASTERY_CRAFT_COUNT_THRESHOLD = 10  # +1% every 10 crafts
const MASTERY_BONUS_PER_THRESHOLD = 1.0   # Percent
const MASTERY_MAX_BONUS = 15.0             # Max 15% bonus
const MASTERY_UNCOMMON_WEIGHT = 0.4
const MASTERY_RARE_WEIGHT = 0.3
const MASTERY_EPIC_WEIGHT = 0.2
const MASTERY_LEGENDARY_WEIGHT = 0.1


# ============================================
# Adventurer System - Hiring
# ============================================
const ADVENTURER_HIRE_COST_DEFAULT = 100


# ============================================
# Adventurer System - Experience
# ============================================
const ADVENTURER_MAX_LEVEL = 15
const ADVENTURER_LEVEL_UP_STAT_GAIN = 2  # Stat gain per level up


# ============================================
# World Tier Unlock System
# ============================================
## Unlock conditions per tier: required hires & minimum level
const TIER_UNLOCK_CONDITIONS = {
	2: {"min_adventurers": 2, "min_level": 3},
	3: {"min_adventurers": 3, "min_level": 5},
	4: {"min_adventurers": 4, "min_level": 7},
	5: {"min_adventurers": 5, "min_level": 10}
}

const TIER_MAX = 5
const TIER_DEFAULT = 1


# ============================================
# Initial Resources (first run)
# ============================================
const INITIAL_GOLD = 100
const INITIAL_COPPER = 13
const INITIAL_TIN = 7


# ============================================
# Grade System (GRADES referenced by game logic)
# ============================================
const GRADES = {
	"common":    {"name": "Common", "color": "#ffffff", "multiplier": 1.0},
	"uncommon":  {"name": "Uncommon", "color": "#4caf50", "multiplier": 1.5},
	"rare":      {"name": "Rare", "color": "#2196f3", "multiplier": 2.5},
	"epic":      {"name": "Epic", "color": "#9c27b0", "multiplier": 5.0},
	"legendary": {"name": "Legendary", "color": "#ff9800", "multiplier": 10.0}
}

const BASE_GRADE_CHANCES = {
	"common": 60.0,
	"uncommon": 25.0,
	"rare": 10.0,
	"epic": 4.0,
	"legendary": 1.0
}


# ============================================
# Adventurer Class Ore Bonuses
# ============================================
const CLASS_ORE_BONUS = {"warrior": 1.2, "paladin": 1.1, "rogue": 1.0, "mage": 1.0}
const PICKAXE_ORE_BONUS_PER_LEVEL = 0.1

# Exploration time formula: BASE + (tier - 1) * PER_TIER
const EXPLORATION_BASE_TIME = 45.0
const EXPLORATION_TIME_PER_TIER = 30.0


# ============================================
# Equipment Stat System
# ============================================
# Base stats per equipment subtype
const EQUIPMENT_BASE_STATS = {
	# Weapons → attack_power
	"sword":  {"attack_power": 5, "speed_bonus": 1.0},
	"axe":    {"attack_power": 7, "speed_bonus": 0.95},
	"dagger": {"attack_power": 3, "speed_bonus": 1.10},
	"spear":  {"attack_power": 6, "speed_bonus": 1.0},
	"staff":  {"attack_power": 4, "speed_bonus": 1.05},
	# Armor → defense
	"chest":  {"defense": 6, "speed_bonus": 0.95},
	"shield": {"defense": 4, "speed_bonus": 0.98},
}

# Tier multiplier for base stats (higher tier materials = stronger gear)
const EQUIPMENT_TIER_MULTIPLIER = {1: 1.0, 2: 1.5, 3: 2.2, 4: 3.0, 5: 4.5}

# Grade multiplier for stats (better roll = stronger item)
const EQUIPMENT_GRADE_MULTIPLIER = {
	"common": 1.0, "uncommon": 1.3, "rare": 1.6, "epic": 2.0, "legendary": 3.0
}

# Dungeon combat: how equipment stats translate to bonuses
const ATTACK_GOLD_BONUS_PER_POINT = 0.02      # +2% gold per attack point
const ATTACK_ORE_BONUS_PER_POINT = 0.015       # +1.5% ore per attack point
const DEFENSE_EXP_BONUS_PER_POINT = 0.02       # +2% exp per defense point
const DEFENSE_SPEED_BONUS_PER_POINT = 0.01     # +1% speed per defense point


# ============================================
# Party Dungeon System
# ============================================
const MAX_PARTY_SIZE = 4
const MIN_PARTY_SIZE = 1

# Dungeon material drop settings per tier
const DUNGEON_MATERIAL_DROP_CHANCE = {1: 0.6, 2: 0.5, 3: 0.45, 4: 0.4, 5: 0.35}
const DUNGEON_MATERIAL_MIN_QTY = {1: 1, 2: 1, 3: 1, 4: 1, 5: 1}
const DUNGEON_MATERIAL_MAX_QTY = {1: 3, 2: 2, 3: 2, 4: 2, 5: 2}
# Party size bonus: more members = more material drops
const PARTY_SIZE_MATERIAL_BONUS = {1: 1.0, 2: 1.3, 3: 1.6, 4: 2.0}


# ============================================
# Ore System - Drop Rates
# ============================================
const ORE_SPAWN_CHANCES = {
	# Tier 1 - Basic ores
	1: {
		"copper": 50.0,
		"tin": 50.0
	},
	# Tier 2 - Intermediate ores
	2: {
		"iron": 50.0,
		"silver": 50.0
	},
	# Tier 3 - Advanced ores
	3: {
		"gold": 100.0
	},
	# Tier 4 - Very rare ores
	4: {
		"mithril": 100.0
	},
	# Tier 5 - Legendary ores
	5: {
		"orichalcum": 100.0
	}
}
