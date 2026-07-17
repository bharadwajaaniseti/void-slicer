@tool
extends Control

signal pressed

@export_group("Content")
@export var button_text: String = "START":
	set(value):
		button_text = value
		_update_visuals_deferred()

@export var icon_texture: Texture2D:
	set(value):
		icon_texture = value
		_update_visuals_deferred()

@export_group("Mode")
@export var primary_button: bool = true:
	set(value):
		primary_button = value
		_update_visuals_deferred()

@export_group("Size")
@export var button_size: Vector2 = Vector2(600, 110):
	set(value):
		button_size = value
		custom_minimum_size = value
		size = value
		pivot_offset = value / 2.0
		_update_visuals_deferred()

@export_group("Colors")
@export var primary_color: Color = Color("#7B22FF")
@export var primary_hover_color: Color = Color("#8D35FF")
@export var secondary_bg: Color = Color("#FFFFFF")
@export var secondary_hover_bg: Color = Color("#FBF7FF")
@export var text_primary: Color = Color("#FFFFFF")
@export var text_secondary: Color = Color("#101018")
@export var accent_color: Color = Color("#8A2BFF")
@export var border_color: Color = Color("#B873FF")
@export var secondary_border_color: Color = Color("#E8D8FF")

@export_group("Hover Animation")
@export var hover_scale: float = 1.035
@export var secondary_hover_scale: float = 1.025
@export var normal_glow_alpha: float = 0.16
@export var hover_glow_alpha: float = 0.42
@export var animation_time: float = 0.16

@export_group("Shape")
@export var corner_radius: int = 16
@export var border_width: int = 2
@export var inner_padding: float = 6.0

@export_group("Text")
@export var primary_font_size: int = 36
@export var secondary_font_size: int = 32

@onready var glow_panel: Panel = get_node_or_null("GlowPanel")
@onready var button_bg: Panel = get_node_or_null("ButtonBg")
@onready var shine: ColorRect = get_node_or_null("Shine")
@onready var content: HBoxContainer = get_node_or_null("Content")
@onready var icon: TextureRect = get_node_or_null("Content/Icon")
@onready var text_label: Label = get_node_or_null("Content/TextLabel")
@onready var click_area: Button = get_node_or_null("ClickArea")

var tween: Tween
var is_hovered: bool = false


func _ready() -> void:
	custom_minimum_size = button_size
	size = button_size
	pivot_offset = button_size / 2.0

	_setup_node_layouts()
	_connect_signals()
	_update_visuals()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		pivot_offset = size / 2.0
		if icon:
			icon.pivot_offset = icon.size / 2.0


func _setup_node_layouts() -> void:
	if glow_panel:
		glow_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		glow_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
		glow_panel.offset_left = 0
		glow_panel.offset_top = 0
		glow_panel.offset_right = 0
		glow_panel.offset_bottom = 0

	if button_bg:
		button_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		button_bg.offset_left = inner_padding
		button_bg.offset_top = inner_padding
		button_bg.offset_right = -inner_padding
		button_bg.offset_bottom = -inner_padding

	if shine:
		shine.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shine.set_anchors_preset(Control.PRESET_FULL_RECT)
		shine.offset_left = inner_padding + 2
		shine.offset_top = inner_padding + 2
		shine.offset_right = -(inner_padding + 2)
		shine.offset_bottom = -(inner_padding + 2)

	if content:
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.set_anchors_preset(Control.PRESET_FULL_RECT)
		content.offset_left = 42
		content.offset_top = 0
		content.offset_right = -42
		content.offset_bottom = 0
		content.alignment = BoxContainer.ALIGNMENT_CENTER
		content.add_theme_constant_override("separation", 34)

	if icon:
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.custom_minimum_size = Vector2(48, 48)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.pivot_offset = icon.size / 2.0

	if text_label:
		text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	if click_area:
		click_area.set_anchors_preset(Control.PRESET_FULL_RECT)
		click_area.offset_left = 0
		click_area.offset_top = 0
		click_area.offset_right = 0
		click_area.offset_bottom = 0
		click_area.flat = true
		click_area.mouse_filter = Control.MOUSE_FILTER_STOP
		click_area.focus_mode = Control.FOCUS_NONE

		var empty_style := StyleBoxEmpty.new()
		click_area.add_theme_stylebox_override("normal", empty_style)
		click_area.add_theme_stylebox_override("hover", empty_style)
		click_area.add_theme_stylebox_override("pressed", empty_style)
		click_area.add_theme_stylebox_override("disabled", empty_style)
		click_area.add_theme_stylebox_override("focus", empty_style)


func _connect_signals() -> void:
	if not click_area:
		push_error("MenuButton is missing ClickArea node.")
		return

	if not click_area.mouse_entered.is_connected(_on_mouse_entered):
		click_area.mouse_entered.connect(_on_mouse_entered)

	if not click_area.mouse_exited.is_connected(_on_mouse_exited):
		click_area.mouse_exited.connect(_on_mouse_exited)

	if not click_area.pressed.is_connected(_on_pressed):
		click_area.pressed.connect(_on_pressed)


func _update_visuals_deferred() -> void:
	if not is_inside_tree():
		return

	call_deferred("_update_visuals")


