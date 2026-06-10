class_name PlayerActor
extends Node2D

signal setup_finished

@export var class_data: ClassData

@onready var sprite: Sprite2D = $Sprite2D
@onready var stats_component: StatsComponent = $StatsComponent
@onready var health_component: HealthComponent = $HealthComponent
@onready var combat_component: CombatComponent = $CombatComponent
@onready var inventory_component: InventoryComponent = $InventoryComponent


func setup(actor_class: ClassData, rolled_atributtes: Dictionary) -> void:
	class_data = actor_class
	sprite.texture = class_data.sprite
	stats_component.setup_from_class(class_data, rolled_atributtes)
	health_component.setup(stats_component.get_value("max_hp"))
	setup_finished.emit()
