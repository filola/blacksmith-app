extends Control

## Adventure Tab - Dungeon Map + Party Formation UI

# Dungeon map
@onready var dungeon_list: HBoxContainer = %DungeonList
@onready var dungeon_name_label: Label = %DungeonNameLabel
@onready var dungeon_desc_label: Label = %DungeonDescLabel
@onready var dungeon_drops_label: Label = %DungeonDropsLabel

# Party formation
@onready var party_slots_container: VBoxContainer = %PartySlotsContainer
@onready var party_stats_label: Label = %PartyStatsLabel
@onready var start_exploration_btn: Button = %StartExplorationBtn
@onready var exploration_progress: ProgressBar = %ExplorationProgress
@onready var exploration_status_label: Label = %ExplorationStatusLabel

# Battle log
@onready var battle_log_scroll: ScrollContainer = %BattleLogScroll
@onready var battle_log: RichTextLabel = %BattleLog

# Adventurer list
@onready var adventurer_list_container: VBoxContainer = %AdventurerListContainer
@onready var inventory_list: ItemList = %InventoryList

# State
var selected_dungeon_id: String = ""
var party_member_ids: Array[String] = []
var active_party_id: String = ""
var selected_adventurer_for_equip: String = ""

var exploration_timer: Timer
var battle_log_timer: Timer
var last_log_progress: float = 0.0


func _ready() -> void:
	# Signals
	GameManager.party_exploration_started.connect(_on_party_started)
	GameManager.party_exploration_completed.connect(_on_party_completed)
	GameManager.adventurer_hired.connect(func(_a, _b): _refresh_all())
	GameManager.game_loaded.connect(_refresh_all)
	GameManager.item_equipped.connect(func(_a, _b): _refresh_all())
	GameManager.item_unequipped.connect(func(_a, _b): _refresh_all())

	start_exploration_btn.pressed.connect(_on_start_exploration)
	inventory_list.item_selected.connect(_on_inventory_item_selected)

	# Exploration timer
	exploration_timer = Timer.new()
	add_child(exploration_timer)
	exploration_timer.timeout.connect(_on_exploration_tick)
	exploration_timer.wait_time = 0.2

	# Battle log event timer
	battle_log_timer = Timer.new()
	add_child(battle_log_timer)
	battle_log_timer.timeout.connect(_generate_battle_event)
	battle_log_timer.wait_time = 2.5

	_build_dungeon_map()
	_refresh_all()


## Build dungeon selection buttons
func _build_dungeon_map() -> void:
	for child in dungeon_list.get_children():
		child.queue_free()

	var dungeons = GameManager.get_dungeons()
	# Sort by tier
	var sorted_ids = dungeons.keys()
	sorted_ids.sort_custom(func(a, b): return dungeons[a]["tier"] < dungeons[b]["tier"])

	for dg_id in sorted_ids:
		var dg = dungeons[dg_id]
		var unlocked = GameManager.is_dungeon_unlocked(dg_id)

		# VBox: icon on top, name below
		var vbox = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER

		# Dungeon tile icon
		var icon_rect = TextureRect.new()
		icon_rect.custom_minimum_size = Vector2(48, 48)
		icon_rect.expand_mode = TextureRect.EXPAND_KEEP_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var icon_path = dg.get("icon", "")
		if icon_path != "" and ResourceLoader.exists(icon_path):
			icon_rect.texture = load(icon_path)
		if not unlocked:
			icon_rect.modulate = Color(0.3, 0.3, 0.3)
		vbox.add_child(icon_rect)

		# Monster icon (smaller, below tile)
		var monster_path = dg.get("monster_icon", "")
		if monster_path != "" and ResourceLoader.exists(monster_path):
			var monster_rect = TextureRect.new()
			monster_rect.custom_minimum_size = Vector2(32, 32)
			monster_rect.expand_mode = TextureRect.EXPAND_KEEP_SIZE
			monster_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			monster_rect.texture = load(monster_path)
			if not unlocked:
				monster_rect.modulate = Color(0.3, 0.3, 0.3)
			vbox.add_child(monster_rect)

		# Button wrapping the visuals
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(130, 80)
		btn.text = "T%d %s" % [dg["tier"], dg["name"]]
		btn.disabled = not unlocked
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if not unlocked:
			btn.tooltip_text = "Unlock Tier %d to access" % dg["tier"]
		if dg_id == selected_dungeon_id:
			btn.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
		var captured_id = dg_id
		btn.pressed.connect(func(): _on_dungeon_selected(captured_id))

		vbox.add_child(btn)
		dungeon_list.add_child(vbox)


