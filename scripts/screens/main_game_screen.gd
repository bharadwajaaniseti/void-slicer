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

@onready var content_host: Control = $ContentHost

@onready var home_button: Button = $NavBar/NavHBox/HomeButton
@onready var skills_button: Button = $NavBar/NavHBox/SkillsButton
@onready var upgrades_button: Button = $NavBar/NavHBox/UpgradesButton
@onready var research_button: Button = $NavBar/NavHBox/ResearchButton
@onready var shop_button: Button = $NavBar/NavHBox/ShopButton
@onready var prestige_button: Button = $NavBar/NavHBox/PrestigeButton

var current_tab: Control = null
var current_tab_name: String = ""


func _ready() -> void:
	_connect_nav_buttons()
	open_tab(default_tab)


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
	if is_active:
		button.add_theme_color_override("font_color", Color("#7329ff"))
		button.add_theme_color_override("font_hover_color", Color("#7329ff"))
		button.add_theme_color_override("font_pressed_color", Color("#7329ff"))
	else:
		button.add_theme_color_override("font_color", Color("#05050b"))
		button.add_theme_color_override("font_hover_color", Color("#7329ff"))
		button.add_theme_color_override("font_pressed_color", Color("#7329ff"))


func _play_tab_intro(tab: Control) -> void:
	tab.modulate.a = 0.0
	tab.position.y = 12.0

	var tween: Tween = create_tween()
	tween.set_parallel(true)

	tween.tween_property(tab, "modulate:a", 1.0, 0.18)
	tween.tween_property(tab, "position:y", 0.0, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
