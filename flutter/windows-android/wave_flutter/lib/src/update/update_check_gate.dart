import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_update_install_flow.dart';
import 'update_controller.dart';
import 'update_prompt.dart';

class UpdateCheckGate extends StatefulWidget {
  const UpdateCheckGate({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<UpdateCheckGate> createState() => _UpdateCheckGateState();
}

class _UpdateCheckGateState extends State<UpdateCheckGate> {
  bool _startupCheckTriggered = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_startupCheckTriggered) {
      return;
    }
    _startupCheckTriggered = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_runStartupCheck());
    });
  }

  Future<void> _runStartupCheck() async {
    final controller = context.read<UpdateController>();
    final result = await controller.checkForUpdates();
    final update = result.update;
    if (!mounted || update == null || !update.canDetermineIfNewer) {
      return;
    }

    final shouldOpen = await showAppUpdateDialog(context, update: update);
    if (shouldOpen != true || !mounted) {
      return;
    }

    await runManagedAppUpdateInstallFlow(
      context,
      controller: controller,
      update: update,
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
