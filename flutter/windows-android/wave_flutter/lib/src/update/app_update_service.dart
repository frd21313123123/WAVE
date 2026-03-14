import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'app_update_installer.dart';

class AppUpdateService {
  AppUpdateService({
    required this.githubOwner,
    required this.githubRepository,
    Dio? dio,
    AppUpdateInstaller? installer,
  })  : _dio = dio ??
            Dio(
              BaseOptions(
                headers: const <String, String>{
                  HttpHeaders.acceptHeader: 'application/vnd.github+json',
                  HttpHeaders.userAgentHeader: 'wave-flutter-app',
                },
              ),
            ),
        _installer = installer ?? AppUpdateInstaller();

  final String githubOwner;
  final String githubRepository;
  final Dio _dio;
  final AppUpdateInstaller _installer;

  Uri get _latestReleaseUri => Uri.https(
        'api.github.com',
        '/repos/$githubOwner/$githubRepository/releases/latest',
      );

  Future<String> getInstalledVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version.trim();
  }

  Future<AppUpdateCheckResult> checkForUpdates() async {
    try {
      final currentVersion = await getInstalledVersion();
      final response =
          await _dio.getUri<Map<String, dynamic>>(_latestReleaseUri);
      final payload = response.data;

      if (payload == null) {
        return AppUpdateCheckResult(
          currentVersion: currentVersion,
          errorMessage: 'GitHub Releases вернул пустой ответ.',
        );
      }

      final tagName = payload['tag_name']?.toString() ?? '';
      final releaseName = payload['name']?.toString() ?? '';
      final releasePageUrl =
          Uri.tryParse(payload['html_url']?.toString() ?? '');
      if (releasePageUrl == null) {
        return AppUpdateCheckResult(
          currentVersion: currentVersion,
          errorMessage: 'В релизе GitHub нет корректной ссылки.',
        );
      }

      final update = _buildUpdateInfo(
        payload: payload,
        currentVersion: currentVersion,
        releaseTag: tagName,
        releaseName: releaseName,
        latestVersion: _extractVersion('$tagName $releaseName'),
        releasePageUrl: releasePageUrl,
      );

      return AppUpdateCheckResult(
        currentVersion: currentVersion,
        update: update,
      );
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      final message = statusCode == null
          ? 'Не удалось подключиться к GitHub Releases.'
          : 'GitHub Releases вернул HTTP $statusCode.';
      return AppUpdateCheckResult(
        currentVersion: await _safeInstalledVersion(),
        errorMessage: message,
      );
    } catch (error) {
      return AppUpdateCheckResult(
        currentVersion: await _safeInstalledVersion(),
        errorMessage: error.toString(),
      );
    }
  }

  Future<AppUpdateInstallResult> downloadAndInstallUpdate(
    AppUpdateInfo update, {
    void Function(AppUpdateDownloadProgress progress)? onProgress,
  }) async {
    final downloadUrl = update.downloadUrl;
    if (downloadUrl == null) {
      return const AppUpdateInstallResult(
        status: AppUpdateInstallStatus.failed,
        message: 'Для этой платформы в релизе нет установочного файла.',
      );
    }

    final targetFile = await _resolveDownloadTarget(update);
    await targetFile.parent.create(recursive: true);
    if (await targetFile.exists()) {
      await targetFile.delete();
    }

    onProgress?.call(
      const AppUpdateDownloadProgress(
        message: 'Подготавливаем загрузку обновления...',
      ),
    );

    try {
      await _dio.downloadUri(
        downloadUrl,
        targetFile.path,
        deleteOnError: true,
        onReceiveProgress: (received, total) {
          final fraction = total > 0 ? received / total : null;
          onProgress?.call(
            AppUpdateDownloadProgress(
              message: total > 0
                  ? 'Скачиваем обновление... ${(fraction! * 100).toStringAsFixed(0)}%'
                  : 'Скачиваем обновление...',
              fraction: fraction,
            ),
          );
        },
      );
    } on DioException catch (error) {
      return AppUpdateInstallResult(
        status: AppUpdateInstallStatus.failed,
        message: error.message ?? 'Не удалось скачать обновление.',
      );
    } catch (error) {
      return AppUpdateInstallResult(
        status: AppUpdateInstallStatus.failed,
        message: error.toString(),
      );
    }

    final expectedSha256 = _normalizeSha256Digest(update.sha256Digest);
    if (expectedSha256 == null) {
      await targetFile.delete().catchError((_) {});
      return const AppUpdateInstallResult(
        status: AppUpdateInstallStatus.failed,
        message:
            'В релизе отсутствует контрольная сумма SHA-256. Установка из приложения заблокирована.',
      );
    }

    onProgress?.call(
      const AppUpdateDownloadProgress(
        message: 'Проверяем целостность файла...',
      ),
    );

    final actualSha256 = await _computeSha256Hex(targetFile);
    if (actualSha256 != expectedSha256) {
      await targetFile.delete().catchError((_) {});
      return const AppUpdateInstallResult(
        status: AppUpdateInstallStatus.failed,
        message:
            'Проверка целостности обновления не пройдена. Установка отменена.',
      );
    }

    onProgress?.call(
      const AppUpdateDownloadProgress(
        message: 'Запускаем установщик...',
      ),
    );

    return _installer.installDownloadedFile(targetFile.path);
  }

  void dispose() {
    _dio.close(force: true);
  }

  Future<String?> _safeInstalledVersion() async {
    try {
      return await getInstalledVersion();
    } catch (_) {
      return null;
    }
  }


  Future<String> _computeSha256Hex(File file) async {
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString();
  }

  String? _normalizeSha256Digest(String? digest) {
    if (digest == null) {
      return null;
    }

    final trimmed = digest.trim().toLowerCase();
    if (trimmed.isEmpty) {
      return null;
    }

    final normalized = trimmed.startsWith('sha256:')
        ? trimmed.substring('sha256:'.length)
        : trimmed;

    final isHex = RegExp(r'^[a-f0-9]{64}$').hasMatch(normalized);
    return isHex ? normalized : null;
  }

  Future<File> _resolveDownloadTarget(AppUpdateInfo update) async {
    final tempDirectory = await getTemporaryDirectory();
    final safeName = _sanitizeFileName(
      update.assetName ??
          update.downloadUrl?.pathSegments.lastOrNull ??
          'wave-update.bin',
    );
    return File('${tempDirectory.path}/$safeName');
  }

  AppUpdateInfo? _buildUpdateInfo({
    required Map<String, dynamic> payload,
    required String currentVersion,
    required String releaseTag,
    required String releaseName,
    required String? latestVersion,
    required Uri releasePageUrl,
  }) {
    final assets = (payload['assets'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<dynamic, dynamic>>()
        .map((raw) => Map<String, dynamic>.from(raw))
        .toList(growable: false);
    final selectedAsset = _selectAssetForCurrentPlatform(assets);
    final publishedAt =
        DateTime.tryParse(payload['published_at']?.toString() ?? '');
    final resolvedReleaseName =
        releaseName.trim().isNotEmpty ? releaseName.trim() : 'GitHub Release';

    if (latestVersion != null) {
      if (_compareVersions(latestVersion, currentVersion) <= 0) {
        return null;
      }

      return AppUpdateInfo(
        currentVersion: currentVersion,
        latestVersion: latestVersion,
        releaseName: resolvedReleaseName,
        releaseNotes: payload['body']?.toString() ?? '',
        releasePageUrl: releasePageUrl,
        publishedAt: publishedAt,
        downloadUrl: Uri.tryParse(selectedAsset?.downloadUrl ?? ''),
        assetName: selectedAsset?.name,
        sha256Digest: selectedAsset?.sha256Digest,
        actionLabel: _actionLabelForCurrentPlatform(selectedAsset != null),
        canDetermineIfNewer: true,
      );
    }

    if (selectedAsset == null) {
      return null;
    }

    return AppUpdateInfo(
      currentVersion: currentVersion,
      latestVersion: _fallbackReleaseLabel(
        tagName: releaseTag,
        publishedAt: publishedAt,
      ),
      releaseName: resolvedReleaseName,
      releaseNotes: payload['body']?.toString() ?? '',
      releasePageUrl: releasePageUrl,
      publishedAt: publishedAt,
      downloadUrl: Uri.tryParse(selectedAsset.downloadUrl),
      assetName: selectedAsset.name,
      sha256Digest: selectedAsset.sha256Digest,
      actionLabel: _actionLabelForCurrentPlatform(true),
      canDetermineIfNewer: false,
    );
  }

  _GithubReleaseAsset? _selectAssetForCurrentPlatform(
    List<Map<String, dynamic>> assets,
  ) {
    if (assets.isEmpty) {
      return null;
    }

    final options = switch (defaultTargetPlatform) {
      TargetPlatform.android => const <String>['.apk'],
      TargetPlatform.windows => const <String>['.exe', '.msix', '.msi', '.zip'],
      _ => const <String>[],
    };

    for (final suffix in options) {
      for (final asset in assets) {
        final name = asset['name']?.toString() ?? '';
        final url = asset['browser_download_url']?.toString() ?? '';
        if (!name.toLowerCase().endsWith(suffix) || url.isEmpty) {
          continue;
        }

        final digest = _normalizeSha256Digest(asset['digest']?.toString());
        if (digest == null) {
          continue;
        }

        return _GithubReleaseAsset(
          name: name,
          downloadUrl: url,
          sha256Digest: digest,
        );
      }
    }

    return null;
  }

  String _actionLabelForCurrentPlatform(bool hasDirectAsset) {
    return switch (defaultTargetPlatform) {
      TargetPlatform.android =>
        hasDirectAsset ? 'Скачать и установить APK' : 'Открыть релиз',
      TargetPlatform.windows =>
        hasDirectAsset ? 'Скачать и установить' : 'Открыть релиз',
      _ => 'Открыть релиз',
    };
  }

  String _fallbackReleaseLabel({
    required String tagName,
    required DateTime? publishedAt,
  }) {
    if (publishedAt != null) {
      final local = publishedAt.toLocal();
      final year = local.year.toString().padLeft(4, '0');
      final month = local.month.toString().padLeft(2, '0');
      final day = local.day.toString().padLeft(2, '0');
      final hour = local.hour.toString().padLeft(2, '0');
      final minute = local.minute.toString().padLeft(2, '0');
      return '$year-$month-$day $hour:$minute';
    }

    final normalizedTag = tagName.trim();
    return normalizedTag.isNotEmpty ? normalizedTag : 'latest';
  }

  String? _extractVersion(String source) {
    final match = RegExp(
      r'(\d+)\.(\d+)\.(\d+(?:[-+][0-9A-Za-z.-]+)?)',
    ).firstMatch(source);
    if (match == null) {
      return null;
    }

    final major = match.group(1);
    final minor = match.group(2);
    final patch = match.group(3);
    if (major == null || minor == null || patch == null) {
      return null;
    }

    return '$major.$minor.$patch';
  }

  String _sanitizeFileName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'wave-update.bin';
    }

    return trimmed.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  }

  int _compareVersions(String left, String right) {
    final a = _parseVersion(left);
    final b = _parseVersion(right);

    for (var i = 0; i < 3; i += 1) {
      final delta = a.core[i] - b.core[i];
      if (delta != 0) {
        return delta;
      }
    }

    if (a.preRelease == b.preRelease) {
      return 0;
    }
    if (a.preRelease == null) {
      return 1;
    }
    if (b.preRelease == null) {
      return -1;
    }
    return a.preRelease!.compareTo(b.preRelease!);
  }

  _ParsedVersion _parseVersion(String value) {
    final normalized = value.trim();
    final mainAndBuild = normalized.split('+').first;
    final parts = mainAndBuild.split('-');
    final core = parts.first
        .split('.')
        .map((segment) => int.tryParse(segment) ?? 0)
        .toList(growable: false);

    return _ParsedVersion(
      core: <int>[
        core.isNotEmpty ? core[0] : 0,
        core.length > 1 ? core[1] : 0,
        core.length > 2 ? core[2] : 0,
      ],
      preRelease: parts.length > 1 ? parts.sublist(1).join('-') : null,
    );
  }
}

