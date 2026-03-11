import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../controllers/chat_controller.dart';
import '../controllers/session_controller.dart';
import '../models/app_models.dart';
import '../services/api_client.dart';
import '../widgets/wave_avatar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _composerController = TextEditingController();
  final _scrollController = ScrollController();
  String? _lastConversationId;
  int _lastMessageCount = 0;

  @override
  void dispose() {
    _composerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final chat = context.watch<ChatController>();
    final currentUser = session.currentUser!;
    final activeConversation = chat.activeConversation;
    final messages = chat.activeMessages;
    final isWide = MediaQuery.sizeOf(context).width >= 920;

    _scheduleAutoScroll(chat.activeConversationId, messages.length);

    final conversationPane = _ConversationPane(
      currentUser: currentUser,
      conversations: chat.conversations,
      activeConversationId: chat.activeConversationId,
      onSelectConversation: (conversationId) async {
        await chat.openConversation(conversationId);
        if (mounted && !isWide) {
          Navigator.of(context).maybePop();
        }
      },
      onNewChat: _openNewChatSheet,
      onNewGroup: _openNewGroupSheet,
      onOpenProfile: _openProfileSheet,
    );

    return Scaffold(
      drawer: isWide
          ? null
          : Drawer(
              width: 360,
              child: SafeArea(child: conversationPane),
            ),
      appBar: AppBar(
        title: Text(
            activeConversation?.titleFor(currentUser.id) ?? 'Wave Messenger'),
        actions: [
          IconButton(
            onPressed: _openNewChatSheet,
            tooltip: 'Новый чат',
            icon: const Icon(Icons.person_add_alt_1_rounded),
          ),
          IconButton(
            onPressed: _openProfileSheet,
            tooltip: 'Профиль',
            icon: const Icon(Icons.tune_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: isWide
            ? Row(
                children: [
                  SizedBox(width: 360, child: conversationPane),
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: _ChatPane(
                      currentUser: currentUser,
                      conversation: activeConversation,
                      messages: messages,
                      typingDisplayName: chat.typingDisplayName,
                      composerController: _composerController,
                      scrollController: _scrollController,
                      onComposerChanged: (_) => chat.sendTypingSignal(),
                      onSend: () => _sendMessage(chat),
                      onEditMessage: (message) => _editMessage(chat, message),
                    ),
                  ),
                ],
              )
            : _ChatPane(
                currentUser: currentUser,
                conversation: activeConversation,
                messages: messages,
                typingDisplayName: chat.typingDisplayName,
                composerController: _composerController,
                scrollController: _scrollController,
                onComposerChanged: (_) => chat.sendTypingSignal(),
                onSend: () => _sendMessage(chat),
                onEditMessage: (message) => _editMessage(chat, message),
              ),
      ),
    );
  }

  void _scheduleAutoScroll(String? conversationId, int messageCount) {
    if (conversationId == null) {
      _lastConversationId = null;
      _lastMessageCount = 0;
      return;
    }

    if (_lastConversationId == conversationId &&
        _lastMessageCount == messageCount) {
      return;
    }

    _lastConversationId = conversationId;
    _lastMessageCount = messageCount;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _sendMessage(ChatController chat) async {
    final text = _composerController.text;
    _composerController.clear();

    try {
      await chat.sendTextMessage(text);
    } on ApiException catch (error) {
      _composerController.text = text;
      _composerController.selection = TextSelection.collapsed(
        offset: _composerController.text.length,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  Future<void> _editMessage(ChatController chat, ChatMessage message) async {
    final controller = TextEditingController(text: message.text);
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Редактировать сообщение'),
          content: TextField(
            controller: controller,
            maxLines: 5,
            minLines: 1,
            decoration: const InputDecoration(labelText: 'Текст'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () async {
                try {
                  await chat.editMessage(
                    conversationId: message.conversationId,
                    messageId: message.id,
                    text: controller.text,
                  );
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                } on ApiException catch (error) {
                  if (!mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error.message)),
                  );
                }
              },
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openNewChatSheet() async {
    final chat = context.read<ChatController>();
    final conversation = await showModalBottomSheet<ConversationSummary>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _NewChatSheet(chat: chat),
    );

    if (conversation != null && mounted) {
      await chat.openConversation(conversation.id);
    }
  }

  Future<void> _openNewGroupSheet() async {
    final chat = context.read<ChatController>();
    final conversation = await showModalBottomSheet<ConversationSummary>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _NewGroupSheet(chat: chat),
    );

    if (conversation != null && mounted) {
      await chat.openConversation(conversation.id);
    }
  }

  Future<void> _openProfileSheet() async {
    final session = context.read<SessionController>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ProfileSheet(session: session),
    );
  }
}

class _ConversationPane extends StatelessWidget {
  const _ConversationPane({
    required this.currentUser,
    required this.conversations,
    required this.activeConversationId,
    required this.onSelectConversation,
    required this.onNewChat,
    required this.onNewGroup,
    required this.onOpenProfile,
  });

  final PublicUser currentUser;
  final List<ConversationSummary> conversations;
  final String? activeConversationId;
  final Future<void> Function(String conversationId) onSelectConversation;
  final VoidCallback onNewChat;
  final VoidCallback onNewGroup;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.92),
            scheme.surface.withValues(alpha: 0.82),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.waves_rounded),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Wave',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      onPressed: onOpenProfile,
                      icon: const Icon(Icons.more_horiz_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: ListTile(
                    leading: WaveAvatar(
                      label: currentUser.displayNameOrUsername,
                      imageUrl: currentUser.avatarUrl,
                      radius: 22,
                    ),
                    title: Text(currentUser.displayNameOrUsername),
                    subtitle: Text(currentUser.email),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onNewChat,
                        icon: const Icon(Icons.chat_bubble_outline_rounded),
                        label: const Text('Новый чат'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onNewGroup,
                        icon: const Icon(Icons.group_add_rounded),
                        label: const Text('Группа'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: conversations.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Диалогов пока нет. Начни с поиска пользователя или создай группу.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
                    itemCount: conversations.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final conversation = conversations[index];
                      final selected = conversation.id == activeConversationId;
                      final partner = conversation.participant;

                      return Material(
                        color: selected
                            ? scheme.primary.withValues(alpha: 0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(24),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () => onSelectConversation(conversation.id),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    WaveAvatar(
                                      label: conversation
                                          .avatarLabelFor(currentUser.id),
                                      imageUrl: conversation
                                          .avatarSourceFor(currentUser.id),
                                      radius: 24,
                                    ),
                                    if (!conversation.isGroup &&
                                        partner?.online == true)
                                      Positioned(
                                        right: -1,
                                        bottom: -1,
                                        child: Container(
                                          width: 14,
                                          height: 14,
                                          decoration: BoxDecoration(
                                            color: scheme.secondary,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        conversation.titleFor(currentUser.id),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                                fontWeight: FontWeight.w700),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _conversationPreview(conversation),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _formatTime(conversation.updatedAt),
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ChatPane extends StatelessWidget {
  const _ChatPane({
    required this.currentUser,
    required this.conversation,
    required this.messages,
    required this.typingDisplayName,
    required this.composerController,
    required this.scrollController,
    required this.onComposerChanged,
    required this.onSend,
    required this.onEditMessage,
  });

  final PublicUser currentUser;
  final ConversationSummary? conversation;
  final List<ChatMessage> messages;
  final String? typingDisplayName;
  final TextEditingController composerController;
  final ScrollController scrollController;
  final ValueChanged<String> onComposerChanged;
  final VoidCallback onSend;
  final ValueChanged<ChatMessage> onEditMessage;

  @override
  Widget build(BuildContext context) {
    final active = conversation;
    if (active == null) {
      return const _EmptyChatState();
    }

    final partner = active.participant;
    final scheme = Theme.of(context).colorScheme;
    final canSend = !active.blockedMe;

    return Container(
      color: Colors.white.withValues(alpha: 0.55),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.78),
              border: Border(
                bottom: BorderSide(
                  color: scheme.outlineVariant.withValues(alpha: 0.35),
                ),
              ),
            ),
            child: Row(
              children: [
                WaveAvatar(
                  label: active.avatarLabelFor(currentUser.id),
                  imageUrl: active.avatarSourceFor(currentUser.id),
                  radius: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        active.titleFor(currentUser.id),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        active.isGroup
                            ? '${active.participants.length} участников'
                            : partner?.online == true
                                ? 'в сети'
                                : partner?.lastSeenAt != null
                                    ? 'был(а) ${DateFormat('dd.MM HH:mm').format(partner!.lastSeenAt!)}'
                                    : '@${partner?.username ?? ''}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (active.blockedMe)
            Container(
              width: double.infinity,
              color: scheme.errorContainer,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                'Отправка недоступна: собеседник вас заблокировал.',
                style: TextStyle(color: scheme.onErrorContainer),
              ),
            ),
          Expanded(
            child: ListView.separated(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              itemCount: messages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final message = messages[index];
                final isMine = message.senderId == currentUser.id;
                final canEdit = isMine && message.canEdit && !message.isPending;
                final senderName = active.isGroup && !isMine
                    ? _senderNameFor(active, message.senderId, message.sender)
                    : null;

                return GestureDetector(
                  onLongPress: canEdit ? () => onEditMessage(message) : null,
                  child: _MessageBubble(
                    message: message,
                    isMine: isMine,
                    senderName: senderName,
                  ),
                );
              },
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: (typingDisplayName ?? '').isEmpty
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '$typingDisplayName печатает...',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: composerController,
                      enabled: canSend,
                      minLines: 1,
                      maxLines: 5,
                      textInputAction: TextInputAction.send,
                      decoration: InputDecoration(
                        hintText:
                            canSend ? 'Сообщение' : 'Сообщения недоступны',
                        prefixIcon: const Icon(Icons.waves_rounded),
                      ),
                      onChanged: onComposerChanged,
                      onSubmitted: (_) => onSend(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: canSend ? onSend : null,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      shape: const CircleBorder(),
                    ),
                    child: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMine,
    this.senderName,
  });

  final ChatMessage message;
  final bool isMine;
  final String? senderName;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bubbleColor = isMine ? scheme.primary : Colors.white;
    final textColor = isMine ? Colors.white : const Color(0xFF152238);
    final imageBytes = _decodeDataImage(message.imageData);

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: bubbleColor.withValues(alpha: message.isPending ? 0.78 : 1),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(22),
              topRight: const Radius.circular(22),
              bottomLeft: Radius.circular(isMine ? 22 : 8),
              bottomRight: Radius.circular(isMine ? 8 : 22),
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: 18,
                color: Colors.black.withValues(alpha: 0.06),
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Column(
              crossAxisAlignment:
                  isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if ((senderName ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      senderName!,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: textColor.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                if (message.isImage && imageBytes != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.memory(
                      imageBytes,
                      fit: BoxFit.cover,
                    ),
                  ),
                  if (message.text.trim().isNotEmpty &&
                      message.text.trim() != '🖼 Скриншот') ...[
                    const SizedBox(height: 10),
                    Text(
                      message.text,
                      style: TextStyle(color: textColor),
                    ),
                  ],
                ] else if (message.isVoice) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.graphic_eq_rounded, color: textColor),
                      const SizedBox(width: 8),
                      Text(
                        'Голосовое сообщение',
                        style: TextStyle(color: textColor),
                      ),
                    ],
                  ),
                ] else ...[
                  Text(
                    message.text,
                    style: TextStyle(
                      color: textColor,
                      height: 1.38,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (message.editedAt != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text(
                          'изм.',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: textColor.withValues(alpha: 0.75),
                                  ),
                        ),
                      ),
                    Text(
                      DateFormat('HH:mm').format(message.createdAt),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: textColor.withValues(alpha: 0.75),
                          ),
                    ),
                    if (isMine) ...[
                      const SizedBox(width: 6),
                      Icon(
                        message.isPending
                            ? Icons.schedule_rounded
                            : message.readAt != null
                                ? Icons.done_all_rounded
                                : Icons.done_rounded,
                        size: 16,
                        color: textColor.withValues(alpha: 0.78),
                      ),
                    ],
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

class _EmptyChatState extends StatelessWidget {
  const _EmptyChatState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        scheme.primary.withValues(alpha: 0.15),
                        scheme.tertiary.withValues(alpha: 0.25),
                      ],
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(22),
                    child: Icon(Icons.waves_rounded, size: 56),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Выбери диалог',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Список чатов слева. На телефоне открой drawer и начни новый разговор.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NewChatSheet extends StatefulWidget {
  const _NewChatSheet({required this.chat});

  final ChatController chat;

  @override
  State<_NewChatSheet> createState() => _NewChatSheetState();
}

class _NewChatSheetState extends State<_NewChatSheet> {
  final _searchController = TextEditingController();
  bool _loading = false;
  List<PublicUser> _results = const [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: 560,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Поиск пользователя',
                  hintText: 'логин, email, display name',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
                onChanged: _runSearch,
              ),
            ),
            if (_loading) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: _results.isEmpty
                  ? Center(
                      child: Text(
                        'Начни вводить минимум 2 символа.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  : ListView.separated(
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final user = _results[index];
                        return ListTile(
                          leading: WaveAvatar(
                            label: user.displayNameOrUsername,
                            imageUrl: user.avatarUrl,
                          ),
                          title: Text(user.displayNameOrUsername),
                          subtitle: Text('@${user.username} • ${user.email}'),
                          onTap: () async {
                            try {
                              final conversation = await widget.chat
                                  .createDirectConversation(user.id);
                              if (mounted) {
                                Navigator.of(context).pop(conversation);
                              }
                            } on ApiException catch (error) {
                              if (!mounted) {
                                return;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(error.message)),
                              );
                            }
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runSearch(String value) async {
    if (value.trim().length < 2) {
      setState(() {
        _results = const [];
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final results = await widget.chat.searchUsers(value);
      if (mounted) {
        setState(() {
          _results = results;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }
}

class _NewGroupSheet extends StatefulWidget {
  const _NewGroupSheet({required this.chat});

  final ChatController chat;

  @override
  State<_NewGroupSheet> createState() => _NewGroupSheetState();
}

class _NewGroupSheetState extends State<_NewGroupSheet> {
  final _nameController = TextEditingController();
  final _searchController = TextEditingController();
  bool _loading = false;
  bool _creating = false;
  List<PublicUser> _results = const [];
  final Map<String, PublicUser> _selected = <String, PublicUser>{};

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: 620,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Название группы',
                      prefixIcon: Icon(Icons.groups_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Добавить участников',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                    onChanged: _runSearch,
                  ),
                ],
              ),
            ),
            if (_selected.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selected.values
                      .map(
                        (user) => InputChip(
                          label: Text(user.displayNameOrUsername),
                          onDeleted: () {
                            setState(() {
                              _selected.remove(user.id);
                            });
                          },
                        ),
                      )
                      .toList(),
                ),
              ),
            if (_loading) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: _results.isEmpty
                  ? Center(
                      child: Text(
                        'Найди пользователей и добавь их в группу.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  : ListView.separated(
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final user = _results[index];
                        final selected = _selected.containsKey(user.id);
                        return CheckboxListTile(
                          value: selected,
                          title: Text(user.displayNameOrUsername),
                          subtitle: Text('@${user.username} • ${user.email}'),
                          secondary: WaveAvatar(
                            label: user.displayNameOrUsername,
                            imageUrl: user.avatarUrl,
                          ),
                          onChanged: (_) {
                            setState(() {
                              if (selected) {
                                _selected.remove(user.id);
                              } else {
                                _selected[user.id] = user;
                              }
                            });
                          },
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: FilledButton.icon(
                onPressed: _creating ? null : _createGroup,
                icon: _creating
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.group_add_rounded),
                label: const Text('Создать группу'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runSearch(String value) async {
    if (value.trim().length < 2) {
      setState(() {
        _results = const [];
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final results = await widget.chat.searchUsers(value);
      if (mounted) {
        setState(() {
          _results = results;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _createGroup() async {
    setState(() {
      _creating = true;
    });

    try {
      final conversation = await widget.chat.createGroup(
        name: _nameController.text,
        memberIds: _selected.keys.toList(),
      );
      if (mounted) {
        Navigator.of(context).pop(conversation);
      }
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _creating = false;
        });
      }
    }
  }
}

class _ProfileSheet extends StatefulWidget {
  const _ProfileSheet({required this.session});

  final SessionController session;

  @override
  State<_ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends State<_ProfileSheet> {
  late final TextEditingController _displayNameController;
  bool _savingProfile = false;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(
      text: widget.session.currentUser?.displayName ?? '',
    );
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.session.currentUser!;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: 520,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Row(
              children: [
                WaveAvatar(
                  label: user.displayNameOrUsername,
                  imageUrl: user.avatarUrl,
                  radius: 30,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayNameOrUsername,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(user.email),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _displayNameController,
              decoration: const InputDecoration(
                labelText: 'Display name',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: _savingProfile
                  ? null
                  : () async {
                      setState(() {
                        _savingProfile = true;
                      });
                      try {
                        await widget.session
                            .updateDisplayName(_displayNameController.text);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Профиль обновлён')),
                          );
                        }
                      } on ApiException catch (error) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error.message)),
                          );
                        }
                      } finally {
                        if (mounted) {
                          setState(() {
                            _savingProfile = false;
                          });
                        }
                      }
                    },
              child: const Text('Сохранить имя'),
            ),
            const SizedBox(height: 24),
            FilledButton.tonalIcon(
              onPressed: () async {
                await widget.session.logout();
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Выйти'),
            ),
          ],
        ),
      ),
    );
  }
}

String _conversationPreview(ConversationSummary conversation) {
  final last = conversation.lastMessage;
  if (last == null) {
    return conversation.isGroup ? 'Групповой чат' : 'Сообщений пока нет';
  }
  if (last.isImage) {
    return '🖼 Изображение';
  }
  if (last.isVoice) {
    return '🎤 Голосовое сообщение';
  }
  return last.text.trim().isEmpty ? 'Сообщение' : last.text.trim();
}

String _formatTime(DateTime value) {
  final now = DateTime.now();
  if (now.year == value.year &&
      now.month == value.month &&
      now.day == value.day) {
    return DateFormat('HH:mm').format(value);
  }
  return DateFormat('dd.MM').format(value);
}

String? _senderNameFor(
  ConversationSummary conversation,
  String senderId,
  PublicUser? sender,
) {
  if (sender != null) {
    return sender.displayNameOrUsername;
  }
  for (final participant in conversation.participants) {
    if (participant.id == senderId) {
      return participant.displayNameOrUsername;
    }
  }
  return null;
}

Uint8List? _decodeDataImage(String? value) {
  if (value == null || !value.startsWith('data:image')) {
    return null;
  }
  final comma = value.indexOf(',');
  if (comma < 0) {
    return null;
  }
  try {
    return base64Decode(value.substring(comma + 1));
  } catch (_) {
    return null;
  }
}
