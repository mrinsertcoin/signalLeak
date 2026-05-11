extends Area2D

const SpriteSheetBuilder = preload("res://scripts/sprite_sheet_builder.gd")

var animated_visual: AnimatedSprite2D = null

signal collected(effect_id: String)

@export_enum("inverted_controls", "slow_motion", "enemy_duplication", "wall_phase", "fake_minimap") var effect_id: String = "inverted_controls"
@export var despawn_after: float = 4.0
var despawn_started: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_setup_sprite()
	_start_despawn_timer()

func _process(delta: float) -> void:
	rotation += delta * 0.8
	if animated_visual != null:
		animated_visual.position.y = sin(Time.get_ticks_msec() * 0.006) * 2.0

func _setup_sprite() -> void:
	animated_visual = SpriteSheetBuilder.build("res://assets/sprites/items/signal_sheet.png", Vector2i(32, 32), 4, 6.0)
	if animated_visual == null:
		return
	add_child(animated_visual)
	animated_visual.z_index = 6
	var fallback: CanvasItem = get_node_or_null("Visual") as CanvasItem
	if fallback != null:
		fallback.visible = false

func _on_body_entered(body: Node) -> void:
	if body.name == "Player":
		collected.emit(effect_id)
		queue_free()


func _start_despawn_timer() -> void:
	if despawn_started:
		return
	despawn_started = true
	await get_tree().create_timer(despawn_after, false).timeout
	if is_inside_tree():
		queue_free()
