extends CharacterBody2D

const SpriteSheetBuilder = preload("res://scripts/sprite_sheet_builder.gd")

signal health_changed(current_health: int)
signal died
signal shoot_requested(origin: Vector2, direction: Vector2, weapon_state: Dictionary)
signal ammo_changed(current_ammo: int, max_ammo: int)
signal level_changed(level: int, xp: int, xp_to_next: int)
signal ultra_changed(current_charge: int, max_charge: int)
signal ultra_requested(origin: Vector2, direction: Vector2, damage: int, radius: float, arc_angle: float)

@export var speed: float = 260.0
@export var max_health: int = 100
@export var shoot_cooldown: float = 0.24
@export var muzzle_distance: float = 30.0
@export var max_ammo: int = 62
@export var ammo_capacity_per_level: int = 9

@export var fire_ring_radius: float = 74.0
@export var fire_ring_damage: int = 1
@export var fire_ring_interval: float = 0.32
@export var orbit_disk_radius: float = 92.0
@export var orbit_disk_size: float = 22.0
@export var orbit_disk_damage: int = 2
@export var orbit_disk_interval: float = 0.18
@export var orbit_disk_speed: float = 3.6

@export var ultra_max_charge: int = 170
@export var ultra_charge_per_kill: int = 6
@export var ultra_radius: float = 520.0
@export var ultra_base_damage: int = 10
@export var ultra_arc_degrees: float = 90.0

var health: int
var ammo: int
var base_max_ammo: int = 80
var inverted_controls: bool = false
var wall_phase_enabled: bool = false
var last_move_direction: Vector2 = Vector2.RIGHT
var can_shoot: bool = true
var autoshoot_enabled: bool = false

var triple_shot_enabled: bool = false
var bounce_shot_enabled: bool = false
var homing_enabled: bool = false
var ring_fire_enabled: bool = false
var orbit_disk_enabled: bool = false
var reverse_shot_enabled: bool = false

var triple_shot_level: int = 0
var bounce_count: int = 0
var homing_level: int = 0
var fire_ring_level: int = 0
var orbit_disk_level: int = 0
var reverse_shot_level: int = 0

var player_level: int = 1
var xp: int = 0
var xp_to_next: int = 8
var ultra_charge: int = 0

var fire_ring_timer: float = 0.0
var orbit_disk_timer: float = 0.0
var orbit_disk_angle: float = 0.0
var fire_ring_area: Area2D = null
var orbit_disk_area: Area2D = null
var fire_ring_line: Line2D = null
var orbit_disk_visual: Polygon2D = null

@onready var sprite: CanvasItem = $Visual
var animated_visual: AnimatedSprite2D = null

func _ready() -> void:
	base_max_ammo = max_ammo
	health = max_health
	ammo = max_ammo
	health_changed.emit(health)
	ammo_changed.emit(ammo, max_ammo)
	level_changed.emit(player_level, xp, xp_to_next)
	ultra_changed.emit(ultra_charge, ultra_max_charge)
	_setup_sprite_animation()

func _physics_process(delta: float) -> void:
	var direction: Vector2 = _get_hardcoded_move_direction()
	if inverted_controls:
		direction *= -1.0
	if direction != Vector2.ZERO:
		last_move_direction = direction.normalized()

	velocity = direction * speed
	move_and_slide()
	_update_orbit_disk(delta)
	_update_visual_animation(delta, direction)

	if autoshoot_enabled or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_request_shot()

func _process(delta: float) -> void:
	_process_contact_weapons(delta)

func _get_hardcoded_move_direction() -> Vector2:
	var x_axis: float = 0.0
	var y_axis: float = 0.0

	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		x_axis -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		x_axis += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		y_axis -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		y_axis += 1.0

	var direction: Vector2 = Vector2(x_axis, y_axis)
	if direction.length() > 1.0:
		direction = direction.normalized()
	return direction

func _request_shot() -> void:
	if not can_shoot or ammo <= 0:
		return
	can_shoot = false
	ammo -= 1
	ammo_changed.emit(ammo, max_ammo)
	var aim_direction: Vector2 = _get_mouse_aim_direction()
	shoot_requested.emit(global_position, aim_direction, get_weapon_state())
	await get_tree().create_timer(shoot_cooldown).timeout
	can_shoot = true

func _get_mouse_aim_direction() -> Vector2:
	var mouse_position: Vector2 = get_global_mouse_position()
	var aim_direction: Vector2 = global_position.direction_to(mouse_position)
	if aim_direction == Vector2.ZERO:
		return last_move_direction
	return aim_direction.normalized()

func set_autoshoot(enabled: bool) -> void:
	autoshoot_enabled = enabled

func toggle_autoshoot() -> bool:
	autoshoot_enabled = not autoshoot_enabled
	return autoshoot_enabled

