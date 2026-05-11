# Signal Leak Devlog

## Prototype goals

- Top-down movement
- Enemy chasing behavior
- Health and score loop
- Signal pickups with modular temporary effects
- Lightweight cyberpunk presentation

## Current milestone

Playable prototype skeleton with clean scene and script structure.

## v3 - Weapon upgrades and comet hazards

Added stackable weapon upgrades:
- Triple Shot: fires three bullets in a spread.
- Bounce Shot: bullets bounce off obstacles, up to 3 bounces.
- Homing: bullets fly slower but curve toward nearby enemies.

Also added:
- custom polygon obstacles with generated visual detail lines
- slow comet hazards that cross the screen, bounce off obstacles, and damage the player
- HUD weapon readout

## v5 - Modes, Health, Enemy Variety
- Added a visible health bar.
- Added mode selection: Endless and Campaign.
- Added three campaign levels with escalating kill objectives.
- Added enemy archetypes: chaser, sprinter, tank, zigzag, orbiter.
- Improved procedural obstacles with denser polygon detail.

## v6 - Ammo, Spinning Comets, Satellite Enemies

- Comets now use a simple circle-like polygon body and spin while flying.
- Removed comet trail visuals to keep the shape readable and cleaner.
- Added ammo/bullet economy: shooting consumes ammo, green bullet drops refill it.
- Bullet drops spawn periodically and can also drop from killed enemies.
- Added a satellite enemy archetype: a circular enemy orbits an invisible/intangible orb that moves toward the player.
- Added satellite enemies to endless escalation and campaign level 3.

## v7

- Made the invisible-orb enemy easier to encounter by spawning a bright-white orbiter at the start of Endless and Campaign.
- Updated orbiter movement so the visible enemy circles an invisible, intangible target orb that tracks the player.
- Added two combinable close-range weapon upgrades:
  - Fire Ring: circular aura around the player that damages touching enemies.
  - Orbit Disk: rotating disk around the player that damages enemies on contact.
- Expanded random weapon-upgrade pool to include Fire Ring and Orbit Disk.
- Added practical workflow notes for replacing files in the same Godot project instead of importing a new project every time.


## v8 - Health & Hard Mouse Controls

- Added health pickup scene and script.
- Health pickups periodically spawn and can also drop from defeated enemies.
- Movement now uses hard-coded WASD/arrow-key checks instead of relying on the Godot Input Map.
- Shooting now uses hard-coded left mouse hold.
- Right mouse button toggles autofire directly during gameplay.
- Pause text and HUD control hint updated.

## v9 - Power Bar, Ultra Attack, Leveling, Scaling

- Added a blue ultra/power bar.
- Enemy kills charge the ultra bar.
- Press `Q` when fully charged to fire a large shockwave from the player.
- The shockwave expands outward and heavily damages enemies in its radius.
- Added a player leveling system bound to enemy kills.
- Bullet damage now scales with player level.
- Contact weapons also gain modest damage scaling.
- Enemy health increases over time.
- Added in-game announcements for difficulty scaling: `SIGNAL LOSS DETECTED`.
- HUD now displays level, XP progress, bullet damage, ultra charge, and enemy health bonus.

## v10 - Stacking Arsenal + New Enemy Events

- Weapon pickups now stack instead of only unlocking once.
- Fire Ring gets exactly 1 pixel thicker per additional pickup.
- Orbit Disk spins faster with each additional pickup.
- Triple Shot, Homing, Fire Ring, Orbit Disk, and Reverse Shot all have visible levels in the HUD.
- Added Reverse Shot upgrade: fires backward shots, with wider reverse spread at higher levels.
- Player ammo capacity now increases with player level.
- Added Shooter enemy: keeps range and fires blue projectiles that disappear after 1 second.
- Added Hopper enemy: performs chess-knight-style L-shaped hops toward the player.
- Added Doomsday event: announces DOOMSDAY, boosts enemies, and increases spawn rate for 15 seconds.

## v11 - Pixel Sprite Pass

Added a lightweight pixel-art sprite and animation system:

- generated pixel sprite sheets for player, enemies, and item boxes
- added `SpriteSheetBuilder` utility for runtime `AnimatedSprite2D` creation
- player now has a pulsing/glitchy animated sprite and aims/leans toward mouse direction
- enemies now use distinct animated sprites while keeping polygon fallbacks
- pickups now use animated pixel-art boxes
- procedural fallback visuals remain in the scenes, so the game still runs if assets are missing

