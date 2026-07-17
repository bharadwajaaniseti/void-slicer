class_name DotEnemy
extends Area2D

signal died(dot: DotEnemy)
signal merge_finished(dot: DotEnemy)

@export_group("Stats")
@export var radius: float = 12.0
@export var max_hp: float = 50.0
@export var reward: float = 100.0
@export var progress_reward: float = 25.0
@export var velocity: Vector2 = Vector2.ZERO

@export_group("Visual")
@export var dot_color: Color = Color("#050816")
@export var outline_color: Color = Color("#FFFFFF")
@export var outline_width: float = 2.0
@export var shadow_color: Color = Color(0.0, 0.0, 0.0, 0.12)

@export_group("Spawn Animation")
@export var spawn_duration: float = 0.22
@export var spawn_overshoot: float = 1.18

@export_group("Hit Animation")
@export var hit_scale: float = 1.12
@export var hit_duration: float = 0.14

@export_group("Death Animation")
@export var death_duration: float = 0.28
@export var slash_color: Color = Color("#FFFFFF")
@export var slash_width: float = 3.0
@export var slash_length_multiplier: float = 2.4

@export_group("Slice Status")
@export var marked_ring_color: Color = Color("#21B77A")
@export var weak_point_ring_color: Color = Color("#FF9700")

var hp: float = 50.0
var is_dying: bool = false
var is_merging: bool = false

var body_alpha: float = 1.0
var slash_alpha: float = 0.0
var hit_flash: float = 0.0
var slash_angle: float = 0.0
var show_slash: bool = false
var is_marked: bool = false
var mark_duration_remaining: float = 0.0
var mark_damage_multiplier: float = 1.25
var mark_cash_multiplier: float = 1.20
var mark_source_combo: int = 0
var marked_by_slice_id: int = 0
var weak_point_exposed: bool = false
var weak_point_duration_remaining: float = 0.0
var weak_point_critical_chance_bonus: float = 0.15
var weak_point_critical_damage_bonus: float = 0.50


func _ready() -> void:
	input_pickable = false
	_update_collision()
	play_spawn_animation()


func setup_dot(
	new_position: Vector2,
	wave_number: int,
	rng: RandomNumberGenerator
) -> void:
	position = new_position

	radius = rng.randf_range(7.0, 16.0)
	max_hp = rng.randf_range(28.0, 70.0) + float(wave_number) * 0.4
	hp = max_hp

	reward = rng.randf_range(90.0, 260.0) + float(wave_number) * 8.0
	progress_reward = rng.randf_range(18.0, 45.0)

	velocity = Vector2(
		rng.randf_range(-26.0, 26.0),
		rng.randf_range(-20.0, 20.0)
	)

	is_dying = false
	is_merging = false
	body_alpha = 1.0
	slash_alpha = 0.0
	hit_flash = 0.0
	show_slash = false
	clear_slice_status()

	_update_collision()
	queue_redraw()


func apply_scaled_stats(
	scaled_health: float,
	scaled_reward: float,
	scaled_progress_reward: float
) -> void:
	max_hp = maxf(scaled_health, 1.0)
	hp = max_hp
	reward = maxf(scaled_reward, 0.0)
	progress_reward = maxf(scaled_progress_reward, 0.0)
	_update_collision()
	queue_redraw()


func _update_collision() -> void:
	var collision := get_node_or_null("CollisionShape2D") as CollisionShape2D

	if collision == null:
		collision = CollisionShape2D.new()
		collision.name = "CollisionShape2D"
		add_child(collision)

	var circle := CircleShape2D.new()
	circle.radius = radius
	collision.shape = circle


func update_motion(delta: float, arena_size: Vector2) -> void:
	if is_dying:
		return

	if is_merging:
		return

	position += velocity * delta

	var min_x: float = 28.0
	var max_x: float = arena_size.x - 28.0
	var min_y: float = 28.0
	var max_y: float = arena_size.y - 90.0

	if position.x < min_x or position.x > max_x:
		velocity.x *= -1.0

	if position.y < min_y or position.y > max_y:
		velocity.y *= -1.0

	position.x = clampf(position.x, min_x, max_x)
	position.y = clampf(position.y, min_y, max_y)


