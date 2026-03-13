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
import '../settings/app_settings.dart';
import '../settings/avatar_upload.dart';
import '../settings/settings_controller.dart';
import '../settings/wave_settings_sheet.dart';
import '../settings/widgets/settings_feedback_banner.dart';
import '../update/app_update_install_flow.dart';
import '../update/update_controller.dart';
import '../update/update_prompt.dart';
import '../widgets/wave_avatar.dart';
import '../widgets/wave_brand_logo.dart';

enum _MobileHomeTab { chats, settings, profile }

enum _MobileChatFilter { all, direct, groups }

enum _ProfileFeedTab { posts, archived }

enum _MobileSettingsSection { display, encryption, sound, security, account }

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
  final _messageSoundPlayer = AudioPlayer(playerId: 'wave-message-sounds');
  final Map<String, String> _conversationMessageSoundKeys = <String, String>{};
  String? _lastConversationId;
  int _lastMessageCount = 0;
  _MobileHomeTab _mobileTab = _MobileHomeTab.chats;
  _MobileChatFilter _mobileChatFilter = _MobileChatFilter.all;
  _ProfileFeedTab _profileFeedTab = _ProfileFeedTab.posts;
  bool _mobileChatOpen = false;
  ChatController? _chatController;
  CallController? _callController;
  SettingsController? _settingsController;
  CallUiState _lastCallState = const CallUiState.idle();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final chatController = context.read<ChatController>();
    if (!identical(_chatController, chatController)) {
      _chatController?.removeListener(_handleChatStateChanged);
      _chatController = chatController;
      _conversationMessageSoundKeys
        ..clear()
        ..addAll(_captureConversationMessageSoundKeys(chatController));
      chatController.addListener(_handleChatStateChanged);
    }

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
    if (!settingsController.isBootstrapped) {
      unawaited(settingsController.bootstrap());
    }
  }

  @override
  void dispose() {
    _chatController?.removeListener(_handleChatStateChanged);
    _callController?.removeListener(_handleCallStateChanged);
    unawaited(_callController?.deactivate() ?? Future<void>.value());
    unawaited(_callTonePlayer.dispose());
    unawaited(_messageSoundPlayer.dispose());
    _composerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleChatStateChanged() {
    final chatController = _chatController;
    final currentUserId = chatController?.currentUser?.id;
    if (chatController == null || currentUserId == null) {
      return;
    }

    final nextSnapshot = _captureConversationMessageSoundKeys(chatController);
    ChatMessage? newestIncomingMessage;

    for (final conversation in chatController.conversations) {
      final lastMessage = conversation.lastMessage;
      if (lastMessage == null) {
        continue;
      }

      final previousKey = _conversationMessageSoundKeys[conversation.id];
      final nextKey = nextSnapshot[conversation.id];
      if (previousKey == nextKey || lastMessage.senderId == currentUserId) {
        continue;
      }

      if (newestIncomingMessage == null ||
          lastMessage.createdAt.isAfter(newestIncomingMessage.createdAt)) {
        newestIncomingMessage = lastMessage;
      }
    }

    _conversationMessageSoundKeys
      ..clear()
      ..addAll(nextSnapshot);

    final notificationsEnabled =
        _settingsController?.settings.notificationsEnabled ?? true;
    if (notificationsEnabled && newestIncomingMessage != null) {
      unawaited(_playIncomingMessageCue());
    }
  }

  void _handleCallStateChanged() {
    final nextState = _callController?.state ?? const CallUiState.idle();
    final previousState = _lastCallState;
    _lastCallState = nextState;

    final soundsEnabled =
        _settingsController?.settings.callSoundsEnabled ?? true;
    final hadLoopTone =
        previousState.pendingIncoming != null || previousState.isOutgoing;
    final hasLoopTone =
        nextState.pendingIncoming != null || nextState.isOutgoing;

    if (!hadLoopTone && hasLoopTone && soundsEnabled) {
      unawaited(_startIncomingTone());
    } else if (hadLoopTone && !hasLoopTone) {
      unawaited(_stopIncomingTone());
    }

    if (previousState.hasLiveCall && nextState.isIdle && soundsEnabled) {
      unawaited(_playDisconnectCue(nextState.disconnectReason));
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
      onOpenProfile: _openSettingsSurface,
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

    if (!isWide) {
      return _buildMobileScaffold(
        currentUser: currentUser,
        chat: chat,
        settings: settings,
        callController: callController,
        callState: callState,
        activeConversation: activeConversation,
        messages: messages,
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
            onPressed: _openSettingsSurface,
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

  Widget _buildMobileScaffold({
    required PublicUser currentUser,
    required ChatController chat,
    required SettingsController settings,
    required CallController callController,
    required CallUiState callState,
    required ConversationSummary? activeConversation,
    required List<ChatMessage> messages,
  }) {
    final updateController = context.watch<UpdateController>();
    final showConversation = _mobileTab == _MobileHomeTab.chats &&
        _mobileChatOpen &&
        activeConversation != null;
    final filteredConversations =
        _filterMobileConversations(chat.conversations);
    final unreadDockCount = chat.conversations.where((conversation) {
      final lastMessage = conversation.lastMessage;
      return lastMessage != null &&
          lastMessage.senderId != currentUser.id &&
          lastMessage.readAt == null;
    }).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: showConversation
                  ? _ChatPane(
                      key: ValueKey<String>(
                        'mobile-chat-${activeConversation.id}',
                      ),
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
                      showBackButton: true,
                      onBack: _closeMobileConversation,
                    )
                  : _MobileHomeView(
                      key: ValueKey<String>('mobile-tab-${_mobileTab.name}'),
                      currentUser: currentUser,
                      conversations: filteredConversations,
                      allConversations: chat.conversations,
                      settingsController: settings,
                      activeTab: _mobileTab,
                      selectedFilter: _mobileChatFilter,
                      selectedFeedTab: _profileFeedTab,
                      onFilterChanged: (value) {
                        setState(() {
                          _mobileChatFilter = value;
                        });
                      },
                      onFeedTabChanged: (value) {
                        setState(() {
                          _profileFeedTab = value;
                        });
                      },
                      onTabChanged: _setMobileTab,
                      onOpenConversation: _openMobileConversation,
                      onOpenNewChat: () => unawaited(_openNewChatSheet()),
                      onOpenNewGroup: () => unawaited(_openNewGroupSheet()),
                      onOpenSettings: () =>
                          _setMobileTab(_MobileHomeTab.settings),
                      onOpenProfileEditor: () => unawaited(_openProfileSheet()),
                      onUploadAvatar: _uploadAvatarFromProfile,
                      onRunMicrophoneTest: _runMicrophoneTest,
                      onPreviewCallTone: _previewCallTone,
                      onCheckForUpdates: _checkForUpdatesFromSettings,
                      appVersionText: updateController.installedVersion,
                      updateStatusText: updateController.updateStatusLabel,
                      onLogout: _logoutFromMobileShell,
                    ),
            ),
          ),
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
      bottomNavigationBar: showConversation
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: _MobileBottomDock(
                  currentUser: currentUser,
                  activeTab: _mobileTab,
                  chatsBadgeCount: unreadDockCount,
                  onTabSelected: _setMobileTab,
                ),
              ),
            ),
    );
  }

  List<ConversationSummary> _filterMobileConversations(
    List<ConversationSummary> conversations,
  ) {
    return conversations.where((conversation) {
      switch (_mobileChatFilter) {
        case _MobileChatFilter.all:
          return true;
        case _MobileChatFilter.direct:
          return !conversation.isGroup;
        case _MobileChatFilter.groups:
          return conversation.isGroup;
      }
    }).toList(growable: false);
  }

  Future<void> _openMobileConversation(String conversationId) async {
    final chat = context.read<ChatController>();
    await chat.openConversation(conversationId);
    if (!mounted) {
      return;
    }
    setState(() {
      _mobileTab = _MobileHomeTab.chats;
      _mobileChatOpen = true;
    });
  }

  void _closeMobileConversation() {
    if (!mounted) {
      return;
    }
    setState(() {
      _mobileChatOpen = false;
    });
  }

  void _setMobileTab(_MobileHomeTab tab) {
    if (!mounted) {
      return;
    }
    setState(() {
      _mobileTab = tab;
      _mobileChatOpen = false;
    });
  }

  Future<void> _openProfileSheet() async {
    final session = context.read<SessionController>();
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return _ProfileSheet(session: session);
      },
    );
  }

  Future<void> _uploadAvatarFromProfile() async {
    final settings = context.read<SettingsController>();
    try {
      final upload = await _pickAvatarUploadData();
      if (upload == null) {
        return;
      }
      await settings.uploadAvatarBytes(
        upload.bytes,
        mimeType: upload.mimeType,
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

  Future<void> _logoutFromMobileShell() async {
    await context.read<SessionController>().logout();
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
    final notificationsEnabled = settings.settings.notificationsEnabled;
    final payload = settings.buildOutgoingTextPayload(normalized);
    _composerController.clear();

    try {
      await chat.sendTextMessageWithPayload(
        rawText: normalized,
        requestBody: payload,
        optimisticText: normalized,
        optimisticEncryption: null,
      );
      if (notificationsEnabled) {
        unawaited(_playOutgoingMessageCue());
      }
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

  Future<void> _openSettingsSurface() async {
    if (MediaQuery.sizeOf(context).width < 920) {
      _setMobileTab(_MobileHomeTab.settings);
      return;
    }
    await _openSettingsSheet();
  }

  Future<void> _openSettingsSheet() async {
    final session = context.read<SessionController>();
    final settings = context.read<SettingsController>();
    final updateController = context.read<UpdateController>();
    await showWaveSettingsSheet<void>(
      context,
      controller: settings,
      useRootNavigator: true,
      onPickAvatar: _pickAvatarUploadData,
      onRunMicrophoneTest: _runMicrophoneTest,
      onPreviewCallTone: _previewCallTone,
      onCheckForUpdates: _checkForUpdatesFromSettings,
      appVersionText: updateController.installedVersion,
      updateStatusText: updateController.updateStatusLabel,
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

  Future<void> _checkForUpdatesFromSettings() async {
    final updateController = context.read<UpdateController>();
    final messenger = ScaffoldMessenger.of(context);
    final result = await updateController.checkForUpdates();
    if (!mounted) {
      return;
    }

    if (result.hasError) {
      messenger.showSnackBar(
        SnackBar(content: Text(result.errorMessage!)),
      );
      return;
    }

    final update = result.update;
    if (update == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'У вас уже установлена актуальная версия (${result.currentVersion ?? updateController.installedVersion ?? 'unknown'}).',
          ),
        ),
      );
      return;
    }

    final shouldOpen = await showAppUpdateDialog(context, update: update);
    if (shouldOpen != true || !mounted) {
      return;
    }

    await runManagedAppUpdateInstallFlow(
      context,
      controller: updateController,
      update: update,
    );
  }

  Future<void> _playIncomingMessageCue() async {
    await _playForegroundSound('sound-message.mp3');
  }

  Future<void> _playOutgoingMessageCue() async {
    await _playForegroundSound('zvukovoe-uvedomlenie-kontakta.mp3');
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

  Future<void> _playForegroundSound(String fileName) async {
    final appConfig = context.read<AppConfig>();
    await _messageSoundPlayer.stop();
    await _messageSoundPlayer.setReleaseMode(ReleaseMode.stop);
    await _messageSoundPlayer.play(
      UrlSource('${appConfig.baseUrl}/$fileName'),
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
      CallDisconnectReason.busy => null,
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
        'audio': true,
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

  Map<String, String> _captureConversationMessageSoundKeys(
    ChatController chatController,
  ) {
    final snapshot = <String, String>{};
    for (final conversation in chatController.conversations) {
      final lastMessage = conversation.lastMessage;
      if (lastMessage == null) {
        continue;
      }
      snapshot[conversation.id] = _messageSoundKey(lastMessage);
    }
    return snapshot;
  }

  String _messageSoundKey(ChatMessage message) {
    final clientMessageId = message.clientMessageId?.trim();
    if (clientMessageId != null && clientMessageId.isNotEmpty) {
      return 'client:$clientMessageId';
    }
    return 'id:${message.id}';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primary.withValues(alpha: isDark ? 0.16 : 0.08),
            scheme.tertiary.withValues(alpha: isDark ? 0.14 : 0.06),
            scheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
                    const WaveBrandLogo(
                      size: 28,
                      excludeFromSemantics: true,
                    ),
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
                                              color: scheme.surface,
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
    super.key,
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
    this.showBackButton = false,
    this.onBack,
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
  final bool showBackButton;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final active = conversation;
    if (active == null) {
      return const _EmptyChatState();
    }

    final partner = active.participant;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canSend = !active.blockedMe;
    final canStartCall = !active.isGroup &&
        !active.blockedByMe &&
        !active.blockedMe &&
        partner != null;

    return Container(
      color: isDark
          ? scheme.surfaceContainerHighest.withValues(alpha: 0.34)
          : Colors.white.withValues(alpha: 0.55),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
            decoration: BoxDecoration(
              color: isDark
                  ? scheme.surfaceContainerHigh.withValues(alpha: 0.72)
                  : Colors.white.withValues(alpha: 0.78),
              border: Border(
                bottom: BorderSide(
                  color: scheme.outlineVariant.withValues(alpha: 0.35),
                ),
              ),
            ),
            child: Row(
              children: [
                if (showBackButton) ...[
                  IconButton.filledTonal(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    style: IconButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
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
                        prefixIcon: settingsController.settings.vigenereEnabled
                            ? const Icon(Icons.lock_outline_rounded)
                            : const Padding(
                                padding: EdgeInsets.all(10),
                                child: WaveBrandLogo(
                                  size: 24,
                                  excludeFromSemantics: true,
                                ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bubbleColor = isMine
        ? scheme.primary
        : (isDark ? scheme.surfaceContainerHighest : Colors.white);
    final textColor = isMine
        ? scheme.onPrimary
        : (isDark ? scheme.onSurface : const Color(0xFF152238));
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
                color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.06),
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
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const WaveBrandLogo(
                  size: 118,
                  semanticLabel: 'Wave logo',
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

class _MobileHomeView extends StatelessWidget {
  const _MobileHomeView({
    super.key,
    required this.currentUser,
    required this.conversations,
    required this.allConversations,
    required this.settingsController,
    required this.activeTab,
    required this.selectedFilter,
    required this.selectedFeedTab,
    required this.onFilterChanged,
    required this.onFeedTabChanged,
    required this.onTabChanged,
    required this.onOpenConversation,
    required this.onOpenNewChat,
    required this.onOpenNewGroup,
    required this.onOpenSettings,
    required this.onOpenProfileEditor,
    required this.onUploadAvatar,
    required this.onRunMicrophoneTest,
    required this.onPreviewCallTone,
    required this.onCheckForUpdates,
    required this.appVersionText,
    required this.updateStatusText,
    required this.onLogout,
  });

  final PublicUser currentUser;
  final List<ConversationSummary> conversations;
  final List<ConversationSummary> allConversations;
  final SettingsController settingsController;
  final _MobileHomeTab activeTab;
  final _MobileChatFilter selectedFilter;
  final _ProfileFeedTab selectedFeedTab;
  final ValueChanged<_MobileChatFilter> onFilterChanged;
  final ValueChanged<_ProfileFeedTab> onFeedTabChanged;
  final ValueChanged<_MobileHomeTab> onTabChanged;
  final Future<void> Function(String conversationId) onOpenConversation;
  final VoidCallback onOpenNewChat;
  final VoidCallback onOpenNewGroup;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenProfileEditor;
  final Future<void> Function() onUploadAvatar;
  final Future<void> Function() onRunMicrophoneTest;
  final Future<void> Function() onPreviewCallTone;
  final Future<void> Function() onCheckForUpdates;
  final String? appVersionText;
  final String? updateStatusText;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFF4F5F7),
            Color(0xFFF0F2F5),
            Color(0xFFECEFF3),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: switch (activeTab) {
        _MobileHomeTab.chats => _MobileChatsTab(
            currentUser: currentUser,
            conversations: conversations,
            allConversations: allConversations,
            selectedFilter: selectedFilter,
            settingsController: settingsController,
            onFilterChanged: onFilterChanged,
            onOpenConversation: onOpenConversation,
            onOpenNewChat: onOpenNewChat,
            onOpenNewGroup: onOpenNewGroup,
            onOpenSettings: onOpenSettings,
            onLogout: onLogout,
          ),
        _MobileHomeTab.settings => _MobileSettingsTab(
            currentUser: currentUser,
            settingsController: settingsController,
            onUploadAvatar: onUploadAvatar,
            onOpenProfileEditor: onOpenProfileEditor,
            onRunMicrophoneTest: onRunMicrophoneTest,
            onPreviewCallTone: onPreviewCallTone,
            onCheckForUpdates: onCheckForUpdates,
            appVersionText: appVersionText,
            updateStatusText: updateStatusText,
            onLogout: onLogout,
          ),
        _MobileHomeTab.profile => _MobileProfileTab(
            currentUser: currentUser,
            selectedFeedTab: selectedFeedTab,
            onFeedTabChanged: onFeedTabChanged,
            onUploadAvatar: onUploadAvatar,
            onOpenProfileEditor: onOpenProfileEditor,
          ),
      },
    );
  }
}

class _MobileChatsTab extends StatelessWidget {
  const _MobileChatsTab({
    required this.currentUser,
    required this.conversations,
    required this.allConversations,
    required this.selectedFilter,
    required this.settingsController,
    required this.onFilterChanged,
    required this.onOpenConversation,
    required this.onOpenNewChat,
    required this.onOpenNewGroup,
    required this.onOpenSettings,
    required this.onLogout,
  });

  final PublicUser currentUser;
  final List<ConversationSummary> conversations;
  final List<ConversationSummary> allConversations;
  final _MobileChatFilter selectedFilter;
  final SettingsController settingsController;
  final ValueChanged<_MobileChatFilter> onFilterChanged;
  final Future<void> Function(String conversationId) onOpenConversation;
  final VoidCallback onOpenNewChat;
  final VoidCallback onOpenNewGroup;
  final VoidCallback onOpenSettings;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    final directCount = allConversations.where((item) => !item.isGroup).length;
    final groupCount = allConversations.where((item) => item.isGroup).length;
    final theme = Theme.of(context);

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 126),
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x12000000),
                        blurRadius: 18,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const WaveBrandLogo(size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Wave',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: const Color(0xFF1C232D),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '@${currentUser.username}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF7C8798),
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded),
                  onSelected: (value) {
                    if (value == 'chat') {
                      onOpenNewChat();
                    } else if (value == 'group') {
                      onOpenNewGroup();
                    } else if (value == 'settings') {
                      onOpenSettings();
                    } else if (value == 'logout') {
                      unawaited(onLogout());
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'chat', child: Text('Новый чат')),
                    PopupMenuItem(value: 'group', child: Text('Новая группа')),
                    PopupMenuItem(value: 'settings', child: Text('Настройки')),
                    PopupMenuItem(value: 'logout', child: Text('Выйти')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search_rounded, color: Color(0xFF8891A0)),
                  SizedBox(width: 10),
                  Text(
                    'Search chats',
                    style: TextStyle(
                      color: Color(0xFF8891A0),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _MobileFilterChip(
                    label: 'All Chats',
                    count: allConversations.length,
                    selected: selectedFilter == _MobileChatFilter.all,
                    onTap: () => onFilterChanged(_MobileChatFilter.all),
                  ),
                  const SizedBox(width: 8),
                  _MobileFilterChip(
                    label: 'Direct',
                    count: directCount,
                    selected: selectedFilter == _MobileChatFilter.direct,
                    onTap: () => onFilterChanged(_MobileChatFilter.direct),
                  ),
                  const SizedBox(width: 8),
                  _MobileFilterChip(
                    label: 'Groups',
                    count: groupCount,
                    selected: selectedFilter == _MobileChatFilter.groups,
                    onTap: () => onFilterChanged(_MobileChatFilter.groups),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (conversations.isEmpty)
              _MobileBlankCard(
                title: 'No chats yet',
                subtitle:
                    'Start a direct conversation or create a group to fill the list.',
                actionLabel: 'New chat',
                onAction: onOpenNewChat,
              )
            else
              ...conversations.map(
                (conversation) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _MobileConversationTile(
                    currentUser: currentUser,
                    conversation: conversation,
                    settingsController: settingsController,
                    onTap: () => onOpenConversation(conversation.id),
                  ),
                ),
              ),
          ],
        ),
        Positioned(
          right: 18,
          bottom: 102,
          child: FloatingActionButton(
            heroTag: 'mobile-chat-fab',
            onPressed: onOpenNewChat,
            backgroundColor: const Color(0xFF2DA8FF),
            foregroundColor: Colors.white,
            child: const Icon(Icons.add_rounded),
          ),
        ),
      ],
    );
  }
}

// ignore: unused_element
class _MobileContactsTab extends StatelessWidget {
  const _MobileContactsTab({
    required this.directConversations,
    required this.onOpenConversation,
  });

  final List<ConversationSummary> directConversations;
  final Future<void> Function(String conversationId) onOpenConversation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 126),
      children: [
        Text(
          'Contacts',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: const Color(0xFF1D232D),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Quick access to people you already talk to in Wave.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF778294),
          ),
        ),
        const SizedBox(height: 18),
        if (directConversations.isEmpty)
          const _MobileBlankCard(
            title: 'No contacts yet',
            subtitle: 'Open a direct chat and your people will appear here.',
          )
        else
          ...directConversations.map((conversation) {
            final partner = conversation.participant;
            final subtitle = partner == null
                ? 'Wave contact'
                : partner.online
                    ? 'online'
                    : partner.lastSeenAt != null
                        ? 'last seen ${DateFormat('dd.MM HH:mm').format(partner.lastSeenAt!)}'
                        : '@${partner.username}';
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(28),
                child: InkWell(
                  borderRadius: BorderRadius.circular(28),
                  onTap: () => onOpenConversation(conversation.id),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        WaveAvatar(
                          label: conversation.titleFor(''),
                          imageUrl: conversation.avatarSourceFor(''),
                          radius: 28,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                conversation.titleFor(''),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFF808998),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF9DA4B0),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}

// ignore: unused_element
class _LegacyMobileSettingsTab extends StatelessWidget {
  const _LegacyMobileSettingsTab({
    required this.currentUser,
    required this.onOpenSettings,
    required this.onTabChanged,
  });

  final PublicUser currentUser;
  final VoidCallback onOpenSettings;
  final ValueChanged<_MobileHomeTab> onTabChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 126),
      children: [
        Center(
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  WaveAvatar(
                    label: currentUser.displayNameOrUsername,
                    imageUrl: currentUser.avatarUrl,
                    radius: 44,
                  ),
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2DA8FF),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Icon(
                        Icons.photo_camera_outlined,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                currentUser.displayNameOrUsername,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: const Color(0xFF1B222C),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${currentUser.email}  •  @${currentUser.username}',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF7D8796),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            children: [
              _MobileSettingsRow(
                icon: Icons.person_rounded,
                iconColor: const Color(0xFF2DA8FF),
                title: 'Account',
                subtitle: 'Display name, avatar, profile details',
                onTap: () {
                  onTabChanged(_MobileHomeTab.profile);
                },
              ),
              _MobileSettingsRow(
                icon: Icons.chat_bubble_rounded,
                iconColor: const Color(0xFFF0A11C),
                title: 'Chat Settings',
                subtitle: 'Theme, composer, message behavior',
                onTap: onOpenSettings,
              ),
              _MobileSettingsRow(
                icon: Icons.key_rounded,
                iconColor: const Color(0xFF43C948),
                title: 'Privacy & Security',
                subtitle: 'Encryption, 2FA, protected chats',
                onTap: onOpenSettings,
              ),
              _MobileSettingsRow(
                icon: Icons.notifications_active_rounded,
                iconColor: const Color(0xFFF2516B),
                title: 'Notifications',
                subtitle: 'Sounds, badges and message alerts',
                onTap: onOpenSettings,
              ),
              _MobileSettingsRow(
                icon: Icons.folder_copy_rounded,
                iconColor: const Color(0xFF5F85FF),
                title: 'Data and Storage',
                subtitle: 'Media cache and downloads',
                onTap: onOpenSettings,
              ),
              _MobileSettingsRow(
                icon: Icons.battery_saver_rounded,
                iconColor: const Color(0xFFF28A2D),
                title: 'Power Saving',
                subtitle: 'Reduce activity when battery is low',
                onTap: onOpenSettings,
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MobileSettingsTab extends StatefulWidget {
  const _MobileSettingsTab({
    required this.currentUser,
    required this.settingsController,
    required this.onUploadAvatar,
    required this.onOpenProfileEditor,
    required this.onRunMicrophoneTest,
    required this.onPreviewCallTone,
    required this.onCheckForUpdates,
    required this.onLogout,
    this.appVersionText,
    this.updateStatusText,
  });

  final PublicUser currentUser;
  final SettingsController settingsController;
  final Future<void> Function() onUploadAvatar;
  final VoidCallback onOpenProfileEditor;
  final Future<void> Function() onRunMicrophoneTest;
  final Future<void> Function() onPreviewCallTone;
  final Future<void> Function() onCheckForUpdates;
  final Future<void> Function() onLogout;
  final String? appVersionText;
  final String? updateStatusText;

  @override
  State<_MobileSettingsTab> createState() => _MobileSettingsTabState();
}

class _MobileSettingsTabState extends State<_MobileSettingsTab> {
  late final TextEditingController _displayNameController;
  late final TextEditingController _encryptionKeyController;
  late final TextEditingController _twoFactorEnableController;
  late final TextEditingController _twoFactorDisableController;
  late final FocusNode _displayNameFocusNode;
  late final FocusNode _encryptionKeyFocusNode;
  _MobileSettingsSection? _expandedSection;

  SettingsController get _controller => widget.settingsController;
  PublicUser get _currentUser => _controller.currentUser ?? widget.currentUser;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController();
    _encryptionKeyController = TextEditingController();
    _twoFactorEnableController = TextEditingController();
    _twoFactorDisableController = TextEditingController();
    _displayNameFocusNode = FocusNode();
    _encryptionKeyFocusNode = FocusNode();
    _controller.addListener(_handleControllerChanged);
    _syncTextFields(force: true);
    if (!_controller.isBootstrapped) {
      unawaited(_controller.bootstrap());
    }
  }

  @override
  void didUpdateWidget(covariant _MobileSettingsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.settingsController, widget.settingsController)) {
      return;
    }
    oldWidget.settingsController.removeListener(_handleControllerChanged);
    widget.settingsController.addListener(_handleControllerChanged);
    _syncTextFields(force: true);
    if (!widget.settingsController.isBootstrapped) {
      unawaited(widget.settingsController.bootstrap());
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanged);
    _displayNameController.dispose();
    _encryptionKeyController.dispose();
    _twoFactorEnableController.dispose();
    _twoFactorDisableController.dispose();
    _displayNameFocusNode.dispose();
    _encryptionKeyFocusNode.dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    if (!mounted) {
      return;
    }
    _syncTextFields();
    setState(() {});
  }

  void _syncTextFields({bool force = false}) {
    final displayName = _currentUser.displayName ?? '';
    final encryptionKey = _controller.settings.vigenereKey;

    if (force ||
        (!_displayNameFocusNode.hasFocus &&
            _displayNameController.text != displayName)) {
      _displayNameController.value = TextEditingValue(
        text: displayName,
        selection: TextSelection.collapsed(offset: displayName.length),
      );
    }

    if (force ||
        (!_encryptionKeyFocusNode.hasFocus &&
            _encryptionKeyController.text != encryptionKey)) {
      _encryptionKeyController.value = TextEditingValue(
        text: encryptionKey,
        selection: TextSelection.collapsed(offset: encryptionKey.length),
      );
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete account?'),
          content: const Text(
            'This removes the profile, conversations, and account data. '
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      await _controller.deleteAccount();
    }
  }

  void _toggleExpandedSection(_MobileSettingsSection section) {
    setState(() {
      _expandedSection = _expandedSection == section ? null : section;
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final settings = controller.settings;
    final user = _currentUser;
    final joinedAt = DateFormat('dd.MM.yyyy').format(user.createdAt);
    final appearanceFeedback =
        controller.feedbackFor(SettingsFeedbackArea.appearance);
    final encryptionFeedback =
        controller.feedbackFor(SettingsFeedbackArea.encryption);
    final soundFeedback = controller.feedbackFor(SettingsFeedbackArea.sounds);
    final securityFeedback =
        controller.feedbackFor(SettingsFeedbackArea.security);
    final accountFeedback =
        controller.feedbackFor(SettingsFeedbackArea.account);
    final appearanceBusy =
        controller.isAreaBusy(SettingsFeedbackArea.appearance);
    final securityBusy = controller.isAreaBusy(SettingsFeedbackArea.security);
    final accountBusy = controller.isAreaBusy(SettingsFeedbackArea.account);
    final setup = controller.twoFactorSetup;
    final twoFactorEnabled = user.twoFactorEnabled;
    final metrics = controller.encryptionMetrics;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 126),
      children: [
        Center(
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  WaveAvatar(
                    label: user.displayNameOrUsername,
                    imageUrl: user.avatarUrl,
                    radius: 44,
                  ),
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2DA8FF),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                user.displayNameOrUsername,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: const Color(0xFF1B222C),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${user.email} • @${user.username}',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF7D8796),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        _MobileSettingsAccordionCard(
          icon: Icons.palette_outlined,
          title: 'Display',
          subtitle:
              'Profile photo, public name, theme mode and presentation preferences.',
          expanded: _expandedSection == _MobileSettingsSection.display,
          onToggle: () =>
              _toggleExpandedSection(_MobileSettingsSection.display),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (appearanceFeedback != null) ...[
                SettingsFeedbackBanner(
                  message: appearanceFeedback.message,
                  isError: appearanceFeedback.isError,
                ),
                const SizedBox(height: 16),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${user.email} • @${user.username}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed: appearanceBusy
                        ? null
                        : () => unawaited(widget.onUploadAvatar()),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Change photo'),
                  ),
                  OutlinedButton.icon(
                    onPressed:
                        appearanceBusy ? null : widget.onOpenProfileEditor,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit profile'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _displayNameController,
                focusNode: _displayNameFocusNode,
                enabled: !appearanceBusy,
                maxLength: 32,
                onChanged: (_) =>
                    controller.clearFeedback(SettingsFeedbackArea.appearance),
                decoration: const InputDecoration(
                  labelText: 'Display name',
                  hintText: 'Enter your public profile name',
                ),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: appearanceBusy
                    ? null
                    : () => controller.updateDisplayName(
                          _displayNameController.text,
                        ),
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save display name'),
              ),
              const SizedBox(height: 18),
              Text(
                'Theme mode',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ChoiceChip(
                    label: const Text('Light'),
                    avatar: const Icon(Icons.light_mode_outlined, size: 18),
                    selected: settings.themeMode == WaveThemeMode.light,
                    onSelected: (_) => controller.setThemeMode(
                      WaveThemeMode.light,
                    ),
                  ),
                  ChoiceChip(
                    label: const Text('Dark'),
                    avatar: const Icon(Icons.dark_mode_outlined, size: 18),
                    selected: settings.themeMode == WaveThemeMode.dark,
                    onSelected: (_) => controller.setThemeMode(
                      WaveThemeMode.dark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SwitchListTile.adaptive(
                value: settings.fullscreen,
                contentPadding: EdgeInsets.zero,
                title: const Text('Fullscreen mode'),
                subtitle: const Text(
                  'Open chat workspace in fullscreen presentation mode.',
                ),
                onChanged: controller.setFullscreen,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _MobileSettingsAccordionCard(
          icon: Icons.lock_outline_rounded,
          title: 'Encryption',
          subtitle:
              'Local Vigenere encryption settings used for compatible text messages.',
          expanded: _expandedSection == _MobileSettingsSection.encryption,
          onToggle: () =>
              _toggleExpandedSection(_MobileSettingsSection.encryption),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (encryptionFeedback != null) ...[
                SettingsFeedbackBanner(
                  message: encryptionFeedback.message,
                  isError: encryptionFeedback.isError,
                ),
                const SizedBox(height: 16),
              ],
              SwitchListTile.adaptive(
                value: settings.vigenereEnabled,
                contentPadding: EdgeInsets.zero,
                title: const Text('Encrypt outgoing text messages'),
                subtitle: const Text(
                  'Adds encryption metadata to outgoing text payloads.',
                ),
                onChanged: controller.setVigenereEnabled,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _encryptionKeyController,
                focusNode: _encryptionKeyFocusNode,
                obscureText: !controller.encryptionKeyVisible,
                onChanged: controller.setVigenereKey,
                decoration: InputDecoration(
                  labelText: 'Encryption key',
                  helperText: 'Empty values automatically fall back to WAVE.',
                  suffixIcon: IconButton(
                    onPressed: controller.toggleEncryptionKeyVisibility,
                    icon: Icon(
                      controller.encryptionKeyVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MobileSettingsMetricPill(
                    label: 'Strength',
                    value: metrics.label,
                  ),
                  _MobileSettingsMetricPill(
                    label: 'Entropy',
                    value: '${metrics.entropyBits} bits',
                  ),
                  _MobileSettingsMetricPill(
                    label: 'Estimate',
                    value: metrics.estimatedCrackTime,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest.withValues(alpha: 0.42),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preview',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const SelectableText('Hello, Wave / Привет, Wave'),
                    const SizedBox(height: 8),
                    SelectableText(
                      controller.encryptMessage('Hello, Wave / Привет, Wave'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: controller.saveEncryptionPreferences,
                icon: const Icon(Icons.lock_outline),
                label: const Text('Save encryption settings'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _MobileSettingsAccordionCard(
          icon: Icons.volume_up_outlined,
          title: 'Sound',
          subtitle:
              'Call audio levels, incoming call cues and local notification preferences.',
          expanded: _expandedSection == _MobileSettingsSection.sound,
          onToggle: () => _toggleExpandedSection(_MobileSettingsSection.sound),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (soundFeedback != null) ...[
                SettingsFeedbackBanner(
                  message: soundFeedback.message,
                  isError: soundFeedback.isError,
                ),
                const SizedBox(height: 16),
              ],
              _MobileSettingsSliderRow(
                icon: Icons.mic_none_outlined,
                label: 'Microphone level',
                value: settings.microphoneVolume.toDouble(),
                onChanged: controller.setMicrophoneVolume,
              ),
              const SizedBox(height: 12),
              _MobileSettingsSliderRow(
                icon: Icons.volume_up_outlined,
                label: 'Speaker level',
                value: settings.speakerVolume.toDouble(),
                onChanged: controller.setSpeakerVolume,
              ),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                value: settings.callSoundsEnabled,
                contentPadding: EdgeInsets.zero,
                title: const Text('Play call sounds'),
                subtitle: const Text(
                  'Incoming, ended and rejected call tones.',
                ),
                onChanged: controller.setCallSoundsEnabled,
              ),
              SwitchListTile.adaptive(
                value: settings.notificationsEnabled,
                contentPadding: EdgeInsets.zero,
                title: const Text('System notifications'),
                subtitle: const Text(
                  'Foreground and background alert preference for this device.',
                ),
                onChanged: controller.setNotificationsEnabled,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => unawaited(widget.onRunMicrophoneTest()),
                    icon: const Icon(Icons.graphic_eq_outlined),
                    label: const Text('Run mic test'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => unawaited(widget.onPreviewCallTone()),
                    icon: const Icon(Icons.notifications_active_outlined),
                    label: const Text('Preview tone'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: controller.saveSoundPreferences,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save sound settings'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _MobileSettingsAccordionCard(
          icon: Icons.verified_user_outlined,
          title: 'Security',
          subtitle: 'Google Authenticator based 2FA and protected chat access.',
          expanded: _expandedSection == _MobileSettingsSection.security,
          onToggle: () =>
              _toggleExpandedSection(_MobileSettingsSection.security),
          trailing: _MobileSettingsStatusBadge(
            label: twoFactorEnabled ? 'Enabled' : 'Disabled',
            active: twoFactorEnabled,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (securityFeedback != null) ...[
                SettingsFeedbackBanner(
                  message: securityFeedback.message,
                  isError: securityFeedback.isError,
                ),
                const SizedBox(height: 16),
              ],
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    onPressed:
                        securityBusy ? null : controller.beginTwoFactorSetup,
                    icon: const Icon(Icons.qr_code_2_outlined),
                    label: Text(
                      twoFactorEnabled
                          ? 'Rotate setup secret'
                          : 'Begin 2FA setup',
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed:
                        securityBusy ? null : controller.refreshTwoFactorStatus,
                    icon: const Icon(Icons.refresh_outlined),
                    label: const Text('Refresh status'),
                  ),
                ],
              ),
              if (setup?.isReady == true) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.network(
                    setup!.qrImageUrl,
                    width: 148,
                    height: 148,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return Container(
                        width: 148,
                        height: 148,
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(Icons.qr_code_2_outlined, size: 42),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SelectableText(
                  setup.secret,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _twoFactorEnableController,
                  enabled: !securityBusy,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: '6-digit code',
                    hintText: 'Enter the current authenticator code',
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: securityBusy
                      ? null
                      : () => controller.enableTwoFactor(
                            _twoFactorEnableController.text,
                          ),
                  icon: const Icon(Icons.verified_user_outlined),
                  label: const Text('Enable 2FA'),
                ),
              ],
              if (twoFactorEnabled) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _twoFactorDisableController,
                  enabled: !securityBusy,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'Disable code',
                    hintText: 'Enter your current 2FA code',
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: securityBusy
                      ? null
                      : () => controller.disableTwoFactor(
                            _twoFactorDisableController.text,
                          ),
                  icon: const Icon(Icons.lock_reset_outlined),
                  label: const Text('Disable 2FA'),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        _MobileSettingsAccordionCard(
          icon: Icons.person_outline_rounded,
          title: 'Account',
          subtitle:
              'Device update status, session actions and destructive account controls.',
          expanded: _expandedSection == _MobileSettingsSection.account,
          onToggle: () =>
              _toggleExpandedSection(_MobileSettingsSection.account),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (accountFeedback != null) ...[
                SettingsFeedbackBanner(
                  message: accountFeedback.message,
                  isError: accountFeedback.isError,
                ),
                const SizedBox(height: 16),
              ],
              Text(
                user.displayNameOrUsername,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${user.email} • @${user.username}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Joined $joinedAt',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              if (widget.appVersionText != null) ...[
                const SizedBox(height: 14),
                Text(
                  'Installed version: ${widget.appVersionText}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
              if (widget.updateStatusText != null &&
                  widget.updateStatusText!.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  widget.updateStatusText!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () => unawaited(widget.onCheckForUpdates()),
                    icon: const Icon(Icons.system_update_alt_rounded),
                    label: const Text('Check for updates'),
                  ),
                  OutlinedButton.icon(
                    onPressed:
                        accountBusy ? null : () => unawaited(widget.onLogout()),
                    icon: const Icon(Icons.logout_outlined),
                    label: const Text('Log out'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: accountBusy ? null : _confirmDeleteAccount,
                style: FilledButton.styleFrom(
                  backgroundColor: colors.error,
                  foregroundColor: colors.onError,
                ),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete account'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MobileProfileTab extends StatelessWidget {
  const _MobileProfileTab({
    required this.currentUser,
    required this.selectedFeedTab,
    required this.onFeedTabChanged,
    required this.onUploadAvatar,
    required this.onOpenProfileEditor,
  });

  final PublicUser currentUser;
  final _ProfileFeedTab selectedFeedTab;
  final ValueChanged<_ProfileFeedTab> onFeedTabChanged;
  final Future<void> Function() onUploadAvatar;
  final VoidCallback onOpenProfileEditor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final joinedAt = DateFormat('dd.MM.yyyy').format(currentUser.createdAt);

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 126),
      children: [
        Center(
          child: Column(
            children: [
              WaveAvatar(
                label: currentUser.displayNameOrUsername,
                imageUrl: currentUser.avatarUrl,
                radius: 52,
              ),
              const SizedBox(height: 16),
              Text(
                currentUser.displayNameOrUsername,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: const Color(0xFF171E28),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'online',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF7A8392),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: _MobileShortcutCard(
                icon: Icons.photo_camera_outlined,
                label: 'Set Photo',
                onTap: () => unawaited(onUploadAvatar()),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MobileShortcutCard(
                icon: Icons.edit_outlined,
                label: 'Edit Info',
                onTap: onOpenProfileEditor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            children: [
              _MobileInfoRow(
                value: currentUser.email,
                label: 'Email',
              ),
              const SizedBox(height: 18),
              _MobileInfoRow(
                value: '@${currentUser.username}',
                label: 'Username',
              ),
              const SizedBox(height: 18),
              _MobileInfoRow(
                value: 'Joined $joinedAt',
                label: 'Account',
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            children: [
              Expanded(
                child: _MobileSegmentButton(
                  label: 'Posts',
                  selected: selectedFeedTab == _ProfileFeedTab.posts,
                  onTap: () => onFeedTabChanged(_ProfileFeedTab.posts),
                ),
              ),
              Expanded(
                child: _MobileSegmentButton(
                  label: 'Archived Posts',
                  selected: selectedFeedTab == _ProfileFeedTab.archived,
                  onTap: () => onFeedTabChanged(_ProfileFeedTab.archived),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        Container(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(34),
          ),
          child: Column(
            children: [
              Text(
                selectedFeedTab == _ProfileFeedTab.posts
                    ? 'No posts yet...'
                    : 'No archived posts',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF141A24),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Publish photos and short moments so they appear here in the profile.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF7C8798),
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onOpenProfileEditor,
                icon: const Icon(Icons.add_a_photo_outlined),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2DA8FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 14,
                  ),
                ),
                label: const Text('Add a post'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MobileBottomDock extends StatelessWidget {
  const _MobileBottomDock({
    required this.currentUser,
    required this.activeTab,
    required this.chatsBadgeCount,
    required this.onTabSelected,
  });

  final PublicUser currentUser;
  final _MobileHomeTab activeTab;
  final int chatsBadgeCount;
  final ValueChanged<_MobileHomeTab> onTabSelected;

  int _tabIndex(_MobileHomeTab tab) {
    return switch (tab) {
      _MobileHomeTab.chats => 0,
      _MobileHomeTab.settings => 1,
      _MobileHomeTab.profile => 2,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 32,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final slotWidth = constraints.maxWidth / 3;
          return SizedBox(
            height: 68,
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 500),
                  curve: const Cubic(0.34, 1.56, 0.64, 1),
                  left: slotWidth * _tabIndex(activeTab),
                  top: 0,
                  bottom: 0,
                  width: slotWidth,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5F3FF),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x120088CC),
                            blurRadius: 18,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: _MobileBottomDockItem(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: 'Chats',
                        selected: activeTab == _MobileHomeTab.chats,
                        badgeCount: chatsBadgeCount,
                        onTap: () => onTabSelected(_MobileHomeTab.chats),
                      ),
                    ),
                    Expanded(
                      child: _MobileBottomDockItem(
                        icon: Icons.settings_outlined,
                        label: 'Settings',
                        selected: activeTab == _MobileHomeTab.settings,
                        onTap: () => onTabSelected(_MobileHomeTab.settings),
                      ),
                    ),
                    Expanded(
                      child: _MobileBottomDockItem(
                        label: 'Profile',
                        selected: activeTab == _MobileHomeTab.profile,
                        avatarUser: currentUser,
                        onTap: () => onTabSelected(_MobileHomeTab.profile),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MobileBottomDockItem extends StatelessWidget {
  const _MobileBottomDockItem({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.badgeCount = 0,
    this.avatarUser,
  });

  final IconData? icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badgeCount;
  final PublicUser? avatarUser;

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF0088CC);
    const inactiveColor = Color(0xFF1F2937);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(32),
      child: InkWell(
        borderRadius: BorderRadius.circular(32),
        onTap: onTap,
        child: SizedBox(
          height: 68,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 30,
                width: 46,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    if (avatarUser != null)
                      _MobileBottomDockAvatar(
                        user: avatarUser!,
                        selected: selected,
                      )
                    else if (icon != null)
                      Icon(
                        icon,
                        size: 24,
                        color: selected ? activeColor : inactiveColor,
                      ),
                    if (badgeCount > 0)
                      Positioned(
                        top: -4,
                        right: -6,
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 300),
                          scale: selected ? 1.1 : 1,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3390EC),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x14000000),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              badgeCount > 99 ? '99+' : '$badgeCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              Text(
                label,
                style: TextStyle(
                  color: selected ? activeColor : inactiveColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileBottomDockAvatar extends StatelessWidget {
  const _MobileBottomDockAvatar({
    required this.user,
    required this.selected,
  });

  final PublicUser user;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final avatarBytes = _decodeDataImage(user.avatarUrl);
    final avatarUrl = user.avatarUrl?.trim();
    final imageProvider = avatarBytes != null
        ? MemoryImage(avatarBytes)
        : (avatarUrl != null && avatarUrl.isNotEmpty
            ? NetworkImage(avatarUrl)
            : null) as ImageProvider<Object>?;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.all(selected ? 2 : 1),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? const Color(0xFF0088CC) : const Color(0xFFD6DEE8),
          width: selected ? 2 : 1,
        ),
      ),
      child: CircleAvatar(
        radius: 14,
        backgroundColor: const Color(0xFFCCE9F7),
        backgroundImage: imageProvider,
        child: imageProvider == null
            ? Text(
                user.displayNameOrUsername.isEmpty
                    ? '?'
                    : user.displayNameOrUsername[0].toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF173042),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              )
            : null,
      ),
    );
  }
}

class _MobileSettingsAccordionCard extends StatelessWidget {
  const _MobileSettingsAccordionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.expanded,
    required this.onToggle,
    required this.child,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: colors.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5F3FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: const Color(0xFF2796E3)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 12),
                    trailing!,
                  ],
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: expanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ClipRect(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: expanded
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Column(
                        children: [
                          Divider(
                            height: 1,
                            color:
                                colors.outlineVariant.withValues(alpha: 0.55),
                          ),
                          const SizedBox(height: 18),
                          child,
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileSettingsMetricPill extends StatelessWidget {
  const _MobileSettingsMetricPill({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          '$label: $value',
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
    );
  }
}

class _MobileSettingsStatusBadge extends StatelessWidget {
  const _MobileSettingsStatusBadge({
    required this.label,
    required this.active,
  });

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: active ? const Color(0xFFDCF7E7) : const Color(0xFFFFE6BF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: TextStyle(
            color: active ? const Color(0xFF1F8E4B) : const Color(0xFFA56300),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _MobileSettingsSliderRow extends StatelessWidget {
  const _MobileSettingsSliderRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final displayValue = value.round().clamp(0, 100);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF5B6573)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            Text(
              '$displayValue%',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: const Color(0xFF6C7685),
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        Slider(
          value: value.clamp(0, 100),
          min: 0,
          max: 100,
          divisions: 100,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _MobileConversationTile extends StatelessWidget {
  const _MobileConversationTile({
    required this.currentUser,
    required this.conversation,
    required this.settingsController,
    required this.onTap,
  });

  final PublicUser currentUser;
  final ConversationSummary conversation;
  final SettingsController settingsController;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lastMessage = conversation.lastMessage;
    final unread = lastMessage != null &&
        lastMessage.senderId != currentUser.id &&
        lastMessage.readAt == null;

    return Material(
      color: Colors.white.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  WaveAvatar(
                    label: conversation.avatarLabelFor(currentUser.id),
                    imageUrl: conversation.avatarSourceFor(currentUser.id),
                    radius: 28,
                  ),
                  if (!conversation.isGroup &&
                      conversation.participant?.online == true)
                    Positioned(
                      right: 0,
                      bottom: 1,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3CCB69),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.titleFor(currentUser.id),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: const Color(0xFF111821),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _formatTime(conversation.updatedAt),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: const Color(0xFF8090A0),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _conversationPreviewDecoded(
                              conversation,
                              settingsController,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF7B8595),
                            ),
                          ),
                        ),
                        if (unread)
                          Container(
                            margin: const EdgeInsets.only(left: 10),
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2DA8FF),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              '1',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileSettingsRow extends StatelessWidget {
  const _MobileSettingsRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isLast = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.vertical(
          top: const Radius.circular(30),
          bottom: Radius.circular(isLast ? 30 : 0),
        ),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            border: isLast
                ? null
                : const Border(
                    bottom: BorderSide(
                      color: Color(0xFFE8ECF2),
                    ),
                  ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF7D8897),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF97A0AE),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileShortcutCard extends StatelessWidget {
  const _MobileShortcutCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.88),
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
          child: Column(
            children: [
              Icon(icon, size: 26, color: const Color(0xFF1D232E)),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF1A2029),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileInfoRow extends StatelessWidget {
  const _MobileInfoRow({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: const Color(0xFF141A24),
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF8B94A2),
              ),
        ),
      ],
    );
  }
}

class _MobileSegmentButton extends StatelessWidget {
  const _MobileSegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFE3F2FF) : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color:
                  selected ? const Color(0xFF258FDD) : const Color(0xFF7A8494),
              fontSize: 15,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileFilterChip extends StatelessWidget {
  const _MobileFilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? const Color(0xFFE5F3FF)
          : Colors.white.withValues(alpha: 0.82),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? const Color(0xFF258FDD)
                      : const Color(0xFF6E7785),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF2DA8FF)
                      : const Color(0xFFDCE2EA),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: selected ? Colors.white : const Color(0xFF79808C),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileBlankCard extends StatelessWidget {
  const _MobileBlankCard({
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF7E8795),
                ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 18),
            FilledButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
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
