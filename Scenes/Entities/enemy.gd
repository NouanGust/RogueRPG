class_name EnemyActor
extends Node2D


signal setup_finished


@onready var sprite: Sprite2D = $Sprite2D
@onready var stats_component: StatsComponent = $StatsComponent
@onready var health_component: HealthComponent = $HealthComponent
@onready var combat_component: CombatComponent = $CombatComponent

var enemy_data: EnemyData

func _ready() -> void:
	health_component.health_changed.connect(_on_health_changed)

func setup(data: EnemyData, rolled_value:int) -> void:
	enemy_data = data
	if enemy_data == null:
		push_error("EnemyActor.setup: EnemyData é nulo.")
		return
		
	sprite.texture = enemy_data.sprite
	stats_component.setup_from_enemy(enemy_data, rolled_value)
	health_component.setup(stats_component.get_value("max_hp"))
	setup_finished.emit()
	

func _on_health_changed(_current: int, _maximum: int) -> void:
	if sprite.material != null:
		sprite.material.set_shader_parameter("active", true)
		await get_tree().create_timer(0.18).timeout
		if is_instance_valid(sprite) and sprite.material != null:
			sprite.material.set_shader_parameter("active", false)
			
	var tween := create_tween()
	tween.tween_property(sprite, "position:x", 15.0, 0.05).set_trans(Tween.TRANS_SINE)
	tween.tween_property(sprite, "position:x", 0.0, 0.1).set_trans(Tween.TRANS_SPRING)
