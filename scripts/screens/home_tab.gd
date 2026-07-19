extends Control

@onready var start_button: Button = %StartPhaseButton
@onready var loadout_button: Button = %LoadoutButton
@onready var skills_button: Button = %SkillsButton
@onready var upgrades_button: Button = %UpgradesButton
@onready var cash_value: Label = %CashValue
@onready var depth_value: Label = %DepthValue
@onready var shard_value: Label = %ShardValue
@onready var prestige_button: Button = %PrestigeButton


func _ready() -> void:
	start_button.pressed.connect(Navigator.go_to_deployment)
	loadout_button.pressed.connect(Navigator.go_to_deployment)
	skills_button.pressed.connect(Navigator.go_to_home.bind(&"skills"))
	upgrades_button.pressed.connect(Navigator.go_to_home.bind(&"upgrades"))
	prestige_button.pressed.connect(Navigator.go_to_home.bind(&"prestige"))
	_sync_state()
	if not GameState.state_changed.is_connected(_sync_state):
		GameState.state_changed.connect(_sync_state)


func _sync_state() -> void:
	cash_value.text = _format_number(GameState.permanent_cash)
	depth_value.text = str(GameState.best_depth)
	shard_value.text = str(GameState.boss_shards)


func _format_number(value: float) -> String:
	if value >= 1000000.0:
		return "%.2fM" % (value / 1000000.0)
	if value >= 1000.0:
		return "%.1fk" % (value / 1000.0)
	return str(roundi(value))
