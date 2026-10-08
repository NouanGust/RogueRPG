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

@onready var battle_button: Button = $UILayer/MainUI/MarginContainer/HBoxContainer/BattleButton
@onready var stash_button: Button = $UILayer/MainUI/MarginContainer/HBoxContainer/StashButton
@onready var stash_back_button: Button = $UILayer/StashUI/MarginContainer/VBoxContainer/HBoxContainer3/StartButton
@onready var fade_sceen: ColorRect = $UILayer/TransitionLayer
@onready var profile_label: Label = $UILayer/MainUI/MarginContainer/ProfileNameLabel
@onready var stats_label: RichTextLabel = $UILayer/MainUI/MarginContainer/HBoxContainer2/Panel/MarginContainer/PlayerActorInfos


@onready var player_node: PlayerActor3D = $PlayerActor3D
var is_moving: bool = false

func _ready() -> void:
	
	title_ui.new_game_requested.connect(_on_new_game_requested)
	title_ui.load_game_requested.connect(_on_load_game_requested)
	creation_ui.class_confirmed.connect(_on_class_confirmed_in_lobby)
	creation_ui.back_requested.connect(_on_class_back_requested)
	roll_ui.roll_confirmed.connect(_on_roll_confirmed_in_lobby)
	save_ui.load_confirmed.connect(_on_save_selected_in_lobby)
	save_ui.back_requested.connect(_on_load_back_requested)
	battle_button.pressed.connect(_on_start_battle_pressed)
	stash_button.pressed.connect(func(): move_to_station(pos_stash, stash_ui))
	stash_back_button.pressed.connect(func(): move_to_station(pos_main, main_ui))
	
	if GameState.get("returning_from_battle"):
		GameState.returning_from_battle = false
		_handle_return_from_battle()
		
	else:
		_switch_ui(title_ui)
		title_ui.modulate.a = 0.0
		camera.global_position = pos_main.global_position + Vector3(0, 2.0, 3.0)
		camera.global_rotation = pos_main.global_rotation
		camera.rotation_degrees.x -= 15
	
		_play_intro()

