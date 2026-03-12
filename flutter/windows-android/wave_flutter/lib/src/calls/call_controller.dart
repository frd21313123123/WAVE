import 'dart:async';

import 'package:flutter/foundation.dart';

import '../controllers/chat_controller.dart';
import '../models/app_models.dart';
import '../models/call_models.dart';
import '../services/realtime_service.dart';
import 'call_media_engine.dart';

class CallController extends ChangeNotifier {
  CallController({
    required this.chatController,
    required this.realtimeService,
    required this.mediaEngineFactory,
    this.rtcConfigurationLoader,
    this.disconnectGrace = const Duration(seconds: 12),
  });

  final ChatController chatController;
  final RealtimeService realtimeService;
  final CallMediaEngineFactory mediaEngineFactory;
  final Future<Map<String, dynamic>?> Function()? rtcConfigurationLoader;
  final Duration disconnectGrace;

  final Map<String, List<Map<String, dynamic>>> _preOfferIceByKey =
      <String, List<Map<String, dynamic>>>{};

  StreamSubscription<Map<String, dynamic>>? _realtimeSubscription;
  StreamSubscription<Map<String, dynamic>>? _localIceSubscription;
  Timer? _elapsedTimer;
  Timer? _disconnectTimer;
  CallMediaEngine? _engine;
  CallUiState _state = const CallUiState.idle();
  CallMediaConnectionState _lastObservedConnectionState =
      CallMediaConnectionState.idle;
  bool _isActive = false;
  bool _disposed = false;
  bool _recoveryOfferInFlight = false;
  String? _targetUserId;
  String? _conversationId;
  String? _callId;

  CallUiState get state => _state;
  CallMediaEngine? get mediaEngine => _engine;

  Future<void> activate() async {
    if (_isActive) {
      return;
    }
    _isActive = true;
    _realtimeSubscription = realtimeService.events.listen((event) {
      unawaited(_handleRealtimeEvent(event));
    });
  }

  Future<void> deactivate() async {
    _isActive = false;
    await _realtimeSubscription?.cancel();
    _realtimeSubscription = null;
    _preOfferIceByKey.clear();
    await _disposeEngine();
    _stopElapsedTimer();
    _cancelDisconnectGrace();
    _targetUserId = null;
    _conversationId = null;
    _callId = null;
    _setState(const CallUiState.idle());
  }

  Future<void> startOutgoingCall({
    required PublicUser peer,
    String? conversationId,
    bool videoRequested = false,
  }) async {
    await activate();
    _assertReadyForNewCall();

    final conversation = await _resolveDirectConversation(
      peerId: peer.id,
      conversationId: conversationId,
    );
    _assertCallableConversation(conversation);

    final peerSnapshot = _toPeerSnapshot(peer);
    _targetUserId = peer.id;
    _conversationId = conversation.id;
    _callId = _generateCallId();

    await _attachFreshEngine();
    _setState(
      CallUiState(
        stage: CallStage.outgoing,
        statusText: 'Звоним...',
        disconnectReason: CallDisconnectReason.none,
        peer: peerSnapshot,
        conversationId: conversation.id,
      ),
    );

    try {
      await _engine!.prepareOutgoing(videoRequested: videoRequested);
      _syncEngineState(statusText: 'Звоним...');
      final offer = await _engine!.createOffer();
      await _sendSignal(
        targetUserId: peer.id,
        signalType: 'offer',
        conversationId: conversation.id,
        callId: _callId,
        data: <String, dynamic>{
          'sdp': offer,
          'videoRequested': videoRequested,
        },
      );
    } catch (_) {
      await _teardownSession(
        notifyPeer: false,
        statusText: 'Не удалось начать звонок.',
        disconnectReason: CallDisconnectReason.connectionLost,
      );
      rethrow;
    }
  }

