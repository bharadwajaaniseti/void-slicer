@tool
class_name VoidSlicerModalBase
extends CanvasLayer

signal close_requested

@export var title: String = "MODAL TITLE":
	set(value):
		title = value
		_sync_content()
@export_multiline var description: String = "":
	set(value):
		description = value
		_sync_content()
@export var close_on_backdrop: bool = false

@onready var title_label: Label = %TitleLabel
@onready var description_label: Label = %DescriptionLabel
@onready var backdrop_button: Button = %BackdropButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not backdrop_button.pressed.is_connected(_on_backdrop_pressed):
		backdrop_button.pressed.connect(_on_backdrop_pressed)
	_sync_content()


func _sync_content() -> void:
	if not is_node_ready():
		return
	title_label.text = title
	description_label.text = description
	description_label.visible = not description.is_empty()


func _on_backdrop_pressed() -> void:
	if close_on_backdrop:
		close_requested.emit()

