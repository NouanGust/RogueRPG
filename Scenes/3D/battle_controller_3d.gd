class_name BattleController3D
extends Node3D

const Progression = preload("res://Scripts/resources/progression_rules.gd")

signal battle_started
signal turn_changed(current_turn: String)
signal battle_finished(player_won: bool)

@onready var player_node: PlayerActor3D = $PlayerActor3D
@onready var player_anchor: Marker3D = $PlayerActor3D/HealthBarAnchor
@onready var enemy_node: EnemyActor3D = $EnemyActor3D
@onready var enemy_anchor: Marker3D = $EnemyActor3D/HealthBarAnchor

@onready var dice_roller: DiceRoller = $DiceRoller
@onready var ui: BattleUI = $UILayer/BattleUI

@export var enemy_pool: Array[EnemyData] = []
@export var elite_enemy_pool: Array[EnemyData] = []
@export var damage_text_scene: PackedScene
@export var loot_pool: Array[ItemData] = []
@export_range(0.0, 1.0) var backpack_drop_chance: float = 0.05

# --- SFX ---
@export_group("SFX")
@export var attack_sfx: AudioStream
@export var hurt_sfx: AudioStream
@export var dice_sfx: AudioStream
@export var item_sfx: AudioStream
@export var heal_sfx: AudioStream

# --- VFX ---
@export_group("VFX")
@export var slash_effect_scene: PackedScene = preload("res://Scenes/3D/VFX/slash_effect_3d.tscn")
@export var projectile_scene: PackedScene = preload("res://Scenes/3D/VFX/projectile_3d.tscn")

var current_level: int = 1
var current_turn: String = "player"
var battle_active: bool = false
var action_in_progress: bool = false
@onready var main_camera: Camera3D = $Camera3D

enum Phase { SPAWNING, PLAYER, ENEMY, RESOLVING, LEVEL_UP, LOOT, CAMP, FINISHED }
var level_up_queue: Array[Dictionary] = []
var phase: Phase = Phase.SPAWNING
var is_peaceful_room: bool = false
var pending_loot: ItemData
var enemy_defeat_pending: bool = false
var last_camp_encounter: int = 0
var next_battle_is_elite: bool = false
var rounds_since_last_elite: int = 3
var buff_just_applied: bool = false
var attack_uses_remaining: Array[int] = []
var _elite_intro_active: bool = false
var _elite_intro_waiting_confirm: bool = false
var _elite_intro_confirmed: bool = false

const ENEMY_TURN_DELAY := 2
const ELITE_MIN_BREATHER_ROUNDS := 3
const ELITE_SPAWN_CHANCE := 0.38

func _ready() -> void:


	ui.set_controller(self)
	ui.attack_pressed.connect(player_attack)
	if ui.has_signal("attack_selected"):
		ui.attack_selected.connect(player_use_attack)
	ui.escape_pressed.connect(player_escape)
	ui.loot_decision_made.connect(_on_loot_decision)

	start_battle()

func _process(_delta: float) -> void:
	if not battle_active or main_camera == null or _elite_intro_active:
		return

	_update_floating_health_bars()

func _input(event: InputEvent) -> void:
	if not _elite_intro_active or not _elite_intro_waiting_confirm:
		return
	var clicked: bool = event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT
	var accepted: bool = event.is_action_pressed("ui_accept")
	if clicked or accepted:
		_elite_intro_confirmed = true
		get_viewport().set_input_as_handled()

func _setup_peaceful_room() -> void:
	battle_active = true
	enemy_node.hide()
	enemy_node.stats_component.active_buff = {"stat": "", "amount": 0, "turns": 0}
	enemy_node.stats_component.aura_changed.emit("none", "")
	ui.set_enemy_bar_visible(false)
	_reset_attack_uses()
	_refresh_status_badges()
	ui.update_expedition_progress(GameState.encounters_won, true, next_battle_is_elite)

	ui.attack_button.disabled = false
	ui.attack_button.text = "AVANÇAR"
	ui.escape_button.text = "RETORNAR (Seguro)"
	ui.camp_back_button.show()

	ui.log_str("[color=green]ACAMPAMENTO SEGURO[/color]")
	if next_battle_is_elite:
		ui.log_str("[color=orange]Prepare-se! Um Inimigo Elite aguarda na próxima batalha.[/color]")
	ui.log_str("Usos de ataque restaurados. Use itens, RETORNE ao lobby sem punições, ou clique em AVANÇAR para continuar.")


func _update_floating_health_bars() -> void:
	if is_instance_valid(player_node) and player_node.visible:
		var player_screen_pos: Vector2 = main_camera.unproject_position(player_anchor.global_position)
		if not main_camera.is_position_behind(player_anchor.global_position):
			ui.set_player_bar_position(player_screen_pos)
			ui.set_player_bar_visible(true)
		else:
			ui.set_player_bar_visible(false)

	if is_instance_valid(enemy_node) and enemy_node.visible:
		var enemy_screen_pos: Vector2 = main_camera.unproject_position(enemy_anchor.global_position)
		if not main_camera.is_position_behind(enemy_anchor.global_position):
			ui.set_enemy_bar_position(enemy_screen_pos)
			ui.set_enemy_bar_visible(true)
		else:
			ui.set_enemy_bar_visible(false)
func start_battle() -> void:
	if not GameState.can_enter_battle():
		SceneTransition.change_scene("res://Scenes/3D/lobby_3d.tscn")
		return
	battle_active = true
	current_level = GameState.current_level
	player_node.setup(GameState.selected_class, GameState.rolled_attributes)
	_reset_attack_uses()
	player_node.health_component.health_changed.connect(_on_player_health_changed)
	enemy_node.health_component.health_changed.connect(_on_enemy_health_changed)
	player_node.health_component.died.connect(_on_player_died)
	enemy_node.health_component.died.connect(_on_enemy_died)
	player_node.stats_component.aura_changed.connect(_on_any_status_changed)
	enemy_node.stats_component.aura_changed.connect(_on_any_status_changed)
	GameState.level_changed.connect(_on_player_level_up)
	_on_player_health_changed(player_node.health_component.current_hp, player_node.health_component.max_hp)
	_refresh_status_badges()
	await _procede_to_next_enemy()
	battle_started.emit()

