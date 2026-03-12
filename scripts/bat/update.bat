@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul

REM ==========================================
REM READY-TO-RUN updater for WAVE / auto-reg
REM No edits required.
REM ==========================================

set "SERVER_HOST=144.31.212.164"
set "SERVER_PORT=22"
set "SERVER_USER=root"
set "REMOTE_SCRIPT=/root/clawd/scripts/update_projects.sh"
set "SSH_OPTS=-o StrictHostKeyChecking=accept-new -o ConnectTimeout=10"

REM Try common key paths automatically
set "KEY="
if exist "%USERPROFILE%\.ssh\id_ed25519" set "KEY=%USERPROFILE%\.ssh\id_ed25519"
if exist "%USERPROFILE%\.ssh\id_rsa" set "KEY=%USERPROFILE%\.ssh\id_rsa"
if exist "%USERPROFILE%\.ssh\id_ecdsa" set "KEY=%USERPROFILE%\.ssh\id_ecdsa"

where ssh >nul 2>nul
if errorlevel 1 (
echo [ERROR] OpenSSH client not found in PATH.
echo Install "OpenSSH Client" in Windows Optional Features and run again.
pause
exit /b 1
)

:menu
echo.
echo ================================
echo Project updater (remote)
echo ================================
echo 1^) Update WAVE
echo 2^) Update auto-reg
echo 3^) Update ALL
echo 4^) Exit
echo.
set /p CHOICE=Choose [1-4]:

if "%CHOICE%"=="1" set "TARGET=wave"& goto run
if "%CHOICE%"=="2" set "TARGET=auto-reg"& goto run
if "%CHOICE%"=="3" set "TARGET=all"& goto run
if "%CHOICE%"=="4" goto end
echo Invalid choice.
goto menu

:run
echo.
echo [INFO] Connecting to %SERVER_USER%@%SERVER_HOST%:%SERVER_PORT%
echo [INFO] Running: %REMOTE_SCRIPT% %TARGET%
echo.

if defined KEY (
ssh %SSH_OPTS% -i "%KEY%" -p %SERVER_PORT% %SERVER_USER%@%SERVER_HOST% "%REMOTE_SCRIPT% %TARGET%"
) else (
ssh %SSH_OPTS% -p %SERVER_PORT% %SERVER_USER%@%SERVER_HOST% "%REMOTE_SCRIPT% %TARGET%"
)

if errorlevel 1 (
echo.
echo [ERROR] Update failed.
echo If prompted, verify password/key access to the server.
) else (
echo.
echo [OK] Update completed.
)

pause
goto menu

:end
echo Bye.
endlocal
exit /b 0
