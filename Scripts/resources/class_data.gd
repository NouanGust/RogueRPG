class_name ClassData
extends Resource

@export var id: StringName
@export var display_name: String
@export var sprite: Texture2D

@export_group("Base Stats")
@export var base_hp: int = 10
@export var base_attack: int = 1
@export var base_defense: int = 0

@export_group("Dado por atributo")
@export var strength_dice: int = 6
@export var intelligence_dice: int = 6
@export var faith_dice: int = 6
@export var agility_dice: int = 6
