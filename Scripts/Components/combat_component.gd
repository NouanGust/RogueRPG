extends Node
class_name CombatComponent

@export var stats_component: StatsComponent
@export var dice_roller: DiceRoller

func basic_attack(target_stats: StatsComponent, attack_type: String = "physical") -> Dictionary:
	var base_damage := 0

	match attack_type:
		"physical":
			base_damage = stats_component.strength + dice_roller.roll_range(1, 6)
		"magic":
			base_damage = stats_component.intelligence + dice_roller.roll_range(1, 6)
		_:
			base_damage = 1

	var was_critical := dice_roller.roll_percentage(stats_component.luck * 2.0)
	if was_critical:
		base_damage *= 2

	var final_damage := target_stats.receive_damage(base_damage)

	return {
		"damage": final_damage,
		"critical": was_critical,
		"attack_type": attack_type
	}

func try_escape(enemy_level: int) -> bool:
	var chance := 35.0 + (stats_component.luck * 3.0) - (enemy_level * 2.0)
	chance = clamp(chance, 10.0, 85.0)
	return dice_roller.roll_percentage(chance)
