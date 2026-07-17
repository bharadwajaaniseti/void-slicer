class_name RewardCard
extends PanelContainer

signal reward_selected(card: RewardCard, reward: RewardData)
signal lock_changed(card: RewardCard, locked: bool)


@export_group("Node Paths")
@export var card_glow_path: NodePath
@export var rarity_label_path: NodePath
@export var lock_button_path: NodePath
@export var reward_icon_path: NodePath
@export var reward_name_path: NodePath
@export var description_label_path: NodePath
@export var stat_line_1_path: NodePath
@export var stat_line_2_path: NodePath
@export var stat_line_3_path: NodePath
@export var type_label_path: NodePath
@export var select_button_path: NodePath
@export var animation_player_path: NodePath


var card_glow: Panel
var rarity_label: Label
var lock_button: Button
var reward_icon: TextureRect
var reward_name: Label
var description_label: Label
var stat_line_1: Label
var stat_line_2: Label
var stat_line_3: Label
var type_label: Label
var select_button: Button
var animation_player: AnimationPlayer

var reward_data: RewardData
var is_locked: bool = false
var card_index: int = 0


func _ready() -> void:
	card_glow = get_node_or_null(card_glow_path) as Panel
	rarity_label = get_node_or_null(rarity_label_path) as Label
	lock_button = get_node_or_null(lock_button_path) as Button
	reward_icon = get_node_or_null(reward_icon_path) as TextureRect
	reward_name = get_node_or_null(reward_name_path) as Label
	description_label = get_node_or_null(description_label_path) as Label
	stat_line_1 = get_node_or_null(stat_line_1_path) as Label
	stat_line_2 = get_node_or_null(stat_line_2_path) as Label
	stat_line_3 = get_node_or_null(stat_line_3_path) as Label
	type_label = get_node_or_null(type_label_path) as Label
	select_button = get_node_or_null(select_button_path) as Button
	animation_player = get_node_or_null(animation_player_path) as AnimationPlayer

	if lock_button != null:
		if not lock_button.pressed.is_connected(_on_lock_button_pressed):
			lock_button.pressed.connect(_on_lock_button_pressed)

	if select_button != null:
		if not select_button.pressed.is_connected(_on_select_button_pressed):
			select_button.pressed.connect(_on_select_button_pressed)

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func setup(
	new_reward: RewardData,
	new_card_index: int,
	locked: bool = false
) -> void:
	reward_data = new_reward
	card_index = new_card_index
	is_locked = locked

	_update_content()
	_update_lock_visual()
	_update_rarity_style()


func set_locked(locked: bool) -> void:
	is_locked = locked
	_update_lock_visual()


func set_selection_enabled(enabled: bool) -> void:
	if select_button != null:
		select_button.disabled = not enabled

	if lock_button != null:
		lock_button.disabled = not enabled


func play_reveal(delay: float = 0.0) -> void:
	modulate.a = 0.0
	scale = Vector2(0.94, 0.94)
	pivot_offset = size * 0.5

	await get_tree().create_timer(
		delay,
		true,
		false,
		true
	).timeout

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(
		self,
		"modulate:a",
		1.0,
		0.22
	)

	tween.tween_property(
		self,
		"scale",
		Vector2.ONE,
		0.32
	)


func play_reroll_animation() -> void:
	var tween: Tween = create_tween()

	tween.tween_property(
		self,
		"modulate:a",
		0.0,
		0.12
	)

	tween.tween_callback(
		func() -> void:
			_update_content()
			_update_rarity_style()
	)

	tween.tween_property(
		self,
		"modulate:a",
		1.0,
		0.18
	)


func _update_content() -> void:
	if reward_data == null:
		return

	if reward_icon != null:
		reward_icon.texture = reward_data.icon

	if reward_name != null:
		reward_name.text = reward_data.display_name

	if description_label != null:
		description_label.text = reward_data.description

	if rarity_label != null:
		rarity_label.text = _get_rarity_name(reward_data.rarity)

	if type_label != null:
		type_label.text = _get_type_name(reward_data.reward_type)

	_set_stat_label(stat_line_1, reward_data.stat_line_1)
	_set_stat_label(stat_line_2, reward_data.stat_line_2)
	_set_stat_label(stat_line_3, reward_data.stat_line_3)