## Select a dungeon
func _on_dungeon_selected(dungeon_id: String) -> void:
	# Don't change dungeon during exploration
	if not active_party_id.is_empty():
		return

	selected_dungeon_id = dungeon_id
	party_member_ids.clear()
	_refresh_dungeon_info()
	_refresh_party_slots()
	_refresh_adventurer_list()
	_update_party_stats()


## Refresh dungeon info panel
func _refresh_dungeon_info() -> void:
	if selected_dungeon_id.is_empty():
		dungeon_name_label.text = "Select a Dungeon"
		dungeon_desc_label.text = ""
		dungeon_drops_label.text = ""
		return

	var dg = GameManager.get_dungeons().get(selected_dungeon_id, {})
	dungeon_name_label.text = "%s (Tier %d)" % [dg.get("name", "?"), dg.get("tier", 0)]
	dungeon_desc_label.text = dg.get("description", "")

	# Show exclusive drops
	var drops_text = "Exclusive Drops: "
	var materials = dg.get("exclusive_materials", [])
	for i in range(materials.size()):
		var mat_id = materials[i]
		var mat_info = GameManager.get_dungeon_material_info(mat_id)
		var owned = GameManager.get_ore_count(mat_id)
		if i > 0:
			drops_text += "  |  "
		drops_text += "%s: %d" % [mat_info.get("name", mat_id), owned]
	dungeon_drops_label.text = drops_text


## Refresh party slots (4 slots)
func _refresh_party_slots() -> void:
	for child in party_slots_container.get_children():
		child.queue_free()

	for i in range(GameConfig.MAX_PARTY_SIZE):
		var hbox = HBoxContainer.new()

		var slot_label = Label.new()
		slot_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		if i < party_member_ids.size():
			var adv = GameManager.get_adventurer(party_member_ids[i])
			if adv:
				# Portrait in slot
				if ResourceLoader.exists(adv.portrait):
					var portrait = TextureRect.new()
					portrait.texture = load(adv.portrait)
					portrait.custom_minimum_size = Vector2(28, 28)
					portrait.expand_mode = TextureRect.EXPAND_KEEP_SIZE
					portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
					hbox.add_child(portrait)

				var atk = adv.get_total_attack_power()
				var def = adv.get_total_defense()
				slot_label.text = "%s Lv.%d [ATK %d / DEF %d]" % [adv.name, adv.level, atk, def]
			else:
				slot_label.text = "Slot %d: (invalid)" % (i + 1)

			# Remove button
			var remove_btn = Button.new()
			remove_btn.text = "X"
			remove_btn.custom_minimum_size.x = 30
			var idx = i
			remove_btn.pressed.connect(func(): _remove_from_party(idx))
			hbox.add_child(slot_label)
			hbox.add_child(remove_btn)
		else:
			slot_label.text = "Slot %d: (empty)" % (i + 1)
			hbox.add_child(slot_label)

		party_slots_container.add_child(hbox)


## Refresh adventurer list (right panel)
func _refresh_adventurer_list() -> void:
	for child in adventurer_list_container.get_children():
		child.queue_free()

	var all_adventurers = GameManager.get_adventurers()
	for adv in all_adventurers:
		if not adv:
			continue

		var hbox = HBoxContainer.new()

		# Portrait icon
		if ResourceLoader.exists(adv.portrait):
			var portrait = TextureRect.new()
			portrait.texture = load(adv.portrait)
			portrait.custom_minimum_size = Vector2(32, 32)
			portrait.expand_mode = TextureRect.EXPAND_KEEP_SIZE
			portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			hbox.add_child(portrait)

		var info_label = Label.new()
		info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		if not adv.hired:
			# Hire button
			var hire_cost = GameManager.get_hire_cost(adv.id)
			info_label.text = "%s [%s] - Not Hired (%d Gold)" % [adv.name, adv.character_class, hire_cost]
			var hire_btn = Button.new()
			hire_btn.text = "Hire"
			hire_btn.custom_minimum_size.x = 50
			var adv_id = adv.id
			hire_btn.pressed.connect(func(): _on_hire(adv_id))
			hbox.add_child(info_label)
			hbox.add_child(hire_btn)
		elif adv.is_exploring:
			info_label.text = "%s Lv.%d [EXPLORING]" % [adv.name, adv.level]
			hbox.add_child(info_label)
		elif adv.id in party_member_ids:
			info_label.text = "%s Lv.%d [IN PARTY]" % [adv.name, adv.level]
			hbox.add_child(info_label)
		else:
			# Available - can add to party or view equipment
			var atk = adv.get_total_attack_power()
			var def = adv.get_total_defense()
			info_label.text = "%s Lv.%d [%s] ATK:%d DEF:%d" % [adv.name, adv.level, adv.character_class, atk, def]

			if not selected_dungeon_id.is_empty() and party_member_ids.size() < GameConfig.MAX_PARTY_SIZE:
				var add_btn = Button.new()
				add_btn.text = "+"
				add_btn.custom_minimum_size.x = 30
				var adv_id = adv.id
				add_btn.pressed.connect(func(): _add_to_party(adv_id))
				hbox.add_child(info_label)
				hbox.add_child(add_btn)
			else:
				hbox.add_child(info_label)

			# Equip button
			var equip_btn = Button.new()
			equip_btn.text = "Equip"
			equip_btn.custom_minimum_size.x = 50
			var adv_id = adv.id
			equip_btn.pressed.connect(func(): _select_for_equip(adv_id))
			hbox.add_child(equip_btn)

		# Show equipped items as tooltip
		if adv.hired and not adv.equipped_items.is_empty():
			var equip_text = ""
			for item in adv.equipped_items:
				equip_text += "%s " % item.get("name", "?")
			info_label.tooltip_text = "Equipped: " + equip_text

		adventurer_list_container.add_child(hbox)


