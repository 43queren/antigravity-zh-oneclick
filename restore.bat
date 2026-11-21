@echo off
setlocal EnableDelayedExpansion
title Antigravity Chinese Patch - Restore
cd /d "%~dp0"

echo.
echo  ============================================================
echo       Google Antigravity - Restore Original
echo  ============================================================
echo.

REM ---- 1. Find Python (single-token commands only) ----
set "PY="
python -c "import sys" >nul 2>&1
if not errorlevel 1 set "PY=python"
if not defined PY (
    py -c "import sys" >nul 2>&1
    if not errorlevel 1 set "PY=py"
)
if not defined PY if exist "%LOCALAPPDATA%\Programs\Python\Python311\python.exe" set "PY=%LOCALAPPDATA%\Programs\Python\Python311\python.exe"
if not defined PY if exist "%LOCALAPPDATA%\Programs\Python\Python310\python.exe" set "PY=%LOCALAPPDATA%\Programs\Python\Python310\python.exe"
if not defined PY if exist "%LOCALAPPDATA%\Programs\Python\Python39\python.exe" set "PY=%LOCALAPPDATA%\Programs\Python\Python39\python.exe"

if not defined PY (
    echo  [ERROR] Python not found. Run install.bat once first.
    pause
    exit /b 1
)

set "ASAR="
set "EXE="
call :FindAgy "%LOCALAPPDATA%\Programs\antigravity"
call :FindAgy "%LOCALAPPDATA%\Programs\Antigravity"
call :FindAgy "%ProgramFiles%\antigravity"
call :FindAgy "%ProgramFiles%\Antigravity"
if not defined ASAR (
    echo  [ERROR] Antigravity not found.
    pause
    exit /b 1
)

echo  [*] Closing Antigravity...
tasklist /FI "IMAGENAME eq Antigravity.exe" 2>NUL | find /I "Antigravity.exe" >NUL
if "%ERRORLEVEL%"=="0" (
    taskkill /F /IM Antigravity.exe >nul 2>&1
    timeout /t 2 >nul
)

echo  [*] Restoring original...
"!PY!" "%~dp0install.py" --restore --asar "!ASAR!"
if errorlevel 1 (
    echo  [ERROR] Restore failed.
    pause
    exit /b 1
)

start "" "!EXE!"
echo.
echo  [DONE] Original restored. Antigravity is starting.
echo.
timeout /t 4 >nul
endlocal
exit /b 0

:FindAgy
if not defined ASAR (
    if exist "%~1\resources\app.asar" (
        set "ASAR=%~1\resources\app.asar"
        set "EXE=%~1\Antigravity.exe"
    )
)
exit /b 0
