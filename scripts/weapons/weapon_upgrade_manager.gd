class_name WeaponUpgradeManager
extends Node


signal weapon_registered(weapon_id: StringName)
signal weapon_level_changed(weapon_id: StringName, new_level: int)
signal weapon_tier_changed(weapon_id: StringName, new_tier: int)
signal weapon_stats_changed(weapon_id: StringName)
signal weapon_milestone_unlocked(weapon_id: StringName, milestone_level: int)
signal weapon_upgrade_failed(weapon_id: StringName, reason: String)


class WeaponDefinitionData:
	var weapon_id: StringName
	var display_name: String
	var description: String
	var base_damage: float
	var damage_growth: float
	var base_attack_interval: float
	var minimum_attack_interval: float
	var base_upgrade_cost: float
	var upgrade_cost_growth: float
	var starting_level: int
	var starting_tier: int
	var maximum_level: int
	var milestone_levels: Array[int]
	var tags: Array[StringName]

	func _init(
		new_weapon_id: StringName,
		new_display_name: String,
		new_description: String,
		new_base_damage: float,
		new_damage_growth: float,
		new_base_attack_interval: float,
		new_minimum_attack_interval: float,
		new_base_upgrade_cost: float,
		new_upgrade_cost_growth: float,
		new_tags: Array[StringName]
	) -> void:
		weapon_id = new_weapon_id
		display_name = new_display_name
		description = new_description
		base_damage = new_base_damage
		damage_growth = new_damage_growth
		base_attack_interval = new_base_attack_interval
		minimum_attack_interval = new_minimum_attack_interval
		base_upgrade_cost = new_base_upgrade_cost
		upgrade_cost_growth = new_upgrade_cost_growth
		starting_level = 1
		starting_tier = 1
		maximum_level = -1
		milestone_levels = [
			10,
			25,
			50,
			100,
			250
		]
		tags = new_tags.duplicate()


class WeaponRuntimeData:
	var weapon_id: StringName = &""
	var display_name: String = ""
	var level: int = 1
	var tier: int = 1
	var slot_id: String = ""
	var unlocked: bool = false
	var unlocked_milestones: Array[int] = []
	var calculated_damage: float = 0.0
	var calculated_attack_interval: float = 1.0
	var calculated_dps: float = 0.0
	var calculated_range_multiplier: float = 1.0
	var projectiles_per_attack: int = 1
	var ricochet_count: int = 0
	var ricochet_damage_multiplier: float = 0.6
	var explosion_every_n_attacks: int = 0
	var explosion_damage_multiplier: float = 0.0

	func has_milestone(level_value: int) -> bool:
		return unlocked_milestones.has(level_value)

	func clear_run_state() -> void:
		unlocked_milestones.clear()
		calculated_damage = 0.0
		calculated_attack_interval = 1.0
		calculated_dps = 0.0
		projectiles_per_attack = 1
		ricochet_count = 0
		explosion_every_n_attacks = 0
		explosion_damage_multiplier = 0.0


const MAX_BUY_ITERATIONS: int = 1000000
const TIER_DAMAGE_BONUS_PER_LEVEL: float = 0.25
const TIER_ATTACK_SPEED_BONUS_PER_LEVEL: float = 0.10
const TIER_RANGE_BONUS_PER_LEVEL: float = 0.08
const BASIC_TURRET_ID: StringName = &"turret"


var run_state: RunState
var run_upgrade_manager: RunUpgradeManager

var definitions: Dictionary = {}
var runtime_states: Dictionary = {}
var attack_counters: Dictionary = {}

var global_damage_multiplier: float = 1.0
var boss_damage_multiplier: float = 1.0
var global_attack_speed_multiplier: float = 1.0
var weapon_damage_multipliers: Dictionary = {}
var weapon_attack_speed_multipliers: Dictionary = {}
var weapon_range_multipliers: Dictionary = {}
var weapon_tiers: Dictionary = {}


func _ready() -> void:
	_setup_default_definitions()


