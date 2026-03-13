import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/app_models.dart';
import '../services/api_client.dart';
import '../services/realtime_service.dart';

class ChatController extends ChangeNotifier {
  ChatController({
    required this.apiClient,
    required this.realtimeService,
  });

  final ApiClient apiClient;
  final RealtimeService realtimeService;

  PublicUser? _currentUser;
  final List<ConversationSummary> _conversations = [];
  final Map<String, List<ChatMessage>> _messagesByConversation = {};
  final Set<String> _loadedMessagesConversationIds = <String>{};
  final Map<String, Timer> _typingTimers = <String, Timer>{};
  StreamSubscription<Map<String, dynamic>>? _realtimeSubscription;
  String? _activeConversationId;
  String? _typingDisplayName;
  bool _isBootstrapping = false;
  DateTime? _lastTypingSentAt;
  int _sendSequence = 0;

  List<ConversationSummary> get conversations =>
      List.unmodifiable(_conversations);
  String? get activeConversationId => _activeConversationId;
  String? get typingDisplayName => _typingDisplayName;
  bool get isBootstrapping => _isBootstrapping;
  PublicUser? get currentUser => _currentUser;

  ConversationSummary? get activeConversation {
    final id = _activeConversationId;
    if (id == null) {
      return null;
    }
    return conversationById(id);
  }

  List<ChatMessage> get activeMessages {
    final id = _activeConversationId;
    if (id == null) {
      return const [];
    }
    return messagesFor(id);
  }

  ConversationSummary? conversationById(String id) {
    for (final conversation in _conversations) {
      if (conversation.id == id) {
        return conversation;
      }
    }
    return null;
  }

  List<ChatMessage> messagesFor(String conversationId) {
    final messages = _messagesByConversation[conversationId] ?? const [];
    return List.unmodifiable(messages);
  }

  Future<void> activate(PublicUser user) async {
    _currentUser = user;
    _isBootstrapping = true;
    _activeConversationId = null;
    _typingDisplayName = null;
    _conversations.clear();
    _messagesByConversation.clear();
    _loadedMessagesConversationIds.clear();
    notifyListeners();

    _realtimeSubscription ??=
        realtimeService.events.listen(_handleRealtimeEvent);
    await realtimeService.activate();
    try {
      await loadConversations();
    } catch (_) {}

    _isBootstrapping = false;
    notifyListeners();
  }

  Future<void> deactivate() async {
    _currentUser = null;
    _activeConversationId = null;
    _typingDisplayName = null;
    _isBootstrapping = false;
    _lastTypingSentAt = null;
    _conversations.clear();
    _messagesByConversation.clear();
    _loadedMessagesConversationIds.clear();

    for (final timer in _typingTimers.values) {
      timer.cancel();
    }
    _typingTimers.clear();

    await realtimeService.deactivate();
    await _realtimeSubscription?.cancel();
    _realtimeSubscription = null;
    notifyListeners();
  }

  void updateCurrentUser(PublicUser user) {
    _currentUser = user;
    notifyListeners();
  }

  Future<void> loadConversations() async {
    final payload = await apiClient.get('/api/conversations');
    final parsed = ((payload['conversations'] as List?) ?? const [])
        .whereType<Map>()
        .map((item) =>
            ConversationSummary.fromJson(Map<String, dynamic>.from(item)))
        .toList();

    _conversations
      ..clear()
      ..addAll(parsed);
    _sortConversations();
    notifyListeners();
  }

  Future<void> openConversation(String conversationId) async {
    _activeConversationId = conversationId;
    _typingDisplayName = null;
    notifyListeners();

    await loadMessages(conversationId);
    await markConversationAsRead(conversationId);
  }

