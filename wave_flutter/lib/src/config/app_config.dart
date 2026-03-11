import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppConfig extends ChangeNotifier {
  AppConfig._({
    required SharedPreferences prefs,
    required String baseUrl,
  })  : _prefs = prefs,
        _baseUrl = _sanitizeBaseUrl(baseUrl);

  static const _serverUrlKey = 'wave_server_url';
  static const _defaultBaseUrl = String.fromEnvironment(
    'WAVE_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  final SharedPreferences _prefs;
  String _baseUrl;

  static Future<AppConfig> load() async {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString(_serverUrlKey) ?? _defaultBaseUrl;
    return AppConfig._(prefs: prefs, baseUrl: baseUrl);
  }

  String get baseUrl => _baseUrl;

  Uri get baseUri => Uri.parse(_baseUrl);

  Uri get wsUri {
    final uri = baseUri;
    final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
    return uri.replace(scheme: scheme, path: '/ws', query: null, fragment: null);
  }

  Future<void> updateBaseUrl(String value) async {
    _baseUrl = _sanitizeBaseUrl(value);
    await _prefs.setString(_serverUrlKey, _baseUrl);
    notifyListeners();
  }

  static String _sanitizeBaseUrl(String input) {
    final trimmed = input.trim();
    final normalized = trimmed.endsWith('/') ? trimmed.substring(0, trimmed.length - 1) : trimmed;

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
