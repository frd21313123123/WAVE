import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/app_models.dart';
import '../services/api_client.dart';
import '../services/settings_store.dart';
import 'app_settings.dart';
import 'vigenere_cipher.dart';

enum SettingsFeedbackArea {
  appearance,
  theme,
  encryption,
  sounds,
  security,
  account,
}

class SettingsFeedback {
  const SettingsFeedback({
    required this.message,
    this.isError = false,
  });

  final String message;
  final bool isError;
}

enum SettingsAsyncTask {
  bootstrap,
  appearance,
  security,
  account,
}

class SettingsController extends ChangeNotifier {
  SettingsController({
    required ApiClient apiClient,
    required SettingsStore settingsStore,
    PublicUser? initialUser,
    this.onUserChanged,
    this.onAccountDeleted,
  })  : _apiClient = apiClient,
        _settingsStore = settingsStore,
        _currentUser = _cloneNullableUser(initialUser);

  static const int _maxAvatarBytes = 1572864;
  static const Set<String> _allowedAvatarMimeTypes = {
    'image/png',
    'image/jpeg',
    'image/jpg',
    'image/webp',
    'image/gif',
  };

  final ApiClient _apiClient;
  final SettingsStore _settingsStore;
  final ValueChanged<PublicUser?>? onUserChanged;
  final AsyncCallback? onAccountDeleted;

  AppSettings _settings = const AppSettings();
  PublicUser? _currentUser;
  TwoFactorSetupData? _twoFactorSetup;
  final Map<SettingsFeedbackArea, SettingsFeedback> _feedback = {};
  final Set<SettingsAsyncTask> _activeTasks = <SettingsAsyncTask>{};
  bool _encryptionKeyVisible = false;
  bool _bootstrapped = false;

  AppSettings get settings => _settings;
  PublicUser? get currentUser => _currentUser;
  TwoFactorSetupData? get twoFactorSetup => _twoFactorSetup;
  bool get encryptionKeyVisible => _encryptionKeyVisible;
  bool get isBootstrapped => _bootstrapped;
  bool get isBusy => _activeTasks.isNotEmpty;
  bool get canManageRemoteSettings => _currentUser != null;
  EncryptionMetrics get encryptionMetrics =>
      EncryptionMetrics.fromKey(_settings.vigenereKey);

  SettingsFeedback? feedbackFor(SettingsFeedbackArea area) => _feedback[area];

  bool isTaskActive(SettingsAsyncTask task) => _activeTasks.contains(task);

  bool isAreaBusy(SettingsFeedbackArea area) {
    return switch (area) {
      SettingsFeedbackArea.appearance =>
        _activeTasks.contains(SettingsAsyncTask.appearance),
      SettingsFeedbackArea.security =>
        _activeTasks.contains(SettingsAsyncTask.bootstrap) ||
            _activeTasks.contains(SettingsAsyncTask.security),
      SettingsFeedbackArea.account =>
        _activeTasks.contains(SettingsAsyncTask.account),
      _ => false,
    };
  }

  Future<void> bootstrap() async {
    if (_bootstrapped) {
      return;
    }

    await _runTask(SettingsAsyncTask.bootstrap, () async {
      _settings = await _settingsStore.load();
      _bootstrapped = true;
      notifyListeners();

      if (_currentUser != null) {
        await _refreshTwoFactorStatus(trackTask: false, silent: true);
      }
    });
  }

  void replaceCurrentUser(PublicUser? user) {
    _setCurrentUser(user, publish: false);
    if (_bootstrapped && user != null) {
      unawaited(_refreshTwoFactorStatus(silent: true));
    }
  }

  void clearFeedback(SettingsFeedbackArea area) {
    if (_feedback.remove(area) != null) {
      notifyListeners();
    }
  }

  void setThemeMode(WaveThemeMode themeMode) {
    _updateSettings(_settings.copyWith(themeMode: themeMode));
  }

  void setFullscreen(bool fullscreen) {
    _updateSettings(_settings.copyWith(fullscreen: fullscreen));
  }

  void setVigenereEnabled(bool enabled) {
    clearFeedback(SettingsFeedbackArea.encryption);
    _updateSettings(_settings.copyWith(vigenereEnabled: enabled));
  }

