param(
    [string]$Godot = "godot",
    [string]$Preset = "Windows Desktop",
    [string]$OutputDir = "builds/SignalLeak-Windows",
    [string]$ExeName = "SignalLeak.exe"
)

$ErrorActionPreference = "Stop"

Write-Host "Building Signal Leak Windows release..."
Write-Host "Godot command: $Godot"
Write-Host "Preset: $Preset"

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

$exePath = Join-Path $OutputDir $ExeName
& $Godot --headless --path . --export-release $Preset $exePath

if (-not (Test-Path $exePath)) {
    throw "Export failed: $exePath was not created. Check Godot export templates and export_presets.cfg."
}

$zipPath = "builds/SignalLeak-Windows.zip"
if (Test-Path $zipPath) {
    Remove-Item $zipPath -Force
}

Compress-Archive -Path "$OutputDir/*" -DestinationPath $zipPath -Force
Write-Host "Build complete: $zipPath"
