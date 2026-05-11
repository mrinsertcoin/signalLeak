extends Node

signal effect_started(effect_id: String)
signal effect_ended(effect_id: String)

const InvertedControlsEffect = preload("res://scripts/effects/inverted_controls_effect.gd")
const SlowMotionEffect = preload("res://scripts/effects/slow_motion_effect.gd")
const EnemyDuplicationEffect = preload("res://scripts/effects/enemy_duplication_effect.gd")
const WallPhaseEffect = preload("res://scripts/effects/wall_phase_effect.gd")
const FakeMinimapEffect = preload("res://scripts/effects/fake_minimap_effect.gd")

@export var player_path: NodePath
@export var manager_path: NodePath

var active_effects: Array = []

func activate_effect(effect_id: String) -> void:
    var effect = _create_effect(effect_id)
    if effect == null:
        push_warning("Unknown signal effect: %s" % effect_id)
        return

    effect.player = get_node(player_path)
    effect.game_manager = get_node(manager_path)
    active_effects.append(effect)
    effect_started.emit(effect_id)
    effect.start()
    _end_later(effect)

func active_effect_count() -> int:
    return active_effects.size()

func _create_effect(effect_id: String):
    match effect_id:
        "inverted_controls":
            return InvertedControlsEffect.new()
        "slow_motion":
            return SlowMotionEffect.new()
        "enemy_duplication":
            return EnemyDuplicationEffect.new()
        "wall_phase":
            return WallPhaseEffect.new()
        "fake_minimap":
            return FakeMinimapEffect.new()
        _:
            return null

func _end_later(effect) -> void:
    await get_tree().create_timer(effect.duration).timeout
    if effect in active_effects:
        effect.stop()
        active_effects.erase(effect)
        effect_ended.emit(effect.effect_id)
