class_name AttributeRollSceneController
extends Control

@export var battle_scene: PackedScene
@export var class_selection_scene: PackedScene
@export var visual_dice: AnimatedSprite2D

@onready var selected_class_label: Label = $MarginContainer/VBoxContainer/ClassInfoPanel/ClassInfoMargin/ClassInfoVBox/SelectedClassLabel
@onready var instruction_label: Label = $MarginContainer/VBoxContainer/ClassInfoPanel/ClassInfoMargin/ClassInfoVBox/InstructionsLabel

@onready var strength_dice_label: Label = $MarginContainer/VBoxContainer/ClassInfoPanel/ClassInfoMargin/ClassInfoVBox/AttributeGrid/StrengthPanel/MarginContainer/StrengthVBox/StrengthDiceLabel
@onready var strength_value_label: Label = $MarginContainer/VBoxContainer/ClassInfoPanel/ClassInfoMargin/ClassInfoVBox/AttributeGrid/StrengthPanel/MarginContainer/StrengthVBox/StrengtValueLabel
@onready var strength_roll_button: Button = $MarginContainer/VBoxContainer/ClassInfoPanel/ClassInfoMargin/ClassInfoVBox/AttributeGrid/StrengthPanel/MarginContainer/StrengthVBox/StrengthRollButton

@onready var intelligence_dice_label: Label = $MarginContainer/VBoxContainer/ClassInfoPanel/ClassInfoMargin/ClassInfoVBox/AttributeGrid/IntelligencePanel/MarginContainer/IntelligenceVBox/IntelligenceDiceLabel
@onready var intelligence_value_label: Label = $MarginContainer/VBoxContainer/ClassInfoPanel/ClassInfoMargin/ClassInfoVBox/AttributeGrid/IntelligencePanel/MarginContainer/IntelligenceVBox/IntelligenceValueLabel
@onready var intelligence_roll_button: Button = $MarginContainer/VBoxContainer/ClassInfoPanel/ClassInfoMargin/ClassInfoVBox/AttributeGrid/IntelligencePanel/MarginContainer/IntelligenceVBox/IntelligenceRollButton

@onready var faith_dice_label: Label = $MarginContainer/VBoxContainer/ClassInfoPanel/ClassInfoMargin/ClassInfoVBox/AttributeGrid/FaithPanel/MarginContainer/FaithVBox/FaithDiceLabel
@onready var faith_value_label: Label = $MarginContainer/VBoxContainer/ClassInfoPanel/ClassInfoMargin/ClassInfoVBox/AttributeGrid/FaithPanel/MarginContainer/FaithVBox/FaithValueLabel
@onready var faith_roll_button: Button = $MarginContainer/VBoxContainer/ClassInfoPanel/ClassInfoMargin/ClassInfoVBox/AttributeGrid/FaithPanel/MarginContainer/FaithVBox/FaithRollButton

@onready var agility_dice_label: Label = $MarginContainer/VBoxContainer/ClassInfoPanel/ClassInfoMargin/ClassInfoVBox/AttributeGrid/AgilityPanel/MarginContainer/AgilityVBox/AgilityDiceLabel
@onready var agility_value_label: Label = $MarginContainer/VBoxContainer/ClassInfoPanel/ClassInfoMargin/ClassInfoVBox/AttributeGrid/AgilityPanel/MarginContainer/AgilityVBox/AgilityValueLabel
@onready var agility_roll_button: Button = $MarginContainer/VBoxContainer/ClassInfoPanel/ClassInfoMargin/ClassInfoVBox/AttributeGrid/AgilityPanel/MarginContainer/AgilityVBox/AgilityRollButton

@onready var back_button: Button = $MarginContainer/VBoxContainer/BottomBar/BackButton
@onready var roll_all_button: Button = $MarginContainer/VBoxContainer/BottomBar/RollAllButton
@onready var confirm_button: Button = $MarginContainer/VBoxContainer/BottomBar/ConfirmButton

