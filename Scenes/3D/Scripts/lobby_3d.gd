class_name LobbyController3D
extends Node3D

@onready var camera: Camera3D = $DynamicCamera
@onready var pos_main: Marker3D = $CameraStations/PosMain
@onready var pos_stash: Marker3D = $CameraStations/PosStash
@onready var pos_creation: Marker3D = $CameraStations/PosCreation

@onready var main_ui: Control = $UILayer/MainUI
@onready var stash_ui: Control = $UILayer/StashUI
@onready var creation_ui: Control = $UILayer/CreationUI

@onready var btn_go_stash: Button = $UILayer/MainUI/Button
var is_moving: bool = false

func _ready() -> void:
	_snap_camera_to(pos_main)
	_switch_ui(main_ui)
	
	btn_go_stash.pressed.connect(func(): move_to_station(pos_stash, stash_ui))

func move_to_station(target_marker: Marker3D, target_ui: Control):
	if is_moving: return
	is_moving = true
	
	_switch_ui(null)
	
	var tween = create_tween().set_parallel(true)
	var transition_time = 0.8
	tween.tween_property(camera, "global_position", target_marker.global_position, transition_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	
	var start_quat = camera.global_transform.basis.get_rotation_quaternion()
	var target_quat = target_marker.global_transform.basis.get_rotation_quaternion()
	
	tween.tween_property(camera, "quaternion", target_quat, transition_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	is_moving = false
	
	_switch_ui(target_ui)


func _switch_ui(active_ui: Control) -> void:
	main_ui.hide()
	stash_ui.hide()
	creation_ui.hide()
	
	if active_ui:
		active_ui.show()

func _snap_camera_to(marker: Marker3D) -> void:
	camera.global_position = marker.global_position
	camera.global_rotation = marker.global_rotation
