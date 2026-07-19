extends CanvasLayer

signal restart_requested
signal claim_rewards_requested
signal return_requested
signal prestige_requested

@export_group("Main Labels")
@export var cash_value_path: NodePath
@export var cash_bonus_path: NodePath
@export var shards_value_path: NodePath
@export var shards_bonus_path: NodePath
@export var time_value_path: NodePath
@export var wave_value_path: NodePath
@export var enemies_value_path: NodePath
@export var dps_value_path: NodePath
@export var total_value_path: NodePath

@export_group("Buttons")
@export var restart_button_path: NodePath
@export var claim_button_path: NodePath
@export var return_button_path: NodePath

@export_group("Result Animation")
@export var animate_results: bool = true
@export var card_delay: float = 0.12
@export var shuffle_duration: float = 0.45
@export var shuffle_tick: float = 0.035
@export var reveal_buttons_after_results: bool = true

var cash_value_label: Label
var cash_bonus_label: Label
var shards_value_label: Label
var shards_bonus_label: Label
var time_value_label: Label
var wave_value_label: Label
var enemies_value_label: Label
var dps_value_label: Label
var total_value_label: Label

var time_bonus_label: Label
var wave_bonus_label: Label
var enemies_bonus_label: Label
var dps_bonus_label: Label

var restart_button: Button
var claim_button: Button
var return_button: Button

var has_pending_results: bool = false
var is_playing_results: bool = false

var pending_cash_earned: float = 0.0
var pending_cash_bonus: float = 0.0
var pending_shards_earned: int = 0
var pending_shards_bonus: int = 0
var pending_time_survived: float = 0.0
var pending_highest_wave: int = 0
var pending_enemies_destroyed: int = 0
var pending_peak_dps: float = 0.0
var pending_bosses_defeated: int = 0
var pending_total_rewards_value: float = 0.0

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var result_label_sequence: Array[Dictionary] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	rng.randomize()

	_cache_nodes()
	_apply_phase_one_copy()
	_connect_buttons()
	_prepare_result_nodes_for_intro()

	if has_pending_results:
		if animate_results:
			call_deferred("_play_result_sequence")
		else:
			_apply_pending_results()
			_reveal_action_buttons()

	call_deferred("_animate_in")


func _apply_phase_one_copy() -> void:
	var title_label: Label = find_child("TitleLabel", true, false) as Label
	if title_label != null:
		title_label.text = "PHASE 1 EXTRACTED"
	var subtitle_label: Label = find_child("SubtitleLabel", true, false) as Label
	if subtitle_label != null:
		subtitle_label.text = "RUN COMPLETE"
	var wave_title: Label = find_child("WaveTitle", true, false) as Label
	if wave_title != null:
		wave_title.text = "HIGHEST DEPTH"
	var rewards_grid: Control = find_child("RewardsGrid", true, false) as Control
	if rewards_grid != null:
		rewards_grid.visible = false
	var bonus_header: Control = find_child("BonusHeaderHBox", true, false) as Control
	if bonus_header != null:
		bonus_header.visible = false
	var bonus_labels: Array[Label] = [cash_bonus_label, shards_bonus_label, time_bonus_label, wave_bonus_label, enemies_bonus_label, dps_bonus_label]
	for bonus_label: Label in bonus_labels:
		if bonus_label != null:
			bonus_label.visible = false
	var total_title: Label = find_child("TotalTitleLabel", true, false) as Label
	if total_title != null:
		total_title.text = "BOSSES DEFEATED"
	if restart_button != null:
		restart_button.text = "RESTART PHASE 1"
	if claim_button != null:
		claim_button.text = "RETURN HOME"
	if return_button != null:
		return_button.text = "VIEW PRESTIGE"
	var footer: Label = find_child("FooterLabel", true, false) as Label
	if footer != null:
		footer.text = "Push deeper next time for greater rewards."