## Add adventurer to party
func _add_to_party(adventurer_id: String) -> void:
	if party_member_ids.size() >= GameConfig.MAX_PARTY_SIZE:
		return
	if adventurer_id in party_member_ids:
		return
	party_member_ids.append(adventurer_id)
	_refresh_party_slots()
	_refresh_adventurer_list()
	_update_party_stats()


## Remove adventurer from party
func _remove_from_party(index: int) -> void:
	if index < 0 or index >= party_member_ids.size():
		return
	party_member_ids.remove_at(index)
	_refresh_party_slots()
	_refresh_adventurer_list()
	_update_party_stats()


## Update party stats display
func _update_party_stats() -> void:
	if party_member_ids.is_empty():
		party_stats_label.text = "ATK: 0  |  DEF: 0  |  Speed: x1.00"
		start_exploration_btn.disabled = true
		return

	var total_atk = 0
	var total_def = 0
	var total_speed = 0.0
	for mid in party_member_ids:
		var adv = GameManager.get_adventurer(mid)
		if adv:
			total_atk += adv.get_total_attack_power()
			total_def += adv.get_total_defense()
			total_speed += adv.get_speed_multiplier()
	var avg_speed = total_speed / party_member_ids.size()

	# Show estimated time
	var dg = GameManager.get_dungeons().get(selected_dungeon_id, {})
	var tier = dg.get("tier", 1)
	var defense_speed = 1.0 + total_def * GameConfig.DEFENSE_SPEED_BONUS_PER_POINT
	var base_time = GameConfig.EXPLORATION_BASE_TIME + (tier - 1) * GameConfig.EXPLORATION_TIME_PER_TIER
	var est_time = base_time / (avg_speed * defense_speed)

	party_stats_label.text = "ATK: %d  |  DEF: %d  |  Speed: x%.2f  |  Est: %ds" % [total_atk, total_def, avg_speed, int(est_time)]

	# Check min power
	var min_power = dg.get("min_party_power", 0)
	start_exploration_btn.disabled = (total_atk + total_def) < min_power
	if start_exploration_btn.disabled:
		start_exploration_btn.text = "Need Power %d+ (Current: %d)" % [min_power, total_atk + total_def]
	else:
		start_exploration_btn.text = "Start Exploration!"


## Start party exploration
func _on_start_exploration() -> void:
	if selected_dungeon_id.is_empty() or party_member_ids.is_empty():
		return

	var party_id = GameManager.start_party_exploration(selected_dungeon_id, party_member_ids)
	if party_id.is_empty():
		return

	active_party_id = party_id
	start_exploration_btn.disabled = true
	start_exploration_btn.text = "Exploring..."
	exploration_progress.show()
	exploration_progress.value = 0
	exploration_timer.start()

	# Start battle log
	battle_log.text = ""
	battle_log_scroll.show()
	last_log_progress = 0.0
	var dg = GameManager.get_dungeons().get(selected_dungeon_id, {})
	_add_battle_log("[color=yellow]The party enters %s...[/color]" % dg.get("name", "the dungeon"))
	battle_log_timer.start()

	_refresh_adventurer_list()


