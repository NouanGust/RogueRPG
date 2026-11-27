class_name AttackData
extends Resource

@export var id: StringName
@export var display_name: String = "Ataque"
@export_multiline var description: String = ""

@export_group("Efeito")
@export_enum("damage", "heal", "buff", "debuff", "damage_debuff", "drain") var effect_type: String = "damage"
@export var power_multiplier: float = 1.0
@export var flat_bonus: int = 0
@export_range(1, 100) var accuracy: int = 100
## 0 significa usos ilimitados por batalha
@export var max_uses: int = 0
@export_range(0.0, 1.0) var ignore_defense_ratio: float = 0.0
@export_range(0.0, 1.0) var drain_ratio: float = 0.0

@export_group("Buff")
@export_enum("none", "attack", "defense", "strength", "intelligence", "faith", "agility") var buff_stat: String = "none"
@export var buff_amount: int = 0
@export var buff_turns: int = 2

@export_group("Debuff")
@export_enum("none", "attack", "defense", "strength", "intelligence", "faith", "agility", "primary_stat") var debuff_stat: String = "none"
@export var debuff_amount: int = 0
@export var debuff_turns: int = 2

@export_group("Visual")
@export_enum("melee", "ranged", "self") var attack_style: String = "melee"
@export var slash_texture: Texture2D
@export_range(0, 7) var slash_palette: int = 7
@export var projectile_texture: Texture2D
@export var projectile_frame_size: Vector2i = Vector2i(64, 64)
@export var projectile_flight_frames: int = 1
@export var projectile_impact_frames: int = 0
@export var projectile_speed: float = 8.0
@export var projectile_arc_height: float = 0.0
@export var projectile_color: Color = Color(1, 1, 1, 1)
