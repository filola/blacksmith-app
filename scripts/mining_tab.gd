extends Control

## Mining Tab - Click to mine ores

@onready var mine_button: Button = %MineButton
@onready var ore_list: VBoxContainer = %OreList
@onready var mine_progress: ProgressBar = %MineProgress
@onready var power_label: Label = %PowerLabel
@onready var prob_list: VBoxContainer = %ProbList

var current_ore: String = "copper"
var mine_progress_value: float = 0.0
var mining_time: float = 1.0

func _ready() -> void:
	# Select first ore on game start
	_select_random_ore()
	_update_display()
	_refresh_ore_list()
	_refresh_probability_list()
	mine_button.pressed.connect(_on_mine_click)
	GameManager.ore_changed.connect(_on_ore_changed)
	GameManager.tier_unlocked.connect(_on_tier_unlocked)


func _process(delta: float) -> void:
	# Auto mining
	if GameManager.get_auto_mine_speed() > 0:
		mine_progress_value += delta * GameManager.get_auto_mine_speed() * GameManager.get_mine_power()
		if mine_progress_value >= mining_time:
			_complete_mine()
		mine_progress.value = (mine_progress_value / mining_time) * 100.0


func _on_mine_click() -> void:
	mine_progress_value += GameManager.get_mine_power() * 0.34
	if mine_progress_value >= mining_time:
		_complete_mine()
	mine_progress.value = (mine_progress_value / mining_time) * 100.0

	# Click feedback
	var tween = create_tween()
	mine_button.scale = Vector2(0.9, 0.9)
	tween.tween_property(mine_button, "scale", Vector2(1, 1), 0.1)


func _complete_mine() -> void:
	# Carry over overflow (prevent progress loss on rapid clicks)
	var overflow = mine_progress_value - mining_time
	GameManager.add_ore(current_ore)
	mine_progress_value = max(overflow, 0.0)
	mine_progress.value = (mine_progress_value / mining_time) * 100.0

	# Mining effect text
	_spawn_float_text("+1 " + GameManager.ore_data[current_ore]["name"])
	
	# Select next ore (random)
	_select_random_ore()
	_update_display()


func _spawn_float_text(text: String) -> void:
	var label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", Color.html(GameManager.ore_data[current_ore]["color"]))
	# Place on CanvasLayer for accurate coordinates regardless of tab position
	label.global_position = mine_button.global_position + Vector2(randf_range(-30, 30), -20)
	get_tree().root.add_child(label)

	var start_y = label.global_position.y
	var tween = create_tween()
	tween.tween_property(label, "global_position:y", start_y - 60, 0.8)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.8)
	tween.tween_callback(label.queue_free)


## Calculate ore drop probabilities (using GameManager's ORE_SPAWN_CHANCES)
func _calculate_ore_probabilities() -> Dictionary:
	var probabilities: Dictionary = {}
	
	# Use GameConfig's ORE_SPAWN_CHANCES
	for tier in GameConfig.ORE_SPAWN_CHANCES:
		if tier > GameManager.get_max_unlocked_tier():
			continue
		
		for ore_id in GameConfig.ORE_SPAWN_CHANCES[tier]:
			probabilities[ore_id] = GameConfig.ORE_SPAWN_CHANCES[tier][ore_id]
	
	# Debug logging
	var total_prob = 0.0
	for ore_id in probabilities:
		total_prob += probabilities[ore_id]
	
	push_error("[Stats] _calculate_ore_probabilities():")
	push_error("  Available ores: %s" % probabilities.keys())
	push_error("  Probabilities: %s" % probabilities)
	push_error("  Total: %.1f%%" % total_prob)
	
	return probabilities


## Select random ore (using GameManager's probabilities)
func _select_random_ore() -> void:
	# Use GameManager's get_random_ore() - probability-based selection already implemented
	current_ore = GameManager.get_random_ore()
	mining_time = GameManager.ore_data[current_ore]["base_time"]
	mine_progress_value = 0.0
	
	push_error("[Random] Selected ore: %s (tier %d)" % [
		GameManager.ore_data[current_ore]["name"],
		GameManager.ore_data[current_ore]["tier"]
	])


func _update_display() -> void:
	var data = GameManager.ore_data[current_ore]
	power_label.text = "Mining Power: %.1f" % GameManager.get_mine_power()
	mining_time = data["base_time"]
	mine_progress.value = 0


## Ore selection UI removed (using random drops)


func _refresh_ore_list() -> void:
	# Display owned ore list (selection buttons removed)
	for child in ore_list.get_children():
		child.queue_free()
	
	for ore_id in GameManager.ore_data:
		var data = GameManager.ore_data[ore_id]
		if data["tier"] <= GameManager.get_max_unlocked_tier():
			var label = Label.new()
			label.text = "%s: %d" % [data["name"], GameManager.get_ore_count(ore_id)]
			label.add_theme_color_override("font_color", Color.html(data["color"]))
			ore_list.add_child(label)


func _on_ore_changed(_ore_id: String, _amount: int) -> void:
	# Update ore count
	_refresh_ore_list()


func _on_tier_unlocked(_tier: int) -> void:
	# Update probabilities on new tier unlock
	_refresh_probability_list()


## Update drop probability list
func _refresh_probability_list() -> void:
	# Remove existing children
	for child in prob_list.get_children():
		child.queue_free()
	
	# Calculate probabilities
	var probabilities = _calculate_ore_probabilities()
	
	# Display probability per ore (descending order)
	var sorted_ores: Array = []
	for ore_id in GameManager.ore_data:
		var data = GameManager.ore_data[ore_id]
		if data["tier"] <= GameManager.get_max_unlocked_tier():
			sorted_ores.append({
				"id": ore_id,
				"name": data["name"],
				"probability": probabilities.get(ore_id, 0.0),
				"color": data["color"]
			})
	
	# Sort by probability (highest first)
	sorted_ores.sort_custom(func(a, b): return a["probability"] > b["probability"])
	
	# Debug: check total
	var total = 0.0
	for ore_info in sorted_ores:
		total += ore_info["probability"]
	push_error("[Probability] _refresh_probability_list():")
	push_error("  Ores to display: %d" % sorted_ores.size())
	push_error("  Probability total: %.1f%%" % total)
	
	# Add UI
	for ore_info in sorted_ores:
		var label = Label.new()
		var prob_percent = snapped(ore_info["probability"], 0.1)
		label.text = "%s: %.1f%%" % [ore_info["name"], prob_percent]
		label.add_theme_color_override("font_color", Color.html(ore_info["color"]))
		prob_list.add_child(label)
		push_error("  -> %s: %.1f%%" % [ore_info["name"], prob_percent])
