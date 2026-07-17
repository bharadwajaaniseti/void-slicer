class_name CombatBoss
extends Node2D

signal died(boss: CombatBoss)
signal hp_changed(current_hp: float, max_hp: float)

@export_group("Visual")
@export var boss_color: Color = Color("#050816")
@export var ring_color: Color = Color("#7437FF")
@export var glow_color: Color = Color(0.45, 0.22, 1.0, 0.16)
@export var shadow_color: Color = Color(0.0, 0.0, 0.0, 0.16)
@export var marked_ring_color: Color = Color("#21B77A")
@export var weak_point_ring_color: Color = Color("#FF9700")

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
var is_marked: bool = false
var mark_duration_remaining: float = 0.0
var mark_damage_multiplier: float = 1.125
var mark_cash_multiplier: float = 1.0
var mark_source_combo: int = 0
var marked_by_slice_id: int = 0
var weak_point_exposed: bool = false
var weak_point_duration_remaining: float = 0.0
var weak_point_critical_chance_bonus: float = 0.15
var weak_point_critical_damage_bonus: float = 0.50


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
	clear_slice_status()

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


func update_slice_status(delta: float) -> void:
	var changed: bool = false

	if is_marked:
		mark_duration_remaining = maxf(mark_duration_remaining - delta, 0.0)
		changed = true

		if mark_duration_remaining <= 0.0:
			is_marked = false
			mark_damage_multiplier = 1.0
			mark_cash_multiplier = 1.0
			mark_source_combo = 0
			marked_by_slice_id = 0

	if weak_point_exposed:
		weak_point_duration_remaining = maxf(weak_point_duration_remaining - delta, 0.0)
		changed = true

		if weak_point_duration_remaining <= 0.0:
			weak_point_exposed = false

	if changed:
		queue_redraw()


func clear_slice_status() -> void:
	is_marked = false
	mark_duration_remaining = 0.0
	mark_damage_multiplier = 1.0
	mark_cash_multiplier = 1.0
	mark_source_combo = 0
	marked_by_slice_id = 0
	weak_point_exposed = false
	weak_point_duration_remaining = 0.0


func apply_slice_mark(
	duration: float,
	damage_multiplier: float,
	cash_multiplier: float,
	source_combo: int,
	slice_id: int
) -> void:
	is_marked = true
	mark_duration_remaining = maxf(duration, mark_duration_remaining)
	mark_damage_multiplier = maxf(mark_damage_multiplier, damage_multiplier)
	mark_cash_multiplier = maxf(mark_cash_multiplier, cash_multiplier)
	mark_source_combo = maxi(mark_source_combo, source_combo)
	marked_by_slice_id = slice_id
	queue_redraw()


func expose_weak_point(
	duration: float,
	critical_chance_bonus: float,
	critical_damage_bonus: float
) -> void:
	weak_point_exposed = true
	weak_point_duration_remaining = maxf(duration, weak_point_duration_remaining)
	weak_point_critical_chance_bonus = maxf(
		weak_point_critical_chance_bonus,
		critical_chance_bonus
	)
	weak_point_critical_damage_bonus = maxf(
		weak_point_critical_damage_bonus,
		critical_damage_bonus
	)
	queue_redraw()


func apply_damage_context(context: Variant) -> void:
	if context == null:
		return

	var amount: float = float(context.final_amount)

	if _should_mark_amplify_damage(context):
		amount *= maxf(mark_damage_multiplier, 1.0)

	if _should_critical_affect_damage(context):
		var base_critical_chance: float = float(
			context.metadata.get("critical_chance", 0.0)
		)
		var base_critical_multiplier: float = float(
			context.metadata.get("critical_damage_multiplier", 1.0)
		)
		var chance_bonus: float = 0.0
		var multiplier_bonus: float = 0.0

		if weak_point_exposed:
			chance_bonus = weak_point_critical_chance_bonus
			multiplier_bonus = weak_point_critical_damage_bonus

		var critical_chance: float = clampf(base_critical_chance + chance_bonus, 0.0, 1.0)
		var critical_multiplier: float = maxf(base_critical_multiplier + multiplier_bonus, 1.0)

		if randf() <= critical_chance:
			context.is_critical = true
			amount *= critical_multiplier

	context.final_amount = maxf(amount, 0.0)
	take_damage(context.final_amount)


func _should_mark_amplify_damage(context: Variant) -> bool:
	if not is_marked:
		return false

	if not bool(context.can_trigger_on_hit_effects):
		return false

	if bool(context.is_slice_damage):
		return false

	var source_type: StringName = StringName(context.source_type)
	return source_type == &"weapon" or source_type == &"projectile" or source_type == &"explosion" or source_type == &"damage_over_time"


func _should_critical_affect_damage(context: Variant) -> bool:
	if not bool(context.can_trigger_on_hit_effects):
		return false

	if bool(context.is_slice_damage):
		return false

	var source_type: StringName = StringName(context.source_type)
	return source_type == &"weapon" or source_type == &"projectile" or source_type == &"explosion"


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

	if is_marked:
		var mark_color: Color = marked_ring_color
		mark_color.a = 0.88 * body_alpha
		draw_arc(Vector2.ZERO, radius + 24.0, 0.0, TAU, 96, mark_color, 4.0, true)

	if weak_point_exposed:
		var weak_color: Color = weak_point_ring_color
		weak_color.a = 0.95 * body_alpha
		draw_circle(Vector2(0.0, -radius * 0.35), 8.0, weak_color)
