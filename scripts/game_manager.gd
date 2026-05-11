extends Node2D

@export var enemy_scene: PackedScene
@export var signal_pickup_scene: PackedScene
@export var bullet_scene: PackedScene
@export var weapon_upgrade_scene: PackedScene
@export var bullet_pickup_scene: PackedScene
@export var health_pickup_scene: PackedScene
@export var comet_scene: PackedScene
@export var enemy_bullet_scene: PackedScene
@export var kills_to_win: int = 30

@export var signal_loss_interval: float = 34.0
@export var shockwave_steps: int = 8
@export var shockwave_step_delay: float = 0.045
@export var doomsday_interval: float = 68.0
@export var doomsday_duration: float = 15.0
@export var max_active_enemies_base: int = 16
@export var max_active_enemies_growth_interval: float = 20.0
@export var max_active_enemies_growth_amount: int = 3

var score: int = 0
var elapsed: float = 0.0
var kills: int = 0
var game_over: bool = false
var victory: bool = false
var autoshoot_enabled: bool = false
var game_started: bool = false
var game_mode: String = "menu"
var campaign_level: int = 0
var enemy_health_bonus: int = 0
var next_signal_loss_at: float = 45.0
var base_spawn_wait_time: float = 0.98
var doomsday_active: bool = false
var next_doomsday_at: float = 72.0
var doomsday_ends_at: float = 0.0
var campaign_levels: Array[Dictionary] = [
	{"name": "Level 1: Boot Sector", "kills": 18, "spawn": 1.30, "upgrades": 6.0, "comets": 10.0, "enemies": ["chaser", "chaser", "sprinter", "orbiter", "shooter", "shooter", "tank"]},
	{"name": "Level 2: Broken Cache", "kills": 25, "spawn": 1.00, "upgrades": 5.5, "comets": 8.0, "enemies": ["chaser", "sprinter", "zigzag", "orbiter", "shooter", "shooter", "hopper", "tank"]},
	{"name": "Level 3: Kernel Storm", "kills": 35, "spawn": 0.78, "upgrades": 5.0, "comets": 6.5, "enemies": ["chaser", "sprinter", "zigzag", "tank", "tank", "orbiter", "shooter", "shooter", "hopper"]}
]
var endless_enemy_pool: Array[String] = ["chaser", "chaser", "sprinter", "sprinter", "zigzag", "hopper", "orbiter", "shooter", "shooter", "tank"]
var debug_enemy_pool: Array[String] = ["chaser", "sprinter", "tank", "zigzag", "shooter", "orbiter", "hopper"]

const SAVE_PATH: String = "user://signal_leak_save.json"

var difficulty_index: int = 1
var difficulty_options: Array[Dictionary] = [
	{"id": "casual", "name": "Casual", "spawn_multiplier": 1.18, "max_enemy_bonus": -3, "enemy_health_bonus": 0, "signal_loss_multiplier": 1.25, "doomsday_multiplier": 1.35, "drop_multiplier": 1.18},
	{"id": "normal", "name": "Normal", "spawn_multiplier": 1.00, "max_enemy_bonus": 0, "enemy_health_bonus": 0, "signal_loss_multiplier": 1.00, "doomsday_multiplier": 1.00, "drop_multiplier": 1.00},
	{"id": "collapse", "name": "Signal Collapse", "spawn_multiplier": 0.82, "max_enemy_bonus": 6, "enemy_health_bonus": 1, "signal_loss_multiplier": 0.78, "doomsday_multiplier": 0.75, "drop_multiplier": 0.82}
]
var save_data: Dictionary = {}
var run_finalized: bool = false
var total_kills: int = 0
var highest_level_this_run: int = 1
var doomsday_events_survived: int = 0

