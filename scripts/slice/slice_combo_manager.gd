class_name SliceComboManager
extends Node


signal combo_started
signal combo_changed(current_combo: int, multiplier: float)
signal combo_extended
signal combo_broken
signal slice_completed(hit_count: int)
signal slice_energy_changed(current: float, maximum: float)
signal void_burst_ready
signal void_burst_triggered


@export var combo_duration: float = 3.0
@export var maximum_slice_energy: float = 100.0
@export var break_combo_on_empty_slice: bool = false

var current_combo: int = 0
var highest_combo_this_run: int = 0
var combo_multiplier: float = 1.0
var combo_time_remaining: float = 0.0
var last_slice_hit_count: int = 0
var total_enemies_sliced_this_run: int = 0
var slice_energy: float = 0.0
var void_burst_is_ready: bool = false

var combo_thresholds: Array[int] = [
	1,
	5,
	10,
	20,
	35,
	50
]
var combo_multipliers: Array[float] = [
	1.0,
	1.25,
	1.5,
	2.0,
	3.0,
	5.0
]


func reset_run() -> void:
	current_combo = 0
	highest_combo_this_run = 0
	combo_multiplier = 1.0
	combo_time_remaining = 0.0
	last_slice_hit_count = 0
	total_enemies_sliced_this_run = 0
	slice_energy = 0.0
	void_burst_is_ready = false
	combo_changed.emit(current_combo, combo_multiplier)
	slice_energy_changed.emit(slice_energy, maximum_slice_energy)


func update_combo(delta: float) -> void:
	if current_combo <= 0:
		return

	combo_time_remaining = maxf(combo_time_remaining - delta, 0.0)

	if combo_time_remaining <= 0.0:
		_break_combo()
	else:
		combo_changed.emit(current_combo, combo_multiplier)


func complete_slice(hit_count: int) -> float:
	last_slice_hit_count = maxi(hit_count, 0)
	slice_completed.emit(last_slice_hit_count)

	if last_slice_hit_count <= 0:
		if break_combo_on_empty_slice:
			_break_combo()

		return combo_multiplier

	var was_in_combo: bool = current_combo > 0
	current_combo += last_slice_hit_count
	total_enemies_sliced_this_run += last_slice_hit_count
	highest_combo_this_run = maxi(highest_combo_this_run, current_combo)
	combo_time_remaining = combo_duration
	combo_multiplier = _calculate_combo_multiplier(current_combo)

	if was_in_combo:
		combo_extended.emit()
	else:
		combo_started.emit()

	combo_changed.emit(current_combo, combo_multiplier)
	return combo_multiplier


func add_slice_energy(amount: float) -> void:
	if amount <= 0.0:
		return

	if void_burst_is_ready:
		return

	slice_energy = clampf(
		slice_energy + amount,
		0.0,
		maximum_slice_energy
	)

	if slice_energy >= maximum_slice_energy:
		slice_energy = maximum_slice_energy
		void_burst_is_ready = true
		void_burst_ready.emit()

	slice_energy_changed.emit(slice_energy, maximum_slice_energy)


func can_trigger_void_burst() -> bool:
	return void_burst_is_ready and slice_energy >= maximum_slice_energy


func consume_void_burst() -> bool:
	if not can_trigger_void_burst():
		return false

	slice_energy = 0.0
	void_burst_is_ready = false
	void_burst_triggered.emit()
	slice_energy_changed.emit(slice_energy, maximum_slice_energy)
	return true


func _break_combo() -> void:
	if current_combo <= 0:
		return

	current_combo = 0
	combo_multiplier = 1.0
	combo_time_remaining = 0.0
	combo_broken.emit()
	combo_changed.emit(current_combo, combo_multiplier)


func _calculate_combo_multiplier(combo_value: int) -> float:
	var multiplier: float = 1.0

	for index: int in range(combo_thresholds.size()):
		if combo_value >= combo_thresholds[index]:
			multiplier = combo_multipliers[index]

	return multiplier
