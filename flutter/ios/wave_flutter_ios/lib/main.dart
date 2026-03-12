import 'dart:io' show Platform;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import 'src/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isIOS) {
    await AudioPlayer.global.setAudioContext(
      AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playAndRecord,
          options: const {
            AVAudioSessionOptions.allowAirPlay,
            AVAudioSessionOptions.allowBluetooth,
            AVAudioSessionOptions.allowBluetoothA2DP,
            AVAudioSessionOptions.defaultToSpeaker,
          },
        ),
      ),
    );
  }
  final bootstrap = await AppBootstrap.initialize();
  runApp(WaveApp(bootstrap: bootstrap));
}
