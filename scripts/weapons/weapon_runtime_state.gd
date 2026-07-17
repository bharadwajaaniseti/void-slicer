class_name WeaponRuntimeState
extends RefCounted


var weapon_id: StringName = &""
var display_name: String = ""
var level: int = 1
var tier: int = 1
var slot_id: String = ""
var unlocked: bool = false
var unlocked_milestones: Array[int] = []
var calculated_damage: float = 0.0
var calculated_attack_interval: float = 1.0
var calculated_dps: float = 0.0
var calculated_range_multiplier: float = 1.0
var projectiles_per_attack: int = 1
var ricochet_count: int = 0
var ricochet_damage_multiplier: float = 0.6
var explosion_every_n_attacks: int = 0
var explosion_damage_multiplier: float = 0.0


func has_milestone(level_value: int) -> bool:
	return unlocked_milestones.has(level_value)


func clear_run_state() -> void:
	unlocked_milestones.clear()
	calculated_damage = 0.0
	calculated_attack_interval = 1.0
	calculated_dps = 0.0
	projectiles_per_attack = 1
	ricochet_count = 0
	explosion_every_n_attacks = 0
	explosion_damage_multiplier = 0.0
