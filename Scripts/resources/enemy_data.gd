class_name EnemyData
extends Resource

@export var id: StringName
@export var display_name: String
@export var sprite: Texture2D

@export_group("Base Stats")
@export var base_hp: int = 15
@export var base_attack: int = 1
@export var base_defense: int = 0
@export var xp_reward: int = 10

@export_group("Dado por atributo")
@export var stats_dice: int = 4
