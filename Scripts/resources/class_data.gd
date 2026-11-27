class_name ClassData
extends Resource

@export var id: StringName
@export var display_name: String
@export var sprite: SpriteFrames

@export_group("Base Stats")
@export var base_hp: int = 10
@export var base_attack: int = 1
@export var base_defense: int = 0
@export_enum("strength", "intelligence", "faith", "agility") var main_attribute: String

@export_group("Dado por atributo")
@export var strength_dice: int = 6
@export var intelligence_dice: int = 6
@export var faith_dice: int = 6
@export var agility_dice: int = 6

@export_group("Ataque Visual")
@export_enum("melee", "ranged") var attack_style: String = "melee"
@export var slash_texture: Texture2D
@export_range(0, 7) var slash_palette: int = 7
@export var projectile_texture: Texture2D
@export var projectile_frame_size: Vector2i = Vector2i(64, 64)
@export var projectile_flight_frames: int = 1
@export var projectile_impact_frames: int = 0
@export var projectile_speed: float = 8.0
@export var projectile_arc_height: float = 0.0
@export var projectile_color: Color = Color(1, 1, 1, 1)

@export_group("Ataques Disponíveis (4)")
@export var attacks: Array[AttackData] = []
@export var unlockable_attacks: Array[AttackData] = []
