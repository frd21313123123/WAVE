import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../models/app_models.dart';
import '../services/api_client.dart';
import 'chat_controller.dart';

enum SessionStatus {
  loading,
  unauthenticated,
  awaitingTwoFactor,
  authenticated,
}

class SessionController extends ChangeNotifier {
  SessionController({
    required this.apiClient,
    required this.appConfig,
    required this.chatController,
  });

  final ApiClient apiClient;
  final AppConfig appConfig;
  final ChatController chatController;

  SessionStatus _status = SessionStatus.loading;
  PublicUser? _currentUser;
  String? _errorMessage;
  bool _busy = false;
  String? _challengeToken;

  SessionStatus get status => _status;
  PublicUser? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get busy => _busy;
  String get serverUrl => appConfig.baseUrl;

  Future<void> bootstrap() async {
    _setBusy(true);
    _status = SessionStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final payload = await apiClient.get('/api/auth/me');
      final user = PublicUser.fromJson(
        Map<String, dynamic>.from(payload['user'] as Map),
      );
      _currentUser = user;
      _status = SessionStatus.authenticated;
      await chatController.activate(user);
    } on ApiException catch (error) {
      await chatController.deactivate();
      _currentUser = null;
      _status = SessionStatus.unauthenticated;
      if (error.statusCode < 500) {
        _errorMessage = null;
      } else {
        _errorMessage = error.message;
      }
    } catch (_) {
      await chatController.deactivate();
      _currentUser = null;
      _status = SessionStatus.unauthenticated;
      _errorMessage = 'Не удалось подключиться к $serverUrl';
    } finally {
      _setBusy(false);
      notifyListeners();
    }
  }

  Future<void> login({
    required String login,
    required String password,
  }) async {
    _setBusy(true);
    _errorMessage = null;
    notifyListeners();

    try {
      final payload = await apiClient.post(
        '/api/auth/login',
        data: {
          'login': login.trim(),
          'password': password,
        },
      );

      if (payload['requires2fa'] == true) {
        _challengeToken = payload['challengeToken']?.toString();
        _status = SessionStatus.awaitingTwoFactor;
        _currentUser = null;
        return;
      }

      await _completeAuthentication(payload);
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Не удалось инициализировать сессию';
    } finally {
      _setBusy(false);
      notifyListeners();
    }
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
  }) async {
    _setBusy(true);
    _errorMessage = null;
    notifyListeners();

    try {
      final payload = await apiClient.post(
        '/api/auth/register',
        data: {
          'username': username.trim(),
          'email': email.trim(),
          'password': password,
        },
      );
      await _completeAuthentication(payload);
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Не удалось инициализировать сессию';
    } finally {
      _setBusy(false);
      notifyListeners();
    }
  }

  Future<void> submitTwoFactorCode(String token) async {
    if ((_challengeToken ?? '').isEmpty) {
      _errorMessage = 'Истёк токен подтверждения входа';
      notifyListeners();
      return;
    }

    _setBusy(true);
    _errorMessage = null;
    notifyListeners();

    try {
      final payload = await apiClient.post(
        '/api/auth/login/2fa',
        data: {
          'challengeToken': _challengeToken,
          'token': token.trim(),
        },
      );
      await _completeAuthentication(payload);
      _challengeToken = null;
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Не удалось инициализировать сессию';
    } finally {
      _setBusy(false);
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _setBusy(true);
    notifyListeners();

    try {
      await apiClient.post('/api/auth/logout');
    } catch (_) {
    } finally {
      await apiClient.clearCookies();
      await chatController.deactivate();
      _currentUser = null;
      _challengeToken = null;
      _status = SessionStatus.unauthenticated;
      _errorMessage = null;
      _setBusy(false);
      notifyListeners();
    }
  }

  Future<void> updateDisplayName(String displayName) async {
    final payload = await apiClient.put(
      '/api/auth/profile',
      data: {'displayName': displayName.trim()},
    );

    if (_currentUser != null) {
      _currentUser!.displayName = payload['displayName'] as String?;
      chatController.updateCurrentUser(_currentUser!);
      notifyListeners();
    }
  }

  Future<void> updateServerUrl(String serverUrl) async {
    _setBusy(true);
    notifyListeners();

    try {
      await chatController.deactivate();
      await apiClient.clearCookies();
      await appConfig.updateBaseUrl(serverUrl);
      _challengeToken = null;
      _currentUser = null;
      _status = SessionStatus.unauthenticated;
      _errorMessage = null;
      await bootstrap();
    } finally {
      _setBusy(false);
      notifyListeners();
    }
  }

  void resetTwoFactorFlow() {
    _challengeToken = null;
    _status = SessionStatus.unauthenticated;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _completeAuthentication(Map<String, dynamic> payload) async {
    final user = PublicUser.fromJson(
      Map<String, dynamic>.from(payload['user'] as Map),
    );
    _currentUser = user;
    _status = SessionStatus.authenticated;
    await chatController.activate(user);
  }

  void _setBusy(bool value) {
    _busy = value;
  }
}
