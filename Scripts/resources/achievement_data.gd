class_name AchievementData
extends Resource

@export var id: StringName = &""
@export var title: String = ""
@export_multiline var description: String = ""
@export_enum("elite_defeat", "all_elites", "milestone") var category: String = "elite_defeat"
@export var target_id: StringName = &""
@export var required_count: int = 1
@export var icon: Texture2D