@onready var player: Node = $Player
@onready var enemies: Node2D = $Enemies
@onready var pickups: Node2D = $Pickups
@onready var bullets: Node2D = $Bullets
@onready var comets: Node2D = $Comets
@onready var enemy_bullets: Node2D = $EnemyBullets
@onready var signal_director: Node = $SignalDirector
@onready var hud_label: Label = $CanvasLayer/HUD
@onready var weapon_label: Label = $CanvasLayer/Weapons
@onready var mode_label: Label = $CanvasLayer/ModeLabel
@onready var health_fill: ColorRect = $CanvasLayer/HealthBar/Fill
@onready var health_text: Label = $CanvasLayer/HealthBar/HealthText
@onready var ultra_fill: ColorRect = $CanvasLayer/UltraBar/Fill
@onready var ultra_text: Label = $CanvasLayer/UltraBar/UltraText
@onready var level_label: Label = $CanvasLayer/LevelText
@onready var announcement_label: Label = $CanvasLayer/Announcement
@onready var game_over_panel: Control = $CanvasLayer/GameOverPanel
@onready var victory_panel: Control = $CanvasLayer/VictoryPanel
@onready var spawn_timer: Timer = $EnemySpawnTimer
@onready var pickup_timer: Timer = $PickupSpawnTimer
@onready var upgrade_timer: Timer = $WeaponUpgradeTimer
@onready var bullet_pickup_timer: Timer = $BulletPickupTimer
@onready var health_pickup_timer: Timer = $HealthPickupTimer
@onready var comet_timer: Timer = $CometTimer
@onready var pause_panel: Control = $CanvasLayer/PausePanel
@onready var pause_label: Label = $CanvasLayer/PausePanel/PauseText
@onready var mode_panel: Control = $CanvasLayer/ModePanel
@onready var music_player: Node = get_node_or_null("MusicPlayer")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	randomize()
	game_over_panel.visible = false
	victory_panel.visible = false
	pause_panel.visible = false
	mode_panel.visible = true
	announcement_label.visible = false
	player.health_changed.connect(_on_health_changed)
	player.ammo_changed.connect(_on_ammo_changed)
	player.level_changed.connect(_on_level_changed)
	player.ultra_changed.connect(_on_ultra_changed)
	player.ultra_requested.connect(_on_player_ultra_requested)
	player.died.connect(_on_player_died)
	player.shoot_requested.connect(_on_player_shoot_requested)
	signal_director.effect_started.connect(_on_effect_started)
	signal_director.effect_ended.connect(_on_effect_ended)
	spawn_timer.timeout.connect(spawn_enemy)
	pickup_timer.timeout.connect(spawn_pickup)
	upgrade_timer.timeout.connect(spawn_weapon_upgrade)
	bullet_pickup_timer.timeout.connect(spawn_bullet_pickup)
	health_pickup_timer.timeout.connect(spawn_health_pickup)
	comet_timer.timeout.connect(spawn_comet)
	_stop_timers()
	_load_save_data()
	_update_mode_panel_text()
	_update_hud()

func _process(delta: float) -> void:
	if get_tree().paused:
		_update_pause_menu()
		return
	if not game_started or game_over or victory:
		return
	elapsed += delta
	highest_level_this_run = max(highest_level_this_run, player.player_level)
	score = int(elapsed * 10.0) + total_kills * 50 + (player.player_level - 1) * 100
	_update_spawn_pressure()
	_check_signal_loss_scaling()
	_check_doomsday_event()
	_update_hud()

func _input(event: InputEvent) -> void:
	# Use _input instead of _unhandled_input so the title screen UI can never swallow mode keys.
	# Also support direct key checks, so the game still starts even if project.godot input maps were not copied over.
	if not game_started:
		if _event_pressed_action_or_key(event, "start_endless", KEY_1):
			_start_endless()
			return
		if _event_pressed_action_or_key(event, "start_campaign", KEY_2):
			_start_campaign(0)
			return
		if _event_pressed_action_or_key(event, "start_debug", KEY_3):
			_start_debug_endless()
			return

	if (not game_started or get_tree().paused) and _event_pressed_action_or_key(event, "cycle_difficulty", KEY_D):
		_cycle_difficulty()
		return

	if _event_pressed_action_or_key(event, "toggle_fullscreen", KEY_F):
		_toggle_fullscreen()
		return

	if game_started and not game_over and not victory and _event_is_right_click_press(event):
		_set_autoshoot_state(not autoshoot_enabled)
		return

	if game_started and not game_over and not victory and _event_pressed_action_or_key(event, "ultra_attack", KEY_Q):
		if not player.try_activate_ultra():
			_show_announcement("ULTRA NOT CHARGED", Color(0.55, 0.8, 1.0, 1.0), 0.85)
		return

	if _event_pressed_action_or_key(event, "pause", KEY_ESCAPE):
		_toggle_pause()
		return

	if _event_pressed_action_or_key(event, "restart", KEY_R) and (game_over or victory):
		get_tree().paused = false
		get_tree().reload_current_scene()

func _event_pressed_action_or_key(event: InputEvent, action_name: String, fallback_key: int) -> bool:
	if InputMap.has_action(action_name) and event.is_action_pressed(action_name):
		return true
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if not key_event.pressed or key_event.echo:
			return false
		return int(key_event.keycode) == fallback_key or int(key_event.physical_keycode) == fallback_key
	return false

