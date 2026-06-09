extends Node
class_name DiceRoller

var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	

func roll_range(min_value:int, max_value) -> int:
	return rng.randi_range(min_value, max_value)
	
func roll_percentage(chance: float) -> bool:
	return rng.randf_range(0.0, 100.0)

func roll_stats(class_data: ClassData) -> Dictionary:
	return{
		"max_vida": roll_range(class_data.min_vida, class_data.max_vida),
		"forca": roll_range(class_data.max_forca, class_data.min_forca),
		"inteligencia": roll_range(class_data.max_int, class_data.min_int),
		"defesa": roll_range(class_data.max_defesa, class_data.min_defesa),
		"sorte": roll_range(class_data.max_sorte, class_data.min_sorte),
	}
