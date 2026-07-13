import 'package:flutter/material.dart';

import '../purification_live_presentation.dart';
import 'purification_live_visual_painter.dart';
import 'purification_live_visual_placeholder.dart';

/// Visual-Bereich im Live-Guide — Platzhalter, später Bild/Illustration/Animation.
class PurificationLiveVisual extends StatelessWidget {
  const PurificationLiveVisual({
    super.key,
    required this.presentation,
  });

  final PurificationLivePresentation presentation;

  bool get _usesRasterAsset {
    return presentation.hasVisualAsset &&
        (presentation.visualType == PurificationVisualType.image ||
            presentation.visualType == PurificationVisualType.illustration);
  }

  @override
  Widget build(BuildContext context) {
    if (!presentation.showsVisualArea) {
      return const SizedBox.shrink();
    }

    if (_usesRasterAsset) {
      return Semantics(
        label: presentation.visualSemanticLabel,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: ColoredBox(
            color: const Color(0xFF0A1412),
            child: Image.asset(
              presentation.visualAsset!,
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return PurificationLiveVisualPlaceholder(
                  presentation: presentation,
                );
              },
            ),
          ),
        ),
      );
    }

    return PurificationLiveVisualPlaceholder(presentation: presentation);
  }
}

/// Berechnet die Visual-Höhe anhand des Content-Modells.
double purificationLiveVisualHeight({
  required PurificationLivePresentation presentation,
  required double maxHeight,
}) {
  if (!presentation.showsVisualArea) return 0;

  return switch (presentation.visualDisplay) {
    PurificationLiveVisualDisplay.full => (maxHeight * 0.34).clamp(88.0, 148.0),
    PurificationLiveVisualDisplay.compact =>
      (maxHeight * 0.2).clamp(52.0, 80.0),
    PurificationLiveVisualDisplay.minimal =>
      (maxHeight * 0.12).clamp(36.0, 52.0),
    PurificationLiveVisualDisplay.hidden => 0,
  };
}

/// Export für Tests — Painter-Zugriff.
PurificationLiveVisualCategory purificationLiveVisualCategory(
  PurificationLivePresentation presentation,
) {
  return presentation.visualCategory;
}

/// Export für Painter in Platzhalter.
Widget buildPurificationLiveVisualPainter({
  required PurificationLiveVisualCategory category,
}) {
  return CustomPaint(
    painter: PurificationLiveVisualPainter(category: category),
    child: const SizedBox.expand(),
  );
}
