import 'package:flutter/foundation.dart';

import 'app_update_service.dart';

class UpdateController extends ChangeNotifier {
  UpdateController(this._service);

  final AppUpdateService _service;

  bool _isChecking = false;
  String? _installedVersion;
  String? _lastErrorMessage;
  AppUpdateInfo? _availableUpdate;

  bool get isChecking => _isChecking;
  String? get installedVersion => _installedVersion;
  String? get lastErrorMessage => _lastErrorMessage;
  AppUpdateInfo? get availableUpdate => _availableUpdate;
  bool get hasUpdate => _availableUpdate != null;

  String get updateStatusLabel {
    if (_isChecking) {
      return 'Проверяем GitHub Releases...';
    }
    if (_availableUpdate != null) {
      return _availableUpdate!.canDetermineIfNewer
          ? 'Доступно обновление: ${_availableUpdate!.latestVersion}'
          : 'Доступна последняя сборка для загрузки';
    }
    if ((_lastErrorMessage ?? '').isNotEmpty) {
      return _lastErrorMessage!;
    }
    return 'Установлена версия: ${_installedVersion ?? 'unknown'}';
  }

  Future<void> loadInstalledVersion() async {
    _installedVersion = await _service.getInstalledVersion();
    notifyListeners();
  }

  Future<AppUpdateCheckResult> checkForUpdates() async {
    if (_isChecking) {
      return AppUpdateCheckResult(
        currentVersion: _installedVersion,
        update: _availableUpdate,
        errorMessage: _lastErrorMessage,
      );
    }

    _isChecking = true;
    notifyListeners();

    try {
      final result = await _service.checkForUpdates();
      _installedVersion = result.currentVersion ?? _installedVersion;
      _availableUpdate = result.update;
      _lastErrorMessage = result.errorMessage;
      return result;
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  Future<bool> openUpdate(AppUpdateInfo update) {
    return _service.openUpdate(update);
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
