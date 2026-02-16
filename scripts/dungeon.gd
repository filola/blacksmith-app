extends Node

## 던전 시스템 - 보상 테이블, 탐험 처리

class_name Dungeon

# 던전 난이도별 보상 설정
var dungeon_rewards: Dictionary = {
	1: {
		"min_gold": 10,
		"max_gold": 30,
		"common_items": 1.5,  # 평균 1.5개
		"artifact_chance": 0.08,  # 8% 유물
		"possible_artifacts": ["cursed_ring"]
	},
	2: {
		"min_gold": 30,
		"max_gold": 70,
		"common_items": 2.0,
		"artifact_chance": 0.12,  # 12%
		"possible_artifacts": ["cursed_ring", "golden_amulet", "dragon_scale", "shadow_cloak"]
	},
	3: {
		"min_gold": 70,
		"max_gold": 150,
		"common_items": 2.5,
		"artifact_chance": 0.15,
		"possible_artifacts": ["golden_amulet", "dragon_scale", "holy_grail", "eternal_blade", "shadow_cloak"]
	},
	4: {
		"min_gold": 150,
		"max_gold": 250,
		"common_items": 3.0,
		"artifact_chance": 0.18,
		"possible_artifacts": ["golden_amulet", "dragon_scale", "holy_grail", "eternal_blade", "shadow_cloak"]
	},
	5: {
		"min_gold": 250,
		"max_gold": 400,
		"common_items": 3.5,
		"artifact_chance": 0.20,
		"possible_artifacts": ["holy_grail", "eternal_blade", "dragon_scale"]
	}
}

var artifact_data: Dictionary = {}

func _ready() -> void:
	_load_artifact_data()


func _load_artifact_data() -> void:
	var artifact_file = FileAccess.open("res://resources/data/artifacts.json", FileAccess.READ)
	if artifact_file:
		artifact_data = JSON.parse_string(artifact_file.get_as_text())
		artifact_file.close()


## 던전 탐험 보상 계산 (경험치 포함)
func generate_rewards(dungeon_tier: int, adventurer_level: int = 1) -> Dictionary:
	if not dungeon_rewards.has(dungeon_tier):
		dungeon_tier = 1
	
	var reward_config = dungeon_rewards[dungeon_tier]
	var rewards = {
		"gold": 0,
		"items": [],  # 일반 아이템 (쿼터)
		"artifacts": [],  # 유물
		"experience": 0  # 경험치
	}
	
	# 골드
	rewards["gold"] = randi_range(reward_config["min_gold"], reward_config["max_gold"])
	
	# 일반 아이템 수 (평균)
	var item_count = int(reward_config["common_items"])
	if randf() < (reward_config["common_items"] - int(reward_config["common_items"])):
		item_count += 1
	
	# 임시: 쿼터 드롭 (나중에 게임매니저에서 제공)
	for i in range(item_count):
		var ore_id = _get_random_ore_for_tier(dungeon_tier)
		var quantity = randi_range(1, 3)
		rewards["items"].append({"ore_id": ore_id, "quantity": quantity})
	
	# 유물
	if randf() < reward_config["artifact_chance"]:
		var artifact_id = _get_random_artifact(reward_config["possible_artifacts"])
		if artifact_data.has(artifact_id):
			var artifact = artifact_data[artifact_id].duplicate()
			artifact["is_artifact"] = true  # 표시
			artifact["acquired_tier"] = dungeon_tier
			rewards["artifacts"].append(artifact)
	
	# 경험치 (난이도와 모험가 레벨에 따라)
	var base_exp = 50 + dungeon_tier * 20  # 기본 경험치
	var level_scaling = 1.0 - (max(0, adventurer_level - dungeon_tier) * 0.05)  # 레벨 차이에 따른 스케일
	level_scaling = max(level_scaling, 0.3)  # 최소 30%
	
	rewards["experience"] = int(base_exp * level_scaling)
	
	return rewards


## 던전 난이도에 맞는 랜덤 광석
func _get_random_ore_for_tier(tier: int) -> String:
	var ores = ["copper", "tin", "iron", "silver", "gold", "mithril", "orichalcum"]
	var available_ores = []
	
	for ore in ores:
		# 난이도 적응형: 높은 난이도에서도 낮은 광석 드롭 가능하지만, 높은 광석이 더 자주
		var min_tier = 1
		match ore:
			"copper", "tin": min_tier = 1
			"iron", "silver": min_tier = 2
			"gold": min_tier = 3
			"mithril": min_tier = 4
			"orichalcum": min_tier = 5
		
		if tier >= min_tier:
			available_ores.append(ore)
	
	return available_ores[randi() % available_ores.size()]


## 사용 가능한 유물 중 랜덤
func _get_random_artifact(possible_artifacts: Array) -> String:
	if possible_artifacts.is_empty():
		return ""
	return possible_artifacts[randi() % possible_artifacts.size()]


## 난이도별 예상 탐험 시간 (초)
func get_estimated_exploration_time(tier: int, speed_multiplier: float = 1.0) -> float:
	var base_time = 30.0 + (tier - 1) * 30.0
	return base_time / speed_multiplier
