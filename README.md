# WAVE

WAVE is organized into separate zones so the repository root stays clean and each task has its own place.

## Structure

```text
backend/                     Node.js backend, static client, tests, data
flutter/
  ios/wave_flutter_ios/      Flutter project for iOS
  windows-android/wave_flutter/
                             Flutter project for Windows and Android
scripts/
  bat/                       Windows launch/build helpers
  powershell/                PowerShell automation
  node/                      Utility Node.js scripts
runtime/
  artifacts/                 Build exports and screenshots
  logs/                      Runtime and emulator logs
  temp/                      Temporary working folders
```

## Backend Quick Start

```bash
cmd /c npm install
copy .env.example .env
cmd /c npm run dev
```

Required `.env` values:

- `JWT_SECRET` with at least 32 characters
- `VAPID_PUBLIC_KEY`
- `VAPID_PRIVATE_KEY`
- `VAPID_EMAIL`

## Common Commands

```bash
cmd /c npm start
cmd /c npm run test:perf
cmd /c npm run test:load
cmd /c npm run icons
cmd /c scripts\\bat\\start-server.bat
cmd /c scripts\\bat\\run-mobile.bat
cmd /c scripts\\bat\\build-wave-windows.bat
```

## Notes

- The backend now lives in `backend/`, but `npm` commands are still executed from the repository root.
- Flutter builds and mobile automation use `flutter/windows-android/wave_flutter`.
- iOS-specific work uses `flutter/ios/wave_flutter_ios`.
- Logs, temporary outputs, and exported artifacts are collected under `runtime/`.
