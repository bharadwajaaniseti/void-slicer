class_name WeaponUpgradeDebugPanel
extends PanelContainer


var run_state: RunState
var weapon_manager: Node
var resources_label: Label
var weapons_box: VBoxContainer
var weapon_rows: Dictionary = {}


func configure(
	new_run_state: RunState,
	new_weapon_manager: Node
) -> void:
	run_state = new_run_state
	weapon_manager = new_weapon_manager

	if not is_inside_tree():
		return

	_connect_sources()
	_rebuild()
	_refresh()


func _ready() -> void:
	_build_layout()
	_connect_sources()
	_rebuild()
	_refresh()


func _build_layout() -> void:
	custom_minimum_size = Vector2(360.0, 0.0)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(1.0, 1.0, 1.0, 0.94)
	panel_style.border_color = Color("#111827")
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
	root_box.add_theme_constant_override("separation", 8)
	margin.add_child(root_box)

	var title_label: Label = Label.new()
	title_label.text = "WEAPON LEVELS"
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.add_theme_color_override("font_color", Color("#111827"))
	root_box.add_child(title_label)

	resources_label = Label.new()
	resources_label.add_theme_color_override("font_color", Color("#374151"))
	root_box.add_child(resources_label)

	var separator: HSeparator = HSeparator.new()
	root_box.add_child(separator)

	weapons_box = VBoxContainer.new()
	weapons_box.name = "WeaponsBox"
	weapons_box.add_theme_constant_override("separation", 8)
	root_box.add_child(weapons_box)


func _connect_sources() -> void:
	if run_state != null:
		if not run_state.state_changed.is_connected(_refresh):
			run_state.state_changed.connect(_refresh)

	if weapon_manager == null:
		return

	_connect_manager_signal(
		&"weapon_registered",
		Callable(self, "_on_weapon_list_changed")
	)

	_connect_manager_signal(
		&"weapon_level_changed",
		Callable(self, "_on_weapon_level_changed")
	)

	_connect_manager_signal(
		&"weapon_tier_changed",
		Callable(self, "_on_weapon_tier_changed")
	)

	_connect_manager_signal(
		&"weapon_stats_changed",
		Callable(self, "_on_weapon_stats_changed")
	)

	_connect_manager_signal(
		&"weapon_milestone_unlocked",
		Callable(self, "_on_weapon_milestone_unlocked")
	)


func _connect_manager_signal(
	signal_name: StringName,
	callable: Callable
) -> void:
	if weapon_manager == null:
		return

	if not weapon_manager.has_signal(signal_name):
		return

	if weapon_manager.is_connected(signal_name, callable):
		return

	weapon_manager.connect(signal_name, callable)


func _rebuild() -> void:
	if weapons_box == null:
		return

	for child: Node in weapons_box.get_children():
		child.queue_free()

	weapon_rows.clear()

	if weapon_manager == null:
		return

	var weapon_ids: Array[StringName] = []
	var raw_weapon_ids: Variant = weapon_manager.call("get_registered_weapon_ids")

	if raw_weapon_ids is Array:
		for raw_weapon_id: Variant in raw_weapon_ids:
			weapon_ids.append(StringName(raw_weapon_id))

	for weapon_id: StringName in weapon_ids:
		var row: VBoxContainer = VBoxContainer.new()
		row.add_theme_constant_override("separation", 3)
		weapons_box.add_child(row)

		var label: Label = Label.new()
		label.add_theme_color_override("font_color", Color("#111827"))
		label.add_theme_font_size_override("font_size", 11)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(label)

		var button_box: HBoxContainer = HBoxContainer.new()
		button_box.add_theme_constant_override("separation", 4)
		row.add_child(button_box)

		var buy_one: Button = _make_button("Buy 1")
		buy_one.pressed.connect(_on_buy_pressed.bind(String(weapon_id), 1))
		button_box.add_child(buy_one)

		var buy_ten: Button = _make_button("Buy 10")
		buy_ten.pressed.connect(_on_buy_pressed.bind(String(weapon_id), 10))
		button_box.add_child(buy_ten)

		var buy_twenty_five: Button = _make_button("Buy 25")
		buy_twenty_five.pressed.connect(_on_buy_pressed.bind(String(weapon_id), 25))
		button_box.add_child(buy_twenty_five)

		var buy_max: Button = _make_button("Max")
		buy_max.pressed.connect(_on_buy_max_pressed.bind(String(weapon_id)))
		button_box.add_child(buy_max)

		weapon_rows[weapon_id] = {
			"label": label,
			"buy_one": buy_one,
			"buy_ten": buy_ten,
			"buy_twenty_five": buy_twenty_five,
			"buy_max": buy_max
		}