func configure(
	new_run_state: RunState,
	new_run_upgrade_manager: RunUpgradeManager
) -> void:
	run_state = new_run_state
	run_upgrade_manager = new_run_upgrade_manager
	_setup_default_definitions()
	_recalculate_all()


func register_weapon(
	weapon_id: String,
	slot_id: String = "",
	tier: int = 1
) -> WeaponRuntimeData:
	var normalized_id: StringName = _normalize_weapon_id(weapon_id)

	if String(normalized_id).is_empty():
		return null

	var definition: WeaponDefinitionData = get_definition(normalized_id)

	if definition == null:
		push_warning("WeaponUpgradeManager: Missing weapon definition: " + String(normalized_id))
		return null

	var state: WeaponRuntimeData = get_state(normalized_id)
	var is_new_state: bool = false

	if state == null:
		state = WeaponRuntimeData.new()
		state.weapon_id = normalized_id
		state.level = maxi(definition.starting_level, 1)
		state.tier = maxi(definition.starting_tier, 1)
		runtime_states[normalized_id] = state
		is_new_state = true

	state.unlocked = true
	state.slot_id = slot_id
	state.tier = maxi(state.tier, tier)

	if not attack_counters.has(normalized_id):
		attack_counters[normalized_id] = 0

	_process_milestones(state)
	_recalculate_state(state)

	if is_new_state:
		weapon_registered.emit(normalized_id)
	else:
		weapon_stats_changed.emit(normalized_id)

	return state


func reset_run_weapon_levels() -> void:
	for state_key: Variant in runtime_states.keys():
		var state: WeaponRuntimeData = runtime_states[state_key] as WeaponRuntimeData

		if state == null:
			continue

		var definition: WeaponDefinitionData = get_definition(state.weapon_id)

		if definition == null:
			continue

		state.level = maxi(definition.starting_level, 1)
		state.tier = maxi(definition.starting_tier, 1)
		state.clear_run_state()
		weapon_level_changed.emit(state.weapon_id, state.level)
		weapon_tier_changed.emit(state.weapon_id, state.tier)

	reset_attack_counters()
	_recalculate_all()


func reset_attack_counters() -> void:
	for state_key: Variant in runtime_states.keys():
		attack_counters[state_key] = 0


func record_attack(weapon_id: String) -> int:
	var normalized_id: StringName = _normalize_weapon_id(weapon_id)
	var current_count: int = int(attack_counters.get(normalized_id, 0)) + 1
	attack_counters[normalized_id] = current_count
	return current_count


func set_temporary_modifiers(
	new_global_damage_multiplier: float,
	new_boss_damage_multiplier: float,
	new_global_attack_speed_multiplier: float,
	new_weapon_damage_multipliers: Dictionary,
	new_weapon_attack_speed_multipliers: Dictionary,
	new_weapon_range_multipliers: Dictionary,
	new_weapon_tiers: Dictionary
) -> void:
	global_damage_multiplier = maxf(new_global_damage_multiplier, 0.0)
	boss_damage_multiplier = maxf(new_boss_damage_multiplier, 0.0)
	global_attack_speed_multiplier = maxf(new_global_attack_speed_multiplier, 0.05)
	weapon_damage_multipliers = _normalize_dictionary_keys(new_weapon_damage_multipliers)
	weapon_attack_speed_multipliers = _normalize_dictionary_keys(new_weapon_attack_speed_multipliers)
	weapon_range_multipliers = _normalize_dictionary_keys(new_weapon_range_multipliers)
	weapon_tiers = _normalize_dictionary_keys(new_weapon_tiers)

	for state_key: Variant in runtime_states.keys():
		var state: WeaponRuntimeData = runtime_states[state_key] as WeaponRuntimeData

		if state == null:
			continue

		var reward_tier: int = int(weapon_tiers.get(state.weapon_id, state.tier))

		if reward_tier > state.tier:
			state.tier = reward_tier
			weapon_tier_changed.emit(state.weapon_id, state.tier)

	_recalculate_all()


