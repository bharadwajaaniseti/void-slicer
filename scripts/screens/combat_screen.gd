extends Control


@export_group("Scene Navigation")
@export var home_scene_path: String = "res://scenes/screens/HomeScreenRoot.tscn"

const RoundEndModalScene: PackedScene = preload(
	"res://scenes/screens/RoundEndModal.tscn"
)

const RunBalanceScript: Script = preload("res://scripts/run/run_balance.gd")
const RunStateScript: Script = preload("res://scripts/run/run_state.gd")
const RunUpgradeManagerScript: Script = preload("res://scripts/run/run_upgrade_manager.gd")
const RunUpgradeDebugPanelScript: Script = preload("res://scripts/ui/run_upgrade_debug_panel.gd")


@export_group("Core Node Paths")
@export var arena_path: NodePath = ^"MainVBox/CombatArena"
@export var reward_manager_path: NodePath = ^"RewardManager"
@export var reward_modal_path: NodePath = ^"RewardSelectionModal"


@export_group("Top Bar Node Paths")
@export var currency_label_path: NodePath = ^"MainVBox/TopBar/TopBarMargin/TopBarHBox/LeftCluster/CenterCluster/CurrencyCard/CurrencyBox/CurrencyLabel"

@export var cps_label_path: NodePath = ^"MainVBox/TopBar/TopBarMargin/TopBarHBox/LeftCluster/CenterCluster/CurrencyCard/CurrencyBox/CpsLabel"

@export var wave_value_label_path: NodePath = ^"MainVBox/TopBar/TopBarMargin/TopBarHBox/RightCluster/WaveVBox/WaveValueLabel"

@export var dps_value_label_path: NodePath = ^"MainVBox/TopBar/TopBarMargin/TopBarHBox/RightCluster/DpsVBox/DpsValueLabel"

@export var time_label_path: NodePath = ^"MainVBox/TopBar/TopBarMargin/TopBarHBox/RightCluster/TimeCard/TimeHBox/TimeLabel"


@export_group("Bottom Bar Node Paths")
@export var end_combat_button_path: NodePath = ^"MainVBox/BottomBar/BottomBarMargin/BottomVBoxContainer/BottomBarHBox/EndCombatButton"

@export var combat_xp_label_path: NodePath = ^"MainVBox/BottomBar/BottomBarMargin/BottomVBoxContainer/XPHBoxContainer/XPLabel"

@export var combat_xp_progress_bar_path: NodePath = ^"MainVBox/BottomBar/BottomBarMargin/BottomVBoxContainer/XPHBoxContainer/XPProgressBar"


@export_group("Ability Card Node Paths")
@export var frenzy_card_path: NodePath
@export var dot_rain_card_path: NodePath
@export var black_hole_card_path: NodePath
@export var focus_fire_card_path: NodePath
@export var drone_swarm_card_path: NodePath


@export_group("Boss Progress Node Paths")
@export var boss_label_path: NodePath = ^"MainVBox/TopBar/TopBarMargin/TopBarHBox/LeftCluster/CenterCluster/ProgressRow/BossCard/ProgressHBox/BossLabel"

@export var boss_progress_value_label_path: NodePath = ^"MainVBox/TopBar/TopBarMargin/TopBarHBox/LeftCluster/CenterCluster/ProgressRow/BossCard/ProgressHBox/XPLabel"

@export var boss_progress_bar_path: NodePath = ^"MainVBox/TopBar/TopBarMargin/TopBarHBox/LeftCluster/CenterCluster/ProgressRow/ProgressBar"


@export_group("Run Values")
@export var earned_currency: float = 0.0
@export var currency_per_second: float = 0.0
@export var current_wave: int = 1
@export var current_dps: float = 0.0


@export_group("Boss Progress Values")
@export var boss_name: String = "Boss"
@export var boss_progress_current: float = 0.0
@export var boss_progress_max: float = 2000.0


@export_group("Combat XP")
@export var starting_combat_level: int = 1
@export var starting_xp_requirement: int = 100

@export_range(1.01, 5.0, 0.01)
var xp_requirement_growth: float = 1.35

@export var normal_dot_xp: int = 5
@export var boss_kill_xp: int = 75
@export var show_xp_numbers_in_label: bool = true


@export_group("Reward Modal Settings")
@export var level_up_maximum_locks: int = 2
@export var boss_reward_maximum_locks: int = 1

@export var level_up_reroll_cost: int = 50
@export var boss_reward_reroll_cost: int = 100

## Temporary testing currency.
@export var reroll_currency_balance: int = 500


@export_group("Timer")
@export var run_duration_seconds: float = 60.0
@export var endless_combat_enabled: bool = true


@export_group("Round Reward Calculation")
@export var shard_value_in_cash: float = 100.0
@export var shards_per_enemy: float = 1.25
@export var shards_per_boss_bonus: int = 100
@export var cash_bonus_percent: float = 0.10
@export var shard_bonus_percent: float = 0.10


var run_cash_earned: float = 0.0
var run_cash_bonus: float = 0.0
var run_shards_earned: int = 0
var run_shards_bonus: int = 0

var enemies_destroyed: int = 0
var bosses_destroyed: int = 0
var peak_dps: float = 0.0
var highest_wave_reached: int = 1

var round_end_modal_open: bool = false
var timer_finished: bool = false

var normal_progress_fill_color: Color = Color("#7437FF")
var boss_progress_fill_color: Color = Color("#FF2A2A")
var xp_progress_fill_color: Color = Color("#21B77A")

