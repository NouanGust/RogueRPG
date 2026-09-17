class_name InventoryPanel
extends PanelContainer

signal item_selected(item: ItemData)

@onready var item_grid: GridContainer = $Panel/MarginContainer/VBoxContainer/SlotsGrids
@onready var close_button: Button = $Panel/MarginContainer/VBoxContainer/CloseBtn

func _ready() -> void:
	hide() 
	
	if close_button:
		close_button.pressed.connect(close_panel)

func open_panel() -> void:
	refresh_items()
	show()

func close_panel() -> void:
	AudioManager.play_ui_cancel()
	hide()

func refresh_items() -> void:
	for child in item_grid.get_children():
		child.queue_free()
		
	if GameState.inventory.is_empty():
		var empty_label = Label.new()
		empty_label.text = "Mochila vazia."
		item_grid.add_child(empty_label)
		return
		
	for item in GameState.inventory:
		var btn = Button.new()
		btn.text = item.item_name
		btn.icon = item.icon
		btn.expand_icon = true
		btn.custom_minimum_size = Vector2(150, 50)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		btn.pressed.connect(_on_item_button_pressed.bind(item))
		
		item_grid.add_child(btn)

func _on_item_button_pressed(item: ItemData) -> void:
	AudioManager.play_ui_click()
	item_selected.emit(item)
