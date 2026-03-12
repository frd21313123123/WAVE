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
        title: const Text('Доступно обновление'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                update.releaseName,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                update.canDetermineIfNewer
                    ? '${update.currentVersion} -> ${update.latestVersion}'
                    : 'Доступна последняя сборка из GitHub Releases.',
                style: theme.textTheme.bodyMedium,
              ),
              if (update.publishedAt != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Опубликовано: ${_formatPublishedAt(update.publishedAt!)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (update.assetName != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Файл: ${update.assetName}',
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
            child: const Text('Позже'),
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

String _formatPublishedAt(DateTime value) {
  final local = value.toLocal();
  final year = local.year.toString().padLeft(4, '0');
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day.$month.$year $hour:$minute';
}
