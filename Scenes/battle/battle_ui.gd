class_name BattleUI
extends Control

signal attack_pressed
signal item_pressed
signal escape_pressed

@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var log_label: RichTextLabel = $MarginContainer/VBoxContainer/LogPanel/LogPanel

@onready var player_hp_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/PlayerPanel/HPLabel
@onready var enemy_hp_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/EnemyPanel/HPLabel

@onready var attack_button: Button = $MarginContainer/VBoxContainer/Actions/ActionsRow/AttackButton
@onready var item_button: Button = $MarginContainer/VBoxContainer/Actions/ActionsRow/ItemButton
@onready var escape_button: Button = $MarginContainer/VBoxContainer/Actions/ActionsRow/EscapeButton

var controller: BattleController

func _ready() -> void:
	attack_button.pressed.connect(func(): attack_pressed.emit())
	item_button.pressed.connect(func(): item_pressed.emit())
	escape_button.pressed.connect(func(): escape_pressed.emit())
	log_label.text = ""

func set_controller(value: BattleController) -> void:
	controller = value
	controller.turn_changed.connect(_on_turn_changed)
	controller.battle_finished.connect(_on_battle_finished)

func update_player_health(current: int, maximum: int) -> void:
	player_hp_label.text = "HP: %d/%d" % [current, maximum]

func update_enemy_health(current: int, maximum: int) -> void:
	enemy_hp_label.text = "HP: %d/%d" % [current, maximum]

func log_str(message: String) -> void:
	log_label.text += message + "\n"
	log_label.scroll_to_line(log_label.get_line_count() - 1)

func open_item_menu() -> void:
	log_str("Inventário ainda não implementado no MVP.")

func _on_turn_changed(current_turn: String) -> void:
	var is_player_turn := current_turn == "player"
	attack_button.disabled = not is_player_turn
	item_button.disabled = not is_player_turn
	escape_button.disabled = not is_player_turn
	title_label.text = "Sua vez" if is_player_turn else "Turno do inimigo"

func _on_battle_finished(player_won: bool) -> void:
	attack_button.disabled = true
	item_button.disabled = true
	escape_button.disabled = true
	if player_won:
		title_label.text = "Vitória!"
		log_str("A run foi concluída com sucesso.")
	else:
		title_label.text = "Derrota!"
		log_str("Permadeath. A run terminou.")


func set_turn_text(text: String) -> void:
	title_label.text = text
