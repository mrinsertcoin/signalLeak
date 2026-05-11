extends AudioStreamPlayer

# Lightweight procedural music controller.
# v15 lag fix: lower mix rate, no per-sample array allocations, fewer oscillators.
# Keeps the ambient signal-leak vibe without hammering the main thread.

@export var test_beep_path: String = "res://assets/audio/test_beep.wav"
@export var mix_rate: float = 22050.0
@export var buffer_length: float = 0.35
@export var normal_volume_db: float = -4.0
@export var doomsday_volume_db: float = -2.0
@export var start_on_ready: bool = true
@export var debug_music: bool = true

var generator_stream: AudioStreamGenerator
var generator_playback: AudioStreamGeneratorPlayback
var test_player: AudioStreamPlayer

var music_enabled: bool = true
var doomsday_mode: bool = false
var bpm: float = 78.0
var sample_index: int = 0
var master_gain: float = 0.42
var max_frames_per_process: int = 2048

var root_a: int = 36
var root_b: int = 31
var root_c: int = 34
var root_d: int = 29


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_configure_audio_output()

	bus = "Master"
	volume_db = normal_volume_db

	generator_stream = AudioStreamGenerator.new()
	generator_stream.mix_rate = mix_rate
	generator_stream.buffer_length = buffer_length
	stream = generator_stream

	test_player = AudioStreamPlayer.new()
	test_player.name = "AudioTestPlayer"
	test_player.bus = "Master"
	test_player.volume_db = 6.0
	add_child(test_player)

	if start_on_ready:
		call_deferred("start_normal")

	set_process(true)
	print("Audio hotkeys: M toggles music, T plays test beep, Y restarts music")


func _process(_delta: float) -> void:
	if music_enabled and playing:
		_fill_audio_buffer()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and not key_event.echo:
			if key_event.keycode == KEY_M:
				_toggle_music()
			elif key_event.keycode == KEY_T:
				play_test_beep()
			elif key_event.keycode == KEY_Y:
				play_music_test()


func _configure_audio_output() -> void:
	AudioServer.output_device = "Default"
	var master_index: int = AudioServer.get_bus_index("Master")
	if master_index >= 0:
		AudioServer.set_bus_mute(master_index, false)
		AudioServer.set_bus_solo(master_index, false)
		AudioServer.set_bus_bypass_effects(master_index, false)
		AudioServer.set_bus_volume_db(master_index, 0.0)


func start_normal() -> void:
	doomsday_mode = false
	bpm = 78.0
	volume_db = normal_volume_db
	master_gain = 0.42
	_start_generator_if_needed()
	if debug_music:
		print("Procedural music started: LIGHTWEIGHT AMBIENT bpm=", bpm, " mix_rate=", mix_rate)


func start_doomsday() -> void:
	doomsday_mode = true
	bpm = 96.0
	volume_db = doomsday_volume_db
	master_gain = 0.50
	_start_generator_if_needed()
	if debug_music:
		print("Procedural music started: LIGHTWEIGHT DOOMSDAY bpm=", bpm, " mix_rate=", mix_rate)


func stop_music() -> void:
	music_enabled = false
	stop()
	generator_playback = null
	if debug_music:
		print("Procedural music stopped")


func play_test_beep() -> void:
	if test_player == null:
		return
	var beep_stream: AudioStream = load(test_beep_path) as AudioStream
	if beep_stream == null:
		push_warning("Test beep missing or could not be loaded: " + test_beep_path)
		return
	test_player.stream = beep_stream
	test_player.play(0.0)
	print("TEST BEEP playing")


func play_music_test() -> void:
	sample_index = 0
	start_normal()
	print("Y pressed: lightweight procedural music restarted")


func _toggle_music() -> void:
	if music_enabled and playing:
		stop_music()
	else:
		music_enabled = true
		start_normal()


func _start_generator_if_needed() -> void:
	music_enabled = true
	if stream == null:
		stream = generator_stream
	if not playing:
		play(0.0)
	var playback: AudioStreamPlayback = get_stream_playback()
	generator_playback = playback as AudioStreamGeneratorPlayback
	if generator_playback == null:
		push_warning("Could not obtain AudioStreamGeneratorPlayback")
		return
	_fill_audio_buffer()


func _fill_audio_buffer() -> void:
	if generator_playback == null:
		var playback: AudioStreamPlayback = get_stream_playback()
		generator_playback = playback as AudioStreamGeneratorPlayback
		if generator_playback == null:
			return

	var frames_available: int = generator_playback.get_frames_available()
	if frames_available <= 0:
		return

	# Safety cap prevents one bad frame from generating a huge amount of audio on the main thread.
	var frames_to_push: int = min(frames_available, max_frames_per_process)
	for _i in range(frames_to_push):
		generator_playback.push_frame(_next_frame())


