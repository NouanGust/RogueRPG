class_name BattleSceneRoot
extends Node2D


@onready var controller: BattleController =  $BattleController


func _ready() -> void:
	if not GameState.can_enter_battle():
		get_tree().change_scene_to_file("res://Scenes/Run/main_menu_scene.tscn")
		return

	controller.start_battle()
