import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_windows/webview_windows.dart';

import '../theme/app_theme.dart';
import '../update/app_update_service.dart';
import '../update/update_prompt.dart';
import '../widgets/wave_brand_logo.dart';
import 'desktop_shell_settings_store.dart';

Future<void> runWaveWindowsShellApp() async {
  final settingsStore = DesktopShellSettingsStore();
  final initialSettings = await settingsStore.read();
  final webViewVersion = await WebviewController.getWebViewVersion();

  if (webViewVersion != null) {
    final userDataPath = await settingsStore.ensureWebViewDataPath();
    await WebviewController.initializeEnvironment(userDataPath: userDataPath);
  }

  runApp(
    WaveWindowsShellApp(
      settingsStore: settingsStore,
      initialSettings: initialSettings,
      webViewVersion: webViewVersion,
    ),
  );
}

class WaveWindowsShellApp extends StatelessWidget {
  const WaveWindowsShellApp({
    super.key,
    required this.settingsStore,
    required this.initialSettings,
    required this.webViewVersion,
  });

  final DesktopShellSettingsStore settingsStore;
  final DesktopShellSettings initialSettings;
  final String? webViewVersion;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wave Messenger',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: WaveWindowsShellScreen(
        settingsStore: settingsStore,
        initialSettings: initialSettings,
        webViewVersion: webViewVersion,
      ),
    );
  }
}

class WaveWindowsShellScreen extends StatefulWidget {
  const WaveWindowsShellScreen({
    super.key,
    required this.settingsStore,
    required this.initialSettings,
    required this.webViewVersion,
  });

  final DesktopShellSettingsStore settingsStore;
  final DesktopShellSettings initialSettings;
  final String? webViewVersion;

  @override
  State<WaveWindowsShellScreen> createState() => _WaveWindowsShellScreenState();
}

class _WaveWindowsShellScreenState extends State<WaveWindowsShellScreen> {
  late final WebviewController _controller;
  late final TextEditingController _urlController;
  late final AppUpdateService _updateService;

  StreamSubscription<LoadingState>? _loadingSubscription;
  StreamSubscription<WebErrorStatus>? _loadErrorSubscription;

  late DesktopShellSettings _settings;

  bool _controllerReady = false;
  bool _controllerInitializeCalled = false;
  bool _initializing = true;
  bool _loading = true;
  bool _checkingForUpdates = false;
  String? _fatalError;
  WebErrorStatus? _loadError;
  String? _installedVersion;
  AppUpdateInfo? _availableUpdate;
  String? _updateError;

  @override
  void initState() {
    super.initState();
    _controller = WebviewController();
    _updateService = AppUpdateService(
      githubOwner: 'frd21313123123',
      githubRepository: 'WAVE',
    );
    _settings = widget.initialSettings;
    _urlController =
        TextEditingController(text: widget.initialSettings.baseUrl);
    unawaited(_initializeShell());
    unawaited(_primeUpdateState());
  }

  @override
  void dispose() {
    _urlController.dispose();
    unawaited(_loadingSubscription?.cancel() ?? Future<void>.value());
    unawaited(_loadErrorSubscription?.cancel() ?? Future<void>.value());
    unawaited(_disposeController());
    _updateService.dispose();
    super.dispose();
  }

