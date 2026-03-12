import 'package:flutter/foundation.dart';

class AppConfig extends ChangeNotifier {
  AppConfig._({
    required String baseUrl,
  }) : _baseUrl = _sanitizeBaseUrl(baseUrl);

  static const _defaultBaseUrl = 'http://45.12.70.75:3000';
  static const _baseUrlOverride = String.fromEnvironment(
    'WAVE_BASE_URL',
    defaultValue: _defaultBaseUrl,
  );

  final String _baseUrl;

  static Future<AppConfig> load() async {
    return AppConfig._(baseUrl: _baseUrlOverride);
  }

  String get baseUrl => _baseUrl;

  Uri get baseUri => Uri.parse(_baseUrl);

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