func _refresh() -> void:
	if resources_label != null:
		var cash_value: float = 0.0

		if run_state != null:
			cash_value = run_state.run_cash

		resources_label.text = "Cash %s" % _format_number(cash_value)

	if weapon_manager == null:
		return

	for row_key: Variant in weapon_rows.keys():
		var weapon_id: StringName = StringName(row_key)
		var state: Variant = weapon_manager.call("get_state", weapon_id)
		var row_data: Dictionary = weapon_rows[weapon_id]
		var label: Label = row_data["label"] as Label
		var buy_one: Button = row_data["buy_one"] as Button
		var buy_ten: Button = row_data["buy_ten"] as Button
		var buy_twenty_five: Button = row_data["buy_twenty_five"] as Button
		var buy_max: Button = row_data["buy_max"] as Button

		if state == null:
			continue

		var next_cost: float = float(
			weapon_manager.call("get_current_cost", String(weapon_id))
		)
		var next_milestone: int = int(
			weapon_manager.call("get_next_milestone", String(weapon_id))
		)
		var milestone_text: String = "Next MS %d" % next_milestone

		if next_milestone <= 0:
			milestone_text = "All listed MS unlocked"

		if label != null:
			label.text = "%s Lv.%d T%d  DMG %s  %.2fs  DPS %s  Cost %s  %s" % [
				state.display_name,
				state.level,
				state.tier,
				_format_number(state.calculated_damage),
				state.calculated_attack_interval,
				_format_number(state.calculated_dps),
				_format_number(next_cost),
				milestone_text
			]

		if buy_one != null:
			buy_one.disabled = not bool(
				weapon_manager.call("can_purchase", String(weapon_id), 1)
			)

		if buy_ten != null:
			buy_ten.disabled = not bool(
				weapon_manager.call("can_purchase", String(weapon_id), 10)
			)

		if buy_twenty_five != null:
			buy_twenty_five.disabled = not bool(
				weapon_manager.call("can_purchase", String(weapon_id), 25)
			)

		if buy_max != null:
			var max_quantity: int = 0

			if run_state != null:
				max_quantity = int(
					weapon_manager.call(
						"get_max_affordable_quantity",
						String(weapon_id),
						run_state.run_cash
					)
				)

			buy_max.disabled = max_quantity <= 0


func _on_buy_pressed(weapon_id: String, quantity: int) -> void:
	if weapon_manager == null:
		return

	weapon_manager.call("purchase", weapon_id, quantity)


func _on_buy_max_pressed(weapon_id: String) -> void:
	if weapon_manager == null:
		return

	weapon_manager.call("purchase_max", weapon_id)


func _on_weapon_list_changed(_weapon_id: StringName) -> void:
	_rebuild()
	_refresh()


func _on_weapon_level_changed(_weapon_id: StringName, _new_level: int) -> void:
	_refresh()


func _on_weapon_tier_changed(_weapon_id: StringName, _new_tier: int) -> void:
	_refresh()


func _on_weapon_stats_changed(_weapon_id: StringName) -> void:
	_refresh()


func _on_weapon_milestone_unlocked(_weapon_id: StringName, _milestone_level: int) -> void:
	_refresh()


func _make_button(text_value: String) -> Button:
	var button: Button = Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(76.0, 28.0)
	button.add_theme_font_size_override("font_size", 10)
	return button


func _format_number(value: float) -> String:
	var abs_value: float = absf(value)

	if value == INF:
		return "MAX"

	if abs_value >= 1000000000000.0:
		return "%.2fT" % (value / 1000000000000.0)

	if abs_value >= 1000000000.0:
		return "%.2fB" % (value / 1000000000.0)

	if abs_value >= 1000000.0:
		return "%.2fM" % (value / 1000000.0)

	if abs_value >= 1000.0:
		return "%.1fk" % (value / 1000.0)

	return str(roundi(value))
