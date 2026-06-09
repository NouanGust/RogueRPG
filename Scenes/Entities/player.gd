extends Node2D

@onready var stats: StatsComponent = $StatsComponent
@onready var combat: CombatComponent = $CombatComponent
@onready var inventory: InventoryComponent = $InventoryComponent
@onready var rewards: RewardComponent = $RewardComponent

func _ready() -> void:
	stats.setup(GameState.current_class.class_name, GameState.current_stats)
