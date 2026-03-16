# Wave Messenger Flutter

Flutter client for `Wave Messenger` with Android and Windows targets.

## Windows

Windows now starts the native Flutter client by default. This matters for calls:

- audio and video calls run through `flutter_webrtc`;
- the Windows client uses the same backend and signaling flow as the web client;
- calls between the Windows app and the web version are therefore compatible.

The old `WebView2` shell is still available, but only as an explicit opt-in mode.

## Run

```bash
flutter pub get
flutter run
```

For Windows:

```bash
flutter run -d windows
```

To point the client at a specific backend:

```bash
flutter run -d windows --dart-define=WAVE_BASE_URL=http://127.0.0.1:3000
```

To launch the legacy WebView shell instead of the native Windows client:

```bash
flutter run -d windows --dart-define=WAVE_WINDOWS_CLIENT_MODE=shell --dart-define=WAVE_BASE_URL=https://your-domain.example
```

## Android update-safe release builds

To install a new Android build over an already installed app, two things must stay consistent:

1. the same `applicationId` (`com.wave.messenger`);
2. the same **release keystore** used to sign every release.

If signing key changes (or debug key is used), Android will fail to update with a signature mismatch.

### 1) Configure release keystore once

Create `flutter/windows-android/wave_flutter/android/key.properties`:

```properties
storeFile=../keys/wave-upload.jks
storePassword=YOUR_STORE_PASSWORD
keyAlias=wave-upload
keyPassword=YOUR_KEY_PASSWORD
```

Keep this keystore safe and never rotate it for normal updates.

### 2) Increase build number on every release

Build number maps to Android `versionCode` and must always grow for updates.

```bash
flutter build appbundle --release --build-number=2
```

For next release use `--build-number=3`, then `4`, etc.

> The Android Gradle config now blocks release builds when `android/key.properties` is missing, so broken non-updatable releases are prevented early.

## Recreate platform files

```bash
flutter create --platforms=android,windows .
```

## Notes

- `WebView2` is no longer required for the default Windows build.
- `WebView2` is required only for `WAVE_WINDOWS_CLIENT_MODE=shell`.
- If `flutter build windows` or `flutter run -d windows` fails on plugin symlinks, enable Windows Developer Mode.
