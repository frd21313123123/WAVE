import 'package:flutter/material.dart';

class WaveBrandLogo extends StatelessWidget {
  const WaveBrandLogo({
    super.key,
    this.size,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.semanticLabel,
    this.excludeFromSemantics = false,
  });

  static const String assetPath = 'assets/branding/wave_logo.png';

  final double? size;
  final double? width;
  final double? height;
  final BoxFit fit;
  final String? semanticLabel;
  final bool excludeFromSemantics;

  @override
  Widget build(BuildContext context) {
    final resolvedWidth = width ?? size;
    final resolvedHeight = height ?? size;

    return Image.asset(
      assetPath,
      width: resolvedWidth,
      height: resolvedHeight,
      fit: fit,
      filterQuality: FilterQuality.high,
      semanticLabel: excludeFromSemantics ? null : semanticLabel,
      excludeFromSemantics: excludeFromSemantics,
    );
  }
}
