extends Node

const SAVE_DIR = "user://saves/"
var current_profile_name: String = ""
var profile_data: Dictionary = {
	"coins": 0,
	"backpack_level": 1,
	"stach": []
}

func _ready() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_absolute(SAVE_DIR)


func get_all_profiles() -> Array[String]:
	var profiles: Array[String] = []
	var dir = DirAccess.open(SAVE_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".save"):
				profiles.append(file_name.replace(".save", ""))
			file_name = dir.get_next()
			
	return profiles

func create_new_profile(profile_name: String) -> void:
	current_profile_name = profile_name
	profile_data = {
		"coins": 0,
		"backpack_level": 1,
		"stash": []
	}
	save_game()
	

func load_profile(profile_name: String) -> bool:
	var path = SAVE_DIR + profile_name + ".save"
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		if file:
			var data = file.get_var()
			if typeof(data) == TYPE_DICTIONARY:
				profile_data = {"coins": 0, "backpack": 1, "stash": []}
				profile_data.merge(data, true)
				current_profile_name = profile_name
			file.close()
			return true
	return false
func save_game() -> void:
	if current_profile_name == "":
		push_error("SaveManager: Tentando salvar sem um perfil ativo.")
		return
	var path = SAVE_DIR + current_profile_name + ".save"
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_var(profile_data)
		file.close()
	else:
		push_error("SaveManager: Falha ao abrir o arquivo.")

# Gets Globais

func get_coins() -> int:
	return profile_data.get("coins", 0)
	
func add_coins(amount: int) -> void:
	profile_data["coins"] = get_coins() + amount
	save_game()

func spend_coins(amount: int) -> bool:
	var current = get_coins()
	if current >= amount:
		profile_data["coins"] = current - amount
		save_game()
		return true
	return false

func get_backpack_limit() -> int:
	return 2 + profile_data.get("backpack_level", 1)
	
func add_to_stash(item_id: String) -> void:
	var stash: Array = profile_data.get("stash", [])
	stash.append(item_id)
	save_game()
