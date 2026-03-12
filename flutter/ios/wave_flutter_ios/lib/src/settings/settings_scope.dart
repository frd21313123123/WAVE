import 'package:flutter/widgets.dart';

import 'settings_controller.dart';

class SettingsScope extends InheritedNotifier<SettingsController> {
  const SettingsScope({
    super.key,
    required SettingsController controller,
    required super.child,
  }) : super(notifier: controller);

  static SettingsController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<SettingsScope>();
    assert(scope != null, 'SettingsScope is missing in the widget tree.');
    return scope!.notifier!;
  }

  static SettingsController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<SettingsScope>()
        ?.notifier;
  }
}
