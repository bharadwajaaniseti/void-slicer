extends Control

signal currency_gained(amount: float)
signal dps_updated(value: float)
signal wave_changed(value: int)
signal boss_progress_changed(current_value: float, max_value: float, label_text: String)
signal combat_finished
signal enemy_destroyed
signal boss_destroyed


class DamageEvent:
	var time: float
	var damage: float

	func _init(event_time: float, event_damage: float) -> void:
		time = event_time
		damage = event_damage


@export_group("Scene References")
@export var dot_scene: PackedScene
@export var dot_layer_path: NodePath

@export var slash_fx_scene: PackedScene
@export var fx_layer_path: NodePath

@export var projectile_scene: PackedScene
@export var projectile_layer_path: NodePath

@export var beam_fx_scene: PackedScene
@export var impact_fx_scene: PackedScene
@export var black_hole_scene: PackedScene

@export var turret_scene: PackedScene
@export var turret_layer_path: NodePath

@export var boss_scene: PackedScene
@export var boss_layer_path: NodePath

@export var drone_scene: PackedScene
@export var drone_layer_path: NodePath


@export_group("Manual Weapon Slot Rails")
@export var left_slot_rail_path: NodePath
@export var right_slot_rail_path: NodePath
@export var bottom_mount_rail_path: NodePath


@export_group("Gameplay Arena Bounds")
@export var play_area_frame_path: NodePath
@export var play_area_padding: float = 18.0


@export_group("Round Setup")
@export var starting_wave: int = 1
@export var max_dots: int = 120
@export var starting_dot_count: int = 35


@export_group("Spawning")
@export var spawn_delay_min: float = 0.08
@export var spawn_delay_base: float = 0.22


@export_group("Camera Drop Spawn")
@export var use_camera_drop_spawn: bool = true
@export var camera_drop_duration: float = 0.5
@export var camera_drop_start_scale: float = 3.0
@export var camera_drop_land_scale: float = 0.92
@export var camera_drop_final_scale: float = 1.0
@export var starting_camera_drop_gap: float = 0.015

@export_group("Dot Movement")
@export var dot_start_speed_min: float = 20.0
@export var dot_start_speed_max: float = 50.0
@export var dot_max_speed: float = 70.0
@export var dot_bounce_damping: float = 0.88


@export_group("Arena Safe Area Fallback")
@export var spawn_left_margin: float = 130.0
@export var spawn_right_margin: float = 130.0
@export var spawn_top_margin: float = 45.0
@export var spawn_bottom_margin: float = 135.0

@export_group("Startup Safety")
@export var startup_wait_frames: int = 2
@export var startup_max_wait_frames: int = 120
@export var minimum_valid_play_area_size: Vector2 = Vector2(160.0, 120.0)


@export_group("Slicing")
@export var slice_damage: float = 90.0
@export var slice_width: float = 22.0


@export_group("Boss Progress")
@export var starting_progress_max: float = 2000.0
@export var progress_growth_per_round: float = 350.0


@export_group("Boss Formation")
@export var boss_form_duration: float = 0.85
@export var minimum_boss_form_dots: int = 14
@export var boss_form_spawn_radius_min: float = 130.0
@export var boss_form_spawn_radius_max: float = 250.0


@export_group("Boss Spit Dots")
@export var boss_spit_damage_step_ratio: float = 0.10
@export var boss_spit_min_dots: int = 3
@export var boss_spit_max_dots: int = 6
@export var boss_spit_speed_min: float = 130.0
@export var boss_spit_speed_max: float = 260.0


@export_group("Active Abilities")
@export var frenzy_duration: float = 6.0
@export var frenzy_turret_speed_multiplier: float = 3.0
@export var dot_rain_spawn_multiplier: float = 2.0
@export var focus_fire_duration: float = 4.0


@export_group("Drone Swarm")
@export var drone_count: int = 3
@export var drone_damage: float = 18.0
@export var drone_speed: float = 260.0
@export var drone_target_range: float = 300.0
@export var drone_hit_radius: float = 22.0
@export var drone_hit_interval: float = 0.25
@export var drones_can_attack_boss_when_no_dots: bool = false


@export_group("Reward Tier Scaling")
@export var tier_damage_bonus_per_level: float = 0.25
@export var tier_attack_speed_bonus_per_level: float = 0.10
@export var tier_range_bonus_per_level: float = 0.08


var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var dot_layer: Node2D
var fx_layer: Node2D
var projectile_layer: Node2D
var turret_layer: Node2D
var boss_layer: Node2D
var drone_layer: Node2D

var left_slot_rail: Control
var right_slot_rail: Control
var bottom_mount_rail: Control

var dots: Array[DotEnemy] = []
var turrets: Array[CombatTurret] = []
var projectiles: Array[CombatProjectile] = []
var black_holes: Array[CombatBlackHole] = []
var drones: Array[Node2D] = []
var damage_events: Array[DamageEvent] = []

var current_boss: CombatBoss = null

var boss_dots_max: int = 45
var boss_next_spit_hp: float = 0.0

var spawn_timer: float = 0.0
var wave_timer: float = 0.0
var dps_emit_timer: float = 0.0

var wave: int = 0
var round_number: int = 1
var boss_level: int = 1

var progress_current: float = 0.0
var progress_max: float = 2000.0

var is_boss_phase: bool = false
var is_forming_boss: bool = false
var combat_is_over: bool = false

var boss_form_center: Vector2 = Vector2.ZERO

var frenzy_timer: float = 0.0
var focus_fire_timer: float = 0.0
var drone_swarm_enabled: bool = true

var is_slicing: bool = false
var last_mouse_position: Vector2 = Vector2.ZERO

var background_color: Color = Color("#FFFFFF")
var purple_color: Color = Color("#7437FF")
var blue_color: Color = Color("#0077FF")
var orange_color: Color = Color("#FF9700")
var soft_border_color: Color = Color("#E5E6EF")
var arena_grid_color: Color = Color("#E9EAF4")

var weapon_slots: Dictionary = {}
var equipped_weapons: Dictionary = {}

var arena_initialized: bool = false
var arena_initializing: bool = false
var turret_rebuild_queued: bool = false
var starting_spawn_generation: int = 0


# Reward-system runtime modifiers.
var combat_paused: bool = false

var global_damage_multiplier: float = 1.0
var boss_damage_multiplier: float = 1.0
var global_attack_speed_multiplier: float = 1.0
var critical_chance: float = 0.0
var critical_damage_multiplier: float = 1.5

var weapon_damage_multipliers: Dictionary = {}
var weapon_attack_speed_multipliers: Dictionary = {}
var weapon_range_multipliers: Dictionary = {}
var weapon_tiers: Dictionary = {}

var unlocked_combat_weapons: Array[String] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	rng.randomize()

	wave = starting_wave
	progress_max = starting_progress_max
	progress_current = 0.0

	# Prevent gameplay logic from running while Containers and anchors are
	# still calculating the arena's final size.
	set_process(false)
	call_deferred("_late_initialize_arena")


func _late_initialize_arena() -> void:
	if arena_initialized or arena_initializing:
		return

	arena_initializing = true

	# Give the scene tree and UI Containers time to finish their first layout.
	var initial_frames: int = maxi(1, startup_wait_frames)
	for i in range(initial_frames):
		await get_tree().process_frame

	_setup_layers()
	_setup_manual_weapon_slots()

	# On a cold Run Project launch, the frame can temporarily report 0x0.
	# Wait with a hard limit instead of starting gameplay in an invalid rect.
	var waited_frames: int = 0
	var max_frames: int = maxi(1, startup_max_wait_frames)

	while not _is_play_area_ready() and waited_frames < max_frames:
		waited_frames += 1
		await get_tree().process_frame

	if not _is_play_area_ready():
		arena_initializing = false
		push_error(
			"CombatArena: play area never became valid. Arena size: %s, play rect: %s"
			% [size, _get_play_area_rect()]
		)
		return

	if dot_scene == null:
		push_error("CombatArena: dot_scene is missing. Assign Dot.tscn in the inspector.")
		return

	if projectile_scene == null:
		push_error("CombatArena: projectile_scene is missing. Assign Projectile.tscn in the inspector.")
		return

	if turret_scene == null:
		push_error("CombatArena: turret_scene is missing. Assign Turret.tscn in the inspector.")
		return

	if boss_scene == null:
		push_error("CombatArena: boss_scene is missing. Assign Boss.tscn in the inspector.")
		return

	if slash_fx_scene == null:
		push_warning("CombatArena: slash_fx_scene is missing. Slicing still damages enemies, but no mouse slash trail will appear.")

	if beam_fx_scene == null:
		push_warning("CombatArena: beam_fx_scene is missing. Tesla and laser still deal damage, but no beam visual will appear.")

	if impact_fx_scene == null:
		push_warning("CombatArena: impact_fx_scene is missing. Damage still works, but no hit impact pop will appear.")

	if black_hole_scene == null:
		push_warning("CombatArena: black_hole_scene is missing. Black Hole ability will not work yet.")

	if drone_scene == null:
		push_warning("CombatArena: drone_scene is missing. Drone Swarm ability will not spawn drones yet.")

	if dot_layer == null:
		push_error("CombatArena: DotLayer is missing.")
		return

	if fx_layer == null:
		push_error("CombatArena: FxLayer is missing.")
		return

	if projectile_layer == null:
		push_error("CombatArena: ProjectileLayer is missing.")
		return

	if turret_layer == null:
		push_error("CombatArena: TurretLayer is missing.")
		return

	if boss_layer == null:
		push_error("CombatArena: BossLayer is missing.")
		return

	if drone_layer == null:
		push_error("CombatArena: DroneLayer is missing.")
		return

	arena_initialized = true
	arena_initializing = false

	_rebuild_turrets()
	_start_normal_round()
	_refresh_drone_swarm()

	set_process(true)
	queue_redraw()