func get_weapon_state() -> Dictionary:
	return {
		"triple_shot": triple_shot_enabled,
		"triple_shot_level": triple_shot_level,
		"bounce_shot": bounce_shot_enabled,
		"bounce_count": bounce_count,
		"homing": homing_enabled,
		"homing_level": homing_level,
		"reverse_shot": reverse_shot_enabled,
		"reverse_shot_level": reverse_shot_level,
		"bullet_damage": get_bullet_damage(),
		"muzzle_distance": muzzle_distance
	}

func get_bullet_damage() -> int:
	return 1 + int((player_level - 1) / 4) + int(max(0, triple_shot_level - 1) / 5)

func get_contact_weapon_damage(base_damage: int, upgrade_level: int = 1) -> int:
	return base_damage + int((player_level - 1) / 5) + max(0, upgrade_level - 1)

func get_ultra_damage() -> int:
	return ultra_base_damage + player_level * 2

func apply_weapon_upgrade(upgrade_id: String) -> void:
	match upgrade_id:
		"triple_shot":
			triple_shot_enabled = true
			triple_shot_level += 1
		"bounce_shot":
			bounce_shot_enabled = true
			bounce_count = min(3, bounce_count + 1)
		"homing":
			homing_enabled = true
			homing_level += 1
		"ring_fire":
			ring_fire_enabled = true
			fire_ring_level += 1
			_ensure_fire_ring()
			_update_fire_ring_power()
		"orbit_disk":
			orbit_disk_enabled = true
			orbit_disk_level += 1
			_ensure_orbit_disk()
			_update_orbit_disk_power()
		"reverse_shot":
			reverse_shot_enabled = true
			reverse_shot_level += 1
		_:
			print("Unknown weapon upgrade: ", upgrade_id)
	print("Weapon upgrade applied: ", upgrade_id, " -> ", get_weapon_state())

func register_enemy_kill() -> bool:
	ultra_charge = min(ultra_max_charge, ultra_charge + ultra_charge_per_kill)
	ultra_changed.emit(ultra_charge, ultra_max_charge)

	xp += 1
	var leveled_up: bool = false
	while xp >= xp_to_next:
		xp -= xp_to_next
		player_level += 1
		xp_to_next = 7 + player_level * 3 + int(player_level / 2)
		leveled_up = true
	if leveled_up:
		_update_ammo_capacity_for_level()
	level_changed.emit(player_level, xp, xp_to_next)
	return leveled_up

func _update_ammo_capacity_for_level() -> void:
	var old_max_ammo: int = max_ammo
	max_ammo = base_max_ammo + (player_level - 1) * ammo_capacity_per_level
	if max_ammo > old_max_ammo:
		ammo += max_ammo - old_max_ammo
		ammo_changed.emit(ammo, max_ammo)

func try_activate_ultra() -> bool:
	if ultra_charge < ultra_max_charge or health <= 0:
		return false
	ultra_charge = 0
	ultra_changed.emit(ultra_charge, ultra_max_charge)
	ultra_requested.emit(global_position, _get_mouse_aim_direction(), get_ultra_damage(), ultra_radius, deg_to_rad(ultra_arc_degrees))
	return true

func add_ammo(amount: int) -> void:
	ammo = min(max_ammo, ammo + amount)
	ammo_changed.emit(ammo, max_ammo)

func heal(amount: int) -> void:
	if amount <= 0 or health <= 0:
		return
	health = min(max_health, health + amount)
	health_changed.emit(health)

func damage(amount: int) -> void:
	if wall_phase_enabled:
		amount = max(1, int(amount / 2))

	health = max(0, health - amount)
	health_changed.emit(health)
	_flash_hit()

	if health <= 0:
		died.emit()

func set_inverted_controls(enabled: bool) -> void:
	inverted_controls = enabled

func set_wall_phase(enabled: bool) -> void:
	wall_phase_enabled = enabled
	collision_layer = 0 if enabled else 1
	var alpha: float = 0.45 if enabled else 1.0
	sprite.modulate.a = alpha
	if animated_visual != null:
		animated_visual.modulate.a = alpha

func _process_contact_weapons(delta: float) -> void:
	if ring_fire_enabled and fire_ring_area != null:
		fire_ring_timer -= delta
		if fire_ring_timer <= 0.0:
			_damage_overlapping_enemies(fire_ring_area, get_contact_weapon_damage(fire_ring_damage, fire_ring_level))
			fire_ring_timer = max(0.12, fire_ring_interval - float(max(0, fire_ring_level - 1)) * 0.02)

	if orbit_disk_enabled and orbit_disk_area != null:
		orbit_disk_timer -= delta
		if orbit_disk_timer <= 0.0:
			_damage_overlapping_enemies(orbit_disk_area, get_contact_weapon_damage(orbit_disk_damage, orbit_disk_level))
			orbit_disk_timer = max(0.08, orbit_disk_interval - float(max(0, orbit_disk_level - 1)) * 0.012)

func _damage_overlapping_enemies(area: Area2D, amount: int) -> void:
	if area == null:
		return
	var bodies: Array[Node2D] = []
	for body in area.get_overlapping_bodies():
		if body is Node2D:
			bodies.append(body)
	for body in bodies:
		if is_instance_valid(body) and body.has_method("take_damage"):
			body.take_damage(amount)

