extends RefCounted

# Costs grow while encounter XP remains tied to the enemy, not player level.
static func xp_required(level: int) -> int:
	return 30 + 15 * (maxi(1, level) - 1)

static func encounter_xp(base_reward: int) -> int:
	return maxi(1, base_reward)

static func coin_bonus(level: int) -> int:
	return mini(3, int((maxi(1, level) - 1) / 5))

static func coin_reward(level: int) -> int:
	return randi_range(2, 4) + coin_bonus(level)
