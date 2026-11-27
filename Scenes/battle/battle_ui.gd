class_name BattleUI
extends Control

signal attack_pressed
signal attack_selected(attack_index: int)
signal escape_pressed
signal loot_decision_made(decision: String, item: ItemData)
signal _learn_attack_decided(slot_index: int)

const STYLE_CONFIRM: StyleBox = preload("res://Assets/Themes/confirm_button.tres")
const STYLE_CONFIRM_HOVER: StyleBox = preload("res://Assets/Themes/confirm_button_hover.tres")
const STYLE_CONFIRM_DISABLED: StyleBox = preload("res://Assets/Themes/confirm_button_disable.tres")
const STYLE_CHOSE: StyleBox = preload("res://Assets/Themes/chose_button.tres")
const STYLE_CHOSE_HOVER: StyleBox = preload("res://Assets/Themes/chose_button_hover.tres")
const STYLE_QUIT: StyleBox = preload("res://Assets/Themes/quit_button.tres")
const STYLE_QUIT_HOVER: StyleBox = preload("res://Assets/Themes/quit_button_hover.tres")

@onready var title_label: Label = $MarginContainer/VBoxContainer/PanelContainer/TopHeader/TitleLabel
@onready var expedition_dots: HBoxContainer = $MarginContainer/VBoxContainer/PanelContainer/TopHeader/ExpeditionRow/ExpeditionDots
@onready var expedition_label: Label = $MarginContainer/VBoxContainer/PanelContainer/TopHeader/ExpeditionRow/ExpeditionLabel
@onready var log_container: PanelContainer = $MarginContainer/VBoxContainer/LogPanel
@onready var log_label: RichTextLabel = $MarginContainer/VBoxContainer/LogPanel/LogPanel
@onready var player_status_panel: VBoxContainer = $PlayerStatusPanel
@onready var enemy_status_panel: VBoxContainer = $EnemyStatusPanel
@onready var history_button: Button = $MarginContainer/VBoxContainer/Actions/HBoxContainer/StatusSection/HistoryButton

@onready var player_hp_label: Label = $MarginContainer/VBoxContainer/Actions/HBoxContainer/PanelContainer/ProgressBar/PlayerHPLAbel
@onready var enemy_hp_label: Label = $MarginContainer/VBoxContainer/EnemyPanel/EnemyHPBar/HPLabel

@onready var actions_row: HBoxContainer = $MarginContainer/VBoxContainer/Actions/HBoxContainer/ActionsRow
@onready var attack_button: Button = $MarginContainer/VBoxContainer/Actions/HBoxContainer/ActionsRow/AttackButton
@onready var item_button: Button = $MarginContainer/VBoxContainer/Actions/HBoxContainer/ActionsRow/ItemButton
@onready var escape_button: Button = $MarginContainer/VBoxContainer/Actions/HBoxContainer/ActionsRow/EscapeButton

@onready var player_hp_bar: ProgressBar = $MarginContainer/VBoxContainer/Actions/HBoxContainer/PanelContainer/ProgressBar
@onready var enemy_hp_bar: ProgressBar = $MarginContainer/VBoxContainer/EnemyPanel/EnemyHPBar

@onready var inventory_panel: InventoryPanel = $InventoryPanel
@onready var loot_panel: PanelContainer = $LootPanel
@onready var loot_label: Label = $LootPanel/MarginContainer/VBoxContainer/Label
@onready var backpack_button: Button = $LootPanel/MarginContainer/VBoxContainer/BagButton
@onready var stash_button: Button = $LootPanel/MarginContainer/VBoxContainer/StashButton
@onready var sell_button: Button = $LootPanel/MarginContainer/VBoxContainer/SellButton
@onready var item_sprite: TextureRect = $LootPanel/MarginContainer/VBoxContainer/ItemSprite
@onready var level_up_panel: Control = $LevelUpPanel

var controller
var current_loot: ItemData
var camp_back_button: Button
var progress_label: Label
var moves_container: HBoxContainer
var moves_grid: GridContainer
var move_buttons: Array[Button] = []
var current_attacks: Array[AttackData] = []
var _elite_intro_overlay: Control = null

