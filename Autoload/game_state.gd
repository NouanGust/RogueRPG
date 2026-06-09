extends Node

var current_class: ClassData
var current_stats: Dictionary = {}
var current_floor: int = 1
var current_gold: int = 0

func create_new_run(class_data: ClassData, rolled_stats: Dictionary) -> void:
	current_class = class_data
	current_stats = rolled_stats.duplicate(true)
	current_floor = 1
	current_gold = 0

func advance_floor() -> void:
	current_floor += 1

func reset_run() -> void:
	current_class = null
	current_stats.clear()
	current_floor = 1
	current_gold = 0
