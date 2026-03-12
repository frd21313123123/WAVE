import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

class AppConfig extends ChangeNotifier {
  AppConfig._({
    required String baseUrl,
  }) : _baseUrl = _sanitizeBaseUrl(baseUrl);

  static const _defaultBaseUrl = 'http://45.12.70.75:3000';
  static const _baseUrlOverride = String.fromEnvironment(
    'WAVE_BASE_URL',
    defaultValue: _defaultBaseUrl,
  );
  static const _androidFirebaseApiKey = String.fromEnvironment(
    'WAVE_FIREBASE_ANDROID_API_KEY',
  );
  static const _androidFirebaseAppId = String.fromEnvironment(
    'WAVE_FIREBASE_ANDROID_APP_ID',
  );
  static const _androidFirebaseMessagingSenderId = String.fromEnvironment(
    'WAVE_FIREBASE_ANDROID_MESSAGING_SENDER_ID',
  );
  static const _androidFirebaseProjectId = String.fromEnvironment(
    'WAVE_FIREBASE_ANDROID_PROJECT_ID',
  );
  static const _androidFirebaseStorageBucket = String.fromEnvironment(
    'WAVE_FIREBASE_ANDROID_STORAGE_BUCKET',
  );

  final String _baseUrl;

  static Future<AppConfig> load() async {
    return AppConfig._(baseUrl: _baseUrlOverride);
  }

  String get baseUrl => _baseUrl;

  Uri get baseUri => Uri.parse(_baseUrl);

  bool get hasAndroidFirebaseMessagingConfig {
    return _androidFirebaseApiKey.isNotEmpty &&
        _androidFirebaseAppId.isNotEmpty &&
        _androidFirebaseMessagingSenderId.isNotEmpty &&
        _androidFirebaseProjectId.isNotEmpty;
  }

  FirebaseOptions? get androidFirebaseOptions {
    if (!hasAndroidFirebaseMessagingConfig) {
      return null;
    }

    return FirebaseOptions(
      apiKey: _androidFirebaseApiKey,
      appId: _androidFirebaseAppId,
      messagingSenderId: _androidFirebaseMessagingSenderId,
      projectId: _androidFirebaseProjectId,
      storageBucket: _androidFirebaseStorageBucket.isEmpty
          ? null
          : _androidFirebaseStorageBucket,
    );
  }

  Uri get wsUri {
    final uri = baseUri;
    final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
    return uri.replace(
        scheme: scheme, path: '/ws', query: null, fragment: null);
  }

  static String _sanitizeBaseUrl(String input) {
    final trimmed = input.trim();
    final normalized = trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;

    if (normalized.isEmpty) {
      return _defaultBaseUrl;
    }

    final uri = Uri.tryParse(normalized);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return _defaultBaseUrl;
    }

    return normalized;
  }
}