  Future<void> _primeUpdateState() async {
    final installedVersion = await _updateService.getInstalledVersion();
    if (!mounted) {
      return;
    }
    setState(() {
      _installedVersion = installedVersion;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_checkForUpdates(showPrompt: false));
    });
  }

  Future<void> _initializeShell() async {
    setState(() {
      _fatalError = null;
      _loadError = null;
      _controllerReady = false;
      _initializing = true;
      _loading = true;
    });

    try {
      if (widget.webViewVersion == null) {
        throw const _WindowsShellException(
          'Microsoft Edge WebView2 Runtime was not found. '
          'Install it and restart the app.',
        );
      }

      _controllerInitializeCalled = true;
      await _controller.initialize();
      _bindControllerStreams();
      await _controller.setBackgroundColor(const Color(0xFF0E1621));
      await _controller.setPopupWindowPolicy(
        WebviewPopupWindowPolicy.sameWindow,
      );
      await _controller.loadUrl(buildDesktopShellUrl(_settings.baseUrl));

      if (!mounted) {
        return;
      }
      setState(() {
        _controllerReady = true;
        _initializing = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _fatalError = _formatError(error);
        _initializing = false;
        _loading = false;
      });
    }
  }

  Future<void> _disposeController() async {
    if (!_controllerInitializeCalled) {
      return;
    }
    try {
      await _controller.dispose();
    } catch (_) {
      // Ignore teardown failures during widget disposal.
    }
  }

  void _bindControllerStreams() {
    _loadingSubscription?.cancel();
    _loadErrorSubscription?.cancel();

    _loadingSubscription = _controller.loadingState.listen((state) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = state == LoadingState.loading;
        if (state == LoadingState.loading) {
          _loadError = null;
        }
      });
    });

    _loadErrorSubscription = _controller.onLoadError.listen((status) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadError = status;
      });
    });
  }

  Future<void> _reload() async {
    if (_fatalError != null && !_controllerReady) {
      await _initializeShell();
      return;
    }
    if (!_controllerReady) {
      return;
    }
    setState(() {
      _loading = true;
      _fatalError = null;
      _loadError = null;
    });
    await _controller.reload();
  }

  Future<void> _openSettingsDialog() async {
    final action = await showDialog<_WindowsShellDialogAction>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Wave Windows'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _urlController,
                  decoration: const InputDecoration(
                    labelText: 'URL веб-версии',
                    hintText: 'http://127.0.0.1:3000',
                    prefixIcon: Icon(Icons.link_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      label: const Text('Localhost'),
                      onPressed: () {
                        _urlController.text = defaultDesktopBaseUrl;
                      },
                    ),
                    ActionChip(
                      label: const Text('VPS'),
                      onPressed: () {
                        _urlController.text = desktopVpsBaseUrl;
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Windows-версия открывает ту же веб-версию, что и браузер. '
                  'Укажи тот же URL, чтобы функционал совпадал один в один.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  'Версия приложения: ${_installedVersion ?? 'unknown'}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  _checkingForUpdates
                      ? 'Проверка обновлений...'
                      : _availableUpdate != null
                          ? 'Доступно обновление ${_availableUpdate!.latestVersion}'
                          : (_updateError ?? 'Обновлений не найдено.'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(
                _WindowsShellDialogAction.clearSession,
              ),
              child: const Text('Очистить session'),
            ),
            TextButton(
              onPressed: _checkingForUpdates
                  ? null
                  : () => Navigator.of(context).pop(
                        _WindowsShellDialogAction.checkForUpdates,
                      ),
              child: const Text('Проверить обновления'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(
                _WindowsShellDialogAction.saveAndOpen,
              ),
              child: const Text('Сохранить и открыть'),
            ),
          ],
        );
      },
    );

    switch (action) {
      case _WindowsShellDialogAction.clearSession:
        await _clearSession();
      case _WindowsShellDialogAction.checkForUpdates:
        await _checkForUpdates(showPrompt: true);
      case _WindowsShellDialogAction.saveAndOpen:
        await _saveAndOpenRequestedUrl();
      case null:
        break;
    }
  }

  Future<void> _checkForUpdates({required bool showPrompt}) async {
    if (_checkingForUpdates) {
      return;
    }

    setState(() {
      _checkingForUpdates = true;
      _updateError = null;
    });

    try {
      final result = await _updateService.checkForUpdates();
      if (!mounted) {
        return;
      }

      setState(() {
        _installedVersion = result.currentVersion ?? _installedVersion;
        _availableUpdate = result.update;
        _updateError = result.errorMessage;
      });

      if (result.hasError) {
        if (showPrompt) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.errorMessage!)),
          );
        }
        return;
      }

      final update = result.update;
      if (update == null) {
        if (showPrompt) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Установлена актуальная версия (${result.currentVersion ?? _installedVersion ?? 'unknown'}).',
              ),
            ),
          );
        }
        return;
      }

      if (!showPrompt) {
        return;
      }

      final shouldOpen = await showAppUpdateDialog(context, update: update);
      if (shouldOpen != true || !mounted) {
        return;
      }

      final opened = await _updateService.openUpdate(update);
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Не удалось открыть ссылку на обновление.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _checkingForUpdates = false;
        });
      }
    }
  }

  Future<void> _saveAndOpenRequestedUrl() async {
    final nextBaseUrl = sanitizeDesktopBaseUrl(
      _urlController.text,
      fallback: _settings.baseUrl,
    );
    final nextSettings = _settings.copyWith(baseUrl: nextBaseUrl);

    await widget.settingsStore.write(nextSettings);

    setState(() {
      _settings = nextSettings;
      _fatalError = null;
      _loadError = null;
    });

    if (_controllerReady) {
      await _controller.loadUrl(buildDesktopShellUrl(nextBaseUrl));
      return;
    }

    await _initializeShell();
  }

  Future<void> _clearSession() async {
    if (!_controllerReady) {
      return;
    }
    await _controller.clearCookies();
    await _controller.clearCache();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cookies и cache очищены.')),
    );
  }

  Future<WebviewPermissionDecision> _handlePermissionRequest(
    String url,
    WebviewPermissionKind permissionKind,
    bool isUserInitiated,
  ) async {
    final requestedUri = Uri.tryParse(url);
    final allowedHost = Uri.tryParse(_settings.baseUrl)?.host;
    if (requestedUri == null || requestedUri.host != allowedHost) {
      return WebviewPermissionDecision.deny;
    }

    if (permissionKind == WebviewPermissionKind.unknown) {
      return WebviewPermissionDecision.none;
    }

    final permissionLabel = switch (permissionKind) {
      WebviewPermissionKind.microphone => 'микрофон',
      WebviewPermissionKind.camera => 'камеру',
      WebviewPermissionKind.notifications => 'уведомления',
      WebviewPermissionKind.geoLocation => 'геолокацию',
      WebviewPermissionKind.clipboardRead => 'буфер обмена',
      WebviewPermissionKind.otherSensors => 'датчики',
      WebviewPermissionKind.unknown => 'системный доступ',
    };

    final decision = await showDialog<WebviewPermissionDecision>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Разрешение для веб-клиента'),
          content: Text(
            'Веб-версия Wave запрашивает доступ к "$permissionLabel".\n\n'
            'Запрос инициирован пользователем: ${isUserInitiated ? 'да' : 'нет'}.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(
                WebviewPermissionDecision.deny,
              ),
              child: const Text('Запретить'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(
                WebviewPermissionDecision.allow,
              ),
              child: const Text('Разрешить'),
            ),
          ],
        );
      },
    );

    return decision ?? WebviewPermissionDecision.deny;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Column(
        children: [
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    scheme.primary.withValues(alpha: 0.14),
                    scheme.tertiary.withValues(alpha: 0.12),
                    scheme.surface,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: _buildBody(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_fatalError != null) {
      return _WindowsShellErrorView(
        message: _fatalError!,
        baseUrl: _settings.baseUrl,
        onRetry: _initializeShell,
      );
    }

    if (_initializing || !_controllerReady) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            WaveBrandLogo(
              size: 108,
              semanticLabel: 'Wave logo',
            ),
            SizedBox(height: 18),
            CircularProgressIndicator(),
          ],
        ),
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: Webview(
            _controller,
            permissionRequested: _handlePermissionRequest,
          ),
        ),
        if (_loadError != null)
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: Material(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(20),
              elevation: 10,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.wifi_off_rounded,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Не удалось загрузить веб-клиент: $_loadError',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onErrorContainer,
                            ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: _openSettingsDialog,
                      child: const Text('URL'),
                    ),
                    FilledButton.tonal(
                      onPressed: _reload,
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _formatError(Object error) {
    if (error is _WindowsShellException) {
      return error.message;
    }
    return 'Failed to open the Wave web app inside the Windows shell.\n$error';
  }
}

class _WindowsShellErrorView extends StatelessWidget {
  const _WindowsShellErrorView({
    required this.message,
    required this.baseUrl,
    required this.onRetry,
  });

  final String message;
  final String baseUrl;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const WaveBrandLogo(
                  size: 54,
                  semanticLabel: 'Wave logo',
                ),
                const SizedBox(height: 18),
                Text(
                  'Windows shell unavailable',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 18),
                SelectableText(
                  baseUrl,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: baseUrl));
                        if (!context.mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Server URL copied to clipboard.'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_all_rounded),
                      label: const Text('Copy URL'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WindowsShellException implements Exception {
  const _WindowsShellException(this.message);

  final String message;
}

enum _WindowsShellDialogAction {
  saveAndOpen,
  clearSession,
  checkForUpdates,
}
