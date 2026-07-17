class_name DamageContext
extends RefCounted


var base_amount: float = 0.0
var final_amount: float = 0.0
var source_type: StringName = &"environmental"
var source_id: StringName = &""
var damage_type: StringName = &"normal"
var is_critical: bool = false
var is_area_damage: bool = false
var is_chain_damage: bool = false
var is_slice_damage: bool = false
var can_trigger_on_hit_effects: bool = true
var owner_reference: Variant = null
var hit_position: Vector2 = Vector2.ZERO
var metadata: Dictionary = {}


static func create(
	new_base_amount: float,
	new_source_type: StringName,
	new_source_id: StringName,
	new_damage_type: StringName,
	new_hit_position: Vector2
) -> RefCounted:
	var context: RefCounted = load("res://scripts/combat/damage_context.gd").new() as RefCounted
	context.base_amount = maxf(new_base_amount, 0.0)
	context.final_amount = context.base_amount
	context.source_type = new_source_type
	context.source_id = new_source_id
	context.damage_type = new_damage_type
	context.hit_position = new_hit_position
	return context


func duplicate_context() -> RefCounted:
	var context: RefCounted = load("res://scripts/combat/damage_context.gd").new() as RefCounted
	context.base_amount = base_amount
	context.final_amount = final_amount
	context.source_type = source_type
	context.source_id = source_id
	context.damage_type = damage_type
	context.is_critical = is_critical
	context.is_area_damage = is_area_damage
	context.is_chain_damage = is_chain_damage
	context.is_slice_damage = is_slice_damage
	context.can_trigger_on_hit_effects = can_trigger_on_hit_effects
	context.owner_reference = owner_reference
	context.hit_position = hit_position
	context.metadata = metadata.duplicate(true)
	return context
