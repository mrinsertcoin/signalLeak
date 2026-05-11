#!/usr/bin/env bash
set -euo pipefail

GODOT_BIN="${GODOT_BIN:-godot}"
PRESET="Windows Desktop"
OUTPUT_DIR="builds/SignalLeak-Windows"
EXE_PATH="$OUTPUT_DIR/SignalLeak.exe"
ZIP_PATH="builds/SignalLeak-Windows.zip"

echo "Building Signal Leak Windows release..."
echo "Godot command: $GODOT_BIN"
echo "Preset: $PRESET"

mkdir -p "$OUTPUT_DIR"
"$GODOT_BIN" --headless --path . --export-release "$PRESET" "$EXE_PATH"

if [ ! -f "$EXE_PATH" ]; then
  echo "Export failed: $EXE_PATH was not created. Check Godot export templates and export_presets.cfg." >&2
  exit 1
fi

rm -f "$ZIP_PATH"
(
  cd builds
  zip -r "SignalLeak-Windows.zip" "SignalLeak-Windows"
)

echo "Build complete: $ZIP_PATH"
