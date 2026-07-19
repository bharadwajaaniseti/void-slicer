@tool
class_name VoidSlicerProgressCard
extends PanelContainer

@export var title: String = "PROGRESS":
	set(value):
		title = value
		_sync_content()
@export var current_value: float = 0.0:
	set(value):
		current_value = value
		_sync_content()
@export var maximum_value: float = 100.0:
	set(value):
		maximum_value = maxf(value, 0.001)
		_sync_content()
@export var display_text: String = "":
	set(value):
		display_text = value
		_sync_content()
@export var boss_style: bool = false:
	set(value):
		boss_style = value
		_sync_content()

@onready var title_label: Label = %TitleLabel
@onready var value_label: Label = %ValueLabel
@onready var progress_bar: ProgressBar = %ProgressBar


func _ready() -> void:
	_sync_content()


func _sync_content() -> void:
	if not is_node_ready():
		return
	title_label.text = title
	progress_bar.max_value = maximum_value
	progress_bar.value = clampf(current_value, 0.0, maximum_value)
	progress_bar.theme_type_variation = &"BossProgressBar" if boss_style else &""
	value_label.text = display_text if not display_text.is_empty() else "%d / %d" % [roundi(current_value), roundi(maximum_value)]
