extends Area2D

const SpriteSheetBuilder = preload("res://scripts/sprite_sheet_builder.gd")

signal collected(upgrade_id: String)

@export_enum("triple_shot", "bounce_shot", "homing", "ring_fire", "orbit_disk", "reverse_shot") var upgrade_id: String = "triple_shot"
@export var despawn_after: float = 4.0
var despawn_started: bool = false

@onready var visual: ColorRect = $Visual
@onready var label: Label = $Label
var animated_visual: AnimatedSprite2D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if label != null:
		label.z_index = 10
	_setup_sprite()
	_update_visuals()
	_start_despawn_timer()

func _process(delta: float) -> void:
	rotation += delta * 1.8
	if animated_visual != null:
		animated_visual.position.y = sin(Time.get_ticks_msec() * 0.006) * 2.0

func _setup_sprite() -> void:
	animated_visual = SpriteSheetBuilder.build("res://assets/sprites/items/upgrade_sheet.png", Vector2i(32, 32), 4, 6.0)
	if animated_visual == null:
		return
	add_child(animated_visual)
	animated_visual.z_index = 5
	visual.visible = false

func configure(new_upgrade_id: String) -> void:
	upgrade_id = new_upgrade_id
	if is_node_ready():
		_update_visuals()

func _update_visuals() -> void:
	match upgrade_id:
		"triple_shot":
			visual.color = Color(1.0, 0.82, 0.25)
			label.text = "3"
		"bounce_shot":
			visual.color = Color(0.35, 0.9, 1.0)
			label.text = "B"
		"homing":
			visual.color = Color(0.85, 0.45, 1.0)
			label.text = "H"
		"ring_fire":
			visual.color = Color(1.0, 0.38, 0.08)
			label.text = "F"
		"orbit_disk":
			visual.color = Color(1.0, 0.95, 0.45)
			label.text = "D"
		"reverse_shot":
			visual.color = Color(0.65, 1.0, 0.55)
			label.text = "R"
		_:
			visual.color = Color.WHITE
			label.text = "?"
	if animated_visual != null:
		animated_visual.modulate = visual.color

func _on_body_entered(body: Node) -> void:
	if body.has_method("apply_weapon_upgrade"):
		body.apply_weapon_upgrade(upgrade_id)
		collected.emit(upgrade_id)
		queue_free()


func _start_despawn_timer() -> void:
	if despawn_started:
		return
	despawn_started = true
	await get_tree().create_timer(despawn_after, false).timeout
	if is_inside_tree():
		queue_free()
