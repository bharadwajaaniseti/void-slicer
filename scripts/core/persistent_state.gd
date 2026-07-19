class_name PersistentState
extends Node

signal state_changed

const SAVE_VERSION: int = 1
const SAVE_PATH: String = "user://void_slicer_save.json"

var permanent_cash: float = 0.0
var boss_shards: int = 0
var best_depth: int = 1
var equipped_weapon_id: StringName = &"turret"
var unlocked_weapons: Array[StringName] = [&"turret"]


func _ready() -> void:
	load_state()


func load_state() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("PersistentState: Could not open save file.")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		push_warning("PersistentState: Save data is invalid; defaults retained.")
		return
	_apply_save_data(parsed as Dictionary)
	state_changed.emit()


func save_state() -> bool:
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("PersistentState: Could not write save file.")
		return false
	file.store_string(JSON.stringify(_build_save_data(), "\t"))
	return true


func secure_run(cash: float, shards: int, depth: int) -> void:
	permanent_cash += maxf(cash, 0.0)
	boss_shards += maxi(shards, 0)
	best_depth = maxi(best_depth, depth)
	save_state()
	state_changed.emit()


func is_weapon_unlocked(weapon_id: StringName) -> bool:
	return unlocked_weapons.has(weapon_id)


func _build_save_data() -> Dictionary:
	var weapon_ids: Array[String] = []
	for weapon_id: StringName in unlocked_weapons:
		weapon_ids.append(String(weapon_id))
	return {
		"save_version": SAVE_VERSION,
		"permanent_cash": permanent_cash,
		"boss_shards": boss_shards,
		"best_depth": best_depth,
		"equipped_weapon_id": String(equipped_weapon_id),
		"unlocked_weapons": weapon_ids
	}


func _apply_save_data(data: Dictionary) -> void:
	permanent_cash = maxf(float(data.get("permanent_cash", 0.0)), 0.0)
	boss_shards = maxi(int(data.get("boss_shards", 0)), 0)
	best_depth = maxi(int(data.get("best_depth", 1)), 1)
	equipped_weapon_id = StringName(str(data.get("equipped_weapon_id", "turret")))
	unlocked_weapons.clear()
	var saved_weapons: Variant = data.get("unlocked_weapons", ["turret"])
	if saved_weapons is Array:
		for weapon_value: Variant in saved_weapons:
			var weapon_id: StringName = StringName(str(weapon_value))
			if not weapon_id.is_empty() and not unlocked_weapons.has(weapon_id):
				unlocked_weapons.append(weapon_id)
	if not unlocked_weapons.has(&"turret"):
		unlocked_weapons.push_front(&"turret")
	if not unlocked_weapons.has(equipped_weapon_id):
		equipped_weapon_id = &"turret"
