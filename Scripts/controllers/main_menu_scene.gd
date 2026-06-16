class_name MainMenuSceneController
extends Control

@export var class_selection_scene: PackedScene

@onready var new_run_button: Button = $MarginContainer/ButtonsVBox/NewRunButton
@onready var quit_button: Button = $MarginContainer/ButtonsVBox/QuitButton

func _ready() -> void:
	new_run_button.pressed.connect(_on_new_run_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)

func _on_new_run_button_pressed() -> void:
	GameState.start_new_run()
	SceneTransition.change_scene("res://scenes/run/class_selection_scene.tscn")
	#get_tree().change_scene_to_packed()

func _on_quit_button_pressed() -> void:
	get_tree().quit()
