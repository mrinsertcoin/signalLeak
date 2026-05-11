extends Area2D

const SpriteSheetBuilder = preload("res://scripts/sprite_sheet_builder.gd")

@export var speed: float = 390.0
@export var lifetime: float = 1.0
@export var damage: int = 8

var direction: Vector2 = Vector2.RIGHT
var animated_visual: AnimatedSprite2D = null

@onready var visual: CanvasItem = $Visual

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_setup_sprite()
	await get_tree().create_timer(lifetime).timeout
	if is_inside_tree():
		queue_free()

func _setup_sprite() -> void:
	animated_visual = SpriteSheetBuilder.build("res://assets/sprites/projectiles/enemy_bullet_sheet.png", Vector2i(14, 14), 4, 10.0)
	if animated_visual == null:
		return
	add_child(animated_visual)
	animated_visual.z_index = 20
	if visual != null:
		visual.visible = false

func setup(start_position: Vector2, shot_direction: Vector2, shot_damage: int) -> void:
	global_position = start_position
	direction = shot_direction.normalized()
	damage = shot_damage
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	rotation = direction.angle()

func _on_body_entered(body: Node) -> void:
	if body.has_method("damage"):
		body.damage(damage)
		queue_free()
		return
	if body is StaticBody2D:
		queue_free()
