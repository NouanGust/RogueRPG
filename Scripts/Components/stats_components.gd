extends Node
class_name StatsComponent

signal hp_changed(current_hp: int, max_hp: int)
signal died

var cl_name: String = ""
var level: int = 1
var max_hp: int = 1
var current_hp: int = 1
var strength: int = 1
var intelligence: int = 1
var defense: int = 0
var luck: int = 0

func setup(base_class_name: String, rolled_stats: Dictionary) -> void:
	cl_name = base_class_name
	max_hp = rolled_stats.get("max_hp", 1)
	current_hp = max_hp
	strength = rolled_stats.get("strength", 1)
	intelligence = rolled_stats.get("intelligence", 1)
	defense = rolled_stats.get("defense", 0)
	luck = rolled_stats.get("luck", 0)
	hp_changed.emit(current_hp, max_hp)

func receive_damage(amount: int) -> int:
	var final_damage = max(1, amount - defense)
	current_hp = max(0, current_hp - final_damage)
	hp_changed.emit(current_hp, max_hp)

	if current_hp <= 0:
		died.emit()

	return final_damage

func heal(amount: int) -> int:
	var healed = min(max_hp - current_hp, amount)
	current_hp += healed
	hp_changed.emit(current_hp, max_hp)
	return healed

func is_dead() -> bool:
	return current_hp <= 0
