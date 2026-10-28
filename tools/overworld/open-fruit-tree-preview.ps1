$ErrorActionPreference='Stop'
$projectRoot=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$gameRoot=Join-Path $projectRoot 'godot'
$godotExecutable=$env:GODOT_BIN
if (-not $godotExecutable) {
    $installed=Get-Command godot -ErrorAction SilentlyContinue
    if ($installed) {$godotExecutable=$installed.Source}
}
if (-not $godotExecutable) {
    $localRuntime=Join-Path (Split-Path $projectRoot -Parent) 'pipa-club/tmp/godot-4.7.2/runtime/Godot_v4.7.2-stable_win64_console.exe'
    if (Test-Path -LiteralPath $localRuntime) {$godotExecutable=$localRuntime}
}
if (-not $godotExecutable) {throw 'Defina GODOT_BIN com o caminho do Godot 4.x ou instale godot no PATH.'}
& $godotExecutable --path $gameRoot --script res://tools/fruit_tree_preview.gd
