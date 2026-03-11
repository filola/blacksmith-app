extends Control

## Mining Tab - Click the rock to mine! Miner sprite rests when idle.

@onready var mine_area: Panel = %MineArea
@onready var rock_button: TextureButton = %RockButton
@onready var rock_hp: ProgressBar = %RockHP
@onready var miner_sprite: TextureRect = %MinerSprite
@onready var pickaxe_sprite: TextureRect = %PickaxeSprite
@onready var bubble_label: Label = %BubbleLabel
@onready var ore_icon: TextureRect = %OreIcon
@onready var ore_name_label: Label = %OreNameLabel
@onready var event_label: Label = %EventLabel
@onready var power_label: Label = %PowerLabel
@onready var combo_label: Label = %ComboLabel
@onready var auto_mine_label: Label = %AutoMineLabel
@onready var ore_list: VBoxContainer = %OreList
@onready var prob_list: VBoxContainer = %ProbList

# Rock state
var current_ore: String = "copper"
var rock_hits_left: int = 3
var rock_hits_max: int = 3

# Combo system
var combo_count: int = 0
var combo_timer: float = 0.0
const COMBO_TIMEOUT = 2.0

# Idle animation
var idle_timer: float = 0.0
var idle_phase: int = 0
const IDLE_DELAY = 2.5
var last_click_time: float = 0.0
var is_idle: bool = true

# Idle bubble messages
const IDLE_BUBBLES = [
	"...", "zzZ", "zzZZ", "Phew...", "So tired...",
	"*yawn*", "...", "Back hurts!", "Need a break...",
	"*stretching*", "Hmm...", "*whistling*", "..zzz",
]

# Auto mine
var auto_mine_timer: float = 0.0

# Random events
var event_active: bool = false
var event_bonus: float = 1.0
var event_display_timer: float = 0.0

# Rock textures
var rock_textures: Array[Texture2D] = []

# Miner original positions (for animations)
var miner_origin: Vector2
var pickaxe_origin: Vector2
var pickaxe_swing_tween: Tween


func _ready() -> void:
	_load_rock_textures()
	_select_new_ore()
	_update_rock_display()
	_refresh_ore_list()
	_refresh_probability_list()
	_update_power_display()

	rock_button.pressed.connect(_on_rock_clicked)
	GameManager.ore_changed.connect(_on_ore_changed)
	GameManager.tier_unlocked.connect(_on_tier_unlocked)

	last_click_time = -IDLE_DELAY
	rock_button.pivot_offset = rock_button.size / 2.0
	pickaxe_sprite.pivot_offset = Vector2(pickaxe_sprite.size.x, pickaxe_sprite.size.y)
	bubble_label.text = ""

	# Store original positions after layout settles
	await get_tree().process_frame
	miner_origin = miner_sprite.position
	pickaxe_origin = pickaxe_sprite.position


func _process(delta: float) -> void:
	var now = Time.get_ticks_msec() / 1000.0

	# Combo decay
	if combo_count > 0:
		combo_timer -= delta
		if combo_timer <= 0:
			combo_count = 0
			combo_label.text = ""

	# Idle animation
	var time_since_click = now - last_click_time
	if time_since_click > IDLE_DELAY:
		if not is_idle:
			is_idle = true
			_start_idle_animation()
		idle_timer += delta
		if idle_timer > 2.0:
			idle_timer = 0.0
			idle_phase = (idle_phase + 1) % IDLE_BUBBLES.size()
			_show_bubble(IDLE_BUBBLES[idle_phase])
	else:
		if is_idle:
			is_idle = false
			_stop_idle_animation()

	# Event display timer
	if event_display_timer > 0:
		event_display_timer -= delta
		if event_display_timer <= 0:
			event_label.text = ""
			event_active = false
			event_bonus = 1.0

	# Auto mining
	var auto_speed = GameManager.get_auto_mine_speed()
	if auto_speed > 0:
		auto_mine_label.text = "Auto: x%.1f" % auto_speed
		auto_mine_timer += delta * auto_speed
		if auto_mine_timer >= 1.0:
			auto_mine_timer -= 1.0
			_hit_rock(false)
	else:
		auto_mine_label.text = ""


