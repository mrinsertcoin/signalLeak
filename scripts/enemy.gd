extends CharacterBody2D

const SpriteSheetBuilder = preload("res://scripts/sprite_sheet_builder.gd")

signal killed(enemy: Node)
signal projectile_requested(origin: Vector2, direction: Vector2, damage: int)

@export var speed: float = 115.0
@export var contact_damage: int = 10
@export var max_health: int = 3

var target: Node2D
var health: int
var enemy_type: String = "chaser"
var time_alive: float = 0.0
var orbit_side: float = 1.0
var base_color: Color = Color(1.0, 0.18, 0.45, 1.0)
var desired_size: float = 36.0
var orb_position: Vector2 = Vector2.ZERO
var orbit_radius: float = 78.0
var orbit_angle: float = 0.0
var orbit_speed: float = 2.2

var shoot_range: float = 470.0
var shoot_cooldown: float = 1.15
var shoot_timer: float = 0.4
var projectile_damage: int = 9

var hop_cooldown: float = 0.72
var hop_timer: float = 0.2
var hop_duration: float = 0.18
var hop_time_left: float = 0.0
var hop_target: Vector2 = Vector2.ZERO
var is_hopping: bool = false

var animated_visual: AnimatedSprite2D = null
@onready var visual: Polygon2D = $Visual
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hitbox_shape: CollisionShape2D = $Hitbox/HitboxShape

func _ready() -> void:
	add_to_group("enemies")
	health = max_health
	orb_position = global_position
	orbit_angle = randf() * TAU
	_set_size(desired_size)
	_apply_visuals()

func configure(kind: String, level_index: int = 0, health_bonus: int = 0) -> void:
	enemy_type = kind
	orbit_side = -1.0 if randf() < 0.5 else 1.0
	match enemy_type:
		"sprinter":
			speed = 185.0 + level_index * 8.0
			max_health = 2 + int(level_index > 1)
			contact_damage = 8
			base_color = Color(1.0, 0.42, 0.12, 1.0)
			_set_size(24.0)
		"tank":
			speed = 72.0 + level_index * 5.0
			max_health = 7 + level_index
			contact_damage = 18
			base_color = Color(0.85, 0.05, 0.12, 1.0)
			_set_size(52.0)
		"zigzag":
			speed = 125.0 + level_index * 8.0
			max_health = 3 + int(level_index > 1)
			contact_damage = 11
			base_color = Color(1.0, 0.1, 0.75, 1.0)
			_set_size(34.0)
		"orbiter":
			speed = 92.0 + level_index * 5.0
			max_health = 3 + int(level_index > 1)
			contact_damage = 14
			base_color = Color(1.0, 1.0, 1.0, 1.0)
			orbit_radius = 86.0 + level_index * 8.0
			orbit_speed = 2.2 + level_index * 0.18
			_set_size(30.0)
		"satellite":
			speed = 92.0 + level_index * 5.0
			max_health = 3 + int(level_index > 1)
			contact_damage = 14
			base_color = Color(1.0, 1.0, 1.0, 1.0)
			orbit_radius = 86.0 + level_index * 8.0
			orbit_speed = 2.2 + level_index * 0.18
			_set_size(30.0)
		"shooter":
			speed = 82.0 + level_index * 5.0
			max_health = 4 + int(level_index > 0)
			contact_damage = 8
			projectile_damage = 8 + level_index
			shoot_cooldown = max(0.72, 1.18 - float(level_index) * 0.08)
			shoot_range = 500.0
			base_color = Color(0.35, 0.75, 1.0, 1.0)
			_set_size(34.0)
		"hopper":
			speed = 440.0 + level_index * 16.0
			max_health = 4 + int(level_index > 1)
			contact_damage = 16
			hop_cooldown = max(0.45, 0.72 - float(level_index) * 0.04)
			base_color = Color(0.2, 1.0, 0.35, 1.0)
			_set_size(38.0)
		_:
			speed = 115.0 + level_index * 6.0
			max_health = 3 + int(level_index > 1)
			contact_damage = 10
			base_color = Color(1.0, 0.18, 0.45, 1.0)
			_set_size(36.0)
	max_health += health_bonus
	health = max_health
	orb_position = global_position
	_apply_visuals()

