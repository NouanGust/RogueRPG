class_name ItemData
extends Resource

@export var item_name: String
@export var description: String
@export var icon: Texture2D
@export var cost: int
@export_enum("potion", "elixir", "dice", "relic") var item_type: String
@export var effect_value: String

 
