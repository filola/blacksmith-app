extends Control

## 스킬 트리 탭 - 스킬 해금 및 진행 상태 표시

@onready var skill_canvas: Control = %SkillTreeCanvas
@onready var info_panel: PanelContainer = %SkillInfoPanel
@onready var info_name: Label = %SkillName
@onready var info_desc: Label = %SkillDesc
@onready var info_cost: Label = %SkillCost
@onready var info_req: Label = %SkillReq
@onready var info_status: Label = %SkillStatus
@onready var gold_label: Label = %SkillGoldLabel

# 스킬 노드 UI 매핑
var skill_buttons: Dictionary = {}  # skill_id → Button
var skill_labels: Dictionary = {}   # skill_id → Label
var connector_lines: Array = []     # 연결선 데이터

# 레이아웃 상수
const NODE_WIDTH = 140
const NODE_HEIGHT = 50
const DEPTH_SPACING_Y = 90
const NODE_SPACING_X = 160
const CANVAS_OFFSET_Y = 30
const CANVAS_OFFSET_X = 20

# 색상
const COLOR_UNLOCKED = Color(0.2, 0.8, 0.3)      # 녹색 - 해금됨
const COLOR_AVAILABLE = Color(0.3, 0.6, 1.0)      # 파랑 - 해금 가능
const COLOR_LOCKED = Color(0.4, 0.4, 0.4)         # 회색 - 잠김
const COLOR_LINE_ACTIVE = Color(0.2, 0.8, 0.3, 0.6)
const COLOR_LINE_INACTIVE = Color(0.4, 0.4, 0.4, 0.4)


func _ready():
	info_panel.visible = false
	_build_skill_tree()
	_update_gold_display()
	GameManager.gold_changed.connect(_on_gold_changed)
	GameManager.skill_unlocked.connect(_on_skill_unlocked)


func _on_gold_changed(_amount: int) -> void:
	_update_gold_display()
	_refresh_button_states()


func _on_skill_unlocked(_skill_id: String) -> void:
	_refresh_button_states()
	skill_canvas.queue_redraw()


func _update_gold_display() -> void:
	gold_label.text = "[보유 금화] %d Gold" % GameManager.get_gold()


## 스킬 트리 전체 빌드
func _build_skill_tree() -> void:
	# 기존 버튼 제거
	for child in skill_canvas.get_children():
		child.queue_free()
	skill_buttons.clear()
	skill_labels.clear()
	connector_lines.clear()
	
	var skills = GameManager.skills_data
	if skills.is_empty():
		push_error("[스킬트리] skills_data is empty!")
		return
	
	# depth별 스킬 분류
	var depth_groups: Dictionary = {}
	for skill_id in skills:
		var depth = skills[skill_id].get("depth", 0)
		if not depth_groups.has(depth):
			depth_groups[depth] = []
		depth_groups[depth].append(skill_id)
	
	# 정렬된 depth 키
	var depths = depth_groups.keys()
	depths.sort()
	
	# 각 depth별 스킬 노드 배치
	for depth in depths:
		var group = depth_groups[depth]
		var count = group.size()
		var total_width = count * NODE_SPACING_X
		var start_x = (skill_canvas.size.x - total_width) / 2.0 + NODE_SPACING_X / 2.0 - NODE_WIDTH / 2.0
		
		for i in range(count):
			var skill_id = group[i]
			var x = start_x + i * NODE_SPACING_X + CANVAS_OFFSET_X
			var y = depth * DEPTH_SPACING_Y + CANVAS_OFFSET_Y
			_create_skill_node(skill_id, Vector2(x, y))
	
	# 연결선 데이터 생성
	for skill_id in skills:
		var requires = skills[skill_id].get("requires", [])
		for req_id in requires:
			if skill_buttons.has(req_id) and skill_buttons.has(skill_id):
				connector_lines.append({
					"from": req_id,
					"to": skill_id
				})
	
	# 연결선 그리기 위해 canvas redraw 요청
	skill_canvas.draw.connect(_on_canvas_draw)
	skill_canvas.queue_redraw()
	
	push_error("[스킬트리] Built %d skill nodes across %d depths" % [skills.size(), depths.size()])


## 개별 스킬 노드 생성
func _create_skill_node(skill_id: String, pos: Vector2) -> void:
	var skill = GameManager.skills_data[skill_id]
	
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(NODE_WIDTH, NODE_HEIGHT)
	btn.position = pos
	btn.text = skill["name"]
	btn.tooltip_text = skill["description"]
	
	# 스타일 설정
	_apply_button_style(btn, skill_id)
	
	btn.pressed.connect(_on_skill_clicked.bind(skill_id))
	btn.mouse_entered.connect(_on_skill_hovered.bind(skill_id))
	btn.mouse_exited.connect(_on_skill_unhovered)
	
	skill_canvas.add_child(btn)
	skill_buttons[skill_id] = btn