var is_rolling: bool = false
var has_general_reroll:bool = true

var selected_class: ClassData
var rolled_attributes := {
	"strenght": null,
	"intelligence": null,
	"faith": null,
	"agility": null
}

func _ready() -> void:
	visual_dice.visible = false
	
	if GameState.selected_class == null:
		SceneTransition.change_scene("res://Scenes/run/class_selection_scene.tscn")
		return

	selected_class = GameState.selected_class
	_setup_ui()
	_connect_buttons()
	_update_button_states()

func _setup_ui() -> void:
	selected_class_label.text = "Classe escolhida: %s" % selected_class.display_name

	strength_dice_label.text = "Dado: d%d" % selected_class.strength_dice
	intelligence_dice_label.text = "Dado: d%d" % selected_class.intelligence_dice
	faith_dice_label.text = "Dado: d%d" % selected_class.faith_dice
	agility_dice_label.text = "Dado: d%d" % selected_class.agility_dice

	_reset_value_labels()
	confirm_button.disabled = true

func _connect_buttons() -> void:
	back_button.pressed.connect(_on_back_button_pressed)
	roll_all_button.pressed.connect(_on_roll_all_button_pressed)
	back_button.mouse_entered.connect(_on_back_button_hovered)
	roll_all_button.mouse_entered.connect(_on_roll_all_button_hovered)
	confirm_button.pressed.connect(_on_confirm_button_pressed)
	confirm_button.mouse_entered.connect(_on_confirm_button_hovered)

	strength_roll_button.pressed.connect(_on_strength_roll_button_pressed)
	intelligence_roll_button.pressed.connect(_on_intelligence_roll_button_pressed)
	faith_roll_button.pressed.connect(_on_faith_roll_button_pressed)
	agility_roll_button.pressed.connect(_on_agility_roll_button_pressed)
	strength_roll_button.mouse_entered.connect(_on_strength_roll_button_hovered)
	intelligence_roll_button.mouse_entered.connect(_on_intelligence_roll_button_hovered)
	faith_roll_button.mouse_entered.connect(_on_faith_roll_button_hovered)
	agility_roll_button.mouse_entered.connect(_on_agility_roll_button_hovered)

func _reset_value_labels() -> void:
	strength_value_label.text = "-"
	intelligence_value_label.text = "-"
	faith_value_label.text = "-"
	agility_value_label.text = "-"

func _roll_die(sides: int) -> int:
	return randi_range(1, max(1, sides))

func _update_confirm_state() -> void:
	confirm_button.disabled = (
		rolled_attributes["strenght"] == null
		or rolled_attributes["intelligence"] == null
		or rolled_attributes["faith"] == null
		or rolled_attributes["agility"] == null
	)

#================================
# Botões de atributos
#================================

func _on_strength_roll_button_pressed() -> void:
	AudioManager.play_single_dice()
	var result = await _roll_die(selected_class.strength_dice)
	visual_dice.visible = true
	visual_dice.play_animation(result)
	await visual_dice.animation_finished
	visual_dice.visible = false
	rolled_attributes["strenght"] = result
	strength_value_label.text = str(result)
	_update_button_states()

func _on_strength_roll_button_hovered() -> void:
	AudioManager.play_ui_hover()

func _on_intelligence_roll_button_pressed() -> void:
	AudioManager.play_single_dice()
	var result = await _roll_die(selected_class.intelligence_dice)
	visual_dice.visible = true
	visual_dice.play_animation(result)
	await visual_dice.animation_finished
	visual_dice.visible = false
	rolled_attributes["intelligence"] = result
	intelligence_value_label.text = str(result)
	_update_button_states()

func _on_intelligence_roll_button_hovered() -> void:
	AudioManager.play_ui_hover()

