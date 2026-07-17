class_name CombatTurret
extends Node2D

@export_group("Stats")
@export var kind: String = "turret"
@export var damage: float = 24.0
@export var fire_rate: float = 0.52
@export var range: float = 430.0

@export_group("Visual")
@export var slot_radius: float = 25.0
@export var body_radius: float = 18.0
@export var barrel_length: float = 30.0
@export var barrel_width: float = 7.0
@export var muzzle_radius: float = 5.5

@export var turret_color: Color = Color("#111827")
@export var tesla_color: Color = Color("#0077FF")
@export var laser_color: Color = Color("#7437FF")
@export var cannon_color: Color = Color("#FF9700")

var cooldown: float = 0.0
var aim_direction: Vector2 = Vector2.UP
var weapon_id: StringName = &"turret"
var slot_id: String = ""
var display_name: String = "Basic Turret"
var projectiles_per_attack: int = 1
var ricochet_count: int = 0
var ricochet_damage_multiplier: float = 0.6
var explosion_every_n_attacks: int = 0
var explosion_damage_multiplier: float = 0.0
var attack_counter: int = 0


func setup_turret(turret_position: Vector2, turret_kind: String) -> void:
	position = turret_position
	kind = turret_kind
	cooldown = 0.0
	attack_counter = 0
	weapon_id = StringName(_normalize_weapon_id(turret_kind))
	display_name = _get_default_display_name(turret_kind)
	projectiles_per_attack = 1
	ricochet_count = 0
	ricochet_damage_multiplier = 0.6
	explosion_every_n_attacks = 0
	explosion_damage_multiplier = 0.0

	match kind:
		"tesla":
			damage = 24.0
			fire_rate = 0.38
			range = 460.0
		"laser":
			damage = 36.0
			fire_rate = 0.62
			range = 520.0
		"cannon":
			damage = 60.0
			fire_rate = 1.15
			range = 470.0
		_:
			damage = 24.0
			fire_rate = 0.52
			range = 430.0

	queue_redraw()


func apply_weapon_runtime_state(state: Variant) -> void:
	if state == null:
		return

	weapon_id = state.weapon_id
	display_name = state.display_name
	damage = state.calculated_damage
	fire_rate = state.calculated_attack_interval
	projectiles_per_attack = maxi(state.projectiles_per_attack, 1)
	ricochet_count = maxi(state.ricochet_count, 0)
	ricochet_damage_multiplier = maxf(state.ricochet_damage_multiplier, 0.0)
	explosion_every_n_attacks = maxi(state.explosion_every_n_attacks, 0)
	explosion_damage_multiplier = maxf(state.explosion_damage_multiplier, 0.0)
	queue_redraw()


func update_cooldown(delta: float) -> void:
	cooldown -= delta


func can_fire() -> bool:
	return cooldown <= 0.0


func mark_fired() -> void:
	cooldown = fire_rate
	attack_counter += 1
	play_fire_pulse()


func aim_at(target_position: Vector2) -> void:
	var direction := target_position - position

	if direction.length_squared() <= 0.001:
		return

	aim_direction = direction.normalized()
	queue_redraw()


func get_muzzle_position() -> Vector2:
	return position + aim_direction.normalized() * barrel_length


func get_weapon_color() -> Color:
	match kind:
		"tesla":
			return tesla_color
		"laser":
			return laser_color
		"cannon":
			return cannon_color
		_:
			return turret_color


func _normalize_weapon_id(raw_weapon_id: String) -> String:
	var normalized_id: String = raw_weapon_id.strip_edges().to_lower()

	match normalized_id:
		"tesla":
			return "tesla_coil"
		"pulse":
			return "pulse_cannon"
		"cannon":
			return "pulse_cannon"
		"motor":
			return "mortar"
		_:
			return normalized_id


func _get_default_display_name(turret_kind: String) -> String:
	match turret_kind:
		"tesla":
			return "Tesla Coil"
		"laser":
			return "Laser"
		"cannon":
			return "Pulse Cannon"
		"motor":
			return "Mortar"
		_:
			return "Basic Turret"


func play_fire_pulse() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE * 1.12, 0.045)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

	tween.tween_property(self, "scale", Vector2.ONE, 0.09)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)


func _draw() -> void:
	var slot_color := get_weapon_color()

	draw_circle(Vector2.ZERO, slot_radius, Color(1.0, 1.0, 1.0, 0.95))
	draw_circle(Vector2.ZERO, slot_radius - 2.0, Color(0.0, 0.0, 0.0, 0.18))
	draw_circle(Vector2.ZERO, body_radius, slot_color)

	var barrel_end := aim_direction.normalized() * barrel_length

	draw_line(Vector2.ZERO, barrel_end, slot_color, barrel_width, true)
	draw_circle(barrel_end, muzzle_radius, Color.WHITE)

	if cooldown > 0.0:
		var ratio: float = clampf(cooldown / fire_rate, 0.0, 1.0)
		var arc_color := Color.WHITE
		arc_color.a = 0.45

		draw_arc(
			Vector2.ZERO,
			slot_radius + 4.0,
			-PI * 0.5,
			-PI * 0.5 + TAU * (1.0 - ratio),
			32,
			arc_color,
			2.0,
			true
		)