func _setup_layers() -> void:
	dot_layer = null
	fx_layer = null
	projectile_layer = null
	turret_layer = null
	boss_layer = null
	drone_layer = null

	if dot_layer_path != NodePath():
		dot_layer = get_node_or_null(dot_layer_path) as Node2D

	if fx_layer_path != NodePath():
		fx_layer = get_node_or_null(fx_layer_path) as Node2D

	if projectile_layer_path != NodePath():
		projectile_layer = get_node_or_null(projectile_layer_path) as Node2D

	if turret_layer_path != NodePath():
		turret_layer = get_node_or_null(turret_layer_path) as Node2D

	if boss_layer_path != NodePath():
		boss_layer = get_node_or_null(boss_layer_path) as Node2D

	if drone_layer_path != NodePath():
		drone_layer = get_node_or_null(drone_layer_path) as Node2D

	if dot_layer == null:
		dot_layer = get_node_or_null("DotLayer") as Node2D

	if fx_layer == null:
		fx_layer = get_node_or_null("FxLayer") as Node2D

	if projectile_layer == null:
		projectile_layer = get_node_or_null("ProjectileLayer") as Node2D

	if turret_layer == null:
		turret_layer = get_node_or_null("TurretLayer") as Node2D

	if boss_layer == null:
		boss_layer = get_node_or_null("BossLayer") as Node2D

	if drone_layer == null:
		drone_layer = get_node_or_null("DroneLayer") as Node2D

	if dot_layer == null:
		dot_layer = Node2D.new()
		dot_layer.name = "DotLayer"
		add_child(dot_layer)

	if fx_layer == null:
		fx_layer = Node2D.new()
		fx_layer.name = "FxLayer"
		add_child(fx_layer)

	if projectile_layer == null:
		projectile_layer = Node2D.new()
		projectile_layer.name = "ProjectileLayer"
		add_child(projectile_layer)

	if turret_layer == null:
		turret_layer = Node2D.new()
		turret_layer.name = "TurretLayer"
		add_child(turret_layer)

	if boss_layer == null:
		boss_layer = Node2D.new()
		boss_layer.name = "BossLayer"
		add_child(boss_layer)

	if drone_layer == null:
		drone_layer = Node2D.new()
		drone_layer.name = "DroneLayer"
		add_child(drone_layer)


func _setup_manual_weapon_slots() -> void:
	weapon_slots.clear()

	left_slot_rail = null
	right_slot_rail = null
	bottom_mount_rail = null

	if left_slot_rail_path != NodePath():
		left_slot_rail = get_node_or_null(left_slot_rail_path) as Control

	if right_slot_rail_path != NodePath():
		right_slot_rail = get_node_or_null(right_slot_rail_path) as Control

	if bottom_mount_rail_path != NodePath():
		bottom_mount_rail = get_node_or_null(bottom_mount_rail_path) as Control

	if left_slot_rail == null:
		left_slot_rail = get_node_or_null("LeftSlotRail") as Control

	if right_slot_rail == null:
		right_slot_rail = get_node_or_null("RightSlotRail") as Control

	if bottom_mount_rail == null:
		bottom_mount_rail = get_node_or_null("BottomMountRail") as Control

	_register_slot_buttons_from_rail(left_slot_rail, "left")
	_register_slot_buttons_from_rail(right_slot_rail, "right")
	_register_slot_buttons_from_rail(bottom_mount_rail, "bottom")

	_refresh_slot_visuals()


func _register_slot_buttons_from_rail(rail: Control, prefix: String) -> void:
	if rail == null:
		return

	var index: int = 1

	for child in rail.get_children():
		if child is Button:
			var button: Button = child as Button
			var slot_id: String = prefix + "_" + str(index)

			button.set_meta("slot_id", slot_id)
			button.focus_mode = Control.FOCUS_NONE
			button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			button.text = ""
			button.clip_text = true

			weapon_slots[slot_id] = button

			var pressed_callable: Callable = Callable(self, "_on_weapon_slot_button_pressed").bind(slot_id)

			if not button.pressed.is_connected(pressed_callable):
				button.pressed.connect(pressed_callable)

			index += 1


func _on_weapon_slot_button_pressed(slot_id: String) -> void:
	if combat_paused:
		return

	if combat_is_over:
		return

	if equipped_weapons.has(slot_id):
		unequip_weapon_from_slot(slot_id)
	else:
		var weapon_kind: String = _get_default_weapon_for_slot(slot_id)
		equip_weapon_to_slot(slot_id, weapon_kind)


func _get_default_weapon_for_slot(slot_id: String) -> String:
	if slot_id.begins_with("left_"):
		return "tesla"

	if slot_id.begins_with("right_"):
		return "laser"

	if slot_id == "bottom_2":
		return "motor"

	if slot_id.begins_with("bottom_"):
		return "turret"

	return "turret"


func equip_weapon_to_slot(slot_id: String, weapon_kind: String) -> void:
	if not weapon_slots.has(slot_id):
		push_warning("CombatArena: Cannot equip weapon. Missing slot: " + slot_id)
		return

	equipped_weapons[slot_id] = weapon_kind
	_refresh_slot_visuals()
	_rebuild_turrets()


func unequip_weapon_from_slot(slot_id: String) -> void:
	if equipped_weapons.has(slot_id):
		equipped_weapons.erase(slot_id)

	_refresh_slot_visuals()
	_rebuild_turrets()


func _refresh_slot_visuals() -> void:
	for slot_id in weapon_slots.keys():
		var button: Button = weapon_slots[slot_id] as Button

		if button == null:
			continue

		var weapon_kind: String = equipped_weapons.get(slot_id, "")
		_apply_slot_button_style(button, weapon_kind != "")

		button.text = ""


func _get_weapon_display_name(weapon_kind: String) -> String:
	match weapon_kind:
		"turret":
			return "TURRET"
		"motor":
			return "MOTOR"
		"tesla":
			return "TESLA"
		"laser":
			return "LASER"
		"cannon":
			return "CANNON"
		"rocket":
			return "ROCKET"
		_:
			return weapon_kind.to_upper()


func _apply_slot_button_style(button: Button, is_equipped: bool) -> void:
	button.custom_minimum_size = Vector2(86.0, 96.0)
	button.focus_mode = Control.FOCUS_NONE
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#FFFFFF")
	normal.border_color = Color("#E1E4EE")
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(10)
	normal.shadow_color = Color("#B9BED030")
	normal.shadow_size = 8
	normal.shadow_offset = Vector2(0.0, 3.0)
	normal.content_margin_left = 6.0
	normal.content_margin_right = 6.0
	normal.content_margin_top = 8.0
	normal.content_margin_bottom = 8.0

	var hover := normal.duplicate()
	hover.border_color = purple_color
	hover.shadow_color = Color(purple_color.r, purple_color.g, purple_color.b, 0.25)
	hover.shadow_size = 14

	var pressed_style := normal.duplicate()
	pressed_style.bg_color = Color("#F4F0FF")
	pressed_style.border_color = purple_color

	var equipped_style := normal.duplicate()
	equipped_style.bg_color = Color("#F7F3FF")
	equipped_style.border_color = purple_color
	equipped_style.shadow_color = Color(purple_color.r, purple_color.g, purple_color.b, 0.22)
	equipped_style.shadow_size = 12

	if is_equipped:
		button.add_theme_stylebox_override("normal", equipped_style)
	else:
		button.add_theme_stylebox_override("normal", normal)

	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed_style)

	button.add_theme_color_override("font_color", Color("#11131A"))
	button.add_theme_color_override("font_hover_color", purple_color)
	button.add_theme_color_override("font_pressed_color", purple_color)
	button.add_theme_font_size_override("font_size", 10)


