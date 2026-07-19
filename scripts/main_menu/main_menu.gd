extends Control

const VoidSlicerTheme: Theme = preload("res://themes/void_slicer_theme.tres")

@onready var safe_area: Control = get_node_or_null("SafeArea")
@onready var logo_container: Control = get_node_or_null("SafeArea/LogoContainer")
@onready var tagline_label: RichTextLabel = get_node_or_null("SafeArea/TaglineLabel")
@onready var button_column: VBoxContainer = get_node_or_null("SafeArea/ButtonColumn")
@onready var version_label: Label = get_node_or_null("VersionLabel")

@onready var start_button: Control = get_node_or_null("SafeArea/ButtonColumn/StartButton")
@onready var about_button: Control = get_node_or_null("SafeArea/ButtonColumn/AboutButton")
@onready var credits_button: Control = get_node_or_null("SafeArea/ButtonColumn/CreditsButton")


func _ready() -> void:
	theme = VoidSlicerTheme
	_check_required_nodes()

	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_apply_responsive_layout()

	if start_button and start_button.has_signal("pressed"):
		start_button.pressed.connect(_on_start_pressed)

	if about_button and about_button.has_signal("pressed"):
		about_button.pressed.connect(_on_about_pressed)

	if credits_button and credits_button.has_signal("pressed"):
		credits_button.pressed.connect(_on_credits_pressed)


func _check_required_nodes() -> void:
	var missing_nodes: Array[String] = []

	if safe_area == null:
		missing_nodes.append("SafeArea")

	if logo_container == null:
		missing_nodes.append("SafeArea/LogoContainer")

	if tagline_label == null:
		missing_nodes.append("SafeArea/TaglineLabel")

	if button_column == null:
		missing_nodes.append("SafeArea/ButtonColumn")

	if version_label == null:
		missing_nodes.append("VersionLabel")

	if start_button == null:
		missing_nodes.append("SafeArea/ButtonColumn/StartButton")

	if about_button == null:
		missing_nodes.append("SafeArea/ButtonColumn/AboutButton")

	if credits_button == null:
		missing_nodes.append("SafeArea/ButtonColumn/CreditsButton")

	if missing_nodes.size() > 0:
		push_error("MainMenu missing nodes: " + ", ".join(missing_nodes))


func _on_viewport_size_changed() -> void:
	_apply_responsive_layout()


func _apply_responsive_layout() -> void:
	var viewport_size := get_viewport_rect().size
	var scale_factor: float = min(viewport_size.x / 1920.0, viewport_size.y / 1080.0)
	scale_factor = clamp(scale_factor, 0.75, 1.25)

	var left_margin: float = viewport_size.x * 0.115
	var logo_y: float = viewport_size.y * 0.135
	var tagline_y: float = viewport_size.y * 0.335
	var button_y: float = viewport_size.y * 0.425

	if logo_container:
		logo_container.position = Vector2(left_margin, logo_y)
		logo_container.scale = Vector2.ONE * scale_factor

	if tagline_label:
		tagline_label.position = Vector2(left_margin + 25.0 * scale_factor, tagline_y)
		tagline_label.scale = Vector2.ONE * scale_factor

	if button_column:
		button_column.position = Vector2(left_margin + 10.0 * scale_factor, button_y)
		button_column.scale = Vector2.ONE * scale_factor

	if version_label:
		version_label.position = Vector2(
			(viewport_size.x - version_label.size.x) * 0.5,
			viewport_size.y - 58.0
		)


func _on_start_pressed() -> void:
	Navigator.go_to_home()


func _on_about_pressed() -> void:
	_show_information("ABOUT VOID SLICER", "Void Slicer is an endless incremental combat game about slicing dots, defeating bosses, and pushing deeper into the void.")


func _on_credits_pressed() -> void:
	_show_information("CREDITS", "Void Slicer\nCreated with Godot 4.")


func _show_information(title: String, message: String) -> void:
	var dialog: AcceptDialog = AcceptDialog.new()
	dialog.title = title
	dialog.dialog_text = message
	dialog.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(dialog)
	dialog.close_requested.connect(dialog.queue_free)
	dialog.confirmed.connect(dialog.queue_free)
	dialog.popup_centered(Vector2i(560, 260))
