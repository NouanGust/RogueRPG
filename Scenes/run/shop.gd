class_name ShopController
extends Control

@onready var gold_label = $MarginContainer/HBoxContainer/EconPanel/GoldLabel
@onready var back_button: Button = $MarginContainer/BackButton
@onready var products_grid: GridContainer = $MarginContainer/HBoxContainer/ShopContainer
#=========================
# Exports
#=========================
@export var avaliable_items: Array[ItemData]
@export var item_card_scene: PackedScene


func _ready() -> void:
	# Signals
	back_button.pressed.connect(_on_back_button_pressed)
	back_button.mouse_entered.connect(_on_back_button_hovered)
	
	# 
	_update_gold_display()
	_generate_random_shop_stock()

func _update_gold_display() -> void:
	if gold_label:
		gold_label.text = "Moedas: %d" %SaveManager.get_coins()

func _generate_random_shop_stock() -> void:
	for child in products_grid.get_children():
		child.queue_free()
		
	var pool = avaliable_items.duplicate()
	pool.shuffle()
	var items_to_display = min(4, pool.size())
	
	for i in range(items_to_display):
		var item:ItemData = pool[i]
		if item_card_scene:
			var card = item_card_scene.instantiate()
			products_grid.add_child(card)
			card.setup(item, self)

func buy_item(item: ItemData) -> bool:
	if SaveManager.spend_coins(item.cost):
		AudioManager.play_ui_click()
		#GameState.add_item_to_inventory(item)
		_update_gold_display()
		print("Comprou: %s" %item.item_name)
		return true
	else:
		AudioManager.play_ui_cancel()
		print("Sem gold.")
		return false
		


#===================
# SFX UI 
#===================


func _on_back_button_pressed() -> void:
	AudioManager.play_ui_click()
	SceneTransition.change_scene("res://Scenes/run/main_menu_scene.tscn")

func _on_back_button_hovered() -> void:
	AudioManager.play_ui_hover()
