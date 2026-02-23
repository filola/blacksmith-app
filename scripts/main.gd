extends Control

## Main Screen - Tab switching + top resource bar

@onready var tab_container: TabContainer = %TabContainer
@onready var gold_label: Label = %GoldLabel
@onready var reputation_label: Label = %ReputationLabel
@onready var save_button: Button = %SaveButton
@onready var load_button: Button = %LoadButton
@onready var reset_button: Button = %ResetButton
@onready var save_feedback_label: Label = %SaveFeedbackLabel

var feedback_tween: Tween

func _ready() -> void:
	# Font setup attempt
	_setup_korean_fonts()
	
	GameManager.gold_changed.connect(_on_gold_changed)
	GameManager.reputation_changed.connect(_on_reputation_changed)
	save_button.pressed.connect(_on_save_pressed)
	load_button.pressed.connect(_on_load_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
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


func _on_save_pressed() -> void:
	if GameManager.save_game():
		_show_save_feedback("Game Saved!", Color(0.5, 1.0, 0.5))
	else:
		_show_save_feedback("Save unavailable on this platform.", Color(1.0, 0.6, 0.4))


func _on_load_pressed() -> void:
	if GameManager.load_game():
		_show_save_feedback("Game Loaded!", Color(0.5, 0.8, 1.0))
	else:
		_show_save_feedback("No save found or load failed.", Color(1.0, 0.6, 0.4))


func _on_reset_pressed() -> void:
	_show_save_feedback("Resetting game...", Color(1.0, 0.8, 0.5))
	call_deferred("_deferred_reset_game")


func _deferred_reset_game() -> void:
	GameManager.reset_game()


func _show_save_feedback(message: String, color: Color) -> void:
	save_feedback_label.text = message
	save_feedback_label.modulate = color
	save_feedback_label.modulate.a = 1.0

	if feedback_tween:
		feedback_tween.kill()
	feedback_tween = create_tween()
	feedback_tween.tween_interval(1.0)
	feedback_tween.tween_property(save_feedback_label, "modulate:a", 0.0, 0.7)


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
