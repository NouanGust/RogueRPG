extends RefCounted

const ATTACK_UNLOCK_INTERVAL := 3
const ELITE_ENCOUNTER_INTERVAL := 5

# Costs grow while encounter XP remains tied to the enemy, not player level.
static func xp_required(level: int) -> int:
	return 30 + 15 * (maxi(1, level) - 1)

static func should_offer_attack_unlock(level: int) -> bool:
	return level >= ATTACK_UNLOCK_INTERVAL and level % ATTACK_UNLOCK_INTERVAL == 0

static func is_elite_encounter(encounters_won: int) -> bool:
	return (encounters_won + 1) % ELITE_ENCOUNTER_INTERVAL == 0

static func encounter_xp(base_reward: int) -> int:
	return maxi(1, base_reward)

static func coin_bonus(level: int) -> int:
	return mini(3, int((maxi(1, level) - 1) / 5))

static func coin_reward(level: int) -> int:
	return randi_range(2, 4) + coin_bonus(level)
