param([ValidateSet('cais','bairro')][string]$Scenario='cais')
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
$profileRoot=Join-Path $projectRoot $(if ($Scenario -eq 'bairro') {'tmp/neighborhood-play-profile'} else {'tmp/pier-play-profile'})
$roaming=Join-Path $profileRoot 'Roaming'
$local=Join-Path $profileRoot 'Local'
New-Item -ItemType Directory -Force -Path $roaming,$local | Out-Null
$oldRoaming=$env:APPDATA
$oldLocal=$env:LOCALAPPDATA
try {
    $env:APPDATA=$roaming
    $env:LOCALAPPDATA=$local
    $scene=if ($Scenario -eq 'bairro') {'res://scenes/overworld/neighborhood/bairro-jogavel.tscn'} else {'res://scenes/overworld/pier/cais-jogavel.tscn'}
    $log=if ($Scenario -eq 'bairro') {'tmp/neighborhood-play-live.log'} else {'tmp/pier-play-live.log'}
    & $godotExecutable --path $gameRoot $scene --log-file (Join-Path $projectRoot $log)
} finally {
    $env:APPDATA=$oldRoaming
    $env:LOCALAPPDATA=$oldLocal
}
