class_name SlashEffect3D
extends Node3D

const DEFAULT_SLASH_TEXTURE: Texture2D = preload("res://Assets/2D/Part 1/01.png")
const FRAME_SIZE := 48
const FRAMES_PER_PALETTE := 10
const PALETTES_PER_ROW := 4

@onready var anim_sprite: AnimatedSprite3D = $AnimSprite

@export var slash_texture: Texture2D = DEFAULT_SLASH_TEXTURE
@export_range(0, 7) var palette_index: int = 7
@export var fps: float = 24.0
@export var effect_scale: float = 1.6
@export var flip_horizontal: bool = false

var _configured: bool = false

func _ready() -> void:
	anim_sprite.animation_finished.connect(_on_animation_finished)
	if not _configured:
		play_effect(slash_texture, palette_index, fps, effect_scale, flip_horizontal)

func play_effect(
	texture: Texture2D = null,
	palette: int = 7,
	speed_fps: float = 24.0,
	scale_mult: float = 1.6,
	flip_h: bool = false
) -> void:
	_configured = true
	var sheet: Texture2D = texture if texture != null else DEFAULT_SLASH_TEXTURE
	var clamped_palette := clampi(palette, 0, 7)
	var sprite_frames := _build_sprite_frames(sheet, clamped_palette, speed_fps)
	anim_sprite.sprite_frames = sprite_frames
	anim_sprite.flip_h = flip_h
	anim_sprite.scale = Vector3.ONE * scale_mult
	anim_sprite.play("slash")

func _build_sprite_frames(sheet: Texture2D, palette: int, speed_fps: float) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.add_animation("slash")
	frames.set_animation_loop("slash", false)
	frames.set_animation_speed("slash", maxf(1.0, speed_fps))

	var row := int(palette / float(PALETTES_PER_ROW))
	var col_group := palette % PALETTES_PER_ROW
	var start_x := col_group * FRAMES_PER_PALETTE * FRAME_SIZE
	var start_y := row * FRAME_SIZE
	var tex_w := sheet.get_width()
	var tex_h := sheet.get_height()

	# Suporta spritesheets 1920x96 (Part 1..5) ou qualquer tira horizontal 48x48
	if tex_w >= start_x + FRAMES_PER_PALETTE * FRAME_SIZE and tex_h >= start_y + FRAME_SIZE:
		for i in range(FRAMES_PER_PALETTE):
			var atlas := AtlasTexture.new()
			atlas.atlas = sheet
			atlas.region = Rect2(start_x + i * FRAME_SIZE, start_y, FRAME_SIZE, FRAME_SIZE)
			frames.add_frame("slash", atlas)
	else:
		var frame_h := mini(FRAME_SIZE, tex_h)
		var count := maxi(1, int(tex_w / maxf(1, frame_h)))
		for i in range(count):
			var atlas := AtlasTexture.new()
			atlas.atlas = sheet
			atlas.region = Rect2(i * frame_h, 0, frame_h, frame_h)
			frames.add_frame("slash", atlas)

	return frames

func _on_animation_finished() -> void:
	queue_free()
