extends Node

var failures: int = 0
var checks: int = 0
var level_up_displays: int = 0
var overlap_seen: bool = false
var warrior: ClassData = preload("res://Scripts/resources/Warrior.tres")
var potion: ItemData = preload("res://Scripts/resources/Items/potion_small.tres")

func _ready() -> void:
	_run.call_deferred()

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + message)
	else:
		print("PASS: " + message)

func wait_until(predicate: Callable, message: String, seconds: float = 12.0) -> bool:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000)
	while not predicate.call() and Time.get_ticks_msec() < deadline:
		var scene = get_tree().current_scene
		if scene is BattleController3D and scene.ui.level_up_panel.visible:
			overlap_seen = overlap_seen or scene.ui.loot_panel.visible
			if not scene.ui.level_up_panel.continue_button.disabled:
				level_up_displays += 1
				scene.ui.level_up_panel.continue_button.pressed.emit()
		await get_tree().process_frame
	var success: bool = predicate.call()
	check(success, message)
	return success

func _run() -> void:
	seed(424242)
	# Every run gets an isolated folder; never load or overwrite real player saves.
	SaveManager.save_directory = "res://.test-output/saves_%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(SaveManager.save_directory)
	_test_progression()
	_test_stats()
	_test_profiles()
	await _test_flow()
	# Let the headless audio backend release active MP3 playbacks before shutdown.
	for player in AudioManager.get_children():
		if player is AudioStreamPlayer:
			player.stop()
			player.stream = null
	await get_tree().create_timer(1.0).timeout
	print("RESULT: %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures else 0)

func _test_progression() -> void:
	var rules = preload("res://Scripts/resources/progression_rules.gd")
	check(rules.xp_required(1) == 30 and rules.xp_required(5) == 90 and rules.xp_required(10) == 165, "XP thresholds grow independently of rewards")
	check(rules.encounter_xp(12) == 12, "Enemy XP is not multiplied by player level")
	for level in [1, 5, 10, 50, 100]:
		var minimum := 2 + rules.coin_bonus(level)
		for roll in range(30):
			var reward: int = rules.coin_reward(level)
			if reward < minimum or reward > 7:
				check(false, "Coin reward stays within bounds")
				return
	check(true, "Even high-level enemies award at most seven coins")
	GameState.current_level = 1
	GameState.current_xp = 0
	GameState.add_xp(12)
	GameState.add_xp(12)
	check(GameState.current_level == 1, "Two ordinary encounters no longer guarantee a level")
	GameState.add_xp(90)
	check(GameState.current_level == 3 and GameState.current_xp == 39, "Multi-level XP preserves the correct remainder")
	GameState.reset_run()

func _test_stats() -> void:
	var stats := StatsComponent.new()
	var attributes := {"strength": 6, "intelligence": 2, "faith": 3, "agility": 3}
	stats.setup_from_class(warrior, attributes)
	check(stats.get_value("attack") == 8, "Warrior includes strength in attack")
	stats.apply_buff("strength", 5, 3)
	check(stats.get_value("attack") == 13, "Strength buff changes Warrior damage")
	stats.apply_buff("agility", 1, 3)
	check(stats.get_value("defense") == 3, "Agility buff crosses rounding boundary")
	stats.tick_buffs()
	stats.tick_buffs()
	stats.tick_buffs()
	check(stats.get_value("defense") == 2, "Buff expires")
	stats.apply_level_up(2, 1, 1, 1)
	var reloaded := StatsComponent.new()
	reloaded.setup_from_class(warrior, {"strength": 8, "intelligence": 3, "faith": 4, "agility": 4})
	check(stats.stats == reloaded.stats, "Level-up and reloaded derived stats agree")
	var health := HealthComponent.new()
	var deaths := [0]
	health.died.connect(func(): deaths[0] += 1)
	health.setup(3)
	health.take_damage(3)
	health.take_damage(3)
	health.heal(10)
	check(deaths[0] == 1 and health.current_hp == 0, "Death only emits once and healing cannot resurrect")
	stats.free()
	reloaded.free()
	health.free()

func _test_profiles() -> void:
	check(SaveManager.create_new_profile("Regression"), "Create profile")
	SaveManager.add_coins(100)
	check(not SaveManager.create_new_profile("regression"), "Duplicate names cannot overwrite a profile")
	check(SaveManager.get_coins() == 100, "Duplicate creation preserves coins")
	check(not SaveManager.create_new_profile("../escape"), "Reject profile path traversal")
	GameState.start_new_run()
	GameState.set_selected_class(warrior)
	GameState.set_rolled_attributes({"strength": 6, "intelligence": 2, "faith": 3, "agility": 3})
	GameState.current_level = 3
	GameState.current_xp = 7
	GameState.add_item(potion)
	check(SaveManager.save_active_run(warrior, GameState.rolled_attributes), "Save a living character")
	GameState.rolled_attributes.strength = 99
	check(SaveManager.profile_data.active_attributes.strength == 6, "Save snapshot does not alias live attributes")
	check(SaveManager.load_profile("Regression"), "Reload profile")
	check(GameState.current_level == 3 and GameState.current_xp == 7 and GameState.inventory.size() == 1, "Reload level, XP and backpack")
	var file := FileAccess.open(SaveManager.save_directory.path_join("Invalid.save"), FileAccess.WRITE)
	file.store_var(["not a profile"])
	file.close()
	check(not SaveManager.load_profile("Invalid") and SaveManager.current_profile_name == "Regression", "Invalid save leaves active profile intact")
	file = FileAccess.open(SaveManager.save_directory.path_join("Legacy.save"), FileAccess.WRITE)
	file.store_var({"coins": 12, "backpack": 2, "stash": [potion.resource_path]})
	file.close()
	check(SaveManager.load_profile("Legacy") and SaveManager.get_backpack_limit() == 4 and SaveManager.get_saved_stash().size() == 1, "Migrate earlier save keys")
	check(SaveManager.create_new_profile("Flow"), "Create isolated integration profile")

func _test_flow() -> void:
	var lobby = preload("res://Scenes/3D/lobby_3d.tscn").instantiate()
	get_tree().root.add_child(lobby)
	# Keep this test runner alive while real scene transitions replace the game scene.
	get_tree().current_scene = lobby
	await get_tree().create_timer(2.7).timeout
	check(lobby.title_ui.visible, "Game opens on 3D title menu")
	lobby.title_ui.config_requested.emit()
	check(lobby.settings_ui.visible, "Settings opens from title")
	lobby.settings_ui.back_requested.emit()
	lobby.title_ui.new_game_requested.emit()
	check(lobby.save_ui.visible, "New game requires a profile")
	lobby.save_ui.new_profile_input.text = "UIFlow"
	lobby.save_ui.create_button.pressed.emit()
	await get_tree().create_timer(1.0).timeout
	check(lobby.creation_ui.visible and SaveManager.current_profile_name == "UIFlow", "Create profile opens class selection")
	lobby.creation_ui._on_class_chosen(warrior)
	lobby.creation_ui.confirm_button.pressed.emit()
	await get_tree().create_timer(0.9).timeout
	var roll = lobby.roll_ui
	roll._on_roll_all_button_pressed()
	check(roll.is_rolling and roll.confirm_button.disabled and roll.back_button.disabled, "Roll animation locks conflicting controls")
	if not await wait_until(func(): return not roll.is_rolling, "Roll all attributes completes", 20.0):
		return
	check(roll._all_rolled(), "Every attribute has a value")
	roll.confirm_button.pressed.emit()
	await get_tree().create_timer(1.0).timeout
	check(lobby.main_ui.visible and GameState.can_enter_battle(), "Character reaches lobby ready for combat")
	SaveManager.add_coins(100)
	GameState.add_item(potion)
	lobby.stash_ui.refresh_from_profile()
	lobby.stash_ui._on_backpack_item_clicked(potion)
	check(GameState.inventory.is_empty() and SaveManager.get_saved_stash().size() == 1, "Transfer backpack to stash")
	lobby.stash_ui._on_stash_item_clicked(potion)
	check(GameState.inventory.size() == 1 and SaveManager.get_saved_stash().is_empty(), "Transfer stash to backpack")
	var card := Control.new()
	lobby.stash_ui.add_child(card)
	check(lobby.stash_ui.buy_item(potion, card), "Shop purchase succeeds")
	check(SaveManager.get_coins() == 100 - potion.cost and SaveManager.get_saved_backpack().size() == 2, "Purchase persists coins and item together")
	lobby.battle_button.pressed.emit()
	if not await wait_until(func(): return get_tree().current_scene is BattleController3D, "Enter battle through lobby button"):
		return
	var battle: BattleController3D = get_tree().current_scene
	if not await wait_until(func(): return battle.phase == battle.Phase.PLAYER, "Enemy entrance finishes before actions unlock"):
		return
	battle.loot_pool.clear()
	var item_count := GameState.inventory.size()
	battle.use_item_from_inventory(potion)
	check(GameState.inventory.size() == item_count, "Full-health potion is not consumed")
	# Exercise a real enemy turn following a consumable, with deterministic damage.
	battle.player_node.health_component.take_damage(2)
	battle.enemy_node.stats_component.stats.attack = 1
	await battle.use_item_from_inventory(potion)
	check(battle.phase == battle.Phase.PLAYER and GameState.inventory.size() == item_count - 1, "Potion consumes one item and enemy turn returns control")
	check(battle.player_node.health_component.current_hp == battle.player_node.health_component.max_hp - 1, "Enemy attack deals damage after item use")
	var unused_dice := preload("res://Scripts/resources/Items/dice_6.tres")
	GameState.add_item(unused_dice)
	battle.use_item_from_inventory(unused_dice)
	check(unused_dice in GameState.inventory and battle.phase == battle.Phase.PLAYER, "Unimplemented item cannot consume itself or a turn")
	var initial_coins := SaveManager.get_coins()
	# Hit the actual attack action repeatedly while the same enemy is dying.
	battle.enemy_node.health_component.current_hp = 1
	battle.player_attack()
	battle.player_attack()
	battle.player_attack()
	if not await wait_until(func(): return battle.phase == battle.Phase.PLAYER, "First reward resolves and next enemy arrives"):
		return
	check(GameState.encounters_won == 1 and SaveManager.get_coins() > initial_coins, "Rapid attacks produce one victory and reward")
	for encounter in range(2, 6):
		battle.enemy_node.health_component.current_hp = 1
		battle.player_attack()
		var expected_phase := battle.Phase.CAMP if encounter == 5 else battle.Phase.PLAYER
		if not await wait_until(func(): return battle.phase == expected_phase, "Encounter %d completes" % encounter):
			return
	check(GameState.current_level > 1, "Combat grants XP and levels")
	check(level_up_displays > 0 and not overlap_seen, "Level-up waits for confirmation without overlapping loot")
	check(battle.ui.camp_back_button.visible, "Camp exposes a dedicated return button")
	check(not battle.enemy_node.visible, "Fifth victory opens safe camp")
	battle.player_attack()
	if not await wait_until(func(): return battle.phase == battle.Phase.PLAYER, "Advance leaves camp for sixth encounter"):
		return
	check(battle.enemy_node.visible, "Enemy becomes visible again after camp")
	# Resolve a pending drop twice, as with rapid double clicks on the loot panel.
	battle.pending_loot = potion
	battle._enter_phase(battle.Phase.LOOT)
	var coins_before_loot := SaveManager.get_coins()
	battle._on_loot_decision("sell", potion)
	battle._on_loot_decision("sell", potion)
	if not await wait_until(func(): return battle.phase == battle.Phase.PLAYER, "Loot choice advances once"):
		return
	check(SaveManager.get_coins() == coins_before_loot + maxi(1, int(potion.cost / 2)), "Duplicate loot choice cannot pay twice")
	# Safe return, save, reload and re-enter with the same living character.
	battle._setup_peaceful_room()
	battle._enter_phase(battle.Phase.CAMP)
	battle.player_escape()
	check(battle.phase == battle.Phase.FINISHED, "Safe return ends expedition")
	var saved_level := GameState.current_level
	var saved_xp := GameState.current_xp
	battle.player_escape()
	if not await wait_until(func(): return get_tree().current_scene is LobbyController3D, "Return to 3D lobby"):
		return
	lobby = get_tree().current_scene
	check(GameState.current_level == saved_level and GameState.current_xp == saved_xp, "Safe return preserves level and XP")
	check(SaveManager.load_profile("UIFlow"), "Reload rewarded character")
	check(GameState.current_level == saved_level and GameState.current_xp == saved_xp, "Saved rewards survive reload")
	await get_tree().create_timer(0.8).timeout
	lobby.battle_button.pressed.emit()
	if not await wait_until(func(): return get_tree().current_scene is BattleController3D, "Re-enter expedition"):
		return
	battle = get_tree().current_scene
	if not await wait_until(func(): return battle.phase == battle.Phase.PLAYER, "Re-entered battle is ready"):
		return
	var coins_before_death := SaveManager.get_coins()
	SaveManager.profile_data.backpack_level = 3
	battle.player_node.health_component.take_damage(99999)
	check(SaveManager.profile_data.active_class_path == "", "Death clears save before animation completes")
	check(GameState.current_level == 1 and GameState.current_xp == 0 and GameState.selected_class == null, "Death resets character level and XP")
	check(SaveManager.load_profile("UIFlow") and GameState.selected_class == null, "Reload after death cannot resurrect character")
	check(SaveManager.get_coins() == coins_before_death and SaveManager.get_backpack_limit() == 5, "Death preserves coins and permanent backpack upgrade")
	await get_tree().create_timer(1.7).timeout
	battle.player_escape()
	if not await wait_until(func(): return get_tree().current_scene is LobbyController3D, "Death returns to character creation"):
		return
	lobby = get_tree().current_scene
	check(lobby.creation_ui.visible and GameState.current_level == 1, "Next character starts at level one")
	check(lobby.player_node.sprite.material_overlay.get_shader_parameter("dissolve_amount") == 0.0, "New player instance does not inherit death dissolve")
	await get_tree().create_timer(0.8).timeout
	get_tree().current_scene = null
	lobby.queue_free()
	await get_tree().process_frame
