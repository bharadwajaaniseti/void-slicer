class_name SliceVFX
extends Node2D


@export_group("Checkpoint A Sampling")
@export var sample_spacing: float = 7.0
@export_range(0.0, 1.0, 0.05) var smoothing_strength: float = 0.82
@export var maximum_samples: int = 64
@export var tail_lifetime: float = 0.13
@export var minimum_input_distance: float = 4.0

@export_group("Checkpoint A Shape")
@export var ribbon_width: float = 46.0
@export var sharp_tip_length: float = 22.0

@export_group("Checkpoint A Shader")
@export var core_width: float = 0.12
@export var body_width: float = 0.52
@export var noise_strength: float = 0.12
@export var distortion_strength: float = 0.035
@export var glow_strength: float = 1.15

@export_group("Checkpoint A Release")
@export var release_hold_time: float = 0.06
@export var release_lifetime: float = 0.24
@export var release_width_multiplier: float = 1.08

@export_group("Checkpoint B Presentation")
@export var particle_multiplier: float = 1.0
@export var maximum_secondary_arcs: int = 4
@export var secondary_arc_delay: float = 0.035
@export var impact_flash_lifetime: float = 0.11

var ribbon: SliceRibbonRenderer = null
var sparks: GPUParticles2D = null
var fragments: GPUParticles2D = null
var impact_flash: Polygon2D = null
var secondary_arcs: Array[SliceRibbonRenderer] = []

var source_points: Array[Vector2] = []
var point_ages: Array[float] = []
var is_active: bool = false
var is_releasing: bool = false
var release_elapsed: float = 0.0
var time_offset: float = 0.0
var intensity_tier: int = 0
var hit_count: int = 0
var secondary_arc_count: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_ensure_ribbon()
	_ensure_checkpoint_b_nodes()
	time_offset = float(Time.get_ticks_msec() % 100000) / 1000.0
	_apply_inspector_configuration()
	set_process(false)


func begin_gesture(start_position: Vector2) -> void:
	_ensure_ribbon()
	if ribbon == null:
		queue_free()
		return
	source_points.clear()
	point_ages.clear()
	source_points.append(start_position)
	point_ages.append(0.0)
	is_active = true
	is_releasing = false
	release_elapsed = 0.0
	ribbon.set_shader_value(&"lifetime_alpha", 1.0)
	ribbon.set_shader_value(&"release_pulse", 0.0)
	ribbon.set_shader_value(&"dissolve_amount", 0.0)
	ribbon.set_shader_value(&"overall_intensity", 1.0)
	ribbon.set_shader_value(&"hit_flash", 0.0)
	ribbon.set_shader_value(&"combo_intensity", 0.0)
	ribbon.set_shader_value(&"chromatic_amount", 0.0)
	if sparks != null:
		sparks.emitting = true
	if fragments != null:
		fragments.emitting = false
	if impact_flash != null:
		impact_flash.visible = false
	_hide_secondary_arcs()
	set_process(true)
	_rebuild_ribbon()
	_update_curve_sparks()


func add_authoritative_point(point: Vector2) -> void:
	if not is_active:
		return

	if not source_points.is_empty() and source_points[-1].distance_to(point) < minimum_input_distance:
		return

	source_points.append(point)
	point_ages.append(0.0)

	while source_points.size() > maximum_samples:
		source_points.pop_front()
		point_ages.pop_front()

	_rebuild_ribbon()


func release_gesture(completed_hit_count: int, combo_count: int) -> void:
	if not is_active:
		queue_free()
		return

	is_active = false
	is_releasing = true
	release_elapsed = 0.0
	hit_count = maxi(completed_hit_count, 0)
	intensity_tier = _calculate_intensity_tier(hit_count, combo_count)
	var tier_ratio: float = float(intensity_tier) / 5.0
	var width_scale: float = release_width_multiplier + tier_ratio * 0.28
	ribbon.set_shader_value(&"combo_intensity", tier_ratio)
	ribbon.set_shader_value(&"chromatic_amount", maxf(tier_ratio - 0.55, 0.0) * 0.12)
	_rebuild_ribbon(width_scale)
	if sparks != null:
		sparks.emitting = false
	_start_fragment_burst()
	_start_impact_flash()
	_build_secondary_arcs()