func set_weapon_tier(weapon_id: String, tier: int) -> void:
	var normalized_id: StringName = _normalize_weapon_id(weapon_id)
	var state: WeaponRuntimeData = get_state(normalized_id)
	var safe_tier: int = maxi(tier, 1)
	weapon_tiers[normalized_id] = safe_tier

	if state == null:
		return

	if safe_tier <= state.tier:
		return

	state.tier = safe_tier
	_recalculate_state(state)
	weapon_tier_changed.emit(normalized_id, state.tier)
	weapon_stats_changed.emit(normalized_id)


func get_registered_weapon_ids() -> Array[StringName]:
	var ids: Array[StringName] = []

	for state_key: Variant in runtime_states.keys():
		ids.append(StringName(state_key))

	ids.sort()
	return ids


func get_definition(weapon_id: StringName) -> WeaponDefinitionData:
	return definitions.get(weapon_id, null) as WeaponDefinitionData


func get_state(weapon_id: StringName) -> WeaponRuntimeData:
	return runtime_states.get(weapon_id, null) as WeaponRuntimeData


func get_weapon_damage(weapon_id: String, target_is_boss: bool = false) -> float:
	var state: WeaponRuntimeData = get_state(_normalize_weapon_id(weapon_id))

	if state == null:
		return 0.0

	var damage: float = state.calculated_damage

	if target_is_boss:
		damage *= boss_damage_multiplier

	return maxf(damage, 0.0)


func get_range_multiplier(weapon_id: String) -> float:
	var state: WeaponRuntimeData = get_state(_normalize_weapon_id(weapon_id))

	if state == null:
		return 1.0

	return maxf(state.calculated_range_multiplier, 0.01)


func get_current_cost(weapon_id: String) -> float:
	return get_cost_for_quantity(weapon_id, 1)


func get_cost_for_quantity(weapon_id: String, quantity: int) -> float:
	var normalized_id: StringName = _normalize_weapon_id(weapon_id)
	var state: WeaponRuntimeData = get_state(normalized_id)
	var definition: WeaponDefinitionData = get_definition(normalized_id)

	if state == null or definition == null:
		return INF

	var safe_quantity: int = _get_bounded_quantity(state, maxi(quantity, 0))

	if safe_quantity <= 0:
		return INF

	var first_cost: float = definition.base_upgrade_cost * pow(
		definition.upgrade_cost_growth,
		float(state.level)
	)

	if not _is_safe_number(first_cost):
		return INF

	if is_equal_approx(definition.upgrade_cost_growth, 1.0):
		return first_cost * float(safe_quantity)

	var growth_power: float = pow(
		definition.upgrade_cost_growth,
		float(safe_quantity)
	)

	if not _is_safe_number(growth_power):
		return INF

	var total_cost: float = first_cost * (growth_power - 1.0) / (
		definition.upgrade_cost_growth - 1.0
	)

	if not _is_safe_number(total_cost):
		return INF

	return maxf(total_cost, 0.0)


func can_purchase(weapon_id: String, quantity: int = 1) -> bool:
	if run_state == null:
		return false

	var total_cost: float = get_cost_for_quantity(weapon_id, quantity)

	if not _is_safe_number(total_cost):
		return false

	return run_state.run_cash + 0.0001 >= total_cost


func purchase(weapon_id: String, quantity: int = 1) -> bool:
	var normalized_id: StringName = _normalize_weapon_id(weapon_id)
	var state: WeaponRuntimeData = get_state(normalized_id)

	if state == null:
		weapon_upgrade_failed.emit(normalized_id, "Weapon is not registered.")
		return false

	var safe_quantity: int = _get_bounded_quantity(state, maxi(quantity, 1))
	var total_cost: float = get_cost_for_quantity(String(normalized_id), safe_quantity)

	if safe_quantity <= 0:
		weapon_upgrade_failed.emit(normalized_id, "Weapon is already at max level.")
		return false

	if run_state == null:
		weapon_upgrade_failed.emit(normalized_id, "Run state is missing.")
		return false

	if not _is_safe_number(total_cost):
		weapon_upgrade_failed.emit(normalized_id, "Upgrade cost overflowed.")
		return false

	if not run_state.spend_cash(total_cost):
		weapon_upgrade_failed.emit(normalized_id, "Not enough cash.")
		return false

	state.level += safe_quantity
	_process_milestones(state)
	_recalculate_state(state)
	weapon_level_changed.emit(normalized_id, state.level)
	weapon_stats_changed.emit(normalized_id)
	return true


