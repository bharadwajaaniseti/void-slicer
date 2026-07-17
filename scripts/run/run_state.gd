class_name RunState
extends Node


signal cash_changed(value: float)
signal xp_changed(value: float)
signal materials_changed(value: float)
signal core_energy_changed(current_value: float, required_value: float)
signal sector_stage_changed(sector: int, stage: int)
signal kills_changed(enemies: int, bosses: int)
signal damage_changed(value: float)
signal farming_changed(is_farming: bool)
signal stage_completed_changed(is_completed: bool)
signal boss_state_changed(is_active: bool)
signal state_changed


var current_sector: int = 1
var current_stage: int = 1
var highest_stage_this_run: int = 1
var run_cash: float = 0.0
var run_xp: float = 0.0
var run_materials: float = 0.0
var core_energy: float = 0.0
var core_energy_required: float = 2000.0
var enemies_killed: int = 0
var bosses_killed: int = 0
var total_run_damage: float = 0.0
var is_farming: bool = false
var stage_completed: bool = false
var boss_active: bool = false


func reset_run() -> void:
	current_sector = 1
	current_stage = 1
	highest_stage_this_run = 1
	run_cash = 0.0
	run_xp = 0.0
	run_materials = 0.0
	core_energy = 0.0
	core_energy_required = 2000.0
	enemies_killed = 0
	bosses_killed = 0
	total_run_damage = 0.0
	is_farming = false
	stage_completed = false
	boss_active = false
	_emit_all()


func set_core_energy_requirement(required_value: float) -> void:
	core_energy_required = maxf(required_value, 1.0)
	core_energy = clampf(core_energy, 0.0, core_energy_required)
	core_energy_changed.emit(core_energy, core_energy_required)
	state_changed.emit()


func add_enemy_rewards(
	cash_amount: float,
	xp_amount: float,
	material_amount: float,
	core_amount: float
) -> void:
	add_cash(cash_amount)
	add_xp(xp_amount)
	add_materials(material_amount)
	enemies_killed += 1
	kills_changed.emit(enemies_killed, bosses_killed)
	add_core_energy(core_amount)
	state_changed.emit()


func add_boss_rewards(
	cash_amount: float,
	xp_amount: float,
	material_amount: float
) -> void:
	add_cash(cash_amount)
	add_xp(xp_amount)
	add_materials(material_amount)
	bosses_killed += 1
	kills_changed.emit(enemies_killed, bosses_killed)
	state_changed.emit()


func add_cash(amount: float) -> void:
	if amount <= 0.0:
		return

	run_cash += amount
	cash_changed.emit(run_cash)


func spend_cash(amount: float) -> bool:
	if amount <= 0.0:
		return true

	if run_cash + 0.0001 < amount:
		return false

	run_cash = maxf(run_cash - amount, 0.0)
	cash_changed.emit(run_cash)
	state_changed.emit()
	return true


func add_xp(amount: float) -> void:
	if amount <= 0.0:
		return

	run_xp += amount
	xp_changed.emit(run_xp)


func add_materials(amount: float) -> void:
	if amount <= 0.0:
		return

	run_materials += amount
	materials_changed.emit(run_materials)


func add_core_energy(amount: float) -> bool:
	if amount <= 0.0:
		return false

	if boss_active:
		return false

	core_energy = clampf(
		core_energy + amount,
		0.0,
		core_energy_required
	)

	core_energy_changed.emit(core_energy, core_energy_required)
	state_changed.emit()
	return core_energy >= core_energy_required


func start_boss() -> void:
	boss_active = true
	boss_state_changed.emit(boss_active)
	state_changed.emit()


func complete_boss() -> void:
	boss_active = false
	core_energy = 0.0
	boss_state_changed.emit(boss_active)
	core_energy_changed.emit(core_energy, core_energy_required)
	state_changed.emit()


func complete_stage() -> void:
	stage_completed = true
	is_farming = true
	highest_stage_this_run = maxi(highest_stage_this_run, current_stage)
	stage_completed_changed.emit(stage_completed)
	farming_changed.emit(is_farming)
	state_changed.emit()


func farm_stage() -> void:
	is_farming = true
	farming_changed.emit(is_farming)
	state_changed.emit()


func advance_stage(balance: RunBalance = null) -> void:
	current_stage += 1

	if balance != null:
		current_sector = balance.get_sector_for_stage(current_stage)
	else:
		current_sector = maxi(current_sector, 1)

	highest_stage_this_run = maxi(highest_stage_this_run, current_stage)
	stage_completed = false
	is_farming = false
	core_energy = 0.0
	boss_active = false
	sector_stage_changed.emit(current_sector, current_stage)
	stage_completed_changed.emit(stage_completed)
	farming_changed.emit(is_farming)
	boss_state_changed.emit(boss_active)
	core_energy_changed.emit(core_energy, core_energy_required)
	state_changed.emit()


func add_damage(amount: float) -> void:
	if amount <= 0.0:
		return

	total_run_damage += amount
	damage_changed.emit(total_run_damage)


func _emit_all() -> void:
	cash_changed.emit(run_cash)
	xp_changed.emit(run_xp)
	materials_changed.emit(run_materials)
	core_energy_changed.emit(core_energy, core_energy_required)
	sector_stage_changed.emit(current_sector, current_stage)
	kills_changed.emit(enemies_killed, bosses_killed)
	damage_changed.emit(total_run_damage)
	farming_changed.emit(is_farming)
	stage_completed_changed.emit(stage_completed)
	boss_state_changed.emit(boss_active)
	state_changed.emit()