func update_slice_status(delta: float) -> void:
	var changed: bool = false

	if is_marked:
		mark_duration_remaining = maxf(
			mark_duration_remaining - delta,
			0.0
		)
		changed = true

		if mark_duration_remaining <= 0.0:
			is_marked = false
			mark_damage_multiplier = 1.0
			mark_cash_multiplier = 1.0
			mark_source_combo = 0
			marked_by_slice_id = 0

	if weak_point_exposed:
		weak_point_duration_remaining = maxf(
			weak_point_duration_remaining - delta,
			0.0
		)
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
	weak_point_duration_remaining = maxf(
		duration,
		weak_point_duration_remaining
	)
	weak_point_critical_chance_bonus = maxf(
		weak_point_critical_chance_bonus,
		critical_chance_bonus
	)
	weak_point_critical_damage_bonus = maxf(
		weak_point_critical_damage_bonus,
		critical_damage_bonus
	)
	queue_redraw()


func get_mark_cash_multiplier() -> float:
	if not is_marked:
		return 1.0

	return maxf(mark_cash_multiplier, 1.0)


func apply_damage_context(context: Variant, attack_angle: float = 0.0) -> void:
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
	take_damage(context.final_amount, attack_angle)


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


func take_damage(amount: float, attack_angle: float = 0.0) -> void:
	if is_dying:
		return

	if is_merging:
		return

	hp -= amount
	slash_angle = attack_angle

	if hp <= 0.0:
		play_death_animation()
	else:
		play_hit_animation()


func play_merge_to(target_position: Vector2, duration: float) -> void:
	if is_dying:
		return

	is_merging = true
	monitoring = false
	monitorable = false
	input_pickable = false
	show_slash = false
	slash_alpha = 0.0
	hit_flash = 0.0

	var random_offset := Vector2(
		randf_range(-5.0, 5.0),
		randf_range(-5.0, 5.0)
	)

	var final_position := target_position + random_offset

	var tween := create_tween()
	tween.set_parallel(true)

	tween.tween_property(self, "position", final_position, duration)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_IN)

	tween.tween_property(self, "scale", Vector2.ONE * 0.16, duration)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_IN)

	tween.tween_property(self, "rotation", rotation + randf_range(-1.8, 1.8), duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)

	tween.tween_method(_set_body_alpha, body_alpha, 0.35, duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN)

	tween.finished.connect(_finish_merge)


func _finish_merge() -> void:
	merge_finished.emit(self)


func play_spawn_animation() -> void:
	scale = Vector2.ZERO
	modulate.a = 0.0
	rotation = randf_range(-0.18, 0.18)

	var tween := create_tween()
	tween.set_parallel(true)

	tween.tween_property(self, "scale", Vector2.ONE * spawn_overshoot, spawn_duration * 0.65)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)

	tween.tween_property(self, "modulate:a", 1.0, spawn_duration * 0.55)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

	tween.tween_property(self, "rotation", 0.0, spawn_duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

	tween.chain().tween_property(self, "scale", Vector2.ONE, spawn_duration * 0.35)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)


func play_hit_animation() -> void:
	show_slash = true
	slash_alpha = 1.0
	hit_flash = 1.0
	queue_redraw()

	var tween := create_tween()
	tween.set_parallel(true)

	tween.tween_property(self, "scale", Vector2.ONE * hit_scale, hit_duration * 0.4)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

	tween.chain().tween_property(self, "scale", Vector2.ONE, hit_duration * 0.6)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

	tween.tween_method(_set_hit_flash, 1.0, 0.0, hit_duration)
	tween.tween_method(_set_slash_alpha, 1.0, 0.0, hit_duration)