func purchase_max(weapon_id: String) -> int:
	if run_state == null:
		return 0

	var quantity: int = get_max_affordable_quantity(
		weapon_id,
		run_state.run_cash
	)

	if quantity <= 0:
		weapon_upgrade_failed.emit(_normalize_weapon_id(weapon_id), "Not enough cash.")
		return 0

	if purchase(weapon_id, quantity):
		return quantity

	return 0


func get_max_affordable_quantity(
	weapon_id: String,
	available_cash: float
) -> int:
	if available_cash <= 0.0:
		return 0

	var normalized_id: StringName = _normalize_weapon_id(weapon_id)
	var state: WeaponRuntimeData = get_state(normalized_id)

	if state == null:
		return 0

	var maximum_quantity: int = MAX_BUY_ITERATIONS
	var definition: WeaponDefinitionData = get_definition(normalized_id)

	if definition != null and definition.maximum_level >= 0:
		maximum_quantity = maxi(definition.maximum_level - state.level, 0)

	if maximum_quantity <= 0:
		return 0

	var high: int = 1

	while high < maximum_quantity:
		var high_cost: float = get_cost_for_quantity(weapon_id, high)

		if not _is_safe_number(high_cost):
			break

		if high_cost > available_cash:
			break

		high *= 2

	high = mini(high, maximum_quantity)

	var low: int = 0

	while low < high:
		var mid: int = (low + high + 1) / 2
		var cost: float = get_cost_for_quantity(weapon_id, mid)

		if _is_safe_number(cost) and cost <= available_cash:
			low = mid
		else:
			high = mid - 1

	return low


func get_next_milestone(weapon_id: String) -> int:
	var normalized_id: StringName = _normalize_weapon_id(weapon_id)
	var state: WeaponRuntimeData = get_state(normalized_id)
	var definition: WeaponDefinitionData = get_definition(normalized_id)

	if state == null or definition == null:
		return 0

	for milestone_level: int in definition.milestone_levels:
		if state.level < milestone_level:
			return milestone_level

	return 0


func _recalculate_all() -> void:
	for state_key: Variant in runtime_states.keys():
		var state: WeaponRuntimeData = runtime_states[state_key] as WeaponRuntimeData

		if state == null:
			continue

		_recalculate_state(state)
		weapon_stats_changed.emit(state.weapon_id)


func _recalculate_state(state: WeaponRuntimeData) -> void:
	var definition: WeaponDefinitionData = get_definition(state.weapon_id)

	if definition == null:
		return

	state.display_name = definition.display_name

	if state.weapon_id == BASIC_TURRET_ID and state.has_milestone(100):
		state.display_name = "Twin Void Turret"

	var level_power: int = maxi(state.level - 1, 0)
	var damage: float = definition.base_damage * pow(
		definition.damage_growth,
		float(level_power)
	)
	damage *= _get_tier_damage_multiplier(state.tier)
	damage *= global_damage_multiplier
	damage *= _get_run_damage_multiplier()
	damage *= _get_dictionary_multiplier(weapon_damage_multipliers, state.weapon_id)
	damage *= _get_milestone_damage_multiplier(state)
	state.calculated_damage = maxf(damage, 0.0)

	var attack_speed_multiplier: float = global_attack_speed_multiplier
	attack_speed_multiplier *= _get_run_attack_speed_multiplier()
	attack_speed_multiplier *= _get_tier_attack_speed_multiplier(state.tier)
	attack_speed_multiplier *= _get_dictionary_multiplier(
		weapon_attack_speed_multipliers,
		state.weapon_id
	)
	attack_speed_multiplier *= _get_milestone_attack_speed_multiplier(state)

	var interval: float = definition.base_attack_interval

	if attack_speed_multiplier > 0.0:
		interval /= attack_speed_multiplier

	state.calculated_attack_interval = maxf(
		interval,
		definition.minimum_attack_interval
	)

	state.calculated_range_multiplier = _get_tier_range_multiplier(state.tier)
	state.calculated_range_multiplier *= _get_dictionary_multiplier(
		weapon_range_multipliers,
		state.weapon_id
	)
	state.projectiles_per_attack = _get_projectiles_per_attack(state)
	state.ricochet_count = _get_ricochet_count(state)
	state.ricochet_damage_multiplier = 0.6
	state.explosion_every_n_attacks = _get_explosion_interval(state)
	state.explosion_damage_multiplier = _get_explosion_damage_multiplier(state)
	state.calculated_dps = _calculate_estimated_dps(state)


