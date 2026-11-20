@echo off
setlocal
cd /d "%~dp0"
set "PIPAKLUB_GODOT=%~dp0.local\godot\Godot_v4.7.2-stable_win64.exe"
if not exist "%PIPAKLUB_GODOT%" (
  echo Godot local nao encontrado. Abra godot\project.godot no Godot 4.7.2.
  pause
  exit /b 1
)
if not exist "%~dp0tmp" mkdir "%~dp0tmp"
start "" "%PIPAKLUB_GODOT%" --path "%~dp0godot" --log-file "%~dp0tmp\jogo-atual.log"
