class_name EnemyActor3D
extends Node3D


signal setup_finished


@onready var anim_sprite: AnimatedSprite3D = $AnimSprite
@onready var stats_component: StatsComponent = $StatsComponent
@onready var health_component: HealthComponent = $HealthComponent
@onready var combat_component: CombatComponent = $CombatComponent
@onready var vfx_center: Marker3D = get_node_or_null("VFXCenter")
@onready var intro_light: OmniLight3D = get_node_or_null("IntroLight")

var enemy_data: EnemyData
var _aura_active: bool = false

func _process(_delta: float) -> void:
	if _aura_active:
		_sync_aura_texture()

func get_vfx_center() -> Vector3:
	if vfx_center != null:
		return vfx_center.global_position
	return global_position + Vector3(0.0, -0.25, 0.0)

func _ready() -> void:
	health_component.health_changed.connect(_on_health_changed)
	anim_sprite.animation_finished.connect(_on_animation_finished)
	stats_component.aura_changed.connect(_on_aura_changed)
	anim_sprite.frame_changed.connect(_sync_aura_texture)
	anim_sprite.animation_changed.connect(_sync_aura_texture)
	_sync_aura_texture()

func setup(data: EnemyData, rolled_value:int) -> void:
	enemy_data = data
	if enemy_data == null:
		push_error("EnemyActor.setup: EnemyData é nulo.")
		return
		
	anim_sprite.sprite_frames = enemy_data.sprite_frames
	anim_sprite.modulate = Color.WHITE
	if intro_light != null:
		intro_light.light_energy = 0.0
	play_idle()
	_sync_aura_texture()
	
	stats_component.setup_from_enemy(enemy_data, rolled_value)
	health_component.setup(stats_component.get_value("max_hp"))
	setup_finished.emit()

func _on_aura_changed(aura_type: String, stat_name: String) -> void:
	var mat := anim_sprite.material_overlay as ShaderMaterial
	if mat == null:
		return
	if aura_type == "none":
		_aura_active = false
		mat.set_shader_parameter("aura_active", false)
		mat.set_shader_parameter("is_debuff", false)
		return
	_aura_active = true
	_sync_aura_texture()
	var is_debuff := aura_type == "debuff"
	mat.set_shader_parameter("aura_active", true)
	mat.set_shader_parameter("is_debuff", is_debuff)
	mat.set_shader_parameter("aura_color", _color_for_stat(stat_name))
	mat.set_shader_parameter("aura_intensity", 2.2)
	mat.set_shader_parameter("outline_pixels", 2.2)
	mat.set_shader_parameter("pulse_speed", 4.6 if is_debuff else 3.2)

func _color_for_stat(stat_name: String) -> Color:
	match stat_name.to_lower().strip_edges():
		"defense": return Color(0.25, 0.92, 1.0, 1.0)
		"strength": return Color(1.0, 0.68, 0.14, 1.0)
		"attack": return Color(1.0, 0.48, 0.10, 1.0)
		"intelligence": return Color(0.78, 0.49, 1.0, 1.0)
		"faith": return Color(1.0, 0.95, 0.46, 1.0)
		"agility": return Color(0.22, 0.95, 0.78, 1.0)
		_: return Color(1.0, 0.85, 0.25, 1.0)

func _sync_aura_texture() -> void:
	var mat := anim_sprite.material_overlay as ShaderMaterial
	if mat == null or anim_sprite.sprite_frames == null:
		return
	if not anim_sprite.sprite_frames.has_animation(anim_sprite.animation):
		return
	var frame_count := anim_sprite.sprite_frames.get_frame_count(anim_sprite.animation)
	if frame_count <= 0:
		return
	var tex := anim_sprite.sprite_frames.get_frame_texture(anim_sprite.animation, clampi(anim_sprite.frame, 0, frame_count - 1))
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
	

func play_anim(anim_name: String) -> void:
	if anim_sprite.sprite_frames and anim_sprite.sprite_frames.has_animation(anim_name):
		anim_sprite.play(anim_name)


func play_idle(): play_anim("Idle")
func play_walk(): play_anim("Walk")
func play_attack(): play_anim("Attack")
func play_hurt(): play_anim("Hurt")
func play_dead(): play_anim("Dead")



func _on_health_changed(_current: int, _maximum: int) -> void:
	if _current <= 0:
		return
	play_hurt()
	if anim_sprite.material_overlay != null:
		_sync_aura_texture()
		anim_sprite.material_overlay.set_shader_parameter("hit_flash", true)
		await get_tree().create_timer(0.18).timeout
		if is_instance_valid(anim_sprite) and anim_sprite.material_overlay != null:
			anim_sprite.material_overlay.set_shader_parameter("hit_flash", false)
			
	var tween := create_tween()
	tween.tween_property(anim_sprite, "position:x", 0.3, 0.05).set_trans(Tween.TRANS_SINE)
	tween.tween_property(anim_sprite, "position:x", 0.0, 0.1).set_trans(Tween.TRANS_SPRING)

func _on_animation_finished() -> void:
	if anim_sprite.animation in ["Attack", "Hurt"] and health_component.current_hp > 0:
		play_idle()


func face_target(target_global_pos: Vector3) -> void:
	var look_pos = Vector3(target_global_pos.x, global_position.y, target_global_pos.z)
	look_at(look_pos, Vector3.UP)
	#rotate_y(PI)

func pulse_intro_light(color: Color, peak_energy: float = 5.5, hold_time: float = 0.9) -> void:
	if intro_light == null:
		return
	intro_light.light_color = color
	var tween := create_tween()
	tween.tween_property(intro_light, "light_energy", peak_energy, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_interval(hold_time)
	tween.tween_property(intro_light, "light_energy", 0.0, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
