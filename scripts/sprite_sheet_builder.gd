extends RefCounted

static func build(sheet_path: String, frame_size: Vector2i, frame_count: int, fps: float = 7.0, animation_name: String = "loop") -> AnimatedSprite2D:
	var texture: Texture2D = load(sheet_path)
	if texture == null:
		return null

	var frames: SpriteFrames = SpriteFrames.new()
	if not frames.has_animation(animation_name):
		frames.add_animation(animation_name)
	frames.set_animation_loop(animation_name, true)
	frames.set_animation_speed(animation_name, fps)

	for i in range(frame_count):
		var atlas: AtlasTexture = AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(Vector2(float(i * frame_size.x), 0.0), Vector2(float(frame_size.x), float(frame_size.y)))
		frames.add_frame(animation_name, atlas)

	var animated_sprite: AnimatedSprite2D = AnimatedSprite2D.new()
	animated_sprite.name = "AnimatedVisual"
	animated_sprite.sprite_frames = frames
	animated_sprite.animation = animation_name
	animated_sprite.centered = true
	animated_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	animated_sprite.play(animation_name)
	return animated_sprite
