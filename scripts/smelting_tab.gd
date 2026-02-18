extends Control

## Smelting Tab - Ore refining

@onready var ore_list: VBoxContainer = %SmeltOreList
@onready var result_label: Label = %SmeltResultLabel

func _ready() -> void:
	_update_list()
	GameManager.ore_changed.connect(func(_a, _b): _update_list())


func _update_list() -> void:
	for child in ore_list.get_children():
		child.queue_free()

	for ore_id in GameManager.ore_data:
		var data = GameManager.ore_data[ore_id]
		if data["tier"] > GameManager.get_max_unlocked_tier():
			continue

		var hbox = HBoxContainer.new()

		# Ore icon
		var ore_icon = TextureRect.new()
		var ore_icon_path = data.get("ore_icon", "")
		if ore_icon_path != "" and ResourceLoader.exists(ore_icon_path):
			ore_icon.texture = load(ore_icon_path)
		ore_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ore_icon.custom_minimum_size = Vector2(32, 32)
		hbox.add_child(ore_icon)

		# Arrow
		var arrow = Label.new()
		arrow.text = " -> "
		hbox.add_child(arrow)

		# Bar icon
		var bar_icon = TextureRect.new()
		var bar_icon_path = data.get("bar_icon", "")
		if bar_icon_path != "" and ResourceLoader.exists(bar_icon_path):
			bar_icon.texture = load(bar_icon_path)
		bar_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		bar_icon.custom_minimum_size = Vector2(32, 32)
		hbox.add_child(bar_icon)

		var info = Label.new()
		info.text = "%s: %d (Smelt cost: %d)" % [
			data["name"], GameManager.get_ore_count(ore_id),
			data["ore_per_bar"]
		]
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_theme_color_override("font_color", Color.html(data["color"]))
		hbox.add_child(info)

		var btn = Button.new()
		btn.text = "Smelt"
		btn.disabled = GameManager.get_ore_count(ore_id) < data["ore_per_bar"]
		btn.pressed.connect(_on_smelt.bind(ore_id))
		hbox.add_child(btn)

		# Smelt all button
		var btn_all = Button.new()
		btn_all.text = "All"
		btn_all.disabled = GameManager.get_ore_count(ore_id) < data["ore_per_bar"]
		btn_all.pressed.connect(_on_smelt_all.bind(ore_id))
		hbox.add_child(btn_all)

		ore_list.add_child(hbox)


func _on_smelt(ore_id: String) -> void:
	if GameManager.smelt_ore(ore_id):
		var data = GameManager.ore_data[ore_id]
		result_label.text = "[OK] Smelted 1 %s!" % data["bar_name"]
		_flash_result()


func _on_smelt_all(ore_id: String) -> void:
	var count = 0
	while GameManager.smelt_ore(ore_id):
		count += 1
	if count > 0:
		var data = GameManager.ore_data[ore_id]
		result_label.text = "[OK] Smelted %d %s!" % [count, data["bar_name"]]
		_flash_result()


func _flash_result() -> void:
	var tween = create_tween()
	result_label.modulate = Color.WHITE
	tween.tween_property(result_label, "modulate:a", 0.0, 2.0).set_delay(1.0)
