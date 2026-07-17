@tool
extends Button
class_name WeaponSlot

signal slot_pressed(slot_id: String)

@export var slot_id: String = ""
@export var slot_label: String = "":
	set(value):
		slot_label = value
		_update_visuals()

@export var weapon_name: String = "":
	set(value):
		weapon_name = value
		_update_visuals()

@export var is_unlocked: bool = true:
	set(value):
		is_unlocked = value
		_update_visuals()

@export var accent_color: Color = Color("#7438ff"):
	set(value):
		accent_color = value
		_update_style()

@onready var slot_icon: Label = $VBoxContainer/SlotIcon
@onready var slot_text: Label = $VBoxContainer/SlotLabel


func _ready() -> void:
	custom_minimum_size = Vector2(82, 100)
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	_update_style()
	_update_visuals()

	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)


func _on_pressed() -> void:
	emit_signal("slot_pressed", slot_id)


func _update_visuals() -> void:
	if not is_inside_tree():
		return

	if weapon_name.strip_edges() == "":
		slot_icon.text = "⌗"
		slot_text.text = slot_label
	else:
		slot_icon.text = "✦"
		slot_text.text = weapon_name.to_upper()

	disabled = not is_unlocked
	modulate = Color(1, 1, 1, 1) if is_unlocked else Color(1, 1, 1, 0.45)


func _update_style() -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#ffffff")
	normal.border_color = Color("#e2e5ee")
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(12)
	normal.shadow_color = Color("#b9bfd030")
	normal.shadow_size = 8
	normal.shadow_offset = Vector2(0, 3)
	normal.content_margin_left = 8
	normal.content_margin_right = 8
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8

	var hover := normal.duplicate()
	hover.border_color = accent_color
	hover.shadow_color = Color(accent_color.r, accent_color.g, accent_color.b, 0.25)
	hover.shadow_size = 14

	var pressed_style := normal.duplicate()
	pressed_style.bg_color = Color("#f4f0ff")
	pressed_style.border_color = accent_color

	add_theme_stylebox_override("normal", normal)
	add_theme_stylebox_override("hover", hover)
	add_theme_stylebox_override("pressed", pressed_style)
	add_theme_stylebox_override("disabled", normal)

	add_theme_color_override("font_color", Color("#10131c"))
	add_theme_color_override("font_hover_color", accent_color)
	add_theme_color_override("font_pressed_color", accent_color)