func _set_stat_label(label: Label, value: String) -> void:
	if label == null:
		return

	label.text = value
	label.visible = not value.is_empty()


func _update_lock_visual() -> void:
	if lock_button == null:
		return

	if is_locked:
		lock_button.text = "🔒"
		lock_button.tooltip_text = "Unlock this reward"
	else:
		lock_button.text = "♢"
		lock_button.tooltip_text = "Lock this reward during reroll"


func _update_rarity_style() -> void:
	if reward_data == null:
		return

	var rarity_color: Color = _get_rarity_color(reward_data.rarity)

	if rarity_label != null:
		rarity_label.add_theme_color_override(
			"font_color",
			rarity_color
		)

	var panel_style: StyleBoxFlat = get_theme_stylebox(
		"panel"
	).duplicate() as StyleBoxFlat

	if panel_style != null:
		panel_style.border_color = rarity_color.lightened(0.25)
		add_theme_stylebox_override("panel", panel_style)

	if card_glow != null:
		var glow_style: StyleBoxFlat = card_glow.get_theme_stylebox(
			"panel"
		).duplicate() as StyleBoxFlat

		if glow_style != null:
			glow_style.border_color = Color(
				rarity_color.r,
				rarity_color.g,
				rarity_color.b,
				0.55
			)

			glow_style.shadow_color = Color(
				rarity_color.r,
				rarity_color.g,
				rarity_color.b,
				0.18
			)

			card_glow.add_theme_stylebox_override(
				"panel",
				glow_style
			)


func _get_rarity_name(rarity: RewardData.RewardRarity) -> String:
	match rarity:
		RewardData.RewardRarity.COMMON:
			return "COMMON"

		RewardData.RewardRarity.UNCOMMON:
			return "UNCOMMON"

		RewardData.RewardRarity.RARE:
			return "RARE"

		RewardData.RewardRarity.EPIC:
			return "EPIC"

		RewardData.RewardRarity.LEGENDARY:
			return "LEGENDARY"

	return "COMMON"


func _get_type_name(type: RewardData.RewardType) -> String:
	match type:
		RewardData.RewardType.PASSIVE:
			return "PASSIVE"

		RewardData.RewardType.ABILITY:
			return "ABILITY"

		RewardData.RewardType.WEAPON_UPGRADE:
			return "WEAPON UPGRADE"

		RewardData.RewardType.NEW_WEAPON:
			return "NEW WEAPON"

		RewardData.RewardType.WEAPON_TIER:
			return "TIER UPGRADE"

		RewardData.RewardType.WEAPON_SLOT:
			return "WEAPON SLOT"

	return "REWARD"


func _get_rarity_color(
	rarity: RewardData.RewardRarity
) -> Color:
	match rarity:
		RewardData.RewardRarity.COMMON:
			return Color("#758095")

		RewardData.RewardRarity.UNCOMMON:
			return Color("#18B66B")

		RewardData.RewardRarity.RARE:
			return Color("#1674F5")

		RewardData.RewardRarity.EPIC:
			return Color("#7837EE")

		RewardData.RewardRarity.LEGENDARY:
			return Color("#F18A19")

	return Color("#758095")


func _on_lock_button_pressed() -> void:
	is_locked = not is_locked
	_update_lock_visual()
	lock_changed.emit(self, is_locked)


func _on_select_button_pressed() -> void:
	if reward_data == null:
		return

	reward_selected.emit(self, reward_data)


func _on_mouse_entered() -> void:
	if select_button != null and select_button.disabled:
		return

	pivot_offset = size * 0.5

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(
		self,
		"scale",
		Vector2(1.025, 1.025),
		0.12
	)


func _on_mouse_exited() -> void:
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(
		self,
		"scale",
		Vector2.ONE,
		0.12
	)
