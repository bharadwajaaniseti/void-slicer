class_name RewardSelectionModal
extends CanvasLayer

signal reward_selected(reward: RewardData)
signal reroll_requested(locked_rewards: Array[RewardData])
signal reward_skipped
signal modal_closed


enum RewardMode {
	LEVEL_UP,
	BOSS_REWARD
}


@export_group("Configuration")
@export var maximum_locks: int = 2
@export var reroll_cost: int = 50
@export var allow_skip_level_up: bool = true
@export var allow_skip_boss_reward: bool = false

@export_group("Node Paths")
@export var modal_root_path: NodePath
@export var dim_background_path: NodePath
@export var modal_panel_path: NodePath
@export var title_label_path: NodePath
@export var subtitle_label_path: NodePath
@export var reward_symbol_path: NodePath
@export var cards_container_path: NodePath
@export var reroll_button_path: NodePath
@export var lock_count_label_path: NodePath
@export var skip_button_path: NodePath

@export_group("Reward Cards")
@export var reward_card_1_path: NodePath
@export var reward_card_2_path: NodePath
@export var reward_card_3_path: NodePath


var modal_root: Control
var dim_background: ColorRect
var modal_panel: PanelContainer
var title_label: Label
var subtitle_label: Label
var reward_symbol: TextureRect
var cards_container: HBoxContainer
var reroll_button: Button
var lock_count_label: Label
var skip_button: Button

var reward_cards: Array[RewardCard] = []
var current_rewards: Array[RewardData] = []
var current_mode: RewardMode = RewardMode.LEVEL_UP

var is_open: bool = false
var is_transitioning: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	modal_root = get_node_or_null(modal_root_path) as Control
	dim_background = get_node_or_null(
		dim_background_path
	) as ColorRect
	modal_panel = get_node_or_null(
		modal_panel_path
	) as PanelContainer
	title_label = get_node_or_null(title_label_path) as Label
	subtitle_label = get_node_or_null(
		subtitle_label_path
	) as Label
	reward_symbol = get_node_or_null(
		reward_symbol_path
	) as TextureRect
	cards_container = get_node_or_null(
		cards_container_path
	) as HBoxContainer
	reroll_button = get_node_or_null(
		reroll_button_path
	) as Button
	lock_count_label = get_node_or_null(
		lock_count_label_path
	) as Label
	skip_button = get_node_or_null(
		skip_button_path
	) as Button

	_add_reward_card(reward_card_1_path)
	_add_reward_card(reward_card_2_path)
	_add_reward_card(reward_card_3_path)

	if reroll_button != null:
		if not reroll_button.pressed.is_connected(
			_on_reroll_button_pressed
		):
			reroll_button.pressed.connect(
				_on_reroll_button_pressed
			)

	if skip_button != null:
		if not skip_button.pressed.is_connected(
			_on_skip_button_pressed
		):
			skip_button.pressed.connect(
				_on_skip_button_pressed
			)

	if modal_root != null:
		modal_root.visible = false


func open_modal(
	mode: RewardMode,
	rewards: Array[RewardData]
) -> void:
	if rewards.size() < 3:
		push_error(
			"RewardSelectionModal requires at least 3 rewards."
		)
		return

	current_mode = mode
	current_rewards.clear()

	for reward: RewardData in rewards:
		current_rewards.append(reward)

	is_open = true
	is_transitioning = true

	_configure_mode()
	_setup_cards()
	_update_footer()

	if modal_root != null:
		modal_root.visible = true
		modal_root.modulate.a = 0.0

	if modal_panel != null:
		modal_panel.scale = Vector2(0.94, 0.94)
		modal_panel.pivot_offset = modal_panel.size * 0.5

	_set_cards_enabled(false)

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)

	if modal_root != null:
		tween.tween_property(
			modal_root,
			"modulate:a",
			1.0,
			0.2
		)

	if modal_panel != null:
		tween.tween_property(
			modal_panel,
			"scale",
			Vector2.ONE,
			0.32
		)

	await tween.finished

	for index: int in reward_cards.size():
		reward_cards[index].play_reveal(
			float(index) * 0.08
		)

	await get_tree().create_timer(
		0.32,
		true,
		false,
		true
	).timeout

	is_transitioning = false
	_set_cards_enabled(true)


func replace_rewards(
	rewards: Array[RewardData]
) -> void:
	if rewards.size() < reward_cards.size():
		if reroll_button != null:
			reroll_button.disabled = false

		return

	current_rewards.clear()

	for reward: RewardData in rewards:
		current_rewards.append(reward)

	for index: int in reward_cards.size():
		var card: RewardCard = reward_cards[index]

		if card.is_locked:
			continue

		card.setup(
			current_rewards[index],
			index,
			false
		)

		card.play_reroll_animation()

	_update_footer()
	_set_cards_enabled(true)

	if reroll_button != null:
		reroll_button.disabled = false


