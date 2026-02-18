@echo off
setlocal EnableExtensions EnableDelayedExpansion

cd /d "%~dp0"

if "%HOST%"=="" set "HOST=0.0.0.0"
if "%PORT%"=="" set "PORT=3000"
if "%COOKIE_SECURE%"=="" set "COOKIE_SECURE=auto"
if "%TRUST_PROXY%"=="" set "TRUST_PROXY=1"

if "%JWT_SECRET%"=="" (
  set "JWT_SECRET=change_me_please_set_real_secret"
  echo [WARN] JWT_SECRET is not set. Temporary value is used.
)

set /a "_port_tries=0"
:find_free_port
set "PORT_BUSY="
set "PORT_PID="
for /f "tokens=5" %%p in ('netstat -ano ^| findstr /R /C:":%PORT% .*LISTENING"') do (
  set "PORT_BUSY=1"
  set "PORT_PID=%%p"
  goto :port_check_done
)
:port_check_done

if defined PORT_BUSY (
  echo [WARN] Port %PORT% is already in use by PID %PORT_PID%.
  set /a PORT+=1
  set /a _port_tries+=1
  if !_port_tries! GEQ 20 (
    echo [ERROR] Could not find free port in range 3000-3019.
    pause
    exit /b 1
  )
  goto :find_free_port
)

if not exist "node_modules" (
  echo [INFO] Installing dependencies...
  call npm install
  if errorlevel 1 (
    echo [ERROR] npm install failed.
    pause
    exit /b 1
  )
)

echo [INFO] Starting server...
echo [INFO] Server host: %HOST%
echo [INFO] Server port: %PORT%
echo [INFO] For public internet access use VPS/domain or tunnel.
call npm start

if errorlevel 1 (
  echo [ERROR] Server stopped with error.
)

pause
