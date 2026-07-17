class_name RewardData
extends Resource


enum RewardType {
	PASSIVE,
	ABILITY,
	WEAPON_UPGRADE,
	NEW_WEAPON,
	WEAPON_TIER,
	WEAPON_SLOT
}


enum RewardRarity {
	COMMON,
	UNCOMMON,
	RARE,
	EPIC,
	LEGENDARY
}


@export_group("Identity")
@export var reward_id: String = ""
@export var display_name: String = "REWARD"
@export_multiline var description: String = ""
@export var icon: Texture2D

@export_group("Classification")
@export var reward_type: RewardType = RewardType.PASSIVE
@export var rarity: RewardRarity = RewardRarity.COMMON
@export var tier: int = 0

@export_group("Stats")
@export var stat_line_1: String = ""
@export var stat_line_2: String = ""
@export var stat_line_3: String = ""

@export_group("Application")
@export var stat_id: String = ""
@export var primary_value: float = 0.0
@export var secondary_stat_id: String = ""
@export var secondary_value: float = 0.0
@export var weapon_id: String = ""
@export var ability_id: String = ""

@export_group("Rules")
@export var maximum_stacks: int = 1
@export var requires_equipped_weapon: bool = false
@export var required_weapon_id: String = ""
@export var minimum_weapon_tier: int = 0
@export var boss_reward_only: bool = false
@export var level_up_reward_only: bool = false
