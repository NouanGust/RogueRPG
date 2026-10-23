extends Node

const SAVE_DIR = "user://saves/"
const SAVE_VERSION = 1
var save_directory: String = SAVE_DIR
var current_profile_name: String = ""
var last_error: String = ""
var profile_data: Dictionary = _default_profile()

func _default_profile() -> Dictionary:
	return {
		"version": SAVE_VERSION, "coins": 0, "backpack_level": 1,
		"backpack_items": [], "stash_items": [], "active_class_path": "",
		"active_attributes": {}, "active_level": 1, "active_xp": 0,
	}

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(save_directory)

func _fail(message: String) -> bool:
	last_error = message
	return false

func _valid_profile_name(value: String) -> bool:
	if value.is_empty() or value.length() > 40 or value != value.strip_edges():
		return false
	if not value.is_valid_filename() or value.ends_with(".") or value.begins_with("."):
		return false
	var stem := value.get_slice(".", 0).to_upper()
	if stem in ["CON", "PRN", "AUX", "NUL"]:
		return false
	for index in range(1, 10):
		if stem == "COM%d" % index or stem == "LPT%d" % index:
			return false
	return true

func _profile_path(profile_name: String) -> String:
	return save_directory.path_join(profile_name + ".save")

func get_all_profiles() -> Array[String]:
	var profiles: Array[String] = []
	for file in DirAccess.get_files_at(save_directory):
		if file.ends_with(".save"):
			profiles.append(file.trim_suffix(".save"))
	profiles.sort()
	return profiles

func create_new_profile(profile_name: String) -> bool:
	last_error = ""
	if not _valid_profile_name(profile_name):
		return _fail("Use um nome válido, com até 40 caracteres, sem barras ou pontos nas extremidades.")
	for existing in get_all_profiles():
		if existing.nocasecmp_to(profile_name) == 0:
			return _fail("Já existe um perfil com esse nome. Escolha outro ou carregue o existente.")
	var previous_name := current_profile_name
	var previous_data := profile_data
	current_profile_name = profile_name
	profile_data = _default_profile()
	if not save_game():
		current_profile_name = previous_name
		profile_data = previous_data
		return false
	_sync_to_game_state()
	return true

func load_profile(profile_name: String) -> bool:
	last_error = ""
	if not _valid_profile_name(profile_name):
		return _fail("Nome de perfil inválido.")
	var file := FileAccess.open(_profile_path(profile_name), FileAccess.READ)
	if file == null:
		return _fail("Não foi possível abrir esse perfil.")
	var data: Variant = file.get_var(false)
	file.close()
	if not data is Dictionary:
		return _fail("O arquivo de perfil está inválido.")
	var candidate := _default_profile()
	candidate.merge(data, true)
	# Compatibility with the earlier keys, without discarding saved items.
	if not data.has("backpack_level"):
		candidate.backpack_level = data.get("backpack", 1)
	if not data.has("stash_items"):
		candidate.stash_items = data.get("stash", [])
	if not _valid_profile_data(candidate):
		return _fail("O perfil contém dados incompatíveis. O arquivo foi preservado.")
	candidate.version = SAVE_VERSION
	profile_data = candidate
	current_profile_name = profile_name
	_sync_to_game_state()
	return true

func _valid_profile_data(data: Dictionary) -> bool:
	for key in ["version", "coins", "backpack_level", "active_level", "active_xp"]:
		if not data[key] is int or data[key] < 0:
			return false
	if data.version > SAVE_VERSION or data.backpack_level < 1 or data.active_level < 1:
		return false
	for key in ["backpack_items", "stash_items"]:
		if not data[key] is Array:
			return false
		for path in data[key]:
			if not path is String or not path.begins_with("res://Scripts/resources/Items/"):
				return false
	if not data.active_class_path is String or not data.active_attributes is Dictionary:
		return false
	if not data.active_class_path.is_empty():
		if not data.active_class_path.begins_with("res://Scripts/resources/"):
			return false
		if not ResourceLoader.exists(data.active_class_path) or not load(data.active_class_path) is ClassData:
			return false
		for key in ["strength", "intelligence", "faith", "agility"]:
			if not data.active_attributes.get(key) is int or data.active_attributes[key] < 1:
				return false
	return true

