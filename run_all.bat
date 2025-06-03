@echo off
setlocal enabledelayedexpansion

set DB_USER=postgres
set DB_NAME=betterschool_billing

echo [INFO] Running BetterSchool Billing Setup...

REM === Change to script directory
cd /d "%~dp0"

:password_prompt
set /p DB_PASS=Enter PostgreSQL password for user '%DB_USER%': 
set PGPASSWORD=%DB_PASS%

REM === Start PostgreSQL service
echo [DB] Starting PostgreSQL service...
net start postgresql-x64-17 >nul 2>&1
if %errorlevel% equ 2 (
    echo [DB] PostgreSQL service already running.
) else if %errorlevel% neq 0 (
    echo [ERROR] Failed to start PostgreSQL service. Try running as administrator.
    pause
    exit /b
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
