class_name RewardManager
extends Node


signal reward_applied(reward: RewardData)
signal modifiers_changed
signal weapon_unlocked(weapon_id: String)
signal weapon_tier_changed(weapon_id: String, new_tier: int)
signal weapon_slots_changed(new_slot_count: int)


@export_group("Reward Pools")
@export var level_up_rewards: Array[RewardData] = []
@export var boss_rewards: Array[RewardData] = []


@export_group("Starting Loadout")
@export var starting_unlocked_weapons: Array[String] = [
	"turret"
]

@export var starting_equipped_weapons: Array[String] = [
	"turret"
]

@export var starting_weapon_slots: int = 1


# -------------------------------------------------------------------
# Global run modifiers
# -------------------------------------------------------------------

var global_damage_multiplier: float = 1.0
var boss_damage_multiplier: float = 1.0
var global_attack_speed_multiplier: float = 1.0

var critical_chance: float = 0.0
var critical_damage_multiplier: float = 1.5

var ability_cooldown_multiplier: float = 1.0

var dot_xp_multiplier: float = 1.0
var boss_xp_multiplier: float = 1.0

var maximum_weapon_slots: int = 6


# -------------------------------------------------------------------
# Weapon-specific modifier storage
# -------------------------------------------------------------------

var weapon_damage_multipliers: Dictionary = {}
var weapon_attack_speed_multipliers: Dictionary = {}
var weapon_range_multipliers: Dictionary = {}

var weapon_tiers: Dictionary = {}

var unlocked_weapons: Array[String] = []
var equipped_weapons: Array[String] = []

var obtained_reward_stacks: Dictionary = {}


func _ready() -> void:
	reset_run_modifiers()


# ===================================================================
# RESET
# ===================================================================

func reset_run_modifiers() -> void:
	global_damage_multiplier = 1.0
	boss_damage_multiplier = 1.0
	global_attack_speed_multiplier = 1.0

	critical_chance = 0.0
	critical_damage_multiplier = 1.5

	ability_cooldown_multiplier = 1.0

	dot_xp_multiplier = 1.0
	boss_xp_multiplier = 1.0

	maximum_weapon_slots = maxi(starting_weapon_slots, 1)

	weapon_damage_multipliers.clear()
	weapon_attack_speed_multipliers.clear()
	weapon_range_multipliers.clear()
	weapon_tiers.clear()

	obtained_reward_stacks.clear()
	unlocked_weapons.clear()
	equipped_weapons.clear()

	for weapon_id: String in starting_unlocked_weapons:
		if weapon_id.is_empty():
			continue

		if not unlocked_weapons.has(weapon_id):
			unlocked_weapons.append(weapon_id)

		_ensure_weapon_data_exists(weapon_id)

	for weapon_id: String in starting_equipped_weapons:
		if weapon_id.is_empty():
			continue

		if not unlocked_weapons.has(weapon_id):
			unlocked_weapons.append(weapon_id)

		if not equipped_weapons.has(weapon_id):
			equipped_weapons.append(weapon_id)

		_ensure_weapon_data_exists(weapon_id)

	modifiers_changed.emit()


# ===================================================================
# REWARD GENERATION
# ===================================================================

func generate_level_up_choices(
	count: int = 3,
	excluded_rewards: Array[RewardData] = []
) -> Array[RewardData]:
	return _generate_choices(
		level_up_rewards,
		count,
		excluded_rewards
	)


func generate_boss_choices(
	count: int = 3,
	excluded_rewards: Array[RewardData] = []
) -> Array[RewardData]:
	return _generate_choices(
		boss_rewards,
		count,
		excluded_rewards
	)


func _generate_choices(
	source_pool: Array[RewardData],
	count: int,
	excluded_rewards: Array[RewardData]
) -> Array[RewardData]:
	var valid_pool: Array[RewardData] = []

	for reward: RewardData in source_pool:
		if reward == null:
			continue

		if excluded_rewards.has(reward):
			continue

		if not _is_reward_valid(reward):
			continue

		valid_pool.append(reward)

	valid_pool.shuffle()

	var choices: Array[RewardData] = []
	var choice_count: int = mini(
		maxi(count, 0),
		valid_pool.size()
	)

	for index: int in choice_count:
		choices.append(valid_pool[index])

	return choices


