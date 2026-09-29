@echo off
title Greenify Backend Service
set JAVA_HOME=C:\Program Files\Microsoft\jdk-17.0.20.101-hotspot
cd /d "C:\Users\User\Desktop\Pendrive\Study Materials\Trimester 9\Aoop\Project\AOOP_Project-"

echo Checking if port 8080 is already in use...
for /f "tokens=5" %%a in ('netstat -aon ^| findstr ":8080" ^| findstr "LISTENING"') do (
    echo Stopping stale process on port 8080 (PID: %%a)...
    taskkill /f /pid %%a >nul 2>&1
)

echo ========================================================
echo Starting Greenify Spring Boot Backend on http://localhost:8080/api/v1
echo ========================================================
"C:\Program Files\Microsoft\jdk-17.0.20.101-hotspot\bin\java.exe" -jar "backend\target\greenify-backend-1.0.0-SNAPSHOT.jar" --spring.datasource.url="jdbc:mysql://localhost:3306/greenify_db?createDatabaseIfNotExist=true&useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC" --spring.datasource.username=root --spring.datasource.password=
pause

