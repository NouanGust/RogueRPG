class_name CombatComponent
extends Node

signal attacked(raw_damage: int, final_damage: int)

@export var stats_component: StatsComponent
@export var health_component: HealthComponent

func attack(target_stats: StatsComponent, target_health: HealthComponent) -> int:
	var raw_damage := stats_component.get_value("attack")
	var defense := target_stats.get_value("defense")
	var final_damage: int = max(0, raw_damage - defense)
	target_health.take_damage(final_damage)
	attacked.emit(raw_damage, final_damage)
	return final_damage
