extends "res://scripts/effects/signal_effect.gd"

func _init() -> void:
    effect_id = "inverted_controls"
    duration = 6.0

func start() -> void:
    player.set_inverted_controls(true)

func stop() -> void:
    player.set_inverted_controls(false)