var time_remaining: float = 60.0
var elapsed_run_time: float = 0.0


# -------------------------------------------------------------------
# Incremental run systems
# -------------------------------------------------------------------

var run_balance: RunBalance
var run_state: RunState
var run_upgrade_manager: RunUpgradeManager
var run_upgrade_debug_panel: RunUpgradeDebugPanel


# -------------------------------------------------------------------
# XP state
# -------------------------------------------------------------------

var combat_level: int = 1
var current_combat_xp: int = 0
var combat_xp_required: int = 100


# -------------------------------------------------------------------
# Reward modal state
# -------------------------------------------------------------------

var reward_modal_active: bool = false
var reward_modal_is_closing: bool = false

var active_reward_mode: int = (
	RewardSelectionModal.RewardMode.LEVEL_UP
)

var queued_reward_modes: Array[int] = []


# -------------------------------------------------------------------
# Cached nodes
# -------------------------------------------------------------------

var arena: Control

var reward_manager: RewardManager
var reward_modal: RewardSelectionModal

var currency_label: Label
var cps_label: Label
var wave_value_label: Label
var dps_value_label: Label
var time_label: Label

var boss_label: Label
var boss_progress_value_label: Label
var boss_progress_bar: ProgressBar

var combat_xp_label: Label
var combat_xp_progress_bar: ProgressBar

var end_combat_button: Button

var frenzy_card: CombatAbilityCard
var dot_rain_card: CombatAbilityCard
var black_hole_card: CombatAbilityCard
var focus_fire_card: CombatAbilityCard
var drone_swarm_card: CombatAbilityCard


func _ready() -> void:
	set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	_cache_nodes()
	_setup_run_systems()
	_connect_arena_signals()
	_connect_buttons()
	_connect_reward_system()
	_setup_ability_cards()
	_setup_progress_bar_styles()

	_reset_run_stats()
	_sync_reward_modifiers_to_arena()
	_update_all_ui()


func _process(delta: float) -> void:
	if round_end_modal_open:
		return

	if reward_modal_active:
		return

	if endless_combat_enabled:
		elapsed_run_time += delta

		if time_label != null:
			time_label.text = "ENDLESS " + _format_time(
				elapsed_run_time
			)

		return

	if time_remaining <= 0.0:
		return

	time_remaining -= delta

	if time_remaining <= 0.0:
		time_remaining = 0.0
		timer_finished = true

		if time_label != null:
			time_label.text = _format_time(
				time_remaining
			)

		_on_timer_finished()
		return

	if time_label != null:
		if endless_combat_enabled:
			time_label.text = "ENDLESS " + _format_time(
				elapsed_run_time
			)
		else:
			time_label.text = _format_time(
				time_remaining
			)


# ===================================================================
# INITIAL SETUP
# ===================================================================

func _reset_run_stats() -> void:
	time_remaining = run_duration_seconds
	elapsed_run_time = 0.0
	timer_finished = false
	round_end_modal_open = false

	reward_modal_active = false
	reward_modal_is_closing = false
	queued_reward_modes.clear()

	run_cash_earned = 0.0
	run_cash_bonus = 0.0
	run_shards_earned = 0
	run_shards_bonus = 0

	enemies_destroyed = 0
	bosses_destroyed = 0
	peak_dps = 0.0
	highest_wave_reached = current_wave

	earned_currency = 0.0
	current_dps = 0.0

	combat_level = maxi(
		starting_combat_level,
		1
	)

	current_combat_xp = 0

	combat_xp_required = _calculate_xp_requirement(
		combat_level
	)

	if reward_manager != null:
		reward_manager.reset_run_modifiers()

	if run_state != null:
		run_state.reset_run()

	if run_upgrade_manager != null:
		run_upgrade_manager.reset_upgrades()

	get_tree().paused = false


func _setup_run_systems() -> void:
	run_balance = RunBalanceScript.new() as RunBalance
	run_state = RunStateScript.new() as RunState
	run_upgrade_manager = RunUpgradeManagerScript.new() as RunUpgradeManager

	if run_state != null:
		run_state.name = "RunState"
		add_child(run_state)

	if run_upgrade_manager != null:
		run_upgrade_manager.name = "RunUpgradeManager"
		add_child(run_upgrade_manager)
		run_upgrade_manager.configure(run_state)

	_connect_run_state_signals()
	_connect_run_upgrade_signals()

	if arena != null:
		if arena.has_method("configure_incremental_systems"):
			arena.call(
				"configure_incremental_systems",
				run_state,
				run_balance,
				run_upgrade_manager
			)

	_setup_run_upgrade_debug_panel()


func _connect_run_state_signals() -> void:
	if run_state == null:
		return

	if not run_state.cash_changed.is_connected(_on_run_cash_changed):
		run_state.cash_changed.connect(_on_run_cash_changed)

	if not run_state.xp_changed.is_connected(_on_run_xp_changed):
		run_state.xp_changed.connect(_on_run_xp_changed)

	if not run_state.core_energy_changed.is_connected(_on_run_core_energy_changed):
		run_state.core_energy_changed.connect(_on_run_core_energy_changed)

	if not run_state.sector_stage_changed.is_connected(_on_run_sector_stage_changed):
		run_state.sector_stage_changed.connect(_on_run_sector_stage_changed)

	if not run_state.kills_changed.is_connected(_on_run_kills_changed):
		run_state.kills_changed.connect(_on_run_kills_changed)


