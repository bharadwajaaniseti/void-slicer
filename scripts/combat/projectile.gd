class_name CombatProjectile
extends Area2D

signal expired(projectile: CombatProjectile)

@export_group("Motion")
@export var speed: float = 760.0
@export var lifetime: float = 1.6

@export_group("Visual")
@export var radius: float = 5.0
@export var glow_radius: float = 10.0
@export var projectile_color: Color = Color("#7437FF")

var velocity: Vector2 = Vector2.ZERO
var damage: float = 1.0
var life_left: float = 1.6
var is_expiring: bool = false


func _ready() -> void:
	input_pickable = false
	monitoring = false
	monitorable = false
	_update_collision()
	queue_redraw()


func setup_projectile(
	start_position: Vector2,
	direction: Vector2,
	projectile_damage: float,
	new_color: Color
) -> void:
	position = start_position
	damage = projectile_damage
	projectile_color = new_color
	life_left = lifetime

	if direction.length_squared() <= 0.001:
		velocity = Vector2.UP * speed
	else:
		velocity = direction.normalized() * speed

	rotation = velocity.angle()
	_update_collision()
	queue_redraw()


func update_projectile(delta: float) -> void:
	if is_expiring:
		return

	position += velocity * delta
	life_left -= delta

	if life_left <= 0.0:
		expire()


func expire() -> void:
	if is_expiring:
		return

	is_expiring = true
	expired.emit(self)
	queue_free()


func is_outside_area(area_size: Vector2, margin: float = 40.0) -> bool:
	if position.x < -margin:
		return true

	if position.x > area_size.x + margin:
		return true

	if position.y < -margin:
		return true

	if position.y > area_size.y + margin:
		return true

	return false


func _update_collision() -> void:
	var collision := get_node_or_null("CollisionShape2D") as CollisionShape2D

	if collision == null:
		collision = CollisionShape2D.new()
		collision.name = "CollisionShape2D"
		add_child(collision)

	var circle := CircleShape2D.new()
	circle.radius = glow_radius
	collision.shape = circle


func _draw() -> void:
	draw_circle(
		Vector2.ZERO,
		glow_radius,
		Color(projectile_color.r, projectile_color.g, projectile_color.b, 0.22)
	)

	draw_circle(Vector2.ZERO, radius, projectile_color)

	var trail_color := projectile_color
	trail_color.a = 0.28

	var trail_start := -Vector2.RIGHT * 18.0
	draw_line(trail_start, Vector2.ZERO, trail_color, radius * 1.25, true)
