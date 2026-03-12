# Wave Messenger iOS

This folder contains the iOS-targeted Flutter client for Wave Messenger.
It reuses the same Dart application code and feature set as the Android
client from `../wave_flutter`, but ships with an iOS project scaffold,
permissions, and CocoaPods configuration.

## Included

- authentication and session restore;
- 2FA login flow;
- private and group chats;
- realtime updates over WebSocket;
- profile settings, avatar upload, and account actions;
- WebRTC audio/video calls;
- iOS camera, microphone, photo library, and HTTP networking permissions.

## Local setup

1. Install Flutter 3.41+.
2. Run:

```bash
flutter pub get
```

3. On macOS, install CocoaPods dependencies:

```bash
cd ios
pod install
cd ..
```

4. Start on an iPhone simulator or device:

```bash
flutter run
```

## Notes

- The app allows cleartext HTTP because the current mobile client still talks
  to non-HTTPS Wave servers.
- The iOS project requires macOS + Xcode for final build/sign/run.
- If you change dependencies, rerun `flutter pub get` and `pod install`.

## GitHub Actions

The repository now includes an iOS workflow in
`../.github/workflows/build-ios.yml`.

- Every run builds a downloadable iOS Simulator app artifact.
- If Apple signing secrets are configured, the workflow also exports a signed
  `.ipa` and a zipped `.xcarchive`.
- On `push` and manual workflow runs, GitHub Actions publishes these files as a
  prerelease attachment as well.

### Required secrets for signed IPA

- `APPLE_CERTIFICATE_BASE64`: base64-encoded `.p12` signing certificate.
- `APPLE_CERTIFICATE_PASSWORD`: password for the `.p12` certificate.
- `APPLE_PROVISIONING_PROFILE_BASE64`: base64-encoded `.mobileprovision`.
- `APPLE_TEAM_ID`: Apple Developer Team ID.

### Optional secrets

- `APPLE_KEYCHAIN_PASSWORD`: custom temporary keychain password.
- `IOS_EXPORT_METHOD`: export method for the signed build.
  Defaults to `development`. You can override it with `ad-hoc`,
  `app-store`, or `enterprise`.
