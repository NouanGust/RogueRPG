class_name SaveMenuController
extends Control

@onready var  profile_list: ItemList = $MarginContainer/ItemList
@onready var new_profile_input: LineEdit = $MarginContainer/HBoxContainer/NewProfileInput
@onready var create_button: Button = $MarginContainer/HBoxContainer/CreateButton
@onready var load_button: Button = $MarginContainer/HBoxContainer2/LoadButton
@onready var delete_button: Button = $MarginContainer/HBoxContainer2/DeleteButton


func _ready() -> void:
	load_button.disabled = true
	delete_button.disabled = true
	
	create_button.pressed.connect(_on_create_pressed)


func _on_create_pressed() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
