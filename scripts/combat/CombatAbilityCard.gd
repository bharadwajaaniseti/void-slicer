class_name CombatAbilityCard
extends PanelContainer

signal ability_pressed(ability_id: String)


@export_group("Ability")

@export var ability_id: String = "frenzy":
	set(value):
		ability_id = value
		_update_visuals()

@export var title_text: String = "FRENZY":
	set(value):
		title_text = value
		_update_visuals()

@export var level_text: String = "Lv. 1":
	set(value):
		level_text = value
		_update_visuals()

@export var description_text: String = "Ability description":
	set(value):
		description_text = value
		_update_visuals()

@export var ready_text: String = "READY":
	set(value):
		ready_text = value
		_update_visuals()

@export_range(0.1, 300.0, 0.1)
var cooldown_duration: float = 12.0:
	set(value):
		cooldown_duration = maxf(value, 0.1)

		if cooldown_left > cooldown_duration:
			cooldown_left = cooldown_duration

		_update_visuals()

@export var is_auto_ability: bool = false:
	set(value):
		is_auto_ability = value
		_update_visuals()


@export_group("Cooldown Progress Bar")

## When enabled, the bar begins empty and fills as the ability becomes ready.
## When disabled, the bar begins full and drains during cooldown.
@export var cooldown_bar_fills_up: bool = true:
	set(value):
		cooldown_bar_fills_up = value
		_update_visuals()

## Hides the bar when the ability is ready.
## Disable this if you want the completed bar to remain visible.
@export var hide_bar_when_ready: bool = false:
	set(value):
		hide_bar_when_ready = value
		_update_visuals()

## Automatically hides the cooldown progress bar for auto abilities such as Drones.
@export var hide_bar_for_auto_ability: bool = true:
	set(value):
		hide_bar_for_auto_ability = value
		_update_visuals()


@export_group("Node Paths")

@export var title_label_path: NodePath
@export var level_label_path: NodePath
@export var desc_label_path: NodePath
@export var cooldown_label_path: NodePath
@export var state_button_path: NodePath
@export var cooldown_progress_bar_path: NodePath


var title_label: Label
var level_label: Label
var desc_label: Label
var cooldown_label: Label
var state_button: Button
var cooldown_progress_bar: ProgressBar

var is_ready: bool = true
var cooldown_left: float = 0.0


func _ready() -> void:
	title_label = get_node_or_null(title_label_path) as Label
	level_label = get_node_or_null(level_label_path) as Label
	desc_label = get_node_or_null(desc_label_path) as Label
	cooldown_label = get_node_or_null(cooldown_label_path) as Label
	state_button = get_node_or_null(state_button_path) as Button
	cooldown_progress_bar = get_node_or_null(
		cooldown_progress_bar_path
	) as ProgressBar

	if state_button != null:
		if not state_button.pressed.is_connected(_on_state_button_pressed):
			state_button.pressed.connect(_on_state_button_pressed)

	is_ready = true
	cooldown_left = 0.0

	set_process(true)
	_update_visuals()


func _process(delta: float) -> void:
	if is_auto_ability:
		return

	if is_ready:
		return

	cooldown_left = maxf(cooldown_left - delta, 0.0)

	if cooldown_left <= 0.0:
		cooldown_left = 0.0
		is_ready = true

	_update_visuals()


func start_cooldown() -> void:
	if is_auto_ability:
		return

	is_ready = false
	cooldown_left = maxf(cooldown_duration, 0.1)
	_update_visuals()


func force_ready() -> void:
	is_ready = true
	cooldown_left = 0.0
	_update_visuals()


func set_auto_enabled(enabled: bool) -> void:
	is_auto_ability = true
	is_ready = true
	cooldown_left = 0.0

	if enabled:
		ready_text = "AUTO ON"
	else:
		ready_text = "AUTO OFF"

	_update_visuals()


func get_cooldown_ratio() -> float:
	if cooldown_duration <= 0.0:
		return 1.0

	if is_ready:
		return 1.0

	var remaining_ratio: float = clampf(
		cooldown_left / cooldown_duration,
		0.0,
		1.0
	)

	if cooldown_bar_fills_up:
		return 1.0 - remaining_ratio

	return remaining_ratio


func _on_state_button_pressed() -> void:
	if is_auto_ability:
		ability_pressed.emit(ability_id)
		return

	if not is_ready:
		return

	ability_pressed.emit(ability_id)


func _update_visuals() -> void:
	if not is_inside_tree():
		return

	_update_text_labels()
	_update_state_button()
	_update_cooldown_progress_bar()


func _update_text_labels() -> void:
	if title_label != null:
		title_label.text = title_text

	if level_label != null:
		level_label.text = level_text

	if desc_label != null:
		desc_label.text = description_text

	if cooldown_label == null:
		return

	if is_auto_ability:
		cooldown_label.text = ""
	elif is_ready:
		cooldown_label.text = _format_time(cooldown_duration)
	else:
		cooldown_label.text = _format_time(cooldown_left)


func _update_state_button() -> void:
	if state_button == null:
		return

	if is_auto_ability:
		state_button.text = ready_text
		state_button.disabled = false
		return

	if is_ready:
		state_button.text = ready_text
		state_button.disabled = false
	else:
		state_button.text = "WAIT"
		state_button.disabled = true


func _update_cooldown_progress_bar() -> void:
	if cooldown_progress_bar == null:
		return

	cooldown_progress_bar.min_value = 0.0
	cooldown_progress_bar.max_value = 1.0
	cooldown_progress_bar.step = 0.001
	cooldown_progress_bar.show_percentage = false

	if is_auto_ability and hide_bar_for_auto_ability:
		cooldown_progress_bar.visible = false
		return

	if hide_bar_when_ready and is_ready:
		cooldown_progress_bar.visible = false
		return

	cooldown_progress_bar.visible = true
	cooldown_progress_bar.value = get_cooldown_ratio()


func _format_time(time_seconds: float) -> String:
	var safe_time: float = maxf(time_seconds, 0.0)
	return "%.1fs" % safe_time