Current sprite sheets live in:

```text
assets/sprites/player/
assets/sprites/enemies/
assets/sprites/items/
```

## v12 - Projectile Sprites, Debug Mode, Doomsday Waves, Ominous Background

- Added pixel-art spritesheets for player bullets, enemy bullets, and comets.
- Comets now use an animated spinning corrupted-circle sprite.
- Player and enemy bullets now use flickering projectile sprites.
- Added a procedural ominous Signal Leak background with drifting grid, signal rings, glitch packets, and a shadow-eclipse motif.
- Doomsday now spawns an immediate wave of enemies instead of only changing stats.
- Doomsday wave size scales with elapsed time and temporarily increases spawn pressure.
- Endless enemy pressure now increases over time through lower spawn interval and higher active enemy cap.
- Tanks and shooters appear earlier and more reliably in Endless and Campaign.
- Added Debug Endless mode on key `3`: behaves like Endless, but all enemy types spawn with equal probability.

## v13 - Balance, Pickup Despawn, Directional Ultra, Title/Menu Polish, Prototype Music

- Pickups now despawn after 4 seconds if not collected.
- Leveling is slower: the initial XP requirement is higher and later levels require more kills.
- Ultra charge takes much longer to fill.
- Basic shooting is slightly slower and early-game enemy health is higher, making the starting weapon less dominant.
- Ammo starts lower, but ammo capacity still increases with player level.
- Enemy pressure is stronger over time: Signal Loss happens sooner, active enemy cap grows faster, and Doomsday waves are larger.
- Ultra changed from a full circular shockwave to a directional 90° cone shockwave aimed toward the mouse.
- Pause menu now lists all important controls.
- Title screen was reworked with subtitle, cleaner mode descriptions, and control summary.
- Added generated placeholder music loops:
  - `assets/audio/signal_leak_loop.wav`
  - `assets/audio/signal_leak_doomsday_loop.wav`
- Added `scripts/music_controller.gd` to switch between normal and Doomsday music.


## Audio hotfix

Music now starts on the title screen and uses a higher default volume. If no music is audible, check the Godot Output panel for `Music playing:` or audio loading warnings.


## v13 audiofix5

- Replaced WAV music playback with a procedural `AudioStreamGenerator` music engine.
- `T` still plays the known-good test beep.
- `Y` restarts generated music.
- `M` toggles generated music.
- Normal and Doomsday music now switch via synthesis instead of external music files.


## v14 - Ambient Procedural Music Pass

- Reworked `scripts/music_controller.gd` after the first procedural version felt too fast and monotonous.
- Lowered normal music tempo to 96 BPM and Doomsday tempo to 118 BPM.
- Added evolving ambient pad/drone layers.
- Reduced constant percussion and replaced it with a sparser beat.
- Added intermittent signal/chirp tones throughout the loop.
- Kept the working `AudioStreamGenerator` approach, so no imported music file is required.
- `M`, `Y`, and `T` audio debug hotkeys remain available.

## v15 - Lag Fix

- Replaced the heavy v14 procedural music generator with a lightweight version.
- Reduced audio mix rate to 22.05 kHz for lower CPU cost.
- Removed per-sample array allocations from the music code.
- Added a safety cap for generated audio frames per process tick.
- Reduced procedural background redraw rate to 18 FPS.
- Reduced background grid/ring/packet density.
- Kept the ambient signal-tone music direction without the v14 performance spike.

## v16 - GitHub / CV Polish Update

Focus: turn the prototype into a cleaner portfolio project rather than only adding more gameplay chaos.

Added:

- Title-screen difficulty selection with `D`.
- Difficulty presets: Casual, Normal, Signal Collapse.
- Fullscreen toggle with `F`.
- Local JSON save/highscore system via `user://signal_leak_save.json`.
- Run summary screen after death or campaign completion.
- Saved records: best score, best time, most kills, highest level, campaign completion.
- Improved pause menu with all important controls and debug/audio hotkeys.
- Title screen now displays saved records and selected difficulty.
- Difficulty now affects spawn pressure, active enemy cap, enemy health, Signal Loss timing, Doomsday timing, and drop rates.
- Added `docs/architecture.md`.
- Added `docs/release_checklist.md`.
- Added screenshot placeholder folder.
- Rewrote README for GitHub/CV presentation.

Reasoning:

The project already had enough gameplay systems. v16 focuses on polish, persistence, documentation, and release readiness so the repository is easier to understand and stronger as a CV artifact.
