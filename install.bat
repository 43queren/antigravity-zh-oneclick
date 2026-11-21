@echo off
setlocal EnableDelayedExpansion
title Antigravity Chinese Patch - Install
cd /d "%~dp0"

echo.
echo  ============================================================
echo       Google Antigravity Chinese Patch (Fixed Edition)
echo    - 6005 translation entries + DOM translation engine
echo    - Settings-freeze bug fixed
echo    - Auto backup, fully reversible
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

if defined PY goto :HavePy
echo  [*] No Python found. Downloading portable Python (about 11MB, first time only)...
if exist ".python\python.exe" (
    set "PY=.python\python.exe"
    goto :HavePy
)
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://www.python.org/ftp/python/3.11.9/python-3.11.9-embed-amd64.zip' -OutFile '.python.zip' -UseBasicParsing"
if not exist ".python.zip" (
    echo  [ERROR] Python download failed. Check network or install Python manually.
    goto :Fail
)
echo  [*] Extracting portable Python...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -Path '.python.zip' -DestinationPath '.python' -Force"
if exist ".python\python311._pth" echo import site>> ".python\python311._pth"
del /f /q ".python.zip" >nul 2>&1
set "PY=.python\python.exe"

:HavePy
echo  [OK] Python: !PY!

REM ---- 2. Locate Antigravity ----
set "ASAR="
set "EXE="
call :FindAgy "%LOCALAPPDATA%\Programs\antigravity"
call :FindAgy "%LOCALAPPDATA%\Programs\Antigravity"
call :FindAgy "%ProgramFiles%\antigravity"
call :FindAgy "%ProgramFiles%\Antigravity"
if not defined ASAR (
    echo  [ERROR] Antigravity not found ^(resources\app.asar^).
    echo          Install Google Antigravity first, then run this script.
    goto :Fail
)
echo  [OK] Found: !ASAR!

REM ---- 3. Close Antigravity ----
echo  [*] Closing Antigravity...
tasklist /FI "IMAGENAME eq Antigravity.exe" 2>NUL | find /I "Antigravity.exe" >NUL
if "%ERRORLEVEL%"=="0" (
    taskkill /F /IM Antigravity.exe >nul 2>&1
    timeout /t 2 >nul
)

REM ---- 4. Clear env vars that break Electron ----
set "ELECTRON_RUN_AS_NODE="
set "DEV_URL="

REM ---- 5. Apply patch ----
echo  [*] Installing Chinese patch (original auto-backed-up)...
"!PY!" "%~dp0install.py" --asar "!ASAR!"
if errorlevel 1 (
    echo  [ERROR] Patch failed. See messages above.
    goto :Fail
)

REM ---- 6. Start Antigravity ----
echo  [*] Starting Antigravity...
start "" "!EXE!"

echo.
echo  ============================================================
echo    [DONE] Chinese patch installed. Antigravity is starting.
echo    If UI still shows English, fully quit and reopen once.
echo    To restore original, run "restore.bat" in this folder.
echo  ============================================================
echo.
timeout /t 5 >nul
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

:Fail
echo.
echo  [FAILED] Operation not completed. See messages above.
pause
endlocal
exit /b 1
