import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/app_config.dart';
import 'controllers/chat_controller.dart';
import 'controllers/session_controller.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'services/api_client.dart';
import 'services/realtime_service.dart';
import 'services/session_store.dart';
import 'theme/app_theme.dart';

class AppBootstrap {
  AppBootstrap({
    required this.appConfig,
    required this.apiClient,
    required this.realtimeService,
    required this.chatController,
    required this.sessionController,
  });

  final AppConfig appConfig;
  final ApiClient apiClient;
  final RealtimeService realtimeService;
  final ChatController chatController;
  final SessionController sessionController;

  static Future<AppBootstrap> initialize() async {
    final appConfig = await AppConfig.load();
    final apiClient = await ApiClient.create(appConfig);
    final sessionStore = await SessionStore.create();
    final realtimeService = RealtimeService(
      apiClient: apiClient,
      appConfig: appConfig,
    );
    final chatController = ChatController(
      apiClient: apiClient,
      realtimeService: realtimeService,
    );
    final sessionController = SessionController(
      apiClient: apiClient,
      appConfig: appConfig,
      chatController: chatController,
      sessionStore: sessionStore,
    );

    await sessionController.bootstrap();

    return AppBootstrap(
      appConfig: appConfig,
      apiClient: apiClient,
      realtimeService: realtimeService,
      chatController: chatController,
      sessionController: sessionController,
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
            value: bootstrap.chatController),
        ChangeNotifierProvider<SessionController>.value(
          value: bootstrap.sessionController,
        ),
      ],
      child: MaterialApp(
        title: 'Wave Messenger',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: Consumer<SessionController>(
          builder: (context, session, _) {
            switch (session.status) {
              case SessionStatus.authenticated:
                return const HomeScreen();
              case SessionStatus.awaitingTwoFactor:
              case SessionStatus.unauthenticated:
                return const AuthScreen();
              case SessionStatus.loading:
                return const _SplashScreen();
            }
          },
        ),
      ),
    );
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
              Icon(Icons.waves_rounded, size: 68),
              SizedBox(height: 18),
              CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
