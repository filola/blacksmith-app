extends Control

## 제작 탭 - 무기/방어구 제작 (랜덤 등급!)

@onready var recipe_list: VBoxContainer = %RecipeList
@onready var craft_result: VBoxContainer = %CraftResult
@onready var result_name: Label = %ResultName
@onready var result_grade: Label = %ResultGrade
@onready var result_price: Label = %ResultPrice

func _ready() -> void:
	_update_recipes()
	GameManager.bar_changed.connect(func(_a, _b): _update_recipes())
	GameManager.item_crafted.connect(_on_item_crafted)


func _update_recipes() -> void:
	for child in recipe_list.get_children():
		child.queue_free()

	for recipe_id in GameManager.recipe_data:
		var recipe = GameManager.recipe_data[recipe_id]
		if not recipe.get("unlocked", false):
			continue

		var hbox = HBoxContainer.new()

		# 아이템 아이콘
		var item_icon = TextureRect.new()
		var icon_path = recipe.get("icon", "")
		if icon_path != "" and ResourceLoader.exists(icon_path):
			item_icon.texture = load(icon_path)
		item_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		item_icon.custom_minimum_size = Vector2(48, 48)
		hbox.add_child(item_icon)

		# 레시피 정보
		var info = VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var name_label = Label.new()
		name_label.text = recipe["name"]
		name_label.add_theme_font_size_override("font_size", 18)
		info.add_child(name_label)

		var mat_text = ""
		for mat_id in recipe["materials"]:
			var ore_data = GameManager.ore_data[mat_id]
			var have = GameManager.bars.get(mat_id, 0)
			var need = recipe["materials"][mat_id]
			var color = "green" if have >= need else "red"
			mat_text += "[color=%s]%s %d/%d[/color]  " % [color, ore_data["bar_name"], have, need]

		var mat_label = RichTextLabel.new()
		mat_label.bbcode_enabled = true
		mat_label.text = mat_text
		mat_label.fit_content = true
		mat_label.custom_minimum_size.y = 25
		mat_label.scroll_active = false
		info.add_child(mat_label)

		# 숙련도 표시
		var craft_count = GameManager.mastery.get(recipe_id, 0)
		if craft_count > 0:
			var mastery_label = Label.new()
			mastery_label.text = "숙련도: %d회 제작" % craft_count
			mastery_label.add_theme_font_size_override("font_size", 12)
			mastery_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
			info.add_child(mastery_label)

		hbox.add_child(info)

		# 기본 가격
		var price_label = Label.new()
		price_label.text = "💰%d~" % recipe["base_price"]
		price_label.custom_minimum_size.x = 80
		hbox.add_child(price_label)

		# 제작 버튼
		var btn = Button.new()
		btn.text = "⚒️ 제작"
		btn.custom_minimum_size.x = 100
		btn.disabled = not GameManager.can_craft(recipe_id)
		btn.pressed.connect(_on_craft.bind(recipe_id))
		hbox.add_child(btn)

		# 구분선
		var sep = HSeparator.new()

		recipe_list.add_child(hbox)
		recipe_list.add_child(sep)


func _on_craft(recipe_id: String) -> void:
	var item = GameManager.craft_item(recipe_id)
	if item.is_empty():
		return

	# 결과 표시
	craft_result.visible = true
	result_name.text = item["name"]
	result_grade.text = "%s %s" % [item["grade_emoji"], item["grade_name"]]
	result_grade.add_theme_color_override("font_color", Color(item["grade_color"]))
	result_price.text = "판매가: 💰%d" % item["price"]

	# 등급별 이펙트
	_play_craft_effect(item["grade"])

	_update_recipes()


func _on_item_crafted(_name: String, _grade: String) -> void:
	pass


func _play_craft_effect(grade: String) -> void:
	var tween = create_tween()

	match grade:
		"legendary":
			# 전설! 화면 흔들림 + 금빛
			craft_result.modulate = Color(1.0, 0.8, 0.0)
			tween.tween_property(craft_result, "modulate", Color.WHITE, 1.5)
			# 흔들림
			var original_pos = craft_result.position
			for i in range(10):
				tween.tween_property(craft_result, "position",
					original_pos + Vector2(randf_range(-5, 5), randf_range(-5, 5)), 0.05)
			tween.tween_property(craft_result, "position", original_pos, 0.05)
		"epic":
			craft_result.modulate = Color(0.7, 0.2, 0.9)
			tween.tween_property(craft_result, "modulate", Color.WHITE, 1.0)
		"rare":
			craft_result.modulate = Color(0.2, 0.6, 1.0)
			tween.tween_property(craft_result, "modulate", Color.WHITE, 0.8)
		_:
			craft_result.modulate = Color.WHITE