func _connect_run_upgrade_signals() -> void:
	if run_upgrade_manager == null:
		return

	if not run_upgrade_manager.upgrades_changed.is_connected(_on_run_upgrades_changed):
		run_upgrade_manager.upgrades_changed.connect(_on_run_upgrades_changed)


func _setup_run_upgrade_debug_panel() -> void:
	if run_state == null:
		return

	if run_upgrade_manager == null:
		return

	run_upgrade_debug_panel = RunUpgradeDebugPanelScript.new() as RunUpgradeDebugPanel

	if run_upgrade_debug_panel == null:
		return

	run_upgrade_debug_panel.name = "RunUpgradeDebugPanel"
	add_child(run_upgrade_debug_panel)
	run_upgrade_debug_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	run_upgrade_debug_panel.offset_left = -330.0
	run_upgrade_debug_panel.offset_top = 120.0
	run_upgrade_debug_panel.offset_right = -16.0
	run_upgrade_debug_panel.offset_bottom = 0.0
	run_upgrade_debug_panel.configure(run_state, run_upgrade_manager)

	if not run_upgrade_debug_panel.farm_requested.is_connected(_on_farm_requested):
		run_upgrade_debug_panel.farm_requested.connect(_on_farm_requested)

	if not run_upgrade_debug_panel.advance_requested.is_connected(_on_advance_requested):
		run_upgrade_debug_panel.advance_requested.connect(_on_advance_requested)


func _cache_nodes() -> void:
	arena = _get_node_by_path_or_name(
		arena_path,
		"CombatArena"
	) as Control

	reward_manager = _get_node_by_path_or_name(
		reward_manager_path,
		"RewardManager"
	) as RewardManager

	reward_modal = _get_node_by_path_or_name(
		reward_modal_path,
		"RewardSelectionModal"
	) as RewardSelectionModal

	currency_label = _get_node_by_path_or_name(
		currency_label_path,
		"CurrencyLabel"
	) as Label

	cps_label = _get_node_by_path_or_name(
		cps_label_path,
		"CpsLabel"
	) as Label

	wave_value_label = _get_node_by_path_or_name(
		wave_value_label_path,
		"WaveValueLabel"
	) as Label

	dps_value_label = _get_node_by_path_or_name(
		dps_value_label_path,
		"DpsValueLabel"
	) as Label

	time_label = _get_node_by_path_or_name(
		time_label_path,
		"TimeLabel"
	) as Label

	boss_label = _get_node_by_path_or_name(
		boss_label_path,
		"BossLabel"
	) as Label

	boss_progress_value_label = _get_node_by_path_or_name(
		boss_progress_value_label_path,
		"XPLabel"
	) as Label

	boss_progress_bar = _get_node_by_path_or_name(
		boss_progress_bar_path,
		"ProgressBar"
	) as ProgressBar

	combat_xp_label = _get_node_by_path_or_name(
		combat_xp_label_path,
		"XPLabel"
	) as Label

	combat_xp_progress_bar = _get_node_by_path_or_name(
		combat_xp_progress_bar_path,
		"XPProgressBar"
	) as ProgressBar

	end_combat_button = _get_node_by_path_or_name(
		end_combat_button_path,
		"EndCombatButton"
	) as Button

	frenzy_card = _get_node_by_path_or_name(
		frenzy_card_path,
		"FrenzySkillCard"
	) as CombatAbilityCard

	dot_rain_card = _get_node_by_path_or_name(
		dot_rain_card_path,
		"DotRainSkillCard"
	) as CombatAbilityCard

	black_hole_card = _get_node_by_path_or_name(
		black_hole_card_path,
		"BlackHoleSkillCard"
	) as CombatAbilityCard

	focus_fire_card = _get_node_by_path_or_name(
		focus_fire_card_path,
		"FocusFireSkillCard"
	) as CombatAbilityCard

	drone_swarm_card = _get_node_by_path_or_name(
		drone_swarm_card_path,
		"DroneSwarmSkillCard"
	) as CombatAbilityCard


func _get_node_by_path_or_name(
	path: NodePath,
	fallback_name: String
) -> Node:
	var node: Node = null

	if not path.is_empty():
		node = get_node_or_null(path)

	if node == null and not fallback_name.is_empty():
		node = find_child(
			fallback_name,
			true,
			false
		)

	return node


func _setup_progress_bar_styles() -> void:
	_set_boss_progress_fill_color(
		normal_progress_fill_color
	)

	_set_xp_progress_fill_color(
		xp_progress_fill_color
	)


# ===================================================================
# CONNECTIONS
# ===================================================================

func _connect_arena_signals() -> void:
	if arena == null:
		push_warning(
			"CombatScreen: CombatArena not found."
		)
		return

	_connect_arena_signal(
		"enemy_destroyed",
		"_on_enemy_destroyed"
	)

	_connect_arena_signal(
		"enemy_xp_gained",
		"_on_enemy_xp_gained"
	)

	_connect_arena_signal(
		"boss_destroyed",
		"_on_boss_destroyed"
	)

	_connect_arena_signal(
		"boss_xp_gained",
		"_on_boss_xp_gained"
	)

	_connect_arena_signal(
		"currency_gained",
		"_on_currency_gained"
	)

	_connect_arena_signal(
		"dps_updated",
		"_on_dps_updated"
	)

	_connect_arena_signal(
		"wave_changed",
		"_on_wave_changed"
	)

	_connect_arena_signal(
		"boss_progress_changed",
		"_on_boss_progress_changed"
	)

	_connect_arena_signal(
		"combat_finished",
		"_on_combat_finished_from_arena"
	)

	_connect_arena_signal(
		"stage_completed",
		"_on_stage_completed"
	)

