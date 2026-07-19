@tool
class_name VoidSlicerStatCard
extends PanelContainer

@export var title: String = "STAT":
	set(value):
		title = value
		_sync_content()
@export var value: String = "0":
	set(new_value):
		value = new_value
		_sync_content()
@export_multiline var detail: String = "":
	set(new_value):
		detail = new_value
		_sync_content()

@onready var title_label: Label = %TitleLabel
@onready var value_label: Label = %ValueLabel
@onready var detail_label: Label = %DetailLabel


func _ready() -> void:
	_sync_content()


func _sync_content() -> void:
	if not is_node_ready():
		return
	title_label.text = title
	value_label.text = value
	detail_label.text = detail
	detail_label.visible = not detail.is_empty()

