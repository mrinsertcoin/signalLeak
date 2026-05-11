extends "res://scripts/effects/signal_effect.gd"

func _init() -> void:
    effect_id = "wall_phase"
    duration = 5.0

func start() -> void:
    player.set_wall_phase(true)

func stop() -> void:
    player.set_wall_phase(false)
