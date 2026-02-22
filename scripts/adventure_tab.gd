extends Control

## Adventure Tab UI - Phase 3: Hiring, Leveling, Special Abilities

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

# Phase 3 UI components (dynamically created)
var level_label: Label
var exp_progress_bar: ProgressBar
var abilities_label: Label
var hire_button: Button
var hire_cost_label: Label


func _ready() -> void:
	push_error("[GAME] AdventureTab._ready() called")
	# Node validation
	push_error("  [CHECK] adventure_list: %s" % ("[OK]" if adventure_list else "[X]"))
	push_error("  [CHECK] start_exploration_btn: %s" % ("[OK]" if start_exploration_btn else "[X]"))
	push_error("  [CHECK] inventory_list: %s" % ("[OK]" if inventory_list else "[X]"))
	
	if not adventure_list or not start_exploration_btn or not inventory_list:
		push_error("[X] AdventureTab: Required nodes not found!")
		return
	
	# Signal connections
	GameManager.exploration_started.connect(_on_exploration_started)
	GameManager.exploration_completed.connect(_on_exploration_completed)
	GameManager.item_equipped.connect(_on_item_equipped)
	GameManager.item_unequipped.connect(_on_item_unequipped)
	GameManager.adventurer_hired.connect(_on_adventurer_hired)
	GameManager.experience_gained.connect(_on_experience_gained)
	GameManager.adventurer_leveled_up.connect(_on_adventurer_leveled_up)
	GameManager.game_loaded.connect(_on_game_loaded)
	
	# UI signals
	adventure_list.item_selected.connect(_on_adventure_selected)
	start_exploration_btn.pressed.connect(_on_start_exploration)
	
	# Exploration timer
	exploration_timer = Timer.new()
	add_child(exploration_timer)
	exploration_timer.timeout.connect(_on_exploration_timer_tick)
	exploration_timer.wait_time = 0.1
	
	dungeon_tier_spinbox.min_value = 1
	dungeon_tier_spinbox.max_value = 5
	dungeon_tier_spinbox.value = 1
	
	# Inventory signals
	inventory_list.item_selected.connect(_on_inventory_item_selected)
	
	push_error("  [CALL] Calling _refresh_adventure_list()...")
	_refresh_adventure_list()
	push_error("[OK] AdventureTab._ready() completed - adventure_list has %d items" % adventure_list.item_count)


func _refresh_adventure_list() -> void:
	push_error("[REFRESH] _refresh_adventure_list() START")
	push_error("  [GAME] GameManager: %s" % ("[OK]" if GameManager else "[X]"))
	push_error("  [GAME] GameManager.adventure_system: %s" % ("[OK]" if GameManager.adventure_system else "[X]"))
	if GameManager.adventure_system:
		push_error("  [STATS] GameManager.adventure_system.adventurers.size(): %d" % GameManager.adventure_system.adventurers.size())
	
	adventure_list.clear()
	
	var all_adventurers = GameManager.get_adventurers()
	push_error("  [LIST] all_adventurers.size(): %d" % all_adventurers.size())
	push_error("  [LIST] all_adventurers type: %s" % typeof(all_adventurers))
	
	if all_adventurers.size() == 0:
		push_error("[WARN]  WARNING: all_adventurers is empty!")
		# Force reload attempt
		push_error("[FIX] Forcing GameManager.adventure_system._load_data()...")
		if GameManager.adventure_system:
			GameManager.adventure_system._load_data()
			all_adventurers = GameManager.get_adventurers()
			push_error("  After forced load: %d adventurers" % all_adventurers.size())
		if all_adventurers.size() == 0:
			push_error("[OK] _refresh_adventure_list() END - 0 items added (still empty)")
			return
	
	var added_count = 0
	for adv in all_adventurers:
		if not adv:
			push_error("  [X] NULL adventurer encountered!")
			continue
		
		var status = ""
		if not adv.hired:
			status = " [GOLD] Not Hired"
		elif adv.is_exploring:
			status = "[EXPLORE] Exploring"
		else:
			status = "[IDLE] Idle"
		
		var level_info = " Lv.%d" % adv.level if adv.hired else ""
		var item_text = "%s%s%s" % [adv.name, status, level_info]
		adventure_list.add_item(item_text)
		added_count += 1
	
	push_error("[OK] _refresh_adventure_list() END - added %d items, ItemList.item_count: %d" % [added_count, adventure_list.item_count])


func _on_adventure_selected(index: int) -> void:
	var all_adventurers = GameManager.get_adventurers()
	if index < 0 or index >= all_adventurers.size():
		return
	
	var adv = all_adventurers[index]
	current_selected_adventurer = adv.id
	_update_detail_view(adv)


