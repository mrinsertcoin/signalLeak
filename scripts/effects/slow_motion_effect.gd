extends "res://scripts/effects/signal_effect.gd"

func _init() -> void:
    effect_id = "slow_motion"
    duration = 4.0

func start() -> void:
    Engine.time_scale = 0.55

func stop() -> void:
    Engine.time_scale = 1.0