## 버튼 스타일 적용
func _apply_button_style(btn: Button, skill_id: String) -> void:
	var skill = GameManager.skills_data[skill_id]
	var is_unlocked = skill.get("unlocked", false)
	var check = GameManager.can_unlock_skill(skill_id)
	var can_unlock = check["can"]
	
	var style = StyleBoxFlat.new()
	style.border_width_bottom = 2
	style.border_width_top = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	
	if is_unlocked:
		style.bg_color = Color(0.1, 0.3, 0.1)
		style.border_color = COLOR_UNLOCKED
		btn.add_theme_color_override("font_color", COLOR_UNLOCKED)
	elif can_unlock:
		style.bg_color = Color(0.1, 0.15, 0.3)
		style.border_color = COLOR_AVAILABLE
		btn.add_theme_color_override("font_color", COLOR_AVAILABLE)
	else:
		style.bg_color = Color(0.15, 0.15, 0.15)
		style.border_color = COLOR_LOCKED
		btn.add_theme_color_override("font_color", COLOR_LOCKED)
	
	btn.add_theme_stylebox_override("normal", style)
	
	# Hover style
	var hover_style = style.duplicate()
	hover_style.bg_color = style.bg_color.lightened(0.15)
	btn.add_theme_stylebox_override("hover", hover_style)
	
	# Pressed style
	var pressed_style = style.duplicate()
	pressed_style.bg_color = style.bg_color.darkened(0.1)
	btn.add_theme_stylebox_override("pressed", pressed_style)


## 연결선 그리기
func _on_canvas_draw() -> void:
	for conn in connector_lines:
		var from_btn = skill_buttons.get(conn["from"])
		var to_btn = skill_buttons.get(conn["to"])
		if not from_btn or not to_btn:
			continue
		
		var from_pos = from_btn.position + Vector2(NODE_WIDTH / 2.0, NODE_HEIGHT)
		var to_pos = to_btn.position + Vector2(NODE_WIDTH / 2.0, 0)
		
		var from_skill = GameManager.skills_data.get(conn["from"], {})
		var to_skill = GameManager.skills_data.get(conn["to"], {})
		
		var color = COLOR_LINE_INACTIVE
		if from_skill.get("unlocked", false):
			if to_skill.get("unlocked", false):
				color = COLOR_LINE_ACTIVE
			else:
				color = Color(0.3, 0.6, 1.0, 0.5)  # 파란 계열 - 다음 단계
		
		skill_canvas.draw_line(from_pos, to_pos, color, 2.0, true)


## 호버 - 정보 패널 표시
func _on_skill_hovered(skill_id: String) -> void:
	var skill = GameManager.skills_data[skill_id]
	
	info_name.text = skill["name"]
	info_desc.text = skill["description"]
	
	if skill.get("unlocked", false):
		info_cost.text = "[해금됨]"
		info_cost.add_theme_color_override("font_color", COLOR_UNLOCKED)
	else:
		info_cost.text = "비용: %d Gold" % skill.get("cost", 0)
		if GameManager.get_gold() >= skill.get("cost", 0):
			info_cost.add_theme_color_override("font_color", Color.WHITE)
		else:
			info_cost.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	
	# 요구 스킬
	var requires = skill.get("requires", [])
	if requires.is_empty():
		info_req.text = "요구: 없음"
	else:
		var req_names: Array = []
		for req_id in requires:
			var req_skill = GameManager.skills_data.get(req_id, {})
			var req_name = req_skill.get("name", req_id)
			var is_met = req_skill.get("unlocked", false)
			if is_met:
				req_names.append("[v] " + req_name)
			else:
				req_names.append("[x] " + req_name)
		info_req.text = "요구: " + ", ".join(req_names)
	
	# 상태
	var check = GameManager.can_unlock_skill(skill_id)
	if skill.get("unlocked", false):
		info_status.text = "상태: 해금 완료"
		info_status.add_theme_color_override("font_color", COLOR_UNLOCKED)
	elif check["can"]:
		info_status.text = "상태: 해금 가능! (클릭)"
		info_status.add_theme_color_override("font_color", COLOR_AVAILABLE)
	else:
		info_status.text = "상태: " + check["reason"]
		info_status.add_theme_color_override("font_color", COLOR_LOCKED)
	
	info_panel.visible = true


## 호버 종료
func _on_skill_unhovered() -> void:
	info_panel.visible = false


## 스킬 클릭 → 해금 시도
func _on_skill_clicked(skill_id: String) -> void:
	var result = GameManager.unlock_skill(skill_id)
	if result:
		_refresh_button_states()
		skill_canvas.queue_redraw()
		# 호버 정보 업데이트
		_on_skill_hovered(skill_id)
		# 성공 피드백
		var btn = skill_buttons.get(skill_id)
		if btn:
			var tween = create_tween()
			btn.scale = Vector2(1.15, 1.15)
			tween.tween_property(btn, "scale", Vector2(1, 1), 0.2)


## 버튼 상태 새로고침
func _refresh_button_states() -> void:
	for skill_id in skill_buttons:
		var btn = skill_buttons[skill_id]
		_apply_button_style(btn, skill_id)
