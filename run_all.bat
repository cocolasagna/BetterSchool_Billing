@echo off
setlocal enabledelayedexpansion
title BetterSchool Billing - Launcher

echo -------------------------------------
echo  BETTERSCHOOL BILLING STARTUP SCRIPT
echo -------------------------------------
echo.

REM === Set DB credentials & PORT for portable PostgreSQL
set DB_USER=postgres
set DB_NAME=betterschool_billing
set PG_PORT=5433
set PG_PASSWORD=

REM === Change to script directory
cd /d "%~dp0"

:password_prompt
set /p PG_PASSWORD=Enter PostgreSQL password for user '%DB_USER%': 
set PGPASSWORD=%PG_PASSWORD%
set PGPORT=%PG_PORT%

REM === Start Portable PostgreSQL Server manually
echo [DB] Starting Portable PostgreSQL server...

REM Set paths to your portable PostgreSQL
set PG_BIN=%~dp0pgsql\bin
set PG_DATA=%~dp0pgsql\data

REM Check if PG server is already running (on port %PG_PORT%)
netstat -ano | findstr :%PG_PORT% >nul
if %errorlevel% equ 0 (
    echo [DB] PostgreSQL server is already running on port %PG_PORT%.
) else (
    echo [DB] Starting PostgreSQL server from %PG_BIN%
    start "" "%PG_BIN%\pg_ctl.exe" start -D "%PG_DATA%" -o "-p %PG_PORT%" -w
    timeout /t 5 /nobreak >nul
)

REM === Change to backend directory
cd backend

REM === Check if virtualenv exists
if not exist venv (
    echo [ENV] Virtual environment not found. Creating one...
    python -m venv venv
    if errorlevel 1 (
        echo [ERROR] Failed to create virtual environment.
        pause
        exit /b
    )
    echo [ENV] Installing requirements...
    venv\Scripts\pip.exe install -r requirements.txt
)

REM === Run Python DB setup script
echo [DB] Running Python database setup script...
venv\Scripts\python.exe setup_db.py
if errorlevel 1 (
    echo [ERROR] setup_db.py failed, possibly due to wrong password or DB error. Please try again.
    cd ..
    goto password_prompt
)

cd ..

REM === Start FastAPI backend
echo [INFO] Starting backend...
start cmd /k "cd /d %~dp0backend && venv\Scripts\activate && uvicorn main:app --host 127.0.0.1 --port 8000"

REM === Start frontend (assuming it’s built already)
echo [INFO] Starting frontend in browser...
start http://localhost:8000

echo [INFO] Application started successfully.
pause