extends Node

## 게임 전역 상태 관리

# 시그널
signal gold_changed(amount: int)
signal ore_changed(ore_id: String, amount: int)
signal bar_changed(ore_id: String, amount: int)
signal item_crafted(item_name: String, grade: String)
signal reputation_changed(amount: int)
signal exploration_started(adventurer_id: String, tier: int)
signal exploration_completed(adventurer_id: String, rewards: Dictionary)
signal item_equipped(adventurer_id: String, item: Dictionary)
signal item_unequipped(adventurer_id: String, item: Dictionary)

# Phase 3 시그널
signal adventurer_hired(adventurer_id: String, cost: int)
signal experience_gained(adventurer_id: String, amount: int)
signal adventurer_leveled_up(adventurer_id: String, new_level: int, stat_changes: Dictionary)
signal tier_unlocked(tier: int)

# 재화
var gold: int = 0 :
	set(value):
		gold = value
		gold_changed.emit(gold)

var reputation: int = 0 :
	set(value):
		reputation = value
		reputation_changed.emit(reputation)

# 인벤토리 - 광석, 주괴, 제작 아이템
var ores: Dictionary = {}
var bars: Dictionary = {}
var inventory: Array[Dictionary] = []

# 업그레이드
var pickaxe_level: int = 1
var anvil_level: int = 1
var furnace_level: int = 1
var auto_mine_speed: float = 0.0  # 0이면 자동채굴 없음

# 숙련도 (레시피별 제작 횟수)
var mastery: Dictionary = {}

# 해금된 월드 티어
var max_unlocked_tier: int = 1

# 데이터
var ore_data: Dictionary = {}
var recipe_data: Dictionary = {}
var artifact_data: Dictionary = {}
var adventurer_data: Dictionary = {}
var abilities_data: Dictionary = {}

# 시스템
var adventure_system: AdventureSystem
var dungeon: Dungeon

# 등급 시스템
const GRADES = {
	"common":    {"name": "일반", "color": "#ffffff", "multiplier": 1.0, "emoji": "⬜"},
	"uncommon":  {"name": "고급", "color": "#4caf50", "multiplier": 1.5, "emoji": "🟢"},
	"rare":      {"name": "레어", "color": "#2196f3", "multiplier": 2.5, "emoji": "🔵"},
	"epic":      {"name": "에픽", "color": "#9c27b0", "multiplier": 5.0, "emoji": "🟣"},
	"legendary": {"name": "전설", "color": "#ff9800", "multiplier": 10.0, "emoji": "🟠"}
}

const BASE_GRADE_CHANCES = {
	"common": 60.0,
	"uncommon": 25.0,
	"rare": 10.0,
	"epic": 4.0,
	"legendary": 1.0
}


func _ready() -> void:
	_load_data()


func _load_data() -> void:
	# 광석 데이터 로드
	var ore_file = FileAccess.open("res://resources/data/ores.json", FileAccess.READ)
	if ore_file:
		ore_data = JSON.parse_string(ore_file.get_as_text())
		ore_file.close()
		# 광석/주괴 인벤토리 초기화
		for ore_id in ore_data:
			ores[ore_id] = 0
			bars[ore_id] = 0

	# 레시피 데이터 로드
	var recipe_file = FileAccess.open("res://resources/data/recipes.json", FileAccess.READ)
	if recipe_file:
		recipe_data = JSON.parse_string(recipe_file.get_as_text())
		recipe_file.close()
	
	# 유물 데이터 로드
	var artifact_file = FileAccess.open("res://resources/data/artifacts.json", FileAccess.READ)
	if artifact_file:
		artifact_data = JSON.parse_string(artifact_file.get_as_text())
		artifact_file.close()
	
	# 모험가 데이터 로드
	var adventurer_file = FileAccess.open("res://resources/data/adventurers.json", FileAccess.READ)
	if adventurer_file:
		adventurer_data = JSON.parse_string(adventurer_file.get_as_text())
		adventurer_file.close()
	
	# 능력 데이터 로드
	var abilities_file = FileAccess.open("res://resources/data/abilities.json", FileAccess.READ)
	if abilities_file:
		abilities_data = JSON.parse_string(abilities_file.get_as_text())
		abilities_file.close()
	
	# 시스템 초기화
	adventure_system = AdventureSystem.new()
	add_child(adventure_system)
	dungeon = Dungeon.new()
	add_child(dungeon)
	
	# 테스트용 초기 리소스 (첫 실행)
	if ores.get("copper", 0) == 0:
		gold = 100
		ores["copper"] = 10
		ores["tin"] = 5
		bars["copper"] = 3
		bars["tin"] = 2


## 광석 추가
func add_ore(ore_id: String, amount: int = 1) -> void:
	if ores.has(ore_id):
		ores[ore_id] += amount
		ore_changed.emit(ore_id, ores[ore_id])