func play_death_animation() -> void:
	if is_dying:
		return

	is_dying = true
	monitoring = false
	monitorable = false
	input_pickable = false

	show_slash = true
	slash_alpha = 1.0
	hit_flash = 1.0
	queue_redraw()

	var tween := create_tween()
	tween.set_parallel(true)

	tween.tween_property(self, "scale", Vector2.ONE * 1.16, death_duration * 0.28)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)

	tween.chain().tween_property(self, "scale", Vector2.ZERO, death_duration * 0.72)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_IN)

	tween.tween_method(_set_body_alpha, 1.0, 0.0, death_duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

	tween.tween_method(_set_slash_alpha, 1.0, 0.0, death_duration * 0.85)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

	tween.tween_property(self, "rotation", rotation + randf_range(-0.35, 0.35), death_duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

	tween.finished.connect(_finish_death)


func _finish_death() -> void:
	died.emit(self)
	queue_free()


func _set_body_alpha(value: float) -> void:
	body_alpha = value
	queue_redraw()


func _set_hit_flash(value: float) -> void:
	hit_flash = value
	queue_redraw()


func _set_slash_alpha(value: float) -> void:
	slash_alpha = value

	if slash_alpha <= 0.01:
		show_slash = false

	queue_redraw()


func _draw() -> void:
	var final_shadow_color := shadow_color
	final_shadow_color.a *= body_alpha

	var final_dot_color := dot_color
	final_dot_color.a *= body_alpha

	var final_outline_color := outline_color
	final_outline_color.a *= body_alpha

	draw_circle(Vector2(2.0, 3.0), radius + 3.0, final_shadow_color)
	draw_circle(Vector2.ZERO, radius, final_dot_color)

	if outline_width > 0.0:
		draw_arc(
			Vector2.ZERO,
			radius,
			0.0,
			TAU,
			64,
			final_outline_color,
			outline_width,
			true
		)

	var hp_ratio: float = clampf(hp / max_hp, 0.0, 1.0)

	if hp_ratio < 1.0 and not is_dying and not is_merging:
		_draw_health_bar(hp_ratio)

	if hit_flash > 0.01:
		var flash_color := Color.WHITE
		flash_color.a = hit_flash * 0.35 * body_alpha
		draw_circle(Vector2.ZERO, radius + 2.0, flash_color)

	if show_slash and slash_alpha > 0.01:
		_draw_slash()

	if is_marked:
		var mark_color: Color = marked_ring_color
		mark_color.a = 0.85 * body_alpha
		draw_arc(
			Vector2.ZERO,
			radius + 5.0,
			0.0,
			TAU,
			48,
			mark_color,
			2.0,
			true
		)

	if weak_point_exposed:
		var weak_color: Color = weak_point_ring_color
		weak_color.a = 0.9 * body_alpha
		draw_circle(Vector2(0.0, -radius * 0.45), 3.5, weak_color)


func _draw_health_bar(hp_ratio: float) -> void:
	var bar_width: float = radius * 2.4
	var bar_height: float = 3.0
	var bar_pos := Vector2(-bar_width * 0.5, -radius - 10.0)

	draw_rect(
		Rect2(bar_pos, Vector2(bar_width, bar_height)),
		Color(0.0, 0.0, 0.0, 0.12)
	)

	draw_rect(
		Rect2(bar_pos, Vector2(bar_width * hp_ratio, bar_height)),
		Color("#7437FF")
	)


func _draw_slash() -> void:
	var slash_len: float = radius * slash_length_multiplier
	var dir: Vector2 = Vector2.RIGHT.rotated(slash_angle)
	var normal: Vector2 = dir.orthogonal()

	var start: Vector2 = -dir * slash_len * 0.5
	var end: Vector2 = dir * slash_len * 0.5

	var shadow := Color.BLACK
	shadow.a = slash_alpha * 0.18

	var main := slash_color
	main.a = slash_alpha

	var spark := slash_color
	spark.a = slash_alpha * 0.45

	draw_line(start + normal * 1.5, end + normal * 1.5, shadow, slash_width + 2.0, true)
	draw_line(start, end, main, slash_width, true)
	draw_circle(start, slash_width * 0.7, spark)
	draw_circle(end, slash_width * 0.7, spark)