  Future<void> loadMessages(String conversationId) async {
    if (_loadedMessagesConversationIds.contains(conversationId)) {
      return;
    }

    final payload = await apiClient.get(
      '/api/conversations/$conversationId/messages',
      queryParameters: const {'limit': 200},
    );
    final messages = ((payload['messages'] as List?) ?? const [])
        .whereType<Map>()
        .map((item) => ChatMessage.fromJson(Map<String, dynamic>.from(item)))
        .toList();

    _messagesByConversation[conversationId] = messages;
    _loadedMessagesConversationIds.add(conversationId);
    notifyListeners();
  }

  Future<void> markConversationAsRead(String conversationId) async {
    try {
      final payload =
          await apiClient.post('/api/conversations/$conversationId/read');
      final conversation = payload['conversation'];
      if (conversation is Map<String, dynamic>) {
        _upsertConversation(
          ConversationSummary.fromJson(Map<String, dynamic>.from(conversation)),
        );
      }

      final readAtValue = payload['readAt'];
      final readAt = readAtValue == null
          ? null
          : DateTime.tryParse(readAtValue.toString())?.toLocal();
      final messageIds = ((payload['readMessageIds'] as List?) ?? const [])
          .map((item) => item.toString())
          .toSet();

      if (readAt != null && messageIds.isNotEmpty) {
        _applyReadState(conversationId, messageIds, readAt);
      }
      notifyListeners();
    } catch (_) {
      return;
    }
  }

  Future<void> sendTypingSignal() async {
    final conversationId = _activeConversationId;
    if (conversationId == null) {
      return;
    }

    final now = DateTime.now();
    if (_lastTypingSentAt != null &&
        now.difference(_lastTypingSentAt!) <
            const Duration(milliseconds: 900)) {
      return;
    }

    _lastTypingSentAt = now;
    await realtimeService.send({
      'type': 'typing',
      'conversationId': conversationId,
    });
  }

  Future<void> sendTextMessage(String rawText) async {
    await sendTextMessageWithPayload(
      rawText: rawText,
      requestBody: null,
      optimisticText: null,
      optimisticEncryption: null,
    );
  }

