class_name RunUpgradeDebugPanel
extends PanelContainer


signal farm_requested
signal advance_requested


var run_state: RunState
var upgrade_manager: RunUpgradeManager

var title_label: Label
var stage_label: Label
var resources_label: Label
var stage_action_box: HBoxContainer
var upgrade_rows: Dictionary = {}


func configure(
	new_run_state: RunState,
	new_upgrade_manager: RunUpgradeManager
) -> void:
	run_state = new_run_state
	upgrade_manager = new_upgrade_manager

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
	custom_minimum_size = Vector2(310.0, 0.0)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(1.0, 1.0, 1.0, 0.94)
	panel_style.border_color = Color("#7437FF")
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

	title_label = Label.new()
	title_label.text = "RUN UPGRADES"
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.add_theme_color_override("font_color", Color("#111827"))
	root_box.add_child(title_label)

	stage_label = Label.new()
	stage_label.add_theme_color_override("font_color", Color("#374151"))
	root_box.add_child(stage_label)

	resources_label = Label.new()
	resources_label.add_theme_color_override("font_color", Color("#374151"))
	root_box.add_child(resources_label)

	stage_action_box = HBoxContainer.new()
	stage_action_box.add_theme_constant_override("separation", 6)
	root_box.add_child(stage_action_box)

	var farm_button: Button = _make_button("FARM")
	farm_button.pressed.connect(
		func() -> void:
			farm_requested.emit()
	)
	stage_action_box.add_child(farm_button)

	var advance_button: Button = _make_button("ADVANCE")
	advance_button.pressed.connect(
		func() -> void:
			advance_requested.emit()
	)
	stage_action_box.add_child(advance_button)

	var separator: HSeparator = HSeparator.new()
	root_box.add_child(separator)

	var upgrades_box: VBoxContainer = VBoxContainer.new()
	upgrades_box.name = "UpgradesBox"
	upgrades_box.add_theme_constant_override("separation", 6)
	root_box.add_child(upgrades_box)


func _connect_sources() -> void:
	if run_state != null:
		if not run_state.state_changed.is_connected(_refresh):
			run_state.state_changed.connect(_refresh)

	if upgrade_manager != null:
		if not upgrade_manager.upgrades_changed.is_connected(_refresh):
			upgrade_manager.upgrades_changed.connect(_refresh)


func _rebuild() -> void:
	var upgrades_box: VBoxContainer = find_child("UpgradesBox", true, false) as VBoxContainer

	if upgrades_box == null:
		return

	for child: Node in upgrades_box.get_children():
		child.queue_free()

	upgrade_rows.clear()

	if upgrade_manager == null:
		return

	var upgrade_ids: Array[String] = upgrade_manager.get_upgrade_ids()

	for upgrade_id: String in upgrade_ids:
		var row: VBoxContainer = VBoxContainer.new()
		row.add_theme_constant_override("separation", 3)
		upgrades_box.add_child(row)

		var label: Label = Label.new()
		label.add_theme_color_override("font_color", Color("#111827"))
		label.add_theme_font_size_override("font_size", 12)
		row.add_child(label)

		var button_box: HBoxContainer = HBoxContainer.new()
		button_box.add_theme_constant_override("separation", 4)
		row.add_child(button_box)

		var buy_one: Button = _make_button("Buy 1")
		buy_one.pressed.connect(_on_buy_pressed.bind(upgrade_id, 1))
		button_box.add_child(buy_one)

		var buy_ten: Button = _make_button("Buy 10")
		buy_ten.pressed.connect(_on_buy_pressed.bind(upgrade_id, 10))
		button_box.add_child(buy_ten)

		var buy_max: Button = _make_button("Max")
		buy_max.pressed.connect(_on_buy_max_pressed.bind(upgrade_id))
		button_box.add_child(buy_max)

		upgrade_rows[upgrade_id] = {
			"label": label,
			"buy_one": buy_one,
			"buy_ten": buy_ten,
			"buy_max": buy_max
		}


func _refresh() -> void:
	if run_state != null:
		if stage_label != null:
			stage_label.text = "Sector %d  Stage %d" % [
				run_state.current_sector,
				run_state.current_stage
			]

		if resources_label != null:
			resources_label.text = "Cash %s  XP %s  Materials %s" % [
				_format_number(run_state.run_cash),
				_format_number(run_state.run_xp),
				_format_number(run_state.run_materials)
			]

		if stage_action_box != null:
			stage_action_box.visible = run_state.stage_completed

	if upgrade_manager == null:
		return

	for upgrade_key: Variant in upgrade_rows.keys():
		var upgrade_id: String = str(upgrade_key)
		var row_data: Dictionary = upgrade_rows[upgrade_id]
		var label: Label = row_data["label"] as Label
		var buy_one: Button = row_data["buy_one"] as Button
		var buy_ten: Button = row_data["buy_ten"] as Button
		var buy_max: Button = row_data["buy_max"] as Button
		var level: int = upgrade_manager.get_level(upgrade_id)
		var cost: float = upgrade_manager.get_current_cost(upgrade_id)
		var effect: float = upgrade_manager.get_effect(upgrade_id)

		if label != null:
			label.text = "%s Lv.%d  Cost %s  x%.2f" % [
				upgrade_manager.get_display_name(upgrade_id),
				level,
				_format_number(cost),
				effect
			]

		if buy_one != null:
			buy_one.disabled = not upgrade_manager.can_purchase(upgrade_id, 1)

		if buy_ten != null:
			buy_ten.disabled = not upgrade_manager.can_purchase(upgrade_id, 10)

		if buy_max != null:
			var max_quantity: int = 0

			if run_state != null:
				max_quantity = upgrade_manager.get_max_affordable_quantity(
					upgrade_id,
					run_state.run_cash
				)

			buy_max.disabled = max_quantity <= 0


func _on_buy_pressed(upgrade_id: String, quantity: int) -> void:
	if upgrade_manager == null:
		return

	upgrade_manager.purchase(upgrade_id, quantity)


func _on_buy_max_pressed(upgrade_id: String) -> void:
	if upgrade_manager == null:
		return

	upgrade_manager.purchase_max(upgrade_id)


func _make_button(text_value: String) -> Button:
	var button: Button = Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(72.0, 28.0)
	button.add_theme_font_size_override("font_size", 11)
	return button


func _format_number(value: float) -> String:
	var abs_value: float = absf(value)

	if abs_value >= 1000000000.0:
		return "%.2fB" % (value / 1000000000.0)

	if abs_value >= 1000000.0:
		return "%.2fM" % (value / 1000000.0)

	if abs_value >= 1000.0:
		return "%.1fk" % (value / 1000.0)

	return str(roundi(value))
