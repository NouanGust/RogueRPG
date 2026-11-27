class_name Projectile3D
extends Node3D

signal impacted

@onready var anim_sprite: AnimatedSprite3D = $AnimSprite
@onready var glow_light: OmniLight3D = $GlowLight

@export var default_speed: float = 8.0
@export var default_fps: float = 16.0
@export var default_scale: float = 0.85

var _start_pos: Vector3
var _target_pos: Vector3
var _duration: float = 0.3
var _elapsed: float = 0.0
var _arc_height: float = 0.0
var _in_flight: bool = false
var _has_impact_anim: bool = false

func _ready() -> void:
	anim_sprite.animation_finished.connect(_on_animation_finished)

func launch(start_pos: Vector3, target_pos: Vector3, config: Dictionary = {}) -> void:
	global_position = start_pos
	_start_pos = start_pos
	_target_pos = target_pos
	_elapsed = 0.0

	var speed: float = maxf(0.5, float(config.get("speed", default_speed)))
	var distance := start_pos.distance_to(target_pos)
	_duration = maxf(0.08, distance / speed)
	_arc_height = float(config.get("arc_height", 0.0))

	var texture: Texture2D = config.get("texture", null)
	var frame_size: Vector2i = config.get("frame_size", Vector2i(64, 64))
	var flight_frames: int = maxi(1, int(config.get("flight_frames", 1)))
	var impact_frames: int = maxi(0, int(config.get("impact_frames", 0)))
	var fps: float = float(config.get("fps", default_fps))
	var scale_mult: float = float(config.get("scale", default_scale))
	var tint: Color = config.get("color", Color.WHITE)
	var flip_h: bool = bool(config.get("flip_h", false))

	anim_sprite.scale = Vector3.ONE * scale_mult
	anim_sprite.modulate = tint
	anim_sprite.flip_h = flip_h

	if config.has("sprite_frames") and config["sprite_frames"] is SpriteFrames:
		anim_sprite.sprite_frames = config["sprite_frames"]
		_has_impact_anim = anim_sprite.sprite_frames.has_animation("impact")
	elif texture != null:
		anim_sprite.sprite_frames = _build_sprite_frames(texture, frame_size, flight_frames, impact_frames, fps)
		_has_impact_anim = impact_frames > 0
	else:
		_has_impact_anim = false

	# Luz sutil para projéteis mágicos (desligada se cor for branca padrão ou light_energy == 0)
	var light_energy: float = float(config.get("light_energy", 1.2 if tint != Color.WHITE else 0.0))
	glow_light.light_color = tint
	glow_light.light_energy = light_energy

	if anim_sprite.sprite_frames and anim_sprite.sprite_frames.has_animation("fly"):
		anim_sprite.play("fly")

	_in_flight = true

func _process(delta: float) -> void:
	if not _in_flight:
		return

	_elapsed += delta
	var t := clampf(_elapsed / _duration, 0.0, 1.0)
	var pos := _start_pos.lerp(_target_pos, t)
	if _arc_height != 0.0:
		pos.y += sin(t * PI) * _arc_height
	global_position = pos

	if t >= 1.0:
		_on_reach_target()

func _on_reach_target() -> void:
	_in_flight = false
	global_position = _target_pos
	impacted.emit()

	if _has_impact_anim and anim_sprite.sprite_frames and anim_sprite.sprite_frames.has_animation("impact"):
		anim_sprite.play("impact")
	else:
		queue_free()

func _on_animation_finished() -> void:
	if not _in_flight and anim_sprite.animation == "impact":
		queue_free()

func _build_sprite_frames(
	sheet: Texture2D,
	frame_size: Vector2i,
	flight_count: int,
	impact_count: int,
	fps: float
) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.add_animation("fly")
	frames.set_animation_loop("fly", true)
	frames.set_animation_speed("fly", maxf(1.0, fps))

	var fw := maxi(1, frame_size.x)
	var fh := maxi(1, frame_size.y)
	var tex_w := sheet.get_width()
	var tex_h := sheet.get_height()
	var total_cols := maxi(1, int(tex_w / float(fw)))

	var clamped_flight := mini(flight_count, total_cols)
	for i in range(clamped_flight):
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(i * fw, 0, mini(fw, tex_w), mini(fh, tex_h))
		frames.add_frame("fly", atlas)

	if impact_count > 0 and clamped_flight < total_cols:
		frames.add_animation("impact")
		frames.set_animation_loop("impact", false)
		frames.set_animation_speed("impact", maxf(1.0, fps * 1.25))
		var impact_end := mini(total_cols, clamped_flight + impact_count)
		for i in range(clamped_flight, impact_end):
			var atlas := AtlasTexture.new()
			atlas.atlas = sheet
			atlas.region = Rect2(i * fw, 0, mini(fw, tex_w), mini(fh, tex_h))
			frames.add_frame("impact", atlas)

	return frames