func _notification(what: int) -> void:
	if what != NOTIFICATION_RESIZED:
		return

	queue_redraw()

	if not arena_initialized:
		return

	if turret_rebuild_queued:
		return

	turret_rebuild_queued = true
	call_deferred("_deferred_rebuild_turrets")


func _deferred_rebuild_turrets() -> void:
	turret_rebuild_queued = false

	if not arena_initialized:
		return

	if not _is_play_area_ready():
		return

	_rebuild_turrets()


func _process(delta: float) -> void:
	if combat_paused:
		return

	if combat_is_over:
		return

	if not arena_initialized:
		return

	if not _is_play_area_ready():
		return

	_update_ability_timers(delta)

	if is_forming_boss:
		_update_drones(delta)
		_update_dps(delta)
		queue_redraw()
		return

	_update_wave(delta)
	_update_spawning(delta)
	_update_boss(delta)
	_update_boss_dot_spawning(delta)
	_update_dots(delta)
	_update_black_holes(delta)
	_update_drones(delta)
	_update_turrets(delta)
	_update_projectiles(delta)
	_update_dps(delta)

	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if combat_paused:
		return

	if combat_is_over:
		return

	if is_forming_boss:
		return

	if event is InputEventMouseButton:
		var mouse_button: InputEventMouseButton = event as InputEventMouseButton

		if mouse_button.button_index == MOUSE_BUTTON_LEFT:
			is_slicing = mouse_button.pressed
			last_mouse_position = mouse_button.position

	if event is InputEventMouseMotion:
		var motion: InputEventMouseMotion = event as InputEventMouseMotion

		if is_slicing:
			var current_position: Vector2 = motion.position
			_slice_between(last_mouse_position, current_position)
			_spawn_slash_fx(last_mouse_position, current_position)
			last_mouse_position = current_position


func _draw() -> void:
	_draw_background()


func _draw_background() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), background_color)

	var frame_rect: Rect2 = _get_play_area_rect()

	if frame_rect.size.x <= 0.0 or frame_rect.size.y <= 0.0:
		return

	draw_rect(frame_rect, Color("#FFFFFF"), true)
	draw_rect(frame_rect, soft_border_color, false, 2.0)

	var grid_spacing: float = 80.0
	var grid_alpha: float = 0.12

	var x: float = frame_rect.position.x
	while x <= frame_rect.end.x:
		draw_line(
			Vector2(x, frame_rect.position.y),
			Vector2(x, frame_rect.end.y),
			Color(arena_grid_color.r, arena_grid_color.g, arena_grid_color.b, grid_alpha),
			1.0
		)
		x += grid_spacing

	var y: float = frame_rect.position.y
	while y <= frame_rect.end.y:
		draw_line(
			Vector2(frame_rect.position.x, y),
			Vector2(frame_rect.end.x, y),
			Color(arena_grid_color.r, arena_grid_color.g, arena_grid_color.b, grid_alpha),
			1.0
		)
		y += grid_spacing


func _is_play_area_ready() -> bool:
	if size.x < minimum_valid_play_area_size.x:
		return false

	if size.y < minimum_valid_play_area_size.y:
		return false

	var frame: Control = null

	if play_area_frame_path != NodePath():
		frame = get_node_or_null(play_area_frame_path) as Control

	if frame == null:
		frame = get_node_or_null("ArenaFrame") as Control

	if frame != null:
		var frame_size: Vector2 = frame.get_global_rect().size
		var required_width: float = minimum_valid_play_area_size.x + play_area_padding * 2.0
		var required_height: float = minimum_valid_play_area_size.y + play_area_padding * 2.0

		return frame_size.x >= required_width and frame_size.y >= required_height

	var fallback_width: float = size.x - spawn_left_margin - spawn_right_margin
	var fallback_height: float = size.y - spawn_top_margin - spawn_bottom_margin

	return (
		fallback_width >= minimum_valid_play_area_size.x
		and fallback_height >= minimum_valid_play_area_size.y
	)

func _wait_until_play_area_ready(max_frames: int = 90) -> bool:
	var waited_frames: int = 0

	while not _is_play_area_ready() and waited_frames < max_frames:
		if combat_is_over:
			return false

		waited_frames += 1
		await get_tree().process_frame

	return _is_play_area_ready()

func _get_play_area_rect() -> Rect2:
	var frame: Control = null

	if play_area_frame_path != NodePath():
		frame = get_node_or_null(play_area_frame_path) as Control

	if frame == null:
		frame = get_node_or_null("ArenaFrame") as Control

	if frame != null:
		var frame_global_rect: Rect2 = frame.get_global_rect()
		var arena_global_position: Vector2 = get_global_rect().position

		var local_position: Vector2 = frame_global_rect.position - arena_global_position
		var local_size: Vector2 = frame_global_rect.size

		var rect := Rect2(local_position, local_size)
		rect.position += Vector2(play_area_padding, play_area_padding)
		rect.size -= Vector2(play_area_padding * 2.0, play_area_padding * 2.0)

		if rect.size.x < 32.0:
			rect.size.x = 32.0

		if rect.size.y < 32.0:
			rect.size.y = 32.0

		return rect

	var left: float = spawn_left_margin
	var top: float = spawn_top_margin
	var right: float = maxf(left + 32.0, size.x - spawn_right_margin)
	var bottom: float = maxf(top + 32.0, size.y - spawn_bottom_margin)

	return Rect2(Vector2(left, top), Vector2(right - left, bottom - top))


func _update_ability_timers(delta: float) -> void:
	if frenzy_timer > 0.0:
		frenzy_timer = maxf(0.0, frenzy_timer - delta)

	if focus_fire_timer > 0.0:
		focus_fire_timer = maxf(0.0, focus_fire_timer - delta)


func activate_ability(ability_id: String) -> bool:
	if combat_paused:
		return false

	if combat_is_over:
		return false

	if is_forming_boss:
		return false

	match ability_id:
		"frenzy":
			return _activate_frenzy()

		"dot_rain":
			return _activate_dot_rain()

		"black_hole":
			return _activate_black_hole()

		"focus_fire":
			return _activate_focus_fire()

		"drone_swarm":
			return _toggle_drone_swarm()

		_:
			push_warning("CombatArena: Unknown ability id: " + ability_id)
			return false


func is_drone_swarm_enabled() -> bool:
	return drone_swarm_enabled


func _activate_frenzy() -> bool:
	frenzy_timer = frenzy_duration
	_spawn_impact_fx(_get_play_area_rect().get_center(), orange_color)
	return true


func _activate_dot_rain() -> bool:
	if dot_scene == null:
		return false

	if dot_layer == null:
		return false

	if dots.size() >= max_dots:
		return false

	var amount: int = int(round(float(starting_dot_count) * dot_rain_spawn_multiplier))

	for i in range(amount):
		if dots.size() >= max_dots:
			break

		_spawn_dot()

	_spawn_impact_fx(_get_play_area_rect().get_center(), purple_color)
	return true


func _activate_black_hole() -> bool:
	if black_hole_scene == null:
		return false

	if fx_layer == null:
		return false

	if is_forming_boss:
		return false

	var spawn_position: Vector2 = _get_play_area_rect().get_center()

	var black_hole: CombatBlackHole = black_hole_scene.instantiate() as CombatBlackHole

	if black_hole == null:
		push_error("CombatArena: black_hole_scene must use CombatBlackHole script.")
		return false

	fx_layer.add_child(black_hole)
	black_hole.play(spawn_position)

	if not black_hole.expired.is_connected(_on_black_hole_expired):
		black_hole.expired.connect(_on_black_hole_expired)

	black_holes.append(black_hole)

	_spawn_impact_fx(spawn_position, purple_color)

	return true


func _activate_focus_fire() -> bool:
	if not is_boss_phase:
		return false

	if current_boss == null:
		return false

	if not is_instance_valid(current_boss):
		return false

	if current_boss.is_dying:
		return false

	focus_fire_timer = focus_fire_duration
	_spawn_impact_fx(current_boss.position, purple_color)
	return true