func _is_reward_valid(reward: RewardData) -> bool:
	if reward == null:
		return false

	if reward.reward_id.is_empty():
		return false

	var current_stacks: int = get_reward_stack_count(
		reward.reward_id
	)

	if reward.maximum_stacks > 0:
		if current_stacks >= reward.maximum_stacks:
			return false

	if reward.requires_equipped_weapon:
		var required_weapon: String = reward.required_weapon_id

		if required_weapon.is_empty():
			required_weapon = reward.weapon_id

		if required_weapon.is_empty():
			return false

		if not equipped_weapons.has(required_weapon):
			return false

		if reward.minimum_weapon_tier > 0:
			var current_tier: int = get_weapon_tier(
				required_weapon
			)

			if current_tier < reward.minimum_weapon_tier:
				return false

	match reward.reward_type:
		RewardData.RewardType.NEW_WEAPON:
			# Phase 1 weapon types are unlocked through Prestige, not run rewards.
			return false
		RewardData.RewardType.WEAPON_SLOT:
			# Phase 1 supports exactly one active weapon type.
			return false

		RewardData.RewardType.WEAPON_UPGRADE:
			if reward.weapon_id.is_empty():
				return false

			if not equipped_weapons.has(reward.weapon_id):
				return false

		RewardData.RewardType.WEAPON_TIER:
			if reward.weapon_id.is_empty():
				return false

			if not equipped_weapons.has(reward.weapon_id):
				return false

			var current_tier: int = get_weapon_tier(
				reward.weapon_id
			)

			if reward.tier <= current_tier:
				return false

		_:
			pass

	return true


# ===================================================================
# APPLY REWARDS
# ===================================================================

func apply_reward(reward: RewardData) -> bool:
	if reward == null:
		return false

	if reward.reward_id.is_empty():
		push_warning(
			"RewardManager: Reward has no reward_id."
		)
		return false

	var current_stacks: int = get_reward_stack_count(
		reward.reward_id
	)

	if reward.maximum_stacks > 0:
		if current_stacks >= reward.maximum_stacks:
			return false

	var applied: bool = false

	match reward.reward_type:
		RewardData.RewardType.PASSIVE:
			applied = _apply_passive_reward(reward)

		RewardData.RewardType.ABILITY:
			applied = _apply_ability_reward(reward)

		RewardData.RewardType.WEAPON_UPGRADE:
			applied = _apply_weapon_upgrade(reward)

		RewardData.RewardType.NEW_WEAPON:
			applied = _unlock_weapon(reward.weapon_id)

		RewardData.RewardType.WEAPON_TIER:
			applied = _apply_weapon_tier(reward)

		RewardData.RewardType.WEAPON_SLOT:
			applied = _apply_weapon_slot(reward)

	if not applied:
		return false

	obtained_reward_stacks[reward.reward_id] = (
		current_stacks + 1
	)

	reward_applied.emit(reward)
	modifiers_changed.emit()

	return true


func _apply_passive_reward(reward: RewardData) -> bool:
	var primary_applied: bool = _apply_stat(
		reward.stat_id,
		reward.primary_value,
		reward
	)

	var secondary_applied: bool = false

	if not reward.secondary_stat_id.is_empty():
		secondary_applied = _apply_stat(
			reward.secondary_stat_id,
			reward.secondary_value,
			reward
		)

	return primary_applied or secondary_applied


func _apply_ability_reward(reward: RewardData) -> bool:
	var primary_applied: bool = false
	var secondary_applied: bool = false

	if not reward.stat_id.is_empty():
		primary_applied = _apply_stat(
			reward.stat_id,
			reward.primary_value,
			reward
		)

	if not reward.secondary_stat_id.is_empty():
		secondary_applied = _apply_stat(
			reward.secondary_stat_id,
			reward.secondary_value,
			reward
		)

	return primary_applied or secondary_applied


func _apply_weapon_upgrade(reward: RewardData) -> bool:
	if reward.weapon_id.is_empty():
		return false

	if not equipped_weapons.has(reward.weapon_id):
		return false

	_ensure_weapon_data_exists(reward.weapon_id)

	var primary_applied: bool = _apply_stat(
		reward.stat_id,
		reward.primary_value,
		reward
	)

	var secondary_applied: bool = false

	if not reward.secondary_stat_id.is_empty():
		secondary_applied = _apply_stat(
			reward.secondary_stat_id,
			reward.secondary_value,
			reward
		)

	return primary_applied or secondary_applied


func _apply_weapon_tier(reward: RewardData) -> bool:
	if reward.weapon_id.is_empty():
		return false

	if not equipped_weapons.has(reward.weapon_id):
		return false

	var current_tier: int = get_weapon_tier(
		reward.weapon_id
	)

	var new_tier: int = maxi(
		reward.tier,
		current_tier + 1
	)

	weapon_tiers[reward.weapon_id] = new_tier

	if not reward.stat_id.is_empty():
		_apply_stat(
			reward.stat_id,
			reward.primary_value,
			reward
		)

	if not reward.secondary_stat_id.is_empty():
		_apply_stat(
			reward.secondary_stat_id,
			reward.secondary_value,
			reward
		)

	weapon_tier_changed.emit(
		reward.weapon_id,
		new_tier
	)

	return true


func _apply_weapon_slot(reward: RewardData) -> bool:
	var slot_increase: int = maxi(
		roundi(reward.primary_value),
		1
	)

	maximum_weapon_slots += slot_increase

	weapon_slots_changed.emit(
		maximum_weapon_slots
	)

	return true


