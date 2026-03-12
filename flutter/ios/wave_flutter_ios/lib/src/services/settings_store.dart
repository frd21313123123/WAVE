import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../settings/app_settings.dart';

class SettingsStore {
  SettingsStore._(this._settingsFile);

  final File _settingsFile;

  static Future<SettingsStore> create() async {
    final supportDir = await getApplicationSupportDirectory();
    return SettingsStore._(File('${supportDir.path}/wave_settings.json'));
  }

  Future<AppSettings> load() async {
    try {
      if (!await _settingsFile.exists()) {
        return const AppSettings();
      }

      final raw = await _settingsFile.readAsString();
      if (raw.trim().isEmpty) {
        return const AppSettings();
      }

      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return const AppSettings();
      }

      return AppSettings.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return const AppSettings();
    }
  }

  Future<void> save(AppSettings settings) async {
    await _settingsFile.parent.create(recursive: true);
    await _settingsFile.writeAsString(
      jsonEncode(settings.toJson()),
      flush: true,
    );
  }

  Future<void> clear() async {
    if (await _settingsFile.exists()) {
      await _settingsFile.delete();
    }
  }
}