func _toggle_drone_swarm() -> bool:
	drone_swarm_enabled = not drone_swarm_enabled
	_refresh_drone_swarm()

	if drone_swarm_enabled:
		print("Drone Swarm AUTO ON")
	else:
		print("Drone Swarm AUTO OFF")

	return true


func _refresh_drone_swarm() -> void:
	if drone_swarm_enabled:
		_spawn_drone_swarm()
	else:
		_clear_drones()


func _spawn_drone_swarm() -> void:
	if drone_scene == null:
		return

	if drone_layer == null:
		return

	if drones.size() >= drone_count:
		return

	var center: Vector2 = _get_play_area_rect().get_center()
	var spawn_radius: float = 90.0

	for i in range(drones.size(), drone_count):
		var angle: float = TAU * float(i) / float(maxi(1, drone_count))
		var spawn_position: Vector2 = center + Vector2.RIGHT.rotated(angle) * spawn_radius
		spawn_position = _clamp_to_arena_safe_area(spawn_position)

		var drone_instance: Node = drone_scene.instantiate()
		var drone_node: Node2D = drone_instance as Node2D

		if drone_node == null:
			push_error("CombatArena: drone_scene root must extend Node2D.")
			return

		drone_layer.add_child(drone_node)

		drone_node.set("damage", drone_damage)
		drone_node.set("move_speed", drone_speed)
		drone_node.set("target_range", drone_target_range)
		drone_node.set("hit_radius", drone_hit_radius)
		drone_node.set("hit_interval", drone_hit_interval)

		if drone_node.has_method("setup_drone"):
			drone_node.call("setup_drone", spawn_position, i)
		else:
			drone_node.position = spawn_position

		drones.append(drone_node)


func _update_drones(delta: float) -> void:
	if not drone_swarm_enabled:
		return

	if drone_scene == null:
		return

	if drones.size() < drone_count:
		_spawn_drone_swarm()

	for i in range(drones.size() - 1, -1, -1):
		var drone_node: Node2D = drones[i]

		if drone_node == null or not is_instance_valid(drone_node):
			drones.remove_at(i)
			continue

		var target_range: float = float(drone_node.get("target_range"))
		var target_dot: DotEnemy = _find_nearest_dot_for_drone(drone_node.position, target_range)

		if target_dot != null:
			if drone_node.has_method("update_drone"):
				drone_node.call("update_drone", delta, size, target_dot.position, true)

			var can_hit_dot: bool = false

			if drone_node.has_method("can_hit_target"):
				can_hit_dot = bool(drone_node.call("can_hit_target", target_dot.position))

			if can_hit_dot:
				var drone_damage_value: float = _calculate_reward_damage(
					float(drone_node.get("damage")),
					"drone",
					false
				)
				var drone_velocity: Vector2 = Vector2.ZERO

				var velocity_value: Variant = drone_node.get("velocity")
				if velocity_value is Vector2:
					drone_velocity = velocity_value

				_spawn_impact_fx(target_dot.position, purple_color)
				_damage_dot(target_dot, drone_damage_value, drone_velocity.angle())

				if drone_node.has_method("mark_hit"):
					drone_node.call("mark_hit")

			continue

		if drones_can_attack_boss_when_no_dots:
			if is_boss_phase and current_boss != null and is_instance_valid(current_boss):
				if not current_boss.is_dying:
					if drone_node.has_method("update_drone"):
						drone_node.call("update_drone", delta, size, current_boss.position, true)

					var can_hit_boss: bool = false

					if drone_node.has_method("can_hit_target"):
						can_hit_boss = bool(drone_node.call("can_hit_target", current_boss.position))

					if can_hit_boss:
						var boss_damage_value: float = _calculate_reward_damage(
							float(drone_node.get("damage")),
							"drone",
							true
						)

						_spawn_impact_fx(current_boss.position, purple_color)
						_damage_boss(boss_damage_value)

						if drone_node.has_method("mark_hit"):
							drone_node.call("mark_hit")

					continue

		if drone_node.has_method("update_drone"):
			drone_node.call("update_drone", delta, size, Vector2.ZERO, false)


func _find_nearest_dot_for_drone(origin: Vector2, max_range: float) -> DotEnemy:
	var nearest_dot: DotEnemy = null
	var nearest_distance: float = max_range

	for dot in dots:
		if dot == null:
			continue

		if not is_instance_valid(dot):
			continue

		if dot.is_dying:
			continue

		if dot.is_merging:
			continue

		var distance: float = origin.distance_to(dot.position)

		if distance < nearest_distance:
			nearest_distance = distance
			nearest_dot = dot

	return nearest_dot


func _clear_drones() -> void:
	for drone_node in drones:
		if drone_node != null and is_instance_valid(drone_node):
			drone_node.queue_free()

	drones.clear()

	if drone_layer != null:
		for child in drone_layer.get_children():
			child.queue_free()


func _start_normal_round() -> void:
	starting_spawn_generation += 1

	is_boss_phase = false
	is_forming_boss = false

	_clear_boss()
	_clear_dots()
	_clear_fx_layer()
	_clear_projectiles()
	_clear_black_holes()

	progress_current = 0.0
	progress_max = starting_progress_max + float(round_number - 1) * progress_growth_per_round

	_spawn_starting_dots()
	_refresh_drone_swarm()
	_emit_progress_normal()


func _spawn_starting_dots() -> void:
	var my_generation: int = starting_spawn_generation

	for i in range(starting_dot_count):
		if my_generation != starting_spawn_generation:
			return

		if starting_camera_drop_gap > 0.0:
			await get_tree().create_timer(starting_camera_drop_gap, false).timeout
		else:
			await get_tree().process_frame

		if my_generation != starting_spawn_generation:
			return

		if combat_is_over:
			return

		if not arena_initialized:
			return

		if not _is_play_area_ready():
			var became_ready: bool = await _wait_until_play_area_ready(90)

			if not became_ready:
				push_warning("CombatArena: Starting dots paused because play area became invalid.")
				return

		if is_boss_phase:
			return

		if is_forming_boss:
			return

		_spawn_dot()


func _start_boss_formation() -> void:
	if is_forming_boss:
		return

	if is_boss_phase:
		return

	is_forming_boss = true
	is_slicing = false
	boss_form_center = _get_play_area_rect().get_center()

	_clear_projectiles()
	_clear_black_holes()
	_clear_fx_layer()
	_ensure_boss_form_dots()

	for dot in dots:
		if dot == null:
			continue

		if not is_instance_valid(dot):
			continue

		if dot.is_dying:
			continue

		dot.play_merge_to(boss_form_center, boss_form_duration)

	_spawn_impact_fx(boss_form_center, purple_color)
	_finish_boss_formation_after_delay()


func _ensure_boss_form_dots() -> void:
	var missing_count: int = minimum_boss_form_dots - dots.size()

	if missing_count <= 0:
		return

	for i in range(missing_count):
		var angle: float = TAU * float(i) / float(maxi(1, missing_count))
		angle += rng.randf_range(-0.25, 0.25)

		var spawn_radius: float = rng.randf_range(
			boss_form_spawn_radius_min,
			boss_form_spawn_radius_max
		)

		var spawn_position: Vector2 = boss_form_center + Vector2.RIGHT.rotated(angle) * spawn_radius
		spawn_position = _clamp_to_arena_safe_area(spawn_position)

		var dot: DotEnemy = _spawn_dot_at_position(spawn_position)

		if dot != null:
			dot.set_meta("camera_dropping", false)
			_apply_random_dot_velocity(dot)


func _finish_boss_formation_after_delay() -> void:
	await get_tree().create_timer(boss_form_duration + 0.08, false).timeout

	if combat_is_over:
		return

	if not is_forming_boss:
		return

	_finish_boss_formation()


func _finish_boss_formation() -> void:
	_clear_dots()

	is_forming_boss = false
	is_boss_phase = true

	_spawn_impact_fx(boss_form_center, purple_color)
	_spawn_boss_from_center(boss_form_center)
	_emit_progress_boss()


func _spawn_boss_from_center(center_position: Vector2) -> void:
	if boss_scene == null:
		return

	if boss_layer == null:
		return

	_clear_boss()

	var boss: CombatBoss = boss_scene.instantiate() as CombatBoss

	if boss == null:
		push_error("CombatArena: boss_scene must use CombatBoss script.")
		return

	boss_layer.add_child(boss)
	boss.setup_boss(center_position, center_position, boss_level, true)
	boss.died.connect(_on_boss_died)
	boss.hp_changed.connect(_on_boss_hp_changed)

	current_boss = boss
	boss_next_spit_hp = current_boss.max_hp * (1.0 - boss_spit_damage_step_ratio)


