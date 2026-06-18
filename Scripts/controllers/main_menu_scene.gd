class_name MainMenuSceneController
extends Control

@export var class_selection_scene: PackedScene

@onready var new_run_button: Button = $MarginContainer/ButtonsVBox/NewRunButton
@onready var settings_button: Button = $MarginContainer/ButtonsVBox/SettingsButton
@onready var quit_button: Button = $MarginContainer/ButtonsVBox/QuitButton

func _ready() -> void:
	AudioManager.play_menu_music()
	new_run_button.pressed.connect(_on_new_run_button_pressed)
	new_run_button.mouse_entered.connect(_on_new_run_button_hovered)
	
	settings_button.pressed.connect(_on_settings_button_pressed)
	settings_button.mouse_entered.connect(_on_settings_button_hovered)
	
	quit_button.pressed.connect(_on_quit_button_pressed)
	quit_button.mouse_entered.connect(_on_quit_button_hovered)

func _on_new_run_button_pressed() -> void:
	AudioManager.play_ui_click()
	GameState.start_new_run()
	SceneTransition.change_scene("res://Scenes/Run/class_selection_scene.tscn")

func _on_new_run_button_hovered() -> void:
	AudioManager.play_ui_hover()

func _on_settings_button_pressed() -> void:
	AudioManager.play_ui_click()
	SceneTransition.change_scene("res://Scenes/main/SettingsScene.tscn")

func _on_settings_button_hovered() -> void:
	AudioManager.play_ui_hover()

func _on_quit_button_pressed() -> void:
	AudioManager.play_ui_cancel()
	get_tree().quit()

func _on_quit_button_hovered() -> void:
	AudioManager.play_ui_hover()
