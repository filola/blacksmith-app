extends Control

## Inventory/Shop Tab - View crafted items + sell or equip

@onready var item_list: VBoxContainer = %ItemList
@onready var sell_all_button: Button = %SellAllButton
@onready var sell_result: Label = %SellResult

func _ready() -> void:
	_update_list()
	sell_all_button.pressed.connect(_on_sell_all)
	GameManager.item_crafted.connect(func(_a, _b): _update_list())
	GameManager.gold_changed.connect(func(_a): _update_list())
	GameManager.item_equipped.connect(func(_a, _b): _update_list())
	GameManager.item_unequipped.connect(func(_a, _b): _update_list())


func _update_list() -> void:
	for child in item_list.get_children():
		child.queue_free()

	if GameManager.get_inventory_items().is_empty():
		var empty = Label.new()
		empty.text = "No items. Try crafting some!"
		empty.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		item_list.add_child(empty)
		sell_all_button.disabled = true
		return

	sell_all_button.disabled = false

	var items = GameManager.get_inventory_items()
	for i in range(items.size()):
		var item = items[i]
		var hbox = HBoxContainer.new()

		# Item icon
		var item_icon = TextureRect.new()
		var icon_path = GameManager.recipe_data.get(item["recipe_id"], {}).get("icon", "")
		if icon_path != "" and ResourceLoader.exists(icon_path):
			item_icon.texture = load(icon_path)
		item_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		item_icon.custom_minimum_size = Vector2(32, 32)
		hbox.add_child(item_icon)

		# Grade emoji + name
		var name_label = Label.new()
		name_label.text = "%s %s [%s]" % [item["grade_emoji"], item["name"], item["grade_name"]]
		name_label.add_theme_color_override("font_color", Color.html(item["grade_color"]))
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(name_label)

		# Price
		var price_label = Label.new()
		price_label.text = "%dG" % item["price"]
		price_label.custom_minimum_size.x = 80
		hbox.add_child(price_label)

		# Action buttons
		var action_hbox = HBoxContainer.new()
		
		# Regular item or artifact (equippable)
		if item.get("type") and item.get("type") in ["weapon", "armor", "accessory"]:
			var equip_btn = Button.new()
			equip_btn.text = "Equip"
			equip_btn.custom_minimum_size.x = 60
			var item_idx = i
			equip_btn.pressed.connect(func(): _on_equip_item(item_idx))
			action_hbox.add_child(equip_btn)
		
		var sell_btn = Button.new()
		sell_btn.text = "Sell"
		sell_btn.custom_minimum_size.x = 60
		var item_ref = item
		sell_btn.pressed.connect(func(): _on_sell_item(item_ref))
		action_hbox.add_child(sell_btn)
		
		hbox.add_child(action_hbox)

		item_list.add_child(hbox)


func _on_sell_item(item: Dictionary) -> void:
	var index = GameManager.get_inventory_items().find(item)
	if index == -1:
		return
	var price = GameManager.sell_item(index)
	if price > 0:
		sell_result.text = "+%d Gold!" % price
		_flash_result()
		_update_list()


func _on_sell_all() -> void:
	var total = 0
	while not GameManager.get_inventory_items().is_empty():
		total += GameManager.sell_item(0)
	if total > 0:
		sell_result.text = "+%d Gold total!" % total
		_flash_result()
		_update_list()


func _on_equip_item(inventory_index: int) -> void:
	# Adventurer selection popup (simplified - first adventurer)
	var adventurers = GameManager.get_adventurers()
	if adventurers.is_empty():
		sell_result.text = "No adventurers available!"
		_flash_result()
		return
	
	# Simply equip to first adventurer
	var adv = adventurers[0]
	var success = GameManager.equip_item_to_adventurer(adv.id, inventory_index)
	
	if success:
		var inv_items = GameManager.get_inventory_items()
		sell_result.text = "Equipped %s to %s!" % [inv_items[inventory_index]["name"] if inventory_index < inv_items.size() else "item", adv.name]
		_flash_result()
		_update_list()
	else:
		sell_result.text = "Equip failed!"
		_flash_result()


func _flash_result() -> void:
	sell_result.modulate = Color.WHITE
	var tween = create_tween()
	tween.tween_property(sell_result, "modulate:a", 0.0, 2.0).set_delay(1.0)
