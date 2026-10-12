@echo off
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Open-Visual-Studio.ps1"
set "TURTLE_EXIT_CODE=%ERRORLEVEL%"
pause
exit /b %TURTLE_EXIT_CODE%
