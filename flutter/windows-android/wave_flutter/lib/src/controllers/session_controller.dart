import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../models/app_models.dart';
import '../services/api_client.dart';
import '../services/session_store.dart';
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
    required this.sessionStore,
    this.beforeLogout,
  });

  final ApiClient apiClient;
  final AppConfig appConfig;
  final ChatController chatController;
  final SessionStore sessionStore;
  final Future<void> Function()? beforeLogout;

  SessionStatus _status = SessionStatus.loading;
  PublicUser? _currentUser;
  String? _errorMessage;
  bool _busy = false;
  String? _challengeToken;

  SessionStatus get status => _status;
  PublicUser? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get busy => _busy;

  Future<void> bootstrap() async {
    _setBusy(true);
    _status = SessionStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final cachedSession = await sessionStore.load();
    if (cachedSession != null) {
      await apiClient.restoreAuthToken(cachedSession.authToken);
    }

    try {
      final payload = await apiClient.get('/api/auth/me');
      final user = PublicUser.fromJson(
        Map<String, dynamic>.from(payload['user'] as Map),
      );
      await _applyAuthenticatedUser(user);
    } on ApiException catch (error) {
      if (cachedSession != null && error.statusCode >= 500) {
        await _restoreCachedSession(cachedSession);
      } else {
        await _clearSessionState(clearCookies: true, clearCache: true);
        if (error.statusCode >= 500) {
          _errorMessage = error.message;
        }
      }
    } catch (_) {
      if (cachedSession != null) {
        await _restoreCachedSession(cachedSession);
      } else {
        await _clearSessionState(clearCookies: false, clearCache: false);
        _errorMessage = 'Не удалось подключиться к серверу';
      }
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
      if (beforeLogout != null) {
        await beforeLogout!.call();
      }
      await apiClient.post('/api/auth/logout');
    } catch (_) {
    } finally {
      await _clearSessionState(clearCookies: true, clearCache: true);
      _challengeToken = null;
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
      await _persistSession(_currentUser!);
      notifyListeners();
    }
  }

  void synchronizeCurrentUser(PublicUser user) {
    _currentUser = PublicUser.fromJson(user.toJson());
    _status = SessionStatus.authenticated;
    _errorMessage = null;
    chatController.updateCurrentUser(_currentUser!);
    unawaited(_persistSession(_currentUser!));
    notifyListeners();
  }

  Future<void> handleAccountDeleted() async {
    await _clearSessionState(clearCookies: false, clearCache: true);
    _challengeToken = null;
    _errorMessage = null;
    _setBusy(false);
    notifyListeners();
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
    await _applyAuthenticatedUser(user);
  }

  Future<void> _applyAuthenticatedUser(PublicUser user) async {
    _currentUser = user;
    _status = SessionStatus.authenticated;
    _errorMessage = null;
    await _persistSession(user);
    await chatController.activate(user);
  }

  Future<void> _restoreCachedSession(CachedSession cachedSession) async {
    _currentUser = cachedSession.user;
    _status = SessionStatus.authenticated;
    _errorMessage = null;
    await chatController.activate(cachedSession.user);
  }

  Future<void> _persistSession(PublicUser user) async {
    final authToken = await apiClient.readAuthToken();
    if ((authToken ?? '').isEmpty) {
      return;
    }

    await sessionStore.save(
      CachedSession(
        user: user,
        authToken: authToken!,
      ),
    );
  }

  Future<void> _clearSessionState({
    required bool clearCookies,
    required bool clearCache,
  }) async {
    if (clearCookies) {
      await apiClient.clearCookies();
    }
    if (clearCache) {
      await sessionStore.clear();
    }
    await chatController.deactivate();
    _currentUser = null;
    _status = SessionStatus.unauthenticated;
  }

  void _setBusy(bool value) {
    _busy = value;
  }
}