func _on_boss_destroyed() -> void:
	if round_end_modal_open:
		return

	if run_state == null:
		bosses_destroyed += 1

		# Add boss XP first.
		# When this completes the XP bar, the level-up reward is queued first.
		add_combat_xp(
			_get_boss_xp_reward()
		)

	# Queue the guaranteed boss reward after the level-up reward.
	request_boss_reward()
	
func _connect_arena_signal(
	signal_name: StringName,
	method_name: StringName
) -> void:
	if arena == null:
		return

	if not arena.has_signal(signal_name):
		return

	var callable: Callable = Callable(
		self,
		method_name
	)

	if not arena.is_connected(
		signal_name,
		callable
	):
		arena.connect(
			signal_name,
			callable
		)


func _connect_buttons() -> void:
	if end_combat_button == null:
		push_warning(
			"CombatScreen: EndCombatButton not found."
		)
		return

	if not end_combat_button.pressed.is_connected(
		_on_end_combat_pressed
	):
		end_combat_button.pressed.connect(
			_on_end_combat_pressed
		)


func _connect_reward_system() -> void:
	if reward_manager == null:
		push_warning(
			"CombatScreen: RewardManager not found."
		)
	else:
		if not reward_manager.modifiers_changed.is_connected(
			_on_reward_modifiers_changed
		):
			reward_manager.modifiers_changed.connect(
				_on_reward_modifiers_changed
			)

		if not reward_manager.weapon_unlocked.is_connected(
			_on_reward_weapon_unlocked
		):
			reward_manager.weapon_unlocked.connect(
				_on_reward_weapon_unlocked
			)

		if not reward_manager.weapon_tier_changed.is_connected(
			_on_reward_weapon_tier_changed
		):
			reward_manager.weapon_tier_changed.connect(
				_on_reward_weapon_tier_changed
			)

	if reward_modal == null:
		push_warning(
			"CombatScreen: RewardSelectionModal not found."
		)
		return

	if not reward_modal.reward_selected.is_connected(
		_on_reward_selected
	):
		reward_modal.reward_selected.connect(
			_on_reward_selected
		)

	if not reward_modal.reroll_requested.is_connected(
		_on_reward_reroll_requested
	):
		reward_modal.reroll_requested.connect(
			_on_reward_reroll_requested
		)

	if not reward_modal.reward_skipped.is_connected(
		_on_reward_skipped
	):
		reward_modal.reward_skipped.connect(
			_on_reward_skipped
		)

	if not reward_modal.modal_closed.is_connected(
		_on_reward_modal_closed
	):
		reward_modal.modal_closed.connect(
			_on_reward_modal_closed
		)


# ===================================================================
# ABILITY CARDS
# ===================================================================

func _setup_ability_cards() -> void:
	_connect_ability_card(frenzy_card)
	_connect_ability_card(dot_rain_card)
	_connect_ability_card(black_hole_card)
	_connect_ability_card(focus_fire_card)
	_connect_ability_card(drone_swarm_card)

	if drone_swarm_card != null:
		drone_swarm_card.set_auto_enabled(true)


func _connect_ability_card(
	card: CombatAbilityCard
) -> void:
	if card == null:
		return

	if not card.ability_pressed.is_connected(
		_on_ability_card_pressed
	):
		card.ability_pressed.connect(
			_on_ability_card_pressed
		)


func _on_ability_card_pressed(
	ability_id: String
) -> void:
	if reward_modal_active:
		return

	if round_end_modal_open:
		return

	if arena == null:
		return

	if not arena.has_method("activate_ability"):
		return

	var activated: bool = bool(
		arena.call(
			"activate_ability",
			ability_id
		)
	)

	if not activated:
		return

	var card: CombatAbilityCard = (
		_get_ability_card_by_id(ability_id)
	)

	if card == null:
		return

	if card.is_auto_ability:
		if ability_id == "drone_swarm":
			card.set_auto_enabled(
				_get_drone_swarm_enabled_from_arena()
			)

		return

	_start_ability_card_cooldown(card)


func _start_ability_card_cooldown(
	card: CombatAbilityCard
) -> void:
	if card == null:
		return

	var cooldown_multiplier: float = 1.0

	if reward_manager != null:
		cooldown_multiplier = (
			reward_manager.ability_cooldown_multiplier
		)

	card.start_cooldown()

	card.cooldown_left = maxf(
		card.cooldown_duration * cooldown_multiplier,
		0.1
	)


func _get_ability_card_by_id(
	ability_id: String
) -> CombatAbilityCard:
	match ability_id:
		"frenzy":
			return frenzy_card

		"dot_rain":
			return dot_rain_card

		"black_hole":
			return black_hole_card

		"focus_fire":
			return focus_fire_card

		"drone_swarm":
			return drone_swarm_card

	return null


func _get_drone_swarm_enabled_from_arena() -> bool:
	if arena == null:
		return true

	if not arena.has_method("is_drone_swarm_enabled"):
		return true

	return bool(
		arena.call("is_drone_swarm_enabled")
	)


# ===================================================================
# XP SYSTEM
# ===================================================================