func _next_frame() -> Vector2:
	var t: float = float(sample_index) / mix_rate
	var beat: float = t * bpm / 60.0
	var bar_beat: float = fmod(beat, 4.0)
	var phrase_beat: float = fmod(beat, 16.0)

	var root: int = _current_root(beat)
	if doomsday_mode:
		root -= 2

	var root_hz: float = _midi_to_hz(root)

	# Ambient pad/drone: only a few oscillators, deliberately cheap.
	var slow_lfo: float = 0.72 + 0.28 * sin(TAU * 0.045 * t)
	var pad_a: float = sin(TAU * _midi_to_hz(root + 12) * t) * 0.10 * slow_lfo
	var pad_b: float = sin(TAU * _midi_to_hz(root + 19) * t + 0.9) * 0.075
	var drone: float = sin(TAU * root_hz * 0.5 * t) * 0.14

	# Sparse beat.
	var kick_env: float = max(_env(bar_beat, 0.0, 0.18, 4.0), _env(bar_beat, 2.5, 0.18, 4.0))
	if doomsday_mode:
		kick_env = max(kick_env, _env(bar_beat, 1.5, 0.15, 4.0))
	var kick: float = sin(TAU * (42.0 + kick_env * 55.0) * t) * kick_env * 0.85

	var snare_env: float = _env(bar_beat, 2.0, 0.14, 4.0)
	if doomsday_mode:
		snare_env = max(snare_env, _env(bar_beat, 3.0, 0.11, 4.0))
	var snare: float = _noise(sample_index * 9 + 21) * snare_env * 0.25

	var hat_env: float = _hat_env(beat)
	var hat: float = _noise(sample_index * 17 + 5) * hat_env * 0.055

	# Signal tones: sparse pings, no trigger arrays.
	var ping: Vector2 = _light_signal_ping(t, phrase_beat, root)

	# Rare glitch texture.
	var glitch: float = 0.0
	if phrase_beat > 15.35 or (doomsday_mode and phrase_beat > 13.45):
		glitch = _noise(sample_index * 31) * _env(fmod(beat * 8.0, 1.0), 0.0, 0.16, 1.0) * 0.09

	var left: float = pad_a + pad_b * 0.65 + drone + kick + snare + hat + ping.x + glitch
	var right: float = pad_a * 0.8 + pad_b + drone * 0.9 + kick + snare * 0.82 + hat * 0.9 + ping.y - glitch * 0.65

	left = tanh(left * master_gain * 1.25)
	right = tanh(right * master_gain * 1.25)

	sample_index += 1
	return Vector2(clamp(left, -0.9, 0.9), clamp(right, -0.9, 0.9))


func _current_root(beat: float) -> int:
	var chord_step: int = int(floor(fmod(beat / 4.0, 4.0)))
	if chord_step == 0:
		return root_a
	if chord_step == 1:
		return root_b
	if chord_step == 2:
		return root_c
	return root_d


func _light_signal_ping(t: float, phrase_beat: float, root: int) -> Vector2:
	var e1: float = _env(phrase_beat, 1.25, 0.34, 16.0)
	var e2: float = _env(phrase_beat, 5.5, 0.34, 16.0)
	var e3: float = _env(phrase_beat, 9.75, 0.34, 16.0)
	var e4: float = _env(phrase_beat, 14.25, 0.34, 16.0)
	if doomsday_mode:
		e1 = max(e1, _env(phrase_beat, 3.25, 0.25, 16.0))
		e3 = max(e3, _env(phrase_beat, 11.25, 0.25, 16.0))

	var mix_l: float = 0.0
	var mix_r: float = 0.0
	mix_l += _ping_wave(t, root + 36, e1) * 0.7
	mix_r += _ping_wave(t, root + 43, e1) * 0.45
	mix_l += _ping_wave(t, root + 48, e2) * 0.35
	mix_r += _ping_wave(t, root + 43, e2) * 0.75
	mix_l += _ping_wave(t, root + 55, e3) * 0.55
	mix_r += _ping_wave(t, root + 60, e3) * 0.65
	mix_l += _ping_wave(t, root + 67, e4) * 0.45
	mix_r += _ping_wave(t, root + 60, e4) * 0.50
	return Vector2(mix_l, mix_r)


func _ping_wave(t: float, midi_note: int, env_value: float) -> float:
	if env_value <= 0.0:
		return 0.0
	var freq: float = _midi_to_hz(midi_note)
	return sin(TAU * freq * t + sin(TAU * freq * 0.125 * t) * 0.7) * env_value * 0.18


func _hat_env(beat: float) -> float:
	var phrase: float = fmod(beat, 16.0)
	if not doomsday_mode and phrase > 12.0:
		return 0.0
	var local: float = fmod(beat * 2.0, 1.0)
	if local > 0.12:
		return 0.0
	var pulse_index: int = int(floor(beat * 2.0))
	if not doomsday_mode and pulse_index % 4 == 1:
		return 0.0
	return pow(max(0.0, 1.0 - local / 0.12), 3.0)


func _env(position: float, trigger: float, length: float, cycle: float) -> float:
	var distance: float = position - trigger
	if distance < 0.0:
		distance += cycle
	if distance > length:
		return 0.0
	var normalized: float = distance / max(0.001, length)
	return pow(max(0.0, 1.0 - normalized), 2.5)


func _midi_to_hz(note: int) -> float:
	return 440.0 * pow(2.0, (float(note) - 69.0) / 12.0)


func _noise(seed_value: int) -> float:
	var n: int = seed_value
	n = (n << 13) ^ n
	var value: int = (n * (n * n * 15731 + 789221) + 1376312589) & 2147483647
	return 1.0 - float(value) / 1073741824.0
