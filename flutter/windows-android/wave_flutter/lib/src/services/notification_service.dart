import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../config/app_config.dart';
import '../controllers/chat_controller.dart';
import '../controllers/session_controller.dart';
import '../settings/settings_controller.dart';
import 'api_client.dart';
import 'realtime_service.dart';

class NotificationService {
  NotificationService({
    required ApiClient apiClient,
    required RealtimeService realtimeService,
    required AppConfig appConfig,
  })  : _apiClient = apiClient,
        _realtimeService = realtimeService,
        _appConfig = appConfig;

  static const AndroidNotificationChannel _messageChannel =
      AndroidNotificationChannel(
    'wave_messages',
    'Wave Messages',
    description: 'New messages and foreground alerts.',
    importance: Importance.max,
  );

  static const String _androidPushProvider = 'fcm';
  static const String _androidPlatform = 'android';
  static const String _windowsPlatform = 'windows';
  static const Duration _dedupeWindow = Duration(minutes: 2);
  static const String _payloadConversationType = 'conversation';

  final ApiClient _apiClient;
  final RealtimeService _realtimeService;
  final AppConfig _appConfig;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final Map<String, DateTime> _recentNotificationKeys = <String, DateTime>{};

  StreamSubscription<Map<String, dynamic>>? _realtimeSubscription;
  StreamSubscription<RemoteMessage>? _firebaseForegroundSubscription;
  StreamSubscription<RemoteMessage>? _firebaseOpenedSubscription;
  StreamSubscription<String>? _firebaseTokenRefreshSubscription;
  AppLifecycleListener? _lifecycleListener;

  SessionController? _sessionController;
  ChatController? _chatController;
  SettingsController? _settingsController;

  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;
  bool _initialized = false;
  bool _firebaseReady = false;
  bool _disposed = false;
  String? _registeredNativeToken;
  String? _pendingConversationId;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;
    _lifecycleListener = AppLifecycleListener(
      onStateChange: (state) {
        _lifecycleState = state;
      },
    );