func _unlock_weapon(weapon_id: String) -> bool:
	if weapon_id.is_empty():
		return false

	if unlocked_weapons.has(weapon_id):
		return false

	if equipped_weapons.size() >= maximum_weapon_slots:
		return false

	unlocked_weapons.append(weapon_id)
	equipped_weapons.append(weapon_id)

	_ensure_weapon_data_exists(weapon_id)

	weapon_unlocked.emit(weapon_id)

	return true


# ===================================================================
# STAT APPLICATION
# ===================================================================

func _apply_stat(
	stat_id: String,
	value: float,
	reward: RewardData
) -> bool:
	if stat_id.is_empty():
		return false

	match stat_id:
		"global_damage_multiplier":
			global_damage_multiplier += value
			return true

		"boss_damage_multiplier":
			boss_damage_multiplier += value
			return true

		"global_attack_speed_multiplier":
			global_attack_speed_multiplier += value
			return true

		"critical_chance":
			critical_chance = clampf(
				critical_chance + value,
				0.0,
				1.0
			)
			return true

		"critical_damage_multiplier":
			critical_damage_multiplier += value
			return true

		"ability_cooldown_reduction":
			ability_cooldown_multiplier = maxf(
				0.20,
				ability_cooldown_multiplier - value
			)
			return true

		"dot_xp_multiplier":
			dot_xp_multiplier += value
			return true

		"boss_xp_multiplier":
			boss_xp_multiplier += value
			return true

		"maximum_weapon_slots":
			maximum_weapon_slots += maxi(
				roundi(value),
				1
			)

			weapon_slots_changed.emit(
				maximum_weapon_slots
			)
			return true

		"weapon_damage_multiplier":
			return _add_weapon_dictionary_value(
				weapon_damage_multipliers,
				reward.weapon_id,
				value
			)

		"weapon_attack_speed_multiplier":
			return _add_weapon_dictionary_value(
				weapon_attack_speed_multipliers,
				reward.weapon_id,
				value
			)

		"weapon_range_multiplier":
			return _add_weapon_dictionary_value(
				weapon_range_multipliers,
				reward.weapon_id,
				value
			)

		"tesla_chain_range_multiplier":
			return _add_weapon_dictionary_value(
				weapon_range_multipliers,
				"tesla_coil",
				value
			)

		"tesla_chain_damage_multiplier":
			return _add_weapon_dictionary_value(
				weapon_damage_multipliers,
				"tesla_coil",
				value
			)

		"turret_tier":
			return true

		"railgun_tier":
			return true

		_:
			push_warning(
				"RewardManager: Unknown stat_id: "
				+ stat_id
			)
			return false


func _add_weapon_dictionary_value(
	dictionary: Dictionary,
	weapon_id: String,
	value: float
) -> bool:
	if weapon_id.is_empty():
		return false

	_ensure_weapon_data_exists(weapon_id)

	var current_value: float = float(
		dictionary.get(weapon_id, 1.0)
	)

	dictionary[weapon_id] = current_value + value

	return true


func _ensure_weapon_data_exists(
	weapon_id: String
) -> void:
	if weapon_id.is_empty():
		return

	if not weapon_damage_multipliers.has(weapon_id):
		weapon_damage_multipliers[weapon_id] = 1.0

	if not weapon_attack_speed_multipliers.has(weapon_id):
		weapon_attack_speed_multipliers[weapon_id] = 1.0

	if not weapon_range_multipliers.has(weapon_id):
		weapon_range_multipliers[weapon_id] = 1.0

	if not weapon_tiers.has(weapon_id):
		weapon_tiers[weapon_id] = 1


# ===================================================================
# PUBLIC GETTERS
# ===================================================================

func get_reward_stack_count(
	reward_id: String
) -> int:
	return int(
		obtained_reward_stacks.get(reward_id, 0)
	)


func get_weapon_tier(
	weapon_id: String
) -> int:
	return int(
		weapon_tiers.get(weapon_id, 1)
	)


func get_weapon_damage_multiplier(
	weapon_id: String
) -> float:
	return float(
		weapon_damage_multipliers.get(
			weapon_id,
			1.0
		)
	)


func get_weapon_attack_speed_multiplier(
	weapon_id: String
) -> float:
	return float(
		weapon_attack_speed_multipliers.get(
			weapon_id,
			1.0
		)
	)


func get_weapon_range_multiplier(
	weapon_id: String
) -> float:
	return float(
		weapon_range_multipliers.get(
			weapon_id,
			1.0
		)
	)


func is_weapon_unlocked(
	weapon_id: String
) -> bool:
	return unlocked_weapons.has(weapon_id)


func is_weapon_equipped(
	weapon_id: String
) -> bool:
	return equipped_weapons.has(weapon_id)
