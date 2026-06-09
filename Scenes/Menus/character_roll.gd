extends Control

@export var selected_class: ClassData

@onready var dice_roller: DiceRoller = $DiceRoller

var rolled_stats: Dictionary = {}

func _ready() -> void:
	roll_character()

func roll_character() -> void:
	if selected_class == null:
		push_warning("Nenhuma classe selecionada.")
		return

	rolled_stats = dice_roller.roll_stats(selected_class)
	update_ui()

func update_ui() -> void:
	$Panel/ClassNameLabel.text = selected_class.class_name
	$Panel/HpValue.text = str(rolled_stats.get("max_hp", 0))
	$Panel/StrengthValue.text = str(rolled_stats.get("strength", 0))
	$Panel/IntelligenceValue.text = str(rolled_stats.get("intelligence", 0))
	$Panel/DefenseValue.text = str(rolled_stats.get("defense", 0))
	$Panel/LuckValue.text = str(rolled_stats.get("luck", 0))

func _on_reroll_button_pressed() -> void:
	roll_character()

func _on_confirm_button_pressed() -> void:
	GameState.create_new_run(selected_class, rolled_stats)
	get_tree().change_scene_to_file("res://scenes/combat/battle_scene.tscn")
