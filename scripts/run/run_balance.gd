class_name RunBalance
extends Resource


@export_group("Enemy Scaling")
@export var base_enemy_health: float = 55.0
@export var base_enemy_cash: float = 120.0
@export var base_enemy_xp: float = 5.0
@export var base_enemy_core_energy: float = 25.0
@export var enemy_health_growth_per_stage: float = 1.18
@export var enemy_reward_growth_per_stage: float = 1.12
@export var enemy_xp_growth_per_stage: float = 1.10

@export_group("Boss Scaling")
@export var boss_health_multiplier: float = 20.0
@export var boss_reward_multiplier: float = 10.0
@export var boss_xp_multiplier: float = 10.0

@export_group("Sector Structure")
@export var stages_per_sector: int = 10
@export var boss_checkpoint_interval: int = 1


func get_enemy_health(sector: int, stage: int) -> float:
	var stage_index: int = _get_global_stage_index(sector, stage)
	return base_enemy_health * pow(enemy_health_growth_per_stage, float(stage_index))


func get_enemy_cash_reward(sector: int, stage: int) -> float:
	var stage_index: int = _get_global_stage_index(sector, stage)
	return base_enemy_cash * pow(enemy_reward_growth_per_stage, float(stage_index))


func get_enemy_xp_reward(sector: int, stage: int) -> float:
	var stage_index: int = _get_global_stage_index(sector, stage)
	return base_enemy_xp * pow(enemy_xp_growth_per_stage, float(stage_index))


func get_enemy_material_reward(sector: int, stage: int) -> float:
	var stage_index: int = _get_global_stage_index(sector, stage)
	return maxf(1.0, 1.0 + float(stage_index) * 0.25)


func get_enemy_core_energy(sector: int, stage: int) -> float:
	return base_enemy_core_energy


func get_boss_health(sector: int, stage: int) -> float:
	return get_enemy_health(sector, stage) * boss_health_multiplier


func get_boss_cash_reward(sector: int, stage: int) -> float:
	return get_enemy_cash_reward(sector, stage) * boss_reward_multiplier


func get_boss_xp_reward(sector: int, stage: int) -> float:
	return get_enemy_xp_reward(sector, stage) * boss_xp_multiplier


func get_boss_material_reward(sector: int, stage: int) -> float:
	return get_enemy_material_reward(sector, stage) * boss_reward_multiplier


func get_core_energy_requirement(sector: int, stage: int) -> float:
	var boss_health: float = get_boss_health(sector, stage)
	return maxf(boss_health * 0.25, base_enemy_core_energy * 8.0)


func is_boss_checkpoint(stage: int) -> bool:
	var interval: int = maxi(boss_checkpoint_interval, 1)
	return stage % interval == 0


func get_sector_for_stage(stage: int) -> int:
	var safe_stage: int = maxi(stage, 1)
	var safe_stages_per_sector: int = maxi(stages_per_sector, 1)
	return ((safe_stage - 1) / safe_stages_per_sector) + 1


func get_stage_in_sector(stage: int) -> int:
	var safe_stage: int = maxi(stage, 1)
	var safe_stages_per_sector: int = maxi(stages_per_sector, 1)
	return ((safe_stage - 1) % safe_stages_per_sector) + 1


func _get_global_stage_index(sector: int, stage: int) -> int:
	var safe_sector: int = maxi(sector, 1)
	var safe_stage: int = maxi(stage, 1)
	var safe_stages_per_sector: int = maxi(stages_per_sector, 1)
	return ((safe_sector - 1) * safe_stages_per_sector) + safe_stage - 1
