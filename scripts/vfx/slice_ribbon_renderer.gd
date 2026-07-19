class_name SliceRibbonRenderer
extends MeshInstance2D


@export_group("Ribbon Geometry")
@export var sample_spacing: float = 7.0
@export_range(0.0, 1.0, 0.05) var smoothing_strength: float = 0.82
@export var maximum_samples: int = 64
@export var ribbon_width: float = 46.0
@export var minimum_speed_width: float = 0.82
@export var maximum_speed_width: float = 1.18
@export var speed_for_maximum_width: float = 1200.0
@export var sharp_tip_length: float = 22.0
@export var width_profile: Curve

var ribbon_mesh: ArrayMesh = ArrayMesh.new()
var ribbon_material: ShaderMaterial


func _ready() -> void:
	_ensure_initialized()


func rebuild(
	input_points: Array[Vector2],
	input_ages: Array[float],
	tail_lifetime: float,
	width_multiplier: float = 1.0
) -> void:
	_ensure_initialized()
	if input_points.size() < 2:
		ribbon_mesh.clear_surfaces()
		return

	var samples: PackedVector2Array = _build_centripetal_samples(input_points)
	if samples.size() < 2:
		ribbon_mesh.clear_surfaces()
		return

	var sample_ages: PackedFloat32Array = _resample_ages(input_ages, samples.size())
	var vertices: PackedVector2Array = PackedVector2Array()
	var uvs: PackedVector2Array = PackedVector2Array()
	var colors: PackedColorArray = PackedColorArray()
	var indices: PackedInt32Array = PackedInt32Array()
	var distances: PackedFloat32Array = PackedFloat32Array()
	distances.resize(samples.size())

	var total_distance: float = 0.0
	for index: int in range(1, samples.size()):
		total_distance += samples[index - 1].distance_to(samples[index])
		distances[index] = total_distance

	var previous_normal: Vector2 = Vector2.ZERO
	for index: int in range(samples.size()):
		var tangent: Vector2 = _calculate_tangent(samples, index)
		var normal: Vector2 = tangent.orthogonal().normalized()
		if previous_normal != Vector2.ZERO and normal.dot(previous_normal) < 0.0:
			normal = -normal
		previous_normal = normal

		var path_ratio: float = distances[index] / maxf(total_distance, 0.001)
		var profile_width: float = _sample_width_profile(path_ratio)
		var local_speed: float = _estimate_local_speed(samples, sample_ages, index)
		var speed_ratio: float = clampf(local_speed / maxf(speed_for_maximum_width, 1.0), 0.0, 1.0)
		var speed_width: float = lerpf(minimum_speed_width, maximum_speed_width, speed_ratio)
		var half_width: float = ribbon_width * width_multiplier * profile_width * speed_width * 0.5
		var age_alpha: float = 1.0 - smoothstep(
			maxf(tail_lifetime * 0.62, 0.001),
			maxf(tail_lifetime, 0.002),
			sample_ages[index]
		)

		vertices.append(samples[index] - normal * half_width)
		vertices.append(samples[index] + normal * half_width)
		uvs.append(Vector2(path_ratio, 0.0))
		uvs.append(Vector2(path_ratio, 1.0))
		colors.append(Color(1.0, 1.0, 1.0, age_alpha))
		colors.append(Color(1.0, 1.0, 1.0, age_alpha))

	var tip_tangent: Vector2 = _calculate_tangent(samples, samples.size() - 1)
	var tip_position: Vector2 = samples[-1] + tip_tangent * sharp_tip_length
	var tip_index: int = vertices.size()
	vertices.append(tip_position)
	vertices.append(tip_position)
	uvs.append(Vector2(1.0, 0.5))
	uvs.append(Vector2(1.0, 0.5))
	colors.append(Color.WHITE)
	colors.append(Color.WHITE)

	for index: int in range(samples.size() - 1):
		var vertex_index: int = index * 2
		indices.append_array(PackedInt32Array([
			vertex_index,
			vertex_index + 1,
			vertex_index + 2,
			vertex_index + 1,
			vertex_index + 3,
			vertex_index + 2
		]))

	var last_pair: int = (samples.size() - 1) * 2
	indices.append_array(PackedInt32Array([
		last_pair,
		last_pair + 1,
		tip_index,
		last_pair + 1,
		tip_index + 1,
		tip_index
	]))

	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices

	ribbon_mesh.clear_surfaces()
	ribbon_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)


