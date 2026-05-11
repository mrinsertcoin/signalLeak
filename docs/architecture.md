# Signal Leak Architecture

Signal Leak is a small Godot 4 arcade-survival game built around modular gameplay systems rather than a single monolithic script. The project is intentionally lightweight so it can be cloned, opened, inspected, and exported quickly.

## Core Game Loop

1. The player starts in Endless, Campaign, or Debug Endless mode.
2. Enemies spawn around the player and scale over time.
3. The player kills enemies to gain XP, level up, charge the ultra attack, and collect drops.
4. Signal Loss events increase enemy health.
5. Doomsday events temporarily increase enemy strength and spawn pressure.
6. A run ends in death, campaign completion, or manual restart.

## Scene Structure

The main scene contains persistent world containers:

- `Player` — movement, shooting, upgrades, health, level, ultra state.
- `Enemies` — runtime enemy instances.
- `Pickups` — ammo, health, signal, and weapon upgrade drops.
- `Bullets` / `EnemyBullets` — projectile containers.
- `Comets` — slow moving obstacle-bouncing hazards.
- `WorldGenerator` — procedural obstacles around the player.
- `SignalBackground` — low-cost ominous procedural background.
- `MusicPlayer` — procedural audio generator.
- `CanvasLayer` — HUD, title, pause, and run-summary UI.

## Player System

`player.gd` owns player-local state:

- health and damage handling
- hard-coded movement input
- mouse aiming and shooting
- ammo capacity scaling
- weapon upgrade levels
- fire ring and orbit disk contact damage
- XP and level progression
- directional 90-degree ultra shockwave activation

The player emits signals such as `shoot_requested`, `died`, `level_changed`, and `ultra_requested`. `game_manager.gd` listens to these signals and spawns bullets, updates the HUD, or finalizes the run.

## Enemy System

Enemies share one scene and one script, but each enemy type has different configuration and movement behavior:

- Chaser: direct pressure unit.
- Sprinter: fast aggressive unit.
- Tank: high-health slow enemy.
- Zigzag: unstable lateral movement.
- Shooter: ranged unit that fires temporary enemy bullets.
- Orbiter/Satellite: circular enemy orbiting an invisible target point that tracks the player.
- Hopper: chess-knight-style jumping enemy.

This keeps the repository compact while still demonstrating AI/state variation.

## Weapon Upgrade System

Weapon upgrades are stackable. If the player already owns an upgrade, another pickup increases that upgrade's level instead of doing nothing.

Examples:

- Triple Shot adds wider shot patterns at higher levels.
- Bounce Shot increases bounce count up to a maximum.
- Homing adds guided projectile behavior.
- Fire Ring gets one pixel thicker per extra pickup.
- Orbit Disk rotates faster with upgrades.
- Reverse Shot adds backward fire patterns.

## Difficulty and Progression

The game includes three difficulty presets:

- Casual
- Normal
- Signal Collapse

Difficulty affects spawn pressure, active enemy cap, enemy health bonuses, Signal Loss timing, Doomsday timing, and drop generosity.

Enemy pressure also scales over time through:

- decreasing spawn interval
- increasing active enemy cap
- Signal Loss health increases
- Doomsday wave events

## Save System

Local highscores are written to:

```text
user://signal_leak_save.json
```

Tracked values include:

- best score
- best survival time
- most kills
- highest level
- campaign completion
- selected difficulty preset

This demonstrates basic persistence and JSON file handling without requiring an external backend.

## Procedural Audio

The music system uses `AudioStreamGenerator` instead of imported music files. This avoids WAV import/playback issues and demonstrates real-time procedural audio generation.

The controller generates:

- ambient pad/drone layers
- sparse beats
- signal-like pings
- more intense Doomsday patterns

The implementation was optimized in v15 by lowering the mix rate, reducing oscillator count, and capping generated frames per process tick.

## Performance Considerations

The project avoids heavy dependencies and expensive runtime systems. Performance-sensitive decisions include:

- lightweight procedural audio
- reduced background redraw rate
- reused single enemy scene with type-based behavior
- simple collision and damage systems
- no external plugins

## Portfolio Relevance

This repository demonstrates:

- Godot 4 project structure
- modular gameplay scripting
- signal-based system communication
- AI behavior variants
- procedural generation
- local JSON persistence
- UI/HUD work
- runtime audio generation
- balancing and difficulty systems
- export-ready PC game development