func _cache_nodes() -> void:
	cash_value_label = _get_node_by_path_or_name(cash_value_path, "CashValue") as Label
	cash_bonus_label = _get_node_by_path_or_name(cash_bonus_path, "CashBonus") as Label

	shards_value_label = _get_node_by_path_or_name(shards_value_path, "ShardsValue") as Label
	shards_bonus_label = _get_node_by_path_or_name(shards_bonus_path, "ShardsBonus") as Label

	time_value_label = _get_node_by_path_or_name(time_value_path, "TimeValue") as Label
	wave_value_label = _get_node_by_path_or_name(wave_value_path, "WaveValue") as Label
	enemies_value_label = _get_node_by_path_or_name(enemies_value_path, "EnemiesValue") as Label
	dps_value_label = _get_node_by_path_or_name(dps_value_path, "DpsValue") as Label

	total_value_label = _get_node_by_path_or_name(total_value_path, "TotalValueLabel") as Label

	time_bonus_label = find_child("TimeBonus", true, false) as Label
	wave_bonus_label = find_child("WaveBonus", true, false) as Label
	enemies_bonus_label = find_child("EnemiesBonus", true, false) as Label
	dps_bonus_label = find_child("DpsBonus", true, false) as Label

	restart_button = _get_node_by_path_or_name(restart_button_path, "RestartButton") as Button
	claim_button = _get_node_by_path_or_name(claim_button_path, "ClaimButton") as Button
	return_button = _get_node_by_path_or_name(return_button_path, "ReturnButton") as Button

	_warn_if_missing(cash_value_label, "CashValue")
	_warn_if_missing(cash_bonus_label, "CashBonus")
	_warn_if_missing(shards_value_label, "ShardsValue")
	_warn_if_missing(shards_bonus_label, "ShardsBonus")
	_warn_if_missing(time_value_label, "TimeValue")
	_warn_if_missing(wave_value_label, "WaveValue")
	_warn_if_missing(enemies_value_label, "EnemiesValue")
	_warn_if_missing(dps_value_label, "DpsValue")
	_warn_if_missing(total_value_label, "TotalValue")


func _get_node_by_path_or_name(path: NodePath, fallback_name: String) -> Node:
	var node: Node = null

	if not path.is_empty():
		node = get_node_or_null(path)

	if node == null and fallback_name != "":
		node = find_child(fallback_name, true, false)

	return node


func _warn_if_missing(node: Node, node_name: String) -> void:
	if node == null:
		push_warning("RoundEndModal: Missing node named '" + node_name + "'.")


func _connect_buttons() -> void:
	if restart_button != null and not restart_button.pressed.is_connected(_on_restart_pressed):
		restart_button.pressed.connect(_on_restart_pressed)

	if claim_button != null and not claim_button.pressed.is_connected(_on_claim_pressed):
		claim_button.pressed.connect(_on_claim_pressed)

	if return_button != null and not return_button.pressed.is_connected(_on_return_pressed):
		return_button.pressed.connect(_on_return_pressed)


func setup_results(
	cash_earned: float,
	cash_bonus: float,
	shards_earned: int,
	shards_bonus: int,
	time_survived: float,
	highest_wave: int,
	enemies_destroyed: int,
	peak_dps: float,
	total_rewards_value: float,
	bosses_defeated: int
) -> void:
	pending_cash_earned = cash_earned
	pending_cash_bonus = cash_bonus
	pending_shards_earned = shards_earned
	pending_shards_bonus = shards_bonus
	pending_time_survived = time_survived
	pending_highest_wave = highest_wave
	pending_enemies_destroyed = enemies_destroyed
	pending_peak_dps = peak_dps
	pending_total_rewards_value = total_rewards_value
	pending_bosses_defeated = bosses_defeated
	has_pending_results = true

	if is_inside_tree():
		if cash_value_label == null:
			_cache_nodes()

		_prepare_result_nodes_for_intro()

		if animate_results:
			_play_result_sequence()
		else:
			_apply_pending_results()
			_reveal_action_buttons()


func _apply_pending_results() -> void:
	if cash_value_label != null:
		cash_value_label.text = "$" + _format_number(pending_cash_earned)
		cash_value_label.modulate.a = 1.0

	if cash_bonus_label != null:
		cash_bonus_label.text = "+" + _format_number(pending_cash_bonus)
		cash_bonus_label.modulate.a = 1.0

	if shards_value_label != null:
		shards_value_label.text = _format_integer(pending_shards_earned)
		shards_value_label.modulate.a = 1.0

	if shards_bonus_label != null:
		shards_bonus_label.text = "+" + _format_integer(pending_shards_bonus)
		shards_bonus_label.modulate.a = 1.0

	if time_value_label != null:
		time_value_label.text = _format_time(pending_time_survived)
		time_value_label.modulate.a = 1.0

	if wave_value_label != null:
		wave_value_label.text = str(pending_highest_wave)
		wave_value_label.modulate.a = 1.0

	if enemies_value_label != null:
		enemies_value_label.text = _format_integer(pending_enemies_destroyed)
		enemies_value_label.modulate.a = 1.0

	if dps_value_label != null:
		dps_value_label.text = _format_number(pending_peak_dps)
		dps_value_label.modulate.a = 1.0

	if total_value_label != null:
		total_value_label.text = str(pending_bosses_defeated)
		total_value_label.modulate.a = 1.0

	if time_bonus_label != null:
		time_bonus_label.text = "New Best!"
		time_bonus_label.modulate.a = 1.0

	if wave_bonus_label != null:
		wave_bonus_label.text = "New Best!"
		wave_bonus_label.modulate.a = 1.0

	if enemies_bonus_label != null:
		enemies_bonus_label.text = "+100%"
		enemies_bonus_label.modulate.a = 1.0

	if dps_bonus_label != null:
		dps_bonus_label.text = "New Best!"
		dps_bonus_label.modulate.a = 1.0


