class_name CampController
extends Control

@export var all_items: Array[ItemData] = []
@export var item_card_scene: PackedScene

@onready var profile_name_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/ProfileNameLabel
@onready var coins_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/CoinsLabel
@onready var start_button: Button = $MarginContainer/VBoxContainer/HBoxContainer3/StartButton
@onready var reroll_button: Button = $MarginContainer/VBoxContainer/HBoxContainer3/RerollShopButton
@onready var shop_grid: GridContainer = $MarginContainer/VBoxContainer/HBoxContainer2/Shop/VBoxContainer/GridContainer
@onready var backpack_grid: GridContainer = $MarginContainer/VBoxContainer/HBoxContainer2/Bag/VBoxContainer/GridContainer
@onready var stash_grid: GridContainer = $MarginContainer/VBoxContainer/HBoxContainer2/Stash/VBoxContainer/GridContainer

var stash_items: Array[ItemData] = []
func _ready() -> void:
	GameState.load_inventory_from_save()
	stash_items = SaveManager.get_saved_stash()
	_update_ui()
	_update_backpack_ui()
	_update_stash_ui()
	
	
	start_button.pressed.connect(_on_start_button_pressed)
	reroll_button.pressed.connect(_on_reroll_button_pressed)
	
	_generate_shop()

func _update_ui() -> void:
	profile_name_label.text = "Perfil: %s" % SaveManager.current_profile_name
	coins_label.text = "Moedas: %d" %SaveManager.get_coins()

func _update_backpack_ui() -> void:
	for child in backpack_grid.get_children():
		child.queue_free()
		
	for item in GameState.inventory:
		var btn = _create_item_button(item)
		btn.pressed.connect(_on_backpack_item_clicked.bind(item))
		backpack_grid.add_child(btn)
		
	var max_size = SaveManager.get_backpack_limit()
	for i in range(max_size - GameState.inventory.size()):
		var empty_slot = Panel.new()
		empty_slot.custom_minimum_size = Vector2(40, 40)
		empty_slot.modulate.a = 0.3 
		backpack_grid.add_child(empty_slot)

func _update_stash_ui() -> void:
	for child in stash_grid.get_children():
		child.queue_free()
	
	for item in stash_items:
		var btn = _create_item_button(item)
		btn.pressed.connect(_on_stash_item_clicked.bind(item))
		stash_grid.add_child(btn)
		


func _create_item_button(item: ItemData) -> Button:
	var btn = Button.new()
	btn.icon = item.icon
	btn.expand_icon = true
	btn.custom_minimum_size = Vector2(40, 40)
	btn.tooltip_text = item.item_name + "\n" + item.description
	
	btn.pivot_offset = Vector2(20,20)
	btn.pivot_offset = Vector2(20, 20)
	btn.scale = Vector2.ZERO
	
	var tween = create_tween()
	tween.tween_property(btn, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return btn

func _generate_shop() -> void: 
	for child in shop_grid.get_children():
		child.queue_free()
	if all_items.is_empty():
		push_warning("CampController: Lista de itens vazia")
		return
	
	for i in range(3):
		var random_item = _roll_item_rng()
		if random_item and item_card_scene:
			var card = item_card_scene.instantiate() as ItemCard
			shop_grid.add_child(card)
			card.setup(random_item, self)

func _roll_item_rng() -> ItemData:
	var roll = randf()
	var pool: Array[ItemData] = []
	
	for item in all_items:
		if item.item_type == "relic":
			if roll > 0.90: pool.append(item)
		elif item.item_type == "dice":
			if roll > 0.60: pool.append(item)
	
	if pool.is_empty():
		return all_items.pick_random()
	
	return pool.pick_random()

func buy_item(item: ItemData, card_node: Control) -> bool:
	if SaveManager.get_coins() < item.cost:
		AudioManager.play_ui_cancel()
		trigger_ui_error(coins_label)
		trigger_ui_error(card_node)
		return false
	if not GameState.has_inventory_space():
		AudioManager.play_ui_cancel()
		trigger_ui_error(coins_label)
		trigger_ui_error(card_node)
		return false
	
	SaveManager.spend_coins(item.cost)
	GameState.add_item(item)
	
	var tween = create_tween()
	var original_pos = card_node.position
	
	tween.tween_property(card_node, "position:y", original_pos.y - 15, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(card_node, "scale", Vector2(1.05, 1.05), 0.1)
	
	tween.tween_property(card_node, "position:y", original_pos.y, 0.15).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(card_node, "scale", Vector2.ONE, 0.15)
	
	
	_update_ui()
	_update_backpack_ui()
	
	AudioManager.play_ui_choose()
	return true


func _on_reroll_button_pressed() -> void:
	var reroll_cost = 10
	if SaveManager.spend_coins(reroll_cost):
		AudioManager.play_ui_click()
		_generate_shop()
		_update_ui()
	else:
		AudioManager.play_ui_cancel()
		trigger_ui_error(coins_label)
		trigger_ui_error(reroll_button)

func _on_start_button_pressed() -> void:
	AudioManager.play_ui_choose()
	GameState.reset_run()
	SceneTransition.change_scene("res://Scenes/run/class_selection_scene.tscn")

func _on_backpack_item_clicked(item: ItemData) -> void:
	AudioManager.play_ui_click()
	GameState.remove_item(item)
	stash_items.append(item)
	
	SaveManager.save_stash(stash_items)
	
	_update_backpack_ui()
	_update_stash_ui()


func _on_stash_item_clicked(item: ItemData) -> void:
	if not GameState.has_inventory_space():
		AudioManager.play_ui_cancel()
		trigger_ui_error(backpack_grid)
		return
	
	AudioManager.play_ui_click()
	stash_items.erase(item)
	GameState.add_item(item)
	
	SaveManager.save_stash(stash_items)
	
	_update_backpack_ui()
	_update_stash_ui()

func trigger_ui_error(control: Control) -> void:
	if not is_instance_valid(control): return
	
	var tween = create_tween()
	var original_x = control.position.x
	var original_color = control.modulate
	
	control.modulate = Color.RED
	tween.tween_property(control, "position:x", original_x - 6, 0.04)
	tween.tween_property(control, "position:x", original_x + 6, 0.04)
	tween.tween_property(control, "position:x", original_x - 4, 0.04)
	tween.tween_property(control, "position:x", original_x + 4, 0.04)
	tween.tween_property(control, "position:x", original_x, 0.04)
	
	tween.parallel().tween_property(control, "modulate", original_color, 0.25)
