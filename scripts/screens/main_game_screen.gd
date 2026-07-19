extends Control


@export_group("Tab Scenes")
@export var home_scene: PackedScene
@export var skills_scene: PackedScene
@export var upgrades_scene: PackedScene
@export var research_scene: PackedScene
@export var shop_scene: PackedScene
@export var prestige_scene: PackedScene

@export_group("Tab Names")
@export var default_tab: String = "home"

@onready var content_host: Control = find_child("ContentHost", true, false) as Control

@onready var home_button: Button = find_child("HomeButton", true, false) as Button
@onready var skills_button: Button = find_child("SkillsButton", true, false) as Button
@onready var upgrades_button: Button = find_child("UpgradesButton", true, false) as Button
@onready var research_button: Button = find_child("ResearchButton", true, false) as Button
@onready var shop_button: Button = find_child("ShopButton", true, false) as Button
@onready var prestige_button: Button = find_child("PrestigeButton", true, false) as Button
@onready var header_cash_value: Label = %HeaderCashValue
@onready var header_depth_value: Label = %HeaderDepthValue
@onready var header_shard_value: Label = %HeaderShardValue
@onready var clock_value: Label = %ClockValue

var current_tab: Control = null
var current_tab_name: String = ""


func _ready() -> void:
	_connect_nav_buttons()
	var requested_tab: String = String(Navigator.pending_home_tab)
	Navigator.pending_home_tab = &"home"
	open_tab(requested_tab if not requested_tab.is_empty() else default_tab)
	_sync_header()
	if not GameState.state_changed.is_connected(_sync_header):
		GameState.state_changed.connect(_sync_header)


func _process(_delta: float) -> void:
	var now: Dictionary = Time.get_time_dict_from_system()
	clock_value.text = "◷  %02d:%02d" % [int(now.get("hour", 0)), int(now.get("minute", 0))]


func _sync_header() -> void:
	header_cash_value.text = "$" + _format_number(GameState.permanent_cash)
	header_depth_value.text = str(GameState.best_depth)
	header_shard_value.text = _format_integer(GameState.boss_shards)


func _format_number(value: float) -> String:
	if value >= 1000000.0:
		return "%.2fM" % (value / 1000000.0)
	if value >= 1000.0:
		return "%.1fk" % (value / 1000.0)
	return str(roundi(value))


func _format_integer(value: int) -> String:
	var raw: String = str(value)
	var formatted: String = ""
	for index: int in range(raw.length()):
		if index > 0 and (raw.length() - index) % 3 == 0:
			formatted += ","
		formatted += raw[index]
	return formatted


func _connect_nav_buttons() -> void:
	home_button.pressed.connect(func() -> void: open_tab("home"))
	skills_button.pressed.connect(func() -> void: open_tab("skills"))
	upgrades_button.pressed.connect(func() -> void: open_tab("upgrades"))
	research_button.pressed.connect(func() -> void: open_tab("research"))
	shop_button.pressed.connect(func() -> void: open_tab("shop"))
	prestige_button.pressed.connect(func() -> void: open_tab("prestige"))


func open_tab(tab_name: String) -> void:
	if tab_name == current_tab_name:
		return

	var scene_to_load: PackedScene = _get_scene_for_tab(tab_name)

	if scene_to_load == null:
		push_warning("No scene assigned for tab: " + tab_name)
		return

	_clear_current_tab()

	current_tab = scene_to_load.instantiate() as Control

	if current_tab == null:
		push_warning("Tab scene root must be a Control node: " + tab_name)
		return

	content_host.add_child(current_tab)

	current_tab.set_anchors_preset(Control.PRESET_FULL_RECT)
	current_tab.offset_left = 0
	current_tab.offset_top = 0
	current_tab.offset_right = 0
	current_tab.offset_bottom = 0

	current_tab_name = tab_name

	_update_nav_visuals(tab_name)
	_play_tab_intro(current_tab)


func _get_scene_for_tab(tab_name: String) -> PackedScene:
	match tab_name:
		"home":
			return home_scene
		"skills":
			return skills_scene
		"upgrades":
			return upgrades_scene
		"research":
			return research_scene
		"shop":
			return shop_scene
		"prestige":
			return prestige_scene
		_:
			return null


func _clear_current_tab() -> void:
	if current_tab == null:
		return

	current_tab.queue_free()
	current_tab = null
	current_tab_name = ""


func _update_nav_visuals(active_tab: String) -> void:
	_set_nav_button_active(home_button, active_tab == "home")
	_set_nav_button_active(skills_button, active_tab == "skills")
	_set_nav_button_active(upgrades_button, active_tab == "upgrades")
	_set_nav_button_active(research_button, active_tab == "research")
	_set_nav_button_active(shop_button, active_tab == "shop")
	_set_nav_button_active(prestige_button, active_tab == "prestige")


func _set_nav_button_active(button: Button, is_active: bool) -> void:
	button.theme_type_variation = &"TabButtonActive" if is_active else &"TabButton"


func _play_tab_intro(tab: Control) -> void:
	tab.modulate.a = 0.0
	tab.position.y = 12.0

	var tween: Tween = create_tween()
	tween.set_parallel(true)

	tween.tween_property(tab, "modulate:a", 1.0, 0.18)
	tween.tween_property(tab, "position:y", 0.0, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