func _update_visuals() -> void:
	if not is_inside_tree():
		return

	custom_minimum_size = button_size
	size = button_size
	pivot_offset = button_size / 2.0

	if icon:
		icon.texture = icon_texture
		icon.modulate = Color.WHITE if primary_button else accent_color

	if text_label:
		text_label.text = button_text
		text_label.add_theme_font_size_override(
			"font_size",
			primary_font_size if primary_button else secondary_font_size
		)
		text_label.add_theme_color_override(
			"font_color",
			text_primary if primary_button else text_secondary
		)

	_update_styles(is_hovered)


func _update_styles(hovered: bool) -> void:
	_update_button_background(hovered)
	_update_glow(hovered)
	_update_shine(hovered)


func _update_button_background(hovered: bool) -> void:
	if not button_bg:
		return

	var bg_style := StyleBoxFlat.new()

	bg_style.corner_radius_top_left = corner_radius
	bg_style.corner_radius_top_right = corner_radius
	bg_style.corner_radius_bottom_left = corner_radius
	bg_style.corner_radius_bottom_right = corner_radius

	bg_style.border_width_left = border_width
	bg_style.border_width_right = border_width
	bg_style.border_width_top = border_width
	bg_style.border_width_bottom = border_width

	if primary_button:
		bg_style.bg_color = primary_hover_color if hovered else primary_color
		bg_style.border_color = Color("#D9B3FF") if hovered else border_color
	else:
		bg_style.bg_color = secondary_hover_bg if hovered else secondary_bg
		bg_style.border_color = Color("#B873FF") if hovered else secondary_border_color

	bg_style.shadow_color = Color(0, 0, 0, 0.10)
	bg_style.shadow_size = 10
	bg_style.shadow_offset = Vector2(0, 4)

	button_bg.add_theme_stylebox_override("panel", bg_style)


func _update_glow(hovered: bool) -> void:
	if not glow_panel:
		return

	var glow_style := StyleBoxFlat.new()

	glow_style.corner_radius_top_left = corner_radius + 8
	glow_style.corner_radius_top_right = corner_radius + 8
	glow_style.corner_radius_bottom_left = corner_radius + 8
	glow_style.corner_radius_bottom_right = corner_radius + 8

	var glow_alpha := hover_glow_alpha if hovered else normal_glow_alpha

	glow_style.bg_color = Color(
		accent_color.r,
		accent_color.g,
		accent_color.b,
		glow_alpha
	)

	glow_style.shadow_color = Color(
		accent_color.r,
		accent_color.g,
		accent_color.b,
		0.55 if hovered else 0.28
	)

	glow_style.shadow_size = 30 if hovered else 18
	glow_style.shadow_offset = Vector2.ZERO

	glow_panel.add_theme_stylebox_override("panel", glow_style)


func _update_shine(hovered: bool) -> void:
	if not shine:
		return

	shine.visible = primary_button
	shine.color = Color(1, 1, 1, 0.10 if hovered else 0.045)


func _on_mouse_entered() -> void:
	is_hovered = true
	_animate_button(true)


func _on_mouse_exited() -> void:
	is_hovered = false
	_animate_button(false)


func _on_pressed() -> void:
	pressed.emit()

	if tween:
		tween.kill()
		tween = null

	var press_tween := create_tween()
	tween = press_tween

	press_tween.set_trans(Tween.TRANS_QUAD)
	press_tween.set_ease(Tween.EASE_OUT)

	press_tween.tween_property(self, "scale", Vector2.ONE * 0.97, 0.06)

	var return_scale := Vector2.ONE * (hover_scale if primary_button else secondary_hover_scale)
	if not is_hovered:
		return_scale = Vector2.ONE

	press_tween.tween_property(self, "scale", return_scale, 0.10)


func _animate_button(hovered: bool) -> void:
	if tween:
		tween.kill()
		tween = null

	_update_styles(hovered)

	var target_scale := Vector2.ONE
	if hovered:
		target_scale = Vector2.ONE * (hover_scale if primary_button else secondary_hover_scale)

	var new_tween := create_tween()
	tween = new_tween

	new_tween.set_trans(Tween.TRANS_QUAD)
	new_tween.set_ease(Tween.EASE_OUT)
	new_tween.set_parallel(true)

	new_tween.tween_property(self, "scale", target_scale, animation_time)

	if icon:
		var icon_target_scale := Vector2.ONE * 1.12 if hovered else Vector2.ONE
		new_tween.tween_property(icon, "scale", icon_target_scale, animation_time)

	if button_bg:
		var bg_offset := inner_padding
		if hovered:
			bg_offset = max(inner_padding - 2.0, 0.0)

		new_tween.tween_property(button_bg, "offset_left", bg_offset, animation_time)
		new_tween.tween_property(button_bg, "offset_top", bg_offset, animation_time)
		new_tween.tween_property(button_bg, "offset_right", -bg_offset, animation_time)
		new_tween.tween_property(button_bg, "offset_bottom", -bg_offset, animation_time)

	if text_label and not primary_button:
		var text_target_modulate := Color("#7B22FF") if hovered else text_secondary
		new_tween.tween_property(text_label, "modulate", text_target_modulate, animation_time)