func _on_boss_died(boss: CombatBoss) -> void:
	if boss == null:
		return

	if current_boss != boss:
		return

	var boss_reward_value: float = boss.reward

	currency_gained.emit(boss_reward_value)

	current_boss = null
	is_boss_phase = false
	is_forming_boss = false

	round_number += 1
	boss_level += 1
	wave += 1

	wave_changed.emit(wave)

	# Dedicated boss-death signal.
	# Do not emit enemy_destroyed here.
	boss_destroyed.emit()

	_start_normal_round()


func _on_boss_hp_changed(current_hp: float, max_hp: float) -> void:
	boss_progress_changed.emit(current_hp, max_hp, "Boss Fight " + str(boss_level))


func _update_wave(delta: float) -> void:
	if is_boss_phase:
		return

	wave_timer += delta

	if wave_timer >= 20.0:
		wave_timer = 0.0
		wave += 1
		wave_changed.emit(wave)


func _update_spawning(delta: float) -> void:
	if is_boss_phase:
		return

	if is_forming_boss:
		return

	if not arena_initialized:
		return

	if not _is_play_area_ready():
		return

	spawn_timer -= delta

	if spawn_timer <= 0.0:
		_spawn_dot()

		var wave_bonus: float = maxf(0.0, float(wave - starting_wave) * 0.006)
		spawn_timer = maxf(spawn_delay_min, spawn_delay_base - wave_bonus)


func _update_boss(delta: float) -> void:
	if current_boss == null:
		return

	if not is_instance_valid(current_boss):
		current_boss = null
		return

	current_boss.update_boss(delta, size, rng)


func _update_boss_dot_spawning(_delta: float) -> void:
	if not is_boss_phase:
		return

	if current_boss == null:
		return

	if not is_instance_valid(current_boss):
		return

	pass


func _update_dots(delta: float) -> void:
	for i in range(dots.size() - 1, -1, -1):
		var dot: DotEnemy = dots[i]

		if dot == null or not is_instance_valid(dot):
			dots.remove_at(i)
			continue

		if dot.has_meta("camera_dropping") and bool(dot.get_meta("camera_dropping")):
			_bounce_dot_inside_play_area(dot)
			continue

		dot.update_motion(delta, size)
		_bounce_dot_inside_play_area(dot)


func _bounce_dot_inside_play_area(dot: DotEnemy) -> void:
	if dot == null:
		return

	if not is_instance_valid(dot):
		return

	var play_rect: Rect2 = _get_play_area_rect()
	var radius: float = dot.radius * maxf(dot.scale.x, dot.scale.y)

	var min_x: float = play_rect.position.x + radius
	var max_x: float = play_rect.end.x - radius
	var min_y: float = play_rect.position.y + radius
	var max_y: float = play_rect.end.y - radius

	if dot.position.x < min_x:
		dot.position.x = min_x
		dot.velocity.x = absf(dot.velocity.x) * dot_bounce_damping

	elif dot.position.x > max_x:
		dot.position.x = max_x
		dot.velocity.x = -absf(dot.velocity.x) * dot_bounce_damping

	if dot.position.y < min_y:
		dot.position.y = min_y
		dot.velocity.y = absf(dot.velocity.y) * dot_bounce_damping

	elif dot.position.y > max_y:
		dot.position.y = max_y
		dot.velocity.y = -absf(dot.velocity.y) * dot_bounce_damping

	if dot.velocity.length() > dot_max_speed:
		dot.velocity = dot.velocity.normalized() * dot_max_speed


func _update_black_holes(delta: float) -> void:
	if black_holes.is_empty():
		return

	var dots_to_devour: Array[DotEnemy] = []

	for i in range(black_holes.size() - 1, -1, -1):
		var black_hole: CombatBlackHole = black_holes[i]

		if black_hole == null or not is_instance_valid(black_hole):
			black_holes.remove_at(i)
			continue

		if not black_hole.is_active:
			continue

		_apply_black_hole_pull(black_hole, delta, dots_to_devour)

	for dot in dots_to_devour:
		if dot == null:
			continue

		if not is_instance_valid(dot):
			continue

		if not dots.has(dot):
			continue

		var nearest_black_hole: CombatBlackHole = _find_nearest_black_hole(dot.position)

		if nearest_black_hole == null:
			continue

		_devour_dot(dot, nearest_black_hole)


func _apply_black_hole_pull(
	black_hole: CombatBlackHole,
	delta: float,
	dots_to_devour: Array[DotEnemy]
) -> void:
	for dot in dots:
		if dot == null:
			continue

		if not is_instance_valid(dot):
			continue

		if dot.is_dying:
			continue

		if dot.is_merging:
			continue

		var to_black_hole: Vector2 = black_hole.position - dot.position
		var distance: float = to_black_hole.length()

		if distance > black_hole.pull_radius:
			continue

		if distance <= black_hole.devour_radius:
			if not dots_to_devour.has(dot):
				dots_to_devour.append(dot)
			continue

		var direction: Vector2 = to_black_hole.normalized()
		var strength_ratio: float = 1.0 - clampf(distance / black_hole.pull_radius, 0.0, 1.0)
		var pull_amount: float = black_hole.pull_strength * maxf(0.18, strength_ratio) * delta

		dot.position += direction * pull_amount
		dot.velocity = dot.velocity.lerp(direction * 140.0, clampf(delta * 4.0, 0.0, 1.0))
		_bounce_dot_inside_play_area(dot)


func _devour_dot(dot: DotEnemy, black_hole: CombatBlackHole) -> void:
	if dot == null:
		return

	if not is_instance_valid(dot):
		return

	if not dots.has(dot):
		return

	dots.erase(dot)

	var cash_reward: float = dot.reward * black_hole.reward_multiplier
	var progress_reward: float = dot.progress_reward * black_hole.progress_multiplier

	currency_gained.emit(cash_reward)

	if not is_boss_phase and not is_forming_boss:
		_add_progress(progress_reward)

	enemy_destroyed.emit()

	_spawn_impact_fx(dot.position, purple_color)

	dot.queue_free()


func _find_nearest_black_hole(point: Vector2) -> CombatBlackHole:
	var nearest: CombatBlackHole = null
	var nearest_distance: float = INF

	for black_hole in black_holes:
		if black_hole == null:
			continue

		if not is_instance_valid(black_hole):
			continue

		var distance: float = point.distance_to(black_hole.position)

		if distance < nearest_distance:
			nearest_distance = distance
			nearest = black_hole

	return nearest


func _on_black_hole_expired(black_hole: CombatBlackHole) -> void:
	if black_hole == null:
		return

	if black_holes.has(black_hole):
		black_holes.erase(black_hole)


func _update_turrets(delta: float) -> void:
	for turret in turrets:
		if turret == null or not is_instance_valid(turret):
			continue

		var weapon_id: String = _normalize_weapon_id(turret.kind)
		var attack_speed_multiplier: float = _get_weapon_attack_speed_multiplier(
			weapon_id
		)

		var cooldown_delta: float = delta * global_attack_speed_multiplier
		cooldown_delta *= attack_speed_multiplier

		if frenzy_timer > 0.0:
			cooldown_delta *= frenzy_turret_speed_multiplier

		turret.update_cooldown(cooldown_delta)

		if not turret.can_fire():
			continue

		if focus_fire_timer > 0.0:
			if is_boss_phase and current_boss != null and is_instance_valid(current_boss):
				if not current_boss.is_dying:
					_fire_turret_at_boss(turret)
					turret.mark_fired()
					continue

		var effective_range: float = turret.range * _get_weapon_range_multiplier(
			weapon_id
		)

		var target_dot: DotEnemy = _find_nearest_dot(
			turret.position,
			effective_range
		)

		if target_dot != null:
			_fire_turret_at_dot(turret, target_dot)
			turret.mark_fired()
			continue

		if is_boss_phase and current_boss != null and is_instance_valid(current_boss):
			if not current_boss.is_dying:
				_fire_turret_at_boss(turret)
				turret.mark_fired()


