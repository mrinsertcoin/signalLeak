extends Area2D

const SpriteSheetBuilder = preload("res://scripts/sprite_sheet_builder.gd")

@export var heal_amount: int = 22
@export var despawn_after: float = 4.0
var despawn_started: bool = false

@onready var visual: Polygon2D = $Visual
@onready var label: Label = $Label
var animated_visual: AnimatedSprite2D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if label != null:
		label.z_index = 10
	_setup_sprite()
	_update_label()
	_start_despawn_timer()

func _process(delta: float) -> void:
	rotation += delta * 1.15
	var pulse: float = 1.0 + sin(Time.get_ticks_msec() * 0.006) * 0.08
	if visual != null:
		visual.scale = Vector2.ONE * pulse
	if animated_visual != null:
		animated_visual.scale = Vector2.ONE * pulse

func _setup_sprite() -> void:
	animated_visual = SpriteSheetBuilder.build("res://assets/sprites/items/health_sheet.png", Vector2i(32, 32), 4, 6.0)
	if animated_visual == null:
		return
	add_child(animated_visual)
	animated_visual.z_index = 5
	visual.visible = false

func configure(amount: int) -> void:
	heal_amount = amount
	if is_node_ready():
		_update_label()

func _update_label() -> void:
	if label != null:
		label.text = "+%d" % heal_amount

func _on_body_entered(body: Node) -> void:
	if body.has_method("heal"):
		body.heal(heal_amount)
		queue_free()


func _start_despawn_timer() -> void:
	if despawn_started:
		return
	despawn_started = true
	await get_tree().create_timer(despawn_after, false).timeout
	if is_inside_tree():
		queue_free()