    await _initializeLocalNotifications();
    await _initializeFirebaseMessaging();
    _realtimeSubscription = _realtimeService.events.listen((event) {
      unawaited(_handleRealtimeEvent(event));
    });
  }

  void bindControllers({
    required SessionController sessionController,
    required ChatController chatController,
    required SettingsController settingsController,
  }) {
    if (identical(_sessionController, sessionController) &&
        identical(_chatController, chatController) &&
        identical(_settingsController, settingsController)) {
      return;
    }

    _sessionController?.removeListener(_handleSessionStateChanged);
    _chatController?.removeListener(_handleChatStateChanged);
    _settingsController?.removeListener(_handleSettingsChanged);

    _sessionController = sessionController;
    _chatController = chatController;
    _settingsController = settingsController;

    sessionController.addListener(_handleSessionStateChanged);
    chatController.addListener(_handleChatStateChanged);
    settingsController.addListener(_handleSettingsChanged);

    unawaited(_syncRemotePushRegistration());
    unawaited(_openPendingConversationIfPossible());
  }

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _sessionController?.removeListener(_handleSessionStateChanged);
    _chatController?.removeListener(_handleChatStateChanged);
    _settingsController?.removeListener(_handleSettingsChanged);
    _lifecycleListener?.dispose();
    await _realtimeSubscription?.cancel();
    await _firebaseForegroundSubscription?.cancel();
    await _firebaseOpenedSubscription?.cancel();
    await _firebaseTokenRefreshSubscription?.cancel();
  }

  Future<void> prepareForLogout() async {
    await _unregisterNativePushTokenIfNeeded();
  }

  Future<void> _initializeLocalNotifications() async {
    const androidInitialization =
        AndroidInitializationSettings('ic_stat_wave_notification');
    const windowsInitialization = WindowsInitializationSettings(
      appName: 'Wave Messenger',
      appUserModelId: 'com.wave.messenger',
      guid: 'e57f2497-4872-4836-a56d-7a0b4a8867ee',
    );

    const initializationSettings = InitializationSettings(
      android: androidInitialization,
      windows: windowsInitialization,
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );

    final launchDetails =
        await _localNotifications.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp == true) {
      _handleNotificationPayloadString(
        launchDetails?.notificationResponse?.payload,
      );
    }

    final androidNotifications =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidNotifications?.createNotificationChannel(_messageChannel);
  }

  Future<void> _initializeFirebaseMessaging() async {
    if (!Platform.isAndroid) {
      return;
    }

    final firebaseOptions = _appConfig.androidFirebaseOptions;
    if (firebaseOptions == null) {
      return;
    }

    try {
      await Firebase.initializeApp(options: firebaseOptions);
      _firebaseReady = true;

      _firebaseForegroundSubscription = FirebaseMessaging.onMessage.listen(
        (message) {
          unawaited(_handleFirebaseForegroundMessage(message));
        },
      );
      _firebaseOpenedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
        (message) {
          _handleNotificationData(message.data);
        },
      );
      _firebaseTokenRefreshSubscription =
          FirebaseMessaging.instance.onTokenRefresh.listen((token) {
        unawaited(_registerNativePushToken(token));
      });

      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationData(initialMessage.data);
      }
    } catch (error, stackTrace) {
      debugPrint(
        'Wave notifications: Firebase Messaging initialization skipped: '
        '$error\n$stackTrace',
      );
      _firebaseReady = false;
    }
  }

  Future<void> _handleRealtimeEvent(Map<String, dynamic> event) async {
    if (!_notificationsEnabled || !_isAuthenticated) {
      return;
    }

    final type = event['type']?.toString();
    switch (type) {
      case 'message:new':
        await _handleRealtimeMessageEvent(event);
        return;
      case 'call:signal':
        await _handleRealtimeCallSignal(event);
        return;
      default:
        return;
    }
  }

  Future<void> _handleRealtimeMessageEvent(Map<String, dynamic> event) async {
    final rawMessage = event['message'];
    if (rawMessage is! Map) {
      return;
    }

    final message = Map<String, dynamic>.from(rawMessage);
    final senderId = message['senderId']?.toString();
    final currentUserId = _sessionController?.currentUser?.id;
    if (senderId == null || senderId == currentUserId) {
      return;
    }

    final conversationId = message['conversationId']?.toString() ?? '';
    if (_shouldSuppressConversationNotification(conversationId)) {
      return;
    }

    final notificationKey = _notificationKey(
      kind: 'message',
      identifier: message['id']?.toString(),
    );
    await _showLocalNotificationIfFresh(
      key: notificationKey,
      title: _messageNotificationTitle(message),
      body: _messageNotificationBody(message),
      payload: _notificationPayload(
        conversationId: conversationId,
      ),
    );
  }

  Future<void> _handleRealtimeCallSignal(Map<String, dynamic> event) async {
    final signalType = event['signalType']?.toString();
    final fromUserId = event['fromUserId']?.toString();
    final currentUserId = _sessionController?.currentUser?.id;
    if (signalType != 'offer' ||
        fromUserId == null ||
        currentUserId == null ||
        fromUserId == currentUserId) {
      return;
    }

    final conversationId = event['conversationId']?.toString() ?? '';
    if (_lifecycleState == AppLifecycleState.resumed &&
        _chatController?.activeConversationId == conversationId) {
      return;
    }

    await _showLocalNotificationIfFresh(
      key: _notificationKey(
        kind: 'call',
        identifier: '$fromUserId:$conversationId',
      ),
      title: 'Incoming call',
      body: 'Open Wave Messenger to answer the call.',
      payload: _notificationPayload(conversationId: conversationId),
    );
  }

  Future<void> _handleFirebaseForegroundMessage(RemoteMessage message) async {
    if (!_notificationsEnabled) {
      return;
    }

    final data = Map<String, dynamic>.from(message.data);
    final conversationId = data['conversationId']?.toString() ?? '';
    if (_shouldSuppressConversationNotification(conversationId)) {
      return;
    }

    final title = message.notification?.title ??
        data['title']?.toString() ??
        'Wave Messenger';
    final body =
        message.notification?.body ?? data['body']?.toString() ?? 'New event';
    final key = _notificationKey(
      kind: data['type']?.toString() ?? 'message',
      identifier:
          data['messageId']?.toString() ?? message.messageId ?? conversationId,
    );

    await _showLocalNotificationIfFresh(
      key: key,
      title: title,
      body: body,
      payload: _notificationPayload(conversationId: conversationId),
    );
  }

  Future<void> _showLocalNotificationIfFresh({
    required String key,
    required String title,
    required String body,
    required String payload,
  }) async {
    if (key.trim().isEmpty || title.trim().isEmpty || body.trim().isEmpty) {
      return;
    }
    if (_wasRecentlyShown(key)) {
      return;
    }

    final notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        _messageChannel.id,
        _messageChannel.name,
        channelDescription: _messageChannel.description,
        importance: Importance.max,
        priority: Priority.high,
        icon: 'ic_stat_wave_notification',
      ),
      windows: const WindowsNotificationDetails(),
    );

    await _localNotifications.show(
      id: key.hashCode & 0x7fffffff,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: payload,
    );
  }

  Future<void> _syncRemotePushRegistration() async {
    if (!_isAuthenticated || !_notificationsEnabled) {
      await _unregisterNativePushTokenIfNeeded();
      return;
    }

    await _requestNotificationPermissions();

    if (!Platform.isAndroid || !_firebaseReady) {
      return;
    }

    try {
      final token = await FirebaseMessaging.instance.getToken();
      await _registerNativePushToken(token);
    } catch (error, stackTrace) {
      debugPrint(
        'Wave notifications: failed to obtain native push token: '
        '$error\n$stackTrace',
      );
    }
  }

  Future<void> _requestNotificationPermissions() async {
    final androidNotifications =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    try {
      await androidNotifications?.requestNotificationsPermission();
    } catch (_) {
      // Older Android versions or unsupported desktop platforms may ignore this.
    }

    if (Platform.isAndroid && _firebaseReady) {
      try {
        await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
      } catch (_) {
        // Permission APIs are not fatal for realtime-backed notifications.
      }
    }
  }

  Future<void> _registerNativePushToken(String? token) async {
    final normalizedToken = token?.trim() ?? '';
    if (normalizedToken.isEmpty ||
        !_isAuthenticated ||
        !_notificationsEnabled) {
      return;
    }
    if (_registeredNativeToken == normalizedToken) {
      return;
    }

    try {
      await _apiClient.post(
        '/api/push/native/register',
        data: {
          'provider': _androidPushProvider,
          'platform': _platformName,
          'token': normalizedToken,
        },
      );
      _registeredNativeToken = normalizedToken;
    } catch (error, stackTrace) {
      debugPrint(
        'Wave notifications: failed to register native push token: '
        '$error\n$stackTrace',
      );
    }
  }

  Future<void> _unregisterNativePushTokenIfNeeded() async {
    final token = _registeredNativeToken;
    if (token == null || token.trim().isEmpty) {
      return;
    }

    try {
      await _apiClient.post(
        '/api/push/native/unregister',
        data: {'token': token},
      );
    } catch (error, stackTrace) {
      debugPrint(
        'Wave notifications: failed to unregister native push token: '
        '$error\n$stackTrace',
      );
    } finally {
      _registeredNativeToken = null;
    }
  }

  void _handleNotificationResponse(NotificationResponse response) {
    _handleNotificationPayloadString(response.payload);
  }

  void _handleNotificationPayloadString(String? rawPayload) {
    final raw = rawPayload?.trim();
    if (raw == null || raw.isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        _handleNotificationData(decoded);
      } else if (decoded is Map) {
        _handleNotificationData(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {
      return;
    }
  }

  void _handleNotificationData(Map<String, dynamic> data) {
    final type = data['type']?.toString();
    final isConversationPayload = type == _payloadConversationType;
    final isIncomingCallPayload = type == 'call:incoming';
    if (!isConversationPayload && !isIncomingCallPayload) {
      return;
    }

    final conversationId = data['conversationId']?.toString() ?? '';
    if (conversationId.isEmpty) {
      return;
    }

    _pendingConversationId = conversationId;
    unawaited(_openPendingConversationIfPossible());
  }

  Future<void> _openPendingConversationIfPossible() async {
    final conversationId = _pendingConversationId;
    final session = _sessionController;
    final chat = _chatController;
    if (conversationId == null ||
        conversationId.isEmpty ||
        session == null ||
        chat == null ||
        session.status != SessionStatus.authenticated ||
        session.currentUser == null) {
      return;
    }

    try {
      await chat.openConversation(conversationId);
      _pendingConversationId = null;
    } catch (error, stackTrace) {
      debugPrint(
        'Wave notifications: failed to open conversation from payload: '
        '$error\n$stackTrace',
      );
    }
  }

  void _handleSessionStateChanged() {
    unawaited(_syncRemotePushRegistration());
    unawaited(_openPendingConversationIfPossible());
  }

  void _handleChatStateChanged() {
    unawaited(_openPendingConversationIfPossible());
  }

  void _handleSettingsChanged() {
    unawaited(_syncRemotePushRegistration());
  }

  bool get _notificationsEnabled =>
      _settingsController?.settings.notificationsEnabled ?? true;

  bool get _isAuthenticated =>
      _sessionController?.status == SessionStatus.authenticated &&
      _sessionController?.currentUser != null;

  String get _platformName {
    if (Platform.isAndroid) {
      return _androidPlatform;
    }
    if (Platform.isWindows) {
      return _windowsPlatform;
    }
    return defaultTargetPlatform.name;
  }

  bool _shouldSuppressConversationNotification(String conversationId) {
    if (conversationId.isEmpty) {
      return false;
    }
    return _lifecycleState == AppLifecycleState.resumed &&
        _chatController?.activeConversationId == conversationId;
  }

  String _messageNotificationTitle(Map<String, dynamic> message) {
    final sender = message['sender'];
    if (sender is Map) {
      final senderMap = Map<String, dynamic>.from(sender);
      final displayName = senderMap['displayName']?.toString().trim() ?? '';
      if (displayName.isNotEmpty) {
        return displayName;
      }
      final username = senderMap['username']?.toString().trim() ?? '';
      if (username.isNotEmpty) {
        return username;
      }
    }
    return 'New message';
  }

  String _messageNotificationBody(Map<String, dynamic> message) {
    final messageType = message['messageType']?.toString() ?? 'text';
    if (messageType == 'voice') {
      return 'Voice message';
    }
    if (messageType == 'image') {
      return 'Image';
    }

    final text = message['text']?.toString().trim() ?? '';
    if (text.isEmpty) {
      return 'Message';
    }
    if (text.length <= 120) {
      return text;
    }
    return '${text.substring(0, 117)}...';
  }

  String _notificationPayload({
    required String conversationId,
  }) {
    return jsonEncode(
      <String, dynamic>{
        'type': _payloadConversationType,
        'conversationId': conversationId,
      },
    );
  }

  String _notificationKey({
    required String kind,
    required String? identifier,
  }) {
    final normalizedIdentifier = identifier?.trim() ?? '';
    if (normalizedIdentifier.isEmpty) {
      return '';
    }
    return '$kind:$normalizedIdentifier';
  }

  bool _wasRecentlyShown(String key) {
    final now = DateTime.now();
    _recentNotificationKeys.removeWhere(
      (_, createdAt) => now.difference(createdAt) > _dedupeWindow,
    );

    if (_recentNotificationKeys.containsKey(key)) {
      return true;
    }
    _recentNotificationKeys[key] = now;
    return false;
  }
}