## Start idle bob + droop animation on miner
func _start_idle_animation() -> void:
	_show_bubble("...")
	# Miner bobs up and down slowly
	var idle_tween = create_tween().set_loops()
	idle_tween.tween_property(miner_sprite, "position:y", miner_origin.y + 3.0, 1.0) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	idle_tween.tween_property(miner_sprite, "position:y", miner_origin.y - 2.0, 1.0) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	miner_sprite.set_meta("idle_tween", idle_tween)

	# Pickaxe droops down (resting)
	var pk_tween = create_tween()
	pk_tween.tween_property(pickaxe_sprite, "rotation", 0.4, 0.5) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	pickaxe_sprite.set_meta("droop_tween", pk_tween)


## Stop idle animation, reset to ready pose
func _stop_idle_animation() -> void:
	bubble_label.text = ""
	if miner_sprite.has_meta("idle_tween"):
		var t: Tween = miner_sprite.get_meta("idle_tween")
		if t and t.is_valid():
			t.kill()
		miner_sprite.remove_meta("idle_tween")
	miner_sprite.position = miner_origin

	if pickaxe_sprite.has_meta("droop_tween"):
		var t: Tween = pickaxe_sprite.get_meta("droop_tween")
		if t and t.is_valid():
			t.kill()
		pickaxe_sprite.remove_meta("droop_tween")
	pickaxe_sprite.rotation = 0.0


## Show bubble text above miner
func _show_bubble(text: String) -> void:
	bubble_label.text = text
	bubble_label.modulate = Color.WHITE
	var tween = create_tween()
	tween.tween_property(bubble_label, "modulate:a", 1.0, 0.2)
	tween.tween_interval(1.5)
	tween.tween_property(bubble_label, "modulate:a", 0.0, 0.3)


func _on_rock_clicked() -> void:
	_hit_rock(true)


func _hit_rock(is_manual: bool) -> void:
	var now = Time.get_ticks_msec() / 1000.0
	last_click_time = now
	idle_timer = 0.0

	# Pickaxe swing animation
	_swing_pickaxe()

	# Combo
	if is_manual:
		combo_count += 1
		combo_timer = COMBO_TIMEOUT
		if combo_count >= 5:
			combo_label.text = "COMBO x%d!" % combo_count
		elif combo_count >= 3:
			combo_label.text = "Combo x%d" % combo_count
		else:
			combo_label.text = ""

	# Calculate damage
	var damage = 1
	var power = GameManager.get_mine_power()
	if power >= 3.0:
		damage = 2
	if combo_count >= 10:
		damage += 1

	# Apply hit
	rock_hits_left = max(rock_hits_left - damage, 0)

	# Rock shake
	_shake_rock()

	# Update HP bar
	rock_hp.value = (float(rock_hits_left) / float(rock_hits_max)) * 100.0

	# Color shift
	var health_ratio = float(rock_hits_left) / float(rock_hits_max)
	rock_button.modulate = Color(1.0, 0.5 + health_ratio * 0.5, 0.5 + health_ratio * 0.5)

	# Sparks
	_spawn_hit_spark()

	if rock_hits_left <= 0:
		_break_rock()


## Pickaxe swing animation
func _swing_pickaxe() -> void:
	if pickaxe_swing_tween and pickaxe_swing_tween.is_valid():
		pickaxe_swing_tween.kill()

	pickaxe_sprite.rotation = 0.0
	pickaxe_swing_tween = create_tween()
	# Swing back
	pickaxe_swing_tween.tween_property(pickaxe_sprite, "rotation", -0.8, 0.06)
	# Strike forward
	pickaxe_swing_tween.tween_property(pickaxe_sprite, "rotation", 0.3, 0.08) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	# Return
	pickaxe_swing_tween.tween_property(pickaxe_sprite, "rotation", 0.0, 0.1)

	# Miner lunge forward slightly
	var lunge_tween = create_tween()
	lunge_tween.tween_property(miner_sprite, "position:x", miner_origin.x + 8.0, 0.08)
	lunge_tween.tween_property(miner_sprite, "position:x", miner_origin.x, 0.1)


func _shake_rock() -> void:
	var original_pos = rock_button.position
	var tween = create_tween()
	tween.tween_property(rock_button, "position",
		original_pos + Vector2(randf_range(-8, 8), randf_range(-6, 6)), 0.04)
	tween.tween_property(rock_button, "position",
		original_pos + Vector2(randf_range(-4, 4), randf_range(-3, 3)), 0.04)
	tween.tween_property(rock_button, "position", original_pos, 0.04)


