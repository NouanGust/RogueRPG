class_name BattleUI
extends Control

signal attack_pressed
signal item_pressed
signal escape_pressed

@onready var title_label: Label = $MarginContainer/VBoxContainer/PanelContainer/TitleLabel
@onready var log_label: RichTextLabel = $MarginContainer/VBoxContainer/Actions/HBoxContainer/LogPanel/LogPanel

@onready var player_hp_label: Label = $MarginContainer/VBoxContainer/Actions/HBoxContainer/PanelContainer/PlayerHPLAbel
@onready var enemy_hp_label: Label = $MarginContainer/VBoxContainer/EnemyPanel/HPLabel

@onready var attack_button: Button = $MarginContainer/VBoxContainer/Actions/HBoxContainer/ActionsRow/AttackButton
@onready var item_button: Button = $MarginContainer/VBoxContainer/Actions/HBoxContainer/ActionsRow/ItemButton
@onready var escape_button: Button = $MarginContainer/VBoxContainer/Actions/HBoxContainer/ActionsRow/EscapeButton

@onready var player_hp_bar: ProgressBar = $MarginContainer/VBoxContainer/Actions/HBoxContainer/PanelContainer/ProgressBar
@onready var enemy_hp_bar: ProgressBar = $MarginContainer/VBoxContainer/EnemyPanel/EnemyHPBar


var controller: BattleController
var item_menu: PopupMenu

func _ready() -> void:
	attack_button.pressed.connect(func(): attack_pressed.emit())
	item_button.pressed.connect(func(): item_pressed.emit())
	escape_button.pressed.connect(func(): escape_pressed.emit())
	log_label.text = ""
	
	item_menu = PopupMenu.new()
	add_child(item_menu)
	item_menu.id_pressed.connect(_on_item_selected)

func set_controller(value: BattleController) -> void:
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

func open_item_menu() -> void:
	item_menu.clear()
	var inventory = controller.player_node.inventory_component
	
	item_menu.add_item("Poção (%d) - Cura 5 de HP" % inventory.potions, 0)
	item_menu.set_item_disabled(0, inventory.potions <= 0)
	item_menu.add_item("Elixir (%d) - Buff aleatório" % inventory.elixirs, 1)
	item_menu.set_item_disabled(1, inventory.elixirs <= 0)
	item_menu.popup_centered(Vector2i(250, 100))
	
	
func _on_item_selected(id: int) -> void:
	controller.use_specific_item(id)



func _on_turn_changed(current_turn: String) -> void:
	var is_player_turn := current_turn == "player"
	attack_button.disabled = not is_player_turn
	item_button.disabled = not is_player_turn
	escape_button.disabled = not is_player_turn
	title_label.text = "Sua vez" if is_player_turn else "Turno do inimigo"

func _on_battle_finished(player_won: bool) -> void:
	attack_button.disabled = true
	item_button.disabled = true
	escape_button.disabled = false
	escape_button.text = "MENU"
	if player_won:
		title_label.text = "Vitória!"
		log_str("A run foi concluída com sucesso. Clique em MENU para sair.")
	else:
		title_label.text = "Derrota!"
		log_str("Permadeath. A run terminou. Clique em MENU para sair.")


func set_turn_text(text: String) -> void:
	title_label.text = text
