extends Control

## 채굴 탭 - 자동 + 클릭 채굴 (랜덤 광석)

@onready var mine_button: Button = %MineButton
@onready var mine_progress: ProgressBar = %MineProgress
@onready var mine_label: Label = %MineLabel
@onready var power_label: Label = %PowerLabel
@onready var auto_label: Label = %AutoLabel

var current_ore: String = "copper"
var mine_progress_value: float = 0.0
var mining_time: float = 1.0

# 자동 채굴 설정
const AUTO_MINE_BASE_SPEED = 0.1  # 기본 0.1배속 (자동 진행)
const CLICK_BOOST_SPEED = 1.0     # 클릭 시 1.0배속 (가속)
var is_auto_mining: bool = true   # 기본적으로 자동 채굴 활성화

func _ready() -> void:
	_update_display()
	_select_random_ore()
	mine_button.pressed.connect(_on_mine_click)
	GameManager.ore_changed.connect(_on_ore_changed)


func _process(delta: float) -> void:
	# 자동 채굴 (기본 0.1배속)
	if is_auto_mining:
		mine_progress_value += delta * AUTO_MINE_BASE_SPEED * GameManager.get_mine_power()
		if mine_progress_value >= mining_time:
			_complete_mine()
		mine_progress.value = (mine_progress_value / mining_time) * 100.0
	
	# UI 업데이트
	_update_auto_label()


func _on_mine_click() -> void:
	# 클릭 시 1.0배속으로 가속 진행
	mine_progress_value += CLICK_BOOST_SPEED * GameManager.get_mine_power()
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
	
	# 다음 채굴을 위해 새로운 광석 선택
	_select_random_ore()


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


## 랜덤 광석 선택
func _select_random_ore() -> void:
	current_ore = GameManager.get_random_ore()
	mining_time = GameManager.ore_data[current_ore]["base_time"]
	mine_progress_value = 0.0
	_update_display()


func _update_display() -> void:
	var data = GameManager.ore_data[current_ore]
	mine_label.text = data["name"] + " 채굴 중"
	power_label.text = "채굴력: %.1f" % GameManager.get_mine_power()
	mining_time = data["base_time"]
	mine_progress.value = 0


func _update_auto_label() -> void:
	if auto_label:
		if is_auto_mining:
			auto_label.text = "⚙️ 자동 채굴 중... (%.1fx 속도)" % AUTO_MINE_BASE_SPEED
		else:
			auto_label.text = "⏸️ 자동 채굴 일시정지"


func _on_ore_changed(_ore_id: String, _amount: int) -> void:
	# 광석 변경 시 표시 업데이트만 수행 (버튼은 더 이상 없음)
	pass