func _prepare_result_nodes_for_intro() -> void:
	var all_value_labels: Array[Label] = [
		cash_value_label,
		cash_bonus_label,
		shards_value_label,
		shards_bonus_label,
		time_value_label,
		wave_value_label,
		enemies_value_label,
		dps_value_label,
		total_value_label,
		time_bonus_label,
		wave_bonus_label,
		enemies_bonus_label,
		dps_bonus_label
	]

	for label in all_value_labels:
		if label == null:
			continue

		label.text = "—"
		label.modulate.a = 0.0

	var card_labels: Array[Label] = [
		cash_value_label,
		shards_value_label,
		time_value_label,
		wave_value_label,
		enemies_value_label,
		dps_value_label,
		total_value_label
	]

	for label in card_labels:
		if label == null:
			continue

		var parent_card: Control = _find_nearest_card(label)

		if parent_card != null:
			parent_card.modulate.a = 0.0
			parent_card.scale = Vector2(0.96, 0.96)
			parent_card.pivot_offset = parent_card.size * 0.5

	if reveal_buttons_after_results:
		_hide_action_buttons()


func _play_result_sequence() -> void:
	if is_playing_results:
		return

	is_playing_results = true
	result_label_sequence.clear()

	result_label_sequence.append({
		"value": cash_value_label,
		"bonus": cash_bonus_label,
		"value_text": "$" + _format_number(pending_cash_earned),
		"bonus_text": "+" + _format_number(pending_cash_bonus),
		"kind": "money"
	})

	result_label_sequence.append({
		"value": shards_value_label,
		"bonus": shards_bonus_label,
		"value_text": _format_integer(pending_shards_earned),
		"bonus_text": "+" + _format_integer(pending_shards_bonus),
		"kind": "integer"
	})

	result_label_sequence.append({
		"value": time_value_label,
		"bonus": time_bonus_label,
		"value_text": _format_time(pending_time_survived),
		"bonus_text": "New Best!",
		"kind": "time"
	})

	result_label_sequence.append({
		"value": wave_value_label,
		"bonus": wave_bonus_label,
		"value_text": str(pending_highest_wave),
		"bonus_text": "New Best!",
		"kind": "integer"
	})

	result_label_sequence.append({
		"value": enemies_value_label,
		"bonus": enemies_bonus_label,
		"value_text": _format_integer(pending_enemies_destroyed),
		"bonus_text": "+100%",
		"kind": "integer"
	})

	result_label_sequence.append({
		"value": dps_value_label,
		"bonus": dps_bonus_label,
		"value_text": _format_number(pending_peak_dps),
		"bonus_text": "New Best!",
		"kind": "dps"
	})

	result_label_sequence.append({
		"value": total_value_label,
		"bonus": null,
		"value_text": str(pending_bosses_defeated),
		"bonus_text": "",
		"kind": "integer"
	})

	await _play_result_items()

	is_playing_results = false
	_reveal_action_buttons()


func _play_result_items() -> void:
	for item in result_label_sequence:
		var value_label: Label = item["value"] as Label
		var bonus_label: Label = item["bonus"] as Label
		var value_text: String = str(item["value_text"])
		var bonus_text: String = str(item["bonus_text"])
		var kind: String = str(item["kind"])

		var parent_card: Control = null

		if value_label != null:
			parent_card = _find_nearest_card(value_label)

		if parent_card != null:
			_reveal_card(parent_card)

		await get_tree().create_timer(card_delay).timeout

		if value_label != null:
			await _shuffle_label_to_text(value_label, value_text, kind)

		if bonus_label != null:
			bonus_label.modulate.a = 1.0
			await _shuffle_label_to_text(bonus_label, bonus_text, "bonus_text")


