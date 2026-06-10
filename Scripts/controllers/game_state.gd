class_name GameStateClass
extends Node

signal run_started
signal run_reset
signal class_selected(class_data: ClassData)
signal attributes_rolled(attributes: Dictionary)
signal level_changed(new_level: int)
signal xp_changed(current_xp: int)
signal enemy_selected(enemy_data: EnemyData)
signal run_finished(victory: bool)

const MAX_LEVEL: int = 3

var selected_class: ClassData
var rolled_attributes: Dictionary = {}
var current_enemy: EnemyData
var current_level: int = 1
var current_xp: int = 0
var run_active: bool = false

func start_new_run() -> void:
	selected_class = null
	rolled_attributes = {}
	current_enemy = null
	current_level = 1
	current_xp = 0
	run_active = true
	run_started.emit()
	

func reset_run() -> void:
	selected_class = null
	rolled_attributes = {}
	current_enemy = null
	current_level = 1
	current_xp = 0
	run_active = false
	run_reset.emit()
	
	

func set_selected_class(value: ClassData) -> void:
	selected_class = value
	class_selected.emit(rolled_attributes)
	

func set_rolled_attributes(value: Dictionary) -> void:
	rolled_attributes = value.duplicate(true)
	attributes_rolled.emit(rolled_attributes)
	

func set_current_enemy(value: EnemyData) -> void:
	current_enemy = value
	enemy_selected.emit(current_enemy)
	
func add_xp(amount: int) -> void:
	current_xp += amount
	xp_changed.emit(current_xp)
	

func advance_level() -> void:
	current_level += 1
	level_changed.emit(current_level)

func complete_run(victory: bool) -> void:
	run_active = false
	run_finished.emit(victory)
	

func has_selected_class() -> bool:
	return selected_class != null
	
func has_rolled_attributes() -> bool:
	return not rolled_attributes.is_empty()

func is_last_level() -> bool:
	return current_level >= MAX_LEVEL

func can_enter_battle() -> bool:
	return run_active and selected_class != null and not rolled_attributes.is_empty()