  Future<void> acceptIncomingCall({bool? videoRequested}) async {
    await activate();
    final pendingIncoming = _state.pendingIncoming;
    if (pendingIncoming == null || _state.incomingActionInFlight) {
      return;
    }

    _targetUserId = pendingIncoming.fromUserId;
    _conversationId = pendingIncoming.conversationId;
    _callId = pendingIncoming.callId;
    _setState(
      _state.copyWith(
        incomingActionInFlight: true,
        statusText: 'Подключение...',
      ),
    );

    await _attachFreshEngine();

    try {
      final enableVideo = videoRequested ?? pendingIncoming.videoRequested;
      await _engine!.prepareIncoming(videoRequested: enableVideo);
      await _engine!.applyRemoteOffer(pendingIncoming.offerSdp);
      for (final candidate in pendingIncoming.pendingIceCandidates) {
        await _engine!.addRemoteIceCandidate(candidate);
      }

      final answer = await _engine!.createAnswer();
      _markActive(
        peer: pendingIncoming.peer,
        conversationId: pendingIncoming.conversationId,
        statusText: 'В звонке.',
      );
      await _sendSignal(
        targetUserId: pendingIncoming.fromUserId,
        signalType: 'answer',
        conversationId: pendingIncoming.conversationId,
        callId: pendingIncoming.callId,
        data: <String, dynamic>{'sdp': answer},
      );
    } catch (_) {
      await _sendSignal(
        targetUserId: pendingIncoming.fromUserId,
        signalType: 'reject',
        conversationId: pendingIncoming.conversationId,
        callId: pendingIncoming.callId,
      );
      await _teardownSession(
        notifyPeer: false,
        statusText: 'Не удалось принять звонок.',
        disconnectReason: CallDisconnectReason.rejected,
      );
      rethrow;
    }
  }

  Future<void> rejectIncomingCall({
    String statusText = 'Входящий звонок отклонен.',
  }) async {
    final pendingIncoming = _state.pendingIncoming;
    if (pendingIncoming == null) {
      return;
    }

    await _sendSignal(
      targetUserId: pendingIncoming.fromUserId,
      signalType: 'reject',
      conversationId: pendingIncoming.conversationId,
      callId: pendingIncoming.callId,
    );
    _preOfferIceByKey.remove(
      _signalQueueKey(
        userId: pendingIncoming.fromUserId,
        conversationId: pendingIncoming.conversationId,
        callId: pendingIncoming.callId,
      ),
    );
    _targetUserId = null;
    _conversationId = null;
    _callId = null;
    _setState(
      const CallUiState.idle().copyWith(
        statusText: statusText,
        disconnectReason: CallDisconnectReason.rejected,
      ),
    );
  }

  Future<void> endCall({
    bool notifyPeer = true,
    String? statusText,
  }) async {
    if (_state.pendingIncoming != null && !_state.hasLiveCall) {
      await rejectIncomingCall(
        statusText: statusText ?? 'Входящий звонок отклонен.',
      );
      return;
    }
    if (_state.isIdle) {
      return;
    }

    await _teardownSession(
      notifyPeer: notifyPeer,
      statusText: statusText ?? 'Звонок завершен.',
      disconnectReason: CallDisconnectReason.endedByLocal,
    );
  }

  Future<void> toggleMuted() async {
    final engine = _engine;
    if (engine == null) {
      return;
    }
    await engine.setMuted(!engine.muted);
    _syncEngineState();
  }

  Future<void> toggleSpeaker() async {
    final engine = _engine;
    if (engine == null) {
      return;
    }
    await engine.setSpeakerEnabled(!engine.speakerEnabled);
    _syncEngineState();
  }

  Future<void> toggleCamera() async {
    final engine = _engine;
    if (engine == null) {
      return;
    }
    await engine.setCameraEnabled(!engine.cameraEnabled);
    _syncEngineState();
    if (_state.hasLiveCall || _state.isOutgoing) {
      await _sendOffer();
    }
  }

