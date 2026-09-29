@echo off
title Greenify Mobile Flutter Web
cd /d "C:\Users\User\Desktop\Pendrive\Study Materials\Trimester 9\Aoop\Project\AOOP_Project-\mobile"

echo Checking if port 3000 is already in use...
for /f "tokens=5" %%a in ('netstat -aon ^| findstr ":3000" ^| findstr "LISTENING"') do (
    echo Stopping stale process on port 3000 (PID: %%a)...
    taskkill /f /pid %%a >nul 2>&1
)

echo ========================================================
echo Starting Greenify Flutter Web Server on http://localhost:3000
echo ========================================================
"C:\Users\User\develop\flutter\bin\flutter.bat" run -d web-server --web-port=3000 --web-hostname=localhost
pause
