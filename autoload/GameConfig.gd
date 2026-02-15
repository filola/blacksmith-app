## GameConfig.gd - 게임 밸런스 상수 관리
## 모든 매직 넘버를 한 곳에서 관리하여 결합도 낮추기
## Note: class_name removed to avoid conflict with autoload singleton

# ============================================
# 채굴 시스템
# ============================================
const PICKAXE_POWER_BASE = 1.0
const PICKAXE_POWER_PER_LEVEL = 0.5  # 레벨당 증가량


# ============================================
# 제련 시스템 (현재 1:1 제련만 지원)
# ============================================
# ore_data.json에서 ore_per_bar로 관리


# ============================================
# 모루 강화 시스템
# ============================================
const ANVIL_BONUS_PER_LEVEL = 0.5  # 레벨당 보너스 퍼센트
const ANVIL_RARE_WEIGHT = 0.5
const ANVIL_EPIC_WEIGHT = 0.3
const ANVIL_LEGENDARY_WEIGHT = 0.2
const ANVIL_COMMON_MIN = 5.0  # 일반 등급 최소값


# ============================================
# 숙련도 강화 시스템
# ============================================
const MASTERY_CRAFT_COUNT_THRESHOLD = 10  # 10회마다 1% 증가
const MASTERY_BONUS_PER_THRESHOLD = 1.0   # 퍼센트
const MASTERY_MAX_BONUS = 15.0             # 최대 15% 보너스
const MASTERY_UNCOMMON_WEIGHT = 0.4
const MASTERY_RARE_WEIGHT = 0.3
const MASTERY_EPIC_WEIGHT = 0.2
const MASTERY_LEGENDARY_WEIGHT = 0.1


# ============================================
# 모험가 시스템 - 고용
# ============================================
const ADVENTURER_HIRE_COST_DEFAULT = 100


# ============================================
# 모험가 시스템 - 경험치
# ============================================
const ADVENTURER_MAX_LEVEL = 15
const ADVENTURER_LEVEL_UP_STAT_GAIN = 2  # 레벨업 시 스탯 증가량


# ============================================
# 월드 티어 언락 시스템
# ============================================
## 각 티어별 언락 조건: 필요 고용 인원 & 최소 레벨
const TIER_UNLOCK_CONDITIONS = {
	2: {"min_adventurers": 2, "min_level": 3},
	3: {"min_adventurers": 3, "min_level": 5},
	4: {"min_adventurers": 4, "min_level": 7},
	5: {"min_adventurers": 5, "min_level": 10},
	6: {"min_adventurers": 6, "min_level": 12}
}

const TIER_MAX = 6
const TIER_DEFAULT = 1


# ============================================
# 초기 리소스 (첫 실행)
# ============================================
const INITIAL_GOLD = 100
const INITIAL_COPPER = 10
const INITIAL_TIN = 5
const INITIAL_COPPER_BAR = 3
const INITIAL_TIN_BAR = 2


# ============================================
# 등급 시스템 (게임 로직에서 참조하는 GRADES는 여기)
# ============================================
const GRADES = {
	"common":    {"name": "일반", "color": "#ffffff", "multiplier": 1.0},
	"uncommon":  {"name": "고급", "color": "#4caf50", "multiplier": 1.5},
	"rare":      {"name": "레어", "color": "#2196f3", "multiplier": 2.5},
	"epic":      {"name": "에픽", "color": "#9c27b0", "multiplier": 5.0},
	"legendary": {"name": "전설", "color": "#ff9800", "multiplier": 10.0}
}

const BASE_GRADE_CHANCES = {
	"common": 60.0,
	"uncommon": 25.0,
	"rare": 10.0,
	"epic": 4.0,
	"legendary": 1.0
}


# ============================================
# 광석 시스템 - 드롭 확률
# ============================================
const ORE_SPAWN_CHANCES = {
	# Tier 1 - 기본 광석
	1: {
		"copper": 50.0,
		"tin": 50.0
	},
	# Tier 2 - 중급 광석
	2: {
		"iron": 50.0,
		"silver": 50.0
	},
	# Tier 3 - 고급 광석
	3: {
		"gold": 100.0
	},
	# Tier 4 - 매우 귀한 광석
	4: {
		"mithril": 100.0
	},
	# Tier 5 - 전설 광석
	5: {
		"orichalcum": 100.0
	}
}
