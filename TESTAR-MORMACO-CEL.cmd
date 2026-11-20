@echo off
cd /d "%~dp0"
set "APPDATA=%~dp0.local\mormaco-cel-profile"
if not exist "%APPDATA%" mkdir "%APPDATA%"
start "" /b ".local\godot\Godot_v4.7.2-stable_win64.exe" --path "%~dp0godot" res://scenes/overworld/mormaco_cel_pilot.tscn
