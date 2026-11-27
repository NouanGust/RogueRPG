class_name EnemyData
extends Resource

@export var id: StringName
@export var display_name: String
@export var sprite_frames: SpriteFrames

@export_group("Base Stats")
@export var base_hp: int = 15
@export var base_attack: int = 1
@export var base_defense: int = 0
@export var xp_reward: int = 10

@export_group("Dado por atributo")
@export var stats_dice: int = 4

@export_group("Ataque Visual")
@export_enum("melee", "ranged") var attack_style: String = "melee"
@export var slash_texture: Texture2D
@export_range(0, 7) var slash_palette: int = 4
@export var projectile_texture: Texture2D
@export var projectile_frame_size: Vector2i = Vector2i(64, 64)
@export var projectile_flight_frames: int = 1
@export var projectile_impact_frames: int = 0
@export var projectile_speed: float = 8.0
@export var projectile_arc_height: float = 0.0
@export var projectile_color: Color = Color(1, 1, 1, 1)

@export_group("Ataques do Inimigo")
@export var attacks: Array[AttackData] = []
