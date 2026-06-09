extends Node
class_name RewardComponent

var gold: int = 0
var temporary_bonuses: Dictionary = {}

func add_gold(amount: int) -> void:
	gold += amount

func add_bonus(stat_name: String, amount: int) -> void:
	temporary_bonuses[stat_name] = temporary_bonuses.get(stat_name, 0) + amount

func reset_run_bonuses() -> void:
	temporary_bonuses.clear()
