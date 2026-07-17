class_name CombatBlackHole
extends Node2D

signal expired(black_hole: CombatBlackHole)

@export_group("Stats")
@export var duration: float = 5.0
@export var pull_radius: float = 260.0
@export var devour_radius: float = 28.0
@export var pull_strength: float = 620.0
@export var reward_multiplier: float = 0.5
@export var progress_multiplier: float = 0.5

@export_group("Visual")
@export var core_color: Color = Color("#050816")
@export var ring_color: Color = Color("#7437FF")
@export var glow_color: Color = Color(0.45, 0.22, 1.0, 0.22)
@export var danger_color: Color = Color("#FF9700")

@export_group("Animation")
@export var spawn_duration: float = 0.22
@export var rotation_speed: float = 3.6
@export var pulse_speed: float = 6.0

var life_left: float = 5.0
var age: float = 0.0
var alpha: float = 1.0
var pulse: float = 0.0
var is_active: bool = false
var is_expiring: bool = false


func _ready() -> void:
	set_process(false)
	scale = Vector2.ZERO
	queue_redraw()


func play(spawn_position: Vector2) -> void:
	position = spawn_position
	life_left = duration
	age = 0.0
	alpha = 1.0
	pulse = 0.0
	is_active = true
	is_expiring = false

	scale = Vector2.ZERO
	set_process(true)

	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, spawn_duration)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)

	queue_redraw()


func _process(delta: float) -> void:
	if not is_active:
		return

	age += delta
	life_left -= delta
	rotation += rotation_speed * delta
	pulse = sin(age * pulse_speed) * 0.5 + 0.5

	if life_left <= 0.0:
		_start_expire()
		return

	if life_left < 0.5:
		alpha = clampf(life_left / 0.5, 0.0, 1.0)
	else:
		alpha = 1.0

	queue_redraw()


func _start_expire() -> void:
	if is_expiring:
		return

	is_expiring = true
	is_active = false

	var tween := create_tween()
	tween.set_parallel(true)

	tween.tween_property(self, "scale", Vector2.ZERO, 0.22)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_IN)

	tween.tween_method(_set_alpha, alpha, 0.0, 0.18)

	tween.finished.connect(_finish_expire)


func _finish_expire() -> void:
	expired.emit(self)
	queue_free()


func _set_alpha(value: float) -> void:
	alpha = value
	queue_redraw()


func _draw() -> void:
	var final_glow := glow_color
	final_glow.a *= alpha

	var final_core := core_color
	final_core.a *= alpha

	var final_ring := ring_color
	final_ring.a *= alpha

	var final_danger := danger_color
	final_danger.a = alpha * 0.45

	var pulse_radius: float = lerpf(42.0, 58.0, pulse)

	draw_circle(Vector2.ZERO, pull_radius, Color(final_glow.r, final_glow.g, final_glow.b, final_glow.a * 0.22))
	draw_circle(Vector2.ZERO, pulse_radius + 18.0, final_glow)

	draw_arc(Vector2.ZERO, pull_radius, 0.0, TAU, 96, Color(final_ring.r, final_ring.g, final_ring.b, alpha * 0.18), 3.0, true)
	draw_arc(Vector2.ZERO, pulse_radius + 10.0, 0.0, TAU, 72, final_ring, 4.0, true)
	draw_arc(Vector2.ZERO, pulse_radius + 22.0, PI * 0.25, PI * 1.55, 72, final_danger, 3.0, true)

	draw_circle(Vector2.ZERO, devour_radius + 14.0, Color(final_ring.r, final_ring.g, final_ring.b, alpha * 0.35))
	draw_circle(Vector2.ZERO, devour_radius + 6.0, final_core)
	draw_circle(Vector2.ZERO, devour_radius * 0.55, Color.BLACK)

	for i in range(4):
		var angle: float = rotation + float(i) * TAU / 4.0
		var inner: Vector2 = Vector2.RIGHT.rotated(angle) * (devour_radius + 10.0)
		var outer: Vector2 = Vector2.RIGHT.rotated(angle + 0.65) * (pulse_radius + 26.0)

		var arm_color := final_ring
		arm_color.a = alpha * 0.65

		draw_line(inner, outer, arm_color, 4.0, true)
