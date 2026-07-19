@tool
class_name VoidSlicerNavigationTabs
extends PanelContainer

signal tab_selected(tab_id: StringName)

@export var active_tab: StringName = &"home":
	set(value):
		active_tab = value
		_update_buttons()

@onready var tab_row: HBoxContainer = %TabRow


func _ready() -> void:
	for child: Node in tab_row.get_children():
		var button: Button = child as Button
		if button == null:
			continue
		var tab_id: StringName = StringName(button.name.trim_suffix("Button").to_lower())
		if not button.pressed.is_connected(_on_tab_pressed.bind(tab_id)):
			button.pressed.connect(_on_tab_pressed.bind(tab_id))
	_update_buttons()


func select_tab(tab_id: StringName, emit_selection: bool = false) -> void:
	active_tab = tab_id
	if emit_selection:
		tab_selected.emit(tab_id)


func _on_tab_pressed(tab_id: StringName) -> void:
	if tab_id == active_tab:
		return
	active_tab = tab_id
	tab_selected.emit(tab_id)


func _update_buttons() -> void:
	if not is_node_ready():
		return
	for child: Node in tab_row.get_children():
		var button: Button = child as Button
		if button == null:
			continue
		var tab_id: StringName = StringName(button.name.trim_suffix("Button").to_lower())
		button.button_pressed = tab_id == active_tab
		button.theme_type_variation = &"TabButtonActive" if button.button_pressed else &"TabButton"
