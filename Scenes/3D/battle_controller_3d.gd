class_name BattleController3D
extends Node3D

signal battle_started
signal turn_changed(current_turn: String)
signal battle_finished(player_won: bool)

@onready var player_node: PlayerActor3D = $PlayerActor3D
@onready var enemy_node: EnemyActor3D = $EnemyActor3D
@onready var dice_roller: DiceRoller = $DiceRoller
@onready var ui: BattleUI = $UILayer/BattleUI
@export var combat_debug: CombatDebug

@export var enemy_pool: Array[EnemyData] = []
@export var damage_text_scene: PackedScene
@export var loot_pool: Array[ItemData] = []

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
@onready var main_camera: Camera3D = $Camera3D
var idle_time: float = 0.0
var base_camera_pos: Vector2

#const MAX_LEVEL: int = 3
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
	ui.escape_pressed.connect(player_escape)
	ui.loot_decision_made.connect(_on_loot_decision)

#func _process(_delta: float) -> void:
	#if not battle_active or main_camera == null: return
	
	#if current_turn == "player" and not action_in_progress:
		#idle_time += delta
		#var sway_x := sin(idle_time * 0.5) * 15.0
		#var sway_y := cos(idle_time * 0.3) * 8.0
		#
		#var target_pos := base_camera_pos + Vector2(sway_x, sway_y)
		#main_camera.position = main_camera.position.lerp(target_pos, delta * 2.0)
	#else:
		#main_camera.position = main_camera.position.lerp(base_camera_pos, delta * 4.0)
func start_battle() -> void:
	if GameState.selected_class == null or GameState.rolled_attributes.is_empty():
		push_error("BattleController: GameState inválido.")
		return
		
	
	#main_camera = get_viewport().get_camera_2d()
	#if main_camera:
		#base_camera_pos = main_camera.position

	battle_active = true
	current_level = GameState.current_level

	player_node.setup(GameState.selected_class, GameState.rolled_attributes)
	_spawn_enemy_for_level(current_level)
	
	#if combat_debug:
		#combat_debug.setup(player_node, enemy_node)

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
	
	if not GameState.level_changed.is_connected(_on_player_level_up):
		GameState.level_changed.connect(_on_player_level_up)
	_set_turn("player")
	battle_started.emit()

func _spawn_enemy_for_level(level: int) -> void:
	if enemy_pool.is_empty():
		push_error("BattleController3D: enemy_pool vazio.")
		return

	var valid_enemies: Array[EnemyData] = []
	for enemy in enemy_pool:
		valid_enemies.append(enemy)

	var enemy_data: EnemyData = valid_enemies.pick_random() if not valid_enemies.is_empty() else enemy_pool.pick_random()
	var dice_size := _get_level_dice(level)
	var rolled_value := dice_roller.roll(dice_size)
	enemy_node.setup(enemy_data, rolled_value)
	
	var base_pos = Vector3(0, 0, -2) 
	
	enemy_node.global_position = Vector3(base_pos.x, base_pos.y, base_pos.z - 8)
	enemy_node.play_walk()
	
	var tween = create_tween()
	tween.tween_property(enemy_node, "global_position", base_pos, 1.5).set_trans(Tween.TRANS_LINEAR)
	await tween.finished
	
	enemy_node.play_idle()

func _get_level_dice(level: int) -> int:
	return 2 + (level * 2)

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
		var spawn_pos = enemy_node.global_position + Vector3(0, -30, 0)
		text_node.start(damage, spawn_pos, damage >=5)
	
	
	ui.log_damage("Você atacou e causou %d de dano." % damage)

	if enemy_node.health_component.current_hp <= 0:
		action_in_progress = false
		return

	await _set_turn("enemy")
	action_in_progress = false


