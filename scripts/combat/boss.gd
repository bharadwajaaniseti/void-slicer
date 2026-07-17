class_name CombatBoss
extends Node2D

signal died(boss: CombatBoss)
signal hp_changed(current_hp: float, max_hp: float)

@export_group("Visual")
@export var boss_color: Color = Color("#050816")
@export var ring_color: Color = Color("#7437FF")
@export var glow_color: Color = Color(0.45, 0.22, 1.0, 0.16)
@export var shadow_color: Color = Color(0.0, 0.0, 0.0, 0.16)

@export_group("Motion")
@export var entrance_speed: float = 260.0
@export var move_speed: float = 180.0

@export_group("Formation Animation")
@export var formation_duration: float = 0.36
@export var formation_overshoot: float = 1.14

@export_group("Death Animation")
@export var death_duration: float = 0.35

var level: int = 1
var radius: float = 58.0
var hp: float = 8000.0
var max_hp: float = 8000.0
var reward: float = 18000.0

var target_position: Vector2 = Vector2.ZERO
var move_timer: float = 0.0
var entrance_complete: bool = false
var is_dying: bool = false

var body_alpha: float = 1.0
var hit_flash: float = 0.0


func setup_boss(
	spawn_position: Vector2,
	final_position: Vector2,
	boss_level: int,
	formed_from_dots: bool = false
) -> void:
	position = spawn_position
	target_position = final_position

	level = boss_level
	radius = 58.0 + float(boss_level) * 3.5
	max_hp = 8000.0 + float(boss_level) * 3500.0
	hp = max_hp
	reward = 18000.0 + float(boss_level) * 6500.0

	move_timer = 0.0
	is_dying = false
	body_alpha = 1.0
	hit_flash = 0.0
	rotation = 0.0

	if formed_from_dots:
		position = final_position
		target_position = final_position
		entrance_complete = true
		play_formation_animation()
	else:
		scale = Vector2.ONE
		entrance_complete = false

	queue_redraw()
	hp_changed.emit(hp, max_hp)


func apply_scaled_stats(
	scaled_health: float,
	scaled_reward: float
) -> void:
	max_hp = maxf(scaled_health, 1.0)
	hp = max_hp
	reward = maxf(scaled_reward, 0.0)
	hp_changed.emit(hp, max_hp)
	queue_redraw()


func update_boss(delta: float, arena_size: Vector2, rng: RandomNumberGenerator) -> void:
	if is_dying:
		return

	if not entrance_complete:
		position = position.move_toward(target_position, entrance_speed * delta)

		if position.distance_to(target_position) <= 4.0:
			position = target_position
			entrance_complete = true
			_pick_new_target(arena_size, rng)

		queue_redraw()
		return

	move_timer -= delta

	if move_timer <= 0.0:
		_pick_new_target(arena_size, rng)

	position = position.move_toward(target_position, move_speed * delta)
	queue_redraw()


func take_damage(amount: float) -> void:
	if is_dying:
		return

	hp -= amount
	hp = maxf(hp, 0.0)

	hp_changed.emit(hp, max_hp)
	play_hit_flash()

	if hp <= 0.0:
		play_death_animation()

	queue_redraw()


func play_formation_animation() -> void:
	scale = Vector2.ONE * 0.16
	body_alpha = 0.0
	queue_redraw()

	var tween := create_tween()
	tween.set_parallel(true)

	tween.tween_property(self, "scale", Vector2.ONE * formation_overshoot, formation_duration * 0.65)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)

	tween.tween_method(_set_body_alpha, 0.0, 1.0, formation_duration * 0.7)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

	tween.chain().tween_property(self, "scale", Vector2.ONE, formation_duration * 0.35)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)


func play_hit_flash() -> void:
	hit_flash = 1.0
	queue_redraw()

	var tween := create_tween()
	tween.tween_method(_set_hit_flash, 1.0, 0.0, 0.14)


func play_death_animation() -> void:
	if is_dying:
		return

	is_dying = true

	var tween := create_tween()
	tween.set_parallel(true)

	tween.tween_property(self, "scale", Vector2.ONE * 1.12, death_duration * 0.28)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)

	tween.chain().tween_property(self, "scale", Vector2.ZERO, death_duration * 0.72)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_IN)

	tween.tween_method(_set_body_alpha, 1.0, 0.0, death_duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

	tween.tween_property(self, "rotation", rotation + randf_range(-0.45, 0.45), death_duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

	tween.finished.connect(_finish_death)


func _finish_death() -> void:
	died.emit(self)
	queue_free()


func _pick_new_target(arena_size: Vector2, rng: RandomNumberGenerator) -> void:
	var padding: float = radius + 70.0
	var bottom_safe_area: float = 130.0

	target_position = Vector2(
		rng.randf_range(padding, maxf(padding, arena_size.x - padding)),
		rng.randf_range(padding, maxf(padding, arena_size.y - bottom_safe_area))
	)

	move_timer = rng.randf_range(1.4, 2.6)


func _set_body_alpha(value: float) -> void:
	body_alpha = value
	queue_redraw()


func _set_hit_flash(value: float) -> void:
	hit_flash = value
	queue_redraw()


func _draw() -> void:
	var hp_ratio: float = clampf(hp / max_hp, 0.0, 1.0)

	var final_glow := glow_color
	final_glow.a *= body_alpha

	var final_shadow := shadow_color
	final_shadow.a *= body_alpha

	var final_body := boss_color
	final_body.a *= body_alpha

	var final_ring := ring_color
	final_ring.a *= body_alpha

	draw_circle(Vector2.ZERO, radius + 16.0, final_glow)
	draw_circle(Vector2.ZERO, radius + 7.0, final_shadow)
	draw_circle(Vector2.ZERO, radius, final_body)

	draw_arc(
		Vector2.ZERO,
		radius + 14.0,
		-PI * 0.5,
		-PI * 0.5 + TAU * hp_ratio,
		96,
		final_ring,
		7.0,
		true
	)

	if hit_flash > 0.01:
		var flash_color := Color.WHITE
		flash_color.a = hit_flash * 0.28 * body_alpha
		draw_circle(Vector2.ZERO, radius + 4.0, flash_color)
