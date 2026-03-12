import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/app_models.dart';

class CachedSession {
  CachedSession({
    required this.user,
    required this.authToken,
  });

  factory CachedSession.fromJson(Map<String, dynamic> json) {
    return CachedSession(
      user: PublicUser.fromJson(
        Map<String, dynamic>.from(json['user'] as Map? ?? const {}),
      ),
      authToken: json['authToken'] as String? ?? '',
    );
  }

  final PublicUser user;
  final String authToken;

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'authToken': authToken,
    };
  }
}

class SessionStore {
  SessionStore._(this._sessionFile);

  final File _sessionFile;

  static Future<SessionStore> create() async {
    final supportDir = await getApplicationSupportDirectory();
    return SessionStore._(File('${supportDir.path}/wave_session.json'));
  }

  Future<CachedSession?> load() async {
    try {
      if (!await _sessionFile.exists()) {
        return null;
      }

      final raw = await _sessionFile.readAsString();
      if (raw.trim().isEmpty) {
        return null;
      }

      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return null;
      }

      final session =
          CachedSession.fromJson(Map<String, dynamic>.from(decoded));
      if (session.user.id.trim().isEmpty || session.authToken.trim().isEmpty) {
        return null;
      }

      return session;
    } catch (_) {
      return null;
    }
  }

  Future<void> save(CachedSession session) async {
    await _sessionFile.parent.create(recursive: true);
    await _sessionFile.writeAsString(
      jsonEncode(session.toJson()),
      flush: true,
    );
  }

  Future<void> clear() async {
    if (await _sessionFile.exists()) {
      await _sessionFile.delete();
    }
  }
}
