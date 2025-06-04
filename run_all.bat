@echo off
setlocal enabledelayedexpansion
title BetterSchool Billing - Launcher

echo -------------------------------------
echo  BETTERSCHOOL BILLING STARTUP SCRIPT
echo -------------------------------------
echo.

REM === Set DB credentials & config
set DB_USER=postgres
set DB_NAME=betterschool_billing
set PG_PORT=5433
set PG_PASSWORD=
set PG_LOG=%~dp0pgsql\pg_logfile.log

REM === Change to script directory
cd /d "%~dp0"

:password_prompt
set /p PG_PASSWORD=Enter PostgreSQL password for user '%DB_USER%': 
set PGPASSWORD=%PG_PASSWORD%
set PGPORT=%PG_PORT%

REM === Set paths
set PG_BIN=%~dp0pgsql\bin
set PG_DATA=%~dp0pgsql\data

REM === Check if PostgreSQL already running on port
netstat -ano | findstr :%PG_PORT% >nul
if %errorlevel% equ 0 (
    echo [DB] PostgreSQL already running on port %PG_PORT%.
) else (
    echo [DB] Starting PostgreSQL server silently...
    "%PG_BIN%\pg_ctl.exe" start -D "%PG_DATA%" -o "-p %PG_PORT% -h 127.0.0.1" -l "%PG_LOG%" -w -s
    if errorlevel 1 (
        echo [ERROR] Failed to start PostgreSQL.
        pause
        exit /b
    )
    echo [DB] PostgreSQL started on port %PG_PORT%.
)

REM === Move into backend and ensure venv exists
cd backend

if not exist venv (
    echo [ENV] Creating virtual environment...
    python -m venv venv
    if errorlevel 1 (
        echo [ERROR] Failed to create virtual environment.
        pause
        exit /b
    )
    echo [ENV] Installing dependencies...
    venv\Scripts\pip.exe install -r requirements.txt
)

REM === Run setup_db.py (creates DB if needed)
echo [DB] Running Python database setup...
venv\Scripts\python.exe setup_db.py
if errorlevel 1 (
    echo [ERROR] Database setup failed — wrong password or DB error.
    echo Please re-enter password.
    cd ..
    goto password_prompt
)



REM === Start FastAPI server in this window
echo [INFO] Launching backend server...
venv\Scripts\python.exe -m uvicorn main:app --host 127.0.0.1 --port 8000

REM === Launch frontend in browser
start http://localhost:8000

REM === This line won't be reached unless server exits
echo [INFO] Application started successfully.
pause
