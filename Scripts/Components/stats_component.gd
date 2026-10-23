class_name StatsComponent
extends Node

signal stats_changed(current_stats: Dictionary)
signal buff_status_changed(message: String)


var stats := {
	"strength": 0,
	"intelligence": 0,
	"faith": 0,
	"agility": 0,
	"attack": 0,
	"defense": 0,
	"max_hp": 1,
}

var active_buff := {
	"stat": "",
	"amount": 0,
	"turns": 0
}

var primary_stat: String
var base_attack: int = 0
var base_defense: int = 0
var base_hp: int = 1

func setup_from_class(class_data: ClassData, rolled_atributes: Dictionary) -> void:
	primary_stat = class_data.main_attribute
	base_attack = class_data.base_attack
	base_defense = class_data.base_defense
	base_hp = class_data.base_hp
	active_buff = {"stat": "", "amount": 0, "turns": 0}
	
	stats.strength = rolled_atributes.get("strength", 0)
	stats.intelligence = rolled_atributes.get("intelligence", 0)
	stats.faith = rolled_atributes.get("faith", 0)
	stats.agility = rolled_atributes.get("agility", 0)
	
	_recalculate_derived_stats()
	stats_changed.emit(stats)


func setup_from_enemy(enemy_data: EnemyData, rolled_value: int) -> void:
	active_buff = {"stat": "", "amount": 0, "turns": 0}
	stats.strength = rolled_value
	stats.intelligence = rolled_value
	stats.faith = rolled_value
	stats.agility = rolled_value
	
	stats.attack = enemy_data.base_attack + rolled_value
	stats.defense = enemy_data.base_defense + int(rolled_value / 2)
	stats.max_hp = enemy_data.base_hp + rolled_value
	stats_changed.emit(stats)
	

func apply_buff(stat_name: String, amount: int, turns: int) -> void:
	active_buff["stat"] = stat_name
	active_buff["amount"] = amount
	active_buff["turns"] = turns
	buff_status_changed.emit("Buff de +%d %s por %d turnos!"  % [amount, stat_name.capitalize(), turns])

func tick_buffs() -> void:
	if active_buff["turns"] > 0:
		active_buff["turns"] -= 1
		if active_buff["turns"] <= 0:
			var expired_stat = active_buff["stat"]
			active_buff["stat"] = ""
			buff_status_changed.emit("O buff de %s acabou." % expired_stat.capitalize())

func get_value(stat_name: String) -> int:
	var base_value: int = stats.get(stat_name, 0)
	return base_value + get_modifier(stat_name)

func get_modifier(stat_name: String) -> int:
	var bonus: int = 0
	
	if active_buff["turns"] > 0:
		if active_buff["stat"] == stat_name:
			bonus += active_buff["amount"]
			
		if stat_name == "attack" and active_buff["stat"] in [primary_stat, "primary_stat"]:
			bonus += active_buff["amount"]
		elif stat_name == "defense" and active_buff["stat"] == "agility":
			bonus += int((stats.agility + active_buff["amount"]) / 2) - int(stats.agility / 2)
			
	return bonus

func _recalculate_derived_stats() -> void:
	stats.attack = base_attack + stats.get(primary_stat, 0)
	stats.defense = base_defense + int(stats.agility / 2)
	stats.max_hp = base_hp + stats.strength

func apply_level_up(str_bonus: int, int_bonus: int, fai_bonus: int, agi_bonus: int) -> void:
	stats.strength += str_bonus
	stats.intelligence += int_bonus
	stats.faith += fai_bonus
	stats.agility += agi_bonus
	
	_recalculate_derived_stats()
	
	stats_changed.emit(stats)
