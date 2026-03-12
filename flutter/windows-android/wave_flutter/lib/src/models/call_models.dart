import 'package:flutter/foundation.dart';

enum CallStage {
  idle,
  outgoing,
  incoming,
  active,
  reconnecting,
}

enum CallSignalType {
  offer,
  answer,
  ice,
  reject,
  busy,
  end,
}

enum CallDisconnectReason {
  none,
  rejected,
  busy,
  endedByRemote,
  endedByLocal,
  connectionLost,
}

enum CallMediaConnectionState {
  idle,
  connecting,
  connected,
  disconnected,
  failed,
  closed,
}

@immutable
class CallPeerSnapshot {
  const CallPeerSnapshot({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
  });

  final String userId;
  final String displayName;
  final String? avatarUrl;
}

@immutable
class PendingIncomingCall {
  const PendingIncomingCall({
    required this.fromUserId,
    required this.conversationId,
    required this.callId,
    required this.offerSdp,
    required this.peer,
    this.pendingIceCandidates = const <Map<String, dynamic>>[],
    this.videoRequested = false,
  });

  final String fromUserId;
  final String conversationId;
  final String callId;
  final Map<String, dynamic> offerSdp;
  final CallPeerSnapshot peer;
  final List<Map<String, dynamic>> pendingIceCandidates;
  final bool videoRequested;

  PendingIncomingCall copyWith({
    String? fromUserId,
    String? conversationId,
    String? callId,
    Map<String, dynamic>? offerSdp,
    CallPeerSnapshot? peer,
    List<Map<String, dynamic>>? pendingIceCandidates,
    bool? videoRequested,
  }) {
    return PendingIncomingCall(
      fromUserId: fromUserId ?? this.fromUserId,
      conversationId: conversationId ?? this.conversationId,
      callId: callId ?? this.callId,
      offerSdp: offerSdp ?? this.offerSdp,
      peer: peer ?? this.peer,
      pendingIceCandidates: pendingIceCandidates ?? this.pendingIceCandidates,
      videoRequested: videoRequested ?? this.videoRequested,
    );
  }
}

@immutable
class CallUiState {
  const CallUiState({
    required this.stage,
    required this.statusText,
    required this.disconnectReason,
    this.peer,
    this.conversationId,
    this.pendingIncoming,
    this.elapsed = Duration.zero,
    this.startedAt,
    this.muted = false,
    this.speakerEnabled = true,
    this.cameraEnabled = false,
    this.localVideoVisible = false,
    this.remoteVideoVisible = false,
    this.localSpeaking = false,
    this.remoteSpeaking = false,
    this.incomingActionInFlight = false,
  });

  const CallUiState.idle()
      : stage = CallStage.idle,
        statusText = '',
        disconnectReason = CallDisconnectReason.none,
        peer = null,
        conversationId = null,
        pendingIncoming = null,
        elapsed = Duration.zero,
        startedAt = null,
        muted = false,
        speakerEnabled = true,
        cameraEnabled = false,
        localVideoVisible = false,
        remoteVideoVisible = false,
        localSpeaking = false,
        remoteSpeaking = false,
        incomingActionInFlight = false;

  final CallStage stage;
  final String statusText;
  final CallDisconnectReason disconnectReason;
  final CallPeerSnapshot? peer;
  final String? conversationId;
  final PendingIncomingCall? pendingIncoming;
  final Duration elapsed;
  final DateTime? startedAt;
  final bool muted;
  final bool speakerEnabled;
  final bool cameraEnabled;
  final bool localVideoVisible;
  final bool remoteVideoVisible;
  final bool localSpeaking;
  final bool remoteSpeaking;
  final bool incomingActionInFlight;

  bool get isIdle => stage == CallStage.idle;
  bool get isOutgoing => stage == CallStage.outgoing;
  bool get isIncoming => stage == CallStage.incoming;
  bool get isActive => stage == CallStage.active;
  bool get isReconnecting => stage == CallStage.reconnecting;
  bool get hasLiveCall => isOutgoing || isActive || isReconnecting;

  String get elapsedLabel {
    final totalSeconds = elapsed.inSeconds;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    final hours = totalSeconds ~/ 3600;
    if (hours > 0) {
      final hh = hours.toString().padLeft(2, '0');
      return '$hh:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  CallUiState copyWith({
    CallStage? stage,
    String? statusText,
    CallDisconnectReason? disconnectReason,
    CallPeerSnapshot? peer,
    String? conversationId,
    PendingIncomingCall? pendingIncoming,
    Duration? elapsed,
    DateTime? startedAt,
    bool? muted,
    bool? speakerEnabled,
    bool? cameraEnabled,
    bool? localVideoVisible,
    bool? remoteVideoVisible,
    bool? localSpeaking,
    bool? remoteSpeaking,
    bool? incomingActionInFlight,
    bool clearPeer = false,
    bool clearConversationId = false,
    bool clearPendingIncoming = false,
    bool clearStartedAt = false,
  }) {
    return CallUiState(
      stage: stage ?? this.stage,
      statusText: statusText ?? this.statusText,
      disconnectReason: disconnectReason ?? this.disconnectReason,
      peer: clearPeer ? null : (peer ?? this.peer),
      conversationId:
          clearConversationId ? null : (conversationId ?? this.conversationId),
      pendingIncoming: clearPendingIncoming
          ? null
          : (pendingIncoming ?? this.pendingIncoming),
      elapsed: elapsed ?? this.elapsed,
      startedAt: clearStartedAt ? null : (startedAt ?? this.startedAt),
      muted: muted ?? this.muted,
      speakerEnabled: speakerEnabled ?? this.speakerEnabled,
      cameraEnabled: cameraEnabled ?? this.cameraEnabled,
      localVideoVisible: localVideoVisible ?? this.localVideoVisible,
      remoteVideoVisible: remoteVideoVisible ?? this.remoteVideoVisible,
      localSpeaking: localSpeaking ?? this.localSpeaking,
      remoteSpeaking: remoteSpeaking ?? this.remoteSpeaking,
      incomingActionInFlight:
          incomingActionInFlight ?? this.incomingActionInFlight,
    );
  }
}
