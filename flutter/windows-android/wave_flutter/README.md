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

## Recreate platform files

```bash
flutter create --platforms=android,windows .
```

## Notes

- `WebView2` is no longer required for the default Windows build.
- `WebView2` is required only for `WAVE_WINDOWS_CLIENT_MODE=shell`.
- If `flutter build windows` or `flutter run -d windows` fails on plugin symlinks, enable Windows Developer Mode.