## Exploration tick
func _on_exploration_tick() -> void:
	if active_party_id.is_empty():
		return

	var party = GameManager.adventure_system.get_party(active_party_id)
	if not party:
		# Party already completed
		_finish_exploration_ui()
		return

	exploration_progress.value = party.get_exploration_progress() * 100.0
	var remaining = party.exploration_duration - ((Time.get_ticks_msec() / 1000.0) - party.exploration_start_time)
	exploration_status_label.text = "Exploring... %ds remaining" % max(0, int(remaining))

	# Check completion
	if party.is_exploration_complete():
		var result = GameManager.check_and_complete_party_exploration(active_party_id)
		if not result.is_empty():
			_show_rewards(result)
			_finish_exploration_ui()


func _finish_exploration_ui() -> void:
	active_party_id = ""
	exploration_timer.stop()
	battle_log_timer.stop()
	exploration_progress.hide()
	party_member_ids.clear()
	_refresh_all()
	# Keep battle log visible for a while after completion
	get_tree().create_timer(8.0).timeout.connect(func(): battle_log_scroll.hide())


## Show reward summary
func _show_rewards(result: Dictionary) -> void:
	var rewards = result.get("rewards", {})

	_add_battle_log("\n[color=gold]--- Exploration Complete! ---[/color]")
	_add_battle_log("[color=yellow]Gold: %d[/color]" % rewards.get("gold", 0))
	_add_battle_log("[color=cyan]EXP: %d (all members)[/color]" % rewards.get("experience", 0))

	var ore_count = 0
	for ore in rewards.get("items", []):
		ore_count += ore.get("quantity", 0)
	if ore_count > 0:
		_add_battle_log("[color=green]Ores: %d[/color]" % ore_count)

	for mat in rewards.get("dungeon_materials", []):
		var mat_info = GameManager.get_dungeon_material_info(mat["material_id"])
		_add_battle_log("[color=magenta]%s x%d[/color]" % [mat_info.get("name", mat["material_id"]), mat["quantity"]])

	if rewards.get("artifacts", []).size() > 0:
		_add_battle_log("[color=orange]Artifacts: %d![/color]" % rewards["artifacts"].size())

	exploration_status_label.text = "Exploration Complete!"


## Hire adventurer
func _on_hire(adventurer_id: String) -> void:
	GameManager.hire_adventurer(adventurer_id)


## Select adventurer for equipment management
func _select_for_equip(adventurer_id: String) -> void:
	selected_adventurer_for_equip = adventurer_id
	_refresh_inventory_list()


## Refresh inventory for equipping
func _refresh_inventory_list() -> void:
	inventory_list.clear()
	if selected_adventurer_for_equip.is_empty():
		return

	var inv_items = GameManager.get_inventory_items()
	for i in range(inv_items.size()):
		var item = inv_items[i]
		if not item.get("type") or item.get("type") not in ["weapon", "armor", "accessory"]:
			continue

		var item_text = "%s %s" % [item.get("grade_emoji", ""), item["name"]]
		if item.get("attack_power", 0) > 0:
			item_text += " [ATK +%d]" % item["attack_power"]
		if item.get("defense", 0) > 0:
			item_text += " [DEF +%d]" % item["defense"]

		inventory_list.add_item(item_text)
		inventory_list.set_item_metadata(inventory_list.item_count - 1, i)


## Equip item to selected adventurer
func _on_inventory_item_selected(index: int) -> void:
	if selected_adventurer_for_equip.is_empty():
		return

	var inventory_index = inventory_list.get_item_metadata(index)
	GameManager.equip_item_to_adventurer(selected_adventurer_for_equip, inventory_index)
	_refresh_inventory_list()
	_refresh_adventurer_list()
	_update_party_stats()


## Refresh everything
func _refresh_all() -> void:
	_build_dungeon_map()
	_refresh_dungeon_info()
	_refresh_party_slots()
	_refresh_adventurer_list()
	_update_party_stats()
	_refresh_inventory_list()

	# Check for active party on load
	if not active_party_id.is_empty():
		exploration_progress.show()
		exploration_timer.start()


func _on_party_started(_party_id: String, _dungeon_id: String) -> void:
	pass


func _on_party_completed(_party_id: String, _rewards: Dictionary) -> void:
	_refresh_all()


## Add a line to the battle log
func _add_battle_log(text: String) -> void:
	if battle_log.text != "":
		battle_log.text += "\n"
	battle_log.text += text
	# Auto-scroll to bottom
	await get_tree().process_frame
	battle_log_scroll.scroll_vertical = int(battle_log_scroll.get_v_scroll_bar().max_value)


