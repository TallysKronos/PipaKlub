@echo off
setlocal
cd /d "%~dp0"
set "SOULGEN_STUDIO_PORT=5241"
echo Soulgen do projeto unificado: http://127.0.0.1:5241
node tools\soulgen-studio\server.mjs
if errorlevel 1 pause
