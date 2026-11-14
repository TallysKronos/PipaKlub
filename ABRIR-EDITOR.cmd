@echo off
setlocal
cd /d "%~dp0"
set "PIPAKLUB_GODOT=%~dp0.local\godot\Godot_v4.7.2-stable_win64.exe"
if not exist "%PIPAKLUB_GODOT%" (
  echo Godot local nao encontrado. Importe godot\project.godot no seu editor.
  pause
  exit /b 1
)
start "" "%PIPAKLUB_GODOT%" --editor --path "%~dp0godot"
