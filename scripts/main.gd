extends Control

## Main Screen - Tab switching + top resource bar

@onready var tab_container: TabContainer = %TabContainer
@onready var gold_label: Label = %GoldLabel
@onready var reputation_label: Label = %ReputationLabel

func _ready() -> void:
	# Font setup attempt
	_setup_korean_fonts()
	
	GameManager.gold_changed.connect(_on_gold_changed)
	GameManager.reputation_changed.connect(_on_reputation_changed)
	_update_status()
	
	# Version label binding
	var version_label = $VersionLabel
	if version_label:
		version_label.text = GameManager.GAME_VERSION


func _on_gold_changed(_amount: int) -> void:
	_update_status()


func _on_reputation_changed(_amount: int) -> void:
	_update_status()


func _update_status() -> void:
	gold_label.text = "[GOLD] %d Gold" % GameManager.get_gold()
	reputation_label.text = "[REP] Reputation: %d" % GameManager.get_reputation()


func _setup_korean_fonts() -> void:
	"""Set up fonts for all labels and UI elements in the project."""
	# Use default font to work in web export environment
	# Since Godot 4.6 cannot use system fonts directly,
	# traverse all text elements recursively to set fonts
	_apply_fonts_recursive(self)


func _apply_fonts_recursive(node: Node) -> void:
	"""Traverse node tree and apply fonts to all Controls."""
	if node is Label or node is Button or node is LineEdit or node is TextEdit:
		# Use default font if none is already set
		# In web environment, keep each node theme as default
		pass
	
	# Apply recursively to all child nodes
	for child in node.get_children():
		_apply_fonts_recursive(child)
