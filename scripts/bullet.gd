extends Area2D

const SpriteSheetBuilder = preload("res://scripts/sprite_sheet_builder.gd")

@export var speed: float = 760.0
@export var lifetime: float = 1.4
@export var damage: int = 1
@export var homing_strength: float = 2.2
@export var homing_speed_multiplier: float = 0.62

var direction: Vector2 = Vector2.RIGHT
var bounce_remaining: int = 0
var homing_enabled: bool = false
var homing_level: int = 0
var enemies_group_path: NodePath = NodePath("../Enemies")
var animated_visual: AnimatedSprite2D = null

@onready var visual: CanvasItem = $Visual

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_setup_sprite()
	await get_tree().create_timer(lifetime).timeout
	if is_inside_tree():
		queue_free()

func _setup_sprite() -> void:
	animated_visual = SpriteSheetBuilder.build("res://assets/sprites/projectiles/player_bullet_sheet.png", Vector2i(12, 12), 4, 12.0)
	if animated_visual == null:
		return
	add_child(animated_visual)
	animated_visual.z_index = 20
	if visual != null:
		visual.visible = false

func setup(start_position: Vector2, shot_direction: Vector2, weapon_state: Dictionary) -> void:
	global_position = start_position
	direction = shot_direction.normalized()
	rotation = direction.angle()
	damage = int(weapon_state.get("bullet_damage", damage))
	bounce_remaining = int(weapon_state.get("bounce_count", 0)) if bool(weapon_state.get("bounce_shot", false)) else 0
	homing_enabled = bool(weapon_state.get("homing", false))
	homing_level = int(weapon_state.get("homing_level", 0))
	if homing_enabled:
		var speed_penalty: float = max(0.42, homing_speed_multiplier + float(homing_level - 1) * 0.05)
		speed *= speed_penalty
		homing_strength += float(max(0, homing_level - 1)) * 0.35
		modulate = Color(0.9, 0.65, 1.0)
	elif bounce_remaining > 0:
		modulate = Color(0.55, 0.9, 1.0)

func _physics_process(delta: float) -> void:
	if homing_enabled:
		_apply_homing(delta)
	global_position += direction.normalized() * speed * delta
	rotation = direction.angle()

func _apply_homing(delta: float) -> void:
	var target: Node2D = _find_nearest_enemy()
	if target == null:
		return
	var desired: Vector2 = (target.global_position - global_position).normalized()
	direction = direction.normalized().lerp(desired, homing_strength * delta).normalized()

func _find_nearest_enemy() -> Node2D:
	var enemies: Array = get_tree().get_nodes_in_group("enemies")
	var nearest: Node2D = null
	var nearest_distance: float = INF
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var dist: float = global_position.distance_squared_to(enemy.global_position)
		if dist < nearest_distance:
			nearest_distance = dist
			nearest = enemy
	return nearest

func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
		return

	if body is StaticBody2D and bounce_remaining > 0:
		bounce_remaining -= 1
		var normal: Vector2 = (global_position - body.global_position).normalized()
		if abs(normal.x) > abs(normal.y):
			normal = Vector2(sign(normal.x), 0)
		else:
			normal = Vector2(0, sign(normal.y))
		direction = direction.bounce(normal).normalized()
		global_position += direction * 12.0
		return

	if body is StaticBody2D:
		queue_free()