func add_combat_xp(amount: int) -> void:
	if amount <= 0:
		return

	if round_end_modal_open:
		return

	current_combat_xp += amount

	_update_combat_xp_ui()
	_check_for_pending_level_up()


func _get_dot_xp_reward() -> int:
	var multiplier: float = 1.0

	if reward_manager != null:
		multiplier = reward_manager.dot_xp_multiplier

	return maxi(
		roundi(float(normal_dot_xp) * multiplier),
		1
	)


func _get_boss_xp_reward() -> int:
	var multiplier: float = 1.0

	if reward_manager != null:
		multiplier = reward_manager.boss_xp_multiplier

	return maxi(
		roundi(float(boss_kill_xp) * multiplier),
		1
	)


func _check_for_pending_level_up() -> void:
	if current_combat_xp < combat_xp_required:
		return

	if _has_level_up_reward_pending():
		return

	_queue_reward_modal(
		RewardSelectionModal.RewardMode.LEVEL_UP
	)


func _has_level_up_reward_pending() -> bool:
	if reward_modal_active:
		if active_reward_mode == (
			RewardSelectionModal.RewardMode.LEVEL_UP
		):
			return true

	for queued_mode: int in queued_reward_modes:
		if queued_mode == (
			RewardSelectionModal.RewardMode.LEVEL_UP
		):
			return true

	return false


func _complete_level_up() -> void:
	current_combat_xp = maxi(
		current_combat_xp - combat_xp_required,
		0
	)

	combat_level += 1

	combat_xp_required = _calculate_xp_requirement(
		combat_level
	)

	_update_combat_xp_ui()

	if current_combat_xp >= combat_xp_required:
		_queue_reward_modal(
			RewardSelectionModal.RewardMode.LEVEL_UP
		)


func _calculate_xp_requirement(
	level: int
) -> int:
	var exponent: int = maxi(
		level - starting_combat_level,
		0
	)

	return maxi(
		roundi(
			float(starting_xp_requirement)
			* pow(
				xp_requirement_growth,
				exponent
			)
		),
		1
	)


func _update_combat_xp_ui() -> void:
	if combat_xp_progress_bar != null:
		combat_xp_progress_bar.min_value = 0.0
		combat_xp_progress_bar.max_value = float(
			combat_xp_required
		)

		combat_xp_progress_bar.value = clampf(
			float(current_combat_xp),
			0.0,
			float(combat_xp_required)
		)

	if combat_xp_label != null:
		if show_xp_numbers_in_label:
			combat_xp_label.text = (
				"LV. %d  XP %s / %s"
				% [
					combat_level,
					_format_integer(
						current_combat_xp
					),
					_format_integer(
						combat_xp_required
					)
				]
			)
		else:
			combat_xp_label.text = (
				"LV. %d  XP" % combat_level
			)


# ===================================================================
# REWARD MODAL
# ===================================================================

func request_level_up_reward() -> void:
	_queue_reward_modal(
		RewardSelectionModal.RewardMode.LEVEL_UP
	)


func request_boss_reward() -> void:
	_queue_reward_modal(
		RewardSelectionModal.RewardMode.BOSS_REWARD
	)


func _queue_reward_modal(mode: int) -> void:
	if round_end_modal_open:
		return

	queued_reward_modes.append(mode)

	if not reward_modal_active:
		_open_next_reward_modal()


func _open_next_reward_modal() -> void:
	if round_end_modal_open:
		return

	if reward_modal_active:
		return

	if queued_reward_modes.is_empty():
		_resume_combat_after_rewards()
		return

	if reward_manager == null:
		push_warning(
			"CombatScreen: RewardManager is missing."
		)

		queued_reward_modes.clear()
		_resume_combat_after_rewards()
		return

	if reward_modal == null:
		push_warning(
			"CombatScreen: RewardSelectionModal is missing."
		)

		queued_reward_modes.clear()
		_resume_combat_after_rewards()
		return

	active_reward_mode = queued_reward_modes.pop_front()

	var choices: Array[RewardData] = (
		_generate_reward_choices(
			active_reward_mode,
			3,
			[]
		)
	)

	if choices.size() < 3:
		push_warning(
			"CombatScreen: Not enough valid rewards for mode: "
			+ str(active_reward_mode)
		)

		# Do not destroy the rest of the queue.
		# Skip only the invalid reward request.
		call_deferred("_open_next_reward_modal")
		return

	reward_modal_active = true
	reward_modal_is_closing = false

	_configure_reward_modal()
	_pause_combat_for_reward()

	reward_modal.open_modal(
		active_reward_mode,
		choices
	)

func _configure_reward_modal() -> void:
	if reward_modal == null:
		return

	if active_reward_mode == (
		RewardSelectionModal.RewardMode.LEVEL_UP
	):
		reward_modal.maximum_locks = (
			level_up_maximum_locks
		)

		reward_modal.reroll_cost = (
			level_up_reroll_cost
		)
	else:
		reward_modal.maximum_locks = (
			boss_reward_maximum_locks
		)

		reward_modal.reroll_cost = (
			boss_reward_reroll_cost
		)


func _generate_reward_choices(
	mode: int,
	count: int,
	excluded_rewards: Array[RewardData]
) -> Array[RewardData]:
	if reward_manager == null:
		return []

	if mode == (
		RewardSelectionModal.RewardMode.LEVEL_UP
	):
		return reward_manager.generate_level_up_choices(
			count,
			excluded_rewards
		)

	return reward_manager.generate_boss_choices(
		count,
		excluded_rewards
	)


