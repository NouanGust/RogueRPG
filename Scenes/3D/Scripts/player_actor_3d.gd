class_name PlayerActor3D
extends Node3D

signal setup_finished



@onready var sprite: AnimatedSprite3D = $AnimSprite
@onready var stats_component: StatsComponent = $StatsComponent
@onready var health_component: HealthComponent = $HealthComponent
@onready var combat_component: CombatComponent = $CombatComponent
@onready var inventory_component: InventoryComponent = $InventoryComponent
@onready var level_up_light: OmniLight3D = $LevelUpLight
@onready var vfx_center: Marker3D = get_node_or_null("VFXCenter")

@export var frames: SpriteFrames
var class_data: ClassData
var _aura_active: bool = false

func _process(_delta: float) -> void:
	if _aura_active:
		_sync_aura_texture()

func get_vfx_center() -> Vector3:
	if vfx_center != null:
		return vfx_center.global_position
	return global_position + Vector3(0.0, -0.3, 0.0)

func _ready() -> void:
	health_component.health_changed.connect(_on_health_changed)
	health_component.died.connect(_on_died)
	stats_component.aura_changed.connect(_on_aura_changed)
	sprite.frame_changed.connect(_sync_aura_texture)
	sprite.animation_changed.connect(_sync_aura_texture)
	_sync_aura_texture()

func setup(actor_class: ClassData, rolled_atributtes: Dictionary) -> void:
	class_data = actor_class
	if class_data == null:
		push_error("PlayerActor.setup: class_data é nulo")
		return
	sprite.sprite_frames = class_data.sprite
	sprite.modulate.a = 1.0
	sprite.play("Idle")
	_sync_aura_texture()
	stats_component.setup_from_class(class_data, rolled_atributtes)
	health_component.setup(stats_component.get_value("max_hp"))
	setup_finished.emit()

func _on_aura_changed(aura_type: String, stat_name: String) -> void:
	var mat := sprite.material_overlay as ShaderMaterial
	if mat == null:
		return
	if aura_type == "none":
		_aura_active = false
		mat.set_shader_parameter("aura_active", false)
		return
	_aura_active = true
	_sync_aura_texture()
	mat.set_shader_parameter("aura_active", true)
	mat.set_shader_parameter("aura_color", _color_for_aura(aura_type, stat_name))
	mat.set_shader_parameter("aura_intensity", 2.2)
	mat.set_shader_parameter("outline_pixels", 2.2)
	mat.set_shader_parameter("pulse_speed", 4.6 if aura_type == "debuff" else 3.2)

func _color_for_aura(aura_type: String, stat_name: String) -> Color:
	if aura_type == "debuff":
		return Color(1.0, 0.22, 0.58, 1.0)
	match stat_name.to_lower().strip_edges():
		"defense": return Color(0.25, 0.92, 1.0, 1.0)
		"strength", "attack": return Color(1.0, 0.75, 0.15, 1.0)
		"intelligence": return Color(0.84, 0.48, 1.0, 1.0)
		"faith": return Color(1.0, 0.95, 0.48, 1.0)
		"agility": return Color(0.32, 1.0, 0.58, 1.0)
		_: return Color(1.0, 0.85, 0.25, 1.0)

func _sync_aura_texture() -> void:
	var mat := sprite.material_overlay as ShaderMaterial
	if mat == null or sprite.sprite_frames == null:
		return
	if not sprite.sprite_frames.has_animation(sprite.animation):
		return
	var frame_count := sprite.sprite_frames.get_frame_count(sprite.animation)
	if frame_count <= 0:
		return
	var tex := sprite.sprite_frames.get_frame_texture(sprite.animation, clampi(sprite.frame, 0, frame_count - 1))
	if tex is AtlasTexture and tex.atlas != null:
		var atlas_tex: AtlasTexture = tex
		var w := maxf(1.0, float(atlas_tex.atlas.get_width()))
		var h := maxf(1.0, float(atlas_tex.atlas.get_height()))
		var r := atlas_tex.region
		mat.set_shader_parameter("sprite_texture", atlas_tex.atlas)
		mat.set_shader_parameter("region_rect", Vector4(r.position.x / w, r.position.y / h, (r.position.x + r.size.x) / w, (r.position.y + r.size.y) / h))
	elif tex != null:
		mat.set_shader_parameter("sprite_texture", tex)
		mat.set_shader_parameter("region_rect", Vector4(0.0, 0.0, 1.0, 1.0))

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
	_on_aura_changed("none", "")
	var tween := create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 1.4).set_trans(Tween.TRANS_CUBIC)


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
