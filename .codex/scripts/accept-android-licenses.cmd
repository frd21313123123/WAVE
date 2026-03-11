@echo off
set "SDK_ROOT=%ANDROID_HOME%"
if not defined SDK_ROOT set "SDK_ROOT=%~dp0..\..\.tools\android-sdk"
(for %%I in ("%SDK_ROOT%") do set "SDK_ROOT=%%~fI")
(for /L %%i in (1,1,20) do @echo y) | "%SDK_ROOT%\cmdline-tools\latest\bin\sdkmanager.bat" --sdk_root="%SDK_ROOT%" --licenses
