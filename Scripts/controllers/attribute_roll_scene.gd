class_name AttributeRollSceneController
extends Control

@export var battle_scene_path: String = "res://scenes/battle/BattleScene.tscn"
@export var class_selection_scene_path: String = "res://scenes/run/class_selection_scene.tscn"

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

var rng := RandomNumberGenerator.new()
var selected_class: ClassData
var rolled_attributes := {
	"strength": null,
	"intelligence": null,
	"faith": null,
	"agility": null
}

func _ready() -> void:
	if GameState.selected_class == null:
		get_tree().change_scene_to_file(class_selection_scene_path)
		return

	selected_class = GameState.selected_class
	rng.randomize()

	_setup_ui()
	_connect_buttons()

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
	confirm_button.pressed.connect(_on_confirm_button_pressed)

	strength_roll_button.pressed.connect(_on_strength_roll_button_pressed)
	intelligence_roll_button.pressed.connect(_on_intelligence_roll_button_pressed)
	faith_roll_button.pressed.connect(_on_faith_roll_button_pressed)
	agility_roll_button.pressed.connect(_on_agility_roll_button_pressed)

func _reset_value_labels() -> void:
	strength_value_label.text = "-"
	intelligence_value_label.text = "-"
	faith_value_label.text = "-"
	agility_value_label.text = "-"

func _roll_die(sides: int) -> int:
	return rng.randi_range(1, max(1, sides))

func _update_confirm_state() -> void:
	confirm_button.disabled = (
		rolled_attributes["strength"] == null
		or rolled_attributes["intelligence"] == null
		or rolled_attributes["faith"] == null
		or rolled_attributes["agility"] == null
	)

func _on_strength_roll_button_pressed() -> void:
	var result := _roll_die(selected_class.strength_dice)
	rolled_attributes["strength"] = result
	strength_value_label.text = str(result)
	_update_confirm_state()

func _on_intelligence_roll_button_pressed() -> void:
	var result := _roll_die(selected_class.intelligence_dice)
	rolled_attributes["intelligence"] = result
	intelligence_value_label.text = str(result)
	_update_confirm_state()

func _on_faith_roll_button_pressed() -> void:
	var result := _roll_die(selected_class.faith_dice)
	rolled_attributes["faith"] = result
	faith_value_label.text = str(result)
	_update_confirm_state()

func _on_agility_roll_button_pressed() -> void:
	var result := _roll_die(selected_class.agility_dice)
	rolled_attributes["agility"] = result
	agility_value_label.text = str(result)
	_update_confirm_state()

func _on_roll_all_button_pressed() -> void:
	_on_strength_roll_button_pressed()
	_on_intelligence_roll_button_pressed()
	_on_faith_roll_button_pressed()
	_on_agility_roll_button_pressed()

func _on_confirm_button_pressed() -> void:
	GameState.set_rolled_attributes(rolled_attributes)
	get_tree().change_scene_to_file(battle_scene_path)

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file(class_selection_scene_path)
