extends "res://scripts/effects/signal_effect.gd"

func _init() -> void:
    effect_id = "enemy_duplication"
    duration = 1.0

func start() -> void:
    game_manager.duplicate_enemies()

func stop() -> void:
    pass
