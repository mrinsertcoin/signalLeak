extends StaticBody2D

@onready var polygon: Polygon2D = $Polygon2D
@onready var collision_polygon: CollisionPolygon2D = $CollisionPolygon2D
@onready var detail_lines: Node2D = $DetailLines

func setup(size: Vector2) -> void:
	var points: Array[Vector2] = _make_rock_polygon(size)
	polygon.polygon = PackedVector2Array(points)
	collision_polygon.polygon = PackedVector2Array(points)
	polygon.color = Color(randf_range(0.045, 0.10), randf_range(0.08, 0.16), randf_range(0.18, 0.32), 1.0)
	rotation = randf_range(-0.25, 0.25)
	_make_detail_lines(points)
	_make_core_glow(points)

func _make_rock_polygon(size: Vector2) -> Array[Vector2]:
	var points: Array[Vector2] = []
	var count: int = randi_range(7, 13)
	for i in range(count):
		var angle: float = TAU * float(i) / float(count)
		var wobble: float = randf_range(0.62, 1.22)
		points.append(Vector2(cos(angle) * size.x * 0.5 * wobble, sin(angle) * size.y * 0.5 * wobble))
	return points

func _make_detail_lines(points: Array[Vector2]) -> void:
	for child in detail_lines.get_children():
		child.queue_free()
	var line_count: int = randi_range(4, 7)
	for i in range(line_count):
		var line: Line2D = Line2D.new()
		line.width = randf_range(1.0, 2.2)
		line.default_color = Color(0.18, 0.38, 0.55, 0.62)
		line.add_point(points.pick_random() * randf_range(0.10, 0.45))
		line.add_point(points.pick_random() * randf_range(0.35, 0.92))
		detail_lines.add_child(line)

func _make_core_glow(points: Array[Vector2]) -> void:
	var core: Polygon2D = Polygon2D.new()
	var core_points: Array[Vector2] = []
	for point in points:
		core_points.append(point * randf_range(0.18, 0.32))
	core.polygon = PackedVector2Array(core_points)
	core.color = Color(0.05, 0.65, 0.85, 0.18)
	detail_lines.add_child(core)