func _on_reward_selected(
	reward: RewardData
) -> void:
	if reward_modal_is_closing:
		return

	reward_modal_is_closing = true

	var reward_applied: bool = false

	if reward_manager != null:
		reward_applied = reward_manager.apply_reward(
			reward
		)

	if not reward_applied:
		push_warning(
			"Selected reward could not be applied: "
			+ reward.reward_id
		)

	if active_reward_mode == (
		RewardSelectionModal.RewardMode.LEVEL_UP
	):
		_complete_level_up()

	_sync_reward_modifiers_to_arena()

	if reward_modal != null:
		reward_modal.close_modal()


func _on_reward_reroll_requested(
	_locked_rewards: Array[RewardData]
) -> void:
	if reward_manager == null:
		return

	if reward_modal == null:
		return

	if reward_modal_is_closing:
		return

	var reroll_cost: int = (
		_get_current_reroll_cost()
	)

	if not _can_afford_reroll(reroll_cost):
		push_warning(
			"Not enough reroll currency."
		)

		reward_modal.set_deferred(
			"is_transitioning",
			false
		)

		return

	var locked_count: int = (
		reward_modal.get_lock_count()
	)

	var replacement_count: int = maxi(
		3 - locked_count,
		0
	)

	if replacement_count <= 0:
		return

	var excluded_rewards: Array[RewardData] = []

	for card: RewardCard in reward_modal.reward_cards:
		if card.reward_data != null:
			excluded_rewards.append(
				card.reward_data
			)

	var replacement_rewards: Array[RewardData] = (
		_generate_reward_choices(
			active_reward_mode,
			replacement_count,
			excluded_rewards
		)
	)

	if replacement_rewards.size() < replacement_count:
		push_warning(
			"Not enough rewards available for reroll."
		)

		reward_modal.replace_rewards(
			reward_modal.current_rewards
		)

		return

	var combined_rewards: Array[RewardData] = []
	var replacement_index: int = 0

	for card: RewardCard in reward_modal.reward_cards:
		if card.is_locked:
			combined_rewards.append(
				card.reward_data
			)
		else:
			combined_rewards.append(
				replacement_rewards[
					replacement_index
				]
			)

			replacement_index += 1

	_spend_reroll_currency(reroll_cost)

	reward_modal.replace_rewards(
		combined_rewards
	)


func _on_reward_skipped() -> void:
	if reward_modal_is_closing:
		return

	reward_modal_is_closing = true

	if active_reward_mode == (
		RewardSelectionModal.RewardMode.LEVEL_UP
	):
		_complete_level_up()

	if reward_modal != null:
		reward_modal.close_modal()


func _on_reward_modal_closed() -> void:
	reward_modal_active = false
	reward_modal_is_closing = false

	_open_next_reward_modal()


func _get_current_reroll_cost() -> int:
	if active_reward_mode == (
		RewardSelectionModal.RewardMode.LEVEL_UP
	):
		return level_up_reroll_cost

	return boss_reward_reroll_cost


func _can_afford_reroll(
	cost: int
) -> bool:
	return reroll_currency_balance >= cost


func _spend_reroll_currency(
	cost: int
) -> void:
	reroll_currency_balance = maxi(
		reroll_currency_balance - cost,
		0
	)


# ===================================================================
# REWARD MODIFIER SYNCHRONIZATION
# ===================================================================

func _on_reward_modifiers_changed() -> void:
	_sync_reward_modifiers_to_arena()


func _sync_reward_modifiers_to_arena() -> void:
	if arena == null:
		return

	if reward_manager == null:
		return

	if arena.has_method("update_reward_modifiers"):
		arena.call(
			"update_reward_modifiers",
			reward_manager.global_damage_multiplier,
			reward_manager.boss_damage_multiplier,
			reward_manager.global_attack_speed_multiplier,
			reward_manager.critical_chance,
			reward_manager.critical_damage_multiplier
		)

	if arena.has_method("update_weapon_reward_modifiers"):
		arena.call(
			"update_weapon_reward_modifiers",
			reward_manager.weapon_damage_multipliers,
			reward_manager.weapon_attack_speed_multipliers,
			reward_manager.weapon_range_multipliers,
			reward_manager.weapon_tiers
		)


func _on_reward_weapon_unlocked(
	weapon_id: String
) -> void:
	if arena == null:
		return

	if arena.has_method("unlock_combat_weapon"):
		arena.call(
			"unlock_combat_weapon",
			weapon_id
		)


func _on_reward_weapon_tier_changed(
	weapon_id: String,
	new_tier: int
) -> void:
	if arena == null:
		return

	if arena.has_method("set_weapon_tier"):
		arena.call(
			"set_weapon_tier",
			weapon_id,
			new_tier
		)


# ===================================================================
# PAUSE
# ===================================================================

func _pause_combat_for_reward() -> void:
	if arena != null:
		if arena.has_method("set_combat_paused"):
			arena.call(
				"set_combat_paused",
				true
			)

	get_tree().paused = true


func _resume_combat_after_rewards() -> void:
	if round_end_modal_open:
		return

	if reward_modal_active:
		return

	if not queued_reward_modes.is_empty():
		return

	if arena != null:
		if arena.has_method("set_combat_paused"):
			arena.call(
				"set_combat_paused",
				false
			)

	get_tree().paused = false


# ===================================================================
# ARENA SIGNALS
# ===================================================================

