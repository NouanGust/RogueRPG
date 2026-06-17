class_name BattleController
extends Node

signal battle_started
signal turn_changed(current_turn: String)
signal battle_finished(player_won: bool)

@onready var player_node: PlayerActor = $"../BattleFieldLayer/PlayerAnchor/Player"
@onready var enemy_node: EnemyActor = $"../BattleFieldLayer/EnemyAnchor/Enemy"
@onready var dice_roller: DiceRoller = $"../DiceRoller"
@onready var ui: BattleUI = $"../UILayer/BattleUI"

@export var enemy_pool: Array[EnemyData] = []
@export var damage_text_scene: PackedScene

# --- SFX ---
@export_group("SFX")
@export var attack_sfx: AudioStream
@export var hurt_sfx: AudioStream
@export var dice_sfx: AudioStream
@export var item_sfx: AudioStream
@export var heal_sfx: AudioStream

var current_level: int = 1
var current_turn: String = "player"
var player_xp: int = 0
var battle_active: bool = false
var action_in_progress: bool = false

var idle_time: float = 0.0
var base_camera_pos: Vector2
var main_camera: Camera2D

const MAX_LEVEL: int = 3
const ENEMY_TURN_DELAY := 2

func _ready() -> void:
	if player_node == null:
		push_error("BattleController: player_node nulo.")
		return
	if enemy_node == null:
		push_error("BattleController: enemy_node nulo.")
		return
	if dice_roller == null:
		push_error("BattleController: dice_roller nulo.")
		return
	if ui == null:
		push_error("BattleController: ui nula.")
		return

	ui.set_controller(self)
	ui.attack_pressed.connect(player_attack)
	ui.item_pressed.connect(player_use_item)
	ui.escape_pressed.connect(player_escape)

func _process(delta: float) -> void:
	if not battle_active or main_camera == null: return
	
	if current_turn == "player" and not action_in_progress:
		idle_time += delta
		var sway_x := sin(idle_time * 0.5) * 15.0
		var sway_y := cos(idle_time * 0.3) * 8.0
		
		var target_pos := base_camera_pos + Vector2(sway_x, sway_y)
		main_camera.position = main_camera.position.lerp(target_pos, delta * 2.0)
	else:
		main_camera.position = main_camera.position.lerp(base_camera_pos, delta * 4.0)
func start_battle() -> void:
	if GameState.selected_class == null or GameState.rolled_attributes.is_empty():
		push_error("BattleController: GameState inválido.")
		return
		
	
	main_camera = get_viewport().get_camera_2d()
	if main_camera:
		base_camera_pos = main_camera.position

	battle_active = true
	current_level = GameState.current_level

	player_node.setup(GameState.selected_class, GameState.rolled_attributes)
	_spawn_enemy_for_level(current_level)

	if not player_node.health_component.health_changed.is_connected(_on_player_health_changed):
		player_node.health_component.health_changed.connect(_on_player_health_changed)
	if not enemy_node.health_component.health_changed.is_connected(_on_enemy_health_changed):
		enemy_node.health_component.health_changed.connect(_on_enemy_health_changed)

	if not player_node.health_component.died.is_connected(_on_player_died):
		player_node.health_component.died.connect(_on_player_died)
	if not enemy_node.health_component.died.is_connected(_on_enemy_died):
		enemy_node.health_component.died.connect(_on_enemy_died)
	
	if not player_node.inventory_component.item_used.is_connected(_on_item_used):
		player_node.inventory_component.item_used.connect(_on_item_used)
		
	_on_player_health_changed(player_node.health_component.current_hp, player_node.health_component.max_hp)
	_on_enemy_health_changed(enemy_node.health_component.current_hp, enemy_node.health_component.max_hp)

	_set_turn("player")
	battle_started.emit()

func _spawn_enemy_for_level(level: int) -> void:
	if enemy_pool.is_empty():
		push_error("BattleController: enemy_pool vazio.")
		return

	var valid_enemies: Array[EnemyData] = []
	for enemy in enemy_pool:
		valid_enemies.append(enemy)

	var enemy_data: EnemyData = valid_enemies.pick_random() if not valid_enemies.is_empty() else enemy_pool.pick_random()
	var dice_size := _get_level_dice(level)
	var rolled_value := dice_roller.roll(dice_size)
	enemy_node.setup(enemy_data, rolled_value)

func _get_level_dice(level: int) -> int:
	match level:
		1: return 4
		2: return 6
		3: return 20
		_: return 20

func _set_turn(new_turn: String) -> void:
	if not battle_active:
		return

	current_turn = new_turn
	turn_changed.emit(current_turn)
	

	if current_turn == "enemy":
		ui.set_turn_text("Turno do inimigo")
		await get_tree().create_timer(ENEMY_TURN_DELAY).timeout
		if battle_active and current_turn == "enemy":
			await enemy_act()
	else:
		player_node.stats_component.tick_buffs()
		ui.set_turn_text("Sua vez")

