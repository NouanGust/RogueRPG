extends Node
class_name DiceRoller

var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()

func roll_range(min_value: int, max_value: int) -> int:
	return rng.randi_range(min_value, max_value)

func roll_percentage(chance: float) -> bool:
	return rng.randf_range(0.0, 100.0) <= chance

func roll_stats(class_data: ClassData) -> Dictionary:
	return {
		"max_hp": roll_range(class_data.min_hp, class_data.max_hp),
		"strength": roll_range(class_data.min_strength, class_data.max_strength),
		"intelligence": roll_range(class_data.min_intelligence, class_data.max_intelligence),
		"defense": roll_range(class_data.min_defense, class_data.max_defense),
		"luck": roll_range(class_data.min_luck, class_data.max_luck)
	}