  void setVigenereKey(String key) {
    clearFeedback(SettingsFeedbackArea.encryption);
    _updateSettings(_settings.copyWith(vigenereKey: key));
  }

  Future<void> saveEncryptionPreferences() async {
    await _persistSettings(
      area: SettingsFeedbackArea.encryption,
      successMessage: 'Encryption preferences saved on this device.',
    );
  }

  void setMicrophoneVolume(double value) {
    clearFeedback(SettingsFeedbackArea.sounds);
    _updateSettings(
      _settings.copyWith(microphoneVolume: value.round()),
    );
  }

  void setSpeakerVolume(double value) {
    clearFeedback(SettingsFeedbackArea.sounds);
    _updateSettings(
      _settings.copyWith(speakerVolume: value.round()),
    );
  }

  void setCallSoundsEnabled(bool enabled) {
    clearFeedback(SettingsFeedbackArea.sounds);
    _updateSettings(_settings.copyWith(callSoundsEnabled: enabled));
  }

  void setNotificationsEnabled(bool enabled) {
    clearFeedback(SettingsFeedbackArea.sounds);
    _updateSettings(_settings.copyWith(notificationsEnabled: enabled));
  }

  Future<void> saveSoundPreferences() async {
    await _persistSettings(
      area: SettingsFeedbackArea.sounds,
      successMessage: 'Sound preferences saved on this device.',
    );
  }

  void setEncryptionKeyVisible(bool visible) {
    if (_encryptionKeyVisible == visible) {
      return;
    }
    _encryptionKeyVisible = visible;
    notifyListeners();
  }

  void toggleEncryptionKeyVisibility() {
    setEncryptionKeyVisible(!_encryptionKeyVisible);
  }

  String encryptMessage(String text) {
    return vigenereEncrypt(
      text,
      _settings.vigenereKey,
      fallbackKey: AppSettings.defaultVigenereKey,
    );
  }

  String decryptMessage(String text) {
    return vigenereDecrypt(
      text,
      _settings.vigenereKey,
      fallbackKey: AppSettings.defaultVigenereKey,
    );
  }

  bool isMessageEncrypted(ChatMessage message) {
    return message.encryption?['type'] == 'vigenere';
  }

  String decodeMessageText(ChatMessage message) {
    if (!isMessageEncrypted(message)) {
      return message.text;
    }
    return decryptMessage(message.text);
  }

  Map<String, dynamic> buildOutgoingTextPayload(String plainText) {
    final payload = <String, dynamic>{'text': plainText};
    if (!_settings.vigenereEnabled) {
      return payload;
    }

    payload['text'] = encryptMessage(plainText);
    payload['encryption'] = const {'type': 'vigenere'};
    return payload;
  }

  Future<void> updateDisplayName(String value) async {
    if (_currentUser == null) {
      _setFeedback(
        SettingsFeedbackArea.appearance,
        'Sign in first to edit your profile.',
        isError: true,
      );
      return;
    }

    await _runTask(SettingsAsyncTask.appearance, () async {
      try {
        final response = await _apiClient.put(
          '/api/auth/profile',
          data: {'displayName': value.trim()},
        );
        _currentUser!.displayName = response['displayName'] as String?;
        _setFeedback(
          SettingsFeedbackArea.appearance,
          'Display name updated.',
        );
        _publishCurrentUser();
      } on ApiException catch (error) {
        _setFeedback(
          SettingsFeedbackArea.appearance,
          error.message,
          isError: true,
        );
      }
    });
  }

