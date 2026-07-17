class_name SlashFx
extends Node2D

@export_group("Visual")
@export var glow_color: Color = Color(1.0, 0.55, 0.0, 0.32)
@export var core_color: Color = Color(1.0, 0.72, 0.02, 1.0)
@export var tip_color: Color = Color(1.0, 0.62, 0.0, 1.0)

@export_group("Shape")
@export var glow_width: float = 22.0
@export var core_width: float = 7.0
@export var tip_radius: float = 8.0

@export_group("Animation")
@export var lifetime: float = 0.18
@export var shrink_end: bool = true

var from_position: Vector2 = Vector2.ZERO
var to_position: Vector2 = Vector2.ZERO
var life_left: float = 0.18
var current_alpha: float = 1.0


func _ready() -> void:
	set_process(false)


func play(start_position: Vector2, end_position: Vector2) -> void:
	from_position = start_position
	to_position = end_position
	life_left = lifetime
	current_alpha = 1.0

	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	life_left -= delta

	if life_left <= 0.0:
		queue_free()
		return

	current_alpha = clampf(life_left / lifetime, 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	var draw_from: Vector2 = from_position
	var draw_to: Vector2 = to_position

	if shrink_end:
		var visible_ratio: float = current_alpha
		draw_from = to_position.lerp(from_position, visible_ratio)

	var final_glow := glow_color
	final_glow.a *= current_alpha

	var final_core := core_color
	final_core.a *= current_alpha

	var final_tip := tip_color
	final_tip.a *= current_alpha

	draw_line(draw_from, draw_to, final_glow, glow_width, true)
	draw_line(draw_from, draw_to, final_core, core_width, true)
	draw_circle(draw_to, tip_radius, final_tip)