func _update_detail_view(adv) -> void:
	adventurer_name_label.text = "%s [%s]" % [adv.name, adv.character_class.to_upper()]
	adventurer_description_label.text = adv.description
	
	if ResourceLoader.exists(adv.portrait):
		adventurer_portrait.texture = load(adv.portrait)
	
	# Phase 3: Level & EXP display
	_update_level_display(adv)
	
	if not adv.hired:
		# Unhired adventurer: show hire button
		_show_hire_button(adv)
		start_exploration_btn.hide()
		dungeon_tier_spinbox.hide()
		exploration_progress.hide()
		equipped_items_container.get_parent().hide()
		inventory_list.get_parent().hide()
		return
	
	# Hired adventurer: show normal UI
	if hire_button:
		hire_button.queue_free()
		hire_button = null
	
	start_exploration_btn.show()
	dungeon_tier_spinbox.show()
	equipped_items_container.get_parent().show()
	inventory_list.get_parent().show()
	
	# Display equipped items
	_refresh_equipped_items(adv)
	
	# Exploration status
	_update_exploration_status(adv)
	
	# Speed multiplier display
	var speed_text = "Speed: x%.2f" % adv.get_speed_multiplier()
	if exploration_status_label:
		exploration_status_label.text = speed_text
	
	# Display inventory (equippable items only)
	_refresh_inventory_list()


func _update_level_display(adv) -> void:
	# Level & EXP UI update
	if not level_label:
		level_label = Label.new()
		adventurer_name_label.add_sibling(level_label)
	
	if not exp_progress_bar:
		exp_progress_bar = ProgressBar.new()
		exp_progress_bar.custom_minimum_size = Vector2(0, 20)
		level_label.add_sibling(exp_progress_bar)
	
	level_label.text = "[LV] Lv.%d (Next level: %d)" % [adv.level, adv.get_exp_to_next_level()]
	exp_progress_bar.value = adv.get_exp_progress() * 100.0
	
	# Phase 3: Special abilities display
	_update_abilities_display(adv)


func _update_abilities_display(adv) -> void:
	if not abilities_label:
		abilities_label = Label.new()
		abilities_label.text = "[ABILITY] Special Abilities"
		adventurer_description_label.add_sibling(abilities_label)
	
	var all_abilities = GameManager.get_all_class_abilities(adv.id)
	var abilities_text = "[ABILITY] Special Abilities\n"
	
	for ability in all_abilities:
		var lock_icon = "[LOCKED]" if not ability.get("is_unlocked", false) else ability.get("emoji", "[BUFF]")
		var level_info = " [Lv.%d]" % ability.get("unlock_level", 1)
		abilities_text += "%s %s%s\n" % [lock_icon, ability.get("name", "?"), level_info]
	
	abilities_label.text = abilities_text.trim_suffix("\n")


func _show_hire_button(adv) -> void:
	if hire_button:
		hire_button.queue_free()
	
	if not hire_cost_label:
		hire_cost_label = Label.new()
		adventurer_name_label.add_sibling(hire_cost_label)
	
	var hire_cost = GameManager.get_hire_cost(adv.id)
	hire_cost_label.text = "[GOLD] Hire Cost: %d Gold" % hire_cost
	
	hire_button = Button.new()
	hire_button.text = "Hire (%d Gold)" % hire_cost
	hire_button.custom_minimum_size = Vector2(0, 50)
	hire_button.pressed.connect(func(): _on_hire_button_pressed(adv.id))
	adventurer_name_label.add_sibling(hire_button)


func _refresh_equipped_items(adv) -> void:
	# Clean up existing UI
	for child in equipped_items_container.get_children():
		child.queue_free()
	
	# Display equipped items
	for i in range(adv.equipped_items.size()):
		var item = adv.equipped_items[i]
		var hbox = HBoxContainer.new()
		
		# Item info
		var item_label = Label.new()
		var speed_bonus = ""
		if item.has("speed_bonus"):
			speed_bonus = " [Speed: x%.2f]" % item["speed_bonus"]
		var artifact_marker = " [Artifact]" if item.get("is_artifact", false) else ""
		item_label.text = "%s (%s)%s%s" % [item["name"], item.get("type", "?"), speed_bonus, artifact_marker]
		item_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(item_label)
		
		# Unequip button
		var unequip_btn = Button.new()
		unequip_btn.text = "Unequip"
		unequip_btn.custom_minimum_size.x = 50
		var item_index = i
		unequip_btn.pressed.connect(func(): _on_unequip_item(item_index))
		hbox.add_child(unequip_btn)
		
		equipped_items_container.add_child(hbox)
	
	if adv.equipped_items.is_empty():
		var no_items_label = Label.new()
		no_items_label.text = "[No Equipped Items]"
		equipped_items_container.add_child(no_items_label)


