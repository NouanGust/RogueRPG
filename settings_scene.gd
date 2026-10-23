class_name SettingsSceneController
extends Control

signal back_requested

@onready var master_slider: HSlider = $Panel/VBox/Master/Slider
@onready var music_slider: HSlider = $Panel/VBox/Music/Slider
@onready var sfx_slider: HSlider = $Panel/VBox/SFX/Slider
@onready var back_button: Button = $Panel/VBox/Back

var master_bus := AudioServer.get_bus_index("Master")
var music_bus := AudioServer.get_bus_index("Music")
var sfx_bus := AudioServer.get_bus_index("SFX")


func _ready() -> void:
	master_slider.value = db_to_linear(AudioServer.get_bus_volume_db(master_bus))
	music_slider.value = db_to_linear(AudioServer.get_bus_volume_db(music_bus))
	sfx_slider.value = db_to_linear(AudioServer.get_bus_volume_db(sfx_bus))
	
	master_slider.value_changed.connect(_on_master_changed)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	back_button.pressed.connect(_on_back_button_pressed)
	_update_values()


func _on_master_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(master_bus, linear_to_db(value))
	_update_values()
	
func _on_music_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(music_bus, linear_to_db(value))
	_update_values()
	
func _on_sfx_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(sfx_bus, linear_to_db(value))
	_update_values()
	
func _on_back_button_pressed() -> void:
	AudioManager.play_ui_click()
	if back_requested.get_connections().is_empty():
		SceneTransition.change_scene("res://Scenes/3D/lobby_3d.tscn")
	else:
		back_requested.emit()

func _update_values() -> void:
	$Panel/VBox/Master/Heading/Value.text = "%d%%" % roundi(master_slider.value * 100)
	$Panel/VBox/Music/Heading/Value.text = "%d%%" % roundi(music_slider.value * 100)
	$Panel/VBox/SFX/Heading/Value.text = "%d%%" % roundi(sfx_slider.value * 100)

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_back_button_pressed()
