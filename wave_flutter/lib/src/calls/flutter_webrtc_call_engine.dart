import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../models/call_models.dart';
import 'call_media_engine.dart';

class FlutterWebRtcCallEngine extends CallMediaEngine {
  FlutterWebRtcCallEngine({
    Map<String, dynamic>? rtcConfiguration,
  }) : _rtcConfiguration = rtcConfiguration ??
            const <String, dynamic>{
              'iceServers': <Map<String, dynamic>>[
                <String, dynamic>{
                  'urls': <String>['stun:stun.l.google.com:19302'],
                },
              ],
            };

  final Map<String, dynamic> _rtcConfiguration;
  final StreamController<Map<String, dynamic>> _localIceController =
      StreamController<Map<String, dynamic>>.broadcast();
  final List<Map<String, dynamic>> _pendingRemoteIceCandidates =
      <Map<String, dynamic>>[];

  RTCPeerConnection? _peerConnection;
  RTCVideoRenderer? _localRenderer;
  RTCVideoRenderer? _remoteRenderer;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  CallMediaConnectionState _connectionState = CallMediaConnectionState.idle;
  bool _remoteDescriptionReady = false;
  bool _muted = false;
  bool _speakerEnabled = true;
  bool _cameraEnabled = false;
  bool _localVideoVisible = false;
  bool _remoteVideoVisible = false;
  bool _localSpeaking = false;
  bool _remoteSpeaking = false;
  bool _initialized = false;
  bool _disposed = false;

  @override
  Stream<Map<String, dynamic>> get localIceCandidates => _localIceController.stream;

  @override
  RTCVideoRenderer? get localRenderer => _localRenderer;

  @override
  RTCVideoRenderer? get remoteRenderer => _remoteRenderer;

  @override
  CallMediaConnectionState get connectionState => _connectionState;

  @override
  bool get remoteDescriptionReady => _remoteDescriptionReady;

  @override
  bool get muted => _muted;

  @override
  bool get speakerEnabled => _speakerEnabled;

  @override
  bool get cameraEnabled => _cameraEnabled;

  @override
  bool get localVideoVisible => _localVideoVisible;

  @override
  bool get remoteVideoVisible => _remoteVideoVisible;

  @override
  bool get localSpeaking => _localSpeaking;

  @override
  bool get remoteSpeaking => _remoteSpeaking;

  @override
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    final localRenderer = RTCVideoRenderer();
    final remoteRenderer = RTCVideoRenderer();
    await localRenderer.initialize();
    await remoteRenderer.initialize();