func _physics_process(delta: float) -> void:
	if target == null:
		return
	time_alive += delta
	_update_visual_motion(delta)
	if enemy_type == "satellite" or enemy_type == "orbiter":
		_update_satellite_motion(delta)
		return
	if enemy_type == "shooter":
		_update_shooter_motion(delta)
		return
	if enemy_type == "hopper":
		_update_hopper_motion(delta)
		return

	var to_target: Vector2 = global_position.direction_to(target.global_position)
	var desired: Vector2 = to_target
	match enemy_type:
		"zigzag":
			var side: Vector2 = Vector2(-to_target.y, to_target.x)
			desired = (to_target + side * sin(time_alive * 5.5) * 0.85).normalized()
		_:
			desired = to_target
	velocity = desired * speed
	move_and_slide()

func _update_satellite_motion(delta: float) -> void:
	var orb_dir: Vector2 = orb_position.direction_to(target.global_position)
	orb_position += orb_dir * speed * delta
	orbit_angle += orbit_speed * orbit_side * delta
	global_position = orb_position + Vector2(cos(orbit_angle), sin(orbit_angle)) * orbit_radius
	rotation += 3.5 * delta * orbit_side

func _update_shooter_motion(delta: float) -> void:
	var to_target: Vector2 = global_position.direction_to(target.global_position)
	var distance: float = global_position.distance_to(target.global_position)
	var side: Vector2 = Vector2(-to_target.y, to_target.x) * orbit_side
	var desired: Vector2 = side
	if distance > shoot_range * 0.82:
		desired = (to_target * 0.55 + side * 0.45).normalized()
	elif distance < shoot_range * 0.48:
		desired = (-to_target * 0.75 + side * 0.35).normalized()
	velocity = desired * speed
	move_and_slide()

	shoot_timer -= delta
	if distance <= shoot_range and shoot_timer <= 0.0:
		shoot_timer = shoot_cooldown
		projectile_requested.emit(global_position, to_target, projectile_damage)

func _update_hopper_motion(delta: float) -> void:
	if is_hopping:
		var to_hop_target: Vector2 = global_position.direction_to(hop_target)
		velocity = to_hop_target * speed
		move_and_slide()
		hop_time_left -= delta
		if hop_time_left <= 0.0 or global_position.distance_to(hop_target) < 12.0:
			is_hopping = false
			velocity = Vector2.ZERO
		return

	hop_timer -= delta
	velocity = Vector2.ZERO
	if hop_timer <= 0.0:
		hop_timer = hop_cooldown
		_begin_knight_hop()

func _begin_knight_hop() -> void:
	var diff: Vector2 = target.global_position - global_position
	var sign_x: float = 1.0 if diff.x >= 0.0 else -1.0
	var sign_y: float = 1.0 if diff.y >= 0.0 else -1.0
	var variants: Array[Vector2] = [
		Vector2(160.0 * sign_x, 80.0 * sign_y),
		Vector2(80.0 * sign_x, 160.0 * sign_y)
	]
	if abs(diff.x) > abs(diff.y):
		hop_target = global_position + variants[0]
	else:
		hop_target = global_position + variants[1]
	# Occasionally choose the other L-shape so it feels less robotic.
	if randf() < 0.28:
		if abs(diff.x) > abs(diff.y):
			hop_target = global_position + variants[1]
		else:
			hop_target = global_position + variants[0]
	is_hopping = true
	hop_time_left = hop_duration

func take_damage(amount: int) -> void:
	health -= amount
	_flash()
	if health <= 0:
		killed.emit(self)
		queue_free()

func apply_health_bonus(amount: int) -> void:
	if amount <= 0 or health <= 0:
		return
	max_health += amount
	health += amount
	contact_damage += int(max(0, amount - 1) / 2)