func _sync_to_game_state() -> void:
	GameState.reset_run()
	if profile_data.active_class_path != "":
		GameState.selected_class = load(profile_data.active_class_path) as ClassData
		GameState.rolled_attributes = profile_data.active_attributes.duplicate(true)
		GameState.current_level = profile_data.active_level
		GameState.current_xp = profile_data.active_xp
		GameState.run_active = true
	GameState.load_inventory_from_save()

func save_game() -> bool:
	if not _valid_profile_name(current_profile_name):
		return _fail("Selecione ou crie um perfil antes de jogar.")
	if DirAccess.make_dir_recursive_absolute(save_directory) != OK:
		return _fail("Não foi possível acessar a pasta de salvamento.")
	var path := _profile_path(current_profile_name)
	var temporary_path := path + ".tmp"
	var file := FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		return _fail("Não foi possível gravar o progresso.")
	file.store_var(profile_data)
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK or DirAccess.rename_absolute(temporary_path, path) != OK:
		return _fail("Não foi possível concluir o salvamento. O perfil anterior foi preservado.")
	last_error = ""
	return true

func save_active_run(class_resource: ClassData, attributes: Dictionary) -> bool:
	if class_resource == null:
		return false
	profile_data.active_class_path = class_resource.resource_path
	profile_data.active_attributes = attributes.duplicate(true)
	profile_data.active_level = GameState.current_level
	profile_data.active_xp = GameState.current_xp
	return save_game()

func clear_active_run() -> bool:
	profile_data.active_class_path = ""
	profile_data.active_attributes = {}
	profile_data.active_level = 1
	profile_data.active_xp = 0
	return save_game()

func delete_profile(profile_name: String) -> bool:
	if not _valid_profile_name(profile_name):
		return _fail("Nome de perfil inválido.")
	if DirAccess.remove_absolute(_profile_path(profile_name)) != OK:
		return _fail("Não foi possível excluir o perfil.")
	if profile_name == current_profile_name:
		current_profile_name = ""
		profile_data = _default_profile()
		GameState.reset_run()
	return true

func _item_paths(items: Array[ItemData]) -> Array[String]:
	var paths: Array[String] = []
	for item in items:
		if item != null:
			paths.append(item.resource_path)
	return paths

func save_backpack(inventory: Array[ItemData]) -> void:
	profile_data.backpack_items = _item_paths(inventory)
	save_game()

func add_to_stash(item: ItemData) -> void:
	profile_data.stash_items.append(item.resource_path)
	save_game()

func save_stash(stash: Array[ItemData]) -> void:
	profile_data.stash_items = _item_paths(stash)
	save_game()

func save_inventory(backpack: Array[ItemData], stash: Array[ItemData]) -> bool:
	profile_data.backpack_items = _item_paths(backpack)
	profile_data.stash_items = _item_paths(stash)
	return save_game()

func get_coins() -> int:
	return profile_data.coins

func add_coins(amount: int) -> void:
	profile_data.coins += maxi(0, amount)
	save_game()

func spend_coins(amount: int) -> bool:
	if amount < 0 or get_coins() < amount:
		return false
	profile_data.coins -= amount
	if not save_game():
		profile_data.coins += amount
		return false
	return true

func get_backpack_limit() -> int:
	return 2 + profile_data.backpack_level

func _load_items(paths: Array) -> Array[ItemData]:
	var items: Array[ItemData] = []
	for path in paths:
		if ResourceLoader.exists(path):
			var item := load(path) as ItemData
			if item != null:
				items.append(item)
	return items

func get_saved_backpack() -> Array[ItemData]:
	return _load_items(profile_data.backpack_items)

func get_saved_stash() -> Array[ItemData]:
	return _load_items(profile_data.stash_items)
