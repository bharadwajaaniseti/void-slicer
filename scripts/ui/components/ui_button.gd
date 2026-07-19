@tool
class_name VoidSlicerButton
extends Button

@export var label_text: String = "BUTTON":
	set(value):
		label_text = value
		text = value

@export_enum("Primary", "Secondary", "Quiet", "Destructive")
var visual_style: String = "Primary":
	set(value):
		visual_style = value
		_apply_visual_style()


func _ready() -> void:
	text = label_text
	_apply_visual_style()


func _apply_visual_style() -> void:
	match visual_style:
		"Secondary":
			theme_type_variation = &"SecondaryButton"
		"Quiet":
			theme_type_variation = &"QuietButton"
		"Destructive":
			theme_type_variation = &"DestructiveButton"
		_:
			theme_type_variation = &"PrimaryButton"

