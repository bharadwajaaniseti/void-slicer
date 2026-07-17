class_name ImpactFx
extends Node2D

@export_group("Visual")
@export var start_radius: float = 4.0
@export var end_radius: float = 18.0
@export var core_radius: float = 4.5
@export var ring_width: float = 3.0

@export_group("Animation")
@export var lifetime: float = 0.18
@export var pop_scale: float = 1.15

var fx_color: Color = Color.WHITE
var life_left: float = 0.18
var age: float = 0.0
var alpha: float = 1.0
var radius: float = 4.0


func _ready() -> void:
	set_process(false)


func play(spawn_position: Vector2, color: Color = Color.WHITE) -> void:
	position = spawn_position
	fx_color = color

	life_left = lifetime
	age = 0.0
	alpha = 1.0
	radius = start_radius
	scale = Vector2.ONE

	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	age += delta
	life_left -= delta

	if life_left <= 0.0:
		queue_free()
		return

	var t: float = clampf(age / lifetime, 0.0, 1.0)

	alpha = 1.0 - t
	radius = lerpf(start_radius, end_radius, t)

	var scale_value: float = lerpf(pop_scale, 1.0, t)
	scale = Vector2.ONE * scale_value

	queue_redraw()


func _draw() -> void:
	var ring_color := fx_color
	ring_color.a = alpha * 0.85

	var glow_color := fx_color
	glow_color.a = alpha * 0.22

	var core_color := fx_color
	core_color.a = alpha

	draw_circle(Vector2.ZERO, radius + 5.0, glow_color)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, ring_color, ring_width, true)
	draw_circle(Vector2.ZERO, core_radius, core_color)
