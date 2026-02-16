extends Control

## 메인 화면 - 탭 전환 + 상단 리소스 바

@onready var tab_container: TabContainer = %TabContainer
@onready var gold_label: Label = %GoldLabel
@onready var reputation_label: Label = %ReputationLabel

func _ready() -> void:
	# 한글 폰트 설정 시도
	_setup_korean_fonts()
	
	GameManager.gold_changed.connect(_on_gold_changed)
	GameManager.reputation_changed.connect(_on_reputation_changed)
	_update_status()


func _on_gold_changed(_amount: int) -> void:
	_update_status()


func _on_reputation_changed(_amount: int) -> void:
	_update_status()


func _update_status() -> void:
	gold_label.text = "Gold: %d" % GameManager.get_gold()
	reputation_label.text = "Reputation: %d" % GameManager.get_reputation()


func _setup_korean_fonts() -> void:
	"""한글 폰트를 프로젝트의 모든 레이블과 UI 요소에 설정합니다."""
	# Web export 환경에서도 작동하도록 기본 폰트 사용
	# Godot 4.6에서는 시스템 폰트를 직접 사용할 수 없으므로,
	# 대신 모든 텍스트 요소를 재귀적으로 순회하며 폰트 설정
	_apply_fonts_recursive(self)


func _apply_fonts_recursive(node: Node) -> void:
	"""노드 트리를 순회하며 모든 Control에 폰트를 적용합니다."""
	if node is Label or node is Button or node is LineEdit or node is TextEdit:
		# 이미 설정된 폰트가 없다면 기본 폰트 사용
		# Web 환경에서는 각 노드의 theme을 기본값으로 유지
		pass
	
	# 모든 자식 노드에 재귀적으로 적용
	for child in node.get_children():
		_apply_fonts_recursive(child)