  Future<void> _handleRealtimeEvent(Map<String, dynamic> event) async {
    final type = event['type']?.toString();
    if (type != 'call:signal') {
      return;
    }

    final fromUserId = event['fromUserId']?.toString();
    final signalType = event['signalType']?.toString();
    final conversationId = event['conversationId']?.toString();
    final rawData = event['data'];
    final data = rawData is Map<String, dynamic>
        ? rawData
        : rawData is Map
            ? Map<String, dynamic>.from(rawData)
            : const <String, dynamic>{};
    final signalCallId = _readCallId(data);

    if (fromUserId == null || signalType == null) {
      return;
    }

    switch (signalType) {
      case 'offer':
        await _handleOffer(
          fromUserId: fromUserId,
          conversationId: conversationId,
          callId: signalCallId,
          data: data,
        );
        return;
      case 'answer':
        await _handleAnswer(
          fromUserId: fromUserId,
          conversationId: conversationId,
          callId: signalCallId,
          data: data,
        );
        return;
      case 'ice':
        await _handleIce(
          fromUserId: fromUserId,
          conversationId: conversationId,
          callId: signalCallId,
          data: data,
        );
        return;
      case 'reject':
        if (_isCurrentPeer(fromUserId) &&
            _callIdsMatch(_callId, signalCallId) &&
            !_state.isActive &&
            !_state.isReconnecting) {
          await _teardownSession(
            notifyPeer: false,
            statusText: 'Собеседник отклонил звонок.',
            disconnectReason: CallDisconnectReason.rejected,
          );
        }
        return;
      case 'busy':
        if (_isCurrentPeer(fromUserId) &&
            _callIdsMatch(_callId, signalCallId) &&
            !_state.isActive &&
            !_state.isReconnecting) {
          await _teardownSession(
            notifyPeer: false,
            statusText: 'Собеседник сейчас в другом звонке.',
            disconnectReason: CallDisconnectReason.busy,
          );
        }
        return;
      case 'end':
        if (_state.pendingIncoming?.fromUserId == fromUserId &&
            _callIdsMatch(_state.pendingIncoming?.callId, signalCallId)) {
          _preOfferIceByKey.remove(
            _signalQueueKey(
              userId: fromUserId,
              conversationId: conversationId,
              callId: signalCallId,
            ),
          );
          _setState(
            const CallUiState.idle().copyWith(
              statusText: 'Собеседник отменил звонок.',
              disconnectReason: CallDisconnectReason.endedByRemote,
            ),
          );
          return;
        }
        if (_isCurrentPeer(fromUserId) &&
            _callIdsMatch(_callId, signalCallId)) {
          await _teardownSession(
            notifyPeer: false,
            statusText: 'Собеседник завершил звонок.',
            disconnectReason: CallDisconnectReason.endedByRemote,
          );
        }
        return;
      default:
        return;
    }
  }