func _update_exploration_status(adv) -> void:
	start_exploration_btn.disabled = adv.is_exploring
	dungeon_tier_spinbox.editable = not adv.is_exploring
	
	if adv.is_exploring:
		exploration_progress.show()
		exploration_status_label.text = "[EXPLORE] Exploring..."
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
	
	# Check completion
	var result = GameManager.check_and_complete_exploration(current_selected_adventurer)
	if not result.is_empty():
		_update_detail_view(adv)
		_refresh_adventure_list()


func _on_exploration_started(adventurer_id: String, tier: int) -> void:
	print("Exploration started: %s - Tier %d" % [adventurer_id, tier])


func _on_exploration_completed(adventurer_id: String, exploration_data: Dictionary) -> void:
	if adventurer_id != current_selected_adventurer:
		return
	
	var rewards = exploration_data.get("rewards", {})
	
	print("Exploration complete: %s" % adventurer_id)
	print("Gold: %d" % rewards.get("gold", 0))
	
	# Print reward summary
	var reward_summary = "[OK] Exploration Complete!\n"
	reward_summary += "[GOLD] %d Gold\n" % rewards.get("gold", 0)
	reward_summary += "[EXP] %d EXP\n" % rewards.get("experience", 0)
	
	var item_count = 0
	for ore_reward in rewards.get("items", []):
		item_count += ore_reward.get("quantity", 0)
	if item_count > 0:
		reward_summary += "[ORE] %d Ores\n" % item_count
	
	if rewards.get("artifacts", []).size() > 0:
		reward_summary += "[ARTIFACT] %d Artifacts!" % rewards.get("artifacts", []).size()
	
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
	
	var inv_items = GameManager.get_inventory_items()
	for i in range(inv_items.size()):
		var item = inv_items[i]
		
		# Show equippable items only
		if not item.get("type") or item.get("type") not in ["weapon", "armor", "accessory"]:
			continue
		
		var item_text = "%s %s" % [item.get("grade_emoji", ""), item["name"]]
		if item.get("is_artifact", false):
			item_text += " [Artifact]"
		if item.has("speed_bonus"):
			item_text += " [Speed: x%.2f]" % item["speed_bonus"]
		
		inventory_list.add_item(item_text)
		inventory_list.set_item_metadata(inventory_list.item_count - 1, i)


func _on_inventory_item_selected(index: int) -> void:
	if current_selected_adventurer.is_empty():
		return
	
	var inventory_index = inventory_list.get_item_metadata(index)
	if inventory_index < 0 or inventory_index >= GameManager.get_inventory_items().size():
		return
	
	var success = GameManager.equip_item_to_adventurer(current_selected_adventurer, inventory_index)
	if success:
		var adv = GameManager.get_adventurer(current_selected_adventurer)
		if adv:
			_update_detail_view(adv)
		print("[OK] Equipped!")


## ===== Phase 3 Signal Handlers =====

func _on_hire_button_pressed(adventurer_id: String) -> void:
	var success = GameManager.hire_adventurer(adventurer_id)
	if success:
		var adv = GameManager.get_adventurer(adventurer_id)
		print("[OK] Hired %s!" % adv.name)
		_update_detail_view(adv)
		_refresh_adventure_list()
	else:
		print("[X] Hire failed: Not enough gold.")


func _on_adventurer_hired(adventurer_id: String, cost: int) -> void:
	print("[HIRE] Adventurer hired: %s (Cost: %d Gold)" % [adventurer_id, cost])


func _on_experience_gained(adventurer_id: String, amount: int) -> void:
	if adventurer_id == current_selected_adventurer:
		var adv = GameManager.get_adventurer(adventurer_id)
		if adv:
			_update_level_display(adv)
		print("[EXP] %s gained %d EXP!" % [adventurer_id, amount])


func _on_adventurer_leveled_up(adventurer_id: String, new_level: int, stat_changes: Dictionary) -> void:
	if adventurer_id == current_selected_adventurer:
		var adv = GameManager.get_adventurer(adventurer_id)
		if adv:
			_update_detail_view(adv)
	
	var hp_increase = stat_changes.get("hp_increase", 0)
	var new_hp = stat_changes.get("new_hp", 0)
	var new_speed = stat_changes.get("new_speed", 1.0)
	
	print("[LEVELUP] %s leveled up to Lv.%d!" % [adventurer_id, new_level])
	print("  [STATS] HP: +%d (Total %d)" % [hp_increase, new_hp])
	print("  [SPEED] Speed: x%.2f" % new_speed)
	
	# Check new ability unlocks
	if stat_changes.has("new_abilities"):
		var new_abilities = stat_changes.get("new_abilities", [])
		for ability_id in new_abilities:
			print("  [ABILITY] New ability unlocked: %s" % ability_id)


func _on_game_loaded() -> void:
	_refresh_adventure_list()
	if current_selected_adventurer.is_empty():
		return
	var adv = GameManager.get_adventurer(current_selected_adventurer)
	if adv:
		_update_detail_view(adv)