class AppUpdateCheckResult {
  const AppUpdateCheckResult({
    required this.currentVersion,
    this.update,
    this.errorMessage,
  });

  final String? currentVersion;
  final AppUpdateInfo? update;
  final String? errorMessage;

  bool get hasUpdate => update != null;
  bool get hasError => (errorMessage ?? '').isNotEmpty;
}

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseName,
    required this.releaseNotes,
    required this.releasePageUrl,
    required this.actionLabel,
    required this.canDetermineIfNewer,
    this.publishedAt,
    this.downloadUrl,
    this.assetName,
    this.sha256Digest,
  });

  final String currentVersion;
  final String latestVersion;
  final String releaseName;
  final String releaseNotes;
  final Uri releasePageUrl;
  final Uri? downloadUrl;
  final DateTime? publishedAt;
  final String? assetName;
  final String? sha256Digest;
  final String actionLabel;
  final bool canDetermineIfNewer;
}

class _GithubReleaseAsset {
  const _GithubReleaseAsset({
    required this.name,
    required this.downloadUrl,
    required this.sha256Digest,
  });

  final String name;
  final String downloadUrl;
  final String? sha256Digest;
}

class _ParsedVersion {
  const _ParsedVersion({
    required this.core,
    required this.preRelease,
  });

  final List<int> core;
  final String? preRelease;
}
