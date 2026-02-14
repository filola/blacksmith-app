extends Control

## 채굴 탭 - 클릭해서 광석 캐기

@onready var mine_button: Button = %MineButton
@onready var ore_list: VBoxContainer = %OreList
@onready var mine_progress: ProgressBar = %MineProgress
@onready var mine_label: Label = %MineLabel
@onready var power_label: Label = %PowerLabel
@onready var prob_list: VBoxContainer = %ProbList

var current_ore: String = "copper"
var mine_progress_value: float = 0.0
var mining_time: float = 1.0

func _ready() -> void:
	# 게임 시작 시 첫 광석 선택
	_select_random_ore()
	_update_display()
	_refresh_ore_list()
	_refresh_probability_list()
	mine_button.pressed.connect(_on_mine_click)
	GameManager.ore_changed.connect(_on_ore_changed)
	GameManager.tier_unlocked.connect(_on_tier_unlocked)


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
	
	# 다음 광석 선택 (랜덤)
	_select_random_ore()
	_update_display()


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


## 광석 드롭 확률 계산
func _calculate_ore_probabilities() -> Dictionary:
	var probabilities: Dictionary = {}
	var available_ores: Array[String] = []
	
	# 현재 해금된 광석만 필터링
	for ore_id in GameManager.ore_data:
		var data = GameManager.ore_data[ore_id]
		if data["tier"] <= GameManager.max_unlocked_tier:
			available_ores.append(ore_id)
	
	# 티어별 기본 확률 계산
	var tier_probabilities: Dictionary = {}
	for ore_id in available_ores:
		var tier = GameManager.ore_data[ore_id]["tier"]
		if not tier_probabilities.has(tier):
			tier_probabilities[tier] = []
		tier_probabilities[tier].append(ore_id)
	
	# 티어별 가중치 (낮은 티어일수록 높음)
	var max_tier = 1
	for ore_id in available_ores:
		max_tier = max(max_tier, GameManager.ore_data[ore_id]["tier"])
	
	var tier_weights: Dictionary = {}
	for tier in tier_probabilities:
		# 역 가중치: Tier 1 = 70%, Tier 2 = 25%, Tier 3+ = 5%
		if tier == 1:
			tier_weights[tier] = 70.0
		elif tier == 2:
			tier_weights[tier] = 25.0
		else:
			tier_weights[tier] = 5.0 / max(1, max_tier - 2)
	
	# 각 광석의 확률 계산
	for tier in tier_probabilities:
		var tier_prob = tier_weights.get(tier, 0.0)
		var ore_count = tier_probabilities[tier].size()
		var ore_prob = tier_prob / ore_count
		
		for ore_id in tier_probabilities[tier]:
			probabilities[ore_id] = ore_prob
	
	return probabilities


## 랜덤 광석 선택 (확률 기반)
func _select_random_ore() -> void:
	var available_ores: Array[String] = []
	
	# 현재 해금된 광석만 필터링
	for ore_id in GameManager.ore_data:
		var data = GameManager.ore_data[ore_id]
		if data["tier"] <= GameManager.max_unlocked_tier:
			available_ores.append(ore_id)
	
	# 확률 계산
	var probabilities = _calculate_ore_probabilities()
	
	# 확률 기반 선택
	var random_value = randf() * 100.0
	var cumulative = 0.0
	var selected_ore = available_ores[0]
	
	for ore_id in available_ores:
		cumulative += probabilities.get(ore_id, 0.0)
		if random_value < cumulative:
			selected_ore = ore_id
			break
	
	current_ore = selected_ore
	mining_time = GameManager.ore_data[current_ore]["base_time"]
	mine_progress_value = 0.0


func _update_display() -> void:
	var data = GameManager.ore_data[current_ore]
	mine_label.text = data["name"] + " 채굴 중"
	power_label.text = "채굴력: %.1f" % GameManager.get_mine_power()
	mining_time = data["base_time"]
	mine_progress.value = 0


## 광석 선택 UI 제거 (랜덤 드롭 사용)


func _refresh_ore_list() -> void:
	# 보유 광석 목록 표시 (선택 버튼은 제거)
	for child in ore_list.get_children():
		child.queue_free()
	
	for ore_id in GameManager.ore_data:
		var data = GameManager.ore_data[ore_id]
		if data["tier"] <= GameManager.max_unlocked_tier:
			var label = Label.new()
			label.text = "%s: %d개" % [data["name"], GameManager.ores.get(ore_id, 0)]
			label.add_theme_color_override("font_color", Color.html(data["color"]))
			ore_list.add_child(label)


func _on_ore_changed(_ore_id: String, _amount: int) -> void:
	# 광석 개수 업데이트
	_refresh_ore_list()


func _on_tier_unlocked(_tier: int) -> void:
	# 새 티어 언락 시 확률 업데이트
	_refresh_probability_list()


## 드롭 확률 목록 업데이트
func _refresh_probability_list() -> void:
	# 기존 자식 제거
	for child in prob_list.get_children():
		child.queue_free()
	
	# 확률 계산
	var probabilities = _calculate_ore_probabilities()
	
	# 각 광석별 확률 표시 (내림차순으로 정렬)
	var sorted_ores: Array = []
	for ore_id in GameManager.ore_data:
		var data = GameManager.ore_data[ore_id]
		if data["tier"] <= GameManager.max_unlocked_tier:
			sorted_ores.append({
				"id": ore_id,
				"name": data["name"],
				"probability": probabilities.get(ore_id, 0.0),
				"color": data["color"]
			})
	
	# 확률 높은 순서로 정렬
	sorted_ores.sort_custom(func(a, b): return a["probability"] > b["probability"])
	
	# UI 추가
	for ore_info in sorted_ores:
		var label = Label.new()
		var prob_percent = snapped(ore_info["probability"], 0.1)
		label.text = "%s: %.1f%%" % [ore_info["name"], prob_percent]
		label.add_theme_color_override("font_color", Color.html(ore_info["color"]))
		prob_list.add_child(label)