func _spawn_enemy_for_level(level: int) -> void:
	var is_elite_round := next_battle_is_elite and not elite_enemy_pool.is_empty()
	next_battle_is_elite = false
	var active_pool: Array[EnemyData] = elite_enemy_pool if is_elite_round else enemy_pool
	if active_pool.is_empty():
		battle_active = false
		_enter_phase(Phase.FINISHED)
		ui.log_str("Nenhum inimigo disponível. Retorne ao lobby.")
		battle_finished.emit(true)
		return
	_enter_phase(Phase.SPAWNING)
	ui.update_expedition_progress(GameState.encounters_won, false, is_elite_round)
	enemy_node.show()
	ui.set_enemy_bar_visible(true)
	var enemy_data: EnemyData = active_pool.pick_random()
	var rolled_value := (level - 1) * 2 + (2 if enemy_data.is_elite else 0)
	enemy_node.setup(enemy_data, rolled_value)
	var enemy_scale := 1.14 if enemy_data.is_elite else 1.0
	enemy_node.scale = Vector3.ONE * enemy_scale
	if enemy_data.is_elite:
		ui.set_turn_text("ELITE: %s se aproxima!" % enemy_data.display_name)
		ui.log_str("[color=orange]INIMIGO ELITE: %s entrou na batalha![/color]" % enemy_data.display_name)
	var ground_offset := (enemy_scale - 1.0) * 0.64
	var base_pos := Vector3(0, 0.666 + ground_offset, -2)
	if enemy_data.is_elite:
		await _play_elite_intro(enemy_data, base_pos)
	else:
		enemy_node.global_position = base_pos - Vector3(0, 0, 8)
		enemy_node.face_target(player_node.global_position)
		enemy_node.play_walk()
		var tween := create_tween()
		tween.tween_property(enemy_node, "global_position", base_pos, 1.5)
		await tween.finished
	if phase != Phase.SPAWNING:
		return
	enemy_node.play_idle()
	_enter_phase(Phase.PLAYER)

