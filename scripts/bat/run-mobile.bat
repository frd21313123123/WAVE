@echo off
setlocal
for %%I in ("%~dp0..\..") do set "REPO_ROOT=%%~fI"
cd /d "%REPO_ROOT%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%REPO_ROOT%\scripts\powershell\run-mobile.ps1" %*
