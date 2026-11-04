$ErrorActionPreference='Stop'
$projectRoot=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$runtime=Join-Path (Split-Path $projectRoot -Parent) 'pipa-club/tmp/godot-4.7.2/runtime/Godot_v4.7.2-stable_win64_console.exe'
$profile=Join-Path $projectRoot 'tmp/workshop-art-profile'
New-Item -ItemType Directory -Force (Join-Path $profile 'Roaming'),(Join-Path $profile 'Local') | Out-Null
$savedRoaming=$env:APPDATA
$savedLocal=$env:LOCALAPPDATA
try {
    $env:APPDATA=Join-Path $profile 'Roaming'
    $env:LOCALAPPDATA=Join-Path $profile 'Local'
    & $runtime --path (Join-Path $projectRoot 'godot') --script res://tools/workshop_manga_preview.gd --log-file (Join-Path $projectRoot 'tmp/workshop-art-live.log') -- --play
} finally {
    $env:APPDATA=$savedRoaming
    $env:LOCALAPPDATA=$savedLocal
}