func _ready() -> void:
	camp_back_button = Button.new()
	camp_back_button.text = "Voltar ao acampamento"
	camp_back_button.position = Vector2(24, 76)
	camp_back_button.custom_minimum_size = Vector2(210, 40)
	camp_back_button.theme = preload("res://Scenes/ui/adventure_theme.tres")
	camp_back_button.add_theme_stylebox_override("normal", STYLE_QUIT)
	camp_back_button.add_theme_stylebox_override("hover", STYLE_QUIT_HOVER)
	camp_back_button.add_theme_stylebox_override("pressed", STYLE_QUIT_HOVER)
	add_child(camp_back_button)
	camp_back_button.hide()
	camp_back_button.pressed.connect(func():
		if controller.phase == controller.Phase.CAMP:
			controller._finish_expedition()
			controller.player_escape())
	progress_label = Label.new()
	progress_label.position = Vector2(24, 22)
	progress_label.theme = preload("res://Scenes/ui/adventure_theme.tres")
	add_child(progress_label)
	GameState.xp_changed.connect(func(_xp: int): _update_progress())
	_update_progress()
	_build_moves_menu()
	attack_button.pressed.connect(_on_attack_button_pressed)
	item_button.pressed.connect(_on_item_button_pressed)
	escape_button.pressed.connect(func(): escape_pressed.emit())
	if history_button:
		history_button.pressed.connect(_on_history_button_pressed)
	KeyboardNav.attach_key_hint(attack_button, "A")
	KeyboardNav.attach_key_hint(item_button, "I")
	KeyboardNav.attach_key_hint(escape_button, "F")
	if history_button:
		KeyboardNav.attach_key_hint(history_button, "H")
	if log_container:
		log_container.hide()
	log_label.text = ""
	update_status_badges({}, {})
	update_expedition_progress(GameState.encounters_won, false)
	
	inventory_panel.item_selected.connect(_on_inventory_item_selected)
	loot_panel.hide()
	backpack_button.pressed.connect(func(): _on_loot_chosen("backpack"))
	stash_button.pressed.connect(func(): _on_loot_chosen("stash"))
	sell_button.pressed.connect(func(): _on_loot_chosen("sell"))

func _build_moves_menu() -> void:
	moves_container = HBoxContainer.new()
	moves_container.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	moves_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	moves_container.add_theme_constant_override("separation", 10)
	moves_container.hide()

	moves_grid = GridContainer.new()
	moves_grid.columns = 2
	moves_grid.add_theme_constant_override("h_separation", 8)
	moves_grid.add_theme_constant_override("v_separation", 8)
	moves_container.add_child(moves_grid)

	for i in range(4):
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(185, 38)
		btn.add_theme_font_size_override("font_size", 15)
		btn.pressed.connect(_on_move_button_pressed.bind(i))
		moves_grid.add_child(btn)
		KeyboardNav.attach_key_hint(btn, str(i + 1))
		move_buttons.append(btn)

	var back_btn := Button.new()
	back_btn.text = "VOLTAR"
	back_btn.custom_minimum_size = Vector2(96, 38)
	back_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	back_btn.add_theme_font_size_override("font_size", 15)
	back_btn.add_theme_stylebox_override("normal", STYLE_QUIT)
	back_btn.add_theme_stylebox_override("hover", STYLE_QUIT_HOVER)
	back_btn.add_theme_stylebox_override("pressed", STYLE_QUIT_HOVER)
	back_btn.pressed.connect(_close_moves_menu)
	moves_container.add_child(back_btn)
	KeyboardNav.attach_key_hint(back_btn, "ESC")

	var parent_box := actions_row.get_parent()
	parent_box.add_child(moves_container)
	parent_box.move_child(moves_container, actions_row.get_index() + 1)

func _on_history_button_pressed() -> void:
	if AudioManager.has_method("play_ui_click"):
		AudioManager.play_ui_click()
	if log_container:
		log_container.visible = not log_container.visible

func update_status_badges(player_buff: Dictionary, enemy_buff: Dictionary) -> void:
	_populate_status_panel(player_status_panel, "HERÓI", player_buff)
	_populate_status_panel(enemy_status_panel, "INIMIGO", enemy_buff)

func _populate_status_panel(panel: VBoxContainer, owner_title: String, buff: Dictionary) -> void:
	if panel == null:
		return
	for child in panel.get_children():
		child.queue_free()

	var turns: int = int(buff.get("turns", 0))
	if turns <= 0:
		panel.hide()
		return

	var header := Label.new()
	header.text = owner_title
	header.add_theme_font_size_override("font_size", 11)
	header.add_theme_color_override("font_color", Color(0.92, 0.86, 0.68, 0.92))
	header.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.08, 1.0))
	header.add_theme_constant_override("outline_size", 3)
	if panel == enemy_status_panel:
		header.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	panel.add_child(header)

	panel.add_child(_make_status_badge(buff))
	panel.show()

