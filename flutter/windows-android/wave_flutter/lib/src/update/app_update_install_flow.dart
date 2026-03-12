import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app_update_installer.dart';
import 'app_update_service.dart';
import 'update_controller.dart';

typedef UpdateInstallRunner = Future<AppUpdateInstallResult> Function(
  AppUpdateInfo update, {
  void Function(AppUpdateDownloadProgress progress)? onProgress,
});

Future<void> runAppUpdateInstallFlow(
  BuildContext context, {
  required AppUpdateInfo update,
  required UpdateInstallRunner onInstall,
}) async {
  final progress = ValueNotifier<AppUpdateDownloadProgress>(
    const AppUpdateDownloadProgress(
      message: 'Подготавливаем обновление...',
    ),
  );

  unawaited(
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return PopScope(
          canPop: false,
          child: ValueListenableBuilder<AppUpdateDownloadProgress>(
            valueListenable: progress,
            builder: (context, state, _) {
              return AlertDialog(
                title: const Text('Установка обновления'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(state.message),
                    const SizedBox(height: 16),
                    if (state.fraction == null)
                      const Center(child: CircularProgressIndicator())
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LinearProgressIndicator(value: state.fraction),
                          const SizedBox(height: 8),
                          Text(
                              '${(state.fraction! * 100).toStringAsFixed(0)}%'),
                        ],
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    ),
  );

  await Future<void>.delayed(Duration.zero);

  final result = await onInstall(
    update,
    onProgress: (next) {
      progress.value = next;
    },
  );

  progress.dispose();

  if (context.mounted) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  if (!context.mounted) {
    return;
  }

  final messenger = ScaffoldMessenger.of(context);
  switch (result.status) {
    case AppUpdateInstallStatus.installerLaunched:
      messenger.showSnackBar(
        SnackBar(content: Text(result.message)),
      );
      if (!kIsWeb &&
          defaultTargetPlatform == TargetPlatform.windows &&
          result.shouldCloseApp) {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        exit(0);
      }
    case AppUpdateInstallStatus.permissionRequired:
      messenger.showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    case AppUpdateInstallStatus.unsupported:
    case AppUpdateInstallStatus.failed:
      messenger.showSnackBar(
        SnackBar(content: Text(result.message)),
      );
  }
}

Future<void> runManagedAppUpdateInstallFlow(
  BuildContext context, {
  required UpdateController controller,
  required AppUpdateInfo update,
}) {
  return runAppUpdateInstallFlow(
    context,
    update: update,
    onInstall: controller.downloadAndInstallUpdate,
  );
}