func _on_enemy_destroyed() -> void:
	if reward_modal_active:
		return

	if round_end_modal_open:
		return

	if run_state == null:
		enemies_destroyed += 1
		add_combat_xp(_get_dot_xp_reward())


func _on_enemy_xp_gained(
	amount: float
) -> void:
	if reward_modal_active:
		return

	if round_end_modal_open:
		return

	var multiplier: float = 1.0

	if reward_manager != null:
		multiplier = reward_manager.dot_xp_multiplier

	add_combat_xp(
		maxi(roundi(amount * multiplier), 1)
	)


func _on_boss_xp_gained(
	amount: float
) -> void:
	if round_end_modal_open:
		return

	var multiplier: float = 1.0

	if reward_manager != null:
		multiplier = reward_manager.boss_xp_multiplier

	add_combat_xp(
		maxi(roundi(amount * multiplier), 1)
	)


func _on_stage_completed(
	_sector: int,
	_stage: int
) -> void:
	_update_all_ui()


func _on_currency_gained(
	amount: float
) -> void:
	if reward_modal_active:
		return

	if round_end_modal_open:
		return

	if run_state != null:
		run_cash_earned = run_state.run_cash
		earned_currency = run_state.run_cash
	else:
		run_cash_earned += amount
		earned_currency = run_cash_earned

	if currency_label != null:
		currency_label.text = (
			"$" + _format_number(earned_currency)
		)


func _on_dps_updated(
	value: float
) -> void:
	if reward_modal_active:
		return

	if round_end_modal_open:
		return

	current_dps = value
	peak_dps = maxf(
		peak_dps,
		value
	)

	if dps_value_label != null:
		dps_value_label.text = _format_number(
			current_dps
		)


func _on_wave_changed(
	value: int
) -> void:
	if reward_modal_active:
		return

	if round_end_modal_open:
		return

	current_wave = value

	highest_wave_reached = maxi(
		highest_wave_reached,
		current_wave
	)

	if wave_value_label != null:
		wave_value_label.text = str(
			current_wave
		)


func _on_boss_progress_changed(
	current_value: float,
	max_value: float,
	label_text: String
) -> void:
	if round_end_modal_open:
		return

	boss_progress_current = current_value
	boss_progress_max = maxf(
		max_value,
		1.0
	)

	boss_name = label_text

	var is_boss_fight: bool = (
		label_text.begins_with("Boss Fight")
	)

	if is_boss_fight:
		_set_boss_progress_fill_color(
			boss_progress_fill_color
		)
	else:
		_set_boss_progress_fill_color(
			normal_progress_fill_color
		)

	_update_boss_progress_ui()


func _on_combat_finished_from_arena() -> void:
	pass


func _on_run_cash_changed(value: float) -> void:
	run_cash_earned = value
	earned_currency = value

	if currency_label != null:
		currency_label.text = "$" + _format_number(value)


func _on_run_xp_changed(_value: float) -> void:
	pass


func _on_run_core_energy_changed(
	current_value: float,
	required_value: float
) -> void:
	boss_progress_current = current_value
	boss_progress_max = maxf(required_value, 1.0)
	_update_boss_progress_ui()


func _on_run_sector_stage_changed(
	sector: int,
	stage: int
) -> void:
	current_wave = stage
	highest_wave_reached = maxi(highest_wave_reached, stage)
	boss_name = "Sector %d Stage %d" % [sector, stage]

	if wave_value_label != null:
		wave_value_label.text = str(stage)

	_update_boss_progress_ui()


func _on_run_kills_changed(
	enemies: int,
	bosses: int
) -> void:
	enemies_destroyed = enemies
	bosses_destroyed = bosses


func _on_run_upgrades_changed() -> void:
	pass


func _on_farm_requested() -> void:
	if arena == null:
		return

	if arena.has_method("farm_completed_stage"):
		arena.call("farm_completed_stage")


func _on_advance_requested() -> void:
	if arena == null:
		return

	if arena.has_method("advance_to_next_stage"):
		arena.call("advance_to_next_stage")


# ===================================================================
# UI
# ===================================================================

func _update_all_ui() -> void:
	if currency_label != null:
		currency_label.text = (
			"$" + _format_number(earned_currency)
		)

	if cps_label != null:
		cps_label.text = (
			"+"
			+ _format_number(currency_per_second)
			+ " / sec"
		)

	if wave_value_label != null:
		wave_value_label.text = str(
			current_wave
		)

	if dps_value_label != null:
		dps_value_label.text = _format_number(
			current_dps
		)

	if time_label != null:
		time_label.text = _format_time(
			time_remaining
		)

	_update_boss_progress_ui()
	_update_combat_xp_ui()


func _update_boss_progress_ui() -> void:
	if boss_label != null:
		boss_label.text = boss_name

	if boss_progress_value_label != null:
		boss_progress_value_label.text = (
			"%s / %s"
			% [
				_format_integer(
					roundi(boss_progress_current)
				),
				_format_integer(
					roundi(boss_progress_max)
				)
			]
		)

	if boss_progress_bar != null:
		boss_progress_bar.min_value = 0.0
		boss_progress_bar.max_value = maxf(
			boss_progress_max,
			1.0
		)

		boss_progress_bar.value = clampf(
			boss_progress_current,
			0.0,
			boss_progress_max
		)


# ===================================================================
# ROUND END
# ===================================================================

func _on_timer_finished() -> void:
	_show_round_end_modal()


func _on_end_combat_pressed() -> void:
	_show_round_end_modal()


