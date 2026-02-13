extends Node

## 모험가 시스템

class_name AdventureSystem

# 모험가 클래스
class Adventurer:
	var id: String
	var name: String
	var description: String
	var base_hp: int
	var base_speed: float
	var portrait: String
	
	# 런타임 상태
	var current_hp: int
	var is_exploring: bool = false
	var exploration_start_time: float = 0.0
	var exploration_duration: float = 0.0  # 초 단위
	var current_dungeon_tier: int = 1
	
	# 장착 아이템
	var equipped_items: Array[Dictionary] = []  # 최대 3개 (무기, 갑옷, 악세서리)
	
	func _init(p_id: String, p_name: String, p_description: String, p_hp: int, p_speed: float, p_portrait: String) -> void:
		id = p_id
		name = p_name
		description = p_description
		base_hp = p_hp
		current_hp = p_hp
		base_speed = p_speed
		portrait = p_portrait
	
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
				data["base_hp"],
				data["base_speed"],
				data["portrait"]
			)
			adventurers[adv_id] = adv


## 모험가 획득
func get_adventurer(adventurer_id: String) -> Adventurer:
	return adventurers.get(adventurer_id)


## 모든 모험가 획득
func get_all_adventurers() -> Array[Adventurer]:
	var result: Array[Adventurer] = []
	for adv in adventurers.values():
		result.append(adv)
	return result


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
