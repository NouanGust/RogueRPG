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

var current_level: int = 1
var current_turn: String = "player"
var player_xp: int = 0
var battle_active: bool = false

const MAX_LEVEL: int = 3
const ENEMY_TURN_DELAY := 0.8

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

func start_battle() -> void:
	if GameState.selected_class == null or GameState.rolled_attributes.is_empty():
		push_error("BattleController: GameState inválido.")
		return

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
		1: return 6
		2: return 10
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
		ui.set_turn_text("Sua vez")

func player_attack() -> String:
	if not battle_active or current_turn != "player":
		return ""

	var damage := player_node.combat_component.attack(enemy_node.stats_component, enemy_node.health_component)
	ui.log_str("Você atacou e causou %d de dano." % damage)

	if enemy_node.health_component.current_hp <= 0:
		return "enemy_dead"

	await _set_turn("enemy")
	return "attack_resolved"

func player_use_item() -> void:
	if not battle_active or current_turn != "player":
		return
	ui.open_item_menu()

func player_escape() -> String:
	if not battle_active or current_turn != "player":
		return ""

	var result := dice_roller.roll(20)
	if result >= 10:
		ui.log_str("Você fugiu da batalha.")
		battle_active = false
		GameState.complete_run(false)
		battle_finished.emit(false)
		return "escaped"

	ui.log_str("Falha ao fugir. Você perdeu o turno.")
	await _set_turn("enemy")
	return "escape_failed"

func enemy_act() -> String:
	if not battle_active or current_turn != "enemy":
		return ""

	var damage := enemy_node.combat_component.attack(player_node.stats_component, player_node.health_component)
	ui.log_str("O inimigo atacou e causou %d de dano." % damage)

	if player_node.health_component.current_hp <= 0:
		return "player_dead"

	await _set_turn("player")
	return "enemy_resolved"

func _on_enemy_died() -> void:
	if not battle_active:
		return

	var reward := enemy_node.enemy_data.xp_reward * current_level
	GameState.add_xp(reward)
	player_xp += reward
	ui.log_str("Inimigo derrotado! +%d XP." % reward)

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
	ui.log_str("Você foi derrotado. Permadeath.")
	GameState.complete_run(false)
	battle_finished.emit(false)

func _on_player_health_changed(current: int, maximum: int) -> void:
	ui.update_player_health(current, maximum)

func _on_enemy_health_changed(current: int, maximum: int) -> void:
	ui.update_enemy_health(current, maximum)
