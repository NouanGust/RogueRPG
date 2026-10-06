class_name PlayerActor3D
extends Node3D

signal setup_finished



@onready var sprite: AnimatedSprite3D = $AnimSprite
@onready var stats_component: StatsComponent = $StatsComponent
@onready var health_component: HealthComponent = $HealthComponent
@onready var combat_component: CombatComponent = $CombatComponent
@onready var inventory_component: InventoryComponent = $InventoryComponent
@onready var level_up_light: OmniLight3D = $LevelUpLight

@export var frames: SpriteFrames
var class_data: ClassData

func _ready() -> void:
	health_component.health_changed.connect(_on_health_changed)
	health_component.died.connect(_on_died)

func setup(actor_class: ClassData, rolled_atributtes: Dictionary) -> void:
	class_data = actor_class
	if class_data == null:
		push_error("PlayerActor.setup: class_data é nulo")
		return
	sprite.sprite_frames = class_data.sprite
	sprite.play("Idle")
	stats_component.setup_from_class(class_data, rolled_atributtes)
	health_component.setup(stats_component.get_value("max_hp"))
	setup_finished.emit()

func _on_health_changed(_current: int, _maximum: int) -> void:
	var tween := create_tween()
	
	# --- Squash e Stretch ---
	tween.tween_property(sprite, "scale", Vector3(1.3, 0.7,1.2), 0.06).set_trans(Tween.TRANS_SINE)
	tween.tween_property(sprite, "scale", Vector3(0.8, 1.2, 1.2), 0.08).set_trans(Tween.TRANS_SINE)
	tween.tween_property(sprite, "scale", Vector3(1.0, 1.0, 1.0), 0.15).set_trans(Tween.TRANS_SPRING)
	
	var knock_tween = create_tween()
	knock_tween.tween_property(sprite, "position:x", -0.3, 0.05).set_trans(Tween.TRANS_SINE) 
	knock_tween.tween_property(sprite, "position:x", -0.0, 0.1).set_trans(Tween.TRANS_SPRING) 

func _on_died() -> void:
	if sprite.material_overlay != null:
		var tween := create_tween()
		tween.tween_method(_update_dissolve, 0.0, 1.0, 1.5).set_trans(Tween.TRANS_CUBIC)
	
	
func _update_dissolve(value: float) -> void:
	if sprite.material_overlay != null:
		sprite.material_overlay.set_shader_parameter("dissolve_amount", value)


func play_anim(anim_name: String) -> void:
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)


func play_idle(): play_anim("Idle")
func play_walk(): play_anim("Walk")
func play_attack(): play_anim("Attack")
func play_hurt(): play_anim("Hurt")
func play_dead(): play_anim("Dead")

func play_level_up_effect() -> void:
	var tween = create_tween()
	tween.tween_property(level_up_light, "light_energy", 8.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(level_up_light, "light_energy", 0.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	var original_y = sprite.position.y
	var jump_tween = create_tween()
	jump_tween.tween_property(sprite, "position:y", original_y + 0.5, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	jump_tween.tween_property(sprite, "position:y", original_y, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