func _update_projectiles(delta: float) -> void:
	for i in range(projectiles.size() - 1, -1, -1):
		var projectile: CombatProjectile = projectiles[i]

		if projectile == null or not is_instance_valid(projectile):
			projectiles.remove_at(i)
			continue

		projectile.update_projectile(delta)

		var should_remove: bool = false
		var damage_target_is_boss: bool = false
		var boss_damage_amount: float = 0.0
		var dot_target: DotEnemy = null
		var dot_damage_amount: float = 0.0

		dot_target = _find_projectile_hit(projectile)

		if dot_target != null:
			should_remove = true
			dot_damage_amount = projectile.damage
		elif is_boss_phase and current_boss != null and is_instance_valid(current_boss):
			if projectile.position.distance_to(current_boss.position) <= current_boss.radius + projectile.glow_radius:
				should_remove = true
				damage_target_is_boss = true
				boss_damage_amount = projectile.damage

		if projectile.is_outside_area(size):
			should_remove = true

		if should_remove:
			if projectiles.has(projectile):
				projectiles.erase(projectile)

			if is_instance_valid(projectile):
				projectile.queue_free()

			if damage_target_is_boss:
				if current_boss != null and is_instance_valid(current_boss):
					_spawn_impact_fx(current_boss.position, orange_color)

				_damage_boss(boss_damage_amount)
			elif dot_target != null:
				var projectile_angle: float = projectile.velocity.angle()
				_spawn_impact_fx(dot_target.position, orange_color)
				_damage_dot(dot_target, dot_damage_amount, projectile_angle)


func _update_dps(delta: float) -> void:
	dps_emit_timer -= delta

	if dps_emit_timer > 0.0:
		return

	dps_emit_timer = 0.25

	var now: float = Time.get_ticks_msec() / 1000.0
	var total_damage: float = 0.0

	for i in range(damage_events.size() - 1, -1, -1):
		var event: DamageEvent = damage_events[i]

		if now - event.time > 1.0:
			damage_events.remove_at(i)
		else:
			total_damage += event.damage

	dps_updated.emit(total_damage)


func _spawn_dot() -> void:
	if combat_paused:
		return

	if dots.size() >= max_dots:
		return

	if not arena_initialized:
		return

	if not _is_play_area_ready():
		return

	var play_rect: Rect2 = _get_play_area_rect()

	if play_rect.size.x < minimum_valid_play_area_size.x:
		return

	if play_rect.size.y < minimum_valid_play_area_size.y:
		return

	var spawn_position: Vector2 = _get_random_arena_position()
	var dot: DotEnemy = _spawn_dot_at_position(spawn_position)

	if dot == null:
		return

	if use_camera_drop_spawn:
		_play_dot_camera_drop(dot)
	else:
		_apply_random_dot_velocity(dot)


