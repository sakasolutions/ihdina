import 'package:flutter/material.dart';

/// Design-Tokens: Nur Emerald – Tier-1-Branding für Logo und UI.
class AppTokens {
  AppTokens._();

  // ——— Colors (Emerald only) ———
  static const Color bg = Color(0xFF0A2E28);
  static const Color surface = Color(0xFF0D3D35);
  static const Color surfaceVariant = Color(0xFF0F4D44);
  static const Color primary = Color(0xFF059669);
  static const Color primaryLight = Color(0xFF10B981);
  static const Color accent = Color(0xFF059669);
  static const Color accentLight = Color(0xFF34D399);
  static const Color divider = Color(0xFF147A6A);
  static const Color textPrimary = Color(0xFFECFDF5);
  static const Color textSecondary = Color(0xFFA7F3D0);
  static const Color textMuted = Color(0xFF6EE7B7);

  // ——— Radii ———
  static const double radiusMd = 16;
  static const double radiusLg = 24;
  static const double radiusChip = 14;
  static const double radiusPill = 20;

  // ——— Shadows (weich, feine Borders) ———
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: divider.withOpacity(0.8),
          blurRadius: 1,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get heroShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.07),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get chipGlow => [
        BoxShadow(
          color: primary.withOpacity(0.15),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];
}
