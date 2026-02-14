extends Node

## 모험가 시스템 - Phase 3 확장: 레벨업, 경험치, 특수 능력

class_name AdventureSystem

# 레벨업 경험치 필요량 (레벨당)
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

# 모험가 클래스
class Adventurer:
	var id: String
	var name: String
	var description: String
	var character_class: String  # warrior, rogue, mage, paladin
	var base_hp: int
	var base_speed: float
	var portrait: String
	
	# 런타임 상태
	var current_hp: int
	var is_exploring: bool = false
	var exploration_start_time: float = 0.0
	var exploration_duration: float = 0.0  # 초 단위
	var current_dungeon_tier: int = 1
	
	# 레벨 & 경험치
	var level: int = 1
	var experience: int = 0
	var hired: bool = false
	
	# 장착 아이템
	var equipped_items: Array[Dictionary] = []  # 최대 3개 (무기, 갑옷, 악세서리)
	
	# 해금된 능력
	var unlocked_abilities: Array[String] = []  # 능력 ID 배열
	
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
	
	## 현재 탐험 속도 배수 계산 (장착 아이템 포함)
	func get_speed_multiplier() -> float:
		var multiplier = base_speed
		for item in equipped_items:
			if item.has("speed_bonus"):
				multiplier *= item["speed_bonus"]
		return multiplier
	
	## 탐험 시간 계산 (초 단위)
	func calculate_exploration_time(dungeon_tier: int) -> float:
		# 기본 시간: 난이도별 30초 ~ 180초
		var base_time = 30.0 + (dungeon_tier - 1) * 30.0
		
		# 속도 배수 적용 (높을수록 빨라짐)
		var speed_mult = get_speed_multiplier()
		return base_time / speed_mult
	
	## 현재 레벨에서 다음 레벨까지 필요한 경험치
	func get_exp_to_next_level() -> int:
		if not EXP_PER_LEVEL.has(level + 1):
			return 999999  # 최대 레벨 도달
		var next_level_exp = EXP_PER_LEVEL[level + 1]
		var current_level_exp = EXP_PER_LEVEL.get(level, 0)
		return next_level_exp - current_level_exp
	
	## 현재 레벨에서의 경험치 진행률 (0.0 ~ 1.0)
	func get_exp_progress() -> float:
		var current_level_exp = EXP_PER_LEVEL.get(level, 0)
		var next_level_exp = EXP_PER_LEVEL.get(level + 1, 999999)
		
		if experience >= next_level_exp:
			return 1.0
		
		var exp_in_level = experience - current_level_exp
		var exp_needed = next_level_exp - current_level_exp
		
		return float(exp_in_level) / float(exp_needed)
	
	## 경험치 추가 및 레벨업 확인 (연속 레벨업 지원)
	func add_experience(amount: int) -> int:
		experience += amount
		
		# 도달 가능한 모든 레벨 업을 카운팅 (실제 레벨 변경 없이)
		var levels_gained = 0
		var next_level = level + 1
		while EXP_PER_LEVEL.has(next_level) and experience >= EXP_PER_LEVEL[next_level]:
			levels_gained += 1
			next_level += 1
		
		# 한 번에 올라간 레벨 수 반환 (0 = 레벨업 없음, 1+ = 레벨업 수)
		return levels_gained
	
	## 레벨업 처리
	func level_up() -> Dictionary:
		if not EXP_PER_LEVEL.has(level + 1):
			return {}  # 최대 레벨 도달
		
		level += 1
		
		# 스텟 상승
		var hp_increase = 10 + (level - 1) * 2  # 레벨마다 2씩 증가
		base_hp += hp_increase
		current_hp = base_hp
		
		var speed_increase = 0.02  # 레벨마다 2% 증가
		base_speed *= (1.0 + speed_increase)
		
		return {
			"level": level,
			"hp_increase": hp_increase,
			"new_hp": base_hp,
			"new_speed": base_speed
		}
	
	## 아이템 장착
	func equip_item(item: Dictionary) -> bool:
		# 같은 슬롯의 기존 아이템 제거
		var item_type = item.get("type", "")
		var item_subtype = item.get("subtype", "")
		
		for i in range(equipped_items.size()):
			if equipped_items[i].get("type") == item_type and equipped_items[i].get("subtype") == item_subtype:
				equipped_items.remove_at(i)
				break
		
		# 최대 3개 제한 (무기 1, 갑옷 1, 악세서리 1)
		if equipped_items.size() >= 3:
			equipped_items.pop_back()
		
		equipped_items.append(item)
		return true
	
	## 아이템 해제
	func unequip_item(item_index: int) -> Dictionary:
		if item_index < 0 or item_index >= equipped_items.size():
			return {}
		var item = equipped_items[item_index]
		equipped_items.remove_at(item_index)
		return item
	
	## 탐험 시작
	func start_exploration(tier: int) -> void:
		if is_exploring:
			return
		is_exploring = true
		current_dungeon_tier = tier
		exploration_start_time = Time.get_ticks_msec() / 1000.0
		exploration_duration = calculate_exploration_time(tier)
	
	## 탐험 진행률 (0.0 ~ 1.0)
	func get_exploration_progress() -> float:
		if not is_exploring:
			return 0.0
		var elapsed = (Time.get_ticks_msec() / 1000.0) - exploration_start_time
		return minf(elapsed / exploration_duration, 1.0)
	
	## 탐험 완료 확인
	func is_exploration_complete() -> bool:
		if not is_exploring:
			return false
		return get_exploration_progress() >= 1.0
	
	## 탐험 완료 처리
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


