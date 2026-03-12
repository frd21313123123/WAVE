import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

const String defaultDesktopBaseUrl = String.fromEnvironment(
  'WAVE_BASE_URL',
  defaultValue: 'http://45.12.70.75:3000',
);

const String desktopVpsBaseUrl = 'http://45.12.70.75:3000';
const String desktopShellQueryParameter = 'desktopShell';

const String _settingsFileName = 'wave_desktop_settings.json';
const String _webViewDataFolderName = 'wave_webview';

String sanitizeDesktopBaseUrl(
  String input, {
  String fallback = defaultDesktopBaseUrl,
}) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) {
    return fallback;
  }

  final candidate = trimmed.contains('://') ? trimmed : 'http://$trimmed';
  final normalized = candidate.endsWith('/')
      ? candidate.substring(0, candidate.length - 1)
      : candidate;

  final uri = Uri.tryParse(normalized);
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
    return fallback;
  }

  return normalized;
}

String buildDesktopShellUrl(String baseUrl) {
  final uri = Uri.tryParse(baseUrl);
  if (uri == null) {
    return baseUrl;
  }

  final nextQueryParameters = <String, String>{
    ...uri.queryParameters,
    desktopShellQueryParameter: '1',
  };

  return uri.replace(queryParameters: nextQueryParameters).toString();
}

class DesktopShellSettings {
  const DesktopShellSettings({
    required this.baseUrl,
  });

  factory DesktopShellSettings.defaults() {
    return const DesktopShellSettings(baseUrl: defaultDesktopBaseUrl);
  }

  factory DesktopShellSettings.fromJson(Map<String, dynamic> json) {
    return DesktopShellSettings(
      baseUrl: sanitizeDesktopBaseUrl(
        json['baseUrl'] as String? ?? '',
      ),
    );
  }

  final String baseUrl;

  DesktopShellSettings copyWith({
    String? baseUrl,
  }) {
    return DesktopShellSettings(
      baseUrl: baseUrl ?? this.baseUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'baseUrl': baseUrl,
    };
  }
}

class DesktopShellSettingsStore {
  Future<DesktopShellSettings> read() async {
    final file = await _settingsFile();
    if (!await file.exists()) {
      return DesktopShellSettings.defaults();
    }

    try {
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return DesktopShellSettings.defaults();
      }
      return DesktopShellSettings.fromJson(decoded);
    } catch (_) {
      return DesktopShellSettings.defaults();
    }
  }

  Future<void> write(DesktopShellSettings settings) async {
    final file = await _settingsFile();
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(settings.toJson()),
    );
  }

  Future<String> ensureWebViewDataPath() async {
    final root = await _rootDirectory();
    final directory = Directory(
      '${root.path}${Platform.pathSeparator}$_webViewDataFolderName',
    );
    await directory.create(recursive: true);
    return directory.path;
  }

  Future<File> _settingsFile() async {
    final root = await _rootDirectory();
    return File('${root.path}${Platform.pathSeparator}$_settingsFileName');
  }

  Future<Directory> _rootDirectory() async {
    final directory = await getApplicationSupportDirectory();
    await directory.create(recursive: true);
    return directory;
  }
}
