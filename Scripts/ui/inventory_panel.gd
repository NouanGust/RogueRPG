class_name InventoryPanel
extends PanelContainer

signal item_selected(item: ItemData)

@onready var title_label: Label = $Panel/MarginContainer/VBoxContainer/Label
@onready var item_grid: GridContainer = $Panel/MarginContainer/VBoxContainer/Scroll/SlotsGrids
@onready var close_button: Button = $Panel/MarginContainer/VBoxContainer/CloseBtn

func _ready() -> void:
	hide()
	if close_button:
		close_button.pressed.connect(close_panel)

func open_panel() -> void:
	refresh_items()
	show()
	call_deferred("_focus_first_control")

func _focus_first_control() -> void:
	if not visible:
		return
	for child in item_grid.get_children():
		if child is Button and not child.disabled:
			child.grab_focus()
			return
	if close_button != null and close_button.is_visible_in_tree():
		close_button.grab_focus()

func close_panel() -> void:
	AudioManager.play_ui_cancel()
	hide()

func refresh_items() -> void:
	if title_label:
		title_label.text = "MOCHILA (%d / %d)" % [GameState.inventory.size(), GameState.get_max_inventory_slots()]

	for child in item_grid.get_children():
		child.queue_free()

	if GameState.inventory.is_empty():
		var empty_label := Label.new()
		empty_label.text = "Mochila vazia."
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item_grid.add_child(empty_label)
		return

	for item in GameState.inventory:
		if item == null:
			continue
		var btn := Button.new()
		btn.text = item.item_name
		btn.icon = item.icon
		btn.expand_icon = true
		btn.custom_minimum_size = Vector2(0, 48)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_constant_override("icon_max_width", 28)
		btn.add_theme_font_size_override("font_size", 16)
		btn.tooltip_text = "%s\n%s" % [item.item_name, item.description]
		btn.pressed.connect(_on_item_button_pressed.bind(item))
		item_grid.add_child(btn)

func _on_item_button_pressed(item: ItemData) -> void:
	AudioManager.play_ui_click()
	item_selected.emit(item)
