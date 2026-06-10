class_name BattleController
extends Node

signal battle_started
signal turn_chanhed(current_turn: String)
signal battle_finished(player_won: bool)
signal xp_awarded(amount: int)

@export var player_node: PlayerActor
@export var enemy_node: EnemyActor
@export var dice_roller: DiceRoller

@export var enemy_pool: Array[EnemyData] = []

@export var current_level: int = 1
@export var current_turn: String = "player"
@export var player_xp: int = 1

func start_battle(player_class: ClassData, rolled_attributes: Dictionary) -> void:
	if not GameState.can_enter_battle(): return 
	
	player_node.setup(player_class, rolled_attributes)
	_spawn_enemy_for_level(current_level)
	
	player_node.health_component.died.connect(_on_player_died)
	enemy_node.health_component.died.connect(_on_enemy_died)
	
	current_turn = "player"
	turn_chanhed.emit(current_turn)
	battle_started.emit()



#region Spawn Enemy
func _spawn_enemy_for_level(level: int) -> void:
	if enemy_pool.is_empty(): return
	
	var enemy_data = enemy_pool.pick_random()
	var dice_sides = _get_level_dices(level)
	var rolled_values = dice_roller.roll(dice_sides)
	enemy_node.setup(enemy_data, rolled_values)
#endregion

func _get_level_dices(level: int) -> int:
	match level:
		1: return 6
		2: return 10
		3: return 20
		_: return 20
		
func player_attack() -> String:
	if current_turn != "player": return ""
	
	var damage := player_node.combat_component.attack(enemy_node.stats, enemy_node.health_component)
	current_turn = "enemy"
	turn_chanhed.emit(current_turn)
	return "Você atacou e causou %d de dano." % damage


func player_use_potion() -> String:
	if current_turn != "player": return ""
	
	if player_node.inventory_component.use_potions(player_node.health_component):
		current_turn = "enemy"
		turn_chanhed.emit(current_turn)
		return "Você usou uma poção."
	return "Sem poções disponíveis."


func player_escape() -> String:
	if current_turn != "Player": return ""
	
	var result = dice_roller.roll(20)
	if result >= 10:
		battle_finished.emit(false)
		return "Você fugiu!"
	else:
		current_turn = "enemy"
		turn_chanhed.emit(current_turn)
		return "Falha ao fugir. Perdeu o turno"


func enemy_act() -> String:
	if current_turn != "enemy": return ""
	
	var damage = enemy_node.combat_component.attack(player_node.stats_component, player_node.health_component)
	current_turn = "player"
	turn_chanhed.emit(current_turn)
	return "O inimigo atacou e causou %d de dano." % damage
	

func _on_player_died() -> void:
	GameState.complete_run(false)
	battle_finished.emit(false)
	
	
	
func _on_enemy_died() -> void:
	var reward = enemy_node.enemy_data.xp_reward * GameState.current_level
	GameState.add_xp(reward)
	
	if GameState.is_last_level():
		GameState.complete_run(true)
		battle_finished.emit(true)
		return
	
	GameState.advance_level()
	_spawn_enemy_for_level(GameState.current_level)
	current_turn = "player"
	turn_chanhed.emit(current_turn)
	
