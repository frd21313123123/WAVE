import 'package:flutter/material.dart';

import 'app_update_service.dart';

Future<bool?> showAppUpdateDialog(
  BuildContext context, {
  required AppUpdateInfo update,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      final theme = Theme.of(context);
      final notes = _trimNotes(update.releaseNotes);

      return AlertDialog(
        title: const Text('Update available'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${update.releaseName}\n${update.currentVersion} -> ${update.latestVersion}',
                style: theme.textTheme.titleMedium,
              ),
              if (update.assetName != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Asset: ${update.assetName}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (notes != null) ...[
                const SizedBox(height: 16),
                Text(
                  notes,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(update.actionLabel),
          ),
        ],
      );
    },
  );
}

String? _trimNotes(String notes) {
  final normalized = notes.trim();
  if (normalized.isEmpty) {
    return null;
  }

  final lines = normalized
      .split('\n')
      .map((line) => line.trimRight())
      .where((line) => line.isNotEmpty)
      .take(8)
      .toList(growable: false);

  if (lines.isEmpty) {
    return null;
  }

  final suffix =
      normalized.split('\n').where((line) => line.trim().isNotEmpty).length >
              lines.length
          ? '\n...'
          : '';
  return '${lines.join('\n')}$suffix';
}