  Future<void> _handleOffer({
    required String fromUserId,
    required String? conversationId,
    required String? callId,
    required Map<String, dynamic> data,
  }) async {
    final sdp = data['sdp'];
    final sdpMap = sdp is Map<String, dynamic>
        ? sdp
        : sdp is Map
            ? Map<String, dynamic>.from(sdp)
            : null;

    if (sdpMap == null) {
      await _sendSignal(
        targetUserId: fromUserId,
        signalType: 'reject',
        conversationId: conversationId,
        callId: callId,
      );
      return;
    }

    if (_isCurrentPeer(fromUserId) &&
        _engine != null &&
        !_state.isIdle &&
        _callIdsMatch(_callId, callId)) {
      if (_state.incomingActionInFlight) {
        return;
      }
      try {
        await _engine!.applyRemoteOffer(sdpMap);
        final answer = await _engine!.createAnswer();
        await _sendSignal(
          targetUserId: fromUserId,
          signalType: 'answer',
          conversationId: conversationId ?? _conversationId,
          callId: callId ?? _callId,
          data: <String, dynamic>{'sdp': answer},
        );
        if (_state.isOutgoing || _state.isReconnecting) {
          _markActive(
            peer:
                _state.peer ?? _resolvePeerSnapshot(fromUserId, conversationId),
            conversationId: conversationId ?? _conversationId ?? '',
            statusText: 'В звонке.',
          );
        }
      } catch (_) {
        await _teardownSession(
          notifyPeer: true,
          statusText: 'Соединение прервано.',
          disconnectReason: CallDisconnectReason.connectionLost,
        );
      }
      return;
    }

    final existingPending = _state.pendingIncoming;
    if (!_state.isIdle &&
        (existingPending == null || existingPending.fromUserId != fromUserId)) {
      await _sendSignal(
        targetUserId: fromUserId,
        signalType: 'busy',
        conversationId: conversationId,
        callId: callId,
      );
      return;
    }

    final samePendingCall = existingPending != null &&
        existingPending.fromUserId == fromUserId &&
        _callIdsMatch(existingPending.callId, callId);
    final queuedIce = List<Map<String, dynamic>>.from(
      _preOfferIceByKey.remove(
            _signalQueueKey(
              userId: fromUserId,
              conversationId: conversationId,
              callId: callId,
            ),
          ) ??
          const <Map<String, dynamic>>[],
    );
    final peer = _resolvePeerSnapshot(fromUserId, conversationId);
    final pendingIncoming = PendingIncomingCall(
      fromUserId: fromUserId,
      conversationId: conversationId ?? existingPending?.conversationId ?? '',
      callId: callId ?? existingPending?.callId ?? '',
      offerSdp: sdpMap,
      peer: peer,
      pendingIceCandidates: <Map<String, dynamic>>[
        ...(samePendingCall
            ? existingPending.pendingIceCandidates
            : const <Map<String, dynamic>>[]),
        ...queuedIce,
      ],
      videoRequested:
          data['videoRequested'] == true || data['requestVideo'] == true,
    );

    _targetUserId = null;
    _conversationId = null;
    _callId = null;
    _setState(
      CallUiState(
        stage: CallStage.incoming,
        statusText: 'Входящий звонок...',
        disconnectReason: CallDisconnectReason.none,
        peer: peer,
        conversationId: pendingIncoming.conversationId,
        pendingIncoming: pendingIncoming,
      ),
    );
  }

  Future<void> _handleAnswer({
    required String fromUserId,
    required String? conversationId,
    required String? callId,
    required Map<String, dynamic> data,
  }) async {
    if (!_isCurrentPeer(fromUserId) ||
        _engine == null ||
        !_callIdsMatch(_callId, callId)) {
      return;
    }

    final sdp = data['sdp'];
    final sdpMap = sdp is Map<String, dynamic>
        ? sdp
        : sdp is Map
            ? Map<String, dynamic>.from(sdp)
            : null;
    if (sdpMap == null) {
      return;
    }

    await _engine!.applyRemoteAnswer(sdpMap);
    _markActive(
      peer: _state.peer ?? _resolvePeerSnapshot(fromUserId, conversationId),
      conversationId: conversationId ?? _conversationId ?? '',
      statusText: 'В звонке.',
    );
  }

  Future<void> _handleIce({
    required String fromUserId,
    required String? conversationId,
    required String? callId,
    required Map<String, dynamic> data,
  }) async {
    final candidate = data['candidate'];
    final candidateMap = candidate is Map<String, dynamic>
        ? candidate
        : candidate is Map
            ? Map<String, dynamic>.from(candidate)
            : null;
    if (candidateMap == null) {
      return;
    }

    final pendingIncoming = _state.pendingIncoming;
    if (pendingIncoming != null &&
        pendingIncoming.fromUserId == fromUserId &&
        _callIdsMatch(pendingIncoming.callId, callId) &&
        _engine == null) {
      _setState(
        _state.copyWith(
          pendingIncoming: pendingIncoming.copyWith(
            pendingIceCandidates: <Map<String, dynamic>>[
              ...pendingIncoming.pendingIceCandidates,
              candidateMap,
            ],
          ),
        ),
      );
      return;
    }

    if (_isCurrentPeer(fromUserId) &&
        _engine != null &&
        _callIdsMatch(_callId, callId)) {
      await _engine!.addRemoteIceCandidate(candidateMap);
      return;
    }

    _preOfferIceByKey
        .putIfAbsent(
          _signalQueueKey(
            userId: fromUserId,
            conversationId: conversationId,
            callId: callId,
          ),
          () => <Map<String, dynamic>>[],
        )
        .add(candidateMap);
  }

