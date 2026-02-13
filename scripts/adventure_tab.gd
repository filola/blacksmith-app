extends Control

## 모험가 탭 UI

@onready var adventure_list: ItemList = %AdventureList
@onready var adventurer_detail: PanelContainer = %AdventurerDetail
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
	
	_refresh_adventure_list()


func _refresh_adventure_list() -> void:
	adventure_list.clear()
	var adventurers = GameManager.get_adventurers()
	
	for adv in adventurers:
		var status = "⏳ 대기중" if not adv.is_exploring else "🚀 탐험중"
		adventure_list.add_item("%s - %s" % [adv.name, status], -1)


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


func _refresh_equipped_items(adv) -> void:
	# 기존 UI 정리
	for child in equipped_items_container.get_children():
		child.queue_free()
	
	# 장착 아이템 표시
	for item in adv.equipped_items:
		var item_label = Label.new()
		var item_text = "%s (%s)" % [item["name"], item.get("type", "?")]
		item_label.text = item_text
		equipped_items_container.add_child(item_label)
	
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


func _on_exploration_completed(adventurer_id: String, rewards: Dictionary) -> void:
	print("탐험 완료: %s" % adventurer_id)
	print("보상: %s" % rewards)


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
