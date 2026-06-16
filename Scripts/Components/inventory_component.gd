class_name InventoryComponent
extends Node

signal item_used(item_id: StringName, message: String)

var potions: int = 2
var elixirs: int = 1

func use_potions(target_health: HealthComponent) -> bool:
	if potions <= 0:
		return false
	potions -= 1
	target_health.heal(5)
	item_used.emit(&"potion", "Você usou uma Poção e recuperou 5 de HP.")
	return true
	

func use_elixir(target_status: StatsComponent) -> bool:
	if elixirs <= 0:
		return false
	elixirs -= 1
	
	var possible_stats = ["strength", "defence", "attack", "faith", "intelligence"]
	var chosen_stat: String = possible_stats.pick_random()
	
	var turns: int = randi_range(1, 3)
	var buff_amount: int = randi_range(1, 4)
	
	target_status.apply_buff(chosen_stat, buff_amount, turns)
	item_used.emit(&"elixir", "Você tomou um Elixir misterioso")
	return true
	
