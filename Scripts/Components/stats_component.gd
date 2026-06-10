class_name StatsComponent
extends Node

signal stats_changed(current_stats: Dictionary)


var stats := {
	"strength": 0,
	"intelligence": 0,
	"faith": 0,
	"agillity": 0,
	"attack": 0,
	"defense": 0,
	"max_hp": 1,
}

func setup_from_class(class_data: ClassData, rolled_atributes: Dictionary) -> void:
	stats.strength = rolled_atributes.get("strength", 0)
	stats.intelligence = rolled_atributes.get("intelligence", 0)
	stats.faith = rolled_atributes.get("faith", 0)
	stats.agility = rolled_atributes.get("agility", 0)
	
	stats.attack = class_data.base_attack + stats.strength
	stats.defense = class_data.base_defense + int(stats.agility / 2)
	stats.max_hp = class_data.base_hp + stats.strength
	stats_changed.emit(stats)


func setup_from_enemy(enemy_data: EnemyData, rolled_value: int) -> void:
	stats.strength = rolled_value
	stats.intelligence = rolled_value
	stats.faith = rolled_value
	stats.agility = rolled_value
	
	stats.attack = enemy_data.base_attack + rolled_value
	stats.defense = enemy_data.base_defense + int(rolled_value / 2)
	stats.max_hp = enemy_data.base_hp + rolled_value
	stats_changed.emit(stats)
	

func get_value(stat_name: String) -> int:
	return stats.get(stat_name, 0) 
