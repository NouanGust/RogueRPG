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

@onready var title_label: Label = $MarginContainer/VBoxContainer/PanelContainer/TitleLabel
@onready var log_container: PanelContainer = $MarginContainer/VBoxContainer/LogPanel
@onready var log_label: RichTextLabel = $MarginContainer/VBoxContainer/LogPanel/LogPanel
@onready var status_badges: HBoxContainer = $MarginContainer/VBoxContainer/Actions/HBoxContainer/StatusSection/StatusBadges
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
	if log_container:
		log_container.hide()
	log_label.text = ""
	update_status_badges({}, {})
	
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

	var parent_box := actions_row.get_parent()
	parent_box.add_child(moves_container)
	parent_box.move_child(moves_container, actions_row.get_index() + 1)

func _on_history_button_pressed() -> void:
	if AudioManager.has_method("play_ui_click"):
		AudioManager.play_ui_click()
	if log_container:
		log_container.visible = not log_container.visible

func update_status_badges(player_buff: Dictionary, enemy_buff: Dictionary) -> void:
	if status_badges == null:
		return
	for child in status_badges.get_children():
		child.queue_free()

	var p_turns: int = int(player_buff.get("turns", 0))
	var e_turns: int = int(enemy_buff.get("turns", 0))

	if p_turns > 0:
		status_badges.add_child(_make_status_badge("Herói", player_buff))
	if e_turns > 0:
		status_badges.add_child(_make_status_badge("Inimigo", enemy_buff))

func _make_status_badge(owner_label: String, buff: Dictionary) -> PanelContainer:
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

	if is_debuff:
		style.bg_color = Color(0.32, 0.08, 0.24, 0.92)
		style.border_color = Color(0.9, 0.28, 0.7, 1.0)
	else:
		match stat_key:
			"defense":
				style.bg_color = Color(0.08, 0.24, 0.34, 0.92)
				style.border_color = Color(0.28, 0.85, 1.0, 1.0)
			"intelligence":
				style.bg_color = Color(0.2, 0.14, 0.36, 0.92)
				style.border_color = Color(0.68, 0.48, 1.0, 1.0)
			"agility":
				style.bg_color = Color(0.08, 0.28, 0.18, 0.92)
				style.border_color = Color(0.3, 0.95, 0.55, 1.0)
			_:
				style.bg_color = Color(0.3, 0.22, 0.07, 0.92)
				style.border_color = Color(1.0, 0.8, 0.28, 1.0)

	badge.add_theme_stylebox_override("panel", style)
	var lbl := Label.new()
	lbl.text = "%s: %s %s%d (%dt)" % [owner_label, stat_pt, sign_str, amount, turns]
	lbl.add_theme_font_size_override("font_size", 13)
	badge.add_child(lbl)
	return badge

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

func _close_moves_menu() -> void:
	if moves_container != null:
		moves_container.hide()
	if actions_row != null:
		actions_row.show()

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

	var chosen: int = await _learn_attack_decided
	overlay.queue_free()
	return chosen

func _update_progress() -> void:
	progress_label.text = "Nível %d - XP %d / %d" % [GameState.current_level, GameState.current_xp, GameState.get_xp_required()]
