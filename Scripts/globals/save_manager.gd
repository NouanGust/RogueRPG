extends Node

const SAVE_PATH = "user://meta_progression.save"
var save_data: Dictionary = {
	"coins": 0
}

func _ready() -> void:
	load_game()


func save_game() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()
	else:
		push_error("SaveManager: Falha ao abrir o arquivo para salvar.")

func load_game() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var data  = file.get_var()
			if typeof(data) == TYPE_DICTIONARY:
				save_data.merge(data, true)
			file.close()
			

func get_coins() -> int:
	return save_data.get("coins", 0)
	
func add_coins(amount: int) -> void:
	save_data["coins"] = get_coins() + amount
	save_game()

func spend_coins(amount: int) -> bool:
	var current = get_coins()
	if current >= amount:
		save_data["coins"] = current - amount
		save_game()
		return true
	return false
