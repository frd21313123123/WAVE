import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../calls/calls.dart';
import '../config/app_config.dart';
import '../controllers/chat_controller.dart';
import '../controllers/session_controller.dart';
import '../models/app_models.dart';
import '../models/call_models.dart';
import '../services/api_client.dart';
import '../settings/avatar_upload.dart';
import '../settings/settings_controller.dart';
import '../settings/wave_settings_sheet.dart';
import '../widgets/wave_avatar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _composerController = TextEditingController();
  final _scrollController = ScrollController();
  final _imagePicker = ImagePicker();
  final _callTonePlayer = AudioPlayer(playerId: 'wave-call-tone');
  String? _lastConversationId;
  int _lastMessageCount = 0;
  CallController? _callController;
  SettingsController? _settingsController;
  CallUiState _lastCallState = const CallUiState.idle();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final callController = context.read<CallController>();
    if (!identical(_callController, callController)) {
      _callController?.removeListener(_handleCallStateChanged);
      _callController = callController;
      _lastCallState = callController.state;
      callController.addListener(_handleCallStateChanged);
      unawaited(callController.activate());
    }

    final settingsController = context.read<SettingsController>();
    if (!identical(_settingsController, settingsController)) {
      _settingsController = settingsController;
    }
  }

  @override
  void dispose() {
    _callController?.removeListener(_handleCallStateChanged);
    unawaited(_callController?.deactivate() ?? Future<void>.value());
    unawaited(_callTonePlayer.dispose());
    _composerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleCallStateChanged() {
    final nextState = _callController?.state ?? const CallUiState.idle();
    final previousState = _lastCallState;
    _lastCallState = nextState;

    final soundsEnabled =
        _settingsController?.settings.callSoundsEnabled ?? true;
    final hadIncoming = previousState.pendingIncoming != null;
    final hasIncoming = nextState.pendingIncoming != null;

    if (!hadIncoming && hasIncoming && soundsEnabled) {
      unawaited(_startIncomingTone());
    } else if (hadIncoming && !hasIncoming) {
      unawaited(_stopIncomingTone());
    }

    if (previousState.hasLiveCall && nextState.isIdle && soundsEnabled) {
      unawaited(_playDisconnectCue(nextState.disconnectReason));
    }
    if (nextState.hasLiveCall) {
      unawaited(_stopIncomingTone());
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final chat = context.watch<ChatController>();
    final settings = context.watch<SettingsController>();
    final callController = context.watch<CallController>();
    final callState = callController.state;
    final currentUser = session.currentUser!;
    final activeConversation = chat.activeConversation;
    final messages = chat.activeMessages;
    final isWide = MediaQuery.sizeOf(context).width >= 920;

    _scheduleAutoScroll(chat.activeConversationId, messages.length);

    final conversationPane = _ConversationPane(
      currentUser: currentUser,
      settingsController: settings,
      conversations: chat.conversations,
      activeConversationId: chat.activeConversationId,
      onSelectConversation: (conversationId) async {
        await chat.openConversation(conversationId);
        if (!context.mounted || isWide) {
          return;
        }
        Navigator.of(context).maybePop();
      },
      onNewChat: _openNewChatSheet,
      onNewGroup: _openNewGroupSheet,
      onOpenProfile: _openSettingsSheet,
    );

    final conversationBody = isWide
        ? Row(
            children: [
              SizedBox(width: 360, child: conversationPane),
              const VerticalDivider(width: 1),
              Expanded(
                child: _ChatPane(
                  currentUser: currentUser,
                  settingsController: settings,
                  conversation: activeConversation,
                  messages: messages,
                  typingDisplayName: chat.typingDisplayName,
                  composerController: _composerController,
                  scrollController: _scrollController,
                  onComposerChanged: (_) => chat.sendTypingSignal(),
                  onSend: () => _sendMessage(chat),
                  onEditMessage: (message) => _editMessage(chat, message),
                  onStartAudioCall: () =>
                      _startOutgoingCall(videoRequested: false),
                  onStartVideoCall: () =>
                      _startOutgoingCall(videoRequested: true),
                ),
              ),
            ],
          )
        : _ChatPane(
            currentUser: currentUser,
            settingsController: settings,
            conversation: activeConversation,
            messages: messages,
            typingDisplayName: chat.typingDisplayName,
            composerController: _composerController,
            scrollController: _scrollController,
            onComposerChanged: (_) => chat.sendTypingSignal(),
            onSend: () => _sendMessage(chat),
            onEditMessage: (message) => _editMessage(chat, message),
            onStartAudioCall: () => _startOutgoingCall(videoRequested: false),
            onStartVideoCall: () => _startOutgoingCall(videoRequested: true),
          );

    if (callState.hasLiveCall) {
      return Scaffold(
        body: SafeArea(
          child: ActiveCallSheet(
            state: callState,
            mediaEngine: callController.mediaEngine,
            onEnd: () => unawaited(callController.endCall()),
            onToggleMute: () => unawaited(callController.toggleMuted()),
            onToggleSpeaker: () => unawaited(callController.toggleSpeaker()),
            onToggleCamera: () => unawaited(callController.toggleCamera()),
            expandToFill: true,
          ),
        ),
      );
    }

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
            onPressed: _openSettingsSheet,
            tooltip: 'Профиль',
            icon: const Icon(Icons.tune_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(child: conversationBody),
          if (callState.pendingIncoming != null)
            IncomingCallSheet(
              state: callState,
              onAccept: () => unawaited(_acceptIncomingCall()),
              onReject: () => unawaited(callController.rejectIncomingCall()),
              onAcceptWithVideo: () =>
                  unawaited(_acceptIncomingCall(videoRequested: true)),
            ),
        ],
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
    final normalized = text.trim();
    if (normalized.isEmpty) {
      return;
    }
    final settings = context.read<SettingsController>();
    final payload = settings.buildOutgoingTextPayload(normalized);
    _composerController.clear();

    try {
      await chat.sendTextMessageWithPayload(
        rawText: normalized,
        requestBody: payload,
        optimisticText: normalized,
        optimisticEncryption: null,
      );
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
    final settings = context.read<SettingsController>();
    final controller = TextEditingController(
      text: settings.decodeMessageText(message),
    );
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
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                try {
                  final nextText = controller.text.trim();
                  final textForTransport = settings.isMessageEncrypted(message)
                      ? settings.encryptMessage(nextText)
                      : nextText;
                  await chat.editMessage(
                    conversationId: message.conversationId,
                    messageId: message.id,
                    text: textForTransport,
                  );
                  if (context.mounted) {
                    navigator.pop();
                  }
                } on ApiException catch (error) {
                  if (!context.mounted) {
                    return;
                  }
                  messenger.showSnackBar(
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

  Future<void> _openSettingsSheet() async {
    final session = context.read<SessionController>();
    final settings = context.read<SettingsController>();
    await showWaveSettingsSheet<void>(
      context,
      controller: settings,
      useRootNavigator: true,
      onPickAvatar: _pickAvatarUploadData,
      onRunMicrophoneTest: _runMicrophoneTest,
      onPreviewCallTone: _previewCallTone,
      onLogoutRequested: () async {
        final navigator = Navigator.of(context, rootNavigator: true);
        navigator.pop();
        await session.logout();
      },
    );
  }

  Future<void> _startOutgoingCall({required bool videoRequested}) async {
    final chat = context.read<ChatController>();
    final conversation = chat.activeConversation;
    final peer = conversation?.participant;
    if (conversation == null || conversation.isGroup || peer == null) {
      return;
    }

    try {
      await context.read<CallController>().startOutgoingCall(
            peer: peer,
            conversationId: conversation.id,
            videoRequested: videoRequested,
          );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  Future<void> _acceptIncomingCall({bool? videoRequested}) async {
    try {
      await context.read<CallController>().acceptIncomingCall(
            videoRequested: videoRequested,
          );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  Future<void> _previewCallTone() async {
    final appConfig = context.read<AppConfig>();
    await _callTonePlayer.stop();
    await _callTonePlayer.setReleaseMode(ReleaseMode.stop);
    await _callTonePlayer.play(
      UrlSource('${appConfig.baseUrl}/sound-call.mp3'),
      volume: _callToneVolume,
    );
  }

  Future<void> _startIncomingTone() async {
    final appConfig = context.read<AppConfig>();
    await _callTonePlayer.stop();
    await _callTonePlayer.setReleaseMode(ReleaseMode.loop);
    await _callTonePlayer.play(
      UrlSource('${appConfig.baseUrl}/sound-call.mp3'),
      volume: _callToneVolume,
    );
  }

  Future<void> _stopIncomingTone() async {
    await _callTonePlayer.stop();
    await _callTonePlayer.setReleaseMode(ReleaseMode.stop);
  }

  Future<void> _playDisconnectCue(CallDisconnectReason reason) async {
    final appConfig = context.read<AppConfig>();
    final soundName = switch (reason) {
      CallDisconnectReason.rejected => 'call-rejected.mp3',
      CallDisconnectReason.none => null,
      _ => 'call-ended.mp3',
    };
    if (soundName == null) {
      return;
    }
    await _callTonePlayer.stop();
    await _callTonePlayer.setReleaseMode(ReleaseMode.stop);
    await _callTonePlayer.play(
      UrlSource('${appConfig.baseUrl}/$soundName'),
      volume: _callToneVolume,
    );
  }

  Future<void> _runMicrophoneTest() async {
    final stream = await navigator.mediaDevices.getUserMedia(
      <String, dynamic>{
        'audio': <String, dynamic>{
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
        },
        'video': false,
      },
    );
    for (final track in stream.getTracks()) {
      await track.stop();
    }
    await stream.dispose();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Microphone test completed.')),
    );
  }

  Future<AvatarUploadData?> _pickAvatarUploadData() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Gallery'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Camera'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) {
      return null;
    }

    final file = await _imagePicker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 88,
    );
    if (file == null) {
      return null;
    }

    final bytes = await file.readAsBytes();
    return AvatarUploadData(
      bytes: bytes,
      fileName: file.name,
      mimeType: _mimeTypeForFile(file),
    );
  }

  double get _callToneVolume {
    final rawVolume = _settingsController?.settings.speakerVolume ?? 100;
    return rawVolume.clamp(0, 100) / 100;
  }
}

class _ConversationPane extends StatelessWidget {
  const _ConversationPane({
    required this.currentUser,
    required this.settingsController,
    required this.conversations,
    required this.activeConversationId,
    required this.onSelectConversation,
    required this.onNewChat,
    required this.onNewGroup,
    required this.onOpenProfile,
  });

  final PublicUser currentUser;
  final SettingsController settingsController;
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
                                        _conversationPreviewDecoded(
                                          conversation,
                                          settingsController,
                                        ),
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
    required this.settingsController,
    required this.conversation,
    required this.messages,
    required this.typingDisplayName,
    required this.composerController,
    required this.scrollController,
    required this.onComposerChanged,
    required this.onSend,
    required this.onEditMessage,
    required this.onStartAudioCall,
    required this.onStartVideoCall,
  });

  final PublicUser currentUser;
  final SettingsController settingsController;
  final ConversationSummary? conversation;
  final List<ChatMessage> messages;
  final String? typingDisplayName;
  final TextEditingController composerController;
  final ScrollController scrollController;
  final ValueChanged<String> onComposerChanged;
  final VoidCallback onSend;
  final ValueChanged<ChatMessage> onEditMessage;
  final VoidCallback onStartAudioCall;
  final VoidCallback onStartVideoCall;

  @override
  Widget build(BuildContext context) {
    final active = conversation;
    if (active == null) {
      return const _EmptyChatState();
    }

    final partner = active.participant;
    final scheme = Theme.of(context).colorScheme;
    final canSend = !active.blockedMe;
    final canStartCall = !active.isGroup &&
        !active.blockedByMe &&
        !active.blockedMe &&
        partner != null;

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
                if (canStartCall) ...[
                  IconButton(
                    onPressed: onStartAudioCall,
                    tooltip: 'Voice call',
                    icon: const Icon(Icons.call_rounded),
                  ),
                  IconButton(
                    onPressed: onStartVideoCall,
                    tooltip: 'Video call',
                    icon: const Icon(Icons.videocam_rounded),
                  ),
                ],
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
                final displayText =
                    settingsController.decodeMessageText(message);
                final encrypted =
                    settingsController.isMessageEncrypted(message);

                return GestureDetector(
                  onLongPress: canEdit ? () => onEditMessage(message) : null,
                  child: _MessageBubble(
                    message: message,
                    isMine: isMine,
                    senderName: senderName,
                    displayText: displayText,
                    encrypted: encrypted,
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
                        prefixIcon: Icon(
                          settingsController.settings.vigenereEnabled
                              ? Icons.lock_outline_rounded
                              : Icons.waves_rounded,
                        ),
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
    required this.displayText,
    required this.encrypted,
    this.senderName,
  });

  final ChatMessage message;
  final bool isMine;
  final String displayText;
  final bool encrypted;
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
                if (encrypted)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: textColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        child: Text(
                          'Encrypted',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: textColor.withValues(alpha: 0.82),
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
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
                  if (displayText.trim().isNotEmpty &&
                      displayText.trim() != '🖼 Скриншот') ...[
                    const SizedBox(height: 10),
                    Text(
                      displayText,
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
                    displayText,
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
  Timer? _searchDebounce;
  bool _loading = false;
  List<PublicUser> _results = const [];
  int _searchSequence = 0;

  @override
  void dispose() {
    _searchDebounce?.cancel();
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
                            final navigator = Navigator.of(context);
                            final messenger = ScaffoldMessenger.of(context);
                            try {
                              final conversation = await widget.chat
                                  .createDirectConversation(user.id);
                              if (context.mounted) {
                                navigator.pop(conversation);
                              }
                            } on ApiException catch (error) {
                              if (!context.mounted) {
                                return;
                              }
                              messenger.showSnackBar(
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
    _searchDebounce?.cancel();
    final trimmed = value.trim();
    if (trimmed.length < 2) {
      _searchSequence += 1;
      setState(() {
        _results = const [];
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = true;
    });

    final searchId = ++_searchSequence;
    _searchDebounce = Timer(const Duration(milliseconds: 250), () async {
      try {
        final results = await widget.chat.searchUsers(trimmed);
        if (!mounted || searchId != _searchSequence) {
          return;
        }
        setState(() {
          _results = results;
        });
      } finally {
        if (mounted && searchId == _searchSequence) {
          setState(() {
            _loading = false;
          });
        }
      }
    });
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
  Timer? _searchDebounce;
  bool _loading = false;
  bool _creating = false;
  List<PublicUser> _results = const [];
  final Map<String, PublicUser> _selected = <String, PublicUser>{};
  int _searchSequence = 0;

  @override
  void dispose() {
    _searchDebounce?.cancel();
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
    _searchDebounce?.cancel();
    final trimmed = value.trim();
    if (trimmed.length < 2) {
      _searchSequence += 1;
      setState(() {
        _results = const [];
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = true;
    });

    final searchId = ++_searchSequence;
    _searchDebounce = Timer(const Duration(milliseconds: 250), () async {
      try {
        final results = await widget.chat.searchUsers(trimmed);
        if (!mounted || searchId != _searchSequence) {
          return;
        }
        setState(() {
          _results = results;
        });
      } finally {
        if (mounted && searchId == _searchSequence) {
          setState(() {
            _loading = false;
          });
        }
      }
    });
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
                      final messenger = ScaffoldMessenger.of(context);
                      setState(() {
                        _savingProfile = true;
                      });
                      try {
                        await widget.session
                            .updateDisplayName(_displayNameController.text);
                        if (context.mounted) {
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Профиль обновлён')),
                          );
                        }
                      } on ApiException catch (error) {
                        if (context.mounted) {
                          messenger.showSnackBar(
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
                final navigator = Navigator.of(context);
                await widget.session.logout();
                if (context.mounted) {
                  navigator.pop();
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

String conversationPreviewLegacy(
  ConversationSummary conversation,
  SettingsController settingsController,
) {
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

String _conversationPreviewDecoded(
  ConversationSummary conversation,
  SettingsController settingsController,
) {
  final last = conversation.lastMessage;
  if (last == null) {
    return conversation.isGroup ? 'Group chat' : 'No messages yet';
  }
  if (last.isImage) {
    return 'Image';
  }
  if (last.isVoice) {
    return 'Voice message';
  }
  final decoded = settingsController.decodeMessageText(last).trim();
  return decoded.isEmpty ? 'Message' : decoded;
}

String _mimeTypeForFile(XFile file) {
  final mimeType = file.mimeType?.trim().toLowerCase();
  if ((mimeType ?? '').startsWith('image/')) {
    return mimeType!;
  }

  final path = file.path.toLowerCase();
  if (path.endsWith('.png')) {
    return 'image/png';
  }
  if (path.endsWith('.webp')) {
    return 'image/webp';
  }
  if (path.endsWith('.gif')) {
    return 'image/gif';
  }
  return 'image/jpeg';
}
