import 'package:flutter/material.dart';

import '../purification_live_presentation.dart';
import '../../../theme/app_theme.dart';
import 'purification_live_visual_painter.dart';

/// Ruhige Platzhalterfläche — geometrische Kontur, kein Entwickler-Look.
class PurificationLiveVisualPlaceholder extends StatelessWidget {
  const PurificationLiveVisualPlaceholder({
    super.key,
    required this.presentation,
  });

  final PurificationLivePresentation presentation;

  @override
  Widget build(BuildContext context) {
    final semanticLabel = presentation.visualSemanticLabel;

    return Semantics(
      label: semanticLabel,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x1AFFFFFF)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: CustomPaint(
            painter: PurificationLiveVisualPainter(
              category: presentation.visualCategory,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

/// Kartenhintergrund wie Dua-Dialog — Emerald-Unterton.
Color purificationLiveCardColor() {
  return Color.lerp(
    AppColors.emeraldDark,
    const Color(0xFF050505),
    0.82,
  )!;
}
