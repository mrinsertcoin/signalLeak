extends Node2D

# Ominous procedural background.
# v15 lag fix: redraws at a capped rate and uses fewer line/circle segments.

@export var player_path: NodePath
@export var grid_spacing: float = 128.0
@export var draw_radius: Vector2 = Vector2(1500.0, 950.0)
@export var redraw_fps: float = 18.0

var player: Node2D = null
var time_alive: float = 0.0
var redraw_accumulator: float = 0.0

func _ready() -> void:
	z_index = -90
	if player_path != NodePath(""):
		player = get_node_or_null(player_path) as Node2D
	set_process(true)

func _process(delta: float) -> void:
	time_alive += delta
	redraw_accumulator += delta
	var redraw_interval: float = 1.0 / max(1.0, redraw_fps)
	if redraw_accumulator >= redraw_interval:
		redraw_accumulator = 0.0
		queue_redraw()

func _draw() -> void:
	var center: Vector2 = Vector2.ZERO
	if player != null:
		center = player.global_position

	_draw_void(center)
	_draw_grid(center)
	_draw_signal_rings(center)
	_draw_leaking_packets(center)
	_draw_shadow_eclipse(center)

func _draw_void(center: Vector2) -> void:
	var rect: Rect2 = Rect2(center - draw_radius, draw_radius * 2.0)
	draw_rect(rect, Color(0.008, 0.012, 0.022, 1.0), true)

func _draw_grid(center: Vector2) -> void:
	var start_x: float = floor((center.x - draw_radius.x) / grid_spacing) * grid_spacing
	var end_x: float = center.x + draw_radius.x
	var start_y: float = floor((center.y - draw_radius.y) / grid_spacing) * grid_spacing
	var end_y: float = center.y + draw_radius.y
	var offset: float = sin(time_alive * 0.18) * 8.0
	var grid_color: Color = Color(0.05, 0.32, 0.42, 0.12)
	var x: float = start_x
	while x <= end_x:
		draw_line(Vector2(x + offset, center.y - draw_radius.y), Vector2(x + offset, center.y + draw_radius.y), grid_color, 1.0)
		x += grid_spacing
	var y: float = start_y
	while y <= end_y:
		draw_line(Vector2(center.x - draw_radius.x, y - offset), Vector2(center.x + draw_radius.x, y - offset), grid_color, 1.0)
		y += grid_spacing

func _draw_signal_rings(center: Vector2) -> void:
	var ring_center: Vector2 = center + Vector2(sin(time_alive * 0.11) * 80.0, cos(time_alive * 0.09) * 55.0)
	for i in range(3):
		var radius: float = 320.0 + float(i) * 230.0 + fmod(time_alive * 14.0, 110.0)
		var alpha: float = 0.09 - float(i) * 0.018
		var color: Color = Color(0.08, 0.85, 1.0, max(0.018, alpha))
		_draw_circle_outline(ring_center, radius, color, 1.5)

func _draw_leaking_packets(center: Vector2) -> void:
	for i in range(28):
		var seed_value: float = float(i) * 97.331
		var px: float = center.x - draw_radius.x + fmod(seed_value * 31.0 + time_alive * (8.0 + float(i % 5) * 2.0), draw_radius.x * 2.0)
		var py: float = center.y - draw_radius.y + fmod(seed_value * 17.0 + sin(time_alive * 0.35 + seed_value) * 75.0, draw_radius.y * 2.0)
		var size: float = 3.0 + float(i % 3)
		var cyan: bool = i % 3 != 0
		var color: Color = Color(0.0, 0.9, 1.0, 0.18) if cyan else Color(1.0, 0.06, 0.72, 0.15)
		draw_rect(Rect2(Vector2(px, py), Vector2(size, size)), color, true)

func _draw_shadow_eclipse(center: Vector2) -> void:
	var pos: Vector2 = center + Vector2(cos(time_alive * 0.045) * 380.0, sin(time_alive * 0.038) * 240.0)
	_draw_circle_outline(pos, 340.0, Color(0.55, 0.0, 0.45, 0.045), 8.0)
	_draw_circle_outline(pos, 230.0, Color(0.0, 0.88, 1.0, 0.035), 3.0)
	_draw_circle_outline(pos, 110.0, Color(1.0, 1.0, 1.0, 0.02), 1.5)

func _draw_circle_outline(center: Vector2, radius: float, color: Color, width: float) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	var sides: int = 48
	for i in range(sides + 1):
		var angle: float = float(i) / float(sides) * TAU
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	draw_polyline(points, color, width)