# 모험가 관리
var adventurers: Dictionary[String, Adventurer] = {}
var adventurer_data: Dictionary = {}
var abilities_data: Dictionary = {}

func _ready() -> void:
	_load_data()


func _load_data() -> void:
	# 모험가 데이터 로드
	var adventurer_file = FileAccess.open("res://resources/data/adventurers.json", FileAccess.READ)
	if adventurer_file:
		adventurer_data = JSON.parse_string(adventurer_file.get_as_text())
		adventurer_file.close()
		
		# 초기 모험가 생성
		for adv_id in adventurer_data:
			var data = adventurer_data[adv_id]
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
	
	# 능력 데이터 로드
	var abilities_file = FileAccess.open("res://resources/data/abilities.json", FileAccess.READ)
	if abilities_file:
		abilities_data = JSON.parse_string(abilities_file.get_as_text())
		abilities_file.close()
		
		# 초기 능력 해금 (레벨 1에서 해금되는 능력 찾기)
		_unlock_initial_abilities()


## 초기 능력 해금 (모든 모험가의 레벨 1 능력)
func _unlock_initial_abilities() -> void:
	for adv_id in adventurers:
		var adv = adventurers[adv_id]
		var class_abilities = _get_class_abilities(adv.character_class)
		
		for ability in class_abilities:
			if ability.get("unlock_level", 1) == 1:
				var ability_id = ability.get("id", "")
				if not ability_id.is_empty() and not ability_id in adv.unlocked_abilities:
					adv.unlocked_abilities.append(ability_id)


## 모험가 클래스별 능력 조회
func _get_class_abilities(character_class: String) -> Array:
	var class_key = character_class + "_abilities"
	if abilities_data.has(class_key):
		return abilities_data[class_key] as Array
	return []


## 모험가 획득
func get_adventurer(adventurer_id: String) -> Adventurer:
	return adventurers.get(adventurer_id)


## 모든 모험가 획득
func get_all_adventurers() -> Array[Adventurer]:
	var result: Array[Adventurer] = []
	for adv in adventurers.values():
		result.append(adv)
	return result


## 고용된 모험가만 획득
func get_hired_adventurers() -> Array[Adventurer]:
	var result: Array[Adventurer] = []
	for adv in adventurers.values():
		if adv.hired:
			result.append(adv)
	return result


## 미고용 모험가 획득
func get_available_adventurers() -> Array[Adventurer]:
	var result: Array[Adventurer] = []
	for adv in adventurers.values():
		if not adv.hired:
			result.append(adv)
	return result


## 모험가 고용
func hire_adventurer(adventurer_id: String) -> bool:
	var adv = get_adventurer(adventurer_id)
	if not adv or adv.hired:
		return false
	
	adv.hired = true
	return true


## 모험가에게 아이템 장착
func equip_to_adventurer(adventurer_id: String, item: Dictionary) -> bool:
	var adv = get_adventurer(adventurer_id)
	if not adv:
		return false
	return adv.equip_item(item)


## 모험가에서 아이템 해제
func unequip_from_adventurer(adventurer_id: String, item_index: int) -> Dictionary:
	var adv = get_adventurer(adventurer_id)
	if not adv:
		return {}
	return adv.unequip_item(item_index)


## 모험가 탐험 시작
func start_adventure(adventurer_id: String, dungeon_tier: int) -> bool:
	var adv = get_adventurer(adventurer_id)
	if not adv or adv.is_exploring:
		return false
	adv.start_exploration(dungeon_tier)
	return true


## 모험가 탐험 완료 확인
func check_exploration_complete(adventurer_id: String) -> bool:
	var adv = get_adventurer(adventurer_id)
	if not adv:
		return false
	return adv.is_exploration_complete()


## 경험치 추가 및 레벨업 확인
func add_experience(adventurer_id: String, amount: int) -> int:
	var adv = get_adventurer(adventurer_id)
	if not adv:
		return 0
	
	return adv.add_experience(amount)


## 레벨업 처리
func level_up(adventurer_id: String) -> Dictionary:
	var adv = get_adventurer(adventurer_id)
	if not adv:
		return {}
	
	var level_up_result = adv.level_up()
	
	# 새 레벨에서 해금되는 능력 확인
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


## 모험가의 해금된 능력 조회
func get_unlocked_abilities(adventurer_id: String) -> Array[Dictionary]:
	var adv = get_adventurer(adventurer_id)
	if not adv:
		return []
	
	var result: Array[Dictionary] = []
	var class_abilities = _get_class_abilities(adv.character_class)
	
	# abilities를 ID로 인덱싱하기 위해 맵 생성
	var ability_map: Dictionary = {}
	for ability in class_abilities:
		var ability_id = ability.get("id", "")
		if not ability_id.is_empty():
			ability_map[ability_id] = ability
	
	# 해금된 능력만 결과에 추가
	for ability_id in adv.unlocked_abilities:
		if ability_map.has(ability_id):
			result.append(ability_map[ability_id])
	
	return result


## 모험가의 모든 클래스 능력 조회 (잠금 상태 포함)
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