func _spawn_hit_spark() -> void:
	var spark_pos = rock_button.global_position + rock_button.size / 2.0
	for i in range(3):
		var spark = ColorRect.new()
		spark.size = Vector2(4, 4)
		spark.color = Color(1.0, 0.9, 0.3)
		spark.global_position = spark_pos + Vector2(randf_range(-8, 8), randf_range(-8, 8))
		get_tree().root.add_child(spark)

		var angle = randf() * TAU
		var target = spark.global_position + Vector2(cos(angle), sin(angle)) * randf_range(20, 50)
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(spark, "global_position", target, 0.3)
		tween.tween_property(spark, "modulate:a", 0.0, 0.3)
		tween.chain().tween_callback(spark.queue_free)


func _break_rock() -> void:
	var qty = 1
	if combo_count >= 15:
		qty = 3
	elif combo_count >= 8:
		qty = 2
	qty = int(qty * event_bonus)

	var ore_data = GameManager.ore_data[current_ore]

	for i in range(qty):
		GameManager.add_ore(current_ore)

	# Float text
	var text = "+%d %s" % [qty, ore_data["name"]]
	if qty >= 2:
		text += "!"
	_spawn_float_text(text, rock_button.global_position + Vector2(0, -20),
		Color.html(ore_data["color"]))

	# Break particles
	_spawn_break_particles()

	# Miner celebration bubble
	if qty >= 3:
		_show_bubble("JACKPOT!")
	elif qty >= 2:
		_show_bubble("Nice!")
	else:
		_show_bubble("Got it!")

	# Random event (10%)
	if randf() < 0.10 and not event_active:
		_trigger_random_event()

	_select_new_ore()
	_update_rock_display()

	# Rock respawn animation
	rock_button.scale = Vector2(0.3, 0.3)
	rock_button.modulate = Color.WHITE
	var tween = create_tween()
	tween.tween_property(rock_button, "scale", Vector2(1.0, 1.0), 0.25) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func _trigger_random_event() -> void:
	event_active = true
	event_display_timer = 5.0

	var events = [
		{"text": "Rich Vein! x2!", "bonus": 2.0},
		{"text": "Sparkling Deposit! x3!", "bonus": 3.0},
		{"text": "Miner's Luck! x2!", "bonus": 2.0},
		{"text": "Gold Rush! x2!", "bonus": 2.0},
		{"text": "Critical Strike! x3!", "bonus": 3.0},
	]
	var evt = events[randi() % events.size()]
	event_label.text = evt["text"]
	event_bonus = evt["bonus"]

	var tween = create_tween()
	event_label.modulate = Color(1, 1, 0, 0)
	tween.tween_property(event_label, "modulate", Color(1, 1, 0, 1), 0.3)
	tween.tween_property(event_label, "modulate", Color(1, 0.9, 0.3, 1), 0.3)


func _spawn_break_particles() -> void:
	var center = rock_button.global_position + rock_button.size / 2.0
	var ore_color = Color.html(GameManager.ore_data[current_ore]["color"])
	for i in range(8):
		var p = ColorRect.new()
		p.size = Vector2(randf_range(4, 8), randf_range(4, 8))
		p.color = ore_color if randf() > 0.5 else Color(0.5, 0.5, 0.5)
		p.global_position = center + Vector2(randf_range(-10, 10), randf_range(-10, 10))
		get_tree().root.add_child(p)

		var angle = randf() * TAU
		var dist = randf_range(40, 90)
		var target = p.global_position + Vector2(cos(angle), sin(angle)) * dist
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(p, "global_position", target, 0.5).set_ease(Tween.EASE_OUT)
		tween.tween_property(p, "modulate:a", 0.0, 0.5)
		tween.chain().tween_callback(p.queue_free)


func _select_new_ore() -> void:
	current_ore = GameManager.get_random_ore()
	var data = GameManager.ore_data[current_ore]
	var base_time = data["base_time"]
	rock_hits_max = ceili(base_time / max(GameManager.get_mine_power() * 0.5, 0.1))
	rock_hits_max = clampi(rock_hits_max, 1, 8)
	rock_hits_left = rock_hits_max


func _update_rock_display() -> void:
	if not rock_textures.is_empty():
		rock_button.texture_normal = rock_textures[randi() % rock_textures.size()]
	rock_hp.value = 100.0
	rock_button.modulate = Color.WHITE

	var data = GameManager.ore_data[current_ore]
	var icon_path = "res://resources/assets/dungeon-crawl/ores/%s_ore.png" % current_ore
	if ResourceLoader.exists(icon_path):
		ore_icon.texture = load(icon_path)
	ore_name_label.text = data["name"]
	ore_name_label.add_theme_color_override("font_color", Color.html(data["color"]))