func cancel_immediately() -> void:
	queue_free()


func _process(delta: float) -> void:
	if is_active:
		_age_tail(delta)
		_rebuild_ribbon()
		return

	if not is_releasing:
		return

	release_elapsed += delta
	var pulse_ratio: float = clampf(release_elapsed / maxf(release_hold_time, 0.01), 0.0, 1.0)
	var fade_ratio: float = clampf(
		(release_elapsed - release_hold_time) / maxf(release_lifetime, 0.01),
		0.0,
		1.0
	)
	var brightness: float = 1.0 + sin(pulse_ratio * PI) * 0.48
	var tier_ratio: float = float(intensity_tier) / 5.0
	brightness += tier_ratio * 0.42

	ribbon.set_shader_value(&"release_pulse", pulse_ratio)
	ribbon.set_shader_value(&"overall_intensity", brightness)
	ribbon.set_shader_value(&"lifetime_alpha", 1.0 - smoothstep(0.58, 1.0, fade_ratio))
	ribbon.set_shader_value(&"dissolve_amount", fade_ratio)
	ribbon.set_shader_value(&"hit_flash", (1.0 - pulse_ratio) * tier_ratio)
	_update_checkpoint_b_release(fade_ratio)

	if release_elapsed >= release_hold_time + release_lifetime:
		queue_free()


func _age_tail(delta: float) -> void:
	for index: int in range(point_ages.size()):
		point_ages[index] += delta

	while source_points.size() > 2 and point_ages[0] >= tail_lifetime:
		source_points.pop_front()
		point_ages.pop_front()


func _rebuild_ribbon(width_multiplier: float = 1.0) -> void:
	if ribbon != null:
		ribbon.rebuild(source_points, point_ages, tail_lifetime, width_multiplier)


func _apply_inspector_configuration() -> void:
	if ribbon == null:
		return
	ribbon.sample_spacing = sample_spacing
	ribbon.smoothing_strength = smoothing_strength
	ribbon.maximum_samples = maximum_samples
	ribbon.ribbon_width = ribbon_width
	ribbon.sharp_tip_length = sharp_tip_length
	ribbon.set_shader_value(&"core_width", core_width)
	ribbon.set_shader_value(&"body_width", body_width)
	ribbon.set_shader_value(&"noise_strength", noise_strength)
	ribbon.set_shader_value(&"distortion_strength", distortion_strength)
	ribbon.set_shader_value(&"glow_intensity", glow_strength)
	ribbon.set_shader_value(&"time_offset", time_offset)


func _ensure_ribbon() -> void:
	if ribbon == null:
		ribbon = get_node_or_null("Ribbon") as SliceRibbonRenderer


func _ensure_checkpoint_b_nodes() -> void:
	sparks = get_node_or_null("Sparks") as GPUParticles2D
	fragments = get_node_or_null("Fragments") as GPUParticles2D
	impact_flash = get_node_or_null("ImpactFlash") as Polygon2D
	secondary_arcs.clear()
	var arcs_root: Node = get_node_or_null("SecondaryArcs")
	if arcs_root != null:
		for child: Node in arcs_root.get_children():
			if child is SliceRibbonRenderer:
				secondary_arcs.append(child as SliceRibbonRenderer)


func _update_curve_sparks() -> void:
	if sparks == null or source_points.size() < 2:
		return
	var sample_index: int = clampi(
		roundi(float(source_points.size() - 1) * 0.72),
		1,
		source_points.size() - 1
	)
	var direction: Vector2 = source_points[sample_index - 1].direction_to(source_points[sample_index])
	sparks.position = source_points[sample_index]
	var process_material: ParticleProcessMaterial = sparks.process_material as ParticleProcessMaterial
	if process_material != null:
		process_material.direction = Vector3(-direction.x, -direction.y, 0.0)


