extends Control

## 메인 화면 - 탭 전환 + 상단 리소스 바

@onready var tab_container: TabContainer = %TabContainer
@onready var gold_label: Label = %GoldLabel
@onready var reputation_label: Label = %ReputationLabel

func _ready() -> void:
	GameManager.gold_changed.connect(_on_gold_changed)
	GameManager.reputation_changed.connect(_on_reputation_changed)
	_update_status()


func _on_gold_changed(_amount: int) -> void:
	_update_status()


func _on_reputation_changed(_amount: int) -> void:
	_update_status()


func _update_status() -> void:
	gold_label.text = "💰 %d Gold" % GameManager.gold
	reputation_label.text = "⭐ 명성: %d" % GameManager.reputation