func _load_rock_textures() -> void:
	var paths = [
		"res://resources/assets/dungeon-crawl/dungeon/stone_dark0.png",
		"res://resources/assets/dungeon-crawl/dungeon/stone_dark1.png",
		"res://resources/assets/dungeon-crawl/dungeon/stone_dark2.png",
		"res://resources/assets/dungeon-crawl/dungeon/stone_gray0.png",
		"res://resources/assets/dungeon-crawl/dungeon/stone_gray1.png",
	]
	for path in paths:
		if ResourceLoader.exists(path):
			rock_textures.append(load(path))


func _spawn_float_text(text: String, global_pos: Vector2, color: Color) -> void:
	var label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 20)
	label.global_position = global_pos + Vector2(randf_range(-20, 20), 0)
	get_tree().root.add_child(label)

	var start_y = label.global_position.y
	var tween = create_tween()
	tween.tween_property(label, "global_position:y", start_y - 70, 0.9)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.9)
	tween.tween_callback(label.queue_free)


func _update_power_display() -> void:
	power_label.text = "Mining Power: %.1f" % GameManager.get_mine_power()


func _calculate_ore_probabilities() -> Dictionary:
	var probabilities: Dictionary = {}
	for tier in GameConfig.ORE_SPAWN_CHANCES:
		if tier > GameManager.get_max_unlocked_tier():
			continue
		for ore_id in GameConfig.ORE_SPAWN_CHANCES[tier]:
			probabilities[ore_id] = GameConfig.ORE_SPAWN_CHANCES[tier][ore_id]
	return probabilities


func _refresh_ore_list() -> void:
	for child in ore_list.get_children():
		child.queue_free()

	for ore_id in GameManager.ore_data:
		var data = GameManager.ore_data[ore_id]
		if data["tier"] <= GameManager.get_max_unlocked_tier():
			var hbox = HBoxContainer.new()
			var icon_path = "res://resources/assets/dungeon-crawl/ores/%s_ore.png" % ore_id
			if ResourceLoader.exists(icon_path):
				var icon = TextureRect.new()
				icon.texture = load(icon_path)
				icon.custom_minimum_size = Vector2(24, 24)
				icon.expand_mode = TextureRect.EXPAND_KEEP_SIZE
				icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				hbox.add_child(icon)
			var label = Label.new()
			label.text = "%s: %d" % [data["name"], GameManager.get_ore_count(ore_id)]
			label.add_theme_color_override("font_color", Color.html(data["color"]))
			hbox.add_child(label)
			ore_list.add_child(hbox)

	# Dungeon materials
	var has_any_dungeon_mat = false
	for mat_id in GameManager.dungeon_materials_data:
		if GameManager.get_ore_count(mat_id) > 0:
			has_any_dungeon_mat = true
			break
	if has_any_dungeon_mat:
		var separator = Label.new()
		separator.text = "--- Dungeon Materials ---"
		separator.add_theme_color_override("font_color", Color(0.7, 0.5, 1.0))
		ore_list.add_child(separator)
		for mat_id in GameManager.dungeon_materials_data:
			var count = GameManager.get_ore_count(mat_id)
			if count > 0:
				var data = GameManager.dungeon_materials_data[mat_id]
				var hbox = HBoxContainer.new()
				var mat_icon_path = data.get("icon", "")
				if mat_icon_path != "" and ResourceLoader.exists(mat_icon_path):
					var icon = TextureRect.new()
					icon.texture = load(mat_icon_path)
					icon.custom_minimum_size = Vector2(24, 24)
					icon.expand_mode = TextureRect.EXPAND_KEEP_SIZE
					icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
					hbox.add_child(icon)
				var label = Label.new()
				label.text = "%s: %d" % [data["name"], count]
				label.add_theme_color_override("font_color", Color.html(data["color"]))
				hbox.add_child(label)
				ore_list.add_child(hbox)


func _on_ore_changed(_ore_id: String, _amount: int) -> void:
	_refresh_ore_list()
	_update_power_display()


func _on_tier_unlocked(_tier: int) -> void:
	_refresh_probability_list()


func _refresh_probability_list() -> void:
	for child in prob_list.get_children():
		child.queue_free()
	var probabilities = _calculate_ore_probabilities()
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
	sorted_ores.sort_custom(func(a, b): return a["probability"] > b["probability"])
	for ore_info in sorted_ores:
		var label = Label.new()
		var prob_percent = snapped(ore_info["probability"], 0.1)
		label.text = "%s: %.1f%%" % [ore_info["name"], prob_percent]
		label.add_theme_color_override("font_color", Color.html(ore_info["color"]))
		prob_list.add_child(label)
