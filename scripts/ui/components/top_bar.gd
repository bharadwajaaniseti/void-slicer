@tool
class_name VoidSlicerTopBar
extends PanelContainer

signal settings_requested

@export var logo_text: String = "VOID SLICER":
	set(value): logo_text = value; _sync_content()
@export var zone_text: String = "PHASE 1":
	set(value): zone_text = value; _sync_content()
@export var primary_value: String = "0":
	set(value): primary_value = value; _sync_content()
@export var primary_caption: String = "CASH":
	set(value): primary_caption = value; _sync_content()
@export var depth_value: String = "1":
	set(value): depth_value = value; _sync_content()
@export var shards_value: String = "0":
	set(value): shards_value = value; _sync_content()

@onready var logo_label: Label = %LogoLabel
@onready var zone_label: Label = %ZoneLabel
@onready var primary_caption_label: Label = %PrimaryCaption
@onready var primary_value_label: Label = %PrimaryValue
@onready var depth_value_label: Label = %DepthValue
@onready var shards_value_label: Label = %ShardsValue
@onready var settings_button: Button = %SettingsButton


func _ready() -> void:
	if not settings_button.pressed.is_connected(_on_settings_pressed):
		settings_button.pressed.connect(_on_settings_pressed)
	_sync_content()


func _sync_content() -> void:
	if not is_node_ready(): return
	logo_label.text = logo_text
	zone_label.text = zone_text
	primary_caption_label.text = primary_caption
	primary_value_label.text = primary_value
	depth_value_label.text = depth_value
	shards_value_label.text = shards_value


func _on_settings_pressed() -> void:
	settings_requested.emit()

