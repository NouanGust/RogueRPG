class_name SettingsSceneController
extends Control

@onready var master_slider: HSlider = $MarginContainer/VBoxContainer/MasterSlider
@onready var music_slider: HSlider = $MarginContainer/VBoxContainer/MusicSlider
@onready var sfx_slider: HSlider = $MarginContainer/VBoxContainer/SFXSlider
@onready var back_button: Button = $MarginContainer/VBoxContainer/Button

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


func _on_master_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(master_bus, linear_to_db(value))
	
func _on_music_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(music_bus, linear_to_db(value))
	
func _on_sfx_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(sfx_bus, linear_to_db(value))
	
func _on_back_button_pressed() -> void:
	AudioManager.play_ui_click()
	SceneTransition.change_scene("res://Scenes/Run/main_menu_scene.tscn")