## Generate a random battle event during exploration
func _generate_battle_event() -> void:
	if active_party_id.is_empty():
		return

	var party = GameManager.adventure_system.get_party(active_party_id)
	if not party:
		return

	var progress = party.get_exploration_progress()
	var dg = GameManager.get_dungeons().get(selected_dungeon_id, {})
	var dungeon_name = dg.get("name", "dungeon")
	var tier = dg.get("tier", 1)

	# Get party member names
	var member_names: Array[String] = []
	for mid in party_member_ids:
		var adv = GameManager.get_adventurer(mid)
		if adv:
			member_names.append(adv.name)

	if member_names.is_empty():
		return

	var hero = member_names[randi() % member_names.size()]

	# Different events based on exploration progress
	var event_text = ""
	if progress < 0.2:
		event_text = _get_early_event(hero, dungeon_name, tier)
	elif progress < 0.5:
		event_text = _get_mid_event(hero, dungeon_name, tier)
	elif progress < 0.8:
		event_text = _get_late_event(hero, dungeon_name, tier)
	else:
		event_text = _get_boss_event(hero, dungeon_name, tier)

	_add_battle_log(event_text)


func _get_early_event(hero: String, dungeon: String, tier: int) -> String:
	var events = [
		"[color=gray]%s scouts ahead cautiously...[/color]" % hero,
		"[color=gray]The party moves deeper into %s.[/color]" % dungeon,
		"[color=white]%s finds a narrow passage.[/color]" % hero,
		"[color=gray]Strange sounds echo through the corridors...[/color]",
		"[color=white]%s spots tracks on the ground.[/color]" % hero,
		"[color=gray]A cold breeze sweeps through the dungeon...[/color]",
	]
	if tier >= 3:
		events.append("[color=red]An ominous presence looms ahead...[/color]")
	return events[randi() % events.size()]


func _get_mid_event(hero: String, _dungeon: String, tier: int) -> String:
	var monsters = _get_monsters_for_tier(tier)
	var monster = monsters[randi() % monsters.size()]
	var events = [
		"[color=red]A %s appears! %s attacks![/color]" % [monster, hero],
		"[color=orange]%s strikes the %s with a powerful blow![/color]" % [hero, monster],
		"[color=green]%s defeats the %s![/color]" % [hero, monster],
		"[color=cyan]%s dodges the %s's attack![/color]" % [hero, monster],
		"[color=yellow]The party encounters a group of %ss![/color]" % monster,
		"[color=green]%s finds a hidden chest![/color]" % hero,
		"[color=orange]%s takes a hit but stands firm![/color]" % hero,
	]
	return events[randi() % events.size()]


func _get_late_event(hero: String, _dungeon: String, tier: int) -> String:
	var monsters = _get_monsters_for_tier(tier)
	var monster = monsters[randi() % monsters.size()]
	var events = [
		"[color=red]An elite %s blocks the path![/color]" % monster,
		"[color=yellow]%s unleashes a special attack![/color]" % hero,
		"[color=green]The party clears a monster den![/color]",
		"[color=cyan]%s finds a secret room![/color]" % hero,
		"[color=orange]A fierce battle with %s![/color]" % monster,
		"[color=yellow]%s protects the party from a trap![/color]" % hero,
		"[color=green]The party rests briefly to recover.[/color]",
	]
	return events[randi() % events.size()]


func _get_boss_event(hero: String, dungeon: String, tier: int) -> String:
	var bosses = {
		1: "Goblin Chief",
		2: "Young Dragon",
		3: "Frost Warden",
		4: "Shadow Lord",
		5: "Celestial Guardian"
	}
	var boss = bosses.get(tier, "Dungeon Boss")
	var events = [
		"[color=red][b]The %s awaits at the end of %s![/b][/color]" % [boss, dungeon],
		"[color=yellow][b]%s charges at the %s![/b][/color]" % [hero, boss],
		"[color=orange][b]The %s unleashes a devastating attack![/b][/color]" % boss,
		"[color=cyan][b]The party works together against the %s![/b][/color]" % boss,
		"[color=green][b]%s lands the final blow on the %s![/b][/color]" % [hero, boss],
	]
	return events[randi() % events.size()]


func _get_monsters_for_tier(tier: int) -> Array:
	match tier:
		1: return ["Goblin", "Rat", "Slime", "Bat"]
		2: return ["Lizardman", "Fire Imp", "Drake", "Lava Golem"]
		3: return ["Ice Wraith", "Frost Wolf", "Yeti", "Snow Harpy"]
		4: return ["Shadow Fiend", "Dark Knight", "Void Specter", "Abyssal Worm"]
		5: return ["Angel Guard", "Star Golem", "Celestial Beast", "Light Elemental"]
		_: return ["Monster"]
