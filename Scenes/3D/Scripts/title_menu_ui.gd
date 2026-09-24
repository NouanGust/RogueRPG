extends Control

signal new_game_requested
signal load_game_requested
signal config_requested


func _ready() -> void:
	$MarginContainer/ButtonsVBox/NewGameButton.pressed.connect(func(): new_game_requested.emit())
	$MarginContainer/ButtonsVBox/LoadGameButton.pressed.connect(func(): load_game_requested.emit())
	$MarginContainer/ButtonsVBox/SettingsButton.pressed.connect(func(): config_requested.emit())
	$MarginContainer/ButtonsVBox/QuitButton.pressed.connect(func(): get_tree().quit())
