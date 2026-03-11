import 'package:flutter/material.dart';

import 'src/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bootstrap = await AppBootstrap.initialize();
  runApp(WaveApp(bootstrap: bootstrap));
}