## 광석 → 주괴 제련
func smelt_ore(ore_id: String) -> bool:
	if not ore_data.has(ore_id):
		return false
	var needed = ore_data[ore_id]["ore_per_bar"]
	if ores[ore_id] >= needed:
		ores[ore_id] -= needed
		bars[ore_id] += 1
		ore_changed.emit(ore_id, ores[ore_id])
		bar_changed.emit(ore_id, bars[ore_id])
		return true
	return false


## 제작 가능 여부 확인
func can_craft(recipe_id: String) -> bool:
	if not recipe_data.has(recipe_id):
		return false
	var recipe = recipe_data[recipe_id]
	if not recipe.get("unlocked", false):
		return false
	for mat_id in recipe["materials"]:
		if bars.get(mat_id, 0) < recipe["materials"][mat_id]:
			return false
	return true


## 아이템 제작 (랜덤 등급)
func craft_item(recipe_id: String) -> Dictionary:
	if not can_craft(recipe_id):
		return {}

	var recipe = recipe_data[recipe_id]

	# 재료 소모
	for mat_id in recipe["materials"]:
		bars[mat_id] -= recipe["materials"][mat_id]
		bar_changed.emit(mat_id, bars[mat_id])

	# 등급 결정
	var grade = _roll_grade(recipe_id)
	var grade_info = GRADES[grade]

	# 아이템 생성
	var item = {
		"recipe_id": recipe_id,
		"name": recipe["name"],
		"type": recipe["type"],
		"subtype": recipe.get("subtype", ""),
		"grade": grade,
		"grade_name": grade_info["name"],
		"grade_color": grade_info["color"],
		"grade_emoji": grade_info["emoji"],
		"price": int(recipe["base_price"] * grade_info["multiplier"]),
		"tier": recipe["tier"],
		"is_artifact": false  # 일반 아이템
	}

	inventory.append(item)

	# 숙련도 증가
	mastery[recipe_id] = mastery.get(recipe_id, 0) + 1

	item_crafted.emit(item["name"], grade)
	return item


## 등급 굴림 (확률 강화 반영)
func _roll_grade(recipe_id: String) -> String:
	var chances = BASE_GRADE_CHANCES.duplicate()

	# 모루 보너스: 레벨당 레어 이상 확률 +0.5%
	var anvil_bonus = (anvil_level - 1) * 0.5
	chances["rare"] += anvil_bonus * 0.5
	chances["epic"] += anvil_bonus * 0.3
	chances["legendary"] += anvil_bonus * 0.2
	chances["common"] -= anvil_bonus

	# 숙련도 보너스: 10회당 +1%
	var craft_count = mastery.get(recipe_id, 0)
	var mastery_bonus = floor(craft_count / 10.0) * 1.0
	mastery_bonus = min(mastery_bonus, 15.0)  # 최대 15%
	chances["uncommon"] += mastery_bonus * 0.4
	chances["rare"] += mastery_bonus * 0.3
	chances["epic"] += mastery_bonus * 0.2
	chances["legendary"] += mastery_bonus * 0.1
	chances["common"] -= mastery_bonus

	# common이 음수 되지 않게
	chances["common"] = max(chances["common"], 5.0)

	# 확률 정규화
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


## 아이템 판매
func sell_item(index: int) -> int:
	if index < 0 or index >= inventory.size():
		return 0
	var item = inventory[index]
	var price = item["price"]
	gold += price
	reputation += 1
	inventory.remove_at(index)
	return price


## 채굴 파워 계산
func get_mine_power() -> float:
	return 1.0 + (pickaxe_level - 1) * 0.5


## ===== 모험가 시스템 =====

## 모든 모험가 획득
func get_adventurers() -> Array:
	if not adventure_system:
		return []
	return adventure_system.get_all_adventurers()


## 특정 모험가 획득
func get_adventurer(adventurer_id: String):
	if not adventure_system:
		return null
	return adventure_system.get_adventurer(adventurer_id)


## 모험가에게 아이템 장착
func equip_item_to_adventurer(adventurer_id: String, inventory_index: int) -> bool:
	if inventory_index < 0 or inventory_index >= inventory.size():
		return false
	
	var item = inventory[inventory_index]
	if not adventure_system or not adventure_system.equip_to_adventurer(adventurer_id, item):
		return false
	
	# 인벤토리에서 제거
	inventory.remove_at(inventory_index)
	item_equipped.emit(adventurer_id, item)
	return true


## 모험가에게서 아이템 해제
func unequip_item_from_adventurer(adventurer_id: String, item_index: int) -> bool:
	if not adventure_system:
		return false
	
	var item = adventure_system.unequip_from_adventurer(adventurer_id, item_index)
	if item.is_empty():
		return false
	
	# 인벤토리에 추가
	inventory.append(item)
	item_unequipped.emit(adventurer_id, item)
	return true


## 모험가 탐험 시작
func start_exploration(adventurer_id: String, dungeon_tier: int) -> bool:
	if not adventure_system:
		return false
	
	var success = adventure_system.start_adventure(adventurer_id, dungeon_tier)
	if success:
		exploration_started.emit(adventurer_id, dungeon_tier)
	return success


