@echo off
title Greenify Frontend Launcher
cd /d "%~dp0"
if exist "Start_Frontend.exe" (
    "Start_Frontend.exe" %*
) else (
    echo Launching flutter fallback...
    cd mobile
    call flutter run -d chrome --web-port 3000
)
pause
