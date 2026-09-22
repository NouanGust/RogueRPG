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
	
	_refresh_profile_list()
	
	create_button.pressed.connect(_on_create_pressed)
	load_button.pressed.connect(_on_load_pressed)
	delete_button.pressed.connect(_on_delete_pressed)
	profile_list.item_selected.connect(_on_profile_selected)
	profile_list.item_activated.connect(func(_index: int): _on_load_pressed())
	

func _refresh_profile_list() -> void:
	profile_list.clear()
	var profiles = SaveManager.get_all_profiles()
	for p in profiles:
		profile_list.add_item(p)
	

func _on_create_pressed() -> void:
	var p_name = new_profile_input.text.strip_edges()
	if p_name != "":
		AudioManager.play_ui_click()
		SaveManager.create_new_profile(p_name)
		new_profile_input.text = ""
		_refresh_profile_list()

func _on_load_pressed() -> void:
	var selected = profile_list.get_selected_items()
	if selected.size() > 0:
		AudioManager.play_ui_choose()
		var p_name = profile_list.get_item_text(selected[0])
		SaveManager.load_profile(p_name)
		SceneTransition.change_scene("res://Scenes/main/camp.tscn")

func _on_delete_pressed() -> void:
	var selected =  profile_list.get_selected_items()
	if selected.size() > 0:
		AudioManager.play_ui_cancel()
		var p_name = profile_list.get_item_text(selected[0])
		var path = SaveManager.SAVE_DIR + p_name + ".save"
		DirAccess.remove_absolute(path)
		
		_refresh_profile_list()
		load_button.disabled = true
		delete_button.disabled = true

func _on_profile_selected(_index: int) -> void:
	load_button.disabled = false
	delete_button.disabled = false
	AudioManager.play_ui_hover()