## 탐험 완료 확인 및 보상 처리
func check_and_complete_exploration(adventurer_id: String) -> Dictionary:
	if not adventure_system or not dungeon:
		return {}
	
	if not adventure_system.check_exploration_complete(adventurer_id):
		return {}
	
	var adv = adventure_system.get_adventurer(adventurer_id)
	if not adv:
		return {}
	
	# 탐험 종료 처리
	var exploration_data = adv.finish_exploration()
	if exploration_data.is_empty():
		return {}
	
	# 보상 생성
	var rewards = dungeon.generate_rewards(adv.current_dungeon_tier, adv.level)
	
	# 보상 적용
	gold += rewards["gold"]
	
	# 광석 추가
	for ore_reward in rewards["items"]:
		add_ore(ore_reward["ore_id"], ore_reward["quantity"])
	
	# 유물 인벤토리 추가
	for artifact in rewards["artifacts"]:
		inventory.append(artifact)
	
	# 경험치 처리 (Phase 3)
	if rewards.has("experience"):
		_process_experience(adventurer_id, rewards["experience"])
	
	# 탐험 완료 후 추가 티어 언락 체크
	_check_tier_unlock()
	
	exploration_data["rewards"] = rewards
	exploration_completed.emit(adventurer_id, exploration_data)
	
	return exploration_data


## ===== Phase 3: 모험가 고용 & 레벨업 시스템 =====

## 모험가 고용
func hire_adventurer(adventurer_id: String) -> bool:
	var adv = adventure_system.get_adventurer(adventurer_id)
	if not adv or adv.hired:
		return false
	
	var hire_data = adventurer_data.get(adventurer_id, {})
	var hire_cost = hire_data.get("hire_cost", 100)
	
	if gold < hire_cost:
		return false
	
	gold -= hire_cost
	adventure_system.hire_adventurer(adventurer_id)
	adventurer_hired.emit(adventurer_id, hire_cost)
	
	# 새 티어 언락 확인
	_check_tier_unlock()
	
	return true


## 고용된 모험가만 조회
func get_hired_adventurers() -> Array:
	if not adventure_system:
		return []
	return adventure_system.get_hired_adventurers()


## 미고용 모험가 조회
func get_available_adventurers() -> Array:
	if not adventure_system:
		return []
	return adventure_system.get_available_adventurers()


## 모험가 고용 비용 조회
func get_hire_cost(adventurer_id: String) -> int:
	var data = adventurer_data.get(adventurer_id, {})
	return data.get("hire_cost", 100)


## 경험치 처리 및 레벨업
func _process_experience(adventurer_id: String, amount: int) -> void:
	if not adventure_system:
		return
	
	var adv = adventure_system.get_adventurer(adventurer_id)
	if not adv:
		return
	
	# 경험치 추가 및 레벨업 수 확인
	var levels_gained = adventure_system.add_experience(adventurer_id, amount)
	experience_gained.emit(adventurer_id, amount)
	
	# 레벨업 처리 (연속 레벨업 지원)
	if levels_gained > 0:
		for i in range(levels_gained):
			var level_up_result = adventure_system.level_up(adventurer_id)
			if not level_up_result.is_empty():
				var new_level = level_up_result.get("level", adv.level)
				adventurer_leveled_up.emit(adventurer_id, new_level, level_up_result)
		
		# 새 티어 언락 확인
		_check_tier_unlock()


## 월드 티어 자동 언락
func _check_tier_unlock() -> void:
	var hired_adventurers = adventure_system.get_hired_adventurers()
	if hired_adventurers.is_empty():
		return
	
	# 티어별 언락 조건
	var unlock_conditions = {
		2: {"min_adventurers": 2, "min_level": 3},
		3: {"min_adventurers": 3, "min_level": 5},
		4: {"min_adventurers": 4, "min_level": 7},
		5: {"min_adventurers": 5, "min_level": 10},
		6: {"min_adventurers": 6, "min_level": 12}
	}
	
	for tier in unlock_conditions:
		if max_unlocked_tier >= tier:
			continue
		
		var condition = unlock_conditions[tier]
		
		# 조건 확인
		if hired_adventurers.size() < condition["min_adventurers"]:
			continue
		
		var meets_level = true
		for adv in hired_adventurers:
			if adv.level < condition["min_level"]:
				meets_level = false
				break
		
		if meets_level:
			max_unlocked_tier = tier
			tier_unlocked.emit(tier)


## 평균 모험가 레벨 계산
func get_average_adventurer_level() -> float:
	var hired_adventurers = adventure_system.get_hired_adventurers()
	if hired_adventurers.is_empty():
		return 1.0
	
	var total_level = 0
	for adv in hired_adventurers:
		total_level += adv.level
	
	return float(total_level) / float(hired_adventurers.size())


## 모험가의 해금된 능력 조회
func get_unlocked_abilities(adventurer_id: String) -> Array:
	if not adventure_system:
		return []
	return adventure_system.get_unlocked_abilities(adventurer_id)


## 모험가의 모든 클래스 능력 조회
func get_all_class_abilities(adventurer_id: String) -> Array:
	if not adventure_system:
		return []
	return adventure_system.get_all_class_abilities(adventurer_id)