func set_shader_value(parameter: StringName, value: Variant) -> void:
	_ensure_initialized()
	if ribbon_material != null:
		ribbon_material.set_shader_parameter(parameter, value)


func _ensure_initialized() -> void:
	if mesh != ribbon_mesh:
		mesh = ribbon_mesh
	if ribbon_material == null:
		ribbon_material = material as ShaderMaterial
		if ribbon_material != null:
			ribbon_material = ribbon_material.duplicate() as ShaderMaterial
			material = ribbon_material


func _build_centripetal_samples(points: Array[Vector2]) -> PackedVector2Array:
	var result: PackedVector2Array = PackedVector2Array()
	var bounded_count: int = mini(points.size(), maximum_samples)
	for index: int in range(bounded_count - 1):
		var p0: Vector2 = points[maxi(index - 1, 0)]
		var p1: Vector2 = points[index]
		var p2: Vector2 = points[index + 1]
		var p3: Vector2 = points[mini(index + 2, bounded_count - 1)]
		var segment_steps: int = clampi(
			ceili(p1.distance_to(p2) / maxf(sample_spacing, 1.0)),
			1,
			6
		)
		for step: int in range(segment_steps):
			var weight: float = float(step) / float(segment_steps)
			var spline_point: Vector2 = _centripetal_point(p0, p1, p2, p3, weight)
			result.append(p1.lerp(spline_point, smoothing_strength))
	result.append(points[bounded_count - 1])

	while result.size() > maximum_samples:
		var reduced: PackedVector2Array = PackedVector2Array()
		for index: int in range(0, result.size(), 2):
			reduced.append(result[index])
		if reduced[-1] != result[-1]:
			reduced.append(result[-1])
		result = reduced
	return result


func _centripetal_point(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, weight: float) -> Vector2:
	var t0: float = 0.0
	var t1: float = t0 + sqrt(maxf(p0.distance_to(p1), 0.001))
	var t2: float = t1 + sqrt(maxf(p1.distance_to(p2), 0.001))
	var t3: float = t2 + sqrt(maxf(p2.distance_to(p3), 0.001))
	var t: float = lerpf(t1, t2, weight)
	var a1: Vector2 = _time_lerp(p0, p1, t0, t1, t)
	var a2: Vector2 = _time_lerp(p1, p2, t1, t2, t)
	var a3: Vector2 = _time_lerp(p2, p3, t2, t3, t)
	var b1: Vector2 = _time_lerp(a1, a2, t0, t2, t)
	var b2: Vector2 = _time_lerp(a2, a3, t1, t3, t)
	return _time_lerp(b1, b2, t1, t2, t)


func _time_lerp(a: Vector2, b: Vector2, start: float, end: float, value: float) -> Vector2:
	var ratio: float = clampf((value - start) / maxf(end - start, 0.0001), 0.0, 1.0)
	return a.lerp(b, ratio)


func _resample_ages(ages: Array[float], target_size: int) -> PackedFloat32Array:
	var result: PackedFloat32Array = PackedFloat32Array()
	for index: int in range(target_size):
		var ratio: float = float(index) / float(maxi(target_size - 1, 1))
		var source_position: float = ratio * float(maxi(ages.size() - 1, 0))
		var lower: int = floori(source_position)
		var upper: int = mini(lower + 1, ages.size() - 1)
		result.append(lerpf(ages[lower], ages[upper], source_position - float(lower)))
	return result


func _calculate_tangent(points: PackedVector2Array, index: int) -> Vector2:
	var previous: Vector2 = points[maxi(index - 1, 0)]
	var next: Vector2 = points[mini(index + 1, points.size() - 1)]
	var tangent: Vector2 = previous.direction_to(next)
	return tangent if tangent != Vector2.ZERO else Vector2.RIGHT


func _estimate_local_speed(points: PackedVector2Array, ages: PackedFloat32Array, index: int) -> float:
	if index <= 0:
		return 0.0
	var age_delta: float = absf(ages[index - 1] - ages[index])
	return points[index - 1].distance_to(points[index]) / maxf(age_delta, 0.008)


func _sample_width_profile(ratio: float) -> float:
	if width_profile != null:
		return maxf(width_profile.sample_baked(ratio), 0.0)
	return sin(clampf(ratio, 0.0, 1.0) * PI)
