class_name BattleController
extends Node

# Compatibility entry point for the retired 2D battle scene.
# Combat rules live in Scenes/3D/battle_controller_3d.gd.
func start_battle() -> void:
	SceneTransition.change_scene("res://Scenes/3D/battle_scene_3d.tscn")
