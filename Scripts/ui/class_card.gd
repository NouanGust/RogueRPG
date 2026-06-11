class_name ClassCard
extends PanelContainer

signal class_chosen(class_data: ClassData)

@export var class_data: ClassData

@onready var name_label: Label = $MarginContainer/VBoxContainer/NameLabel
@onready var portrait_rect: TextureRect = $MarginContainer/VBoxContainer/PortraitRect
@onready var description_label: Label = $MarginContainer/VBoxContainer/DescriptionLabel
@onready var stats_label: RichTextLabel = $MarginContainer/VBoxContainer/StatsLabel
@onready var confirm_button: Button = $MarginContainer/VBoxContainer/ConfirmButton




func _ready() -> void:
	confirm_button.pressed.connect(_on_selected_button_pressed)
	if class_data != null:
		setup(class_data)


func setup(data: ClassData) -> void:
	class_data = data
	name_label.text = class_data.display_name
	portrait_rect.texture = class_data.sprite
	stats_label.text = (
		"HP Base: %d\nAtaque Base: %d\nDefesa Base: %d\n\nForça d%d\nInteligência d%d\nFé d%d\nAgilidade d%d"
		% [
			class_data.base_hp,
			class_data.base_attack,
			class_data.base_defense,
			class_data.strength_dice,
			class_data.intelligence_dice,
			class_data.faith_dice,
			class_data.agility_dice
		]
	)

func _on_selected_button_pressed() -> void:
	class_chosen.emit(class_data)
