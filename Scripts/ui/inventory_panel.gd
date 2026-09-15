class_name InventoryPanel
extends Control

signal item_selected(item: ItemData)

@export var item_button_scene: PackedScene
@onready var slots_grid: GridContainer = $Panel/MarginContainer/VBoxContainer/SlotsGrids
@onready var close_btn: Button = $Panel/MarginContainer/VBoxContainer/CloseBtn

var is_open: bool = false
var offscreen_x: float
var onscreen_x: float


func _ready() -> void:
	close_btn.pressed.connect(close_panel)
	
	var screen_width = get_viewport_rect().size.x
	offscreen_x = screen_width
	onscreen_x = screen_width - size.x
	
	position.x = offscreen_x
	hide()


func open_panel() -> void:
	if is_open: return
	#_refresh_inventory()
	show()
	is_open = true
	create_tween().tween_property(self, "position:x", onscreen_x, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	

func close_panel() -> void:
	if not is_open: return
	
	if AudioManager.has_method("play_ui_click"):
		AudioManager.play_ui_click()
	is_open = false
	
	var tween := create_tween()

	tween.tween_property(self, "position:x", offscreen_x, 0.3)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
		
	tween.tween_callback(hide)


func _refresh_inventory() -> void:
	for child in slots_grid.get_children():
		child.queue_free()
	var current_items = GameState.inventory
	
	if current_items.is_empty():
		var empty_label = Label.new()
		empty_label.text = "Inventário vazio"
		slots_grid.add_child(empty_label)
		return
	
	for item in current_items:
		if item_button_scene:
			var btn = item_button_scene.instantiate()
			slots_grid.add_child(btn)
			
			btn.setup(item)
			btn.pressed.connect(func():
				item_selected.emit(item)
				close_panel())
