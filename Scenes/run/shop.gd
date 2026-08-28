extends Control

@onready var gold_label = $MarginContainer/HBoxContainer/EconPanel/GoldLabel
@onready var back_button: Button = $MarginContainer/BackButton

func _ready() -> void:
	var total_coins = SaveManager.get_coins()
	gold_label.text = "Moedas: %d" %total_coins
	
	back_button.pressed.connect(_on_back_button_pressed)
	back_button.mouse_entered.connect(_on_back_button_hovered)


func _on_back_button_pressed() -> void:
	AudioManager.play_ui_click()
	SceneTransition.change_scene("res://Scenes/run/main_menu_scene.tscn")

func _on_back_button_hovered() -> void:
	AudioManager.play_ui_hover()