func player_attack() -> void:
	if not battle_active or current_turn != "player" or action_in_progress:
		return
	
	action_in_progress = true
	var damage := player_node.combat_component.attack(enemy_node.stats_component, enemy_node.health_component)
	
	AudioManager.play_sfx(attack_sfx)
	trigger_hit_pause(0.08)
	
	if damage_text_scene:
		var text_node = damage_text_scene.instantiate()
		add_child(text_node)
		var spawn_pos = enemy_node.global_position + Vector2(0, -30)
		text_node.start(damage, spawn_pos, damage >=5)
	
	
	ui.log_damage("Você atacou e causou %d de dano." % damage)

	if enemy_node.health_component.current_hp <= 0:
		action_in_progress = false
		return

	await _set_turn("enemy")
	action_in_progress = false

func player_use_item() -> void:
	if not battle_active or current_turn != "player":
		return
	ui.open_item_menu()

func player_escape() -> void:
	if not battle_active:
		get_tree().change_scene_to_file("res://scenes/run/main_menu_scene.tscn")
		return
	
	
	if not battle_active or current_turn != "player" or action_in_progress:
		return 
		
	action_in_progress = true
	
	var result := dice_roller.roll(20)
	if result >= 10:
		ui.log_str("Você fugiu da batalha.")
		battle_active = false
		GameState.complete_run(false)
		battle_finished.emit(false)
		action_in_progress = false
		return 

	ui.log_str("Falha ao fugir. Você perdeu o turno.")
	await _set_turn("enemy")
	action_in_progress = false

func enemy_act() -> void:
	if not battle_active or current_turn != "enemy":
		return 

	var damage := enemy_node.combat_component.attack(player_node.stats_component, player_node.health_component)
	ui.log_damage("O inimigo atacou e causou %d de dano." % damage)
	
	trigger_screenshake(10.0, 0.25)
	
	#trigger_hit_pause(0.08)
	
	if player_node.health_component.current_hp <= 0:
		return 

	await _set_turn("player")


func use_specific_item(id: int) -> void:
	if not battle_active or current_turn != "player" or action_in_progress:
		return
	
	action_in_progress = true
	var item_used_sucessfully: bool = false
	
	if id == 0:
		item_used_sucessfully = player_node.inventory_component.use_potions(player_node.health_component)
	elif id == 1:
		item_used_sucessfully = player_node.inventory_component.use_elixir(player_node.stats_component)
	
	if item_used_sucessfully:
		await _set_turn("enemy")
	else:
		ui.log_str("Não foi possivel usar o item.")
		
	action_in_progress = false
	

func _on_item_used(item_id: StringName, message: String) -> void:
	ui.log_heal(message)



func _on_enemy_died() -> void:
	if not battle_active:
		return

	var reward := enemy_node.enemy_data.xp_reward * current_level
	GameState.add_xp(reward)
	player_xp += reward
	ui.log_str("Inimigo derrotado! +%d XP." % reward)
	
	var drop_roll: float = randf()
	if drop_roll <= 0.4:
		var is_potion: float = randf()
		if is_potion:
			player_node.inventory_component.potions += 1
			ui.log_str("O inimigo dropou uma Poção!")
		else:
			player_node.inventory_component.elixirs += 1
			ui.log_str("O inimigo dropou um Elixir!")
	

	if current_level >= MAX_LEVEL:
		battle_active = false
		GameState.complete_run(true)
		battle_finished.emit(true)
		return

	GameState.advance_level()
	current_level = GameState.current_level
	_spawn_enemy_for_level(current_level)
	_on_enemy_health_changed(enemy_node.health_component.current_hp, enemy_node.health_component.max_hp)

	await _set_turn("player")

func _on_player_died() -> void:
	if not battle_active:
		return

	battle_active = false
	ui.log_damage("Você foi derrotado. Permadeath.")
	GameState.complete_run(false)
	battle_finished.emit(false)

func _on_player_health_changed(current: int, maximum: int) -> void:
	ui.update_player_health(current, maximum)

func _on_enemy_health_changed(current: int, maximum: int) -> void:
	ui.update_enemy_health(current, maximum)



# --- Utils ---

func trigger_hit_pause(duration: float = 0.05) -> void:
	Engine.time_scale = 0.0
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0
	
	
func trigger_screenshake(intensity: float = 8.0, duration: float = 0.2) -> void:
	var camera: Camera2D = get_viewport().get_camera_2d()
	
	if not camera: return
	
	var original_offset := camera.offset
	var tween: Tween = create_tween()
	var shakes = int(duration/0.04)
	
	for i in range(shakes):
		var random_offset := Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tween.tween_property(camera, "offset", random_offset, 0.04)
	
	tween.tween_property(camera, "offset", original_offset, 0.04)
