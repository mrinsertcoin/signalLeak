extends Node2D

@export var obstacle_scene: PackedScene
@export var player_path: NodePath
@export var chunk_size: int = 900
@export var render_radius: int = 2
@export var obstacles_per_chunk: int = 6

var player: Node2D
var generated_chunks: Dictionary = {}

func _ready() -> void:
	player = get_node(player_path)

func _process(_delta: float) -> void:
	if player == null:
		return
	_generate_around_player()

func _generate_around_player() -> void:
	var current: Vector2i = Vector2i(floori(player.global_position.x / chunk_size), floori(player.global_position.y / chunk_size))
	for x in range(current.x - render_radius, current.x + render_radius + 1):
		for y in range(current.y - render_radius, current.y + render_radius + 1):
			var coord: Vector2i = Vector2i(x, y)
			if not generated_chunks.has(coord):
				_generate_chunk(coord)

func _generate_chunk(coord: Vector2i) -> void:
	generated_chunks[coord] = true
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash(str(coord.x) + ":" + str(coord.y))
	for i in range(obstacles_per_chunk):
		if obstacle_scene == null:
			return
		var obstacle: Node = obstacle_scene.instantiate()
		var pos: Vector2 = Vector2(
			coord.x * chunk_size + rng.randf_range(90, chunk_size - 90),
			coord.y * chunk_size + rng.randf_range(90, chunk_size - 90)
		)
		if pos.distance_to(Vector2(640, 360)) < 360.0:
			continue
		obstacle.global_position = pos
		add_child(obstacle)
		if obstacle.has_method("setup"):
			obstacle.setup(Vector2(rng.randf_range(75, 210), rng.randf_range(55, 160)))
