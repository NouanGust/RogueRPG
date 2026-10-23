class_name AttributeRoll3D
extends Control

signal roll_confirmed
signal back_requested

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
@onready var test_3d_button: Button = $MarginContainer/VBoxContainer/BottomBar/Test3DButton

var is_rolling: bool = false
var has_general_reroll:bool = true

var selected_class: ClassData
var rolled_attributes := {
	"strength": null,
	"intelligence": null,
	"faith": null,
	"agility": null
}

func _ready() -> void:
	visual_dice.hide()
	test_3d_button.hide()
	back_button.pressed.connect(func():
		if not is_rolling:
			back_requested.emit())
	roll_all_button.pressed.connect(_on_roll_all_button_pressed)
	confirm_button.pressed.connect(_on_confirm_button_pressed)
	strength_roll_button.pressed.connect(_roll_single.bind("strength"))
	intelligence_roll_button.pressed.connect(_roll_single.bind("intelligence"))
	faith_roll_button.pressed.connect(_roll_single.bind("faith"))
	agility_roll_button.pressed.connect(_roll_single.bind("agility"))
	_update_button_states()

func prepare_roll() -> void:
	selected_class = GameState.selected_class
	if selected_class == null:
		return
	rolled_attributes = {"strength": null, "intelligence": null, "faith": null, "agility": null}
	is_rolling = false
	has_general_reroll = true
	selected_class_label.text = "Classe escolhida: %s" % selected_class.display_name
	strength_dice_label.text = "Dado: d%d" % selected_class.strength_dice
	intelligence_dice_label.text = "Dado: d%d" % selected_class.intelligence_dice
	faith_dice_label.text = "Dado: d%d" % selected_class.faith_dice
	agility_dice_label.text = "Dado: d%d" % selected_class.agility_dice
	_refresh_values()
	_update_button_states()

func _roll_single(attribute: String) -> void:
	if is_rolling or selected_class == null or rolled_attributes[attribute] != null:
		return
	is_rolling = true
	_update_button_states()
	await _roll_attribute(attribute)
	is_rolling = false
	_update_button_states()

func _roll_attribute(attribute: String) -> void:
	var sides: int = selected_class.get(attribute + "_dice")
	var result := randi_range(1, maxi(1, sides))
	AudioManager.play_single_dice()
	visual_dice.show()
	visual_dice.play_animation(result)
	await visual_dice.animation_finished
	visual_dice.hide()
	rolled_attributes[attribute] = result
	_refresh_values()

func _all_rolled() -> bool:
	return not rolled_attributes.values().has(null)

func _on_roll_all_button_pressed() -> void:
	if is_rolling or selected_class == null:
		return
	if _all_rolled():
		if not has_general_reroll:
			return
		has_general_reroll = false
		for attribute in rolled_attributes:
			rolled_attributes[attribute] = null
	is_rolling = true
	_refresh_values()
	_update_button_states()
	for attribute in rolled_attributes:
		if rolled_attributes[attribute] == null:
			await _roll_attribute(attribute)
	is_rolling = false
	_update_button_states()

func _refresh_values() -> void:
	strength_value_label.text = str(rolled_attributes.strength) if rolled_attributes.strength != null else "-"
	intelligence_value_label.text = str(rolled_attributes.intelligence) if rolled_attributes.intelligence != null else "-"
	faith_value_label.text = str(rolled_attributes.faith) if rolled_attributes.faith != null else "-"
	agility_value_label.text = str(rolled_attributes.agility) if rolled_attributes.agility != null else "-"

func _update_button_states() -> void:
	strength_roll_button.disabled = is_rolling or rolled_attributes.strength != null
	intelligence_roll_button.disabled = is_rolling or rolled_attributes.intelligence != null
	faith_roll_button.disabled = is_rolling or rolled_attributes.faith != null
	agility_roll_button.disabled = is_rolling or rolled_attributes.agility != null
	back_button.disabled = is_rolling
	confirm_button.disabled = is_rolling or not _all_rolled()
	roll_all_button.text = "Rerrolagem Geral (1)" if _all_rolled() else "Rolar Todos"
	roll_all_button.disabled = is_rolling or (_all_rolled() and not has_general_reroll)

func _on_confirm_button_pressed() -> void:
	if is_rolling or not _all_rolled():
		return
	AudioManager.play_ui_click()
	GameState.set_rolled_attributes(rolled_attributes)
	roll_confirmed.emit()
