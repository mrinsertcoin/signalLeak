# Signal Leak Release Checklist

Use this checklist before publishing a GitHub Release.

## Local smoke test

- [ ] Open project in Godot 4.6+
- [ ] Run `scenes/main.tscn`
- [ ] Start Endless mode with `1`
- [ ] Start Campaign mode with `2`
- [ ] Start Debug Endless mode with `3`
- [ ] Confirm movement works with WASD and arrow keys
- [ ] Confirm left-click shooting works
- [ ] Confirm right-click autofire toggle works
- [ ] Confirm `Q` ultra shockwave works when charged
- [ ] Confirm `ESC` pause menu works
- [ ] Confirm `M` toggles music
- [ ] Confirm `F` toggles fullscreen
- [ ] Confirm run summary appears after death/victory
- [ ] Confirm records save locally

## Export preset

- [ ] `export_presets.cfg` exists
- [ ] Preset name is exactly `Windows Desktop`
- [ ] Export path is `builds/SignalLeak-Windows/SignalLeak.exe`
- [ ] Export templates are installed in Godot

## Local Windows build

From the repository root:

```powershell
./tools/build_windows.ps1
```

Expected output:

```text
builds/SignalLeak-Windows.zip
```

The zip should contain:

```text
SignalLeak-Windows/
├─ SignalLeak.exe
└─ SignalLeak.pck
```

## GitHub Actions release

- [ ] Push project to GitHub
- [ ] Go to `Actions > Build Windows Release`
- [ ] Run workflow with tag `v0.16.0` or newer
- [ ] Confirm `SignalLeak-Windows.zip` appears under GitHub Releases
- [ ] Download the release asset and run the `.exe` on Windows

## README polish

- [ ] Add screenshots to `docs/screenshots/`
- [ ] Add at least one gameplay screenshot to README
- [ ] Add a short GIF if possible
- [ ] Confirm GitHub topics are set
- [ ] Confirm license is visible
