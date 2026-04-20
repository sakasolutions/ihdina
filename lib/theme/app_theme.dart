import 'package:flutter/material.dart';

/// Emerald-only Premium-Farbpalette – Tier 1 (Logo-basiert).
class AppColors {
  AppColors._();

  /// Logo-Emerald: heller Akzent (oben).
  static const Color emeraldLight = Color(0xFF1E6B52);
  /// Logo-Emerald: mittlerer Ton.
  static const Color emeraldMedium = Color(0xFF13382D);
  /// Logo-Emerald: tiefer Schatten.
  static const Color emeraldDark = Color(0xFF081A15);

  static const Color sandBg = Color(0xFF0A2E28);
  static const Color sandLight = Color(0xFF0D3D35);
  static const Color sandDark = Color(0xFF064E3B);
  static const Color accent = Color(0xFF059669);
  static const Color accentLight = Color(0xFF10B981);
  static const Color gold = Color(0xFF059669);
  static const Color goldLight = Color(0xFF34D399);

  /// Champagner / Antik-Gold (Metall-Oblicht, kein reines Gelb) – Hero-Ring, KI-CTA.
  static const Color premiumGoldHighlight = Color(0xFFEFE8D4);
  static const Color premiumGoldMid = Color(0xFFC4A860);
  static const Color premiumGoldDeep = Color(0xFF8F7D4E);
  static const Color premiumGoldRim = Color(0xFFD8C896);
  static const Color textPrimary = Color(0xFFECFDF5);
  static const Color textSecondary = Color(0xFFA7F3D0);
  static const Color cardBg = Color(0xFF0D3D35);
  static const Color chipBg = Color(0xFF0F4D44);
  static const Color cardBorder = Color(0xFF147A6A);

  /// Logo-Gradient (topLeft → bottomRight). Stops keep bright emerald prominent top-left.
  static const LinearGradient mainGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.4, 1.0],
    colors: [
      Color(0xFF1E6B52), // Bright Emerald
      Color(0xFF13382D), // Medium Green
      Color(0xFF081A15), // Deep Dark Green
    ],
  );

  /// Haupt-Hintergrundverlauf (z. B. für Scaffold/Container).
  /// Zurücksetzen: stattdessen decoration: BoxDecoration(color: AppColors.sandBg)
  /// oder decoration: AppGradients.subtleBackground verwenden.
  static final LinearGradient mainBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      sandBg,
      sandBg.withOpacity(0.98),
      sandLight.withOpacity(0.3),
    ],
  );
}

/// Emerald-Gradient für Hintergründe
class AppGradients {
  AppGradients._();

  static BoxDecoration get subtleBackground => BoxDecoration(
        color: AppColors.sandBg,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.sandBg,
            AppColors.sandBg.withOpacity(0.98),
            AppColors.sandLight.withOpacity(0.3),
          ],
        ),
      );

  static BoxDecoration get subtleRadial => BoxDecoration(
        color: AppColors.sandBg,
        gradient: RadialGradient(
          center: Alignment.topRight,
          radius: 1.2,
          colors: [
            AppColors.goldLight.withOpacity(0.08),
            AppColors.sandBg,
          ],
        ),
      );
}
