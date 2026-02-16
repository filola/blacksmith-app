extends Control

## Main screen - Tab switching + Top resource bar

@onready var tab_container: TabContainer = %TabContainer
@onready var gold_label: Label = %GoldLabel
@onready var reputation_label: Label = %ReputationLabel

func _ready() -> void:
	# Font setup attempt
	_setup_fonts()
	
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


func _setup_fonts() -> void:
	"""Set up fonts for all labels and UI elements in the project."""
	# Use default font for web export compatibility
	# In Godot 4.6, system fonts cannot be used directly,
	# so recursively traverse all text elements and set fonts
	_apply_fonts_recursive(self)


func _apply_fonts_recursive(node: Node) -> void:
	"""Traverse node tree and apply font to all Controls."""
	if node is Label or node is Button or node is LineEdit or node is TextEdit:
		# If no font is already set, use default font
		# In web environment, keep each node's theme at default
		pass
	
	# Recursively apply to all child nodes
	for child in node.get_children():
		_apply_fonts_recursive(child)