  Future<void> _attachFreshEngine() async {
    await _disposeEngine();
    Map<String, dynamic>? rtcConfiguration;
    if (rtcConfigurationLoader != null) {
      try {
        rtcConfiguration = await rtcConfigurationLoader!();
      } catch (_) {}
    }
    final engine = mediaEngineFactory(rtcConfiguration: rtcConfiguration);
    _engine = engine;
    _lastObservedConnectionState = engine.connectionState;
    engine.addListener(_handleEngineUpdated);
    _localIceSubscription = engine.localIceCandidates.listen((candidate) {
      final targetUserId = _targetUserId;
      if (targetUserId == null) {
        return;
      }
      unawaited(
        _sendSignal(
          targetUserId: targetUserId,
          signalType: 'ice',
          conversationId: _conversationId,
          callId: _callId,
          data: <String, dynamic>{'candidate': candidate},
        ),
      );
    });
    await engine.initialize();
  }

  Future<void> _disposeEngine() async {
    _cancelDisconnectGrace();
    await _localIceSubscription?.cancel();
    _localIceSubscription = null;

    final engine = _engine;
    _engine = null;
    if (engine != null) {
      engine.removeListener(_handleEngineUpdated);
      await engine.disposeCall();
      engine.dispose();
    }

    _lastObservedConnectionState = CallMediaConnectionState.idle;
  }

  void _handleEngineUpdated() {
    final engine = _engine;
    if (engine == null) {
      return;
    }

    final previousState = _lastObservedConnectionState;
    final currentState = engine.connectionState;
    _lastObservedConnectionState = currentState;
    _syncEngineState();

    if (previousState == currentState) {
      return;
    }

    switch (currentState) {
      case CallMediaConnectionState.connected:
        _cancelDisconnectGrace();
        if (!_state.isIdle) {
          _markActive(
            peer: _state.peer,
            conversationId: _conversationId ?? _state.conversationId ?? '',
            statusText: 'В звонке.',
          );
        }
        return;
      case CallMediaConnectionState.disconnected:
      case CallMediaConnectionState.failed:
        if (_state.hasLiveCall || _state.isOutgoing) {
          _beginDisconnectGrace();
        }
        return;
      case CallMediaConnectionState.closed:
        if (!_state.isIdle) {
          unawaited(
            _teardownSession(
              notifyPeer: false,
              statusText: 'Соединение прервано.',
              disconnectReason: CallDisconnectReason.connectionLost,
            ),
          );
        }
        return;
      case CallMediaConnectionState.idle:
      case CallMediaConnectionState.connecting:
        return;
    }
  }

  Future<void> _sendOffer({bool iceRestart = false}) async {
    final engine = _engine;
    final targetUserId = _targetUserId;
    final conversationId = _conversationId;
    if (engine == null || targetUserId == null || conversationId == null) {
      return;
    }
    _callId ??= _generateCallId();

    final offer = await engine.createOffer(iceRestart: iceRestart);
    await _sendSignal(
      targetUserId: targetUserId,
      signalType: 'offer',
      conversationId: conversationId,
      callId: _callId,
      data: <String, dynamic>{
        'sdp': offer,
        if (iceRestart) 'recovery': true,
      },
    );
  }

