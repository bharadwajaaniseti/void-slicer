class_name RunUpgradeManager
extends Node


signal upgrade_purchased(upgrade_id: String, quantity: int, total_cost: float)
signal upgrades_changed


class RunUpgradeDefinition:
	var upgrade_id: String
	var display_name: String
	var base_cost: float
	var cost_growth: float
	var effect_per_level: float

	func _init(
		new_upgrade_id: String,
		new_display_name: String,
		new_base_cost: float,
		new_cost_growth: float,
		new_effect_per_level: float
	) -> void:
		upgrade_id = new_upgrade_id
		display_name = new_display_name
		base_cost = new_base_cost
		cost_growth = new_cost_growth
		effect_per_level = new_effect_per_level


var run_state: RunState
var upgrade_levels: Dictionary = {}
var upgrade_definitions: Array[RunUpgradeDefinition] = []


func _ready() -> void:
	_setup_default_upgrades()


func configure(new_run_state: RunState) -> void:
	run_state = new_run_state
	_setup_default_upgrades()
	upgrades_changed.emit()


func reset_upgrades() -> void:
	upgrade_levels.clear()

	for definition: RunUpgradeDefinition in upgrade_definitions:
		upgrade_levels[definition.upgrade_id] = 0

	upgrades_changed.emit()


func get_upgrade_ids() -> Array[String]:
	var ids: Array[String] = []

	for definition: RunUpgradeDefinition in upgrade_definitions:
		ids.append(definition.upgrade_id)

	return ids


func get_display_name(upgrade_id: String) -> String:
	var definition: RunUpgradeDefinition = _get_definition(upgrade_id)

	if definition == null:
		return upgrade_id

	return definition.display_name


func get_level(upgrade_id: String) -> int:
	return int(upgrade_levels.get(upgrade_id, 0))


func get_current_cost(upgrade_id: String) -> float:
	return get_cost_for_quantity(upgrade_id, 1)


func get_cost_for_quantity(upgrade_id: String, quantity: int) -> float:
	var definition: RunUpgradeDefinition = _get_definition(upgrade_id)

	if definition == null:
		return INF

	var safe_quantity: int = maxi(quantity, 0)

	if safe_quantity <= 0:
		return 0.0

	var level: int = get_level(upgrade_id)
	var first_cost: float = definition.base_cost * pow(
		definition.cost_growth,
		float(level)
	)

	if is_equal_approx(definition.cost_growth, 1.0):
		return first_cost * float(safe_quantity)

	var growth_power: float = pow(
		definition.cost_growth,
		float(safe_quantity)
	)

	return first_cost * (growth_power - 1.0) / (definition.cost_growth - 1.0)


func get_effect(upgrade_id: String) -> float:
	var definition: RunUpgradeDefinition = _get_definition(upgrade_id)

	if definition == null:
		return 1.0

	return 1.0 + float(get_level(upgrade_id)) * definition.effect_per_level


func can_purchase(upgrade_id: String, quantity: int = 1) -> bool:
	if run_state == null:
		return false

	var total_cost: float = get_cost_for_quantity(upgrade_id, quantity)
	return run_state.run_cash + 0.0001 >= total_cost


func purchase(upgrade_id: String, quantity: int = 1) -> bool:
	var safe_quantity: int = maxi(quantity, 1)
	var total_cost: float = get_cost_for_quantity(upgrade_id, safe_quantity)

	if run_state == null:
		return false

	if not run_state.spend_cash(total_cost):
		return false

	upgrade_levels[upgrade_id] = get_level(upgrade_id) + safe_quantity
	upgrade_purchased.emit(upgrade_id, safe_quantity, total_cost)
	upgrades_changed.emit()
	return true


func purchase_max(upgrade_id: String) -> int:
	if run_state == null:
		return 0

	var quantity: int = get_max_affordable_quantity(
		upgrade_id,
		run_state.run_cash
	)

	if quantity <= 0:
		return 0

	if purchase(upgrade_id, quantity):
		return quantity

	return 0


func get_max_affordable_quantity(
	upgrade_id: String,
	available_cash: float
) -> int:
	if available_cash <= 0.0:
		return 0

	var definition: RunUpgradeDefinition = _get_definition(upgrade_id)

	if definition == null:
		return 0

	var high: int = 1
	var max_high: int = 1000000

	while high < max_high:
		var high_cost: float = get_cost_for_quantity(upgrade_id, high)

		if high_cost > available_cash:
			break

		high *= 2

	high = mini(high, max_high)

	var low: int = 0

	while low < high:
		var mid: int = (low + high + 1) / 2
		var cost: float = get_cost_for_quantity(upgrade_id, mid)

		if cost <= available_cash:
			low = mid
		else:
			high = mid - 1

	return low


func get_global_damage_multiplier() -> float:
	return get_effect("global_damage")


func get_attack_speed_multiplier() -> float:
	return get_effect("attack_speed")


func get_cash_multiplier() -> float:
	return get_effect("cash_multiplier")


func get_spawn_rate_multiplier() -> float:
	return get_effect("enemy_spawn_rate")


func get_slice_power_multiplier() -> float:
	return get_effect("slice_power")


func _setup_default_upgrades() -> void:
	if not upgrade_definitions.is_empty():
		return

	upgrade_definitions = [
		RunUpgradeDefinition.new("global_damage", "Global Damage", 50.0, 1.18, 0.15),
		RunUpgradeDefinition.new("attack_speed", "Attack Speed", 75.0, 1.20, 0.08),
		RunUpgradeDefinition.new("cash_multiplier", "Cash Multiplier", 100.0, 1.22, 0.12),
		RunUpgradeDefinition.new("enemy_spawn_rate", "Enemy Spawn Rate", 125.0, 1.24, 0.06),
		RunUpgradeDefinition.new("slice_power", "Slice Power", 60.0, 1.18, 0.15)
	]

	for definition: RunUpgradeDefinition in upgrade_definitions:
		if not upgrade_levels.has(definition.upgrade_id):
			upgrade_levels[definition.upgrade_id] = 0


func _get_definition(upgrade_id: String) -> RunUpgradeDefinition:
	for definition: RunUpgradeDefinition in upgrade_definitions:
		if definition.upgrade_id == upgrade_id:
			return definition

	return null
