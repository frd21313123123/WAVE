import 'dart:math';

enum WaveThemeMode {
  light,
  dark,
}

class AppSettings {
  const AppSettings({
    this.themeMode = WaveThemeMode.light,
    this.fullscreen = false,
    this.vigenereEnabled = false,
    this.vigenereKey = defaultVigenereKey,
    this.microphoneVolume = 100,
    this.speakerVolume = 100,
    this.callSoundsEnabled = true,
    this.notificationsEnabled = true,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      themeMode: switch (json['themeMode']) {
        'dark' => WaveThemeMode.dark,
        _ => WaveThemeMode.light,
      },
      fullscreen: json['fullscreen'] == true,
      vigenereEnabled: json['vigenereEnabled'] == true,
      vigenereKey: _normalizeVigenereKey(json['vigenereKey'] as String?),
      microphoneVolume: _normalizeVolume(json['microphoneVolume']),
      speakerVolume: _normalizeVolume(json['speakerVolume']),
      callSoundsEnabled: json['callSoundsEnabled'] != false,
      notificationsEnabled: json['notificationsEnabled'] != false,
    );
  }

  static const defaultVigenereKey = 'WAVE';

  final WaveThemeMode themeMode;
  final bool fullscreen;
  final bool vigenereEnabled;
  final String vigenereKey;
  final int microphoneVolume;
  final int speakerVolume;
  final bool callSoundsEnabled;
  final bool notificationsEnabled;

  AppSettings copyWith({
    WaveThemeMode? themeMode,
    bool? fullscreen,
    bool? vigenereEnabled,
    String? vigenereKey,
    int? microphoneVolume,
    int? speakerVolume,
    bool? callSoundsEnabled,
    bool? notificationsEnabled,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      fullscreen: fullscreen ?? this.fullscreen,
      vigenereEnabled: vigenereEnabled ?? this.vigenereEnabled,
      vigenereKey: _normalizeVigenereKey(vigenereKey ?? this.vigenereKey),
      microphoneVolume: _normalizeVolume(microphoneVolume ?? this.microphoneVolume),
      speakerVolume: _normalizeVolume(speakerVolume ?? this.speakerVolume),
      callSoundsEnabled: callSoundsEnabled ?? this.callSoundsEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode.name,
      'fullscreen': fullscreen,
      'vigenereEnabled': vigenereEnabled,
      'vigenereKey': _normalizeVigenereKey(vigenereKey),
      'microphoneVolume': _normalizeVolume(microphoneVolume),
      'speakerVolume': _normalizeVolume(speakerVolume),
      'callSoundsEnabled': callSoundsEnabled,
      'notificationsEnabled': notificationsEnabled,
    };
  }

  static String _normalizeVigenereKey(String? value) {
    final trimmed = (value ?? '').trim();
    return trimmed.isEmpty ? defaultVigenereKey : trimmed;
  }

  static int _normalizeVolume(dynamic value) {
    final parsed = value is int ? value : int.tryParse(value?.toString() ?? '');
    if (parsed == null) {
      return 100;
    }
    return parsed.clamp(0, 100);
  }
}

class TwoFactorSetupData {
  const TwoFactorSetupData({
    required this.secret,
    required this.otpauthUrl,
  });

  factory TwoFactorSetupData.fromJson(Map<String, dynamic> json) {
    return TwoFactorSetupData(
      secret: json['secret'] as String? ?? '',
      otpauthUrl: json['otpauthUrl'] as String? ?? '',
    );
  }

  final String secret;
  final String otpauthUrl;

  bool get isReady => secret.isNotEmpty && otpauthUrl.isNotEmpty;

  String get qrImageUrl {
    if (!isReady) {
      return '';
    }
    return 'https://api.qrserver.com/v1/create-qr-code/?size=192x192&data=${Uri.encodeComponent(otpauthUrl)}';
  }
}

class EncryptionMetrics {
  const EncryptionMetrics({
    required this.level,
    required this.label,
    required this.entropyBits,
    required this.estimatedCrackTime,
  });

  final int level;
  final String label;
  final int entropyBits;
  final String estimatedCrackTime;

  factory EncryptionMetrics.fromKey(String rawKey) {
    final value = rawKey;
    if (value.trim().isEmpty) {
      return const EncryptionMetrics(
        level: 0,
        label: 'No data',
        entropyBits: 0,
        estimatedCrackTime: 'Instant',
      );
    }

    var alphabet = 0;
    if (RegExp(r'[a-z]').hasMatch(value)) {
      alphabet += 26;
    }
    if (RegExp(r'[A-Z]').hasMatch(value)) {
      alphabet += 26;
    }
    if (RegExp(r'[0-9]').hasMatch(value)) {
      alphabet += 10;
    }
    if (RegExp(r'[а-яё]', caseSensitive: false).hasMatch(value)) {
      alphabet += 33;
    }
    if (RegExp(r'[^A-Za-z0-9А-Яа-яЁё]').hasMatch(value)) {
      alphabet += 20;
    }
    if (alphabet == 0) {
      alphabet = 1;
    }

    final entropy = (value.length * (log(alphabet) / ln2)).round();
    final level = switch (entropy) {
      <= 15 => 1,
      <= 31 => 2,
      <= 63 => 3,
      _ => 4,
    };

    final label = switch (level) {
      1 => 'Weak',
      2 => 'Moderate',
      3 => 'Strong',
      _ => 'Very strong',
    };

    final estimated = switch (entropy) {
      <= 15 => 'Seconds',
      <= 31 => 'Hours',
      <= 47 => 'Weeks',
      <= 63 => 'Years',
      _ => 'Centuries',
    };

    return EncryptionMetrics(
      level: level,
      label: label,
      entropyBits: entropy,
      estimatedCrackTime: estimated,
    );
  }
}