  Future<void> sendTextMessageWithPayload({
    required String rawText,
    Map<String, dynamic>? requestBody,
    String? optimisticText,
    Map<String, dynamic>? optimisticEncryption,
  }) async {
    final conversationId = _activeConversationId;
    final currentUser = _currentUser;
    final text = rawText.trim();
    final outboundText = (requestBody?['text']?.toString() ?? rawText).trim();
    if (conversationId == null ||
        currentUser == null ||
        text.isEmpty ||
        outboundText.isEmpty) {
      return;
    }

    final clientMessageId =
        '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1 << 20)}-${_sendSequence++}';

    final optimisticMessage = ChatMessage.optimistic(
      conversationId: conversationId,
      senderId: currentUser.id,
      text: optimisticText?.trim().isNotEmpty == true
          ? optimisticText!.trim()
          : outboundText,
      clientMessageId: clientMessageId,
      encryption: optimisticEncryption,
    )..sender = currentUser;

    _mergeIncomingMessage(optimisticMessage);
    notifyListeners();

    try {
      final body = <String, dynamic>{
        ...(requestBody ?? <String, dynamic>{'text': text}),
        'clientMessageId': clientMessageId,
      };
      final payload = await apiClient.post(
        '/api/conversations/$conversationId/messages',
        data: body,
      );

      final messageJson = payload['message'];
      if (messageJson is Map<String, dynamic>) {
        _mergeIncomingMessage(
          ChatMessage.fromJson(Map<String, dynamic>.from(messageJson)),
        );
      }

      final conversationJson = payload['conversation'];
      if (conversationJson is Map<String, dynamic>) {
        _upsertConversation(
          ConversationSummary.fromJson(
            Map<String, dynamic>.from(conversationJson),
          ),
        );
      }
      notifyListeners();
    } catch (error) {
      _removeMessageByClientId(conversationId, clientMessageId);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> editMessage({
    required String conversationId,
    required String messageId,
    required String text,
  }) async {
    final payload = await apiClient.patch(
      '/api/conversations/$conversationId/messages/$messageId',
      data: {'text': text.trim()},
    );

    final messageJson = payload['message'];
    if (messageJson is Map<String, dynamic>) {
      _applyEditedMessage(
        ChatMessage.fromJson(Map<String, dynamic>.from(messageJson)),
      );
      notifyListeners();
    }
  }

  Future<List<PublicUser>> searchUsers(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      return const [];
    }

    final payload = await apiClient.get(
      '/api/users',
      queryParameters: {'search': trimmed},
    );

    return ((payload['users'] as List?) ?? const [])
        .whereType<Map>()
        .map((item) => PublicUser.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<ConversationSummary> createDirectConversation(String userId) async {
    final payload = await apiClient.post(
      '/api/conversations/direct',
      data: {'userId': userId},
    );
    final conversation = ConversationSummary.fromJson(
      Map<String, dynamic>.from(payload['conversation'] as Map),
    );
    _upsertConversation(conversation);
    notifyListeners();
    return conversation;
  }

  Future<ConversationSummary> createGroup({
    required String name,
    required List<String> memberIds,
  }) async {
    final payload = await apiClient.post(
      '/api/conversations/group',
      data: {
        'name': name.trim(),
        'memberIds': memberIds,
      },
    );
    final conversation = ConversationSummary.fromJson(
      Map<String, dynamic>.from(payload['conversation'] as Map),
    );
    _upsertConversation(conversation);
    notifyListeners();
    return conversation;
  }

  Future<void> _handleRealtimeEvent(Map<String, dynamic> event) async {
    final type = event['type']?.toString();
    if (type == null) {
      return;
    }

    switch (type) {
      case 'ready':
      case 'pong':
        return;
      case 'conversation:update':
        final conversationJson = event['conversation'];
        if (conversationJson is Map<String, dynamic>) {
          _upsertConversation(
            ConversationSummary.fromJson(
              Map<String, dynamic>.from(conversationJson),
            ),
          );
          notifyListeners();
        }
        return;
      case 'message:new':
        final messageJson = event['message'];
        if (messageJson is Map<String, dynamic>) {
          final message =
              ChatMessage.fromJson(Map<String, dynamic>.from(messageJson));
          _mergeIncomingMessage(message);
          if (message.conversationId == _activeConversationId &&
              message.senderId != _currentUser?.id) {
            unawaited(markConversationAsRead(message.conversationId));
            _typingDisplayName = null;
          }
          notifyListeners();
        }
        return;
      case 'message:read':
        final conversationId = event['conversationId']?.toString();
        final readAtValue = event['readAt'];
        final readAt = readAtValue == null
            ? null
            : DateTime.tryParse(readAtValue.toString())?.toLocal();
        final messageIds = ((event['messageIds'] as List?) ?? const [])
            .map((item) => item.toString())
            .toSet();
        if (conversationId != null && readAt != null && messageIds.isNotEmpty) {
          _applyReadState(conversationId, messageIds, readAt);
          notifyListeners();
        }
        return;
      case 'typing':
        final conversationId = event['conversationId']?.toString();
        final userId = event['userId']?.toString();
        if (conversationId == _activeConversationId &&
            userId != null &&
            userId != _currentUser?.id) {
          _typingDisplayName = event['displayName']?.toString() ??
              event['username']?.toString() ??
              'Печатает';
          _typingTimers[userId]?.cancel();
          _typingTimers[userId] = Timer(const Duration(seconds: 3), () {
            _typingTimers.remove(userId);
            _typingDisplayName = null;
            notifyListeners();
          });
          notifyListeners();
        }
        return;
      case 'presence:update':
        final userId = event['userId']?.toString();
        if (userId != null) {
          _applyPresenceUpdate(
            userId: userId,
            online: event['online'] == true,
            lastSeenAt: DateTime.tryParse(event['lastSeenAt']?.toString() ?? '')
                ?.toLocal(),
          );
          notifyListeners();
        }
        return;
      case 'message:edited':
        final messageJson = event['message'];
        if (messageJson is Map<String, dynamic>) {
          _applyEditedMessage(
            ChatMessage.fromJson(Map<String, dynamic>.from(messageJson)),
          );
          notifyListeners();
        }
        return;
      case 'message:deleted':
        final conversationId = event['conversationId']?.toString();
        if (conversationId != null) {
          final ids = ((event['messageIds'] as List?) ?? const [])
              .map((item) => item.toString())
              .toSet();
          _messagesByConversation[conversationId]?.removeWhere(
            (message) => ids.contains(message.id),
          );
          notifyListeners();
        }
        return;
      case 'conversation:deleted':
        final conversationId = event['conversationId']?.toString();
        if (conversationId != null) {
          _conversations
              .removeWhere((conversation) => conversation.id == conversationId);
          _messagesByConversation.remove(conversationId);
          _loadedMessagesConversationIds.remove(conversationId);
          if (_activeConversationId == conversationId) {
            _activeConversationId = null;
          }
          notifyListeners();
        }
        return;
      default:
        return;
    }
  }

  void _mergeIncomingMessage(ChatMessage message) {
    final bucket = _messagesByConversation.putIfAbsent(
      message.conversationId,
      () => <ChatMessage>[],
    );

    final byIdIndex = bucket.indexWhere((item) => item.id == message.id);
    if (byIdIndex >= 0) {
      bucket[byIdIndex] = message..isPending = false;
    } else if (message.clientMessageId != null) {
      final byClientIdIndex = bucket.indexWhere(
        (item) => item.clientMessageId == message.clientMessageId,
      );
      if (byClientIdIndex >= 0) {
        bucket[byClientIdIndex] = message..isPending = false;
      } else {
        bucket.add(message);
      }
    } else {
      bucket.add(message);
    }

    bucket.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final conversation = conversationById(message.conversationId);
    if (conversation != null) {
      conversation.lastMessage = message;
      conversation.updatedAt = message.createdAt;
      _sortConversations();
    }
  }

  void _removeMessageByClientId(String conversationId, String clientMessageId) {
    final bucket = _messagesByConversation[conversationId];
    bucket
        ?.removeWhere((message) => message.clientMessageId == clientMessageId);
  }

  void _applyEditedMessage(ChatMessage message) {
    final bucket = _messagesByConversation[message.conversationId];
    if (bucket == null) {
      return;
    }
    final index = bucket.indexWhere((item) => item.id == message.id);
    if (index < 0) {
      return;
    }
    bucket[index]
      ..text = message.text
      ..editedAt = message.editedAt;
  }

  void _applyReadState(
    String conversationId,
    Set<String> messageIds,
    DateTime readAt,
  ) {
    final bucket = _messagesByConversation[conversationId];
    if (bucket != null) {
      for (final message in bucket) {
        if (messageIds.contains(message.id)) {
          message.readAt = readAt;
        }
      }
    }

    final conversation = conversationById(conversationId);
    final lastMessage = conversation?.lastMessage;
    if (lastMessage != null && messageIds.contains(lastMessage.id)) {
      lastMessage.readAt = readAt;
    }
  }

  void _applyPresenceUpdate({
    required String userId,
    required bool online,
    required DateTime? lastSeenAt,
  }) {
    for (final conversation in _conversations) {
      if (conversation.participant?.id == userId) {
        conversation.participant!
          ..online = online
          ..lastSeenAt = lastSeenAt;
      }
      for (final participant in conversation.participants) {
        if (participant.id == userId) {
          participant
            ..online = online
            ..lastSeenAt = lastSeenAt;
        }
      }
    }
  }

  void _upsertConversation(ConversationSummary conversation) {
    final index =
        _conversations.indexWhere((item) => item.id == conversation.id);
    if (index >= 0) {
      _conversations[index] = conversation;
    } else {
      _conversations.add(conversation);
    }
    _sortConversations();
  }

  void _sortConversations() {
    _conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }
}