func close_modal() -> void:
	if not is_open:
		return

	if is_transitioning:
		return

	is_transitioning = true
	_set_cards_enabled(false)

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN)

	if modal_root != null:
		tween.tween_property(
			modal_root,
			"modulate:a",
			0.0,
			0.18
		)

	if modal_panel != null:
		tween.tween_property(
			modal_panel,
			"scale",
			Vector2(0.96, 0.96),
			0.18
		)

	await tween.finished

	if modal_root != null:
		modal_root.visible = false

	is_open = false
	is_transitioning = false

	_reset_cards_after_close()
	modal_closed.emit()


func _reset_cards_after_close() -> void:
	for card: RewardCard in reward_cards:
		card.set_locked(false)
		card.set_selection_enabled(true)

	if reroll_button != null:
		reroll_button.disabled = false

	if skip_button != null:
		skip_button.disabled = false


func get_locked_rewards() -> Array[RewardData]:
	var locked_rewards: Array[RewardData] = []

	for card: RewardCard in reward_cards:
		if card.is_locked and card.reward_data != null:
			locked_rewards.append(card.reward_data)

	return locked_rewards


func get_locked_indices() -> Array[int]:
	var locked_indices: Array[int] = []

	for index: int in reward_cards.size():
		if reward_cards[index].is_locked:
			locked_indices.append(index)

	return locked_indices


func get_lock_count() -> int:
	var count: int = 0

	for card: RewardCard in reward_cards:
		if card.is_locked:
			count += 1

	return count


func _add_reward_card(path: NodePath) -> void:
	var card: RewardCard = get_node_or_null(path) as RewardCard

	if card == null:
		return

	reward_cards.append(card)

	if not card.reward_selected.is_connected(
		_on_card_reward_selected
	):
		card.reward_selected.connect(
			_on_card_reward_selected
		)

	if not card.lock_changed.is_connected(
		_on_card_lock_changed
	):
		card.lock_changed.connect(
			_on_card_lock_changed
		)


func _setup_cards() -> void:
	for index: int in reward_cards.size():
		var card: RewardCard = reward_cards[index]
		card.setup(
			current_rewards[index],
			index,
			false
		)


func _configure_mode() -> void:
	if current_mode == RewardMode.LEVEL_UP:
		if title_label != null:
			title_label.text = "ASCENSION REWARD"

		if subtitle_label != null:
			subtitle_label.text = (
				"◆  CHOOSE 1 REWARD TO CONTINUE  ◆"
			)

		if skip_button != null:
			skip_button.visible = allow_skip_level_up

	else:
		if title_label != null:
			title_label.text = "BOSS REWARD"

		if subtitle_label != null:
			subtitle_label.text = (
				"◆  CHOOSE YOUR VICTORY REWARD  ◆"
			)

		if skip_button != null:
			skip_button.visible = allow_skip_boss_reward


func _update_footer() -> void:
	var lock_count: int = get_lock_count()
	var remaining_locks: int = maxi(
		maximum_locks - lock_count,
		0
	)

	if lock_count_label != null:
		lock_count_label.text = "🔒  %d locks available" % (
			remaining_locks
		)

	if reroll_button != null:
		reroll_button.text = "REROLL     ◆ %d" % reroll_cost


func _set_cards_enabled(enabled: bool) -> void:
	for card: RewardCard in reward_cards:
		card.set_selection_enabled(enabled)

	if reroll_button != null:
		reroll_button.disabled = not enabled

	if skip_button != null:
		skip_button.disabled = not enabled


func _on_card_lock_changed(
	changed_card: RewardCard,
	locked: bool
) -> void:
	if locked and get_lock_count() > maximum_locks:
		changed_card.set_locked(false)

	_update_footer()


func _on_card_reward_selected(
	_card: RewardCard,
	reward: RewardData
) -> void:
	if is_transitioning:
		return

	_set_cards_enabled(false)
	reward_selected.emit(reward)


func _on_reroll_button_pressed() -> void:
	if is_transitioning:
		return

	reroll_button.disabled = true

	var locked_rewards: Array[RewardData] = get_locked_rewards()
	reroll_requested.emit(locked_rewards)


func _on_skip_button_pressed() -> void:
	if is_transitioning:
		return

	_set_cards_enabled(false)
	reward_skipped.emit()
