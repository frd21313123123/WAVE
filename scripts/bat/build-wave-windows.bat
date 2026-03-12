@echo off
setlocal EnableExtensions

for %%I in ("%~dp0..\..") do set "REPO_ROOT=%%~fI"
cd /d "%REPO_ROOT%"

set "PROJECT_DIR=%REPO_ROOT%\flutter\windows-android\wave_flutter"
set "BUILD_MODE=release"
set "EXE_PATH=%PROJECT_DIR%\build\windows\x64\runner\Release\wave_flutter.exe"

if not exist "%PROJECT_DIR%\pubspec.yaml" (
  echo [ERROR] Flutter project was not found: "%PROJECT_DIR%"
  exit /b 1
)

where flutter >nul 2>nul
if errorlevel 1 (
  echo [ERROR] Flutter is not available in PATH.
  exit /b 1
)

if not "%~1"=="" (
  set "WAVE_BASE_URL=%~1"
)

echo [INFO] Project: "%PROJECT_DIR%"
echo [INFO] Build mode: %BUILD_MODE%
if defined WAVE_BASE_URL (
  echo [INFO] WAVE_BASE_URL=%WAVE_BASE_URL%
) else (
  echo [INFO] WAVE_BASE_URL is not set. Default Flutter config will be used.
)

pushd "%PROJECT_DIR%"

echo [INFO] Running flutter pub get...
call flutter pub get
if errorlevel 1 (
  echo [ERROR] flutter pub get failed.
  popd
  exit /b 1
)

echo [INFO] Building Windows executable...
if defined WAVE_BASE_URL (
  call flutter build windows --%BUILD_MODE% --dart-define=WAVE_BASE_URL=%WAVE_BASE_URL%
) else (
  call flutter build windows --%BUILD_MODE%
)

if errorlevel 1 (
  echo [ERROR] flutter build windows failed.
  echo [HINT] If Flutter reports symlink support issues, enable Developer Mode:
  echo        start ms-settings:developers
  popd
  exit /b 1
)

if not exist "%EXE_PATH%" (
  echo [ERROR] Build finished, but executable was not found:
  echo         "%EXE_PATH%"
  popd
  exit /b 1
)

echo [INFO] Starting executable...
start "" "%EXE_PATH%"

popd
exit /b 0