func _make_status_badge(buff: Dictionary) -> PanelContainer:
	var amount: int = int(buff.get("amount", 0))
	var turns: int = int(buff.get("turns", 0))
	var stat_key: String = str(buff.get("stat", ""))
	var is_debuff := amount < 0

	var stat_names := {
		"strength": "Força",
		"intelligence": "Inteligência",
		"faith": "Fé",
		"agility": "Agilidade",
		"attack": "Ataque",
		"defense": "Defesa",
	}
	var stat_pt: String = str(stat_names.get(stat_key, stat_key.capitalize()))
	var sign_str := "+" if amount > 0 else ""

	var badge := PanelContainer.new()
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.content_margin_left = 10.0
	style.content_margin_top = 6.0
	style.content_margin_right = 10.0
	style.content_margin_bottom = 6.0
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2

	var stat_color := _color_for_stat(stat_key)
	if is_debuff:
		style.bg_color = Color(stat_color.r * 0.16, stat_color.g * 0.16, stat_color.b * 0.16, 0.94)
		style.border_color = stat_color.darkened(0.12)
	else:
		style.bg_color = Color(stat_color.r * 0.28, stat_color.g * 0.28, stat_color.b * 0.28, 0.92)
		style.border_color = stat_color

	badge.add_theme_stylebox_override("panel", style)
	var lbl := Label.new()
	var tag := "DEBUFF" if is_debuff else "BUFF"
	lbl.text = "[%s] %s %s%d (%dt)" % [tag, stat_pt, sign_str, amount, turns]
	lbl.add_theme_font_size_override("font_size", 13)
	badge.add_child(lbl)
	return badge

func _color_for_stat(stat_key: String) -> Color:
	match stat_key.to_lower().strip_edges():
		"defense": return Color(0.25, 0.92, 1.0, 1.0)
		"strength": return Color(1.0, 0.68, 0.14, 1.0)
		"attack": return Color(1.0, 0.48, 0.10, 1.0)
		"intelligence": return Color(0.78, 0.49, 1.0, 1.0)
		"faith": return Color(1.0, 0.95, 0.46, 1.0)
		"agility": return Color(0.22, 0.95, 0.78, 1.0)
		_: return Color(1.0, 0.85, 0.25, 1.0)

func update_expedition_progress(encounters_won: int, in_camp: bool, elite_ahead_or_active: bool = false) -> void:
	if expedition_dots == null or expedition_label == null:
		return
	for child in expedition_dots.get_children():
		child.queue_free()

	const CAMP_INTERVAL := 5
	var cycle_wins := encounters_won % CAMP_INTERVAL
	var stage_index := int(encounters_won / CAMP_INTERVAL) + 1

	for i in range(CAMP_INTERVAL):
		var dot := Panel.new()
		var st := StyleBoxFlat.new()
		var is_done := in_camp or i < cycle_wins
		var is_current := (not in_camp) and i == cycle_wins
		dot.custom_minimum_size = Vector2(14, 14) if is_current else Vector2(11, 11)
		st.corner_radius_top_left = 7
		st.corner_radius_top_right = 7
		st.corner_radius_bottom_right = 7
		st.corner_radius_bottom_left = 7
		st.border_width_left = 2
		st.border_width_top = 2
		st.border_width_right = 2
		st.border_width_bottom = 2
		if is_done:
			st.bg_color = Color(0.92, 0.72, 0.24, 1.0)
			st.border_color = Color(1.0, 0.9, 0.55, 1.0)
		elif is_current and elite_ahead_or_active:
			st.bg_color = Color(0.78, 0.22, 0.95, 1.0)
			st.border_color = Color(1.0, 0.85, 0.35, 1.0)
		elif is_current:
			st.bg_color = Color(0.95, 0.32, 0.28, 1.0)
			st.border_color = Color(1.0, 0.92, 0.72, 1.0)
		else:
			st.bg_color = Color(0.14, 0.16, 0.22, 0.9)
			st.border_color = Color(0.45, 0.42, 0.36, 0.85)
		dot.add_theme_stylebox_override("panel", st)
		expedition_dots.add_child(dot)

	var camp_badge := PanelContainer.new()
	var camp_style := StyleBoxFlat.new()
	camp_style.content_margin_left = 6.0
	camp_style.content_margin_top = 1.0
	camp_style.content_margin_right = 6.0
	camp_style.content_margin_bottom = 1.0
	camp_style.corner_radius_top_left = 5
	camp_style.corner_radius_top_right = 5
	camp_style.corner_radius_bottom_right = 5
	camp_style.corner_radius_bottom_left = 5
	camp_style.border_width_left = 1
	camp_style.border_width_top = 1
	camp_style.border_width_right = 1
	camp_style.border_width_bottom = 1
	if in_camp:
		camp_style.bg_color = Color(0.16, 0.52, 0.28, 1.0)
		camp_style.border_color = Color(0.55, 1.0, 0.68, 1.0)
	else:
		camp_style.bg_color = Color(0.12, 0.22, 0.16, 0.92)
		camp_style.border_color = Color(0.38, 0.75, 0.48, 0.85)
	camp_badge.add_theme_stylebox_override("panel", camp_style)
	var camp_lbl := Label.new()
	camp_lbl.text = "SEGURO"
	camp_lbl.add_theme_font_size_override("font_size", 11)
	camp_lbl.add_theme_color_override("font_color", Color(0.82, 1.0, 0.86, 1.0))
	camp_badge.add_child(camp_lbl)
	expedition_dots.add_child(camp_badge)

	if in_camp:
		if elite_ahead_or_active:
			expedition_label.text = "Área segura | ALERTA: Inimigo Elite à frente!"
		else:
			expedition_label.text = "Área segura alcançada (%d vitórias)" % encounters_won
	elif elite_ahead_or_active:
		expedition_label.text = "BATALHA ELITE | %d vitórias" % encounters_won
	else:
		var current_battle := cycle_wins + 1
		var remaining := CAMP_INTERVAL - cycle_wins
		var prefix := ("Trecho %d | " % stage_index) if stage_index > 1 else ""
		if remaining == 1:
			expedition_label.text = "%sBatalha %d/%d | Área segura a seguir" % [prefix, current_battle, CAMP_INTERVAL]
		else:
			expedition_label.text = "%sBatalha %d/%d | Área segura em %d" % [prefix, current_battle, CAMP_INTERVAL, remaining]

