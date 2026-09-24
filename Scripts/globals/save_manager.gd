extends Node

const SAVE_DIR = "user://saves/"
var current_profile_name: String = ""
var profile_data: Dictionary = {
	"coins": 0,
	"backpack_level": 1,
	"backpack_items": [],
	"stash_items": [],
	"active_class_path": "",
	"active_attributes": {}
}

func _ready() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)


func get_all_profiles() -> Array[String]:
	var profiles: Array[String] = []
	if DirAccess.dir_exists_absolute(SAVE_DIR):
		var files = DirAccess.get_files_at(SAVE_DIR)
		for file in files:
			if file.ends_with(".save"):
				profiles.append(file.replace(".save", ""))
			
	return profiles

func create_new_profile(profile_name: String) -> void:
	current_profile_name = profile_name
	profile_data = {
		"coins": 0,
		"backpack_level": 1,
		"stash": [],
	}
	save_game()
	

func load_profile(profile_name: String) -> bool:
	var path = SAVE_DIR + profile_name + ".save"
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		if file:
			var data = file.get_var()
			if typeof(data) == TYPE_DICTIONARY:
				profile_data = {"coins": 0, "backpack": 1, "stash": [], "active_class_path": "", "active_attributes": {}}
				profile_data.merge(data, true)
				current_profile_name = profile_name
				_sync_to_game_state()
			file.close()
			return true
	return false

func _sync_to_game_state() -> void:
	if profile_data.get("active_class_path", "") != "":
		GameState.selected_class = load(profile_data["active_class_path"])
		GameState.rolled_attributes = profile_data.get("active_attributes", {})
	else:
		GameState.selected_class = null
		GameState.rolled_attributes = {}

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

func save_active_run(class_resource: ClassData, attributes: Dictionary) -> void:
	if class_resource:
		profile_data["active_class_path"] = class_resource.resource_path
		profile_data["active_attributes"] = attributes
		save_game()

func clear_active_run() -> void:
	profile_data["active_class_path"] = ""
	profile_data["active_attributes"] = {}
	save_game()

func save_backpack(inventory: Array[ItemData]) -> void:
	var paths = []
	for item in inventory:
		paths.append(item.resource_path)
	profile_data["backpack_items"] = paths
	save_game()

func add_to_stash(item: ItemData) -> void:
	var stash = profile_data.get("stash_items", [])
	stash.append(item.resource_path)
	profile_data["stash_items"] = stash
	save_game()

func save_stash(stash: Array[ItemData]) -> void:
	var paths = []
	for item in stash:
		paths.append(item.resource_path)
	profile_data["stash_items"] = paths
	save_game()

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

func get_saved_backpack() -> Array[ItemData]:
	var loaded_items: Array[ItemData] = []
	var paths = profile_data.get("backpack_items", [])
	for path in paths:
		if ResourceLoader.exists(path):
			loaded_items.append(ResourceLoader.load(path) as ItemData)
	return loaded_items

func get_saved_stash() -> Array[ItemData]:
	var loaded_items: Array[ItemData] = []
	var paths = profile_data.get("stash_items", [])
	for path in paths:
		if ResourceLoader.exists(path):
			loaded_items.append(ResourceLoader.load(path) as ItemData)
	return loaded_items
