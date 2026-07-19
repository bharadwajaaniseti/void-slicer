class_name VoidBurstVFX
extends Node2D


@export var total_duration: float = 0.68
@export var overlay_peak_alpha: float = 0.28
@export var ring_max_radius: float = 330.0
@export var arc_width: float = 78.0

var overlay: Polygon2D = null
var arc_purple: SliceRibbonRenderer = null
var arc_orange: SliceRibbonRenderer = null
var arc_white: SliceRibbonRenderer = null
var shock_ring: Line2D = null
var intersection_flash: Polygon2D = null
var sparks: GPUParticles2D = null

var elapsed: float = 0.0
var arena_size: Vector2 = Vector2.ZERO


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_ensure_nodes()
	visible = false
	set_process(false)


func play(bounds_size: Vector2) -> void:
	_ensure_nodes()
	arena_size = bounds_size
	position = bounds_size * 0.5
	if overlay == null or arc_purple == null or arc_orange == null or arc_white == null:
		queue_free()
		return

	overlay.polygon = PackedVector2Array([
		-bounds_size * 0.5,
		Vector2(bounds_size.x * 0.5, -bounds_size.y * 0.5),
		bounds_size * 0.5,
		Vector2(-bounds_size.x * 0.5, bounds_size.y * 0.5)
	])
	_build_arc(arc_purple, -0.30, -54.0, 1.10)
	_build_arc(arc_orange, 0.24, 24.0, 0.96)
	_build_arc(arc_white, -0.07, 68.0, 0.82)
	arc_purple.visible = false
	arc_orange.visible = false
	arc_white.visible = false
	intersection_flash.visible = false
	elapsed = 0.0
	visible = true
	if sparks != null:
		sparks.restart()
		sparks.emitting = true
	set_process(true)


func cancel_immediately() -> void:
	queue_free()


func _process(delta: float) -> void:
	elapsed += delta
	var ratio: float = clampf(elapsed / maxf(total_duration, 0.01), 0.0, 1.0)
	overlay.color.a = overlay_peak_alpha * sin(ratio * PI)
	_update_arc(arc_purple, ratio, 0.02, 0.48)
	_update_arc(arc_orange, ratio, 0.14, 0.58)
	_update_arc(arc_white, ratio, 0.27, 0.72)
	_update_ring(ratio)
	intersection_flash.visible = ratio >= 0.28 and ratio <= 0.46
	if intersection_flash.visible:
		var flash_ratio: float = clampf((ratio - 0.28) / 0.18, 0.0, 1.0)
		intersection_flash.scale = Vector2.ONE * lerpf(0.45, 1.65, flash_ratio)
		intersection_flash.modulate.a = 1.0 - flash_ratio

	if ratio >= 1.0:
		queue_free()


func _build_arc(renderer: SliceRibbonRenderer, angle: float, offset_y: float, width_scale: float) -> void:
	var half_length: float = arena_size.length() * 0.64
	var direction: Vector2 = Vector2.RIGHT.rotated(angle)
	var normal: Vector2 = direction.orthogonal()
	var points: Array[Vector2] = []
	var ages: Array[float] = []
	for index: int in range(15):
		var weight: float = float(index) / 14.0
		var along: float = lerpf(-half_length, half_length, weight)
		var bow: float = sin(weight * PI) * 88.0 + offset_y
		points.append(direction * along + normal * bow)
		ages.append(0.0)
	renderer.ribbon_width = arc_width * width_scale
	renderer.sharp_tip_length = 42.0
	renderer.rebuild(points, ages, 1.0, 1.0)


func _update_arc(renderer: SliceRibbonRenderer, ratio: float, start: float, finish: float) -> void:
	if renderer == null:
		return
	renderer.visible = ratio >= start and ratio <= finish
	if not renderer.visible:
		return
	var local_ratio: float = clampf((ratio - start) / maxf(finish - start, 0.01), 0.0, 1.0)
	renderer.set_shader_value(&"release_pulse", clampf(local_ratio * 1.65, 0.0, 1.0))
	renderer.set_shader_value(&"overall_intensity", 1.25 + sin(local_ratio * PI) * 0.85)
	renderer.set_shader_value(&"lifetime_alpha", 1.0 - smoothstep(0.62, 1.0, local_ratio))
	renderer.set_shader_value(&"dissolve_amount", smoothstep(0.48, 1.0, local_ratio))


func _update_ring(ratio: float) -> void:
	if shock_ring == null:
		return
	var points: PackedVector2Array = PackedVector2Array()
	var ring_ratio: float = clampf((ratio - 0.24) / 0.68, 0.0, 1.0)
	var radius: float = ring_max_radius * ease(ring_ratio, 0.45)
	for index: int in range(41):
		var angle: float = TAU * float(index) / 40.0
		points.append(Vector2.from_angle(angle) * radius)
	shock_ring.points = points
	shock_ring.modulate.a = (1.0 - ring_ratio) if ratio >= 0.24 else 0.0


func _ensure_nodes() -> void:
	overlay = get_node_or_null("DarkOverlay") as Polygon2D
	arc_purple = get_node_or_null("ArcPurple") as SliceRibbonRenderer
	arc_orange = get_node_or_null("ArcOrange") as SliceRibbonRenderer
	arc_white = get_node_or_null("ArcWhite") as SliceRibbonRenderer
	shock_ring = get_node_or_null("ShockRing") as Line2D
	intersection_flash = get_node_or_null("IntersectionFlash") as Polygon2D
	sparks = get_node_or_null("OutwardSparks") as GPUParticles2D
