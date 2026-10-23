class_name MainMenuSceneController
extends Control

# Old scene bookmarks still lead to the supported entry point.
@export var class_selection_scene: PackedScene

func _ready() -> void:
	SceneTransition.change_scene("res://Scenes/3D/lobby_3d.tscn")