func _start_fragment_burst() -> void:
	if fragments == null or source_points.is_empty() or intensity_tier <= 0:
		return
	fragments.amount = maxi(roundi((5.0 + float(intensity_tier) * 4.0) * particle_multiplier), 1)
	var midpoint_index: int = source_points.size() / 2
	fragments.position = source_points[midpoint_index]
	fragments.restart()
	fragments.emitting = true


func _start_impact_flash() -> void:
	if impact_flash == null or source_points.is_empty() or hit_count <= 0:
		return
	impact_flash.position = source_points[-1]
	if source_points.size() >= 2:
		impact_flash.rotation = source_points[-2].direction_to(source_points[-1]).angle()
	impact_flash.scale = Vector2.ONE * (0.7 + float(intensity_tier) * 0.18)
	impact_flash.visible = true


func _build_secondary_arcs() -> void:
	secondary_arc_count = clampi(intensity_tier - 1, 0, mini(maximum_secondary_arcs, secondary_arcs.size()))
	if secondary_arc_count <= 0 or source_points.size() < 3:
		return
	var arc_ages: Array[float] = []
	for point: Vector2 in source_points:
		arc_ages.append(0.0)
	for arc_index: int in range(secondary_arc_count):
		var arc: SliceRibbonRenderer = secondary_arcs[arc_index]
		var offset_sign: float = -1.0 if arc_index % 2 == 0 else 1.0
		var offset_amount: float = (10.0 + float(arc_index) * 7.0) * offset_sign
		var arc_points: Array[Vector2] = []
		for point_index: int in range(source_points.size()):
			var previous: Vector2 = source_points[maxi(point_index - 1, 0)]
			var next: Vector2 = source_points[mini(point_index + 1, source_points.size() - 1)]
			var normal: Vector2 = previous.direction_to(next).orthogonal()
			arc_points.append(source_points[point_index] + normal * offset_amount)
		arc.ribbon_width = maxf(ribbon_width * (0.24 - float(arc_index) * 0.025), 7.0)
		arc.sharp_tip_length = sharp_tip_length * 0.55
		arc.set_shader_value(&"overall_intensity", 0.72 + float(intensity_tier) * 0.06)
		arc.set_shader_value(&"combo_intensity", float(intensity_tier) / 5.0)
		arc.rebuild(arc_points, arc_ages, tail_lifetime, 1.0)
		arc.visible = false


func _update_checkpoint_b_release(fade_ratio: float) -> void:
	if impact_flash != null:
		impact_flash.visible = hit_count > 0 and release_elapsed <= impact_flash_lifetime
	for arc_index: int in range(secondary_arc_count):
		var arc: SliceRibbonRenderer = secondary_arcs[arc_index]
		var delay: float = secondary_arc_delay * float(arc_index + 1)
		arc.visible = release_elapsed >= delay
		if arc.visible:
			var arc_fade: float = clampf((fade_ratio - float(arc_index) * 0.06) / 0.82, 0.0, 1.0)
			arc.set_shader_value(&"lifetime_alpha", 1.0 - arc_fade)
			arc.set_shader_value(&"dissolve_amount", arc_fade)


func _hide_secondary_arcs() -> void:
	for arc: SliceRibbonRenderer in secondary_arcs:
		arc.visible = false
	secondary_arc_count = 0


func _calculate_intensity_tier(completed_hit_count: int, combo_count: int) -> int:
	if completed_hit_count <= 0:
		return 0
	if combo_count >= 50:
		return 5
	if combo_count >= 20:
		return 4
	if combo_count >= 10:
		return 3
	if combo_count >= 5:
		return 2
	return 1
