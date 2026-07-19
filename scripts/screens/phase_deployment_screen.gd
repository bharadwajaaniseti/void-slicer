extends Control

@onready var back_button: Button = %BackButton
@onready var prestige_button: Button = %PrestigeButton
@onready var start_button: Button = %StartButton
@onready var skills_button: Button = %SkillsButton
@onready var auto_start_button: Button = %AutoStartButton
@onready var header_shard_value: Label = %HeaderShardValue
@onready var clock_value: Label = %ClockValue


func _ready() -> void:
	back_button.pressed.connect(Navigator.go_to_home)
	prestige_button.pressed.connect(Navigator.go_to_home.bind(&"prestige"))
	start_button.pressed.connect(_start_run)
	skills_button.pressed.connect(Navigator.go_to_home.bind(&"skills"))
	auto_start_button.toggled.connect(_on_auto_start_toggled)
	header_shard_value.text = "◆  " + _format_integer(GameState.boss_shards)


func _process(_delta: float) -> void:
	var now: Dictionary = Time.get_time_dict_from_system()
	clock_value.text = "◷  %02d:%02d" % [int(now.get("hour", 0)), int(now.get("minute", 0))]


func _format_integer(value: int) -> String:
	var raw: String = str(value)
	var formatted: String = ""
	for index: int in range(raw.length()):
		if index > 0 and (raw.length() - index) % 3 == 0:
			formatted += ","
		formatted += raw[index]
	return formatted


func _start_run() -> void:
	GameState.equipped_weapon_id = &"turret"
	GameState.save_state()
	start_button.disabled = true
	Navigator.start_phase_one()


func _on_auto_start_toggled(enabled: bool) -> void:
	auto_start_button.text = "AUTO START\nREADY" if enabled else "AUTO START\nOFF"
