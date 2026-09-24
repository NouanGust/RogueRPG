class_name LobbyController3D
extends Node3D

@onready var camera: Camera3D = $DynamicCamera

#========================
# Markers 
#========================
@onready var pos_main: Marker3D = $CameraStations/PosMain
@onready var pos_stash: Marker3D = $CameraStations/PosStash
@onready var pos_creation: Marker3D = $CameraStations/PosCreation


#========================
# UI
#========================
@onready var main_ui: Control = $UILayer/MainUI
@onready var title_ui: Control = $UILayer/TitleMenuUI
@onready var stash_ui: Control = $UILayer/StashUI
@onready var creation_ui: Control = $UILayer/CreationUI
@onready var roll_ui: Control = $UILayer/AtrributesScene
@onready var save_ui: Control = $UILayer/SaveUI

@onready var fade_sceen: ColorRect = $UILayer/TransitionLayer

@onready var player_node: PlayerActor3D = $PlayerActor3D
var is_moving: bool = false

func _ready() -> void:
	#_snap_camera_to(pos_main)
	_switch_ui(title_ui)
	title_ui.modulate.a = 0.0
	
	title_ui.new_game_requested.connect(_on_new_game_requested)
	title_ui.load_game_requested.connect(_on_load_game_requested)
	creation_ui.class_confirmed.connect(_on_class_confirmed_in_lobby)
	roll_ui.roll_confirmed.connect(_on_roll_confirmed_in_lobby)
	save_ui.load_confirmed.connect(_on_save_selected_in_lobby)
	save_ui.back_requested.connect(_on_load_back_requested)
	
	camera.global_position = pos_main.global_position + Vector3(0, 2.0, 3.0)
	camera.global_rotation = pos_main.global_rotation
	camera.rotation_degrees.x -= 15
	
	_play_intro()


func _play_intro() -> void:
	var tween = create_tween().set_parallel(true)
	tween.tween_property(fade_sceen, "color:a", 0.0, 1.5).set_trans(Tween.TRANS_SINE)
	
	tween.tween_property(camera, "global_position", pos_main.global_position, 2.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(camera, "global_rotation", pos_main.global_rotation, 2.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	tween.tween_property(title_ui, "modulate:a", 1.0, 1.5).set_delay(1.0).set_trans(Tween.TRANS_SINE)
	
	await tween.finished
	fade_sceen.hide()

func _on_new_game_requested() -> void:
	move_to_station(pos_creation, creation_ui)


func _on_load_game_requested() -> void:
	AudioManager.play_ui_click()
	if save_ui.has_method("refresh_save_list"):
		save_ui.refresh_save_list()
		
	_switch_ui(save_ui)


func _on_load_back_requested() -> void:
	AudioManager.play_ui_cancel()
	_switch_ui(title_ui)
	
	
func _on_class_confirmed_in_lobby() -> void:
	_show_attribute_roll_ui()

func _on_save_selected_in_lobby(save_filename: String) -> void:
	# 1. Manda o SaveManager carregar esse arquivo específico para o GameState
	SaveManager.load_profile(save_filename) 
	
	# 2. Instancia a aparência e atributos do herói
	if player_node:
		player_node.show()
		if player_node.has_method("setup"):
			player_node.setup(GameState.selected_class, GameState.rolled_attributes)
			
	# 3. Transição concluída: Esconde o menu de load e revela a interface do acampamento!
	_switch_ui(main_ui)

func _show_attribute_roll_ui() -> void:
	if roll_ui.has_method("prepare_roll"):
		roll_ui.prepare_roll()
	
	roll_ui.show()
	roll_ui.modulate.a = 0.0
	
	var screen_height := get_viewport().get_visible_rect().size.y
	
	var tween := create_tween().set_parallel(true)
	tween.tween_property(creation_ui, "position:y", -screen_height, 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(roll_ui, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_SINE).set_delay(0.2)
	
	await tween.finished
	
	creation_ui.hide()
	creation_ui.position.y = 0


func _on_roll_confirmed_in_lobby() -> void:
	if player_node:
		player_node.show()
		
		if player_node.has_method("setup"):
			player_node.setup(GameState.selected_class, GameState.rolled_attributes)
	
	roll_ui.hide()
	move_to_station(pos_main, main_ui)


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
	title_ui.hide()
	stash_ui.hide()
	creation_ui.hide()
	
	if active_ui:
		active_ui.show()

func _snap_camera_to(marker: Marker3D) -> void:
	camera.global_position = marker.global_position
	camera.global_rotation = marker.global_rotation