func setup_attacks(attacks: Array[AttackData], uses_remaining: Array[int]) -> void:
	current_attacks = attacks
	for i in range(move_buttons.size()):
		var btn := move_buttons[i]
		if i < attacks.size() and attacks[i] != null:
			var atk := attacks[i]
			var is_damage := atk.effect_type == "damage"
			btn.add_theme_stylebox_override("normal", STYLE_CONFIRM if is_damage else STYLE_CHOSE)
			btn.add_theme_stylebox_override("hover", STYLE_CONFIRM_HOVER if is_damage else STYLE_CHOSE_HOVER)
			btn.add_theme_stylebox_override("pressed", STYLE_CONFIRM_HOVER if is_damage else STYLE_CHOSE_HOVER)
			btn.add_theme_stylebox_override("disabled", STYLE_CONFIRM_DISABLED)
			btn.tooltip_text = "%s\nPrecisão: %d%%" % [atk.description, atk.accuracy]
			btn.show()
		else:
			btn.hide()
	update_attack_uses(uses_remaining)

func update_attack_uses(uses_remaining: Array[int]) -> void:
	for i in range(mini(move_buttons.size(), current_attacks.size())):
		var atk := current_attacks[i]
		var btn := move_buttons[i]
		if atk == null:
			continue
		if atk.max_uses > 0:
			var left := uses_remaining[i] if i < uses_remaining.size() else 0
			btn.text = "%s (%d/%d)" % [atk.display_name, left, atk.max_uses]
			btn.disabled = left <= 0
		else:
			btn.text = atk.display_name
			btn.disabled = false

func _on_attack_button_pressed() -> void:
	if controller != null and controller.phase == controller.Phase.CAMP:
		attack_pressed.emit()
		return
	if current_attacks.is_empty():
		attack_pressed.emit()
		return
	if AudioManager.has_method("play_ui_click"):
		AudioManager.play_ui_click()
	actions_row.hide()
	moves_container.show()
	if KeyboardNav.is_keyboard_mode():
		for btn in move_buttons:
			if btn.visible and not btn.disabled:
				btn.grab_focus()
				break

func _close_moves_menu() -> void:
	if moves_container != null:
		moves_container.hide()
	if actions_row != null:
		actions_row.show()
	if KeyboardNav.is_keyboard_mode() and attack_button != null and attack_button.is_visible_in_tree() and not attack_button.disabled:
		attack_button.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if _elite_intro_overlay != null:
		return
	if event.is_action_pressed("ui_cancel"):
		if inventory_panel != null and inventory_panel.visible:
			inventory_panel.close_panel()
			if item_button != null and item_button.is_visible_in_tree() and not item_button.disabled:
				item_button.grab_focus()
			get_viewport().set_input_as_handled()
		elif moves_container != null and moves_container.visible:
			if AudioManager.has_method("play_ui_cancel"):
				AudioManager.play_ui_cancel()
			_close_moves_menu()
			get_viewport().set_input_as_handled()
		return

	var keycode: Key = event.keycode
	if keycode == KEY_H and history_button != null and history_button.is_visible_in_tree():
		_on_history_button_pressed()
		get_viewport().set_input_as_handled()
		return

	if (loot_panel != null and loot_panel.visible) or (level_up_panel != null and level_up_panel.visible):
		return

	if moves_container != null and moves_container.visible:
		var slot := -1
		match keycode:
			KEY_1: slot = 0
			KEY_2: slot = 1
			KEY_3: slot = 2
			KEY_4: slot = 3
		if slot >= 0 and slot < move_buttons.size():
			var mbtn := move_buttons[slot]
			if mbtn.visible and not mbtn.disabled:
				_on_move_button_pressed(slot)
				get_viewport().set_input_as_handled()
		return

	if inventory_panel != null and inventory_panel.visible:
		return

	match keycode:
		KEY_A:
			if attack_button != null and attack_button.is_visible_in_tree() and not attack_button.disabled:
				_on_attack_button_pressed()
				get_viewport().set_input_as_handled()
		KEY_I:
			if item_button != null and item_button.is_visible_in_tree() and not item_button.disabled:
				_on_item_button_pressed()
				get_viewport().set_input_as_handled()
		KEY_F:
			if escape_button != null and escape_button.is_visible_in_tree() and not escape_button.disabled:
				escape_pressed.emit()
				get_viewport().set_input_as_handled()

