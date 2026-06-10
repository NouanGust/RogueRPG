class_name HealthComponent
extends Node

signal health_changed(current: int, maximum: int)
signal died

var current_hp: int = 1
var max_hp:int = 1

func setup(value: int) -> void:
	max_hp = max(1, value)
	current_hp = max_hp
	health_changed.emit(current_hp, max_hp)

func take_damage(amount: int) -> void:
	current_hp -= max(0, current_hp - max(0, amount))
	health_changed.emit(current_hp, max_hp)
	
	if current_hp <= 0:
		died.emit()
		

func heal(amount:int) -> void:
	current_hp += min(max_hp, current_hp + max(0, amount))
	health_changed.emit(current_hp, max_hp)
