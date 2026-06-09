extends Node
class_name Enemy

@export var enemy_data: EnemyData

@onready var stats: StatsComponent = $StatsComponent
@onready var combat: CombatComponent = $CombatComponent

func setup(data: EnemyData, dice_roller: DiceRoller) -> void:
	enemy_data = data

	var rolled_stats := {
		"max_hp": data.max_hp,
		"strength": data.strength,
		"intelligence": data.intelligence,
		"defense": data.defense,
		"luck": data.luck
	}

	stats.setup(data.enemy_name, rolled_stats)
	stats.level = data.level
	combat.stats_component = stats
	combat.dice_roller = dice_roller
