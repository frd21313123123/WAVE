import 'package:flutter/foundation.dart';

class AppConfig extends ChangeNotifier {
  AppConfig._({
    required String baseUrl,
  }) : _baseUrl = _sanitizeBaseUrl(baseUrl);

  static const _fixedBaseUrl = 'http://45.12.70.75:3000';

  final String _baseUrl;

  static Future<AppConfig> load() async {
    return AppConfig._(baseUrl: _fixedBaseUrl);
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
      return _fixedBaseUrl;
    }

    final uri = Uri.tryParse(normalized);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return _fixedBaseUrl;
    }

    return normalized;
  }
}
