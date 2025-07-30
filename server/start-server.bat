@echo off
echo 🎲 Sicbo Multiplayer Server Setup
echo =================================

REM Check if Node.js is installed
where node >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Node.js is not installed. Please install Node.js first.
    echo    Download from: https://nodejs.org/
    pause
    exit /b 1
)

node --version >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo ✅ Node.js found
    node --version
) else (
    echo ❌ Node.js installation seems corrupted
    pause
    exit /b 1
)

REM Navigate to server directory
cd /d "%~dp0"

REM Install dependencies
echo 📦 Installing dependencies...
call npm install

if %ERRORLEVEL% EQU 0 (
    echo ✅ Dependencies installed successfully
) else (
    echo ❌ Failed to install dependencies
    pause
    exit /b 1
)

REM Start the server
echo 🚀 Starting Sicbo Multiplayer Server...
echo    Server will run on: ws://localhost:8080
echo    Press Ctrl+C to stop the server
echo.

call npm start

pause