    _localRenderer = localRenderer;
    _remoteRenderer = remoteRenderer;
    _initialized = true;
  }

  @override
  Future<void> prepareOutgoing({required bool videoRequested}) async {
    await _ensureReady(videoRequested: videoRequested);
  }

  @override
  Future<void> prepareIncoming({required bool videoRequested}) async {
    await _ensureReady(videoRequested: videoRequested);
  }

  @override
  Future<Map<String, dynamic>> createOffer({bool iceRestart = false}) async {
    final peerConnection = await _requirePeerConnection();
    final offer = await peerConnection.createOffer(
      iceRestart ? const <String, dynamic>{'iceRestart': true} : const <String, dynamic>{},
    );
    await peerConnection.setLocalDescription(offer);
    _setConnectionState(CallMediaConnectionState.connecting);
    return _sessionDescriptionToMap(offer);
  }

  @override
  Future<void> applyRemoteOffer(Map<String, dynamic> sdp) async {
    final peerConnection = await _requirePeerConnection();
    final description = _sessionDescriptionFromMap(sdp, fallbackType: 'offer');
    await peerConnection.setRemoteDescription(description);
    _remoteDescriptionReady = true;
    await _flushPendingRemoteIceCandidates();
    _notifyStateChanged();
  }

  @override
  Future<Map<String, dynamic>> createAnswer() async {
    final peerConnection = await _requirePeerConnection();
    final answer = await peerConnection.createAnswer();
    await peerConnection.setLocalDescription(answer);
    return _sessionDescriptionToMap(answer);
  }

  @override
  Future<void> applyRemoteAnswer(Map<String, dynamic> sdp) async {
    final peerConnection = await _requirePeerConnection();
    final description = _sessionDescriptionFromMap(sdp, fallbackType: 'answer');
    await peerConnection.setRemoteDescription(description);
    _remoteDescriptionReady = true;
    await _flushPendingRemoteIceCandidates();
    _notifyStateChanged();
  }

  @override
  Future<void> addRemoteIceCandidate(Map<String, dynamic> candidate) async {
    final peerConnection = _peerConnection;
    if (peerConnection == null || !_remoteDescriptionReady) {
      _pendingRemoteIceCandidates.add(Map<String, dynamic>.from(candidate));
      return;
    }

    try {
      await peerConnection.addCandidate(_iceCandidateFromMap(candidate));
    } catch (_) {
      _pendingRemoteIceCandidates.add(Map<String, dynamic>.from(candidate));
    }
  }

  @override
  Future<void> setMuted(bool value) async {
    final localStream = _localStream;
    if (localStream != null) {
      for (final track in localStream.getAudioTracks()) {
        track.enabled = !value;
      }
    }

    _muted = value;
    _localSpeaking = false;
    _notifyStateChanged();
  }

  @override
  Future<void> setSpeakerEnabled(bool value) async {
    await Helper.setSpeakerphoneOn(value);
    _speakerEnabled = value;
    _notifyStateChanged();
  }

  @override
  Future<void> setCameraEnabled(bool value) async {
    final peerConnection = await _requirePeerConnection();
    final localStream = await _requireLocalStream();

    if (value == _cameraEnabled) {
      return;
    }

    if (value) {
      final captureStream = await navigator.mediaDevices.getUserMedia(
        <String, dynamic>{
          'audio': false,
          'video': _videoConstraints(),
        },
      );
      final newTrack = captureStream.getVideoTracks().isEmpty
          ? null
          : captureStream.getVideoTracks().first;
      if (newTrack == null) {
        return;
      }

      final oldTrack = localStream.getVideoTracks().isEmpty
          ? null
          : localStream.getVideoTracks().first;
      if (oldTrack != null) {
        await localStream.removeTrack(oldTrack);
        await oldTrack.stop();
      }

      await localStream.addTrack(newTrack);
      await _attachOrReplaceVideoSender(
        peerConnection: peerConnection,
        track: newTrack,
        stream: localStream,
      );
      _bindLocalVideoTrack(newTrack);
      _cameraEnabled = true;
      _localVideoVisible = true;
      _localRenderer?.srcObject = localStream;
      _notifyStateChanged();
      return;
    }

    final senders = await peerConnection.getSenders();
    for (final sender in senders) {
      final senderTrack = sender.track;
      if (senderTrack?.kind == 'video') {
        await peerConnection.removeTrack(sender);
      }
    }

    for (final track in List<MediaStreamTrack>.from(localStream.getVideoTracks())) {
      await localStream.removeTrack(track);
      await track.stop();
    }

    _cameraEnabled = false;
    _localVideoVisible = false;
    _localRenderer?.srcObject = null;
    _notifyStateChanged();
  }

  @override
  Future<void> disposeCall() async {
    _connectionState = CallMediaConnectionState.closed;
    _remoteDescriptionReady = false;
    _pendingRemoteIceCandidates.clear();
    _localSpeaking = false;
    _remoteSpeaking = false;
    _remoteVideoVisible = false;
    _localVideoVisible = false;
    _cameraEnabled = false;
    _muted = false;

    final peerConnection = _peerConnection;
    _peerConnection = null;
    if (peerConnection != null) {
      await peerConnection.close();
      await peerConnection.dispose();
    }

    final remoteRenderer = _remoteRenderer;
    if (remoteRenderer != null) {
      remoteRenderer.srcObject = null;
    }
    final localRenderer = _localRenderer;
    if (localRenderer != null) {
      localRenderer.srcObject = null;
    }

    await _disposeStream(_remoteStream);
    _remoteStream = null;
    await _disposeStream(_localStream);
    _localStream = null;
    _notifyStateChanged();
  }

  @override
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    unawaited(_localIceController.close());
    final localRenderer = _localRenderer;
    final remoteRenderer = _remoteRenderer;
    _localRenderer = null;
    _remoteRenderer = null;
    if (localRenderer != null) {
      unawaited(localRenderer.dispose());
    }
    if (remoteRenderer != null) {
      unawaited(remoteRenderer.dispose());
    }
    super.dispose();
  }

  Future<void> _ensureReady({required bool videoRequested}) async {
    await initialize();
    final localStream = await _createLocalStream(videoRequested: videoRequested);
    _localStream = localStream;
    _cameraEnabled = localStream.getVideoTracks().isNotEmpty;
    _localVideoVisible = _cameraEnabled;
    _muted = false;
    if (_cameraEnabled) {
      _localRenderer?.srcObject = localStream;
      _bindLocalVideoTrack(localStream.getVideoTracks().first);
    } else {
      _localRenderer?.srcObject = null;
    }

    final peerConnection = await _createPeerConnection();
    for (final track in localStream.getTracks()) {
      await peerConnection.addTrack(track, localStream);
    }

    await Helper.setSpeakerphoneOn(_speakerEnabled);
    _setConnectionState(CallMediaConnectionState.connecting);
    _notifyStateChanged();
  }

  Future<RTCPeerConnection> _createPeerConnection() async {
    if (_peerConnection != null) {
      return _peerConnection!;
    }

    final peerConnection = await createPeerConnection(
      _rtcConfiguration,
      const <String, dynamic>{},
    );

    peerConnection.onIceCandidate = (RTCIceCandidate candidate) {
      final payload = candidate.toMap();
      if (payload is Map) {
        _localIceController.add(Map<String, dynamic>.from(payload));
      }
    };
    peerConnection.onConnectionState = (RTCPeerConnectionState state) {
      _setConnectionState(_mapPeerConnectionState(state));
    };
    peerConnection.onIceConnectionState = (RTCIceConnectionState state) {
      switch (state) {
        case RTCIceConnectionState.RTCIceConnectionStateConnected:
        case RTCIceConnectionState.RTCIceConnectionStateCompleted:
          _setConnectionState(CallMediaConnectionState.connected);
          return;
        case RTCIceConnectionState.RTCIceConnectionStateDisconnected:
          _setConnectionState(CallMediaConnectionState.disconnected);
          return;
        case RTCIceConnectionState.RTCIceConnectionStateFailed:
          _setConnectionState(CallMediaConnectionState.failed);
          return;
        case RTCIceConnectionState.RTCIceConnectionStateClosed:
          _setConnectionState(CallMediaConnectionState.closed);
          return;
        default:
          return;
      }
    };
    peerConnection.onTrack = _handleRemoteTrack;

    _peerConnection = peerConnection;
    return peerConnection;
  }

  Future<RTCPeerConnection> _requirePeerConnection() async {
    final peerConnection = _peerConnection;
    if (peerConnection != null) {
      return peerConnection;
    }
    return _createPeerConnection();
  }

  Future<MediaStream> _requireLocalStream() async {
    final localStream = _localStream;
    if (localStream != null) {
      return localStream;
    }
    final created = await _createLocalStream(videoRequested: false);
    _localStream = created;
    return created;
  }

  Future<MediaStream> _createLocalStream({required bool videoRequested}) async {
    await _disposeStream(_localStream);
    final stream = await navigator.mediaDevices.getUserMedia(
      <String, dynamic>{
        'audio': _audioConstraints(),
        'video': videoRequested ? _videoConstraints() : false,
      },
    );

    for (final track in stream.getAudioTracks()) {
      track.enabled = true;
      _bindLocalAudioTrack(track);
    }
    for (final track in stream.getVideoTracks()) {
      _bindLocalVideoTrack(track);
    }

    return stream;
  }

  void _handleRemoteTrack(RTCTrackEvent event) {
    if (event.streams.isNotEmpty) {
      _remoteStream = event.streams.first;
      _remoteRenderer?.srcObject = _remoteStream;
    }

    final track = event.track;
    if (track.kind == 'video') {
      _remoteVideoVisible = true;
      _bindRemoteVideoTrack(track);
    } else if (track.kind == 'audio') {
      _bindRemoteAudioTrack(track);
    }

    _notifyStateChanged();
  }

  void _bindLocalAudioTrack(MediaStreamTrack track) {
    track.onMute = () {
      _localSpeaking = false;
      _notifyStateChanged();
    };
    track.onUnMute = () => _notifyStateChanged();
    track.onEnded = () {
      _localSpeaking = false;
      _notifyStateChanged();
    };
  }

  void _bindRemoteAudioTrack(MediaStreamTrack track) {
    track.onMute = () {
      _remoteSpeaking = false;
      _notifyStateChanged();
    };
    track.onUnMute = () => _notifyStateChanged();
    track.onEnded = () {
      _remoteSpeaking = false;
      _notifyStateChanged();
    };
  }

  void _bindLocalVideoTrack(MediaStreamTrack track) {
    track.onMute = () {
      _localVideoVisible = false;
      _notifyStateChanged();
    };
    track.onUnMute = () {
      _localVideoVisible = true;
      _notifyStateChanged();
    };
    track.onEnded = () {
      _cameraEnabled = false;
      _localVideoVisible = false;
      _localRenderer?.srcObject = null;
      _notifyStateChanged();
    };
  }

  void _bindRemoteVideoTrack(MediaStreamTrack track) {
    track.onMute = () {
      _remoteVideoVisible = false;
      _notifyStateChanged();
    };
    track.onUnMute = () {
      _remoteVideoVisible = true;
      _notifyStateChanged();
    };
    track.onEnded = () {
      _remoteVideoVisible = false;
      _notifyStateChanged();
    };
  }

  Future<void> _attachOrReplaceVideoSender({
    required RTCPeerConnection peerConnection,
    required MediaStreamTrack track,
    required MediaStream stream,
  }) async {
    final senders = await peerConnection.getSenders();
    RTCRtpSender? videoSender;
    for (final sender in senders) {
      if (sender.track?.kind == 'video') {
        videoSender = sender;
        break;
      }
    }

    if (videoSender != null) {
      await videoSender.replaceTrack(track);
      return;
    }

    await peerConnection.addTrack(track, stream);
  }

  Future<void> _flushPendingRemoteIceCandidates() async {
    if (!_remoteDescriptionReady || _pendingRemoteIceCandidates.isEmpty) {
      return;
    }

    final peerConnection = _peerConnection;
    if (peerConnection == null) {
      return;
    }

    final pending = List<Map<String, dynamic>>.from(_pendingRemoteIceCandidates);
    _pendingRemoteIceCandidates.clear();
    for (final candidate in pending) {
      try {
        await peerConnection.addCandidate(_iceCandidateFromMap(candidate));
      } catch (_) {
        _pendingRemoteIceCandidates.add(candidate);
      }
    }
  }

  RTCSessionDescription _sessionDescriptionFromMap(
    Map<String, dynamic> data, {
    required String fallbackType,
  }) {
    return RTCSessionDescription(
      data['sdp']?.toString(),
      data['type']?.toString() ?? fallbackType,
    );
  }

  Map<String, dynamic> _sessionDescriptionToMap(RTCSessionDescription description) {
    return <String, dynamic>{
      'sdp': description.sdp,
      'type': description.type,
    };
  }

  RTCIceCandidate _iceCandidateFromMap(Map<String, dynamic> data) {
    final sdpMLineIndex = data['sdpMLineIndex'];
    final parsedMLine = sdpMLineIndex is int
        ? sdpMLineIndex
        : int.tryParse(sdpMLineIndex?.toString() ?? '');
    return RTCIceCandidate(
      data['candidate']?.toString(),
      data['sdpMid']?.toString(),
      parsedMLine,
    );
  }

  Map<String, dynamic> _audioConstraints() {
    return <String, dynamic>{
      'echoCancellation': true,
      'noiseSuppression': true,
      'autoGainControl': true,
    };
  }

  Map<String, dynamic> _videoConstraints() {
    return <String, dynamic>{
      'facingMode': 'user',
      'width': <String, dynamic>{'ideal': 1280},
      'height': <String, dynamic>{'ideal': 720},
      'frameRate': <String, dynamic>{'ideal': 24},
    };
  }

  CallMediaConnectionState _mapPeerConnectionState(RTCPeerConnectionState state) {
    switch (state) {
      case RTCPeerConnectionState.RTCPeerConnectionStateNew:
      case RTCPeerConnectionState.RTCPeerConnectionStateConnecting:
        return CallMediaConnectionState.connecting;
      case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
        return CallMediaConnectionState.connected;
      case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
        return CallMediaConnectionState.disconnected;
      case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
        return CallMediaConnectionState.failed;
      case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
        return CallMediaConnectionState.closed;
    }
  }

  Future<void> _disposeStream(MediaStream? stream) async {
    if (stream == null) {
      return;
    }

    for (final track in List<MediaStreamTrack>.from(stream.getTracks())) {
      await track.stop();
    }
    await stream.dispose();
  }

  void _setConnectionState(CallMediaConnectionState state) {
    if (_connectionState == state) {
      return;
    }
    _connectionState = state;
    _notifyStateChanged();
  }

  void _notifyStateChanged() {
    if (_disposed) {
      return;
    }
    notifyListeners();
  }
}