  Future<void> uploadAvatarBytes(
    Uint8List bytes, {
    String mimeType = 'image/png',
  }) async {
    if (_currentUser == null) {
      _setFeedback(
        SettingsFeedbackArea.appearance,
        'Sign in first to edit your profile.',
        isError: true,
      );
      return;
    }

    final normalizedMimeType = mimeType.trim().toLowerCase();
    if (!_allowedAvatarMimeTypes.contains(normalizedMimeType)) {
      _setFeedback(
        SettingsFeedbackArea.appearance,
        'Only PNG, JPEG, WEBP, and GIF avatars are supported.',
        isError: true,
      );
      return;
    }
    if (bytes.isEmpty) {
      _setFeedback(
        SettingsFeedbackArea.appearance,
        'The selected avatar is empty.',
        isError: true,
      );
      return;
    }
    if (bytes.lengthInBytes > _maxAvatarBytes) {
      _setFeedback(
        SettingsFeedbackArea.appearance,
        'Avatar must be 1.5MB or smaller.',
        isError: true,
      );
      return;
    }

    await _runTask(SettingsAsyncTask.appearance, () async {
      try {
        final dataUrl =
            'data:$normalizedMimeType;base64,${base64Encode(bytes)}';
        final response = await _apiClient.post(
          '/api/auth/avatar',
          data: {'avatar': dataUrl},
        );
        _currentUser!.avatarUrl = response['avatarUrl'] as String?;
        _setFeedback(
          SettingsFeedbackArea.appearance,
          'Avatar updated.',
        );
        _publishCurrentUser();
      } on ApiException catch (error) {
        _setFeedback(
          SettingsFeedbackArea.appearance,
          error.message,
          isError: true,
        );
      }
    });
  }

  Future<void> refreshTwoFactorStatus({bool silent = false}) {
    return _refreshTwoFactorStatus(silent: silent);
  }

  Future<void> beginTwoFactorSetup() async {
    if (_currentUser == null) {
      _setFeedback(
        SettingsFeedbackArea.security,
        'Sign in first to manage 2FA.',
        isError: true,
      );
      return;
    }

    await _runTask(SettingsAsyncTask.security, () async {
      try {
        final response = await _apiClient.post('/api/auth/2fa/setup');
        _twoFactorSetup = TwoFactorSetupData.fromJson(response);
        _setFeedback(
          SettingsFeedbackArea.security,
          'Scan the QR code and confirm with a 6-digit authenticator code.',
        );
        notifyListeners();
      } on ApiException catch (error) {
        _setFeedback(
          SettingsFeedbackArea.security,
          error.message,
          isError: true,
        );
      }
    });
  }

  Future<void> enableTwoFactor(String token) async {
    if (_currentUser == null) {
      _setFeedback(
        SettingsFeedbackArea.security,
        'Sign in first to manage 2FA.',
        isError: true,
      );
      return;
    }

    final normalized = _normalizeOtpToken(token);
    if (normalized.length != 6) {
      _setFeedback(
        SettingsFeedbackArea.security,
        'Enter the 6-digit code from your authenticator app.',
        isError: true,
      );
      return;
    }

    await _runTask(SettingsAsyncTask.security, () async {
      try {
        await _apiClient.post(
          '/api/auth/2fa/enable',
          data: {'token': normalized},
        );
        _currentUser!.twoFactorEnabled = true;
        _twoFactorSetup = null;
        _setFeedback(
          SettingsFeedbackArea.security,
          '2FA enabled for this account.',
        );
        _publishCurrentUser();
        notifyListeners();
      } on ApiException catch (error) {
        _setFeedback(
          SettingsFeedbackArea.security,
          error.message,
          isError: true,
        );
      }
    });
  }

  Future<void> disableTwoFactor(String token) async {
    if (_currentUser == null) {
      _setFeedback(
        SettingsFeedbackArea.security,
        'Sign in first to manage 2FA.',
        isError: true,
      );
      return;
    }

    final normalized = _normalizeOtpToken(token);
    if (normalized.length != 6) {
      _setFeedback(
        SettingsFeedbackArea.security,
        'Enter the current 6-digit 2FA code to disable protection.',
        isError: true,
      );
      return;
    }

    await _runTask(SettingsAsyncTask.security, () async {
      try {
        await _apiClient.post(
          '/api/auth/2fa/disable',
          data: {'token': normalized},
        );
        _currentUser!.twoFactorEnabled = false;
        _twoFactorSetup = null;
        _setFeedback(
          SettingsFeedbackArea.security,
          '2FA disabled for this account.',
        );
        _publishCurrentUser();
        notifyListeners();
      } on ApiException catch (error) {
        _setFeedback(
          SettingsFeedbackArea.security,
          error.message,
          isError: true,
        );
      }
    });
  }