func _on_faith_roll_button_pressed() -> void:
	AudioManager.play_single_dice()
	var result = await _roll_die(selected_class.faith_dice)
	visual_dice.visible = true
	visual_dice.play_animation(result)
	await visual_dice.animation_finished
	visual_dice.visible = false
	rolled_attributes["faith"] = result
	faith_value_label.text = str(result)
	_update_button_states()

func _on_faith_roll_button_hovered() -> void:
	AudioManager.play_ui_hover()

func _on_agility_roll_button_pressed() -> void:
	AudioManager.play_single_dice()
	var result = await _roll_die(selected_class.agility_dice)
	visual_dice.visible = true
	visual_dice.play_animation(result)
	await visual_dice.animation_finished
	visual_dice.visible = false
	rolled_attributes["agility"] = result
	agility_value_label.text = str(result)
	_update_button_states()
	
func _on_agility_roll_button_hovered() -> void:
	AudioManager.play_ui_hover()

func _on_roll_all_button_pressed() -> void:
	#AudioManager.play_multi_dice()
	if roll_all_button.text == "Rerrolagem Geral (1)":
		has_general_reroll = false
		_reset_value_labels()
		
		rolled_attributes = {"strenght": null, "intelligence": null, "faith": null, "agility": null}
		
		if rolled_attributes["strenght"] == null:
			await _on_strength_roll_button_pressed() 
		if rolled_attributes["intelligence"] == null:
			await _on_intelligence_roll_button_pressed()
		if rolled_attributes["faith"] == null:
			await _on_faith_roll_button_pressed()
		if rolled_attributes["agility"] == null:
			await _on_agility_roll_button_pressed()
	else:
		_reset_value_labels()
		await _on_strength_roll_button_pressed()
		await _on_intelligence_roll_button_pressed()
		await _on_faith_roll_button_pressed()
		await _on_agility_roll_button_pressed()

	
	_update_button_states()

func _on_roll_all_button_hovered() -> void:
	AudioManager.play_ui_hover()

func _on_confirm_button_pressed() -> void:
	AudioManager.play_ui_click()
	GameState.set_rolled_attributes(rolled_attributes)
	SceneTransition.change_scene("res://Scenes/battle/BattleScene.tscn")

func _on_confirm_button_hovered() -> void:
	AudioManager.play_ui_hover()

func _on_back_button_pressed() -> void:
	AudioManager.play_ui_cancel()
	SceneTransition.change_scene("res://Scenes/run/class_selection_scene.tscn")

func _on_back_button_hovered() -> void:
	AudioManager.play_ui_hover()

func _update_button_states() -> void:
	if is_rolling:
		strength_roll_button.disabled = true
		intelligence_roll_button.disabled = true
		faith_roll_button.disabled = true
		agility_roll_button.disabled = true
		roll_all_button.disabled = true
		confirm_button.disabled = true
		return
		
	strength_roll_button.disabled = rolled_attributes["strenght"] != null
	intelligence_roll_button.disabled = rolled_attributes["intelligence"] != null
	faith_roll_button.disabled = rolled_attributes["faith"] != null
	agility_roll_button.disabled = rolled_attributes["agility"] != null
	 
	var all_rolled = (
		rolled_attributes["strenght"] != null and rolled_attributes["intelligence"] != null and rolled_attributes["faith"] != null and rolled_attributes["agility"] != null
	)
	
	confirm_button.disabled = not all_rolled
	
	if all_rolled:
		roll_all_button.text = "Rerrolagem Geral (1)"
		roll_all_button.disabled = not has_general_reroll
	else:
		roll_all_button.text = "Rolar Todos"
		roll_all_button.disabled = false


func _do_visual_roll(dice_sides: int) -> int:
	is_rolling = true
	_update_button_states()
	
	var result := _roll_die(dice_sides)
	visual_dice.animate_roll(dice_sides, result)
	await visual_dice.roll_finished
	
	is_rolling = false
	return result
	
	
	
	
