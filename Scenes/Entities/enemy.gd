class_name EnemyActor
extends Node2D


signal setup_finished


@onready var anim_sprite: AnimatedSprite2D = $AnimSprite
@onready var stats_component: StatsComponent = $StatsComponent
@onready var health_component: HealthComponent = $HealthComponent
@onready var combat_component: CombatComponent = $CombatComponent

var enemy_data: EnemyData

func _ready() -> void:
	health_component.health_changed.connect(_on_health_changed)
	anim_sprite.animation_finished.connect(_on_animation_finished)

func setup(data: EnemyData, rolled_value:int) -> void:
	enemy_data = data
	if enemy_data == null:
		push_error("EnemyActor.setup: EnemyData é nulo.")
		return
		
	anim_sprite.sprite_frames = enemy_data.sprite_frames
	play_idle()
	
	stats_component.setup_from_enemy(enemy_data, rolled_value)
	health_component.setup(stats_component.get_value("max_hp"))
	setup_finished.emit()
	

func play_anim(anim_name: String) -> void:
	if anim_sprite.sprite_frames and anim_sprite.sprite_frames.has_animation(anim_name):
		anim_sprite.play(anim_name)


func play_idle(): play_anim("Idle")
func play_walk(): play_anim("Walk")
func play_attack(): play_anim("Attack")
func play_hurt(): play_anim("Hurt")
func play_dead(): play_anim("Dead")



func _on_health_changed(_current: int, _maximum: int) -> void:
	play_hurt()
	if anim_sprite.material != null:
		anim_sprite.material.set_shader_parameter("active", true)
		await get_tree().create_timer(0.18).timeout
		if is_instance_valid(anim_sprite) and anim_sprite.material != null:
			anim_sprite.material.set_shader_parameter("active", false)
			
	var tween := create_tween()
	tween.tween_property(anim_sprite, "position:x", 15.0, 0.05).set_trans(Tween.TRANS_SINE)
	tween.tween_property(anim_sprite, "position:x", 0.0, 0.1).set_trans(Tween.TRANS_SPRING)

func _on_animation_finished() -> void:
	if anim_sprite.animation in["attack", "hurt"]:
		play_idle()