func _play_elite_intro(enemy_data: EnemyData, base_pos: Vector3) -> void:
	_elite_intro_active = true
	_elite_intro_waiting_confirm = false
	_elite_intro_confirmed = false
	if ui.has_method("begin_elite_intro"):
		ui.begin_elite_intro(enemy_data)

	var orig_transform: Transform3D = main_camera.global_transform
	var orig_fov: float = main_camera.fov
	var accent: Color = enemy_data.elite_theme_color

	# Enquadramento dramático em contra-plongée suave focado no Elite
	var focus_target := base_pos + Vector3(0.0, 0.16, 0.0)
	var intro_cam_pos := base_pos + Vector3(1.38, 0.42, 2.45)
	var intro_cam_transform := Transform3D(Basis.IDENTITY, intro_cam_pos).looking_at(focus_target, Vector3.UP)

	var cam_in := create_tween().set_parallel(true)
	cam_in.tween_property(main_camera, "global_transform", intro_cam_transform, 0.85).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	cam_in.tween_property(main_camera, "fov", 52.0, 0.85).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	enemy_node.face_target(player_node.global_position)
	await get_tree().create_timer(0.32).timeout

	match enemy_data.elite_intro_style:
		"rush":
			# Lobisomem Alfa: corrida veloz + freada brusca + ataque com clarão carmesim
			enemy_node.global_position = base_pos + Vector3(0.0, 0.0, -9.0)
			enemy_node.play_anim("Run")
			var run_tw := create_tween()
			run_tw.tween_property(enemy_node, "global_position", base_pos, 0.85).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			await run_tw.finished
			enemy_node.global_position = base_pos
			enemy_node.pulse_intro_light(accent, 6.5, 2.2)
			AudioManager.play_sfx(attack_sfx, false, 0.62)
			trigger_camera_shake(0.26, 0.35)
			enemy_node.play_attack()
			await _wait_enemy_animation("Attack")
		"mystic":
			# Górgona: avanço imponente + animação Special + pulso esmeralda
			enemy_node.global_position = base_pos + Vector3(0.0, 0.0, -4.5)
			enemy_node.play_walk()
			var walk_tw := create_tween()
			walk_tw.tween_property(enemy_node, "global_position", base_pos, 1.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			await walk_tw.finished
			enemy_node.global_position = base_pos
			enemy_node.pulse_intro_light(accent, 6.0, 2.2)
			AudioManager.play_sfx(item_sfx, false, 0.68)
			enemy_node.play_anim("Special")
			await _wait_enemy_animation("Special")
		"drop":
			# Yamabushi Tengu: pausa de tensão + queda do céu + impacto forte + pose de bastão
			enemy_node.global_position = base_pos + Vector3(0.0, 5.8, -0.5)
			await get_tree().create_timer(0.25).timeout
			enemy_node.play_anim("Jump")
			var drop_tw := create_tween()
			drop_tw.tween_property(enemy_node, "global_position", base_pos, 0.68).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			await drop_tw.finished
			enemy_node.global_position = base_pos
			enemy_node.pulse_intro_light(accent, 6.8, 2.2)
			AudioManager.play_sfx(attack_sfx, false, 0.55)
			trigger_camera_shake(0.34, 0.38)
			enemy_node.play_attack()
			await _wait_enemy_animation("Attack")
		"shadow":
			# Karasu Tengu: surgimento das sombras + dash rápido + corte sombrio no ar
			enemy_node.global_position = base_pos + Vector3(0.0, 0.0, -5.0)
			enemy_node.anim_sprite.modulate.a = 0.0
			enemy_node.play_anim("Run")
			var sh_tw := create_tween().set_parallel(true)
			sh_tw.tween_property(enemy_node.anim_sprite, "modulate:a", 1.0, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			sh_tw.tween_property(enemy_node, "global_position", base_pos, 0.72).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
			await sh_tw.finished
			enemy_node.global_position = base_pos
			enemy_node.anim_sprite.modulate.a = 1.0
			enemy_node.pulse_intro_light(accent, 6.4, 2.2)
			_spawn_slash(_vfx_position_for(enemy_node, 0.16), null, enemy_data.slash_palette, true)
			AudioManager.play_sfx(attack_sfx, false, 0.72)
			trigger_camera_shake(0.22, 0.3)
			enemy_node.play_attack()
			await _wait_enemy_animation("Attack")
		_:
			enemy_node.global_position = base_pos
			enemy_node.pulse_intro_light(accent, 5.5, 2.0)
			await get_tree().create_timer(0.8).timeout

	enemy_node.global_position = base_pos
	enemy_node.anim_sprite.modulate = Color.WHITE
	enemy_node.play_idle()

	# Aguarda interação do jogador para encerrar a cena e iniciar a batalha
	_elite_intro_waiting_confirm = true
	if ui.has_method("show_elite_intro_confirm_prompt"):
		ui.show_elite_intro_confirm_prompt()
	while not _elite_intro_confirmed and is_inside_tree():
		await get_tree().process_frame
	_elite_intro_waiting_confirm = false

	if AudioManager.has_method("play_ui_click"):
		AudioManager.play_ui_click()

	var cam_out := create_tween().set_parallel(true)
	cam_out.tween_property(main_camera, "global_transform", orig_transform, 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	cam_out.tween_property(main_camera, "fov", orig_fov, 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await cam_out.finished
	main_camera.global_transform = orig_transform
	main_camera.fov = orig_fov

	if ui.has_method("end_elite_intro"):
		ui.end_elite_intro()
	_elite_intro_active = false
	_elite_intro_confirmed = false
	_refresh_status_badges()


func _set_turn(new_turn: String) -> void:
	if not battle_active:
		return
	if new_turn == "enemy":
		_enter_phase(Phase.ENEMY)
		await get_tree().create_timer(ENEMY_TURN_DELAY).timeout
		if phase == Phase.ENEMY:
			await enemy_act()
	else:
		_enter_phase(Phase.PLAYER)

func _enter_phase(value: Phase) -> void:
	phase = value
	ui.camp_back_button.visible = phase == Phase.CAMP
	is_peaceful_room = phase == Phase.CAMP
	action_in_progress = phase not in [Phase.PLAYER, Phase.CAMP, Phase.FINISHED]
	current_turn = "player" if phase in [Phase.PLAYER, Phase.CAMP] else "enemy"
	turn_changed.emit(current_turn)
	match phase:
		Phase.SPAWNING: ui.set_turn_text("Um inimigo se aproxima")
		Phase.RESOLVING: ui.set_turn_text("Inimigo derrotado")
		Phase.LOOT: ui.set_turn_text("Escolha o destino da recompensa")
		Phase.LEVEL_UP: ui.set_turn_text("Seu herói evoluiu")
		Phase.CAMP: ui.set_turn_text("Acampamento seguro")

func _reset_attack_uses() -> void:
	attack_uses_remaining.clear()
	var equipped := GameState.get_equipped_attacks()
	if not equipped.is_empty():
		for atk in equipped:
			attack_uses_remaining.append(atk.max_uses if atk != null else 0)
		if ui.has_method("setup_attacks"):
			ui.setup_attacks(equipped, attack_uses_remaining)

func player_attack() -> void:
	if phase == Phase.CAMP:
		ui.log_str("Você deixou o acampamento e continuou a jornada.")
		await _procede_to_next_enemy()
		return
	await player_use_attack(0)

func player_use_attack(attack_index: int) -> void:
	if not battle_active or phase != Phase.PLAYER:
		return

	var class_data: ClassData = player_node.class_data
	var equipped := GameState.get_equipped_attacks()
	var attack_data: AttackData = null
	if attack_index >= 0 and attack_index < equipped.size():
		attack_data = equipped[attack_index]
		if attack_data != null and attack_data.max_uses > 0:
			if attack_index >= attack_uses_remaining.size() or attack_uses_remaining[attack_index] <= 0:
				ui.log_str("Sem usos restantes para %s." % attack_data.display_name)
				return
			attack_uses_remaining[attack_index] -= 1
			if ui.has_method("update_attack_uses"):
				ui.update_attack_uses(attack_uses_remaining)

	_enter_phase(Phase.RESOLVING)

	var style := attack_data.attack_style if attack_data != null else (class_data.attack_style if class_data != null else "melee")
	var original_pos := player_node.global_position
	var attack_name := attack_data.display_name if attack_data != null else "Ataque"

	if style == "self":
		if not player_node.combat_component.roll_hit(attack_data):
			AudioManager.play_sfx(dice_sfx, false, 0.72)
			_spawn_miss_text(player_node)
			ui.log_str("Você tentou usar %s, mas falhou." % attack_name)
			await get_tree().create_timer(0.45).timeout
			await _set_turn("enemy")
			return
		player_node.play_level_up_effect()
		await get_tree().create_timer(0.28).timeout
		var self_res := player_node.combat_component.execute_attack(attack_data, enemy_node.stats_component, enemy_node.health_component, true)
		if self_res.get("type") == "heal":
			AudioManager.play_sfx(heal_sfx)
			var heal_amount: int = int(self_res.get("amount", 0))
			_spawn_heal_number(heal_amount, player_node)
			var msg := "Você usou %s e recuperou %d HP." % [attack_name, heal_amount]
			if self_res.has("buff_stat"):
				buff_just_applied = true
				AudioManager.play_buff_sfx(item_sfx)
				msg += " (+%d %s por %d turnos)" % [int(self_res.get("buff_amount", 0)), str(self_res.get("buff_stat", "")), int(self_res.get("buff_turns", 1))]
			ui.log_heal(msg)
		elif self_res.get("type") == "buff":
			AudioManager.play_buff_sfx(item_sfx)
			buff_just_applied = true
			ui.log_heal("Você usou %s: +%d %s por %d turnos." % [attack_name, int(self_res.get("amount", 0)), str(self_res.get("buff_stat", "")), int(self_res.get("buff_turns", 1))])
		player_node.play_idle()
		await _set_turn("enemy")
		return

	if not player_node.combat_component.roll_hit(attack_data):
		AudioManager.play_sfx(dice_sfx, false, 0.72)
		_spawn_miss_text(enemy_node)
		ui.log_str("Você usou %s, mas errou o alvo." % attack_name)
		await get_tree().create_timer(0.45).timeout
		await _set_turn("enemy")
		return

	var is_ranged := style == "ranged"
	player_node.play_attack()
	if is_ranged:
		await get_tree().create_timer(0.18).timeout
		var proj_source: Resource = attack_data if (attack_data != null and attack_data.projectile_texture != null) else class_data
		await _launch_projectile(
			_vfx_position_for(player_node),
			_vfx_position_for(enemy_node, 0.08),
			proj_source,
			false
		)
	else:
		var lunge_pos := enemy_node.global_position + Vector3(0, 0, 1.35)
		var lunge_tween := create_tween()
		lunge_tween.tween_property(player_node, "global_position", lunge_pos, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		await lunge_tween.finished
		var slash_tex: Texture2D = attack_data.slash_texture if (attack_data != null and attack_data.slash_texture != null) else (class_data.slash_texture if class_data != null else null)
		var slash_pal: int = attack_data.slash_palette if attack_data != null else (class_data.slash_palette if class_data != null else 7)
		_spawn_slash(_vfx_position_for(enemy_node, 0.12), slash_tex, slash_pal, false)

	var attack_buff_color := _get_player_attack_buff_color()
	var result := player_node.combat_component.execute_attack(attack_data, enemy_node.stats_component, enemy_node.health_component, true)
	if result.get("hit", true):
		var res_type: String = str(result.get("type", "damage"))
		if res_type == "debuff":
			AudioManager.play_debuff_sfx(item_sfx)
			ui.log_str("Você usou %s: inimigo recebeu -%d %s por %d turnos." % [attack_name, int(result.get("amount", 0)), str(result.get("debuff_stat", "")), int(result.get("debuff_turns", 1))])
		else:
			var damage: int = int(result.get("amount", 0))
			AudioManager.play_sfx(attack_sfx)
			trigger_hit_pause(0.08)
			_spawn_combat_number(damage, enemy_node, damage >= 5, attack_buff_color)
			if res_type == "damage_debuff":
				AudioManager.play_debuff_sfx(item_sfx)
				ui.log_damage("Você usou %s: %d de dano e -%d %s no inimigo." % [attack_name, damage, int(result.get("debuff_amount", 0)), str(result.get("debuff_stat", ""))])
			elif res_type == "drain":
				var drain_heal: int = int(result.get("heal_amount", 0))
				_spawn_heal_number(drain_heal, player_node)
				ui.log_damage("Você usou %s: %d de dano e recuperou %d HP." % [attack_name, damage, drain_heal])
			else:
				ui.log_damage("Você usou %s e causou %d de dano." % [attack_name, damage])
	else:
		ui.log_str("Você usou %s, mas errou o alvo." % attack_name)

	if not is_ranged:
		var return_tween := create_tween()
		return_tween.tween_property(player_node, "global_position", original_pos, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		await return_tween.finished
	player_node.play_idle()

	if enemy_node.health_component.current_hp <= 0:
		return
	await _set_turn("enemy")

func player_escape() -> void:
	if phase == Phase.FINISHED:
		# Retry a failed write before allowing the player to leave this scene.
		var saved: bool
		if player_node.health_component.current_hp <= 0:
			saved = SaveManager.clear_active_run()
		else:
			saved = SaveManager.save_active_run(GameState.selected_class, GameState.rolled_attributes)
		if not saved:
			ui.log_str(SaveManager.last_error)
			return
		GameState.returning_from_battle = true
		SceneTransition.change_scene("res://Scenes/3D/lobby_3d.tscn")
		return
	if phase == Phase.CAMP:
		_finish_expedition()
		return
	if not battle_active or phase != Phase.PLAYER:
		return
	_enter_phase(Phase.RESOLVING)
	var result := dice_roller.roll(20)
	if result >= 10:
		var lost_coins := int(SaveManager.get_coins() * 0.3)
		SaveManager.profile_data.coins -= lost_coins
		if not GameState.inventory.is_empty():
			var lost_item: ItemData = GameState.inventory.pick_random()
			GameState.inventory.erase(lost_item)
			SaveManager.profile_data.backpack_items = SaveManager._item_paths(GameState.inventory)
			ui.log_damage("Você deixou cair %s na fuga." % lost_item.item_name)
		ui.log_str("Você escapou e perdeu %d moedas." % lost_coins)
		_finish_expedition()
	else:
		ui.log_str("Falha ao fugir. Você perdeu o turno.")
		await _set_turn("enemy")

func _finish_expedition() -> void:
	battle_active = false
	_enter_phase(Phase.FINISHED)
	if not SaveManager.save_active_run(GameState.selected_class, GameState.rolled_attributes):
		ui.log_str(SaveManager.last_error)
	battle_finished.emit(true)

func _pick_enemy_attack(enemy_data: EnemyData) -> AttackData:
	if enemy_data == null or enemy_data.attacks.is_empty():
		return null
	var candidates: Array[AttackData] = []
	var enemy_has_buff: bool = int(enemy_node.stats_component.active_buff.get("turns", 0)) > 0 and int(enemy_node.stats_component.active_buff.get("amount", 0)) > 0
	var player_has_debuff: bool = int(player_node.stats_component.active_buff.get("turns", 0)) > 0 and int(player_node.stats_component.active_buff.get("amount", 0)) < 0
	for atk in enemy_data.attacks:
		if atk == null:
			continue
		if atk.effect_type == "buff" and enemy_has_buff:
			continue
		if atk.effect_type == "debuff" and player_has_debuff:
			continue
		candidates.append(atk)
		# Elites priorizam buffs próprios e debuffs com peso maior para um combate mais tático e difícil
		if enemy_data.is_elite:
			if atk.effect_type == "buff" and not enemy_has_buff:
				candidates.append(atk)
				candidates.append(atk)
			elif atk.effect_type in ["debuff", "damage_debuff"] and not player_has_debuff:
				candidates.append(atk)
				candidates.append(atk)
	if candidates.is_empty():
		return enemy_data.attacks[0]
	return candidates.pick_random()

func enemy_act() -> void:
	if not battle_active or phase != Phase.ENEMY: return
	enemy_node.face_target(player_node.global_position)

	var enemy_data: EnemyData = enemy_node.enemy_data
	var chosen_attack: AttackData = _pick_enemy_attack(enemy_data)
	var style := chosen_attack.attack_style if chosen_attack != null else (enemy_data.attack_style if enemy_data != null else "melee")
	var attack_name := chosen_attack.display_name if chosen_attack != null else "Ataque"
	var enemy_label := enemy_data.display_name if (enemy_data != null and not enemy_data.display_name.is_empty()) else "Inimigo"
	if ui.has_method("show_enemy_action_banner"):
		ui.show_enemy_action_banner(enemy_label, attack_name)
	var original_pos = enemy_node.global_position
	var enemy_buffed_now := false

	if not enemy_node.combat_component.roll_hit(chosen_attack):
		AudioManager.play_sfx(dice_sfx, false, 0.72)
		_spawn_miss_text(player_node)
		ui.log_str("%s usou %s, mas errou!" % [enemy_label, attack_name])
		await get_tree().create_timer(0.55).timeout
	elif style == "self":
		enemy_node.play_attack()
		await get_tree().create_timer(0.35).timeout
		var self_res := enemy_node.combat_component.execute_attack(chosen_attack, player_node.stats_component, player_node.health_component, true)
		enemy_node.play_idle()
		if not self_res.get("hit", true):
			ui.log_str("O inimigo usou %s, mas falhou." % attack_name)
		elif self_res.get("type") == "buff":
			enemy_buffed_now = true
			AudioManager.play_buff_sfx(item_sfx)
			ui.log_str("O inimigo usou %s (+%d %s por %d turnos)." % [attack_name, int(self_res.get("amount", 0)), str(self_res.get("buff_stat", "")), int(self_res.get("buff_turns", 1))])
		elif self_res.get("type") == "debuff":
			buff_just_applied = true
			AudioManager.play_debuff_sfx(item_sfx)
			ui.log_damage("O inimigo usou %s: você sofreu -%d %s por %d turnos." % [attack_name, int(self_res.get("amount", 0)), str(self_res.get("debuff_stat", "")), int(self_res.get("debuff_turns", 1))])
	elif style == "ranged":
		enemy_node.play_attack()
		await get_tree().create_timer(0.35).timeout
		var proj_source: Resource = chosen_attack if (chosen_attack != null and chosen_attack.projectile_texture != null) else enemy_data
		await _launch_projectile(
			_vfx_position_for(enemy_node),
			_vfx_position_for(player_node, 0.08),
			proj_source,
			true
		)
		enemy_node.play_idle()

		var res := enemy_node.combat_component.execute_attack(chosen_attack, player_node.stats_component, player_node.health_component, true)
		if res.get("hit", true):
			var damage: int = int(res.get("amount", 0))
			AudioManager.play_sfx(hurt_sfx)
			if res.get("type") == "damage_debuff":
				buff_just_applied = true
				AudioManager.play_debuff_sfx(item_sfx)
				ui.log_damage("O inimigo usou %s: %d de dano e -%d %s." % [attack_name, damage, int(res.get("debuff_amount", 0)), str(res.get("debuff_stat", ""))])
			elif res.get("type") == "drain":
				var enemy_heal: int = int(res.get("heal_amount", 0))
				_spawn_heal_number(enemy_heal, enemy_node)
				ui.log_damage("O inimigo usou %s: %d de dano e recuperou %d HP." % [attack_name, damage, enemy_heal])
			else:
				ui.log_damage("O inimigo usou %s e causou %d de dano." % [attack_name, damage])
			trigger_camera_shake(clamp(damage * 0.05, 0.1, 0.5), 0.25)
		else:
			ui.log_str("O inimigo usou %s, mas errou." % attack_name)
	else:
		var target_pos = player_node.global_position
		target_pos.y = original_pos.y
		target_pos.z -= 1.5

		# 1. Dash 3D
		enemy_node.play_walk()
		var dash_tween = create_tween()
		dash_tween.tween_property(enemy_node, "global_position", target_pos, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		await dash_tween.finished

		# 2. Ataque + Efeito de Slash
		enemy_node.play_attack()
		await _wait_enemy_animation("Attack")
		var slash_tex: Texture2D = chosen_attack.slash_texture if (chosen_attack != null and chosen_attack.slash_texture != null) else (enemy_data.slash_texture if enemy_data != null else null)
		var slash_pal: int = chosen_attack.slash_palette if chosen_attack != null else (enemy_data.slash_palette if enemy_data != null else 4)
		_spawn_slash(_vfx_position_for(player_node, 0.12), slash_tex, slash_pal, true)
		enemy_node.play_idle()

		var res := enemy_node.combat_component.execute_attack(chosen_attack, player_node.stats_component, player_node.health_component, true)
		if res.get("hit", true):
			var damage: int = int(res.get("amount", 0))
			AudioManager.play_sfx(hurt_sfx)
			if res.get("type") == "damage_debuff":
				buff_just_applied = true
				AudioManager.play_debuff_sfx(item_sfx)
				ui.log_damage("O inimigo usou %s: %d de dano e -%d %s." % [attack_name, damage, int(res.get("debuff_amount", 0)), str(res.get("debuff_stat", ""))])
			elif res.get("type") == "drain":
				var enemy_heal: int = int(res.get("heal_amount", 0))
				_spawn_heal_number(enemy_heal, enemy_node)
				ui.log_damage("O inimigo usou %s: %d de dano e recuperou %d HP." % [attack_name, damage, enemy_heal])
			else:
				ui.log_damage("O inimigo usou %s e causou %d de dano." % [attack_name, damage])
			trigger_camera_shake(clamp(damage * 0.05, 0.1, 0.5), 0.25)
		else:
			ui.log_str("O inimigo usou %s, mas errou." % attack_name)

		# 3. Recuo 3D
		enemy_node.play_walk()
		var return_tween = create_tween()
		return_tween.tween_property(enemy_node, "global_position", original_pos, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		await return_tween.finished

		enemy_node.play_idle()

	if player_node.health_component.current_hp <= 0: return
	if buff_just_applied:
		buff_just_applied = false
	else:
		player_node.stats_component.tick_buffs()
	if not enemy_buffed_now:
		enemy_node.stats_component.tick_buffs()
	_refresh_status_badges()
	_enter_phase(Phase.PLAYER)

func _on_any_status_changed(_aura_type: String, _stat_name: String) -> void:
	_refresh_status_badges()

func _refresh_status_badges() -> void:
	if ui != null and ui.has_method("update_status_badges"):
		ui.update_status_badges(player_node.stats_component.active_buff, enemy_node.stats_component.active_buff)

func _vfx_position_for(actor: Node3D, toward_camera: float = 0.0) -> Vector3:
	var center: Vector3 = actor.get_vfx_center() if actor.has_method("get_vfx_center") else actor.global_position + Vector3(0.0, -0.28, 0.0)
	if toward_camera != 0.0 and main_camera != null:
		var dir := (main_camera.global_position - center).normalized()
		center += dir * toward_camera
	return center

func _spawn_slash(world_pos: Vector3, texture: Texture2D, palette: int, flip_h: bool = false) -> void:
	if slash_effect_scene == null:
		return
	var slash := slash_effect_scene.instantiate()
	if slash == null:
		return
	add_child(slash)
	slash.global_position = world_pos
	slash.play_effect(texture, palette, 24.0, 1.0, flip_h)

func _launch_projectile(start_pos: Vector3, target_pos: Vector3, data: Resource, flip_h: bool = false) -> void:
	if projectile_scene == null:
		return
	var proj := projectile_scene.instantiate()
	if proj == null:
		return
	add_child(proj)
	var config := {
		"texture": data.get("projectile_texture"),
		"frame_size": data.get("projectile_frame_size"),
		"flight_frames": data.get("projectile_flight_frames"),
		"impact_frames": data.get("projectile_impact_frames"),
		"speed": data.get("projectile_speed"),
		"arc_height": data.get("projectile_arc_height"),
		"color": data.get("projectile_color"),
		"flip_h": flip_h,
	}
	proj.launch(start_pos, target_pos, config)
	await proj.impacted


func use_item_from_inventory(item: ItemData) -> void:
	if not battle_active or phase not in [Phase.PLAYER, Phase.CAMP] or item not in GameState.inventory:
		return
	var in_camp := phase == Phase.CAMP
	if item.item_type not in ["potion", "elixir"]:
		ui.log_str("Esse item ainda não pode ser usado. Ele foi mantido na mochila.")
		return
	if item.item_type == "potion" and player_node.health_component.current_hp == player_node.health_component.max_hp:
		ui.log_str("Sua vida já está cheia. A poção foi mantida na mochila.")
		return
	_enter_phase(Phase.RESOLVING)
	match item.item_type:
		"potion":
			var before_hp := player_node.health_component.current_hp
			player_node.health_component.heal(item.effect_value)
			var healed_amount := maxi(1, player_node.health_component.current_hp - before_hp)
			_spawn_heal_number(healed_amount, player_node)
			ui.log_heal("Você consumiu %s e recuperou %d HP." % [item.item_name, healed_amount])
		"elixir":
			var chosen_stat: String = [player_node.stats_component.primary_stat, "agility"].pick_random()
			player_node.stats_component.apply_buff(chosen_stat, item.effect_value, 3)
			buff_just_applied = not in_camp
			ui.log_heal("Elixir: +%d %s por 3 turnos." % [item.effect_value, chosen_stat])
	GameState.remove_item(item)
	if item.item_type == "elixir":
		AudioManager.play_buff_sfx(item_sfx)
	else:
		AudioManager.play_sfx(heal_sfx if item.item_type == "potion" else item_sfx)
	ui.inventory_panel.refresh_items()
	if in_camp:
		_enter_phase(Phase.CAMP)
	else:
		await _set_turn("enemy")


func _on_enemy_died() -> void:
	if not battle_active or phase == Phase.LOOT or enemy_defeat_pending:
		return
	enemy_defeat_pending = true
	enemy_node.stats_component.active_buff = {"stat": "", "amount": 0, "turns": 0}
	enemy_node.stats_component.aura_changed.emit("none", "")
	if buff_just_applied:
		buff_just_applied = false
	else:
		player_node.stats_component.tick_buffs()
	_refresh_status_badges()
	_enter_phase(Phase.RESOLVING)
	enemy_node.play_dead()
	await _wait_enemy_animation("Dead")
	await get_tree().create_timer(0.8).timeout
	var defeated_elite := enemy_node.enemy_data != null and enemy_node.enemy_data.is_elite
	var reward := Progression.encounter_xp(enemy_node.enemy_data.xp_reward)
	GameState.add_xp(reward)
	var coins_dropped := Progression.coin_reward(current_level) + (enemy_node.enemy_data.elite_coin_bonus if defeated_elite else 0)
	SaveManager.profile_data.coins += coins_dropped
	GameState.encounters_won += 1
	if defeated_elite:
		rounds_since_last_elite = 0
	else:
		rounds_since_last_elite += 1
	ui.update_expedition_progress(GameState.encounters_won, false, false)
	if not SaveManager.save_active_run(GameState.selected_class, GameState.rolled_attributes):
		ui.log_str(SaveManager.last_error)
	if defeated_elite:
		ui.log_str("[color=yellow]ELITE DERROTADO! +%d XP | +%d moedas.[/color]" % [reward, coins_dropped])
		var unlocked_list := AchievementManager.record_enemy_defeat(enemy_node.enemy_data)
		for ach in unlocked_list:
			ui.log_str("[color=yellow]CONQUISTA DESBLOQUEADA: %s - %s[/color]" % [ach.title, ach.description])
			if ui.has_method("show_achievement_toast"):
				ui.show_achievement_toast(ach)
	else:
		ui.log_str("Inimigo derrotado! +%d XP | +%d moedas." % [reward, coins_dropped])
	while not level_up_queue.is_empty():
		_enter_phase(Phase.LEVEL_UP)
		var growth: Dictionary = level_up_queue.pop_front()
		player_node.play_level_up_effect()
		await ui.show_level_up(growth)
		var reached_level: int = int(growth.get("level", 0))
		var candidate: AttackData = GameState.get_random_unlearned_attack() if Progression.should_offer_attack_unlock(reached_level) else null
		if candidate != null and ui.has_method("show_learn_attack"):
			var equipped := GameState.get_equipped_attacks()
			if equipped.size() < 4:
				GameState.replace_attack(equipped.size(), candidate)
				attack_uses_remaining.append(candidate.max_uses)
				ui.setup_attacks(GameState.get_equipped_attacks(), attack_uses_remaining)
				ui.log_str("[color=yellow]Novo golpe aprendido: %s![/color]" % candidate.display_name)
				SaveManager.save_active_run(GameState.selected_class, GameState.rolled_attributes)
			else:
				var replace_idx: int = await ui.show_learn_attack(candidate, equipped)
				if replace_idx >= 0 and GameState.replace_attack(replace_idx, candidate):
					if replace_idx < attack_uses_remaining.size():
						attack_uses_remaining[replace_idx] = candidate.max_uses
					ui.setup_attacks(GameState.get_equipped_attacks(), attack_uses_remaining)
					ui.log_str("[color=yellow]Novo golpe aprendido: %s![/color]" % candidate.display_name)
					SaveManager.save_active_run(GameState.selected_class, GameState.rolled_attributes)
		await get_tree().create_timer(0.25).timeout
	if SaveManager.can_upgrade_backpack() and randf() <= backpack_drop_chance:
		if SaveManager.upgrade_backpack(1):
			ui.inventory_panel.refresh_items()
			AudioManager.play_buff_sfx(item_sfx)
			AudioManager.play_ui_choose()
			var new_limit := SaveManager.get_backpack_limit()
			if ui.has_method("show_backpack_drop_toast"):
				ui.show_backpack_drop_toast(new_limit)
			ui.log_heal("Drop raro! Você encontrou +1 espaço de mochila (capacidade: %d)." % new_limit)
	var loot_chance := 0.85 if defeated_elite else 0.4
	if randf() <= loot_chance and not loot_pool.is_empty():
		pending_loot = loot_pool.pick_random()
		_enter_phase(Phase.LOOT)
		ui.show_loot_screen(pending_loot)
	else:
		await _procede_to_next_enemy()

func _wait_enemy_animation(animation_name: String) -> void:
	var frames := enemy_node.anim_sprite.sprite_frames
	if frames == null or not frames.has_animation(animation_name):
		await get_tree().process_frame
		return
	var duration := 0.0
	for index in range(frames.get_frame_count(animation_name)):
		duration += frames.get_frame_duration(animation_name, index) / maxf(0.01, frames.get_animation_speed(animation_name))
	await get_tree().create_timer(maxf(0.01, duration)).timeout

func _on_loot_decision(decision: String, item: ItemData) -> void:
	if phase != Phase.LOOT or item == null or item != pending_loot:
		return
	match decision:
		"backpack":
			if not GameState.add_item(item):
				ui.show_loot_screen(item)
				return
		"stash": SaveManager.add_to_stash(item)
		"sell": SaveManager.add_coins(maxi(1, int(item.cost / 2)))
		_: return
	pending_loot = null
	ui.inventory_panel.refresh_items()
	await _procede_to_next_enemy()

func _procede_to_next_enemy() -> void:
	enemy_defeat_pending = false
	var entering_regular_camp := GameState.encounters_won > last_camp_encounter and GameState.encounters_won % 5 == 0
	var can_trigger_elite := (
		not elite_enemy_pool.is_empty()
		and GameState.encounters_won >= 5
		and rounds_since_last_elite >= ELITE_MIN_BREATHER_ROUNDS
		and not next_battle_is_elite
		and phase != Phase.CAMP
	)
	if can_trigger_elite and randf() <= ELITE_SPAWN_CHANCE:
		next_battle_is_elite = true
		if entering_regular_camp:
			last_camp_encounter = GameState.encounters_won
		_setup_peaceful_room()
		_enter_phase(Phase.CAMP)
		return
	if entering_regular_camp:
		last_camp_encounter = GameState.encounters_won
		_setup_peaceful_room()
		_enter_phase(Phase.CAMP)
		return
	ui.attack_button.text = "ATACAR"
	ui.escape_button.text = "FUGIR"
	current_level = GameState.current_level
	await _spawn_enemy_for_level(current_level)

func _on_player_died() -> void:
	if not battle_active:
		return
	battle_active = false
	_enter_phase(Phase.FINISHED)
	# Persist permadeath before any animation or navigation.
	if not SaveManager.clear_active_run():
		ui.log_str(SaveManager.last_error)
	GameState.complete_run(false)
	GameState.reset_run()
	GameState.load_inventory_from_save()
	ui.log_damage("Você foi derrotado. O personagem, nível e XP foram perdidos.")
	player_node.play_dead()
	await get_tree().create_timer(1.5).timeout
	battle_finished.emit(false)

func _on_player_health_changed(current: int, maximum: int) -> void:
	ui.update_player_health(current, maximum)

func _on_enemy_health_changed(current: int, maximum: int) -> void:
	ui.update_enemy_health(current, maximum)


func _on_player_level_up(new_level: int) -> void:
	var str_roll = dice_roller.roll(4)
	var int_roll = dice_roller.roll(4)
	var fai_roll = dice_roller.roll(4)
	var agi_roll = dice_roller.roll(4)

	player_node.stats_component.apply_level_up(str_roll, int_roll, fai_roll, agi_roll)
	player_node.health_component.increase_max_hp(str_roll)

	if not GameState.rolled_attributes.is_empty():
		GameState.rolled_attributes["strength"] += str_roll
		GameState.rolled_attributes["intelligence"] += int_roll
		GameState.rolled_attributes["faith"] += fai_roll
		GameState.rolled_attributes["agility"] += agi_roll

	level_up_queue.append({
		"level": new_level,
		"bonuses": [str_roll, int_roll, fai_roll, agi_roll],
		"attributes": GameState.rolled_attributes.duplicate(true),
	})

	ui.log_str("[color=yellow]LEVEL UP! Você alcançou o Nível %d![/color]" % new_level)
	ui.log_str("Atributos aumentaram: FOR+%d, INT+%d, FÉ+%d, AGI+%d" % [str_roll, int_roll, fai_roll, agi_roll])



# --- Utils ---

func _get_player_attack_buff_color() -> Color:
	if player_node == null or player_node.stats_component == null:
		return Color(0, 0, 0, 0)
	if player_node.stats_component.get_modifier("attack") <= 0:
		return Color(0, 0, 0, 0)
	var stat_key := str(player_node.stats_component.active_buff.get("stat", "")).to_lower().strip_edges()
	if stat_key == "primary_stat":
		stat_key = player_node.stats_component.primary_stat.to_lower().strip_edges()
	match stat_key:
		"strength": return Color(1.0, 0.68, 0.14, 1.0)
		"intelligence": return Color(0.78, 0.49, 1.0, 1.0)
		"faith": return Color(1.0, 0.95, 0.46, 1.0)
		"agility": return Color(0.22, 0.95, 0.78, 1.0)
		"attack": return Color(1.0, 0.48, 0.10, 1.0)
		_: return Color(0, 0, 0, 0)

func _spawn_combat_number(
	amount: int,
	actor: Node3D,
	is_critical: bool = false,
	custom_color: Color = Color(0, 0, 0, 0),
	prefix: String = ""
) -> void:
	if damage_text_scene == null or actor == null or main_camera == null:
		return
	var text_node = damage_text_scene.instantiate()
	ui.add_child(text_node)
	var spawn_pos := main_camera.unproject_position(actor.global_position) + Vector2(0, -30)
	text_node.start(amount, spawn_pos, is_critical, custom_color, prefix)

func _spawn_heal_number(amount: int, actor: Node3D) -> void:
	if amount <= 0 or damage_text_scene == null or actor == null or main_camera == null:
		return
	var text_node = damage_text_scene.instantiate()
	ui.add_child(text_node)
	var spawn_pos := main_camera.unproject_position(actor.global_position) + Vector2(0, -30)
	text_node.start_heal(amount, spawn_pos)

func _spawn_miss_text(actor: Node3D) -> void:
	if damage_text_scene == null or actor == null or main_camera == null:
		return
	var text_node = damage_text_scene.instantiate()
	ui.add_child(text_node)
	var spawn_pos := main_camera.unproject_position(actor.global_position) + Vector2(0, -34)
	text_node.start_miss(spawn_pos)

func trigger_hit_pause(duration: float = 0.05) -> void:
	Engine.time_scale = 0.0
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0


func trigger_camera_shake(intensity: float, duration: float) -> void:
	if not main_camera: return

	var tween = create_tween()
	var orig_h_offset = main_camera.h_offset
	var orig_v_offset = main_camera.v_offset

	# No 3D, sacudir o h_offset e v_offset da câmera é mais suave que rotacioná-la
	tween.tween_property(main_camera, "h_offset", intensity, duration * 0.2)
	tween.tween_property(main_camera, "v_offset", intensity, duration * 0.2)
	tween.tween_property(main_camera, "h_offset", -intensity, duration * 0.2)
	tween.tween_property(main_camera, "v_offset", -intensity, duration * 0.2)

	# Retorna ao eixo original
	tween.tween_property(main_camera, "h_offset", orig_h_offset, duration * 0.2)
	tween.tween_property(main_camera, "v_offset", orig_v_offset, duration * 0.2)
