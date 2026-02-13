extends Control

## 모험가 탭 UI

@onready var adventure_list: ItemList = %AdventureList
@onready var adventurer_name_label: Label = %AdventurerNameLabel
@onready var adventurer_description_label: Label = %AdventurerDescriptionLabel
@onready var adventurer_portrait: TextureRect = %AdventurerPortrait
@onready var equipped_items_container: VBoxContainer = %EquippedItemsContainer
@onready var exploration_progress: ProgressBar = %ExplorationProgress
@onready var exploration_status_label: Label = %ExplorationStatusLabel
@onready var dungeon_tier_spinbox: SpinBox = %DungeonTierSpinBox
@onready var start_exploration_btn: Button = %StartExplorationBtn
@onready var inventory_list: ItemList = %InventoryList

var current_selected_adventurer: String = ""
var exploration_timer: Timer


func _ready() -> void:
	# 노드 검증
	if not adventure_list or not start_exploration_btn or not inventory_list:
		push_error("AdventureTab: 필수 노드를 찾을 수 없습니다!")
		return
	
	# 신호 연결
	GameManager.exploration_started.connect(_on_exploration_started)
	GameManager.exploration_completed.connect(_on_exploration_completed)
	GameManager.item_equipped.connect(_on_item_equipped)
	GameManager.item_unequipped.connect(_on_item_unequipped)
	
	# UI 신호
	adventure_list.item_selected.connect(_on_adventure_selected)
	start_exploration_btn.pressed.connect(_on_start_exploration)
	
	# 탐험 타이머
	exploration_timer = Timer.new()
	add_child(exploration_timer)
	exploration_timer.timeout.connect(_on_exploration_timer_tick)
	exploration_timer.wait_time = 0.1
	
	dungeon_tier_spinbox.min_value = 1
	dungeon_tier_spinbox.max_value = 5
	dungeon_tier_spinbox.value = 1
	
	# 인벤토리 신호
	inventory_list.item_selected.connect(_on_inventory_item_selected)
	
	_refresh_adventure_list()


func _refresh_adventure_list() -> void:
	adventure_list.clear()
	var adventurers = GameManager.get_adventurers()
	
	for adv in adventurers:
		var status = "⏳ 대기중" if not adv.is_exploring else "🚀 탐험중"
		adventure_list.add_item("%s - %s" % [adv.name, status])


func _on_adventure_selected(index: int) -> void:
	var adventurers = GameManager.get_adventurers()
	if index < 0 or index >= adventurers.size():
		return
	
	var adv = adventurers[index]
	current_selected_adventurer = adv.id
	_update_detail_view(adv)


func _update_detail_view(adv) -> void:
	adventurer_name_label.text = adv.name
	adventurer_description_label.text = adv.description
	
	if ResourceLoader.exists(adv.portrait):
		adventurer_portrait.texture = load(adv.portrait)
	
	# 장착 아이템 표시
	_refresh_equipped_items(adv)
	
	# 탐험 상태
	_update_exploration_status(adv)
	
	# 속도 배수 표시
	var speed_text = "속도: %.2f배" % adv.get_speed_multiplier()
	if exploration_status_label:
		exploration_status_label.text = speed_text
	
	# 인벤토리 표시 (장착 가능한 아이템만)
	_refresh_inventory_list()


func _refresh_equipped_items(adv) -> void:
	# 기존 UI 정리
	for child in equipped_items_container.get_children():
		child.queue_free()
	
	# 장착 아이템 표시
	for i in range(adv.equipped_items.size()):
		var item = adv.equipped_items[i]
		var hbox = HBoxContainer.new()
		
		# 아이템 정보
		var item_label = Label.new()
		var speed_bonus = ""
		if item.has("speed_bonus"):
			speed_bonus = " [속도: ×%.2f]" % item["speed_bonus"]
		var artifact_marker = " 🔮" if item.get("is_artifact", false) else ""
		item_label.text = "%s (%s)%s%s" % [item["name"], item.get("type", "?"), speed_bonus, artifact_marker]
		item_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(item_label)
		
		# 해제 버튼
		var unequip_btn = Button.new()
		unequip_btn.text = "해제"
		unequip_btn.custom_minimum_size.x = 50
		var item_index = i
		unequip_btn.pressed.connect(func(): _on_unequip_item(item_index))
		hbox.add_child(unequip_btn)
		
		equipped_items_container.add_child(hbox)
	
	if adv.equipped_items.is_empty():
		var no_items_label = Label.new()
		no_items_label.text = "[장착 아이템 없음]"
		equipped_items_container.add_child(no_items_label)


