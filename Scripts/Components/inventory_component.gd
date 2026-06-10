class_name InventoryComponent
extends Node

signal item_used(item_id: StringName)

var potions: int = 2
var elixirs: int = 1

func use_potions(target_health: HealthComponent) -> bool:
	if potions <= 0:
		return false
	potions -= 1
	target_health.heal(5)
	item_used.emit(&"potion")
	return true
	

func use_elixir() -> bool:
	if elixirs <= 0:
		return false
	elixirs -= 1
	item_used.emit(&"elixir")
	return true
	

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
