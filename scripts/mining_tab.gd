extends Control

## 채굴 탭 - 클릭해서 광석 캐기

@onready var mine_button: Button = %MineButton
@onready var ore_list: VBoxContainer = %OreList
@onready var mine_progress: ProgressBar = %MineProgress
@onready var mine_label: Label = %MineLabel
@onready var power_label: Label = %PowerLabel

var current_ore: String = "copper"
var mine_progress_value: float = 0.0
var mining_time: float = 1.0

func _ready() -> void:
	_update_ore_buttons()
	_update_display()
	mine_button.pressed.connect(_on_mine_click)
	GameManager.ore_changed.connect(_on_ore_changed)


func _process(delta: float) -> void:
	# 자동 채굴
	if GameManager.auto_mine_speed > 0:
		mine_progress_value += delta * GameManager.auto_mine_speed * GameManager.get_mine_power()
		if mine_progress_value >= mining_time:
			_complete_mine()
		mine_progress.value = (mine_progress_value / mining_time) * 100.0


func _on_mine_click() -> void:
	mine_progress_value += GameManager.get_mine_power() * 0.34
	if mine_progress_value >= mining_time:
		_complete_mine()
	mine_progress.value = (mine_progress_value / mining_time) * 100.0

	# 클릭 피드백
	var tween = create_tween()
	mine_button.scale = Vector2(0.9, 0.9)
	tween.tween_property(mine_button, "scale", Vector2(1, 1), 0.1)


func _complete_mine() -> void:
	# 초과 채굴분 이월 (연타 시 progress 손실 방지)
	var overflow = mine_progress_value - mining_time
	GameManager.add_ore(current_ore)
	mine_progress_value = max(overflow, 0.0)
	mine_progress.value = (mine_progress_value / mining_time) * 100.0

	# 채굴 이펙트 텍스트
	_spawn_float_text("+1 " + GameManager.ore_data[current_ore]["name"])


func _spawn_float_text(text: String) -> void:
	var label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", Color.html(GameManager.ore_data[current_ore]["color"]))
	# CanvasLayer 위에 올려서 탭 위치 무관하게 정확한 좌표 사용
	label.global_position = mine_button.global_position + Vector2(randf_range(-30, 30), -20)
	get_tree().root.add_child(label)

	var start_y = label.global_position.y
	var tween = create_tween()
	tween.tween_property(label, "global_position:y", start_y - 60, 0.8)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.8)
	tween.tween_callback(label.queue_free)


func select_ore(ore_id: String) -> void:
	if GameManager.ore_data.has(ore_id):
		var data = GameManager.ore_data[ore_id]
		if data["tier"] <= GameManager.max_unlocked_tier:
			current_ore = ore_id
			mining_time = data["base_time"]
			mine_progress_value = 0.0
			_update_display()


func _update_display() -> void:
	var data = GameManager.ore_data[current_ore]
	mine_label.text = data["name"] + " 채굴 중"
	power_label.text = "채굴력: %.1f" % GameManager.get_mine_power()
	mining_time = data["base_time"]
	mine_progress.value = 0


func _update_ore_buttons() -> void:
	for child in ore_list.get_children():
		child.queue_free()

	for ore_id in GameManager.ore_data:
		var data = GameManager.ore_data[ore_id]
		if data["tier"] > GameManager.max_unlocked_tier:
			continue

		var hbox = HBoxContainer.new()

		# 광석 아이콘
		var icon = TextureRect.new()
		var icon_path = data.get("ore_icon", "")
		if icon_path != "" and ResourceLoader.exists(icon_path):
			icon.texture = load(icon_path)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(32, 32)
		hbox.add_child(icon)

		var btn = Button.new()
		btn.text = "%s (%d)" % [data["name"], GameManager.ores.get(ore_id, 0)]
		btn.name = ore_id
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_color_override("font_color", Color.html(data["color"]))
		btn.pressed.connect(select_ore.bind(ore_id))
		hbox.add_child(btn)

		ore_list.add_child(hbox)


func _on_ore_changed(_ore_id: String, _amount: int) -> void:
	_update_ore_buttons()