func _update_main_ui_info() -> void:
	if SaveManager.current_profile_name != "":
		profile_label.text = "Perfil Ativo: " + SaveManager.current_profile_name
	else:
		profile_label.text = "Nenhum Perfil"

	if GameState.selected_class != null:
		var char_class = GameState.selected_class.display_name
		var attrs = GameState.rolled_attributes
		var current_level = GameState.current_level
		
		var info_text = "[b]Classe:[/b] %s (Nível %d)\n\n" % [char_class, current_level]
		
		# --- HP ---
		var current_hp = player_node.health_component.current_hp
		var max_hp = player_node.health_component.max_hp
		var base_hp = GameState.selected_class.base_hp
		var bonus_hp = max_hp - base_hp 
		
		var hp_tooltip = "Base: %d | Modificador: %d" % [base_hp, bonus_hp]
		if bonus_hp >= 0: hp_tooltip = "Base: %d | Modificador: +%d" % [base_hp, bonus_hp]
		info_text += "[hint=%s][b]HP:[/b] %d/%d[/hint]\n" % [hp_tooltip, current_hp, max_hp]
		
		
		## --- DANO (ATAQUE) E DEFESA ---
		# 1. Identifica o atributo principal da classe para o cálculo de Dano
		var primary_stat = GameState.selected_class.main_attribute
		var main_stat_value = attrs.get(primary_stat, 0)
		var class_base_atk = GameState.selected_class.base_attack
		var total_base_atk = class_base_atk + main_stat_value
		
		# 2. Identifica a agilidade para o cálculo de Defesa
		var agi_value = attrs.get("agility", 0)
		var class_base_def = GameState.selected_class.base_defense
		var total_base_def = class_base_def + int(agi_value / 2)
		
		var mod_atk = 0
		var mod_def = 0
		
		if player_node.stats_component.has_method("get_modifier"):
			mod_atk = player_node.stats_component.get_modifier("attack")
			mod_def = player_node.stats_component.get_modifier("defense")
			
		# Monta os tooltips detalhando a origem do poder
		var stat_name_pt = primary_stat.capitalize() # Deixa a primeira letra maiúscula
		var atk_tooltip = "Ataque da Classe: %d | Bónus (%s): +%d | Modificadores: %d" % [class_base_atk, stat_name_pt, main_stat_value, mod_atk]
		if mod_atk > 0: atk_tooltip = "Ataque da Classe: %d | Bónus (%s): +%d | Modificadores: +%d" % [class_base_atk, stat_name_pt, main_stat_value, mod_atk]
		
		var def_tooltip = "Defesa da Classe: %d | Bónus (Agilidade): +%d | Modificadores: %d" % [class_base_def, int(agi_value / 2), mod_def]
		if mod_def > 0: def_tooltip = "Defesa da Classe: %d | Bónus (Agilidade): +%d | Modificadores: +%d" % [class_base_def, int(agi_value / 2), mod_def]
		
		info_text += "[hint=%s][b]Dano:[/b] %d[/hint]\n" % [atk_tooltip, total_base_atk + mod_atk]
		info_text += "[hint=%s][b]Defesa:[/b] %d[/hint]\n\n" % [def_tooltip, total_base_def + mod_def]
		# --- ATRIBUTOS PRINCIPAIS ---
		var stat_names = {
			"strength": "Força",
			"intelligence": "Inteligência",
			"faith": "Fé",
			"agility": "Agilidade"
		}
		
		for stat_key in stat_names.keys():
			var base_val = attrs.get(stat_key, 0)
			var mod_val = 0
			
			if player_node.stats_component.has_method("get_modifier"):
				mod_val = player_node.stats_component.get_modifier(stat_key)
			
			var total_val = base_val + mod_val
			
			var stat_tooltip = "Valor Base (Dado): %d | Modificador: %d" % [base_val, mod_val]
			if mod_val >= 0: stat_tooltip = "Valor Base (Dado): %d | Modificador: +%d" % [base_val, mod_val]
			
			info_text += "[hint=%s]%s: %d[/hint]\n" % [stat_tooltip, stat_names[stat_key], total_val]
		
		stats_label.text = info_text
	else:
		stats_label.text = "Nenhum herói vivo."

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

func _on_class_back_requested() -> void:
	move_to_station(pos_main, title_ui)
	_switch_ui(title_ui)

func _on_save_selected_in_lobby(save_filename: String) -> void:
	SaveManager.load_profile(save_filename) 

	if GameState.selected_class != null:
		if player_node:
			player_node.show()
			if player_node.has_method("setup"):
				player_node.setup(GameState.selected_class, GameState.rolled_attributes)
		_switch_ui(main_ui)
	
		
	else:
		save_ui.hide()
		move_to_station(pos_creation, creation_ui)


func _on_start_battle_pressed() -> void:
	AudioManager.play_ui_click()
	SaveManager.save_active_run(GameState.selected_class, GameState.rolled_attributes)
	SceneTransition.change_scene("res://Scenes/3D/battle_scene_3d.tscn")

func _handle_return_from_battle() -> void:
	
	if GameState.selected_class != null:
		_snap_camera_to(pos_main)
		if player_node:
			player_node.show()
			if player_node.has_method("setup"):
				player_node.setup(GameState.selected_class, GameState.rolled_attributes)
		_switch_ui(main_ui)
	else:
		if SaveManager.current_profile_name != "":
			_snap_camera_to(pos_creation)
			_switch_ui(creation_ui)
		else:
			_snap_camera_to(pos_main)
			_switch_ui(title_ui)

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
	SaveManager.save_active_run(GameState.selected_class, GameState.rolled_attributes)
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
	if title_ui: title_ui.hide()
	if stash_ui: stash_ui.hide()
	if creation_ui: creation_ui.hide()
	if main_ui: main_ui.hide()
	if roll_ui: roll_ui.hide()
	if save_ui: save_ui.hide()
	
	if active_ui:
		active_ui.show()
		active_ui.modulate.a = 1.0
		if active_ui == main_ui:
			_update_main_ui_info()


func _snap_camera_to(marker: Marker3D) -> void:
	camera.global_position = marker.global_position
	camera.global_rotation = marker.global_rotation