func _show_round_end_modal() -> void:
	if round_end_modal_open:
		return

	round_end_modal_open = true
	reward_modal_active = false
	reward_modal_is_closing = false
	queued_reward_modes.clear()

	get_tree().paused = false

	if arena != null:
		if arena.has_method("set_combat_paused"):
			arena.call(
				"set_combat_paused",
				false
			)

		if arena.has_method("end_combat"):
			arena.call("end_combat")

	_calculate_run_rewards()

	var modal: CanvasLayer = (
		RoundEndModalScene.instantiate()
		as CanvasLayer
	)

	add_child(modal)

	var time_survived: float = elapsed_run_time

	if not endless_combat_enabled:
		time_survived = clampf(
			run_duration_seconds - time_remaining,
			0.0,
			run_duration_seconds
		)

	var total_rewards_value: float = (
		run_cash_earned
		+ float(run_shards_earned)
		* shard_value_in_cash
	)

	if modal.has_method("setup_results"):
		modal.call(
			"setup_results",
			run_cash_earned,
			run_cash_bonus,
			run_shards_earned,
			run_shards_bonus,
			time_survived,
			highest_wave_reached,
			enemies_destroyed,
			peak_dps,
			total_rewards_value
		)

	if modal.has_signal("restart_requested"):
		modal.connect(
			"restart_requested",
			Callable(
				self,
				"_on_restart_run_requested"
			)
		)

	if modal.has_signal("claim_rewards_requested"):
		modal.connect(
			"claim_rewards_requested",
			Callable(
				self,
				"_on_claim_rewards_requested"
			)
		)

	if modal.has_signal("return_requested"):
		modal.connect(
			"return_requested",
			Callable(
				self,
				"_on_return_requested"
			)
		)


func _calculate_run_rewards() -> void:
	if run_state != null:
		run_cash_earned = run_state.run_cash
		earned_currency = run_state.run_cash
		enemies_destroyed = run_state.enemies_killed
		bosses_destroyed = run_state.bosses_killed
		highest_wave_reached = run_state.highest_stage_this_run

	run_cash_bonus = (
		run_cash_earned * cash_bonus_percent
	)

	var enemy_shards: int = floori(
		float(enemies_destroyed)
		* shards_per_enemy
	)

	var boss_shards: int = (
		bosses_destroyed
		* shards_per_boss_bonus
	)

	run_shards_earned = maxi(
		0,
		enemy_shards + boss_shards
	)

	if run_shards_earned <= 0:
		if run_cash_earned > 0.0:
			run_shards_earned = maxi(
				1,
				floori(
					run_cash_earned / 500.0
				)
			)

	run_shards_bonus = floori(
		float(run_shards_earned)
		* shard_bonus_percent
	)


func _on_restart_run_requested() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_claim_rewards_requested() -> void:
	_on_return_requested()


func _on_return_requested() -> void:
	get_tree().paused = false

	if ResourceLoader.exists(home_scene_path):
		get_tree().change_scene_to_file(
			home_scene_path
		)
	else:
		push_warning(
			"Home scene path not found: "
			+ home_scene_path
		)


# ===================================================================
# FORMATTING AND STYLES
# ===================================================================

func _format_number(value: float) -> String:
	var abs_value: float = absf(value)

	if abs_value >= 1000000000.0:
		return "%.2fB" % (
			value / 1000000000.0
		)

	if abs_value >= 1000000.0:
		return "%.2fM" % (
			value / 1000000.0
		)

	if abs_value >= 1000.0:
		return "%.1fk" % (
			value / 1000.0
		)

	return str(roundi(value))


func _format_integer(value: int) -> String:
	var text: String = str(value)
	var result: String = ""
	var count: int = 0

	for index: int in range(
		text.length() - 1,
		-1,
		-1
	):
		result = text[index] + result
		count += 1

		if count == 3 and index != 0:
			result = "," + result
			count = 0

	return result


func _format_time(value: float) -> String:
	var total_seconds: int = floori(value)
	var minutes: int = total_seconds / 60
	var seconds: int = total_seconds % 60

	return "%02d:%02d" % [
		minutes,
		seconds
	]


func _set_boss_progress_fill_color(
	fill_color: Color
) -> void:
	if boss_progress_bar == null:
		return

	var background_style: StyleBoxFlat = (
		StyleBoxFlat.new()
	)

	background_style.bg_color = Color("#E9EDF6")
	background_style.set_corner_radius_all(8)

	var fill_style: StyleBoxFlat = (
		StyleBoxFlat.new()
	)

	fill_style.bg_color = fill_color
	fill_style.set_corner_radius_all(8)

	boss_progress_bar.add_theme_stylebox_override(
		"background",
		background_style
	)

	boss_progress_bar.add_theme_stylebox_override(
		"fill",
		fill_style
	)


func _set_xp_progress_fill_color(
	fill_color: Color
) -> void:
	if combat_xp_progress_bar == null:
		return

	var background_style: StyleBoxFlat = (
		StyleBoxFlat.new()
	)

	background_style.bg_color = Color("#E5E7EB")
	background_style.set_corner_radius_all(5)

	var fill_style: StyleBoxFlat = (
		StyleBoxFlat.new()
	)

	fill_style.bg_color = fill_color
	fill_style.set_corner_radius_all(5)

	combat_xp_progress_bar.add_theme_stylebox_override(
		"background",
		background_style
	)

	combat_xp_progress_bar.add_theme_stylebox_override(
		"fill",
		fill_style
	)
