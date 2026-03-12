import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

class WaveAvatar extends StatelessWidget {
  const WaveAvatar({
    super.key,
    required this.label,
    this.imageUrl,
    this.radius = 24,
  });

  final String label;
  final String? imageUrl;
  final double radius;

  static final LinkedHashMap<String, ImageProvider<Object>> _providerCache =
      LinkedHashMap<String, ImageProvider<Object>>();
  static const int _providerCacheLimit = 96;

  @override
  Widget build(BuildContext context) {
    final provider = providerFromValue(imageUrl);
    final scheme = Theme.of(context).colorScheme;
    final initials = _initials(label);

    return CircleAvatar(
      radius: radius,
      backgroundColor: scheme.primary.withValues(alpha: 0.12),
      foregroundImage: provider,
      child: provider == null
          ? Text(
              initials,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
            )
          : null,
    );
  }

  static ImageProvider<Object>? providerFromValue(String? imageUrl) {
    final value = imageUrl?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }

    final cached = _providerCache.remove(value);
    if (cached != null) {
      _providerCache[value] = cached;
      return cached;
    }

    ImageProvider<Object>? provider;
    if (value.startsWith('data:image')) {
      final bytes = _decodeDataUri(value);
      if (bytes != null) {
        provider = MemoryImage(bytes);
      }
    } else {
      provider = NetworkImage(value);
    }

    if (provider == null) {
      return null;
    }

    if (_providerCache.length >= _providerCacheLimit) {
      _providerCache.remove(_providerCache.keys.first);
    }
    _providerCache[value] = provider;
    return provider;
  }

  static Uint8List? _decodeDataUri(String value) {
    final comma = value.indexOf(',');
    if (comma < 0) {
      return null;
    }
    try {
      return base64Decode(value.substring(comma + 1));
    } catch (_) {
      return null;
    }
  }

  static String _initials(String value) {
    final pieces = value.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (pieces.isEmpty) {
      return 'W';
    }
    if (pieces.length == 1) {
      final chars = pieces.first.runes.toList();
      return String.fromCharCode(chars.first).toUpperCase();
    }
    final first = pieces.first.runes.toList();
    final last = pieces.last.runes.toList();
    return (String.fromCharCode(first.first) + String.fromCharCode(last.first))
        .toUpperCase();
  }
}