func apply_doomsday_boost() -> void:
	apply_health_bonus(2)
	contact_damage += 2
	if enemy_type == "shooter":
		projectile_damage += 2
		shoot_cooldown = max(0.55, shoot_cooldown * 0.82)

func _set_size(size: float) -> void:
	desired_size = size
	if visual != null:
		visual.polygon = _make_enemy_polygon(size * 0.5, 14)
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = size * 0.5
	if collision_shape != null:
		collision_shape.shape = shape
	if hitbox_shape != null:
		hitbox_shape.shape = shape

func _make_enemy_polygon(radius: float, sides: int) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for i in range(sides):
		var angle: float = float(i) / float(sides) * TAU
		var wobble: float = 1.0
		if enemy_type == "tank":
			wobble = 0.92 + float(i % 2) * 0.16
		elif enemy_type == "shooter":
			wobble = 1.18 if i % 3 == 0 else 0.88
		elif enemy_type == "hopper":
			wobble = 1.25 if i % 4 == 0 else 0.82
		points.append(Vector2(cos(angle), sin(angle)) * radius * wobble)
	return points

func _apply_visuals() -> void:
	if visual == null:
		return
	visual.color = base_color
	if enemy_type == "zigzag":
		visual.rotation = 0.15
	elif enemy_type == "satellite" or enemy_type == "orbiter":
		visual.rotation = randf() * TAU
	elif enemy_type == "shooter":
		visual.rotation = 0.78
	else:
		visual.rotation = 0.0
	_setup_animated_visual()

func _setup_animated_visual() -> void:
	if not is_node_ready():
		return
	if animated_visual != null:
		animated_visual.queue_free()
		animated_visual = null
	var sprite_type: String = enemy_type
	if sprite_type == "satellite":
		sprite_type = "orbiter"
	var size: int = 48 if enemy_type == "tank" else 32
	animated_visual = SpriteSheetBuilder.build("res://assets/sprites/enemies/%s_sheet.png" % sprite_type, Vector2i(size, size), 4, 7.0)
	if animated_visual == null:
		visual.visible = true
		return
	add_child(animated_visual)
	animated_visual.z_index = 8
	visual.visible = false

func _update_visual_motion(delta: float) -> void:
	if animated_visual == null:
		return
	animated_visual.modulate = Color.WHITE
	match enemy_type:
		"sprinter":
			if velocity.length() > 0.1:
				animated_visual.rotation = lerp_angle(animated_visual.rotation, velocity.angle(), min(1.0, delta * 12.0))
			animated_visual.scale = Vector2(1.15, 0.88) if velocity.length() > 40.0 else Vector2.ONE
		"tank":
			animated_visual.rotation = sin(time_alive * 1.5) * 0.04
			animated_visual.scale = Vector2.ONE * (1.0 + sin(time_alive * 4.0) * 0.025)
		"zigzag":
			animated_visual.position = Vector2(randf_range(-1.5, 1.5), randf_range(-1.5, 1.5))
		"shooter":
			animated_visual.rotation = global_position.direction_to(target.global_position).angle() if target != null else animated_visual.rotation
		"hopper":
			animated_visual.scale = Vector2(1.15, 0.85) if is_hopping else Vector2(0.95, 1.05)
		"orbiter", "satellite":
			animated_visual.rotation += 4.0 * delta * orbit_side
		_:
			animated_visual.rotation = sin(time_alive * 5.0) * 0.08

func _flash() -> void:
	if visual == null:
		return
	visual.modulate = Color.WHITE
	if animated_visual != null:
		animated_visual.modulate = Color(1.0, 0.2, 0.2, 1.0)
	await get_tree().create_timer(0.05).timeout
	if is_inside_tree() and visual != null:
		visual.modulate = Color(1, 1, 1, 1)

func _on_hitbox_body_entered(body: Node) -> void:
	if body.has_method("damage"):
		body.damage(contact_damage)
