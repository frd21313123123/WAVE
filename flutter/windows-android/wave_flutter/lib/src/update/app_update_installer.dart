import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum AppUpdateInstallStatus {
  installerLaunched,
  permissionRequired,
  unsupported,
  failed,
}

class AppUpdateDownloadProgress {
  const AppUpdateDownloadProgress({
    required this.message,
    this.fraction,
  });

  final String message;
  final double? fraction;
}

class AppUpdateInstallResult {
  const AppUpdateInstallResult({
    required this.status,
    required this.message,
    this.shouldCloseApp = false,
  });

  final AppUpdateInstallStatus status;
  final String message;
  final bool shouldCloseApp;

  bool get isSuccess => status == AppUpdateInstallStatus.installerLaunched;
  bool get requiresPermission =>
      status == AppUpdateInstallStatus.permissionRequired;
}

class AppUpdateInstaller {
  static const MethodChannel _channel = MethodChannel(
    'com.wave.messenger/updater',
  );

  Future<AppUpdateInstallResult> installDownloadedFile(String filePath) async {
    if (kIsWeb) {
      return const AppUpdateInstallResult(
        status: AppUpdateInstallStatus.unsupported,
        message: 'Веб-платформа не поддерживает установку обновлений.',
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _installViaChannel(filePath);
      case TargetPlatform.windows:
        return _installOnWindows(filePath);
      default:
        return const AppUpdateInstallResult(
          status: AppUpdateInstallStatus.unsupported,
          message:
              'Эта платформа не поддерживает установку обновлений из приложения.',
        );
    }
  }

  Future<AppUpdateInstallResult> _installViaChannel(String filePath) async {
    try {
      final response = await _channel.invokeMapMethod<String, dynamic>(
        'installDownloadedUpdate',
        <String, dynamic>{
          'filePath': filePath,
          'path': filePath,
        },
      );
      final launched = response?['launched'] == true;
      final statusRaw = launched
          ? 'installer_launched'
          : response?['status']?.toString() ?? 'failed';
      final message = response?['message']?.toString() ??
          (launched
              ? 'Установщик запущен.'
              : 'Не удалось запустить установщик.');
      final shouldCloseApp = response?['closeRequested'] == true;

      return AppUpdateInstallResult(
        status: switch (statusRaw) {
          'installer_launched' => AppUpdateInstallStatus.installerLaunched,
          'permission_required' => AppUpdateInstallStatus.permissionRequired,
          'unsupported' => AppUpdateInstallStatus.unsupported,
          _ => AppUpdateInstallStatus.failed,
        },
        message: message,
        shouldCloseApp: shouldCloseApp,
      );
    } on PlatformException catch (error) {
      return AppUpdateInstallResult(
        status: AppUpdateInstallStatus.failed,
        message: error.message ?? error.code,
      );
    }
  }

  Future<AppUpdateInstallResult> _installOnWindows(String filePath) async {
    final channelResult = await _installViaChannel(filePath);
    if (channelResult.isSuccess) {
      return channelResult;
    }

    try {
      await Process.start(
        filePath,
        const <String>[],
        mode: ProcessStartMode.detached,
      );
      return AppUpdateInstallResult(
        status: AppUpdateInstallStatus.installerLaunched,
        message: 'Установщик запущен.',
        shouldCloseApp: _shouldCloseForFile(filePath),
      );
    } catch (error) {
      return AppUpdateInstallResult(
        status: AppUpdateInstallStatus.failed,
        message: error.toString(),
      );
    }
  }

  bool _shouldCloseForFile(String filePath) {
    final normalized = filePath.toLowerCase();
    return normalized.endsWith('.exe') ||
        normalized.endsWith('.msi') ||
        normalized.endsWith('.msix') ||
        normalized.endsWith('.msixbundle') ||
        normalized.endsWith('.appinstaller');
  }
}
