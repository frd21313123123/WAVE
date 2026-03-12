// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:wave_flutter/src/desktop/desktop_shell_settings_store.dart';

void main() {
  test('desktop url sanitizer normalizes input', () {
    expect(
      sanitizeDesktopBaseUrl('localhost:3000/'),
      'http://localhost:3000',
    );
    expect(
      sanitizeDesktopBaseUrl('https://wave.example.com/'),
      'https://wave.example.com',
    );
  });

  test('desktop settings json round-trip keeps base url', () {
    const settings = DesktopShellSettings(
      baseUrl: 'http://127.0.0.1:3000',
    );

    expect(
      DesktopShellSettings.fromJson(settings.toJson()).baseUrl,
      'http://127.0.0.1:3000',
    );
  });
}
