class_name SaveUI
extends Control

signal load_confirmed(save_filename: String)
signal back_requested

@onready var profile_list: ItemList = $Panel/Margin/VBox/Profiles
@onready var new_profile_input: LineEdit = $Panel/Margin/VBox/CreateRow/Name
@onready var create_button: Button = $Panel/Margin/VBox/CreateRow/Create
@onready var load_button: Button = $Panel/Margin/VBox/Actions/Load
@onready var delete_button: Button = $Panel/Margin/VBox/Actions/Delete
@onready var status_label: Label = $Panel/Margin/VBox/Status
@onready var delete_dialog: ConfirmationDialog = $DeleteConfirmation
var pending_delete: String = ""

func _ready() -> void:
	create_button.pressed.connect(_on_create_pressed)
	load_button.pressed.connect(_on_load_pressed)
	delete_button.pressed.connect(_on_delete_pressed)
	$Panel/Margin/VBox/Actions/Back.pressed.connect(func(): back_requested.emit())
	profile_list.item_selected.connect(_on_profile_selected)
	profile_list.item_activated.connect(func(_index: int): _on_load_pressed())
	new_profile_input.text_submitted.connect(func(_text: String): _on_create_pressed())
	delete_dialog.confirmed.connect(_confirm_delete)
	refresh_save_list()

func refresh_save_list() -> void:
	profile_list.clear()
	for profile in SaveManager.get_all_profiles():
		profile_list.add_item(profile)
	load_button.disabled = true
	delete_button.disabled = true
	status_label.text = "Crie um perfil ou selecione um para continuar."

func show_error(message: String) -> void:
	status_label.text = message
	AudioManager.play_ui_cancel()

func _on_create_pressed() -> void:
	var profile_name := new_profile_input.text.strip_edges()
	if not SaveManager.create_new_profile(profile_name):
		show_error(SaveManager.last_error)
		return
	AudioManager.play_ui_click()
	new_profile_input.clear()
	refresh_save_list()
	load_confirmed.emit(profile_name)

func _on_load_pressed() -> void:
	var selected := profile_list.get_selected_items()
	if not selected.is_empty():
		AudioManager.play_ui_click()
		load_confirmed.emit(profile_list.get_item_text(selected[0]))

func _on_delete_pressed() -> void:
	var selected := profile_list.get_selected_items()
	if selected.is_empty():
		return
	pending_delete = profile_list.get_item_text(selected[0])
	delete_dialog.dialog_text = "Excluir o perfil %s e todo o progresso dele?" % pending_delete
	delete_dialog.popup_centered()

func _confirm_delete() -> void:
	if not SaveManager.delete_profile(pending_delete):
		show_error(SaveManager.last_error)
		return
	pending_delete = ""
	refresh_save_list()

func _on_profile_selected(_index: int) -> void:
	load_button.disabled = false
	delete_button.disabled = false
