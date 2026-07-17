class_name WeaponDefinition
extends Resource


@export var weapon_id: StringName = &"turret"
@export var display_name: String = "Basic Turret"
@export_multiline var description: String = ""
@export var base_damage: float = 24.0
@export var damage_growth: float = 1.12
@export var base_attack_interval: float = 0.52
@export var minimum_attack_interval: float = 0.08
@export var base_upgrade_cost: float = 35.0
@export var upgrade_cost_growth: float = 1.16
@export var starting_level: int = 1
@export var starting_tier: int = 1
@export var maximum_level: int = -1
@export var milestone_levels: Array[int] = [
	10,
	25,
	50,
	100,
	250
]
@export var tags: Array[StringName] = []
@export var icon: Texture2D
@export var scene: PackedScene


static func create_default(
	new_weapon_id: StringName,
	new_display_name: String,
	new_description: String,
	new_base_damage: float,
	new_damage_growth: float,
	new_base_attack_interval: float,
	new_minimum_attack_interval: float,
	new_base_upgrade_cost: float,
	new_upgrade_cost_growth: float,
	new_tags: Array[StringName] = []
) -> WeaponDefinition:
	var definition: WeaponDefinition = WeaponDefinition.new()
	definition.weapon_id = new_weapon_id
	definition.display_name = new_display_name
	definition.description = new_description
	definition.base_damage = new_base_damage
	definition.damage_growth = new_damage_growth
	definition.base_attack_interval = new_base_attack_interval
	definition.minimum_attack_interval = new_minimum_attack_interval
	definition.base_upgrade_cost = new_base_upgrade_cost
	definition.upgrade_cost_growth = new_upgrade_cost_growth
	definition.tags = new_tags.duplicate()
	return definition