func _process_milestones(state: WeaponRuntimeData) -> void:
	var definition: WeaponDefinitionData = get_definition(state.weapon_id)

	if definition == null:
		return

	for milestone_level: int in definition.milestone_levels:
		if state.level < milestone_level:
			continue

		if state.unlocked_milestones.has(milestone_level):
			continue

		state.unlocked_milestones.append(milestone_level)
		weapon_milestone_unlocked.emit(state.weapon_id, milestone_level)


func _get_milestone_damage_multiplier(state: WeaponRuntimeData) -> float:
	if state.weapon_id == BASIC_TURRET_ID:
		if state.has_milestone(10):
			return 2.0

		return 1.0

	var multiplier: float = 1.0

	if state.has_milestone(10):
		multiplier *= 2.0

	if state.has_milestone(100):
		multiplier *= 3.0

	return multiplier


func _get_milestone_attack_speed_multiplier(state: WeaponRuntimeData) -> float:
	var multiplier: float = 1.0

	if state.weapon_id == BASIC_TURRET_ID:
		if state.has_milestone(100):
			multiplier *= 1.5

		return multiplier

	if state.has_milestone(25):
		multiplier *= 1.25

	return multiplier


func _get_projectiles_per_attack(state: WeaponRuntimeData) -> int:
	if state.weapon_id == BASIC_TURRET_ID and state.has_milestone(25):
		return 2

	return 1


func _get_ricochet_count(state: WeaponRuntimeData) -> int:
	if state.weapon_id == BASIC_TURRET_ID and state.has_milestone(50):
		return 1

	return 0


func _get_explosion_interval(state: WeaponRuntimeData) -> int:
	if state.weapon_id == BASIC_TURRET_ID and state.has_milestone(250):
		return 10

	return 0


func _get_explosion_damage_multiplier(state: WeaponRuntimeData) -> float:
	if state.weapon_id == BASIC_TURRET_ID and state.has_milestone(250):
		return 2.5

	return 0.0


func _calculate_estimated_dps(state: WeaponRuntimeData) -> float:
	var interval: float = maxf(state.calculated_attack_interval, 0.01)
	var projectile_factor: float = float(maxi(state.projectiles_per_attack, 1))

	if state.ricochet_count > 0:
		projectile_factor += float(state.ricochet_count) * state.ricochet_damage_multiplier

	var dps: float = state.calculated_damage * projectile_factor / interval

	if state.explosion_every_n_attacks > 0:
		dps += (
			state.calculated_damage
			* state.explosion_damage_multiplier
			/ float(state.explosion_every_n_attacks)
			/ interval
		)

	return maxf(dps, 0.0)


func _get_bounded_quantity(
	state: WeaponRuntimeData,
	quantity: int
) -> int:
	var safe_quantity: int = maxi(quantity, 0)
	var definition: WeaponDefinitionData = get_definition(state.weapon_id)

	if definition == null:
		return 0

	if definition.maximum_level < 0:
		return mini(safe_quantity, MAX_BUY_ITERATIONS)

	return mini(
		safe_quantity,
		maxi(definition.maximum_level - state.level, 0)
	)


func _get_dictionary_multiplier(
	dictionary: Dictionary,
	weapon_id: StringName
) -> float:
	return maxf(float(dictionary.get(weapon_id, 1.0)), 0.0)


