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

#const MAX_LEVEL: int = 3
#const MAX_INVENTORY_SLOTS: int = 5
var inventory: Array[ItemData] = []

var selected_class: ClassData
var rolled_attributes: Dictionary = {}
var current_enemy: EnemyData
var current_level: int = 1
var current_xp: int = 0
var run_active: bool = false

var returning_from_battle: bool = false

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
	_check_level_up()

func _check_level_up() -> void:
	var xp_required = current_level * 20
	
	if current_xp >= xp_required:
		current_xp -= xp_required
		advance_level()
		_check_level_up()

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

#func is_last_level() -> bool:
	#return current_level >= MAX_LEVEL

func can_enter_battle() -> bool:
	return run_active and selected_class != null and not rolled_attributes.is_empty()
	


#===================
# Inventário
#===================

func get_max_inventory_slots() -> int:
	return SaveManager.get_backpack_limit()

func has_inventory_space() -> bool:
	return inventory.size() < get_max_inventory_slots()


func add_item(item: ItemData) -> bool:
	if has_inventory_space():
		inventory.append(item)
		sync_inventory_to_save()
		return true
	return false

func remove_item(item: ItemData) -> void:
	var index = inventory.find(item)
	if index != -1:
		inventory.remove_at(index)
		sync_inventory_to_save()

func sync_inventory_to_save() -> void:
	SaveManager.save_backpack(inventory)

func load_inventory_from_save() -> void:
	inventory = SaveManager.get_saved_backpack()
