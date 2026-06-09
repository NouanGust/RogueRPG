extends Control
class_name BattleUI

signal attack_selected
signal item_selected
signal escape_selected

@onready var player_name_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/PlayerPanel/VBoxContainer/PlayerNameLabel
@onready var player_hp_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/PlayerPanel/VBoxContainer/PlayerHpLabel
@onready var player_hp_bar: ProgressBar = $MarginContainer/VBoxContainer/HBoxContainer/PlayerPanel/VBoxContainer/PlayerHpBar

@onready var enemy_name_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/EnemyPanel/VBoxContainer/EnemyNameLabel
@onready var enemy_hp_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/EnemyPanel/VBoxContainer/EnemyHpLabel
@onready var enemy_hp_bar: ProgressBar = $MarginContainer/VBoxContainer/HBoxContainer/EnemyPanel/VBoxContainer/EnemyHpBar

@onready var log_label: Label = $MarginContainer/VBoxContainer/LogLabel

@onready var attack_button: Button = $MarginContainer/VBoxContainer/Actions/HBoxContainer/AttackButton
@onready var item_button: Button = $MarginContainer/VBoxContainer/Actions/HBoxContainer/ItemButton
@onready var escape_button: Button = $MarginContainer/VBoxContainer/Actions/HBoxContainer/EscapeButton

func _ready() -> void:
	attack_button.pressed.connect(_on_attack_pressed)
	item_button.pressed.connect(_on_item_pressed)
	escape_button.pressed.connect(_on_escape_pressed)

func setup_player(name: String, current_hp: int, max_hp: int) -> void:
	player_name_label.text = name
	player_hp_bar.max_value = max_hp
	player_hp_bar.value = current_hp
	player_hp_label.text = "HP: %d / %d" % [current_hp, max_hp]

func setup_enemy(name: String, current_hp: int, max_hp: int) -> void:
	enemy_name_label.text = name
	enemy_hp_bar.max_value = max_hp
	enemy_hp_bar.value = current_hp
	enemy_hp_label.text = "HP: %d / %d" % [current_hp, max_hp]

func update_player_hp(current_hp: int, max_hp: int) -> void:
	player_hp_bar.max_value = max_hp
	player_hp_bar.value = current_hp
	player_hp_label.text = "HP: %d / %d" % [current_hp, max_hp]

func update_enemy_hp(current_hp: int, max_hp: int) -> void:
	enemy_hp_bar.max_value = max_hp
	enemy_hp_bar.value = current_hp
	enemy_hp_label.text = "HP: %d / %d" % [current_hp, max_hp]

func set_log(message: String) -> void:
	log_label.text = message

func set_actions_enabled(enabled: bool) -> void:
	attack_button.disabled = not enabled
	item_button.disabled = not enabled
	escape_button.disabled = not enabled

func _on_attack_pressed() -> void:
	attack_selected.emit()

func _on_item_pressed() -> void:
	item_selected.emit()

func _on_escape_pressed() -> void:
	escape_selected.emit()
