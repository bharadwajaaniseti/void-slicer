class_name NavigationController
extends Node

const MAIN_MENU: String = "res://scenes/main_menu/MainMenu.tscn"
const HOME: String = "res://scenes/screens/HomeScreenRoot.tscn"
const DEPLOYMENT: String = "res://scenes/screens/PhaseDeploymentScreen.tscn"
const COMBAT: String = "res://scenes/screens/CombatScreen.tscn"

var pending_home_tab: StringName = &"home"


func go_to_main_menu() -> void:
	_change_scene(MAIN_MENU)


func go_to_home(tab_id: StringName = &"home") -> void:
	pending_home_tab = tab_id
	_change_scene(HOME)


func go_to_deployment() -> void:
	_change_scene(DEPLOYMENT)


func start_phase_one() -> void:
	_change_scene(COMBAT)


func _change_scene(path: String) -> void:
	if not ResourceLoader.exists(path):
		push_error("NavigationController: Scene does not exist: " + path)
		return
	get_tree().paused = false
	get_tree().change_scene_to_file(path)