func _reveal_card(card: Control) -> void:
	card.modulate.a = 0.0
	card.scale = Vector2(0.96, 0.96)
	card.pivot_offset = card.size * 0.5

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(card, "modulate:a", 1.0, 0.16)
	tween.tween_property(card, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _shuffle_label_to_text(label: Label, final_text: String, kind: String) -> void:
	label.modulate.a = 1.0

	var elapsed: float = 0.0

	while elapsed < shuffle_duration:
		label.text = _generate_shuffle_text(final_text, kind)
		await get_tree().create_timer(shuffle_tick).timeout
		elapsed += shuffle_tick

	label.text = final_text

	var original_scale: Vector2 = label.scale
	label.pivot_offset = label.size * 0.5

	var tween: Tween = create_tween()
	tween.tween_property(label, "scale", original_scale * 1.08, 0.06)
	tween.tween_property(label, "scale", original_scale, 0.08)


func _generate_shuffle_text(final_text: String, kind: String) -> String:
	match kind:
		"money":
			return "$" + _random_compact_number()
		"integer":
			return _format_integer(rng.randi_range(100, 99999))
		"time":
			return "%02d:%02d" % [rng.randi_range(0, 14), rng.randi_range(0, 59)]
		"dps":
			return _random_compact_number()
		"bonus":
			return "+" + _random_compact_number()
		"bonus_text":
			return _random_glyph_string(final_text.length())
		_:
			return _random_glyph_string(final_text.length())


func _random_compact_number() -> String:
	var roll: int = rng.randi_range(0, 2)

	if roll == 0:
		return "%.1fk" % rng.randf_range(1.0, 999.9)

	if roll == 1:
		return "%.2fM" % rng.randf_range(1.0, 9.99)

	return _format_integer(rng.randi_range(100, 99999))


func _random_glyph_string(length: int) -> String:
	var chars: String = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	var result: String = ""

	for i in range(maxi(1, length)):
		var index: int = rng.randi_range(0, chars.length() - 1)
		result += chars[index]

	return result


func _find_nearest_card(node: Node) -> Control:
	var current: Node = node

	while current != null:
		if current is PanelContainer:
			return current as Control

		current = current.get_parent()

	return null


func _hide_action_buttons() -> void:
	var buttons: Array[Button] = [
		restart_button,
		claim_button,
		return_button
	]

	for button in buttons:
		if button == null:
			continue

		button.modulate.a = 0.0
		button.disabled = true


func _reveal_action_buttons() -> void:
	var buttons: Array[Button] = [
		restart_button,
		claim_button,
		return_button
	]

	for button in buttons:
		if button == null:
			continue

		button.disabled = false
		button.modulate.a = 0.0
		button.scale = Vector2(0.96, 0.96)
		button.pivot_offset = button.size * 0.5

		var tween: Tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(button, "modulate:a", 1.0, 0.16)
		tween.tween_property(button, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

		await get_tree().create_timer(0.07).timeout


func _animate_in() -> void:
	var overlay: Control = get_node_or_null("OverlayRoot") as Control
	var modal_panel: Control = get_node_or_null("OverlayRoot/DimBackground/ModalCenter/ModalPanel") as Control

	if overlay != null:
		overlay.modulate.a = 0.0

	if modal_panel != null:
		modal_panel.scale = Vector2(0.94, 0.94)
		modal_panel.pivot_offset = modal_panel.size * 0.5

	var tween: Tween = create_tween()
	tween.set_parallel(true)

	if overlay != null:
		tween.tween_property(overlay, "modulate:a", 1.0, 0.18)

	if modal_panel != null:
		tween.tween_property(modal_panel, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_restart_pressed() -> void:
	restart_requested.emit()


func _on_claim_pressed() -> void:
	claim_rewards_requested.emit()


func _on_return_pressed() -> void:
	prestige_requested.emit()


func _format_number(value: float) -> String:
	var abs_value: float = absf(value)

	if abs_value >= 1000000000.0:
		return "%.2fB" % (value / 1000000000.0)

	if abs_value >= 1000000.0:
		return "%.2fM" % (value / 1000000.0)

	if abs_value >= 1000.0:
		return "%.1fk" % (value / 1000.0)

	return str(roundi(value))


func _format_integer(value: int) -> String:
	var text: String = str(value)
	var result: String = ""
	var count: int = 0

	for i in range(text.length() - 1, -1, -1):
		result = text[i] + result
		count += 1

		if count == 3 and i != 0:
			result = "," + result
			count = 0

	return result


func _format_time(value: float) -> String:
	var total_seconds: int = floori(value)
	var minutes: int = total_seconds / 60
	var seconds: int = total_seconds % 60

	return "%02d:%02d" % [minutes, seconds]