func _on_move_button_pressed(index: int) -> void:
	if AudioManager.has_method("play_ui_click"):
		AudioManager.play_ui_click()
	_close_moves_menu()
	attack_selected.emit(index)

func set_controller(value ) -> void:
	controller = value
	controller.turn_changed.connect(_on_turn_changed)
	controller.battle_finished.connect(_on_battle_finished)

func update_player_health(current: int, maximum: int) -> void:
	player_hp_label.text = "HP: %d/%d" % [current, maximum]
	player_hp_bar.max_value = maximum
	var tween := create_tween()
	tween.tween_property(player_hp_bar, "value", current, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func update_enemy_health(current: int, maximum: int) -> void:
	enemy_hp_label.text = "HP: %d/%d" % [current, maximum]
	enemy_hp_bar.max_value = maximum
	var tween := create_tween()
	tween.tween_property(enemy_hp_bar, "value", current, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func log_str(message: String) -> void:
	log_label.append_text(message + "\n")
	log_label.scroll_to_line(log_label.get_line_count() - 1)

func log_damage(message: String) -> void:
	log_label.append_text("[color=red] [shake rate=20.0 level=5 connected + 1]" + message + "[/shake] [/color]\n")
	log_label.scroll_to_line(log_label.get_line_count() - 1)

func log_heal(message: String) -> void:
	log_label.append_text("[color=green] [wave amp=20.0 freq=5.0 connected=1]" + message + "[/wave][/color]\n")
	log_label.scroll_to_line(log_label.get_line_count() - 1)



func _on_item_button_pressed() -> void:
	if AudioManager.has_method("play_ui_click"):
		AudioManager.play_ui_click()
	inventory_panel.open_panel()

func _on_inventory_item_selected(item: ItemData) -> void:
	if inventory_panel.has_method("close_panel"):
		inventory_panel.close_panel()
	else:
		inventory_panel.hide()
	
	controller.use_item_from_inventory(item)
	


func _on_item_selected(id: int) -> void:
	controller.use_specific_item(id)

func show_loot_screen(item: ItemData) -> void:
	var tween = create_tween()
	current_loot = item
	loot_label.text = "O inimigo dropou:\n%s" % item.item_name
	
	backpack_button.disabled = not GameState.has_inventory_space()
	item_sprite.texture = item.icon
	if backpack_button.disabled:
		backpack_button.text = "MOCHILA CHEIA!"
	else:
		backpack_button.text = "GUARDAR NA MOCHILA"
	
	sell_button.text = "VENDER (%d MOEDAS)" % max(1, item.cost/2)
	
	loot_panel.show()
	if not backpack_button.disabled:
		backpack_button.grab_focus()
	else:
		stash_button.grab_focus()
	
	item_sprite.pivot_offset = item_sprite.size / 2.0
	item_sprite.scale = Vector2.ZERO
	
	tween.tween_property(item_sprite, "scale", Vector2.ONE, 0.8).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)


func _on_loot_chosen(decision: String) -> void:
	loot_panel.hide()
	AudioManager.play_ui_click()
	loot_decision_made.emit(decision, current_loot)

func _on_turn_changed(current_turn: String) -> void:
	var is_player_turn := current_turn == "player"
	if not is_player_turn:
		_close_moves_menu()
	attack_button.disabled = not is_player_turn
	item_button.disabled = not is_player_turn
	escape_button.disabled = not is_player_turn
	title_label.text = "Sua vez" if is_player_turn else "Turno do inimigo"
	if KeyboardNav.is_keyboard_mode() and is_player_turn and attack_button.is_visible_in_tree():
		attack_button.grab_focus()

func _on_battle_finished(player_won: bool) -> void:
	_close_moves_menu()
	attack_button.disabled = true
	item_button.disabled = true
	escape_button.disabled = false
	escape_button.text = "MENU"
	if player_won:
		title_label.text = "Expedição encerrada"
		log_str("Você sobreviveu. Clique em MENU para retornar ao lobby.")
	else:
		title_label.text = "Derrota!"
		log_str("Permadeath. A run terminou. Clique em MENU para sair.")


func set_turn_text(text: String) -> void:
	title_label.text = text

func set_player_bar_position(screen_pos: Vector2) -> void:
	# Centraliza horizontalmente e posiciona um pouco acima
	player_hp_bar.global_position = screen_pos - Vector2(player_hp_bar.size.x * 0.5, player_hp_bar.size.y)

func set_player_bar_visible(is_visible: bool) -> void:
	player_hp_bar.visible = is_visible

func set_enemy_bar_position(screen_pos: Vector2) -> void:
	enemy_hp_bar.global_position = screen_pos - Vector2(enemy_hp_bar.size.x * 0.5, enemy_hp_bar.size.y)

func set_enemy_bar_visible(is_visible: bool) -> void:
	enemy_hp_bar.visible = is_visible

func show_level_up(growth: Dictionary) -> void:
	loot_panel.hide()
	inventory_panel.close_panel()
	await level_up_panel.present(growth)

func show_learn_attack(new_attack: AttackData, current_attacks: Array[AttackData]) -> int:
	if new_attack == null:
		return -1
	_close_moves_menu()
	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.02, 0.03, 0.05, 0.72)
	overlay.theme = preload("res://Scenes/ui/adventure_theme.tres")
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 0)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var header := Label.new()
	header.text = "NOVO GOLPE DISPONÍVEL"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 24)
	vbox.add_child(header)

	var info_box := PanelContainer.new()
	vbox.add_child(info_box)
	var info_v := VBoxContainer.new()
	info_v.add_theme_constant_override("separation", 4)
	info_box.add_child(info_v)

	var name_lbl := Label.new()
	name_lbl.text = new_attack.display_name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 20)
	name_lbl.add_theme_color_override("font_color", Color(0.95, 0.82, 0.42, 1))
	info_v.add_child(name_lbl)

	var desc_lbl := Label.new()
	var uses_text := "Ilimitado" if new_attack.max_uses <= 0 else "%d usos" % new_attack.max_uses
	desc_lbl.text = "%s\nPrecisão: %d%% | %s" % [new_attack.description, new_attack.accuracy, uses_text]
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_v.add_child(desc_lbl)

	var prompt := Label.new()
	prompt.text = "Escolha qual golpe substituir:"
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(prompt)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	vbox.add_child(grid)

	for i in range(mini(4, current_attacks.size())):
		var old_atk := current_attacks[i]
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(240, 46)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.text = "Substituir: %s" % (old_atk.display_name if old_atk != null else "Vazio")
		if old_atk != null:
			btn.tooltip_text = old_atk.description
		btn.add_theme_stylebox_override("normal", STYLE_CONFIRM)
		btn.add_theme_stylebox_override("hover", STYLE_CONFIRM_HOVER)
		btn.add_theme_stylebox_override("pressed", STYLE_CONFIRM_HOVER)
		btn.pressed.connect(func():
			if AudioManager.has_method("play_ui_choose"):
				AudioManager.play_ui_choose()
			_learn_attack_decided.emit(i))
		grid.add_child(btn)

	var skip_btn := Button.new()
	skip_btn.custom_minimum_size = Vector2(240, 44)
	skip_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	skip_btn.text = "Manter golpes atuais"
	skip_btn.add_theme_stylebox_override("normal", STYLE_QUIT)
	skip_btn.add_theme_stylebox_override("hover", STYLE_QUIT_HOVER)
	skip_btn.add_theme_stylebox_override("pressed", STYLE_QUIT_HOVER)
	skip_btn.pressed.connect(func():
		if AudioManager.has_method("play_ui_cancel"):
			AudioManager.play_ui_cancel()
		_learn_attack_decided.emit(-1))
	vbox.add_child(skip_btn)
	if grid.get_child_count() > 0 and grid.get_child(0) is Control:
		(grid.get_child(0) as Control).grab_focus()
	else:
		skip_btn.grab_focus()

	var chosen: int = await _learn_attack_decided
	overlay.queue_free()
	return chosen

