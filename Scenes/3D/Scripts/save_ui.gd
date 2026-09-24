class_name SaveUI
extends Control

signal load_confirmed(save_filename: String)
signal back_requested

@onready var  profile_list: ItemList = $MarginContainer/ItemList
@onready var new_profile_input: LineEdit = $MarginContainer/HBoxContainer/NewProfileInput
@onready var create_button: Button = $MarginContainer/HBoxContainer/CreateButton
@onready var load_button: Button = $MarginContainer/ItemList/HBoxContainer2/LoadButton
@onready var delete_button: Button = $MarginContainer/ItemList/HBoxContainer2/DeleteButton




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
	AudioManager.play_ui_click()
	
	var selected_items = profile_list.get_selected_items()
	if selected_items.size() > 0:
		var index = selected_items[0]
		
		# Tenta pegar o metadata (se você o definiu na hora de criar a lista)
		var save_filename = profile_list.get_item_metadata(index) 
		
		# PLANO B: Se o metadata for nulo, usamos o texto visível do item na lista
		if save_filename == null:
			save_filename = profile_list.get_item_text(index)
			
		# Garante que não é vazio antes de enviar o sinal convertendo para String
		if save_filename != null and str(save_filename) != "":
			load_confirmed.emit(str(save_filename))
		else:
			push_error("O item selecionado não tem um nome ou metadata válido!")

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
