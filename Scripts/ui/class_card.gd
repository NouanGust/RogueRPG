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
	pass

func _on_selected_button_pressed() -> void:
	pass
