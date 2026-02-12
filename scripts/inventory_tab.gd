extends Control

## 인벤토리/가게 탭 - 제작한 아이템 확인 + 판매

@onready var item_list: VBoxContainer = %ItemList
@onready var sell_all_button: Button = %SellAllButton
@onready var sell_result: Label = %SellResult

func _ready() -> void:
	_update_list()
	sell_all_button.pressed.connect(_on_sell_all)
	GameManager.item_crafted.connect(func(_a, _b): _update_list())
	GameManager.gold_changed.connect(func(_a): _update_list())


func _update_list() -> void:
	for child in item_list.get_children():
		child.queue_free()

	if GameManager.inventory.is_empty():
		var empty = Label.new()
		empty.text = "아이템이 없습니다. 제작 탭에서 만들어보세요!"
		empty.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		item_list.add_child(empty)
		sell_all_button.disabled = true
		return

	sell_all_button.disabled = false

	for i in range(GameManager.inventory.size()):
		var item = GameManager.inventory[i]
		var hbox = HBoxContainer.new()

		# 등급 이모지 + 이름
		var name_label = Label.new()
		name_label.text = "%s %s [%s]" % [item["grade_emoji"], item["name"], item["grade_name"]]
		name_label.add_theme_color_override("font_color", Color(item["grade_color"]))
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(name_label)

		# 가격
		var price_label = Label.new()
		price_label.text = "💰%d" % item["price"]
		price_label.custom_minimum_size.x = 80
		hbox.add_child(price_label)

		# 판매 버튼 — 인덱스 대신 아이템 참조 사용
		var btn = Button.new()
		btn.text = "판매"
		var item_ref = item
		btn.pressed.connect(func(): _on_sell_item(item_ref))
		hbox.add_child(btn)

		item_list.add_child(hbox)


func _on_sell_item(item: Dictionary) -> void:
	var index = GameManager.inventory.find(item)
	if index == -1:
		return
	var price = GameManager.sell_item(index)
	if price > 0:
		sell_result.text = "💰 %d Gold 획득!" % price
		_flash_result()
		_update_list()


func _on_sell_all() -> void:
	var total = 0
	while not GameManager.inventory.is_empty():
		total += GameManager.sell_item(0)
	if total > 0:
		sell_result.text = "💰 총 %d Gold 획득!" % total
		_flash_result()
		_update_list()


func _flash_result() -> void:
	sell_result.modulate = Color.WHITE
	var tween = create_tween()
	tween.tween_property(sell_result, "modulate:a", 0.0, 2.0).set_delay(1.0)