func _play_dot_camera_drop(dot: DotEnemy) -> void:
	if dot == null:
		return

	if not is_instance_valid(dot):
		return

	dot.set_meta("camera_dropping", true)

	var final_scale: Vector2 = Vector2.ONE * camera_drop_final_scale
	var start_scale: Vector2 = final_scale * camera_drop_start_scale
	var land_scale: Vector2 = final_scale * camera_drop_land_scale

	dot.velocity = Vector2.ZERO
	dot.scale = start_scale
	dot.modulate.a = 1.0
	dot.z_index = 20

	var duration: float = maxf(0.05, camera_drop_duration)

	var tween: Tween = create_tween()

	tween.tween_property(
		dot,
		"scale",
		land_scale,
		duration * 0.82
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	tween.tween_property(
		dot,
		"scale",
		final_scale,
		duration * 0.18
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	tween.finished.connect(_on_dot_camera_drop_finished.bind(dot))


func _on_dot_camera_drop_finished(dot: DotEnemy) -> void:
	if dot == null:
		return

	if not is_instance_valid(dot):
		return

	dot.scale = Vector2.ONE * camera_drop_final_scale
	dot.modulate.a = 1.0
	dot.z_index = 0
	dot.set_meta("camera_dropping", false)

	_apply_random_dot_velocity(dot)


func _apply_random_dot_velocity(dot: DotEnemy) -> void:
	if dot == null:
		return

	if not is_instance_valid(dot):
		return

	var angle: float = rng.randf_range(0.0, TAU)
	var speed: float = rng.randf_range(dot_start_speed_min, dot_start_speed_max)

	dot.velocity = Vector2.RIGHT.rotated(angle) * speed


func _get_random_arena_position() -> Vector2:
	var play_rect: Rect2 = _get_play_area_rect()

	return Vector2(
		rng.randf_range(play_rect.position.x, play_rect.end.x),
		rng.randf_range(play_rect.position.y, play_rect.end.y)
	)


func _clamp_to_arena_safe_area(point: Vector2) -> Vector2:
	var rect: Rect2 = _get_play_area_rect()

	return Vector2(
		clampf(point.x, rect.position.x, rect.end.x),
		clampf(point.y, rect.position.y, rect.end.y)
	)


func _spawn_dot_at_position(spawn_position: Vector2) -> DotEnemy:
	if combat_paused:
		return null

	if dots.size() >= max_dots:
		return null

	if dot_scene == null:
		return null

	if dot_layer == null:
		return null

	var dot: DotEnemy = dot_scene.instantiate() as DotEnemy

	if dot == null:
		push_error("CombatArena: dot_scene must use the DotEnemy script.")
		return null

	dot_layer.add_child(dot)
	dot.setup_dot(spawn_position, wave, rng)
	dot.position = spawn_position

	dot.died.connect(_on_dot_died)
	dots.append(dot)

	return dot


func _spawn_projectile(
	start_position: Vector2,
	direction: Vector2,
	damage: float,
	projectile_color: Color
) -> void:
	if projectile_scene == null:
		return

	if projectile_layer == null:
		return

	var projectile: CombatProjectile = projectile_scene.instantiate() as CombatProjectile

	if projectile == null:
		push_error("CombatArena: projectile_scene must use CombatProjectile script.")
		return

	projectile_layer.add_child(projectile)
	projectile.setup_projectile(start_position, direction, damage, projectile_color)
	projectile.expired.connect(_on_projectile_expired)

	projectiles.append(projectile)


func _on_projectile_expired(projectile: CombatProjectile) -> void:
	if projectile == null:
		return

	if projectiles.has(projectile):
		projectiles.erase(projectile)


func _spawn_slash_fx(from: Vector2, to: Vector2) -> void:
	if slash_fx_scene == null:
		return

	if fx_layer == null:
		return

	if from.distance_to(to) < 2.0:
		return

	var slash_fx: SlashFx = slash_fx_scene.instantiate() as SlashFx

	if slash_fx == null:
		push_error("CombatArena: slash_fx_scene must use the SlashFx script.")
		return

	fx_layer.add_child(slash_fx)
	slash_fx.play(from, to)


func _spawn_beam_fx(from: Vector2, to: Vector2, color: Color) -> void:
	if beam_fx_scene == null:
		return

	if fx_layer == null:
		return

	var beam: CombatBeamFx = beam_fx_scene.instantiate() as CombatBeamFx

	if beam == null:
		push_error("CombatArena: beam_fx_scene must use CombatBeamFx script.")
		return

	fx_layer.add_child(beam)
	beam.play(from, to, color)


func _spawn_impact_fx(spawn_position: Vector2, color: Color = Color.WHITE) -> void:
	if impact_fx_scene == null:
		return

	if fx_layer == null:
		return

	var impact: ImpactFx = impact_fx_scene.instantiate() as ImpactFx

	if impact == null:
		push_error("CombatArena: impact_fx_scene must use ImpactFx script.")
		return

	fx_layer.add_child(impact)
	impact.play(spawn_position, color)


func _clear_dots() -> void:
	for dot in dots:
		if dot != null and is_instance_valid(dot):
			dot.queue_free()

	dots.clear()

	if dot_layer != null:
		for child in dot_layer.get_children():
			child.queue_free()


func _clear_projectiles() -> void:
	for projectile in projectiles:
		if projectile != null and is_instance_valid(projectile):
			projectile.queue_free()

	projectiles.clear()

	if projectile_layer != null:
		for child in projectile_layer.get_children():
			child.queue_free()


func _clear_black_holes() -> void:
	for black_hole in black_holes:
		if black_hole != null and is_instance_valid(black_hole):
			black_hole.queue_free()

	black_holes.clear()


func _clear_fx_layer() -> void:
	if fx_layer == null:
		return

	for child in fx_layer.get_children():
		child.queue_free()


func _clear_turrets() -> void:
	for turret in turrets:
		if turret != null and is_instance_valid(turret):
			turret.queue_free()

	turrets.clear()

	if turret_layer != null:
		for child in turret_layer.get_children():
			child.queue_free()


func _clear_boss() -> void:
	if current_boss != null and is_instance_valid(current_boss):
		current_boss.queue_free()

	current_boss = null

	if boss_layer != null:
		for child in boss_layer.get_children():
			child.queue_free()


func _slice_between(from: Vector2, to: Vector2) -> void:
	if from.distance_to(to) < 2.0:
		return

	var slash_angle: float = (to - from).angle()

	if is_boss_phase and current_boss != null and is_instance_valid(current_boss):
		if current_boss.entrance_complete:
			var boss_distance: float = _distance_to_segment(current_boss.position, from, to)

			if boss_distance <= current_boss.radius + slice_width:
				_spawn_impact_fx(current_boss.position, orange_color)
				_damage_boss(slice_damage)

	var hit_dots: Array[DotEnemy] = []

	for dot in dots:
		if dot == null:
			continue

		if not is_instance_valid(dot):
			continue

		if dot.is_dying:
			continue

		if dot.is_merging:
			continue

		var distance: float = _distance_to_segment(dot.position, from, to)

		if distance <= dot.radius + slice_width:
			hit_dots.append(dot)

	for dot in hit_dots:
		if not dots.has(dot):
			continue

		_spawn_impact_fx(dot.position, orange_color)
		_damage_dot(dot, slice_damage, slash_angle)


func _damage_dot(dot: DotEnemy, amount: float, attack_angle: float = 0.0) -> void:
	if dot == null:
		return

	if not is_instance_valid(dot):
		return

	if not dots.has(dot):
		return

	if dot.is_dying:
		return

	if dot.is_merging:
		return

	_record_damage(amount)
	dot.take_damage(amount, attack_angle)


func _on_dot_died(dot: DotEnemy) -> void:
	if dot == null:
		return

	if dots.has(dot):
		dots.erase(dot)

	currency_gained.emit(dot.reward)

	if not is_boss_phase and not is_forming_boss:
		_add_progress(dot.progress_reward)

	enemy_destroyed.emit()


func _damage_boss(amount: float) -> void:
	if current_boss == null:
		return

	if not is_instance_valid(current_boss):
		current_boss = null
		return

	if current_boss.is_dying:
		return

	_record_damage(amount)
	current_boss.take_damage(amount)
	_check_boss_spit()


func _check_boss_spit() -> void:
	if current_boss == null:
		return

	if not is_instance_valid(current_boss):
		return

	if current_boss.is_dying:
		return

	if boss_spit_damage_step_ratio <= 0.0:
		return

	var spit_step: float = current_boss.max_hp * boss_spit_damage_step_ratio
	var spit_count: int = 0

	while current_boss.hp <= boss_next_spit_hp and boss_next_spit_hp > 0.0:
		_spit_dots_from_boss()
		boss_next_spit_hp -= spit_step

		spit_count += 1

		if spit_count >= 3:
			return


func _spit_dots_from_boss() -> void:
	if current_boss == null:
		return

	if not is_instance_valid(current_boss):
		return

	var amount: int = rng.randi_range(boss_spit_min_dots, boss_spit_max_dots)

	for i in range(amount):
		if dots.size() >= boss_dots_max:
			return

		var angle: float = TAU * float(i) / float(maxi(1, amount))
		angle += rng.randf_range(-0.45, 0.45)

		var direction: Vector2 = Vector2.RIGHT.rotated(angle).normalized()
		var spawn_position: Vector2 = current_boss.position + direction * (current_boss.radius + 16.0)

		spawn_position = _clamp_to_arena_safe_area(spawn_position)

		var dot: DotEnemy = _spawn_dot_at_position(spawn_position)

		if dot == null:
			continue

		dot.set_meta("camera_dropping", false)

		var spit_speed: float = rng.randf_range(boss_spit_speed_min, boss_spit_speed_max)
		dot.velocity = direction * spit_speed

	_spawn_impact_fx(current_boss.position, purple_color)


func _add_progress(amount: float) -> void:
	if is_boss_phase:
		return

	if is_forming_boss:
		return

	progress_current += amount

	if progress_current >= progress_max:
		progress_current = progress_max
		_emit_progress_normal()
		_start_boss_formation()
		return

	_emit_progress_normal()


func _emit_progress_normal() -> void:
	boss_progress_changed.emit(progress_current, progress_max, "Boss " + str(boss_level))


func _emit_progress_boss() -> void:
	if current_boss == null:
		return

	if not is_instance_valid(current_boss):
		return

	boss_progress_changed.emit(
		current_boss.hp,
		current_boss.max_hp,
		"Boss Fight " + str(current_boss.level)
	)


func _record_damage(amount: float) -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	damage_events.append(DamageEvent.new(now, amount))


func _fire_turret_at_dot(turret: CombatTurret, target: DotEnemy) -> void:
	if target == null:
		return

	if not is_instance_valid(target):
		return

	turret.aim_at(target.position)

	var start_position: Vector2 = turret.get_muzzle_position()
	var direction: Vector2 = target.position - start_position
	var projectile_color: Color = purple_color
	var attack_angle: float = direction.angle()
	var weapon_id: String = _normalize_weapon_id(turret.kind)
	var damage_amount: float = _calculate_reward_damage(
		turret.damage,
		weapon_id,
		false
	)

	if turret.kind == "tesla":
		_spawn_beam_fx(start_position, target.position, blue_color)
		_spawn_impact_fx(target.position, blue_color)
		_damage_dot(target, damage_amount, attack_angle)
		return

	if turret.kind == "laser":
		_spawn_beam_fx(start_position, target.position, purple_color)
		_spawn_impact_fx(target.position, purple_color)
		_damage_dot(target, damage_amount, attack_angle)
		return

	if turret.kind == "cannon":
		projectile_color = orange_color

	_spawn_projectile(
		start_position,
		direction,
		damage_amount,
		projectile_color
	)


func _fire_turret_at_boss(turret: CombatTurret) -> void:
	if current_boss == null:
		return

	if not is_instance_valid(current_boss):
		current_boss = null
		return

	if current_boss.is_dying:
		return

	turret.aim_at(current_boss.position)

	var start_position: Vector2 = turret.get_muzzle_position()
	var direction: Vector2 = current_boss.position - start_position
	var projectile_color: Color = purple_color
	var weapon_id: String = _normalize_weapon_id(turret.kind)
	var damage_amount: float = _calculate_reward_damage(
		turret.damage,
		weapon_id,
		true
	)

	if turret.kind == "tesla":
		_spawn_beam_fx(start_position, current_boss.position, blue_color)
		_spawn_impact_fx(current_boss.position, blue_color)
		_damage_boss(damage_amount)
		return

	if turret.kind == "laser":
		_spawn_beam_fx(start_position, current_boss.position, purple_color)
		_spawn_impact_fx(current_boss.position, purple_color)
		_damage_boss(damage_amount)
		return

	if turret.kind == "cannon":
		projectile_color = orange_color

	_spawn_projectile(
		start_position,
		direction,
		damage_amount,
		projectile_color
	)


func _find_nearest_dot(origin: Vector2, max_range: float) -> DotEnemy:
	var nearest_dot: DotEnemy = null
	var nearest_distance: float = max_range

	for dot in dots:
		if dot == null:
			continue

		if not is_instance_valid(dot):
			continue

		if dot.is_dying:
			continue

		if dot.is_merging:
			continue

		var distance: float = origin.distance_to(dot.position)

		if distance < nearest_distance:
			nearest_distance = distance
			nearest_dot = dot

	return nearest_dot


func _find_projectile_hit(projectile: CombatProjectile) -> DotEnemy:
	for dot in dots:
		if dot == null:
			continue

		if not is_instance_valid(dot):
			continue

		if dot.is_dying:
			continue

		if dot.is_merging:
			continue

		if projectile.position.distance_to(dot.position) <= dot.radius + projectile.glow_radius:
			return dot

	return null


func _distance_to_segment(point: Vector2, segment_start: Vector2, segment_end: Vector2) -> float:
	var segment: Vector2 = segment_end - segment_start
	var length_squared: float = segment.length_squared()

	if length_squared <= 0.001:
		return point.distance_to(segment_start)

	var t: float = clampf((point - segment_start).dot(segment) / length_squared, 0.0, 1.0)
	var projection: Vector2 = segment_start + segment * t

	return point.distance_to(projection)


func _rebuild_turrets() -> void:
	_clear_turrets()

	if turret_scene == null:
		return

	if turret_layer == null:
		return

	if size.x <= 10.0 or size.y <= 10.0:
		return

	for slot_id in equipped_weapons.keys():
		var weapon_kind: String = equipped_weapons[slot_id]

		if weapon_kind == "motor":
			continue

		var turret_position: Vector2 = _get_turret_position_for_slot(slot_id)

		if turret_position == Vector2.ZERO:
			continue

		_spawn_turret(turret_position, weapon_kind)


func _get_turret_position_for_slot(slot_id: String) -> Vector2:
	if weapon_slots.has(slot_id):
		var button: Button = weapon_slots[slot_id] as Button

		if button != null and is_instance_valid(button):
			var global_center: Vector2 = button.get_global_rect().get_center()
			var local_center: Vector2 = get_global_transform().affine_inverse() * global_center

			if slot_id.begins_with("left_"):
				return local_center + Vector2(44.0, 0.0)

			if slot_id.begins_with("right_"):
				return local_center + Vector2(-44.0, 0.0)

			if slot_id.begins_with("bottom_"):
				return local_center + Vector2(0.0, -44.0)

			return local_center

	return Vector2.ZERO


func _spawn_turret(turret_position: Vector2, turret_kind: String) -> void:
	if turret_scene == null:
		return

	if turret_layer == null:
		return

	var turret: CombatTurret = turret_scene.instantiate() as CombatTurret

	if turret == null:
		push_error("CombatArena: turret_scene must use CombatTurret script.")
		return

	turret_layer.add_child(turret)
	turret.setup_turret(turret_position, turret_kind)

	if turret_position.x < size.x * 0.25:
		turret.aim_direction = Vector2.RIGHT
	elif turret_position.x > size.x * 0.75:
		turret.aim_direction = Vector2.LEFT
	else:
		turret.aim_direction = Vector2.UP

	turrets.append(turret)


# ===================================================================
# REWARD SYSTEM API
# ===================================================================

func set_combat_paused(paused: bool) -> void:
	combat_paused = paused
	is_slicing = false

	# Pause/resume all gameplay tweens created below this arena.
	# SceneTree pausing is still controlled by CombatScreen.
	if paused:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	else:
		if not combat_is_over:
			mouse_filter = Control.MOUSE_FILTER_STOP


func update_reward_modifiers(
	damage_multiplier: float,
	new_boss_damage_multiplier: float,
	attack_speed_multiplier: float,
	new_critical_chance: float,
	new_critical_damage_multiplier: float
) -> void:
	global_damage_multiplier = maxf(damage_multiplier, 0.0)
	boss_damage_multiplier = maxf(new_boss_damage_multiplier, 0.0)
	global_attack_speed_multiplier = maxf(attack_speed_multiplier, 0.05)
	critical_chance = clampf(new_critical_chance, 0.0, 1.0)
	critical_damage_multiplier = maxf(new_critical_damage_multiplier, 1.0)


func update_weapon_reward_modifiers(
	damage_modifiers: Dictionary,
	attack_speed_modifiers: Dictionary,
	range_modifiers: Dictionary,
	tier_values: Dictionary
) -> void:
	weapon_damage_multipliers = damage_modifiers.duplicate(true)
	weapon_attack_speed_multipliers = attack_speed_modifiers.duplicate(true)
	weapon_range_multipliers = range_modifiers.duplicate(true)
	weapon_tiers = tier_values.duplicate(true)

	if arena_initialized:
		_rebuild_turrets()


func unlock_combat_weapon(weapon_id: String) -> void:
	var normalized_id: String = _normalize_weapon_id(weapon_id)

	if normalized_id.is_empty():
		return

	if not unlocked_combat_weapons.has(normalized_id):
		unlocked_combat_weapons.append(normalized_id)

	var turret_kind: String = _weapon_id_to_turret_kind(normalized_id)
	var empty_slot_id: String = _find_first_empty_slot_for_weapon(turret_kind)

	if empty_slot_id.is_empty():
		push_warning(
			"CombatArena: Weapon unlocked but no empty slot is available: "
			+ normalized_id
		)
		return

	equip_weapon_to_slot(empty_slot_id, turret_kind)


func set_weapon_tier(weapon_id: String, new_tier: int) -> void:
	var normalized_id: String = _normalize_weapon_id(weapon_id)

	if normalized_id.is_empty():
		return

	weapon_tiers[normalized_id] = maxi(new_tier, 1)

	if arena_initialized:
		_rebuild_turrets()


func _calculate_reward_damage(
	base_damage: float,
	weapon_id: String,
	target_is_boss: bool
) -> float:
	var normalized_id: String = _normalize_weapon_id(weapon_id)
	var damage: float = base_damage
	damage *= global_damage_multiplier
	damage *= _get_weapon_damage_multiplier(normalized_id)

	if target_is_boss:
		damage *= boss_damage_multiplier

	if critical_chance > 0.0 and rng.randf() <= critical_chance:
		damage *= critical_damage_multiplier

	return maxf(damage, 0.0)


func _get_weapon_damage_multiplier(weapon_id: String) -> float:
	var normalized_id: String = _normalize_weapon_id(weapon_id)
	var stored_multiplier: float = float(
		weapon_damage_multipliers.get(normalized_id, 1.0)
	)

	return stored_multiplier * _get_tier_damage_multiplier(normalized_id)


func _get_weapon_attack_speed_multiplier(weapon_id: String) -> float:
	var normalized_id: String = _normalize_weapon_id(weapon_id)
	var stored_multiplier: float = float(
		weapon_attack_speed_multipliers.get(normalized_id, 1.0)
	)

	return stored_multiplier * _get_tier_attack_speed_multiplier(normalized_id)


func _get_weapon_range_multiplier(weapon_id: String) -> float:
	var normalized_id: String = _normalize_weapon_id(weapon_id)
	var stored_multiplier: float = float(
		weapon_range_multipliers.get(normalized_id, 1.0)
	)

	return stored_multiplier * _get_tier_range_multiplier(normalized_id)


func _get_weapon_tier(weapon_id: String) -> int:
	var normalized_id: String = _normalize_weapon_id(weapon_id)
	return maxi(int(weapon_tiers.get(normalized_id, 1)), 1)


func _get_tier_damage_multiplier(weapon_id: String) -> float:
	var extra_levels: int = maxi(_get_weapon_tier(weapon_id) - 1, 0)
	return 1.0 + float(extra_levels) * tier_damage_bonus_per_level


func _get_tier_attack_speed_multiplier(weapon_id: String) -> float:
	var extra_levels: int = maxi(_get_weapon_tier(weapon_id) - 1, 0)
	return 1.0 + float(extra_levels) * tier_attack_speed_bonus_per_level


func _get_tier_range_multiplier(weapon_id: String) -> float:
	var extra_levels: int = maxi(_get_weapon_tier(weapon_id) - 1, 0)
	return 1.0 + float(extra_levels) * tier_range_bonus_per_level


func _normalize_weapon_id(weapon_id: String) -> String:
	var normalized_id: String = weapon_id.strip_edges().to_lower()

	match normalized_id:
		"tesla":
			return "tesla_coil"
		"pulse":
			return "pulse_cannon"
		"cannon":
			return "pulse_cannon"
		"motor":
			return "mortar"
		_:
			return normalized_id


func _weapon_id_to_turret_kind(weapon_id: String) -> String:
	match _normalize_weapon_id(weapon_id):
		"tesla_coil":
			return "tesla"
		"pulse_cannon":
			return "cannon"
		"mortar":
			return "motor"
		_:
			return _normalize_weapon_id(weapon_id)


func _find_first_empty_slot_for_weapon(turret_kind: String) -> String:
	var preferred_prefixes: Array[String] = []

	match turret_kind:
		"tesla", "laser", "railgun", "rocket":
			preferred_prefixes = ["left_", "right_", "bottom_"]
		"motor":
			preferred_prefixes = ["bottom_", "left_", "right_"]
		_:
			preferred_prefixes = ["bottom_", "left_", "right_"]

	for prefix: String in preferred_prefixes:
		var sorted_slot_ids: Array[String] = []

		for slot_key: Variant in weapon_slots.keys():
			var slot_id: String = str(slot_key)

			if slot_id.begins_with(prefix):
				sorted_slot_ids.append(slot_id)

		sorted_slot_ids.sort()

		for slot_id: String in sorted_slot_ids:
			if not equipped_weapons.has(slot_id):
				return slot_id

	return ""


func end_combat() -> void:
	starting_spawn_generation += 1
	combat_paused = false
	combat_is_over = true
	is_slicing = false
	is_forming_boss = false

	frenzy_timer = 0.0
	focus_fire_timer = 0.0

	_clear_boss()
	_clear_dots()
	_clear_fx_layer()
	_clear_projectiles()
	_clear_black_holes()
	_clear_drones()

	set_process(false)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	combat_finished.emit()
	queue_redraw()
