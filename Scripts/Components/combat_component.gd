class_name CombatComponent
extends Node

signal attacked(raw_damage: int, final_damage: int)

@export var stats_component: StatsComponent
@export var health_component: HealthComponent

func attack(target_stats: StatsComponent, target_health: HealthComponent) -> int:
	var raw_damage := stats_component.get_value("attack")
	var defense := target_stats.get_value("defense")
	var final_damage: int = max(1, raw_damage - defense)
	attacked.emit(raw_damage, final_damage)
	target_health.take_damage(final_damage)
	return final_damage

func execute_attack(attack_data: AttackData, target_stats: StatsComponent, target_health: HealthComponent) -> Dictionary:
	if attack_data == null:
		var dmg := attack(target_stats, target_health)
		return {"hit": true, "type": "damage", "amount": dmg}

	if attack_data.accuracy < 100 and randi_range(1, 100) > attack_data.accuracy:
		return {"hit": false, "type": attack_data.effect_type, "amount": 0}

	match attack_data.effect_type:
		"heal":
			var main_key := stats_component.primary_stat if stats_component.primary_stat != "" else "attack"
			var main_val := stats_component.get_value(main_key)
			var heal_amount := maxi(1, roundi(main_val * attack_data.power_multiplier) + attack_data.flat_bonus)
			health_component.heal(heal_amount)
			var res := {"hit": true, "type": "heal", "amount": heal_amount}
			if attack_data.buff_stat != "" and attack_data.buff_stat != "none" and attack_data.buff_amount > 0:
				stats_component.apply_buff(attack_data.buff_stat, attack_data.buff_amount, maxi(1, attack_data.buff_turns))
				res["buff_stat"] = attack_data.buff_stat
				res["buff_amount"] = attack_data.buff_amount
				res["buff_turns"] = maxi(1, attack_data.buff_turns)
			return res
		"buff":
			var has_buff_stat := attack_data.buff_stat != "" and attack_data.buff_stat != "none"
			var stat_key := attack_data.buff_stat if has_buff_stat else (stats_component.primary_stat if stats_component.primary_stat != "" else "attack")
			var amount := maxi(1, attack_data.buff_amount)
			var turns := maxi(1, attack_data.buff_turns)
			stats_component.apply_buff(stat_key, amount, turns)
			return {"hit": true, "type": "buff", "amount": amount, "buff_stat": stat_key, "buff_turns": turns}
		"debuff":
			var debuff_key := _resolve_target_stat(attack_data.debuff_stat, target_stats)
			var debuff_val := maxi(1, attack_data.debuff_amount)
			var debuff_turns := maxi(1, attack_data.debuff_turns)
			target_stats.apply_debuff(debuff_key, debuff_val, debuff_turns)
			return {"hit": true, "type": "debuff", "amount": debuff_val, "debuff_stat": debuff_key, "debuff_turns": debuff_turns}
		"damage_debuff":
			var final_dmg := _deal_scaled_damage(attack_data, target_stats, target_health)
			var debuff_key := _resolve_target_stat(attack_data.debuff_stat, target_stats)
			var debuff_val := maxi(1, attack_data.debuff_amount)
			var debuff_turns := maxi(1, attack_data.debuff_turns)
			target_stats.apply_debuff(debuff_key, debuff_val, debuff_turns)
			return {
				"hit": true,
				"type": "damage_debuff",
				"amount": final_dmg,
				"debuff_stat": debuff_key,
				"debuff_amount": debuff_val,
				"debuff_turns": debuff_turns,
			}
		"drain":
			var final_dmg := _deal_scaled_damage(attack_data, target_stats, target_health)
			var healed := maxi(1, roundi(final_dmg * maxf(0.1, attack_data.drain_ratio)))
			health_component.heal(healed)
			return {"hit": true, "type": "drain", "amount": final_dmg, "heal_amount": healed}
		_:
			var final_dmg := _deal_scaled_damage(attack_data, target_stats, target_health)
			return {"hit": true, "type": "damage", "amount": final_dmg}

func _deal_scaled_damage(attack_data: AttackData, target_stats: StatsComponent, target_health: HealthComponent) -> int:
	var base_raw := stats_component.get_value("attack")
	var scaled_raw := roundi(base_raw * attack_data.power_multiplier) + attack_data.flat_bonus
	var raw_defense := target_stats.get_value("defense")
	var effective_defense := roundi(raw_defense * (1.0 - clampf(attack_data.ignore_defense_ratio, 0.0, 1.0)))
	var final_damage: int = maxi(1, scaled_raw - effective_defense)
	attacked.emit(scaled_raw, final_damage)
	target_health.take_damage(final_damage)
	return final_damage

func _resolve_target_stat(stat_name: String, target_stats: StatsComponent) -> String:
	if stat_name == "" or stat_name == "none" or stat_name == "primary_stat":
		return target_stats.primary_stat if target_stats.primary_stat != "" else "attack"
	return stat_name
