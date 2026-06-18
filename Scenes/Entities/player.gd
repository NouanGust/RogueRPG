class_name PlayerActor
extends Node2D

signal setup_finished



@onready var sprite: Sprite2D = $Sprite2D
@onready var stats_component: StatsComponent = $StatsComponent
@onready var health_component: HealthComponent = $HealthComponent
@onready var combat_component: CombatComponent = $CombatComponent
@onready var inventory_component: InventoryComponent = $InventoryComponent

var class_data: ClassData

func _ready() -> void:
	health_component.health_changed.connect(_on_health_changed)
	health_component.died.connect(_on_died)

func setup(actor_class: ClassData, rolled_atributtes: Dictionary) -> void:
	class_data = actor_class
	if class_data == null:
		push_error("PlyerActor.setup: class_data é nulo")
		return
	sprite.texture = class_data.sprite
	stats_component.setup_from_class(class_data, rolled_atributtes)
	health_component.setup(stats_component.get_value("max_hp"))
	setup_finished.emit()

func _on_health_changed(_current: int, _maximum: int) -> void:
	var tween := create_tween()
	
	# --- Squash e Stretch ---
	tween.tween_property(sprite, "scale", Vector2(1.3, 0.7), 0.06).set_trans(Tween.TRANS_SINE)
	tween.tween_property(sprite, "scale", Vector2(0.8, 1.2), 0.08).set_trans(Tween.TRANS_SINE)
	tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_SPRING)
	
	var knock_tween = create_tween()
	knock_tween.tween_property(sprite, "position:x", -10.0, 0.05).set_trans(Tween.TRANS_SINE) 
	knock_tween.tween_property(sprite, "position:x", -0.0, 0.1).set_trans(Tween.TRANS_SPRING) 

func _on_died() -> void:
	if sprite.material != null:
		var tween := create_tween()
		tween.tween_method(_update_dissolve, 0.0, 1.0, 1.5).set_trans(Tween.TRANS_CUBIC)
	
	
func _update_dissolve(value: float) -> void:
	if sprite.material != null:
		sprite.material.set_shader_parameter("dissolve_amount", value)
	
