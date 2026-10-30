$ErrorActionPreference='Stop'
$projectRoot=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$godotExecutable=$env:GODOT_BIN
if (-not $godotExecutable) {
    $installed=Get-Command godot -ErrorAction SilentlyContinue
    if ($installed) {$godotExecutable=$installed.Source}
}
if (-not $godotExecutable) {
    $candidate=Join-Path (Split-Path $projectRoot -Parent) 'pipa-club/tmp/godot-4.7.2/runtime/Godot_v4.7.2-stable_win64_console.exe'
    if (Test-Path -LiteralPath $candidate) {$godotExecutable=$candidate}
}
if (-not $godotExecutable) {throw 'Defina GODOT_BIN com o caminho do Godot 4.x.'}
& $godotExecutable --path (Join-Path $projectRoot 'godot') --script res://tools/kael_gameplay_play.gd --log-file (Join-Path $projectRoot 'tmp/kael-playtest-live.log')