  void _markActive({
    required CallPeerSnapshot? peer,
    required String conversationId,
    required String statusText,
  }) {
    final startedAt = _state.startedAt ?? DateTime.now();
    _conversationId = conversationId;
    _setState(
      _state.copyWith(
        stage: CallStage.active,
        statusText: statusText,
        disconnectReason: CallDisconnectReason.none,
        peer: peer,
        conversationId: conversationId,
        clearPendingIncoming: true,
        startedAt: startedAt,
        elapsed: DateTime.now().difference(startedAt),
        incomingActionInFlight: false,
      ),
    );
    _startElapsedTimer(startedAt);
    _syncEngineState();
  }

  void _syncEngineState({String? statusText}) {
    final engine = _engine;
    if (engine == null || _state.isIdle && _state.pendingIncoming == null) {
      return;
    }

    _setState(
      _state.copyWith(
        statusText: statusText ?? _state.statusText,
        muted: engine.muted,
        speakerEnabled: engine.speakerEnabled,
        cameraEnabled: engine.cameraEnabled,
        localVideoVisible: engine.localVideoVisible,
        remoteVideoVisible: engine.remoteVideoVisible,
        localSpeaking: engine.localSpeaking,
        remoteSpeaking: engine.remoteSpeaking,
      ),
    );
  }

  void _beginDisconnectGrace() {
    if (_disconnectTimer != null) {
      return;
    }

    _setState(
      _state.copyWith(
        stage: CallStage.reconnecting,
        statusText: 'Связь нестабильна, пытаемся восстановить...',
      ),
    );
    _disconnectTimer = Timer(disconnectGrace, () {
      _disconnectTimer = null;
      unawaited(
        _teardownSession(
          notifyPeer: true,
          statusText: 'Соединение прервано.',
          disconnectReason: CallDisconnectReason.connectionLost,
        ),
      );
    });

    if (!_recoveryOfferInFlight) {
      _recoveryOfferInFlight = true;
      unawaited(
        _sendOffer(iceRestart: true).whenComplete(() {
          _recoveryOfferInFlight = false;
        }),
      );
    }
  }

  void _cancelDisconnectGrace() {
    _disconnectTimer?.cancel();
    _disconnectTimer = null;
  }