func _ensure_fire_ring() -> void:
	if fire_ring_area != null:
		return
	fire_ring_area = Area2D.new()
	fire_ring_area.name = "FireRingDamageArea"
	fire_ring_area.collision_layer = 0
	fire_ring_area.collision_mask = 4
	fire_ring_area.monitoring = true
	add_child(fire_ring_area)

	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = fire_ring_radius
	var collision: CollisionShape2D = CollisionShape2D.new()
	collision.shape = shape
	fire_ring_area.add_child(collision)

	fire_ring_line = Line2D.new()
	fire_ring_line.name = "FireRingVisual"
	fire_ring_line.default_color = Color(1.0, 0.38, 0.08, 0.88)
	fire_ring_line.points = _make_circle_points(fire_ring_radius, 48)
	fire_ring_area.add_child(fire_ring_line)
	_update_fire_ring_power()

func _update_fire_ring_power() -> void:
	if fire_ring_line == null:
		return
	# Every extra pickup makes the belt exactly 1 pixel thicker.
	fire_ring_line.width = 5.0 + float(max(0, fire_ring_level - 1))

func _ensure_orbit_disk() -> void:
	if orbit_disk_area != null:
		return
	orbit_disk_area = Area2D.new()
	orbit_disk_area.name = "OrbitDiskDamageArea"
	orbit_disk_area.collision_layer = 0
	orbit_disk_area.collision_mask = 4
	orbit_disk_area.monitoring = true
	add_child(orbit_disk_area)

	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = orbit_disk_size
	var collision: CollisionShape2D = CollisionShape2D.new()
	collision.shape = shape
	orbit_disk_area.add_child(collision)

	orbit_disk_visual = Polygon2D.new()
	orbit_disk_visual.name = "OrbitDiskVisual"
	orbit_disk_visual.color = Color(1.0, 0.95, 0.45, 0.95)
	orbit_disk_visual.polygon = _make_circle_polygon(orbit_disk_size, 22)
	orbit_disk_area.add_child(orbit_disk_visual)
	_update_orbit_disk_power()

func _update_orbit_disk_power() -> void:
	if orbit_disk_visual == null:
		return
	var visual_radius: float = orbit_disk_size + float(max(0, orbit_disk_level - 1)) * 1.5
	orbit_disk_visual.polygon = _make_circle_polygon(visual_radius, 22)

func _update_orbit_disk(delta: float) -> void:
	if not orbit_disk_enabled or orbit_disk_area == null:
		return
	var scaled_speed: float = orbit_disk_speed + float(max(0, orbit_disk_level - 1)) * 1.15
	orbit_disk_angle += scaled_speed * delta
	orbit_disk_area.position = Vector2(cos(orbit_disk_angle), sin(orbit_disk_angle)) * orbit_disk_radius
	orbit_disk_area.rotation += (4.5 + float(orbit_disk_level) * 0.8) * delta

func _make_circle_points(radius: float, sides: int) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for i in range(sides + 1):
		var angle: float = float(i) / float(sides) * TAU
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points

func _make_circle_polygon(radius: float, sides: int) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for i in range(sides):
		var angle: float = float(i) / float(sides) * TAU
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points


func _setup_sprite_animation() -> void:
	animated_visual = SpriteSheetBuilder.build("res://assets/sprites/player/player_sheet.png", Vector2i(48, 48), 4, 7.0)
	if animated_visual == null:
		return
	add_child(animated_visual)
	animated_visual.z_index = 10
	animated_visual.position = Vector2.ZERO
	if sprite != null:
		sprite.visible = false

func _update_visual_animation(delta: float, move_direction: Vector2) -> void:
	if animated_visual == null:
		return
	var moving: bool = move_direction != Vector2.ZERO
	animated_visual.speed_scale = 1.35 if moving else 0.85
	var target_angle: float = _get_mouse_aim_direction().angle() + PI * 0.5
	if moving:
		target_angle += sin(Time.get_ticks_msec() * 0.012) * 0.08
	animated_visual.rotation = lerp_angle(animated_visual.rotation, target_angle, min(1.0, delta * 10.0))
	var pulse: float = 1.0 + sin(Time.get_ticks_msec() * 0.009) * (0.035 if moving else 0.02)
	animated_visual.scale = Vector2(pulse, pulse)

func _flash_hit() -> void:
	if sprite == null:
		return
	sprite.modulate = Color(1.0, 0.2, 0.2)
	if animated_visual != null:
		animated_visual.modulate = Color(1.0, 0.2, 0.2, animated_visual.modulate.a)
	await get_tree().create_timer(0.08).timeout
	var final_color: Color = Color(1.0, 1.0, 1.0, 0.45) if wall_phase_enabled else Color.WHITE
	sprite.modulate = final_color
	if animated_visual != null:
		animated_visual.modulate = final_color
