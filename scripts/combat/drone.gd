class_name CombatDrone
extends Node2D

@export_group("Stats")
@export var damage: float = 18.0
@export var move_speed: float = 260.0
@export var target_range: float = 300.0
@export var hit_radius: float = 22.0
@export var hit_interval: float = 0.25

@export_group("Visual")
@export var drone_radius: float = 12.0
@export var body_color: Color = Color("#7437FF")
@export var core_color: Color = Color.WHITE
@export var wing_color: Color = Color("#050816")
@export var glow_color: Color = Color(0.45, 0.22, 1.0, 0.22)

@export_group("Movement")
@export var wander_speed_multiplier: float = 0.55
@export var turn_strength: float = 7.0
@export var edge_padding: float = 34.0

var velocity: Vector2 = Vector2.ZERO
var hit_cooldown: float = 0.0
var wander_timer: float = 0.0
var wander_direction: Vector2 = Vector2.RIGHT
var visual_spin: float = 0.0
var pulse: float = 0.0
var drone_index: int = 0


func _ready() -> void:
	set_process(false)
	queue_redraw()


func setup_drone(spawn_position: Vector2, index: int) -> void:
	position = spawn_position
	drone_index = index

	var angle: float = TAU * float(index) / 8.0
	wander_direction = Vector2.RIGHT.rotated(angle).normalized()
	velocity = wander_direction * move_speed * wander_speed_multiplier

	hit_cooldown = 0.0
	wander_timer = 0.0
	visual_spin = randf_range(0.0, TAU)
	pulse = 0.0

	set_process(false)
	queue_redraw()


func update_drone(
	delta: float,
	arena_size: Vector2,
	target_position: Vector2,
	has_target: bool
) -> void:
	hit_cooldown = maxf(0.0, hit_cooldown - delta)
	visual_spin += delta * 7.0
	pulse = sin(Time.get_ticks_msec() / 120.0 + float(drone_index)) * 0.5 + 0.5

	if has_target:
		_chase_target(delta, target_position)
	else:
		_wander(delta)

	position += velocity * delta
	_clamp_inside_arena(arena_size)

	if velocity.length_squared() > 0.01:
		rotation = velocity.angle()

	queue_redraw()


func can_hit_target(target_position: Vector2) -> bool:
	if hit_cooldown > 0.0:
		return false

	return position.distance_to(target_position) <= hit_radius


func mark_hit() -> void:
	hit_cooldown = hit_interval
	_play_hit_pulse()


func _chase_target(delta: float, target_position: Vector2) -> void:
	var to_target: Vector2 = target_position - position

	if to_target.length_squared() <= 0.01:
		return

	var desired_velocity: Vector2 = to_target.normalized() * move_speed
	var blend: float = clampf(delta * turn_strength, 0.0, 1.0)

	velocity = velocity.lerp(desired_velocity, blend)


func _wander(delta: float) -> void:
	wander_timer -= delta

	if wander_timer <= 0.0:
		wander_timer = randf_range(0.45, 1.1)
		wander_direction = Vector2.RIGHT.rotated(randf_range(0.0, TAU)).normalized()

	var desired_velocity: Vector2 = wander_direction * move_speed * wander_speed_multiplier
	var blend: float = clampf(delta * 3.5, 0.0, 1.0)

	velocity = velocity.lerp(desired_velocity, blend)


func _clamp_inside_arena(arena_size: Vector2) -> void:
	var min_x: float = edge_padding
	var max_x: float = arena_size.x - edge_padding
	var min_y: float = edge_padding
	var max_y: float = arena_size.y - 95.0

	if position.x < min_x:
		position.x = min_x
		velocity.x = absf(velocity.x)
		wander_direction.x = absf(wander_direction.x)

	if position.x > max_x:
		position.x = max_x
		velocity.x = -absf(velocity.x)
		wander_direction.x = -absf(wander_direction.x)

	if position.y < min_y:
		position.y = min_y
		velocity.y = absf(velocity.y)
		wander_direction.y = absf(wander_direction.y)

	if position.y > max_y:
		position.y = max_y
		velocity.y = -absf(velocity.y)
		wander_direction.y = -absf(wander_direction.y)


func _play_hit_pulse() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE * 1.18, 0.05)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

	tween.tween_property(self, "scale", Vector2.ONE, 0.10)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)


func _draw() -> void:
	var glow_alpha: float = 0.16 + pulse * 0.16
	var final_glow := glow_color
	final_glow.a = glow_alpha

	draw_circle(Vector2.ZERO, drone_radius + 8.0, final_glow)

	var left_wing: Vector2 = Vector2.LEFT.rotated(0.35) * (drone_radius + 7.0)
	var right_wing: Vector2 = Vector2.RIGHT.rotated(-0.35) * (drone_radius + 7.0)
	var nose: Vector2 = Vector2.RIGHT * (drone_radius + 8.0)

	var body_points := PackedVector2Array([
		nose,
		left_wing,
		Vector2.LEFT * 3.0,
		right_wing
	])

	var body_colors := PackedColorArray([
		body_color,
		wing_color,
		body_color,
		wing_color
	])

	if _is_valid_polygon(body_points):
		draw_polygon(body_points, body_colors)

	draw_circle(Vector2.ZERO, drone_radius, body_color)
	draw_circle(Vector2.ZERO, drone_radius * 0.42, core_color)

	var ring_color := core_color
	ring_color.a = 0.45
	draw_arc(Vector2.ZERO, drone_radius + 4.0, visual_spin, visual_spin + PI * 1.35, 32, ring_color, 2.0, true)

func _is_valid_polygon(points: PackedVector2Array) -> bool:
	if points.size() < 3:
		return false

	var area: float = 0.0

	for i in range(points.size()):
		var current: Vector2 = points[i]
		var next: Vector2 = points[(i + 1) % points.size()]
		area += current.x * next.y - next.x * current.y

	return absf(area) > 0.01