func _update_exploration_status(adv) -> void:
	start_exploration_btn.disabled = adv.is_exploring
	dungeon_tier_spinbox.editable = not adv.is_exploring
	
	if adv.is_exploring:
		exploration_progress.show()
		exploration_status_label.text = "🚀 탐험중..."
		exploration_timer.start()
	else:
		exploration_progress.hide()
		exploration_timer.stop()


func _on_start_exploration() -> void:
	if current_selected_adventurer.is_empty():
		return
	
	var tier = int(dungeon_tier_spinbox.value)
	var adv = GameManager.get_adventurer(current_selected_adventurer)
	
	if adv and not adv.is_exploring:
		var success = GameManager.start_exploration(current_selected_adventurer, tier)
		if success:
			_update_detail_view(adv)
			_refresh_adventure_list()


func _on_exploration_timer_tick() -> void:
	var adv = GameManager.get_adventurer(current_selected_adventurer)
	if not adv:
		return
	
	if exploration_progress:
		exploration_progress.value = adv.get_exploration_progress() * 100.0
	
	# 완료 확인
	var result = GameManager.check_and_complete_exploration(current_selected_adventurer)
	if not result.is_empty():
		_update_detail_view(adv)
		_refresh_adventure_list()


func _on_exploration_started(adventurer_id: String, tier: int) -> void:
	print("탐험 시작: %s - Tier %d" % [adventurer_id, tier])


func _on_exploration_completed(adventurer_id: String, exploration_data: Dictionary) -> void:
	if adventurer_id != current_selected_adventurer:
		return
	
	var rewards = exploration_data.get("rewards", {})
	
	print("탐험 완료: %s" % adventurer_id)
	print("금화: %d" % rewards.get("gold", 0))
	
	# 보상 요약 출력
	var reward_summary = "✅ 탐험 완료!\n"
	reward_summary += "💰 %d Gold\n" % rewards.get("gold", 0)
	
	var item_count = 0
	for ore_reward in rewards.get("items", []):
		item_count += ore_reward.get("quantity", 0)
	if item_count > 0:
		reward_summary += "📦 광석 %d개\n" % item_count
	
	if rewards.get("artifacts", []).size() > 0:
		reward_summary += "🔮 유물 %d개!" % rewards.get("artifacts", []).size()
	
	print(reward_summary)


func _on_item_equipped(adventurer_id: String, item: Dictionary) -> void:
	if adventurer_id == current_selected_adventurer:
		var adv = GameManager.get_adventurer(current_selected_adventurer)
		if adv:
			_update_detail_view(adv)


func _on_item_unequipped(adventurer_id: String, item: Dictionary) -> void:
	if adventurer_id == current_selected_adventurer:
		var adv = GameManager.get_adventurer(current_selected_adventurer)
		if adv:
			_update_detail_view(adv)


func _on_unequip_item(item_index: int) -> void:
	if current_selected_adventurer.is_empty():
		return
	
	var success = GameManager.unequip_item_from_adventurer(current_selected_adventurer, item_index)
	if success:
		var adv = GameManager.get_adventurer(current_selected_adventurer)
		if adv:
			_update_detail_view(adv)


func _refresh_inventory_list() -> void:
	inventory_list.clear()
	
	for i in range(GameManager.inventory.size()):
		var item = GameManager.inventory[i]
		
		# 장착 가능한 아이템만 표시
		if not item.get("type") or item.get("type") not in ["weapon", "armor", "accessory"]:
			continue
		
		var item_text = "%s %s" % [item.get("grade_emoji", ""), item["name"]]
		if item.get("is_artifact", false):
			item_text += " 🔮"
		if item.has("speed_bonus"):
			item_text += " [속도: ×%.2f]" % item["speed_bonus"]
		
		inventory_list.add_item(item_text)
		inventory_list.set_item_metadata(inventory_list.item_count - 1, i)


func _on_inventory_item_selected(index: int) -> void:
	if current_selected_adventurer.is_empty():
		return
	
	var inventory_index = inventory_list.get_item_metadata(index)
	if inventory_index < 0 or inventory_index >= GameManager.inventory.size():
		return
	
	var success = GameManager.equip_item_to_adventurer(current_selected_adventurer, inventory_index)
	if success:
		var adv = GameManager.get_adventurer(current_selected_adventurer)
		if adv:
			_update_detail_view(adv)
		print("✅ 장착 완료!")
