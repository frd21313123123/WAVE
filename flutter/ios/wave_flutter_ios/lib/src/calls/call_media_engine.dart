import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../models/call_models.dart';

typedef CallMediaEngineFactory = CallMediaEngine Function();

abstract class CallMediaEngine extends ChangeNotifier {
  Stream<Map<String, dynamic>> get localIceCandidates;

  RTCVideoRenderer? get localRenderer;
  RTCVideoRenderer? get remoteRenderer;

  CallMediaConnectionState get connectionState;
  bool get remoteDescriptionReady;
  bool get muted;
  bool get speakerEnabled;
  bool get cameraEnabled;
  bool get localVideoVisible;
  bool get remoteVideoVisible;
  bool get localSpeaking;
  bool get remoteSpeaking;

  Future<void> initialize();

  Future<void> prepareOutgoing({required bool videoRequested});

  Future<void> prepareIncoming({required bool videoRequested});

  Future<Map<String, dynamic>> createOffer({bool iceRestart = false});

  Future<void> applyRemoteOffer(Map<String, dynamic> sdp);

  Future<Map<String, dynamic>> createAnswer();

  Future<void> applyRemoteAnswer(Map<String, dynamic> sdp);

  Future<void> addRemoteIceCandidate(Map<String, dynamic> candidate);

  Future<void> setMuted(bool value);

  Future<void> setSpeakerEnabled(bool value);

  Future<void> setCameraEnabled(bool value);

  Future<void> disposeCall();
}
