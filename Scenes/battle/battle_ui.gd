class_name BattleUI
extends Control

signal attack_pressed
signal escape_pressed
signal loot_decision_made(decision: String, item: ItemData)

@onready var title_label: Label = $MarginContainer/VBoxContainer/PanelContainer/TitleLabel
@onready var log_label: RichTextLabel = $MarginContainer/VBoxContainer/Actions/HBoxContainer/LogPanel/LogPanel

@onready var player_hp_label: Label = $MarginContainer/VBoxContainer/Actions/HBoxContainer/PanelContainer/PlayerHPLAbel
@onready var enemy_hp_label: Label = $MarginContainer/VBoxContainer/EnemyPanel/HPLabel

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

var controller: BattleController
var current_loot: ItemData

func _ready() -> void:
	attack_button.pressed.connect(func(): attack_pressed.emit())
	item_button.pressed.connect(_on_item_button_pressed)
	escape_button.pressed.connect(func(): escape_pressed.emit())
	log_label.text = ""
	
	inventory_panel.item_selected.connect(_on_inventory_item_selected)
	loot_panel.hide()
	backpack_button.pressed.connect(func(): _on_loot_chosen("backpack"))
	stash_button.pressed.connect(func(): _on_loot_chosen("stash"))
	sell_button.pressed.connect(func(): _on_loot_chosen("sell"))

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
	current_loot = item
	loot_label.text = "O inimigo dropou:\n%s" % item.item_name
	
	backpack_button.disabled = not GameState.has_inventory_space()
	if backpack_button.disabled:
		backpack_button.text = "MOCHILA CHEIA!"
	else:
		backpack_button.text = "GUARDAR NA MOCHILA"
	
	sell_button.text = "VENDER (%d MOEDAS)" % max(1, item.cost/2)
	
	loot_panel.show()


func _on_loot_chosen(decision: String) -> void:
	loot_panel.hide()
	AudioManager.play_ui_click()
	loot_decision_made.emit(decision, current_loot)

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
