@echo off
title Greenify Full-Stack Launch Hub
cd /d "%~dp0"
echo ========================================================
echo   Launching Greenify Full-Stack Platform Services
echo ========================================================
echo.
echo Starting Backend Service in dedicated window...
start "Greenify Backend" "Start_Backend.exe"
timeout /t 3 /nobreak >nul
echo.
echo Starting Frontend Application in dedicated window...
start "Greenify Frontend" "Start_Frontend.exe"
echo.
echo ========================================================
echo   Both services dispatched! 
echo   - Backend: http://localhost:8080/api/v1
echo   - IoT Sim: http://localhost:8080/api/v1/sim
echo   - Frontend Web: http://localhost:3000
echo ========================================================
timeout /t 5
