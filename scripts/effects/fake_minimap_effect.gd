extends "res://scripts/effects/signal_effect.gd"

func _init() -> void:
    effect_id = "fake_minimap"
    duration = 5.0

func start() -> void:
    if game_manager.has_node("CanvasLayer/FakePing"):
        game_manager.get_node("CanvasLayer/FakePing").visible = true

func stop() -> void:
    if game_manager.has_node("CanvasLayer/FakePing"):
        game_manager.get_node("CanvasLayer/FakePing").visible = false