func _get_run_damage_multiplier() -> float:
	if run_upgrade_manager == null:
		return 1.0

	return run_upgrade_manager.get_global_damage_multiplier()


func _get_run_attack_speed_multiplier() -> float:
	if run_upgrade_manager == null:
		return 1.0

	return run_upgrade_manager.get_attack_speed_multiplier()


func _get_tier_damage_multiplier(tier: int) -> float:
	var extra_levels: int = maxi(tier - 1, 0)
	return 1.0 + float(extra_levels) * TIER_DAMAGE_BONUS_PER_LEVEL


func _get_tier_attack_speed_multiplier(tier: int) -> float:
	var extra_levels: int = maxi(tier - 1, 0)
	return 1.0 + float(extra_levels) * TIER_ATTACK_SPEED_BONUS_PER_LEVEL


func _get_tier_range_multiplier(tier: int) -> float:
	var extra_levels: int = maxi(tier - 1, 0)
	return 1.0 + float(extra_levels) * TIER_RANGE_BONUS_PER_LEVEL


func _normalize_dictionary_keys(source: Dictionary) -> Dictionary:
	var normalized: Dictionary = {}

	for source_key: Variant in source.keys():
		var normalized_id: StringName = _normalize_weapon_id(str(source_key))
		normalized[normalized_id] = source[source_key]

	return normalized


func _normalize_weapon_id(weapon_id: String) -> StringName:
	var normalized_id: String = weapon_id.strip_edges().to_lower()

	match normalized_id:
		"tesla":
			return &"tesla_coil"
		"pulse":
			return &"pulse_cannon"
		"cannon":
			return &"pulse_cannon"
		"motor":
			return &"mortar"
		_:
			return StringName(normalized_id)


func _is_safe_number(value: float) -> bool:
	if value != value:
		return false

	if value == INF or value == -INF:
		return false

	return true


func _setup_default_definitions() -> void:
	if not definitions.is_empty():
		return

	_add_definition(WeaponDefinitionData.new(
		&"turret", "Basic Turret", "Reliable projectile weapon.",
		24.0, 1.12, 0.52, 0.08, 35.0, 1.16,
		[&"projectile", &"starter"]
	))
	_add_definition(WeaponDefinitionData.new(
		&"tesla_coil", "Tesla Coil", "Fast beam weapon.",
		24.0, 1.105, 0.38, 0.06, 55.0, 1.17,
		[&"beam", &"energy"]
	))
	_add_definition(WeaponDefinitionData.new(
		&"laser", "Laser", "Precise beam weapon.",
		36.0, 1.11, 0.62, 0.08, 70.0, 1.18,
		[&"beam", &"precision"]
	))
	_add_definition(WeaponDefinitionData.new(
		&"pulse_cannon", "Pulse Cannon", "Slow heavy projectile weapon.",
		60.0, 1.13, 1.15, 0.12, 110.0, 1.19,
		[&"projectile", &"heavy"]
	))
	_add_definition(WeaponDefinitionData.new(
		&"railgun", "Railgun", "High power precision weapon.",
		95.0, 1.14, 1.50, 0.16, 180.0, 1.20,
		[&"projectile", &"precision"]
	))
	_add_definition(WeaponDefinitionData.new(
		&"mortar", "Mortar", "Heavy area weapon placeholder.",
		120.0, 1.14, 1.80, 0.20, 220.0, 1.21,
		[&"heavy", &"area"]
	))
	_add_definition(WeaponDefinitionData.new(
		&"rocket", "Rocket", "Explosive projectile placeholder.",
		80.0, 1.13, 1.30, 0.14, 150.0, 1.20,
		[&"projectile", &"area"]
	))
	_add_definition(WeaponDefinitionData.new(
		&"drone", "Drone", "Automation support placeholder.",
		18.0, 1.10, 0.25, 0.05, 50.0, 1.17,
		[&"automation"]
	))


func _add_definition(definition: WeaponDefinitionData) -> void:
	definitions[definition.weapon_id] = definition
