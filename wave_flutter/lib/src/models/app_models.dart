class PublicUser {
  PublicUser({
    required this.id,
    required this.username,
    required this.email,
    required this.createdAt,
    this.displayName,
    this.twoFactorEnabled = false,
    this.avatarUrl,
    this.online = false,
    this.lastSeenAt,
  });

  factory PublicUser.fromJson(Map<String, dynamic> json) {
    return PublicUser(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      createdAt: _parseDate(json['createdAt']),
      displayName: json['displayName'] as String?,
      twoFactorEnabled: json['twoFactorEnabled'] == true,
      avatarUrl: json['avatarUrl'] as String?,
      online: json['online'] == true,
      lastSeenAt: _parseNullableDate(json['lastSeenAt']),
    );
  }

  String id;
  String username;
  String email;
  DateTime createdAt;
  String? displayName;
  bool twoFactorEnabled;
  String? avatarUrl;
  bool online;
  DateTime? lastSeenAt;

  String get displayNameOrUsername {
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }
    if (username.trim().isNotEmpty) {
      return username;
    }
    return email;
  }
}

class MessageReaction {
  MessageReaction({
    required this.userId,
    required this.emoji,
    required this.createdAt,
  });

  factory MessageReaction.fromJson(Map<String, dynamic> json) {
    return MessageReaction(
      userId: json['userId'] as String? ?? '',
      emoji: json['emoji'] as String? ?? '',
      createdAt: _parseDate(json['createdAt']),
    );
  }

  String userId;
  String emoji;
  DateTime createdAt;
}

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    required this.messageType,
    required this.createdAt,
    this.clientMessageId,
    this.encryption,
    this.replyToId,
    this.forwardFromId,
    this.imageData,
    this.voiceData,
    this.reactions = const [],
    this.sender,
    this.editedAt,
    this.readAt,
    this.isPending = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String? ?? '',
      conversationId: json['conversationId'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      text: json['text'] as String? ?? '',
      messageType: json['messageType'] as String? ?? 'text',
      createdAt: _parseDate(json['createdAt']),
      clientMessageId: json['clientMessageId'] as String?,
      encryption: json['encryption'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['encryption'] as Map)
          : null,
      replyToId: json['replyToId'] as String?,
      forwardFromId: json['forwardFromId'] as String?,
      imageData: json['imageData'] as String?,
      voiceData: json['voiceData'] as String?,
      reactions: ((json['reactions'] as List?) ?? const [])
          .whereType<Map>()
          .map((item) => MessageReaction.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      sender: json['sender'] is Map<String, dynamic>
          ? PublicUser.fromJson(Map<String, dynamic>.from(json['sender'] as Map))
          : null,
      editedAt: _parseNullableDate(json['editedAt']),
      readAt: _parseNullableDate(json['readAt']),
    );
  }

  String id;
  String conversationId;
  String senderId;
  String text;
  String messageType;
  DateTime createdAt;
  String? clientMessageId;
  Map<String, dynamic>? encryption;
  String? replyToId;
  String? forwardFromId;
  String? imageData;
  String? voiceData;
  List<MessageReaction> reactions;
  PublicUser? sender;
  DateTime? editedAt;
  DateTime? readAt;
  bool isPending;

  bool get isImage => messageType == 'image' && (imageData?.isNotEmpty ?? false);
  bool get isVoice => messageType == 'voice' || (voiceData?.isNotEmpty ?? false);
  bool get canEdit => messageType == 'text';

  static ChatMessage optimistic({
    required String conversationId,
    required String senderId,
    required String text,
    required String clientMessageId,
  }) {
    return ChatMessage(
      id: 'pending-$clientMessageId',
      conversationId: conversationId,
      senderId: senderId,
      text: text,
      messageType: 'text',
      createdAt: DateTime.now(),
      clientMessageId: clientMessageId,
      isPending: true,
    );
  }
}

class ConversationSummary {
  ConversationSummary({
    required this.id,
    required this.type,
    required this.updatedAt,
    required this.createdAt,
    this.participant,
    this.participants = const [],
    this.participantIds = const [],
    this.name,
    this.avatarUrl,
    this.creatorId,
    this.blockedByMe = false,
    this.blockedMe = false,
    this.chatProtected = false,
    this.lastMessage,
  });

  factory ConversationSummary.fromJson(Map<String, dynamic> json) {
    return ConversationSummary(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'direct',
      updatedAt: _parseDate(json['updatedAt']),
      createdAt: _parseDate(json['createdAt']),
      participant: json['participant'] is Map<String, dynamic>
          ? PublicUser.fromJson(Map<String, dynamic>.from(json['participant'] as Map))
          : null,
      participants: ((json['participants'] as List?) ?? const [])
          .whereType<Map>()
          .map((item) => PublicUser.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      participantIds: ((json['participantIds'] as List?) ?? const [])
          .map((item) => item.toString())
          .toList(),
      name: json['name'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      creatorId: json['creatorId'] as String?,
      blockedByMe: json['blockedByMe'] == true,
      blockedMe: json['blockedMe'] == true,
      chatProtected: json['chatProtected'] == true,
      lastMessage: json['lastMessage'] is Map<String, dynamic>
          ? ChatMessage.fromJson(Map<String, dynamic>.from(json['lastMessage'] as Map))
          : null,
    );
  }

  String id;
  String type;
  DateTime updatedAt;
  DateTime createdAt;
  PublicUser? participant;
  List<PublicUser> participants;
  List<String> participantIds;
  String? name;
  String? avatarUrl;
  String? creatorId;
  bool blockedByMe;
  bool blockedMe;
  bool chatProtected;
  ChatMessage? lastMessage;

  bool get isGroup => type == 'group';

  String titleFor(String viewerId) {
    if (isGroup) {
      final value = name?.trim();
      return value == null || value.isEmpty ? 'Группа' : value;
    }

    return participant?.displayNameOrUsername ?? 'Диалог';
  }

  String avatarLabelFor(String viewerId) {
    if (isGroup) {
      return titleFor(viewerId);
    }
    return participant?.displayNameOrUsername ?? titleFor(viewerId);
  }

  String? avatarSourceFor(String viewerId) {
    if (isGroup) {
      return avatarUrl;
    }
    return participant?.avatarUrl;
  }
}

DateTime _parseDate(dynamic value) {
  if (value == null) {
    return DateTime.now();
  }
  return DateTime.tryParse(value.toString())?.toLocal() ?? DateTime.now();
}

DateTime? _parseNullableDate(dynamic value) {
  if (value == null) {
    return null;
  }
  return DateTime.tryParse(value.toString())?.toLocal();
}
