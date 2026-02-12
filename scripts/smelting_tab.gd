extends Control

## 제련 탭 - 광석을 주괴로

@onready var ore_list: VBoxContainer = %SmeltOreList
@onready var result_label: Label = %SmeltResultLabel

func _ready() -> void:
	_update_list()
	GameManager.ore_changed.connect(func(_a, _b): _update_list())
	GameManager.bar_changed.connect(func(_a, _b): _update_list())


func _update_list() -> void:
	for child in ore_list.get_children():
		child.queue_free()

	for ore_id in GameManager.ore_data:
		var data = GameManager.ore_data[ore_id]
		if data["tier"] > GameManager.max_unlocked_tier:
			continue

		var hbox = HBoxContainer.new()

		var info = Label.new()
		info.text = "%s: %d개 → %s: %d개 (필요: %d)" % [
			data["name"], GameManager.ores.get(ore_id, 0),
			data["bar_name"], GameManager.bars.get(ore_id, 0),
			data["ore_per_bar"]
		]
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_theme_color_override("font_color", Color(data["color"]))
		hbox.add_child(info)

		var btn = Button.new()
		btn.text = "제련"
		btn.disabled = GameManager.ores.get(ore_id, 0) < data["ore_per_bar"]
		btn.pressed.connect(_on_smelt.bind(ore_id))
		hbox.add_child(btn)

		# 전부 제련 버튼
		var btn_all = Button.new()
		btn_all.text = "전부"
		btn_all.disabled = GameManager.ores.get(ore_id, 0) < data["ore_per_bar"]
		btn_all.pressed.connect(_on_smelt_all.bind(ore_id))
		hbox.add_child(btn_all)

		ore_list.add_child(hbox)


func _on_smelt(ore_id: String) -> void:
	if GameManager.smelt_ore(ore_id):
		var data = GameManager.ore_data[ore_id]
		result_label.text = "✅ %s 1개 제련 완료!" % data["bar_name"]
		_flash_result()


func _on_smelt_all(ore_id: String) -> void:
	var count = 0
	while GameManager.smelt_ore(ore_id):
		count += 1
	if count > 0:
		var data = GameManager.ore_data[ore_id]
		result_label.text = "✅ %s %d개 제련 완료!" % [data["bar_name"], count]
		_flash_result()


func _flash_result() -> void:
	var tween = create_tween()
	result_label.modulate = Color.WHITE
	tween.tween_property(result_label, "modulate:a", 0.0, 2.0).set_delay(1.0)