func _update_progress() -> void:
	progress_label.text = "Nível %d - XP %d / %d" % [GameState.current_level, GameState.current_xp, GameState.get_xp_required()]

func show_achievement_toast(achievement: AchievementData) -> void:
	if achievement == null:
		return
	if AudioManager.has_method("play_ui_choose"):
		AudioManager.play_ui_choose()
	var toast := PanelContainer.new()
	toast.theme = preload("res://Scenes/ui/adventure_theme.tres")
	var style := StyleBoxFlat.new()
	style.content_margin_left = 16.0
	style.content_margin_top = 10.0
	style.content_margin_right = 16.0
	style.content_margin_bottom = 10.0
	style.bg_color = Color(0.14, 0.2, 0.12, 0.96)
	style.border_color = Color(0.98, 0.82, 0.32, 1.0)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	toast.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	toast.add_child(vbox)

	var header := Label.new()
	header.text = "CONQUISTA DESBLOQUEADA"
	header.add_theme_font_size_override("font_size", 12)
	header.add_theme_color_override("font_color", Color(0.55, 1.0, 0.62, 1.0))
	vbox.add_child(header)

	var name_lbl := Label.new()
	name_lbl.text = achievement.title
	name_lbl.add_theme_font_size_override("font_size", 17)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.48, 1.0))
	vbox.add_child(name_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = achievement.description
	desc_lbl.add_theme_font_size_override("font_size", 13)
	vbox.add_child(desc_lbl)

	toast.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	toast.offset_left = -360
	toast.offset_right = -24
	toast.offset_top = 24
	toast.offset_bottom = 110
	toast.modulate.a = 0.0
	add_child(toast)

	var tween := create_tween()
	tween.tween_property(toast, "modulate:a", 1.0, 0.25)
	tween.tween_interval(2.8)
	tween.tween_property(toast, "modulate:a", 0.0, 0.45)
	tween.finished.connect(toast.queue_free)

func begin_elite_intro(enemy_data: EnemyData) -> void:
	end_elite_intro()
	_close_moves_menu()
	if has_node("MarginContainer"):
		$MarginContainer.hide()
	if progress_label != null:
		progress_label.hide()
	if player_status_panel != null:
		player_status_panel.hide()
	if enemy_status_panel != null:
		enemy_status_panel.hide()
	set_player_bar_visible(false)
	set_enemy_bar_visible(false)

	var accent: Color = enemy_data.elite_theme_color if enemy_data != null else Color(1.0, 0.72, 0.25, 1.0)
	var enemy_name: String = enemy_data.display_name.to_upper() if enemy_data != null else "ELITE"
	var epithet: String = enemy_data.elite_epithet if (enemy_data != null and not enemy_data.elite_epithet.is_empty()) else "Inimigo de Elite"

	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.theme = preload("res://Scenes/ui/adventure_theme.tres")
	add_child(overlay)
	_elite_intro_overlay = overlay

	var top_bar := ColorRect.new()
	top_bar.color = Color(0.02, 0.02, 0.04, 0.96)
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.offset_bottom = 0.0
	overlay.add_child(top_bar)

	var bottom_bar := ColorRect.new()
	bottom_bar.color = Color(0.02, 0.02, 0.04, 0.96)
	bottom_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_bar.offset_top = 0.0
	overlay.add_child(bottom_bar)

	var banner := PanelContainer.new()
	banner.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	banner.offset_left = -310.0
	banner.offset_right = 310.0
	banner.offset_top = -196.0
	banner.offset_bottom = -88.0
	banner.modulate.a = 0.0
	var b_style := StyleBoxFlat.new()
	b_style.bg_color = Color(0.05, 0.05, 0.09, 0.88)
	b_style.border_color = accent
	b_style.border_width_left = 4
	b_style.border_width_right = 4
	b_style.border_width_top = 2
	b_style.border_width_bottom = 2
	b_style.corner_radius_top_left = 6
	b_style.corner_radius_top_right = 6
	b_style.corner_radius_bottom_right = 6
	b_style.corner_radius_bottom_left = 6
	b_style.content_margin_left = 24.0
	b_style.content_margin_right = 24.0
	b_style.content_margin_top = 12.0
	b_style.content_margin_bottom = 12.0
	banner.add_theme_stylebox_override("panel", b_style)
	overlay.add_child(banner)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 4)
	banner.add_child(vbox)

	var tag_lbl := Label.new()
	tag_lbl.text = "INIMIGO ELITE"
	tag_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag_lbl.add_theme_font_size_override("font_size", 13)
	tag_lbl.add_theme_color_override("font_color", accent)
	vbox.add_child(tag_lbl)

	var name_lbl := Label.new()
	name_lbl.text = enemy_name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 32)
	name_lbl.add_theme_color_override("font_color", Color(0.98, 0.96, 0.92, 1.0))
	name_lbl.add_theme_color_override("font_outline_color", Color(0.03, 0.03, 0.06, 1.0))
	name_lbl.add_theme_constant_override("outline_size", 5)
	vbox.add_child(name_lbl)

	var line := ColorRect.new()
	line.color = accent
	line.custom_minimum_size = Vector2(220, 2)
	line.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(line)

	var ep_lbl := Label.new()
	ep_lbl.text = epithet
	ep_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ep_lbl.add_theme_font_size_override("font_size", 16)
	ep_lbl.add_theme_color_override("font_color", accent.lightened(0.28))
	vbox.add_child(ep_lbl)

	var prompt_lbl := Label.new()
	prompt_lbl.name = "ContinuePrompt"
	prompt_lbl.text = "Clique ou pressione Espaço para iniciar a batalha"
	prompt_lbl.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	prompt_lbl.offset_left = -280.0
	prompt_lbl.offset_right = 280.0
	prompt_lbl.offset_top = -48.0
	prompt_lbl.offset_bottom = -18.0
	prompt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_lbl.add_theme_font_size_override("font_size", 15)
	prompt_lbl.add_theme_color_override("font_color", Color(0.98, 0.93, 0.72, 1.0))
	prompt_lbl.modulate.a = 0.0
	overlay.add_child(prompt_lbl)

	var tw := create_tween().set_parallel(true)
	tw.tween_property(top_bar, "offset_bottom", 80.0, 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(bottom_bar, "offset_top", -80.0, 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(banner, "modulate:a", 1.0, 0.55).set_delay(0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func show_elite_intro_confirm_prompt() -> void:
	if not is_instance_valid(_elite_intro_overlay):
		return
	var prompt := _elite_intro_overlay.get_node_or_null("ContinuePrompt") as Label
	if prompt == null:
		return
	var tw := create_tween().set_loops()
	tw.tween_property(prompt, "modulate:a", 1.0, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(prompt, "modulate:a", 0.35, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func end_elite_intro() -> void:
	if is_instance_valid(_elite_intro_overlay):
		_elite_intro_overlay.queue_free()
	_elite_intro_overlay = null
	if has_node("MarginContainer"):
		$MarginContainer.show()
	if progress_label != null:
		progress_label.show()

func show_enemy_action_banner(enemy_name: String, attack_name: String) -> void:
	var callout := PanelContainer.new()
	callout.theme = preload("res://Scenes/ui/adventure_theme.tres")
	callout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.06, 0.09, 0.92)
	style.border_color = Color(0.95, 0.42, 0.35, 0.95)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.content_margin_left = 18.0
	style.content_margin_right = 18.0
	style.content_margin_top = 7.0
	style.content_margin_bottom = 7.0
	callout.add_theme_stylebox_override("panel", style)

	var lbl := Label.new()
	lbl.text = "%s usou %s" % [enemy_name, attack_name]
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.85, 1.0))
	callout.add_child(lbl)

	callout.set_anchors_preset(Control.PRESET_CENTER_TOP)
	callout.offset_left = -210.0
	callout.offset_right = 210.0
	callout.offset_top = 114.0
	callout.offset_bottom = 152.0
	callout.modulate.a = 0.0
	add_child(callout)

	var tw := create_tween()
	tw.tween_property(callout, "modulate:a", 1.0, 0.16)
	tw.tween_interval(1.35)
	tw.tween_property(callout, "modulate:a", 0.0, 0.3)
	tw.finished.connect(callout.queue_free)

func show_backpack_drop_toast(new_limit: int) -> void:
	var toast := PanelContainer.new()
	toast.theme = preload("res://Scenes/ui/adventure_theme.tres")
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.22, 0.16, 0.96)
	style.border_color = Color(0.42, 0.98, 0.62, 1.0)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.content_margin_left = 14.0
	style.content_margin_right = 16.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	toast.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	toast.add_child(hbox)

	var icon := TextureRect.new()
	icon.texture = preload("res://Assets/Images/UI/backpack.png")
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.custom_minimum_size = Vector2(36, 36)
	hbox.add_child(icon)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	hbox.add_child(vbox)

	var hdr := Label.new()
	hdr.text = "DROP RARO DE MOCHILA"
	hdr.add_theme_font_size_override("font_size", 12)
	hdr.add_theme_color_override("font_color", Color(0.55, 1.0, 0.68, 1.0))
	vbox.add_child(hdr)

	var body := Label.new()
	body.text = "+1 Espaço de Mochila (Capacidade: %d)" % new_limit
	body.add_theme_font_size_override("font_size", 15)
	body.add_theme_color_override("font_color", Color(1.0, 0.94, 0.68, 1.0))
	vbox.add_child(body)

	toast.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	toast.offset_left = -380.0
	toast.offset_right = -24.0
	toast.offset_top = 122.0
	toast.offset_bottom = 198.0
	toast.modulate.a = 0.0
	add_child(toast)

	var tw := create_tween()
	tw.tween_property(toast, "modulate:a", 1.0, 0.25)
	tw.tween_interval(3.0)
	tw.tween_property(toast, "modulate:a", 0.0, 0.45)
	tw.finished.connect(toast.queue_free)