  void _startElapsedTimer(DateTime startedAt) {
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _setState(
        _state.copyWith(
          elapsed: DateTime.now().difference(startedAt),
        ),
      );
    });
  }

  void _stopElapsedTimer() {
    _elapsedTimer?.cancel();
    _elapsedTimer = null;
  }

  Future<void> _teardownSession({
    required bool notifyPeer,
    required String statusText,
    required CallDisconnectReason disconnectReason,
  }) async {
    final pendingIncoming = _state.pendingIncoming;
    final targetUserId = _targetUserId ?? pendingIncoming?.fromUserId;
    final conversationId = _conversationId ??
        _state.conversationId ??
        pendingIncoming?.conversationId;
    final callId = _callId ?? pendingIncoming?.callId;

    if (notifyPeer && targetUserId != null && conversationId != null) {
      await _sendSignal(
        targetUserId: targetUserId,
        signalType: 'end',
        conversationId: conversationId,
        callId: callId,
      );
    }

    _stopElapsedTimer();
    await _disposeEngine();
    _targetUserId = null;
    _conversationId = null;
    _callId = null;
    _setState(
      const CallUiState.idle().copyWith(
        statusText: statusText,
        disconnectReason: disconnectReason,
      ),
    );
  }

  Future<void> _sendSignal({
    required String targetUserId,
    required String signalType,
    String? conversationId,
    String? callId,
    Map<String, dynamic>? data,
  }) {
    final payloadData = <String, dynamic>{
      if (data != null) ...data,
      if (callId != null && callId.isNotEmpty) 'callId': callId,
    };
    return realtimeService.send(
      <String, dynamic>{
        'type': 'call:signal',
        'targetUserId': targetUserId,
        'signalType': signalType,
        if (conversationId != null && conversationId.isNotEmpty)
          'conversationId': conversationId,
        if (payloadData.isNotEmpty) 'data': payloadData,
      },
    );
  }

  String _generateCallId() {
    final micros = DateTime.now().microsecondsSinceEpoch;
    return 'call-$micros-${micros.toRadixString(36)}';
  }

  String? _readCallId(Map<String, dynamic> data) {
    final value = data['callId']?.toString().trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  bool _callIdsMatch(String? currentCallId, String? incomingCallId) {
    if ((currentCallId ?? '').isEmpty || (incomingCallId ?? '').isEmpty) {
      return true;
    }
    return currentCallId == incomingCallId;
  }

  String _signalQueueKey({
    required String userId,
    String? conversationId,
    String? callId,
  }) {
    final normalizedCallId = callId?.trim();
    if (normalizedCallId != null && normalizedCallId.isNotEmpty) {
      return '$userId::$normalizedCallId';
    }
    final normalizedConversationId = conversationId?.trim();
    if (normalizedConversationId != null &&
        normalizedConversationId.isNotEmpty) {
      return '$userId::$normalizedConversationId';
    }
    return userId;
  }

  ConversationSummary _assertCallableConversation(
      ConversationSummary conversation) {
    if (conversation.isGroup) {
      throw StateError('Calls are supported only for direct conversations.');
    }
    if (conversation.blockedByMe || conversation.blockedMe) {
      throw StateError('Calls are not available in blocked conversations.');
    }
    return conversation;
  }

  Future<ConversationSummary> _resolveDirectConversation({
    required String peerId,
    required String? conversationId,
  }) async {
    if (conversationId != null) {
      final conversation = chatController.conversationById(conversationId);
      if (conversation != null) {
        return conversation;
      }
    }

    for (final conversation in chatController.conversations) {
      if (conversation.isGroup) {
        continue;
      }
      if (conversation.participant?.id == peerId ||
          conversation.participantIds.contains(peerId)) {
        return conversation;
      }
    }

    return chatController.createDirectConversation(peerId);
  }

  CallPeerSnapshot _resolvePeerSnapshot(String userId, String? conversationId) {
    final currentUser = chatController.currentUser;
    ConversationSummary? conversation;
    if (conversationId != null && conversationId.isNotEmpty) {
      conversation = chatController.conversationById(conversationId);
    }

    if (conversation == null) {
      for (final item in chatController.conversations) {
        if (item.isGroup) {
          continue;
        }
        if (item.participant?.id == userId ||
            item.participantIds.contains(userId)) {
          conversation = item;
          break;
        }
      }
    }

    PublicUser? participant = conversation?.participant;
    if (participant == null || participant.id != userId) {
      for (final item in conversation?.participants ?? const <PublicUser>[]) {
        if (item.id == userId && item.id != currentUser?.id) {
          participant = item;
          break;
        }
      }
    }

    if (participant != null) {
      return _toPeerSnapshot(participant);
    }

    return CallPeerSnapshot(
      userId: userId,
      displayName: 'Собеседник',
    );
  }

  CallPeerSnapshot _toPeerSnapshot(PublicUser user) {
    return CallPeerSnapshot(
      userId: user.id,
      displayName: user.displayNameOrUsername,
      avatarUrl: user.avatarUrl,
    );
  }

  bool _isCurrentPeer(String userId) {
    return userId.isNotEmpty && _targetUserId == userId;
  }

  void _assertReadyForNewCall() {
    if (!_state.isIdle || _state.pendingIncoming != null) {
      throw StateError('A call is already in progress.');
    }
  }

  void _setState(CallUiState nextState) {
    if (_disposed) {
      return;
    }
    _state = nextState;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _elapsedTimer?.cancel();
    _disconnectTimer?.cancel();
    _engine?.removeListener(_handleEngineUpdated);
    unawaited(_realtimeSubscription?.cancel() ?? Future<void>.value());
    unawaited(_localIceSubscription?.cancel() ?? Future<void>.value());
    final engine = _engine;
    _engine = null;
    if (engine != null) {
      unawaited(engine.disposeCall());
      engine.dispose();
    }
    super.dispose();
  }
}
