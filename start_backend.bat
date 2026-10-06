@echo off
title Greenify Backend Launcher
cd /d "%~dp0"
if exist "Start_Backend.exe" (
    "Start_Backend.exe" %*
) else (
    echo Launching backend fallback...
    "C:\Program Files\Microsoft\jdk-17.0.20.101-hotspot\bin\java.exe" -jar "backend\target\greenify-backend-1.0.0-SNAPSHOT.jar"
)
pause
