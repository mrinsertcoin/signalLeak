# Signal Leak

**Signal Leak** is a compact Godot 4 arcade-survival game about surviving inside a corrupted digital signal. The project is designed as a runnable portfolio project: easy to clone, easy to inspect, and ready to export as a Windows executable.

## Download / Release

The intended release artifact is:

```text
SignalLeak-Windows.zip
└─ SignalLeak-Windows/
   ├─ SignalLeak.exe
   └─ SignalLeak.pck
```

For players, download the latest Windows build from the repository's **GitHub Releases** page, unzip it, and run:

```text
SignalLeak.exe
```

No installation is required.

## Features

- Top-down arcade survival gameplay
- Endless, Campaign, and Debug Endless modes
- Difficulty presets: Casual, Normal, Signal Collapse
- Hard-coded controls so the project does not break when Input Map settings are missing
- Multiple enemy archetypes with different movement behavior
- Stackable weapon upgrades
- Directional 90° ultra shockwave
- Ammo, health, upgrade, and signal pickups
- Procedural obstacles and effectively unlimited play area
- Doomsday wave events
- Signal Loss enemy-scaling events
- Local save/highscore system using JSON
- Procedural ambient electronic music using `AudioStreamGenerator`
- Pixel-art sprites and procedural fallback visuals
- Export preset and GitHub Actions workflow for Windows releases

## Controls

| Action | Input |
|---|---|
| Move | WASD / Arrow Keys |
| Aim | Mouse |
| Shoot | Hold Left Click |
| Toggle Autofire | Right Click |
| Ultra Shockwave | Q |
| Pause | ESC |
| Restart after death/victory | R |
| Toggle fullscreen | F |
| Toggle music | M |
| Restart music | Y |
| Test beep | T |

## Modes

On the title screen:

| Key | Mode |
|---|---|
| 1 | Endless |
| 2 | Campaign |
| 3 | Debug Endless |
| D | Cycle difficulty preset |

Debug Endless uses equal enemy spawn probability. It exists so every enemy type can be tested quickly.

## Difficulty Presets

- **Casual** — slower pressure, more generous drops.
- **Normal** — intended default balance.
- **Signal Collapse** — faster scaling, more enemies, less generous drops.

The selected difficulty is saved locally.

## Run Summary and Save Data

After death or campaign completion, the game displays a run summary:

- score
- time survived
- kills
- level reached
- Doomsday events survived
- selected difficulty
- saved records

Save data is stored locally in Godot's user folder:

```text
user://signal_leak_save.json
```

Tracked records:

- best score
- best survival time
- most kills
- highest level
- campaign completion

## Project Structure

```text
signal-leak/
├─ .github/workflows/
│  └─ build-windows.yml
├─ assets/
│  ├─ audio/
│  └─ sprites/
├─ builds/
├─ docs/
│  ├─ architecture.md
│  ├─ devlog.md
│  ├─ release_checklist.md
│  ├─ release_notes.md
│  └─ screenshots/
├─ scenes/
├─ scripts/
├─ tools/
│  ├─ build_windows.ps1
│  └─ build_windows.sh
├─ export_presets.cfg
├─ project.godot
├─ README.md
└─ LICENSE
```

## How to Run in Godot

1. Install Godot 4.6 or newer.
2. Open the folder containing `project.godot`.
3. Run `scenes/main.tscn`.
4. Press `1`, `2`, or `3` on the title screen.

## Build Windows `.exe` Locally

### Option A: Godot Editor

1. Open the project in Godot.
2. Go to `Project > Export`.
3. Select the `Windows Desktop` preset.
4. Install export templates if prompted.
5. Export to:

```text
builds/SignalLeak-Windows/SignalLeak.exe
```

Then zip the folder:

```text
builds/SignalLeak-Windows.zip
```

### Option B: PowerShell

From the repository root:

```powershell
./tools/build_windows.ps1
```

If Godot is not in `PATH`, pass the executable manually:

```powershell
./tools/build_windows.ps1 -Godot "C:\\Path\\To\\Godot_v4.6.1-stable_win64.exe"
```

### Option C: Shell / Git Bash

```bash
GODOT_BIN=godot ./tools/build_windows.sh
```

The expected output is:

```text
builds/SignalLeak-Windows.zip
```

## Automated GitHub Release

This repo includes:

```text
.github/workflows/build-windows.yml
```

To create a Windows build from GitHub:

1. Push this repository to GitHub.
2. Open the repository on GitHub.
3. Go to `Actions > Build Windows Release`.
4. Click `Run workflow`.
5. Use version tag `v0.16.0` or a newer version.
6. The workflow exports the Windows build and uploads `SignalLeak-Windows.zip` as a GitHub Release asset.

You can also trigger a release by pushing a tag:

```bash
git tag v0.16.0
git push origin v0.16.0
```

## Documentation

- [Architecture Overview](docs/architecture.md)
- [Release Checklist](docs/release_checklist.md)
- [Release Notes](docs/release_notes.md)
- [Devlog](docs/devlog.md)


## License

MIT License.
