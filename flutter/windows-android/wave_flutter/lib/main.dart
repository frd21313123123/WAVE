import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/config/app_config.dart';
import 'src/desktop/windows_shell_app.dart';

const String _windowsClientMode = String.fromEnvironment(
  'WAVE_WINDOWS_CLIENT_MODE',
  defaultValue: 'native',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb &&
      defaultTargetPlatform == TargetPlatform.windows &&
      _windowsClientMode.toLowerCase() == 'shell') {
    await runWaveWindowsShellApp();
    return;
  }

  final appConfig = await AppConfig.load();
  final bootstrap = await AppBootstrap.initialize(appConfig: appConfig);
  runApp(WaveApp(bootstrap: bootstrap));
}