func player_escape() -> void:
	if not battle_active:
		get_tree().change_scene_to_file("res://Scenes/main/camp.tscn")
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
	if not battle_active or current_turn != "enemy": return 

	var original_pos = enemy_node.global_position
	var target_pos = player_node.global_position
	
	# No 3D, o Z positivo aproxima da câmera. O player está em +Z.
	# Subtraímos um pouco de Z para o inimigo parar na frente do escudo.
	target_pos.z -= 1.5 
	
	# 1. Dash 3D
	enemy_node.play_walk()
	var dash_tween = create_tween()
	dash_tween.tween_property(enemy_node, "global_position", target_pos, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await dash_tween.finished 

	# 2. Ataque
	enemy_node.play_attack()
	await enemy_node.anim_sprite.animation_finished 
	enemy_node.play_idle()
	
	var damage := enemy_node.combat_component.attack(player_node.stats_component, player_node.health_component)
	ui.log_damage("O inimigo atacou e causou %d de dano." % damage)
	
	# Tremor na câmera 3D
	trigger_camera_shake(clamp(damage * 0.05, 0.1, 0.5), 0.25)
	
	# 3. Recuo 3D
	enemy_node.play_walk()
	var return_tween = create_tween()
	return_tween.tween_property(enemy_node, "global_position", original_pos, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await return_tween.finished 

	enemy_node.play_idle()

	if player_node.health_component.current_hp <= 0: return 
	await _set_turn("player")


func use_item_from_inventory(item: ItemData) -> void:
	if not battle_active or current_turn != "player" or action_in_progress: return
	
	action_in_progress = true
	var used_suc: bool = true
	
	match item.item_type:
		"potion":
			var heal_amount = item.effect_value
			player_node.health_component.heal(heal_amount)
			ui.log_heal("Você consumiu %s e curou %d de HP!" %[item.item_name, item.effect_value])
		"elixir":
			var buff_amount = item.effect_value
			var stats = ["strength", "agility"]
			var chosen_stat = stats.pick_random()
			player_node.stats_component.apply_buff(chosen_stat, buff_amount, 3)
			ui.log_heal("O elixir fez efeito! +%d %s por 3 turnos." % [buff_amount, chosen_stat.capitalize()])
		"dice":
			ui.log_str("Voce usou um Dado!")
			#TODO Aplicar efeito do dado
		"relic":
			ui.log_str("Item especial!")
			# TODO definir funcionabilidade do item
		_:
			ui.log_str("Item Desconhecido!")
			used_suc = false

	if used_suc:
		AudioManager.play_sfx(item_sfx)
		GameState.remove_item(item)
		
		if ui.inventory_panel.has_method("refresh_items"):
			ui.inventory_panel.refresh_items()
		await  _set_turn("enemy")
	action_in_progress = false
func _on_item_used(_item_id: StringName, message: String) -> void:
	ui.log_heal(message)



func _on_enemy_died() -> void:
	if not battle_active:
		return
	
	enemy_node.play_dead()
	await enemy_node.anim_sprite.animation_finished
	await  get_tree().create_timer(0.8).timeout
	var reward := enemy_node.enemy_data.xp_reward * current_level
	GameState.add_xp(reward)
	player_xp += reward
	var coins_dropped := randi_range(2, 5) * current_level
	SaveManager.add_coins(coins_dropped)
	ui.log_str("Inimigo derrotado! +%d XP | +%d Moedas." %[reward, coins_dropped])
	
	var drop_roll: float = randf()
	if drop_roll <= 0.4 and not loot_pool.is_empty():
		var dropped_item = loot_pool.pick_random()
		ui.show_loot_screen(dropped_item)
	else:
		_procede_to_next_enemy()
	


func _on_loot_decision(decision: String, item: ItemData) -> void:
	match decision:
		"backpack":
			GameState.add_item(item)
			ui.log_str("Você guardou %s na mochila." % item.item_name)
		"stash":
			SaveManager.add_to_stash(item)
			ui.log_str("Você guardou %s no baú." % item.item_name)
		"sell":
			var sell_value = max(1, item.cost/2)
			SaveManager.add_coins(sell_value)
			ui.log_str("Você vendeu: %s por: %d." % [item.item_name, sell_value])
	if ui.inventory_panel.has_method("refresh_items"):
		ui.inventory_panel.refresh_items()
	_procede_to_next_enemy()

func _procede_to_next_enemy() -> void:
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


func _on_player_level_up(new_level: int) -> void:
	var str_roll = dice_roller.roll(4)
	var int_roll = dice_roller.roll(4)
	var fai_roll = dice_roller.roll(4)
	var agi_roll = dice_roller.roll(4)
	
	player_node.stats_component.apply_level_up(str_roll, int_roll, fai_roll, agi_roll)
	player_node.health_component.increase_max_hp(str_roll)
	
	ui.log_str("[color=yellow]LEVEL UP! Você alcançou o Nível %d![/color]" % new_level)
	ui.log_str("Atributos (d4) aumentaram: FOR+%d, INT+%d, FÉ+%d, AGI+%d" % [str_roll, int_roll, fai_roll, agi_roll])


# --- Utils ---

func trigger_hit_pause(duration: float = 0.05) -> void:
	Engine.time_scale = 0.0
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0
	

func trigger_camera_shake(intensity: float, duration: float) -> void:
	if not main_camera: return
	
	var tween = create_tween()
	var orig_h_offset = main_camera.h_offset
	var orig_v_offset = main_camera.v_offset
	
	# No 3D, sacudir o h_offset e v_offset da câmera é mais suave que rotacioná-la
	tween.tween_property(main_camera, "h_offset", intensity, duration * 0.2)
	tween.tween_property(main_camera, "v_offset", intensity, duration * 0.2)
	tween.tween_property(main_camera, "h_offset", -intensity, duration * 0.2)
	tween.tween_property(main_camera, "v_offset", -intensity, duration * 0.2)
	
	# Retorna ao eixo original
	tween.tween_property(main_camera, "h_offset", orig_h_offset, duration * 0.2)
	tween.tween_property(main_camera, "v_offset", orig_v_offset, duration * 0.2)

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