  Future<void> deleteAccount() async {
    if (_currentUser == null) {
      _setFeedback(
        SettingsFeedbackArea.account,
        'Sign in first to manage your account.',
        isError: true,
      );
      return;
    }

    await _runTask(SettingsAsyncTask.account, () async {
      try {
        await _apiClient.delete('/api/auth/account');
        await _apiClient.clearCookies();
        await _settingsStore.clear();
        _settings = const AppSettings();
        _twoFactorSetup = null;
        _bootstrapped = true;
        _setCurrentUser(null);
        _setFeedback(
          SettingsFeedbackArea.account,
          'Account deleted.',
        );
        if (onAccountDeleted != null) {
          await onAccountDeleted!.call();
        }
      } on ApiException catch (error) {
        _setFeedback(
          SettingsFeedbackArea.account,
          error.message,
          isError: true,
        );
      }
    });
  }

  void _updateSettings(AppSettings nextSettings) {
    if (_settings.toJson().toString() == nextSettings.toJson().toString()) {
      return;
    }

    _settings = nextSettings;
    notifyListeners();
    unawaited(_persistSettings());
  }

  Future<void> _persistSettings({
    SettingsFeedbackArea? area,
    String? successMessage,
  }) async {
    try {
      await _settingsStore.save(_settings);
      if (area != null && successMessage != null) {
        _setFeedback(area, successMessage);
      }
    } catch (_) {
      if (area != null) {
        _setFeedback(
          area,
          'Failed to save preferences on this device.',
          isError: true,
        );
      }
    }
  }

  Future<void> _refreshTwoFactorStatus({
    bool silent = false,
    bool trackTask = true,
  }) {
    if (_currentUser == null) {
      return Future.value();
    }

    if (trackTask) {
      return _runTask(
        SettingsAsyncTask.security,
        () => _refreshTwoFactorStatus(
          silent: silent,
          trackTask: false,
        ),
      );
    }

    return _refreshTwoFactorStatusInternal(silent: silent);
  }

  Future<void> _refreshTwoFactorStatusInternal({bool silent = false}) async {
    try {
      final response = await _apiClient.get('/api/auth/2fa/status');
      final enabled = response['enabled'] == true;
      _currentUser!.twoFactorEnabled = enabled;
      if (!enabled) {
        _twoFactorSetup = null;
      }
      if (!silent) {
        _setFeedback(
          SettingsFeedbackArea.security,
          enabled
              ? '2FA is enabled for this account.'
              : '2FA is currently disabled.',
        );
      }
      _publishCurrentUser();
      notifyListeners();
    } on ApiException catch (error) {
      if (!silent) {
        _setFeedback(
          SettingsFeedbackArea.security,
          error.message,
          isError: true,
        );
      }
    }
  }

  Future<void> _runTask(
    SettingsAsyncTask task,
    Future<void> Function() action,
  ) async {
    final inserted = _activeTasks.add(task);
    if (inserted) {
      notifyListeners();
    }

    try {
      await action();
    } finally {
      if (_activeTasks.remove(task)) {
        notifyListeners();
      }
    }
  }

  void _publishCurrentUser() {
    onUserChanged?.call(_cloneNullableUser(_currentUser));
    notifyListeners();
  }

  void _setCurrentUser(PublicUser? user, {bool publish = true}) {
    _currentUser = _cloneNullableUser(user);
    if (publish) {
      onUserChanged?.call(_cloneNullableUser(_currentUser));
    }
    notifyListeners();
  }

  void _setFeedback(
    SettingsFeedbackArea area,
    String message, {
    bool isError = false,
  }) {
    _feedback[area] = SettingsFeedback(
      message: message,
      isError: isError,
    );
    notifyListeners();
  }

  static String _normalizeOtpToken(String value) {
    return value.replaceAll(RegExp(r'\D+'), '').substring(
          0,
          value.replaceAll(RegExp(r'\D+'), '').length.clamp(0, 6),
        );
  }

  static PublicUser? _cloneNullableUser(PublicUser? user) {
    if (user == null) {
      return null;
    }
    return PublicUser.fromJson(user.toJson());
  }
}