func _event_is_right_click_press(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		return mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_RIGHT
	return false

func _set_autoshoot_state(enabled: bool) -> void:
	autoshoot_enabled = enabled
	if player != null and player.has_method("set_autoshoot"):
		player.set_autoshoot(enabled)
	_update_pause_menu()
	_update_hud()

func _start_endless() -> void:
	if music_player != null and music_player.has_method("start_normal"):
		music_player.start_normal()
	game_mode = "endless"
	kills_to_win = 999999
	game_started = true
	mode_panel.visible = false
	_begin_run_tracking()
	spawn_timer.wait_time = 0.98
	base_spawn_wait_time = spawn_timer.wait_time
	upgrade_timer.wait_time = 6.5
	bullet_pickup_timer.wait_time = 4.0
	health_pickup_timer.wait_time = 7.5
	comet_timer.wait_time = 8.5
	next_signal_loss_at = elapsed + _get_signal_loss_interval()
	next_doomsday_at = elapsed + _get_doomsday_interval()
	doomsday_active = false
	_start_timers()
	_spawn_intro_pack()
	_update_hud()

func _start_debug_endless() -> void:
	if music_player != null and music_player.has_method("start_normal"):
		music_player.start_normal()
	game_mode = "debug"
	kills_to_win = 999999
	game_started = true
	mode_panel.visible = false
	_begin_run_tracking()
	spawn_timer.wait_time = 0.70
	base_spawn_wait_time = spawn_timer.wait_time
	upgrade_timer.wait_time = 5.0
	bullet_pickup_timer.wait_time = 3.5
	health_pickup_timer.wait_time = 6.0
	comet_timer.wait_time = 7.0
	next_signal_loss_at = elapsed + _get_signal_loss_interval()
	next_doomsday_at = elapsed + 30.0
	doomsday_active = false
	_start_timers()
	_spawn_debug_enemy_sampler()
	_show_announcement("DEBUG MODE\nEqual enemy probability", Color(0.75, 0.95, 1.0, 1.0), 1.3)
	_update_hud()

func _start_campaign(level_index: int) -> void:
	if music_player != null and music_player.has_method("start_normal"):
		music_player.start_normal()
	game_mode = "campaign"
	campaign_level = level_index
	var level: Dictionary = campaign_levels[campaign_level]
	kills_to_win = int(level["kills"])
	game_started = true
	mode_panel.visible = false
	_begin_run_tracking()
	spawn_timer.wait_time = float(level["spawn"])
	base_spawn_wait_time = spawn_timer.wait_time
	doomsday_active = false
	next_doomsday_at = elapsed + _get_doomsday_interval()
	upgrade_timer.wait_time = float(level["upgrades"])
	bullet_pickup_timer.wait_time = 4.2
	health_pickup_timer.wait_time = 7.2
	comet_timer.wait_time = float(level["comets"])
	base_spawn_wait_time = spawn_timer.wait_time
	next_signal_loss_at = elapsed + _get_signal_loss_interval()
	next_doomsday_at = elapsed + _get_doomsday_interval()
	doomsday_active = false
	_start_timers()
	_spawn_intro_pack()
	_update_hud()

func _start_timers() -> void:
	spawn_timer.start()
	pickup_timer.start()
	upgrade_timer.start()
	bullet_pickup_timer.start()
	health_pickup_timer.start()
	comet_timer.start()

func _stop_timers() -> void:
	spawn_timer.stop()
	pickup_timer.stop()
	upgrade_timer.stop()
	bullet_pickup_timer.stop()
	health_pickup_timer.stop()
	comet_timer.stop()

func _toggle_pause() -> void:
	if not game_started or game_over or victory:
		return
	get_tree().paused = not get_tree().paused
	pause_panel.visible = get_tree().paused
	_update_pause_menu()

func _update_pause_menu() -> void:
	var state: String = "ON" if autoshoot_enabled else "OFF"
	var difficulty_name: String = _get_difficulty_name()
	pause_label.text = "PAUSED\n\nWASD / Arrow Keys: Move\nMouse: Aim\nHold Left Click: Shoot\nRight Click: Toggle Autofire [%s]\nQ: 90° Ultra Shockwave when charged\nPickups despawn after 4 seconds\n\nSettings / Debug:\nD: Difficulty preset [%s] - applies next run\nF: Toggle fullscreen\nM: Toggle procedural music\nT: Test beep\nY: Restart music\n\nESC: Resume\nR: Restart after death/victory" % [state, difficulty_name]

func _check_signal_loss_scaling() -> void:
	if elapsed < next_signal_loss_at:
		return
	enemy_health_bonus += 1
	next_signal_loss_at += _get_signal_loss_interval()
	_apply_signal_loss_to_existing_enemies()
	_show_announcement("SIGNAL LOSS DETECTED\nEnemy health increased", Color(1.0, 0.18, 0.32, 1.0), 1.8)

func _apply_signal_loss_to_existing_enemies() -> void:
	for enemy in enemies.get_children():
		if is_instance_valid(enemy) and enemy.has_method("apply_health_bonus"):
			enemy.apply_health_bonus(1)

func _check_doomsday_event() -> void:
	if doomsday_active:
		if elapsed >= doomsday_ends_at:
			_end_doomsday()
		return
	if elapsed >= next_doomsday_at:
		_start_doomsday()

func _start_doomsday() -> void:
	if music_player != null and music_player.has_method("start_doomsday"):
		music_player.start_doomsday()
	doomsday_active = true
	doomsday_ends_at = elapsed + doomsday_duration
	next_doomsday_at = elapsed + _get_doomsday_interval()
	if base_spawn_wait_time <= 0.0:
		base_spawn_wait_time = spawn_timer.wait_time
	_update_spawn_pressure()
	spawn_timer.start()
	for enemy in enemies.get_children():
		if is_instance_valid(enemy) and enemy.has_method("apply_doomsday_boost"):
			enemy.apply_doomsday_boost()
	_spawn_doomsday_wave()
	_show_announcement("DOOMSDAY", Color(1.0, 0.08, 0.08, 1.0), 1.8)

func _end_doomsday() -> void:
	if music_player != null and music_player.has_method("start_normal"):
		music_player.start_normal()
	doomsday_active = false
	doomsday_events_survived += 1
	_update_spawn_pressure()
	spawn_timer.start()
	_show_announcement("DOOMSDAY CLEARED", Color(0.45, 1.0, 0.7, 1.0), 1.0)

func _update_spawn_pressure() -> void:
	if not game_started or game_over or victory:
		return
	var time_factor: float = max(0.42, 1.0 - elapsed / 260.0)
	var doomsday_factor: float = 0.45 if doomsday_active else 1.0
	var difficulty_factor: float = float(_difficulty_value("spawn_multiplier", 1.0))
	spawn_timer.wait_time = max(0.24, base_spawn_wait_time * time_factor * doomsday_factor * difficulty_factor)

func _get_max_active_enemies() -> int:
	var growth_steps: int = int(elapsed / max_active_enemies_growth_interval)
	var cap: int = max_active_enemies_base + growth_steps * max_active_enemies_growth_amount
	if game_mode == "campaign":
		cap = 12 + campaign_level * 5 + growth_steps
	elif game_mode == "debug":
		cap += 8
	cap += int(_difficulty_value("max_enemy_bonus", 0))
	if doomsday_active:
		cap += 10
	return max(6, cap)

func spawn_enemy() -> void:
	if enemies.get_child_count() >= _get_max_active_enemies():
		return
	_spawn_enemy_kind(_pick_enemy_type(), 720.0)

func _spawn_intro_pack() -> void:
	_spawn_enemy_kind("orbiter", 520.0)
	_spawn_enemy_kind("shooter", 610.0)
	_spawn_enemy_kind("tank", 680.0)

func _spawn_debug_enemy_sampler() -> void:
	var angle_step: float = TAU / float(debug_enemy_pool.size())
	for i in range(debug_enemy_pool.size()):
		_spawn_enemy_kind(debug_enemy_pool[i], 420.0 + float(i % 3) * 55.0, float(i) * angle_step)

func _spawn_doomsday_wave() -> void:
	var amount: int = 9 + int(elapsed / 18.0)
	amount = min(amount, 26)
	for i in range(amount):
		var kind: String = _pick_enemy_type()
		var angle: float = float(i) / float(max(1, amount)) * TAU + randf_range(-0.18, 0.18)
		_spawn_enemy_kind(kind, randf_range(560.0, 820.0), angle)

func _spawn_enemy_kind(kind: String, distance_from_player: float = 720.0, forced_angle: float = INF) -> void:
	if enemy_scene == null or game_over or victory or not game_started:
		return
	var enemy: Node = enemy_scene.instantiate()
	enemy.target = player
	enemy.global_position = _random_spawn_position(distance_from_player, forced_angle)
	if enemy.has_method("configure"):
		var difficulty_health_bonus: int = int(_difficulty_value("enemy_health_bonus", 0))
		enemy.configure(kind, campaign_level, enemy_health_bonus + difficulty_health_bonus)
	if doomsday_active and enemy.has_method("apply_doomsday_boost"):
		enemy.apply_doomsday_boost()
	if enemy.has_signal("projectile_requested"):
		enemy.connect("projectile_requested", Callable(self, "_on_enemy_projectile_requested"))
	enemy.killed.connect(_on_enemy_killed)
	enemies.add_child(enemy)

func spawn_pickup() -> void:
	if signal_pickup_scene == null or game_over or victory or not game_started:
		return
	var pickup: Node = signal_pickup_scene.instantiate()
	pickup.effect_id = _random_effect_id()
	pickup.global_position = _random_spawn_position(randf_range(260.0, 560.0))
	pickup.collected.connect(signal_director.activate_effect)
	pickups.add_child(pickup)

func spawn_weapon_upgrade() -> void:
	if weapon_upgrade_scene == null or game_over or victory or not game_started:
		return
	var upgrade: Node = weapon_upgrade_scene.instantiate()
	var upgrade_id: String = _random_weapon_upgrade_id()
	upgrade.configure(upgrade_id)
	upgrade.global_position = _random_spawn_position(randf_range(320.0, 620.0))
	upgrade.collected.connect(_on_weapon_upgrade_collected)
	pickups.add_child(upgrade)

func spawn_bullet_pickup() -> void:
	if bullet_pickup_scene == null or game_over or victory or not game_started:
		return
	var drop: Node = bullet_pickup_scene.instantiate()
	drop.configure(randi_range(14, 28))
	drop.global_position = _random_spawn_position(randf_range(240.0, 620.0))
	pickups.add_child(drop)

func spawn_health_pickup() -> void:
	if health_pickup_scene == null or game_over or victory or not game_started:
		return
	# Do not spam health when the player is already full.
	if player.health >= player.max_health and randf() > 0.25:
		return
	var pickup: Node = health_pickup_scene.instantiate()
	pickup.configure(randi_range(16, 30))
	pickup.global_position = _random_spawn_position(randf_range(260.0, 660.0))
	pickups.add_child(pickup)

func spawn_comet() -> void:
	if comet_scene == null or game_over or victory or not game_started:
		return
	var comet: Node = comet_scene.instantiate()
	var angle: float = randf() * TAU
	var start: Vector2 = player.global_position + Vector2(cos(angle), sin(angle)) * randf_range(720.0, 980.0)
	var rough_target: Vector2 = player.global_position + Vector2(randf_range(-260.0, 260.0), randf_range(-180.0, 180.0))
	var dir: Vector2 = start.direction_to(rough_target).rotated(randf_range(-0.35, 0.35))
	comets.add_child(comet)
	comet.setup(start, dir)

func duplicate_enemies() -> void:
	var existing: Array = enemies.get_children()
	for enemy in existing:
		if enemy_scene == null:
			continue
		var clone: Node = enemy_scene.instantiate()
		clone.target = player
		clone.global_position = enemy.global_position + Vector2(randf_range(-40, 40), randf_range(-40, 40))
		if clone.has_method("configure"):
			var clone_difficulty_health_bonus: int = int(_difficulty_value("enemy_health_bonus", 0))
			clone.configure(_pick_enemy_type(), campaign_level, enemy_health_bonus + clone_difficulty_health_bonus)
		if doomsday_active and clone.has_method("apply_doomsday_boost"):
			clone.apply_doomsday_boost()
		if clone.has_signal("projectile_requested"):
			clone.connect("projectile_requested", Callable(self, "_on_enemy_projectile_requested"))
		clone.killed.connect(_on_enemy_killed)
		enemies.add_child(clone)

func _on_player_shoot_requested(origin: Vector2, direction: Vector2, weapon_state: Dictionary) -> void:
	if bullet_scene == null or game_over or victory or not game_started:
		return
	var forward: Vector2 = direction.normalized()
	var shot_directions: Array[Vector2] = [forward]
	var triple_level: int = int(weapon_state.get("triple_shot_level", 0))
	if bool(weapon_state.get("triple_shot", false)):
		shot_directions = [forward.rotated(-0.22).normalized(), forward, forward.rotated(0.22).normalized()]
		if triple_level >= 3:
			shot_directions = [forward.rotated(-0.38).normalized(), forward.rotated(-0.19).normalized(), forward, forward.rotated(0.19).normalized(), forward.rotated(0.38).normalized()]
	var reverse_level: int = int(weapon_state.get("reverse_shot_level", 0))
	if bool(weapon_state.get("reverse_shot", false)):
		var back: Vector2 = -forward
		shot_directions.append(back.normalized())
		if reverse_level >= 2:
			shot_directions.append(back.rotated(-0.22).normalized())
			shot_directions.append(back.rotated(0.22).normalized())
		if reverse_level >= 4:
			shot_directions.append(back.rotated(-0.42).normalized())
			shot_directions.append(back.rotated(0.42).normalized())
	var muzzle_distance: float = float(weapon_state.get("muzzle_distance", 30.0))
	for shot_direction in shot_directions:
		var bullet: Node = bullet_scene.instantiate()
		bullets.add_child(bullet)
		var bullet_origin: Vector2 = origin + shot_direction.normalized() * muzzle_distance
		bullet.setup(bullet_origin, shot_direction, weapon_state)

func _on_enemy_projectile_requested(origin: Vector2, direction: Vector2, damage: int) -> void:
	if enemy_bullet_scene == null or game_over or victory or not game_started:
		return
	var projectile: Node = enemy_bullet_scene.instantiate()
	enemy_bullets.add_child(projectile)
	projectile.setup(origin, direction, damage)

func _on_player_ultra_requested(origin: Vector2, direction: Vector2, damage: int, radius: float, arc_angle: float) -> void:
	if game_over or victory or not game_started:
		return
	_show_announcement("ULTRA CONE SHOCKWAVE", Color(0.45, 0.9, 1.0, 1.0), 0.9)
	_run_shockwave(origin, direction, damage, radius, arc_angle)

func _run_shockwave(origin: Vector2, direction: Vector2, damage: int, radius: float, arc_angle: float) -> void:
	var shockwave: Polygon2D = Polygon2D.new()
	shockwave.name = "UltraDirectionalShockwave"
	shockwave.global_position = origin
	shockwave.color = Color(0.35, 0.9, 1.0, 0.30)
	shockwave.z_index = 55
	add_child(shockwave)

	var outline: Line2D = Line2D.new()
	outline.name = "UltraDirectionalShockwaveOutline"
	outline.global_position = origin
	outline.width = 5.0
	outline.default_color = Color(0.55, 0.95, 1.0, 0.95)
	outline.z_index = 56
	add_child(outline)

	var damaged_ids: Dictionary = {}
	for step in range(1, shockwave_steps + 1):
		if not is_instance_valid(shockwave) or not is_instance_valid(outline):
			return
		var current_radius: float = radius * float(step) / float(shockwave_steps)
		var cone_points: PackedVector2Array = _make_cone_points(direction, current_radius, arc_angle, 32)
		shockwave.polygon = cone_points
		shockwave.color = Color(0.35, 0.9, 1.0, max(0.04, 0.32 - float(step) * 0.03))
		outline.points = cone_points
		outline.width = max(2.0, 8.0 - float(step) * 0.55)
		_damage_enemies_in_cone(origin, direction, current_radius, arc_angle, damage, damaged_ids)
		await get_tree().create_timer(shockwave_step_delay).timeout

	if is_instance_valid(shockwave):
		shockwave.queue_free()
	if is_instance_valid(outline):
		outline.queue_free()

func _damage_enemies_in_cone(origin: Vector2, direction: Vector2, radius: float, arc_angle: float, damage: int, damaged_ids: Dictionary) -> void:
	var radius_squared: float = radius * radius
	var normalized_direction: Vector2 = direction.normalized()
	var half_arc: float = arc_angle * 0.5
	for enemy in enemies.get_children():
		if not is_instance_valid(enemy) or not enemy.has_method("take_damage"):
			continue
		var id: int = enemy.get_instance_id()
		if damaged_ids.has(id):
			continue
		var to_enemy: Vector2 = enemy.global_position - origin
		if to_enemy.length_squared() > radius_squared:
			continue
		if abs(normalized_direction.angle_to(to_enemy.normalized())) <= half_arc:
			damaged_ids[id] = true
			enemy.take_damage(damage)

func _make_cone_points(direction: Vector2, radius: float, arc_angle: float, sides: int) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	points.append(Vector2.ZERO)
	var base_angle: float = direction.normalized().angle()
	for i in range(sides + 1):
		var t: float = float(i) / float(sides)
		var angle: float = base_angle - arc_angle * 0.5 + arc_angle * t
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	points.append(Vector2.ZERO)
	return points

func _on_enemy_killed(_enemy: Node) -> void:
	kills += 1
	total_kills += 1
	score += 50
	var leveled_up: bool = false
	if player.has_method("register_enemy_kill"):
		leveled_up = player.register_enemy_kill()
	if leveled_up:
		_show_announcement("LEVEL UP\nWeapon damage increased", Color(0.35, 1.0, 0.72, 1.0), 1.1)
	var drop_multiplier: float = float(_difficulty_value("drop_multiplier", 1.0))
	if randf() < 0.22 * drop_multiplier:
		_spawn_bullet_drop_at(_enemy.global_position)
	if randf() < 0.10 * drop_multiplier:
		_spawn_health_drop_at(_enemy.global_position)
	if game_mode == "campaign" and kills >= kills_to_win:
		if campaign_level < campaign_levels.size() - 1:
			_advance_campaign_level()
		else:
			_trigger_victory()
	_update_hud()

func _spawn_bullet_drop_at(drop_position: Vector2) -> void:
	if bullet_pickup_scene == null:
		return
	var drop: Node = bullet_pickup_scene.instantiate()
	drop.configure(randi_range(10, 22))
	drop.global_position = drop_position + Vector2(randf_range(-30.0, 30.0), randf_range(-30.0, 30.0))
	pickups.add_child(drop)

func _spawn_health_drop_at(drop_position: Vector2) -> void:
	if health_pickup_scene == null:
		return
	var drop: Node = health_pickup_scene.instantiate()
	drop.configure(randi_range(12, 24))
	drop.global_position = drop_position + Vector2(randf_range(-34.0, 34.0), randf_range(-34.0, 34.0))
	pickups.add_child(drop)

func _advance_campaign_level() -> void:
	campaign_level += 1
	kills = 0
	enemy_health_bonus = max(enemy_health_bonus, campaign_level)
	next_signal_loss_at = elapsed + _get_signal_loss_interval()
	var level: Dictionary = campaign_levels[campaign_level]
	kills_to_win = int(level["kills"])
	spawn_timer.wait_time = float(level["spawn"])
	base_spawn_wait_time = spawn_timer.wait_time
	doomsday_active = false
	next_doomsday_at = elapsed + _get_doomsday_interval()
	upgrade_timer.wait_time = float(level["upgrades"])
	bullet_pickup_timer.wait_time = 4.2
	health_pickup_timer.wait_time = 7.2
	comet_timer.wait_time = float(level["comets"])
	for enemy in enemies.get_children():
		enemy.queue_free()
	_show_announcement(String(level["name"]), Color(0.65, 0.95, 1.0, 1.0), 1.4)
	_update_hud()

func _trigger_victory() -> void:
	victory = true
	_stop_timers()
	_finalize_run(true)
	victory_panel.visible = true
	$CanvasLayer/VictoryPanel/FinalScore.text = _build_run_summary_text("SIGNAL STABILIZED")

func _random_spawn_position(distance_from_player: float, forced_angle: float = INF) -> Vector2:
	var angle: float = forced_angle if forced_angle != INF else randf() * TAU
	return player.global_position + Vector2(cos(angle), sin(angle)) * distance_from_player

func _random_effect_id() -> String:
	var effects: Array[String] = ["inverted_controls", "slow_motion", "enemy_duplication", "wall_phase", "fake_minimap"]
	return effects.pick_random()

func _random_weapon_upgrade_id() -> String:
	var upgrades: Array[String] = ["triple_shot", "bounce_shot", "homing", "ring_fire", "orbit_disk", "reverse_shot"]
	var index: int = randi_range(0, upgrades.size() - 1)
	return upgrades[index]

func _pick_enemy_type() -> String:
	if game_mode == "debug":
		return debug_enemy_pool.pick_random()
	if game_mode == "campaign":
		var level: Dictionary = campaign_levels[campaign_level]
		var pool: Array = level["enemies"]
		return String(pool.pick_random())

	var pool: Array[String] = []
	for kind in endless_enemy_pool:
		pool.append(kind)
	if elapsed > 35.0:
		pool.append("tank")
		pool.append("shooter")
	if elapsed > 75.0:
		pool.append("tank")
		pool.append("hopper")
		pool.append("orbiter")
	if doomsday_active:
		pool.append("shooter")
		pool.append("tank")
		pool.append("sprinter")
	return pool.pick_random()



func _begin_run_tracking() -> void:
	run_finalized = false
	total_kills = 0
	highest_level_this_run = player.player_level
	doomsday_events_survived = 0
	_update_mode_panel_text()
	_update_hud()

func _get_difficulty() -> Dictionary:
	if difficulty_options.is_empty():
		return {}
	difficulty_index = clampi(difficulty_index, 0, difficulty_options.size() - 1)
	return difficulty_options[difficulty_index]

func _get_difficulty_name() -> String:
	return String(_get_difficulty().get("name", "Normal"))

func _difficulty_value(key: String, fallback: Variant) -> Variant:
	return _get_difficulty().get(key, fallback)

func _get_signal_loss_interval() -> float:
	return signal_loss_interval * float(_difficulty_value("signal_loss_multiplier", 1.0))

func _get_doomsday_interval() -> float:
	return doomsday_interval * float(_difficulty_value("doomsday_multiplier", 1.0))

func _cycle_difficulty() -> void:
	difficulty_index = (difficulty_index + 1) % difficulty_options.size()
	save_data["difficulty_index"] = difficulty_index
	_save_data()
	_update_mode_panel_text()
	_update_pause_menu()
	_update_hud()
	_show_announcement("DIFFICULTY: " + _get_difficulty_name(), Color(0.75, 0.95, 1.0, 1.0), 0.9)

func _toggle_fullscreen() -> void:
	var mode: int = DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _load_save_data() -> void:
	save_data = {
		"best_score": 0,
		"best_time": 0.0,
		"most_kills": 0,
		"highest_level": 1,
		"campaign_completed": false,
		"difficulty_index": difficulty_index
	}
	if FileAccess.file_exists(SAVE_PATH):
		var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file != null:
			var parsed: Variant = JSON.parse_string(file.get_as_text())
			if parsed is Dictionary:
				var parsed_dict: Dictionary = parsed
				save_data.merge(parsed_dict, true)
	difficulty_index = int(save_data.get("difficulty_index", difficulty_index))
	difficulty_index = clampi(difficulty_index, 0, difficulty_options.size() - 1)

func _save_data() -> void:
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Could not write save data to " + SAVE_PATH)
		return
	file.store_string(JSON.stringify(save_data, "	"))

func _finalize_run(completed: bool) -> void:
	if run_finalized:
		return
	run_finalized = true
	highest_level_this_run = max(highest_level_this_run, player.player_level)
	save_data["best_score"] = max(int(save_data.get("best_score", 0)), score)
	save_data["best_time"] = max(float(save_data.get("best_time", 0.0)), elapsed)
	save_data["most_kills"] = max(int(save_data.get("most_kills", 0)), total_kills)
	save_data["highest_level"] = max(int(save_data.get("highest_level", 1)), highest_level_this_run)
	if completed and game_mode == "campaign":
		save_data["campaign_completed"] = true
	save_data["difficulty_index"] = difficulty_index
	_save_data()

func _build_run_summary_text(result_title: String) -> String:
	var minutes: int = int(elapsed / 60.0)
	var seconds: int = int(elapsed) % 60
	var campaign_text: String = "yes" if bool(save_data.get("campaign_completed", false)) else "no"
	return "%s\n\nScore: %d\nTime survived: %02d:%02d\nKills: %d\nLevel reached: %d\nDoomsday events survived: %d\nDifficulty: %s\n\nBest score: %d\nBest time: %s\nMost kills: %d\nHighest level: %d\nCampaign completed: %s" % [
		result_title,
		score,
		minutes,
		seconds,
		total_kills,
		highest_level_this_run,
		doomsday_events_survived,
		_get_difficulty_name(),
		int(save_data.get("best_score", 0)),
		_format_time(float(save_data.get("best_time", 0.0))),
		int(save_data.get("most_kills", 0)),
		int(save_data.get("highest_level", 1)),
		campaign_text
	]

func _format_time(value: float) -> String:
	var minutes: int = int(value / 60.0)
	var seconds: int = int(value) % 60
	return "%02d:%02d" % [minutes, seconds]

func _update_mode_panel_text() -> void:
	if mode_panel == null:
		return
	var mode_text_node: Label = mode_panel.get_node_or_null("ModeText") as Label
	if mode_text_node == null:
		return
	var campaign_text: String = "yes" if bool(save_data.get("campaign_completed", false)) else "no"
	mode_text_node.text = "A corrupted arcade survival game\n\n1  ENDLESS\nEscalating enemy pressure, Signal Loss, Doomsday waves.\n\n2  CAMPAIGN\nThree short levels with increasing enemy variety.\n\n3  DEBUG ENDLESS\nAll enemy types spawn with equal probability for testing.\n\nSETTINGS\nD  Difficulty: %s\nF  Toggle fullscreen\nM  Toggle procedural music\nT  Test beep\nY  Restart music\n\nSAVED RECORDS\nBest score: %d | Best time: %s | Most kills: %d | Highest level: %d | Campaign completed: %s\n\nControls: WASD/Arrows move | Mouse aim | Hold Left Click shoot | Right Click autofire | Q cone shockwave | ESC pause" % [
		_get_difficulty_name(),
		int(save_data.get("best_score", 0)),
		_format_time(float(save_data.get("best_time", 0.0))),
		int(save_data.get("most_kills", 0)),
		int(save_data.get("highest_level", 1)),
		campaign_text
	]

func _on_weapon_upgrade_collected(upgrade_id: String) -> void:
	print("Weapon upgrade collected: ", upgrade_id)
	_update_hud()

func _on_health_changed(_health: int) -> void:
	_update_hud()

func _on_ammo_changed(_ammo: int, _max_ammo: int) -> void:
	_update_hud()

func _on_level_changed(_level: int, _xp: int, _xp_to_next: int) -> void:
	_update_hud()

func _on_ultra_changed(_charge: int, _max_charge: int) -> void:
	_update_hud()

func _on_player_died() -> void:
	game_over = true
	_stop_timers()
	_finalize_run(false)
	game_over_panel.visible = true
	$CanvasLayer/GameOverPanel/FinalScore.text = _build_run_summary_text("SIGNAL LOST")

func _on_effect_started(effect_name: String) -> void:
	print("Signal started: ", effect_name)

func _on_effect_ended(effect_name: String) -> void:
	print("Signal ended: ", effect_name)

func _show_announcement(text: String, color: Color, duration: float = 1.2) -> void:
	announcement_label.text = text
	announcement_label.modulate = color
	announcement_label.visible = true
	var local_label: Label = announcement_label
	await get_tree().create_timer(duration).timeout
	if is_instance_valid(local_label) and local_label.text == text:
		local_label.visible = false

func _update_hud() -> void:
	if player == null:
		return
	var health_ratio: float = clamp(float(player.health) / float(player.max_health), 0.0, 1.0)
	health_fill.scale.x = health_ratio
	health_text.text = "%d / %d" % [player.health, player.max_health]

	var ultra_ratio: float = clamp(float(player.ultra_charge) / float(player.ultra_max_charge), 0.0, 1.0)
	ultra_fill.scale.x = ultra_ratio
	ultra_text.text = "ULTRA %d/%d  [Q cone]" % [player.ultra_charge, player.ultra_max_charge]
	level_label.text = "Level: %d   XP: %d/%d   Bullet DMG: %d   Ammo Cap: %d   Enemy HP +%d   Difficulty: %s" % [player.player_level, player.xp, player.xp_to_next, player.get_bullet_damage(), player.max_ammo, enemy_health_bonus + int(_difficulty_value("enemy_health_bonus", 0)), _get_difficulty_name()]

	var mode_text: String = ""
	if not game_started:
		mode_text = "Choose Mode"
	elif game_mode == "campaign":
		mode_text = String(campaign_levels[campaign_level]["name"])
	elif game_mode == "debug":
		mode_text = "Debug Endless Mode"
	else:
		mode_text = "Endless Mode"
	mode_label.text = mode_text
	var kill_text: String = "%d" % total_kills if game_mode == "endless" or game_mode == "debug" else "%d/%d  Total:%d" % [kills, kills_to_win, total_kills]
	hud_label.text = "Score: %d   Kills: %s   Ammo: %d/%d   Best: %d" % [score, kill_text, player.ammo, player.max_ammo, int(save_data.get("best_score", 0))]
	var weapons: Array[String] = []
	if player.triple_shot_enabled:
		weapons.append("Triple L%d" % player.triple_shot_level)
	if player.bounce_shot_enabled:
		weapons.append("Bounce x%d" % player.bounce_count)
	if player.homing_enabled:
		weapons.append("Homing L%d" % player.homing_level)
	if player.ring_fire_enabled:
		weapons.append("Fire Ring L%d" % player.fire_ring_level)
	if player.orbit_disk_enabled:
		weapons.append("Orbit Disk L%d" % player.orbit_disk_level)
	if player.reverse_shot_enabled:
		weapons.append("Reverse L%d" % player.reverse_shot_level)
	var auto_text: String = "ON" if autoshoot_enabled else "OFF"
	var event_text: String = "   Event: DOOMSDAY" if doomsday_active else ""
	weapon_label.text = "Weapons: %s   Autoshoot: %s%s" % [(", ".join(weapons) if weapons.size() > 0 else "Basic"), auto_text, event_text]
