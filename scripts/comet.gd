extends Area2D

const SpriteSheetBuilder = preload("res://scripts/sprite_sheet_builder.gd")

@export var speed: float = 170.0
@export var damage: int = 22
@export var lifetime: float = 16.0
@export var max_bounces: int = 10
@export var spin_speed: float = 3.5

var direction: Vector2 = Vector2.RIGHT
var bounces_left: int = 10
var animated_visual: AnimatedSprite2D = null

@onready var visual: CanvasItem = $Visual
@onready var inner: CanvasItem = $Inner

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	bounces_left = max_bounces
	_setup_sprite()
	await get_tree().create_timer(lifetime).timeout
	if is_inside_tree():
		queue_free()

func _setup_sprite() -> void:
	animated_visual = SpriteSheetBuilder.build("res://assets/sprites/projectiles/comet_sheet.png", Vector2i(32, 32), 4, 8.0)
	if animated_visual == null:
		return
	add_child(animated_visual)
	animated_visual.z_index = 18
	if visual != null:
		visual.visible = false
	if inner != null:
		inner.visible = false

func setup(start_position: Vector2, flight_direction: Vector2) -> void:
	global_position = start_position
	direction = flight_direction.normalized()
	rotation = randf() * TAU

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	rotation += spin_speed * delta

func _on_body_entered(body: Node) -> void:
	if body.has_method("damage"):
		body.damage(damage)
		queue_free()
		return

	if body is StaticBody2D and bounces_left > 0:
		bounces_left -= 1
		var normal: Vector2 = (global_position - body.global_position).normalized()
		if abs(normal.x) > abs(normal.y):
			normal = Vector2(sign(normal.x), 0)
		else:
			normal = Vector2(0, sign(normal.y))
		direction = direction.bounce(normal).normalized()
		global_position += direction * 22.0
		return

	if body is StaticBody2D:
		queue_free()
