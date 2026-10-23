extends Node

func _ready() -> void:
	_capture.call_deferred()

func screenshot(filename: String) -> void:
	await get_tree().process_frame
	RenderingServer.force_draw()
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png("res://.test-output/previews/" + filename + ".png")
	print("CAPTURED: " + filename)

func _capture() -> void:
	DirAccess.make_dir_recursive_absolute("res://.test-output/previews")
	SaveManager.save_directory = "res://.test-output/preview_%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(SaveManager.save_directory)
	SaveManager.create_new_profile("Aventureiro")
	SaveManager.add_coins(42)
	GameState.start_new_run()
	GameState.set_selected_class(preload("res://Scripts/resources/Warrior.tres"))
	GameState.set_rolled_attributes({"strength": 8, "intelligence": 4, "faith": 3, "agility": 6})
	var potion := preload("res://Scripts/resources/Items/potion_small.tres")
	GameState.add_item(potion)
	GameState.add_item(preload("res://Scripts/resources/Items/strenght_elixir.tres"))
	for index in range(24):
		SaveManager.add_to_stash(potion)
	var lobby = preload("res://Scenes/3D/lobby_3d.tscn").instantiate()
	get_tree().root.add_child(lobby)
	get_tree().current_scene = lobby
	await get_tree().create_timer(2.8).timeout
	await lobby.move_to_station(lobby.pos_stash, lobby.stash_ui)
	await get_tree().create_timer(0.5).timeout
	await screenshot("stock-1280")
	lobby._snap_camera_to(lobby.pos_main)
	lobby._on_settings_requested()
	await screenshot("settings-1280")
	lobby.player_node.setup(GameState.selected_class, GameState.rolled_attributes)
	lobby.player_node.show()
	lobby._switch_ui(lobby.main_ui)
	await screenshot("camp-1280")
	get_tree().root.size = Vector2i(1600, 900)
	await lobby.move_to_station(lobby.pos_stash, lobby.stash_ui)
	await screenshot("stock-1600")
	get_tree().root.size = Vector2i(1280, 720)
	lobby.queue_free()
	await get_tree().process_frame
	var battle = preload("res://Scenes/3D/battle_scene_3d.tscn").instantiate()
	get_tree().root.add_child(battle)
	get_tree().current_scene = battle
	await get_tree().create_timer(1.8).timeout
	battle._enter_phase(battle.Phase.LEVEL_UP)
	battle.ui.show_level_up({"level": 2, "bonuses": [3, 1, 2, 2], "attributes": {"strength": 11, "intelligence": 5, "faith": 5, "agility": 8}})
	await get_tree().create_timer(0.5).timeout
	await screenshot("level-up-1280")
	battle.ui.level_up_panel.continue_button.pressed.emit()
	await get_tree().create_timer(0.5).timeout
	battle.ui.show_loot_screen(potion)
	await get_tree().create_timer(0.9).timeout
	await screenshot("loot-1280")
	battle.ui.loot_panel.hide()
	battle._setup_peaceful_room()
	battle._enter_phase(battle.Phase.CAMP)
	await screenshot("rest-1280")
	AudioManager.stop_music()
	for player in AudioManager.get_children():
		if player is AudioStreamPlayer:
			player.stop()
			player.stream = null
	await get_tree().create_timer(0.3).timeout
	get_tree().quit()
