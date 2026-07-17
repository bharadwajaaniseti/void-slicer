class_name CombatBeamFx
extends Node2D

@export_group("Visual")
@export var core_width: float = 3.0
@export var glow_width: float = 10.0
@export var start_pop_radius: float = 5.0
@export var end_pop_radius: float = 7.0

@export_group("Animation")
@export var lifetime: float = 0.12
@export var beam_grow_time: float = 0.035

var from_position: Vector2 = Vector2.ZERO
var to_position: Vector2 = Vector2.ZERO
var beam_color: Color = Color("#7437FF")

var life_left: float = 0.12
var age: float = 0.0
var alpha: float = 1.0


func _ready() -> void:
	set_process(false)


func play(start_position: Vector2, end_position: Vector2, color: Color) -> void:
	from_position = start_position
	to_position = end_position
	beam_color = color

	life_left = lifetime
	age = 0.0
	alpha = 1.0

	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	age += delta
	life_left -= delta

	if life_left <= 0.0:
		queue_free()
		return

	alpha = clampf(life_left / lifetime, 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	var grow_ratio: float = 1.0

	if beam_grow_time > 0.0:
		grow_ratio = clampf(age / beam_grow_time, 0.0, 1.0)

	var visible_to: Vector2 = from_position.lerp(to_position, grow_ratio)

	var glow_color := beam_color
	glow_color.a = alpha * 0.25

	var core_color := beam_color
	core_color.a = alpha

	var start_color := beam_color
	start_color.a = alpha * 0.8

	var end_color := beam_color
	end_color.a = alpha * 0.95

	draw_line(from_position, visible_to, glow_color, glow_width, true)
	draw_line(from_position, visible_to, core_color, core_width, true)

	draw_circle(from_position, start_pop_radius, start_color)
	draw_circle(visible_to, end_pop_radius, end_color)
