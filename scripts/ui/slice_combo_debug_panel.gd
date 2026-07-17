class_name SliceComboDebugPanel
extends PanelContainer


signal void_burst_requested


var combo_manager: Node
var title_label: Label
var combo_label: Label
var energy_label: Label
var energy_bar: ProgressBar
var burst_button: Button


func configure(new_combo_manager: Node) -> void:
	combo_manager = new_combo_manager

	if not is_inside_tree():
		return

	_connect_sources()
	_refresh()


func _ready() -> void:
	_build_layout()
	_connect_sources()
	_refresh()


func _build_layout() -> void:
	custom_minimum_size = Vector2(310.0, 0.0)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(1.0, 1.0, 1.0, 0.94)
	panel_style.border_color = Color("#21B77A")
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(8)
	add_theme_stylebox_override("panel", panel_style)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	add_child(margin)

	var root_box: VBoxContainer = VBoxContainer.new()
	root_box.add_theme_constant_override("separation", 7)
	margin.add_child(root_box)

	title_label = Label.new()
	title_label.text = "SLICE COMBO"
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.add_theme_color_override("font_color", Color("#111827"))
	root_box.add_child(title_label)

	combo_label = Label.new()
	combo_label.add_theme_color_override("font_color", Color("#374151"))
	root_box.add_child(combo_label)

	energy_label = Label.new()
	energy_label.add_theme_color_override("font_color", Color("#374151"))
	root_box.add_child(energy_label)

	energy_bar = ProgressBar.new()
	energy_bar.min_value = 0.0
	energy_bar.max_value = 100.0
	energy_bar.show_percentage = false
	root_box.add_child(energy_bar)

	burst_button = Button.new()
	burst_button.text = "Void Burst"
	burst_button.custom_minimum_size = Vector2(140.0, 30.0)
	burst_button.pressed.connect(
		func() -> void:
			void_burst_requested.emit()
	)
	root_box.add_child(burst_button)


func _connect_sources() -> void:
	if combo_manager == null:
		return

	_connect_combo_signal(&"combo_changed", Callable(self, "_on_combo_changed"))
	_connect_combo_signal(&"combo_broken", Callable(self, "_on_combo_broken"))
	_connect_combo_signal(&"slice_energy_changed", Callable(self, "_on_slice_energy_changed"))
	_connect_combo_signal(&"void_burst_ready", Callable(self, "_on_void_burst_ready"))
	_connect_combo_signal(&"void_burst_triggered", Callable(self, "_on_void_burst_triggered"))


func _connect_combo_signal(signal_name: StringName, callable: Callable) -> void:
	if combo_manager == null:
		return

	if not combo_manager.has_signal(signal_name):
		return

	if combo_manager.is_connected(signal_name, callable):
		return

	combo_manager.connect(signal_name, callable)


func _refresh() -> void:
	var combo_value: int = 0
	var multiplier: float = 1.0
	var remaining: float = 0.0
	var highest: int = 0
	var energy: float = 0.0
	var maximum_energy: float = 100.0
	var ready: bool = false

	if combo_manager != null:
		combo_value = int(combo_manager.get("current_combo"))
		multiplier = float(combo_manager.get("combo_multiplier"))
		remaining = float(combo_manager.get("combo_time_remaining"))
		highest = int(combo_manager.get("highest_combo_this_run"))
		energy = float(combo_manager.get("slice_energy"))
		maximum_energy = float(combo_manager.get("maximum_slice_energy"))
		ready = bool(combo_manager.get("void_burst_is_ready"))

	if combo_label != null:
		combo_label.text = "Combo %d  x%.2f  %.1fs  Best %d" % [
			combo_value,
			multiplier,
			remaining,
			highest
		]

	if energy_label != null:
		if ready:
			energy_label.text = "Slice Energy %.0f / %.0f  READY" % [
				energy,
				maximum_energy
			]
		else:
			energy_label.text = "Slice Energy %.0f / %.0f" % [
				energy,
				maximum_energy
			]

	if energy_bar != null:
		energy_bar.max_value = maxf(maximum_energy, 1.0)
		energy_bar.value = clampf(energy, 0.0, maximum_energy)

	if burst_button != null:
		burst_button.disabled = not ready


func _on_combo_changed(_combo: int, _multiplier: float) -> void:
	_refresh()


func _on_combo_broken() -> void:
	_refresh()


func _on_slice_energy_changed(_current: float, _maximum: float) -> void:
	_refresh()


func _on_void_burst_ready() -> void:
	_refresh()


func _on_void_burst_triggered() -> void:
	_refresh()
