class_name ClassSelectionSceneController
extends Control

@export var available_classes: Array[ClassData] = []
@export var class_card_scene: PackedScene
@export var next_scene_path: String = "res://scenes/run/attribute_roll_scene.tscn"

@onready var classes_grid: GridContainer = $BackgroundPanel/MarginContainer/VBoxContainer/GridContainer
@onready var back_button: Button = $BackgroundPanel/MarginContainer/VBoxContainer/BottomBar/BackButton
@onready var confirm_button: Button = $BackgroundPanel/MarginContainer/VBoxContainer/BottomBar/ConfirmButton

var selected_class: ClassData

func _ready() -> void:
	back_button.pressed.connect(_on_back_button_pressed)
	confirm_button.pressed.connect(_on_confirm_button_pressed)
	confirm_button.disabled = true

	if not GameState.run_active:
		GameState.start_new_run()

	_populate_classes()

func _populate_classes() -> void:
	for child in classes_grid.get_children():
		child.queue_free()

	for class_data in available_classes:
		var card := class_card_scene.instantiate() as ClassCard
		classes_grid.add_child(card)
		card.setup(class_data)
		card.class_chosen.connect(_on_class_chosen)

func _on_class_chosen(class_data: ClassData) -> void:
	selected_class = class_data
	GameState.set_selected_class(class_data)
	confirm_button.disabled = false

func _on_confirm_button_pressed() -> void:
	if selected_class == null:
		return

	get_tree().change_scene_to_file(next_scene_path)

func _on_back_button_pressed() -> void:
	GameState.reset_run()
	get_tree().change_scene_to_file("res://scenes/run/main_menu_scene.tscn")
