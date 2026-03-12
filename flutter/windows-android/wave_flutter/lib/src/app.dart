import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'calls/calls.dart';
import 'config/app_config.dart';
import 'controllers/chat_controller.dart';
import 'controllers/session_controller.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'services/api_client.dart';
import 'services/notification_service.dart';
import 'services/realtime_service.dart';
import 'services/session_store.dart';
import 'services/settings_store.dart';
import 'settings/app_settings.dart';
import 'settings/settings_controller.dart';
import 'theme/app_theme.dart';
import 'update/app_update_service.dart';
import 'update/update_check_gate.dart';
import 'update/update_controller.dart';
import 'widgets/wave_brand_logo.dart';

class AppBootstrap {
  AppBootstrap({
    required this.appConfig,
    required this.apiClient,
    required this.realtimeService,
    required this.chatController,
    required this.sessionController,
    required this.settingsController,
    required this.notificationService,
    required this.callController,
    required this.updateController,
  });

  final AppConfig appConfig;
  final ApiClient apiClient;
  final RealtimeService realtimeService;
  final ChatController chatController;
  final SessionController sessionController;
  final SettingsController settingsController;
  final NotificationService notificationService;
  final CallController callController;
  final UpdateController updateController;

  static Future<AppBootstrap> initialize({AppConfig? appConfig}) async {
    final resolvedAppConfig = appConfig ?? await AppConfig.load();
    final apiClient = await ApiClient.create(resolvedAppConfig);
    final sessionStore = await SessionStore.create();
    final settingsStore = await SettingsStore.create();
    final realtimeService = RealtimeService(
      apiClient: apiClient,
      appConfig: resolvedAppConfig,
    );
    final notificationService = NotificationService(
      apiClient: apiClient,
      realtimeService: realtimeService,
      appConfig: resolvedAppConfig,
    );
    await notificationService.initialize();
    final chatController = ChatController(
      apiClient: apiClient,
      realtimeService: realtimeService,
    );
    final sessionController = SessionController(
      apiClient: apiClient,
      appConfig: resolvedAppConfig,
      chatController: chatController,
      sessionStore: sessionStore,
      beforeLogout: notificationService.prepareForLogout,
    );

    await sessionController.bootstrap();

    final settingsController = SettingsController(
      apiClient: apiClient,
      settingsStore: settingsStore,
      initialUser: sessionController.currentUser,
      onUserChanged: (user) {
        if (user != null) {
          sessionController.synchronizeCurrentUser(user);
        }
      },
      onAccountDeleted: sessionController.handleAccountDeleted,
    );
    await settingsController.bootstrap();
    notificationService.bindControllers(
      sessionController: sessionController,
      chatController: chatController,
      settingsController: settingsController,
    );

    final callController = CallController(
      chatController: chatController,
      realtimeService: realtimeService,
      mediaEngineFactory: () => FlutterWebRtcCallEngine(),
    );
    final updateController = UpdateController(
      AppUpdateService(
        githubOwner: 'frd21313123123',
        githubRepository: 'WAVE',
      ),
    );
    await updateController.loadInstalledVersion();

    return AppBootstrap(
      appConfig: resolvedAppConfig,
      apiClient: apiClient,
      realtimeService: realtimeService,
      chatController: chatController,
      sessionController: sessionController,
      settingsController: settingsController,
      notificationService: notificationService,
      callController: callController,
      updateController: updateController,
    );
  }
}

class WaveApp extends StatelessWidget {
  const WaveApp({super.key, required this.bootstrap});

  final AppBootstrap bootstrap;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppConfig>.value(value: bootstrap.appConfig),
        ChangeNotifierProvider<ChatController>.value(
          value: bootstrap.chatController,
        ),
        ChangeNotifierProvider<SessionController>.value(
          value: bootstrap.sessionController,
        ),
        ChangeNotifierProxyProvider<SessionController, SettingsController>(
          create: (_) => bootstrap.settingsController,
          update: (_, session, settings) {
            settings ??= bootstrap.settingsController;
            settings.replaceCurrentUser(session.currentUser);
            return settings;
          },
        ),
        ChangeNotifierProxyProvider<SessionController, CallController>(
          create: (_) => bootstrap.callController,
          update: (_, session, controller) {
            controller ??= bootstrap.callController;
            final shouldListen =
                session.status == SessionStatus.authenticated &&
                    session.currentUser != null;
            if (shouldListen) {
              unawaited(controller.activate());
            } else {
              unawaited(controller.deactivate());
            }
            return controller;
          },
        ),
        ChangeNotifierProvider<UpdateController>.value(
          value: bootstrap.updateController,
        ),
      ],
      child: Consumer2<SessionController, SettingsController>(
        builder: (context, session, settings, _) {
          final themeMode = settings.settings.themeMode == WaveThemeMode.dark
              ? ThemeMode.dark
              : ThemeMode.light;

          return _SystemUiModeSync(
            fullscreen: settings.settings.fullscreen,
            brightness: themeMode == ThemeMode.dark
                ? Brightness.dark
                : Brightness.light,
            child: MaterialApp(
              title: 'Wave Messenger',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: themeMode,
              builder: (context, child) {
                return UpdateCheckGate(
                  child: child ?? const SizedBox.shrink(),
                );
              },
              home: switch (session.status) {
                SessionStatus.authenticated => const HomeScreen(),
                SessionStatus.awaitingTwoFactor ||
                SessionStatus.unauthenticated =>
                  const AuthScreen(),
                SessionStatus.loading => const _SplashScreen(),
              },
            ),
          );
        },
      ),
    );
  }
}

class _SystemUiModeSync extends StatefulWidget {
  const _SystemUiModeSync({
    required this.fullscreen,
    required this.brightness,
    required this.child,
  });

  final bool fullscreen;
  final Brightness brightness;
  final Widget child;

  @override
  State<_SystemUiModeSync> createState() => _SystemUiModeSyncState();
}

class _SystemUiModeSyncState extends State<_SystemUiModeSync> {
  @override
  void initState() {
    super.initState();
    _apply();
  }

  @override
  void didUpdateWidget(covariant _SystemUiModeSync oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fullscreen != widget.fullscreen ||
        oldWidget.brightness != widget.brightness) {
      _apply();
    }
  }

  Future<void> _apply() async {
    final overlayStyle = widget.brightness == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    await SystemChrome.setEnabledSystemUIMode(
      widget.fullscreen
          ? SystemUiMode.immersiveSticky
          : SystemUiMode.edgeToEdge,
    );
    SystemChrome.setSystemUIOverlayStyle(
      overlayStyle.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              scheme.primary.withValues(alpha: 0.16),
              scheme.tertiary.withValues(alpha: 0.18),
              scheme.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              WaveBrandLogo(
                size: 92,
                semanticLabel: 'Wave logo',
              ),
              SizedBox(height: 18),
              CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
