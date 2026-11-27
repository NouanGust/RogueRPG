extends Node

signal achievement_unlocked(achievement: AchievementData)

const ACHIEVEMENT_PATHS: Array[String] = [
	"res://Scripts/resources/Achievements/elite_werewolf.tres",
	"res://Scripts/resources/Achievements/elite_gorgon.tres",
	"res://Scripts/resources/Achievements/elite_yamabushi_tengu.tres",
	"res://Scripts/resources/Achievements/elite_karasu_tengu.tres",
	"res://Scripts/resources/Achievements/all_elites.tres",
]

var _achievements: Array[AchievementData] = []
var _by_id: Dictionary = {}

func _ready() -> void:
	_load_achievements()

func _load_achievements() -> void:
	_achievements.clear()
	_by_id.clear()
	for path in ACHIEVEMENT_PATHS:
		if ResourceLoader.exists(path):
			var res := load(path) as AchievementData
			if res != null and res.id != &"":
				_achievements.append(res)
				_by_id[String(res.id)] = res

func get_all_achievements() -> Array[AchievementData]:
	return _achievements

func get_achievement(achievement_id: StringName) -> AchievementData:
	return _by_id.get(String(achievement_id), null) as AchievementData

func is_unlocked(achievement_id: StringName) -> bool:
	return String(achievement_id) in SaveManager.get_unlocked_achievements()

func has_defeated_elite(elite_id: StringName) -> bool:
	return String(elite_id) in SaveManager.get_defeated_elites()

func get_progress_summary() -> Dictionary:
	var unlocked_list := SaveManager.get_unlocked_achievements()
	var valid_unlocked := 0
	for ach in _achievements:
		if String(ach.id) in unlocked_list:
			valid_unlocked += 1
	return {
		"unlocked": valid_unlocked,
		"total": _achievements.size(),
	}

func record_enemy_defeat(enemy_data: EnemyData) -> Array[AchievementData]:
	var newly_unlocked: Array[AchievementData] = []
	if enemy_data == null or not enemy_data.is_elite:
		return newly_unlocked

	var elite_key := String(enemy_data.id)
	if elite_key.is_empty():
		return newly_unlocked

	var unlocked := SaveManager.get_unlocked_achievements()
	var defeated_elites := SaveManager.get_defeated_elites()
	var dirty := false

	if elite_key not in defeated_elites:
		defeated_elites.append(elite_key)
		dirty = true

	for ach in _achievements:
		var ach_key := String(ach.id)
		if ach_key in unlocked:
			continue
		if _matches_elite_rule(ach, elite_key, defeated_elites):
			unlocked.append(ach_key)
			newly_unlocked.append(ach)
			dirty = true

	if dirty:
		SaveManager.save_achievements(unlocked, defeated_elites)

	for ach in newly_unlocked:
		achievement_unlocked.emit(ach)

	return newly_unlocked

func unlock(achievement_id: StringName) -> bool:
	var ach := get_achievement(achievement_id)
	if ach == null:
		return false
	var ach_key := String(ach.id)
	var unlocked := SaveManager.get_unlocked_achievements()
	if ach_key in unlocked:
		return false
	unlocked.append(ach_key)
	var defeated_elites := SaveManager.get_defeated_elites()
	if not SaveManager.save_achievements(unlocked, defeated_elites):
		return false
	achievement_unlocked.emit(ach)
	return true

func _matches_elite_rule(ach: AchievementData, elite_key: String, defeated_elites: Array[String]) -> bool:
	match ach.category:
		"elite_defeat":
			return String(ach.target_id) == elite_key
		"all_elites":
			return defeated_elites.size() >= maxi(1, ach.required_count)
		_:
			return false
