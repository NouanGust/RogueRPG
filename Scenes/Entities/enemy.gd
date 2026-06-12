class_name EnemyActor
extends Node2D


signal setup_finished


@onready var sprite: Sprite2D = $Sprite2D
@onready var stats_component: StatsComponent = $StatsComponent
@onready var health_component: HealthComponent = $HealthComponent
@onready var combat_component: CombatComponent = $CombatComponent

var enemy_data: EnemyData

func setup(data: EnemyData, rolled_value:int) -> void:
	enemy_data = data
	if enemy_data == null:
		push_error("EnemyActor.setup: EnemyData é nulo.")
		return
		
	sprite.texture = enemy_data.sprite
	stats_component.setup_from_enemy(enemy_data, rolled_value)
	health_component.setup(stats_component.get_value("max_hp"))
	setup_finished.emit()
