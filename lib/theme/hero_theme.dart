import 'package:flutter/material.dart';

import '../prayer/prayer_type.dart';

/// Maps prayer phase / time-of-day to hero visuals (asset-based backgrounds).
enum HeroPhase {
  night,
  fajr,
  day,
  maghrib,
}

/// Dynamic hero theme: asset path and fallback color per phase.
class DynamicHeroTheme {
  DynamicHeroTheme._();

  static HeroPhase phaseFromPrayer(PrayerType? next) {
    if (next == null) return HeroPhase.day;
    switch (next) {
      case PrayerType.imsak:
      case PrayerType.fajr:
        return HeroPhase.fajr;
      case PrayerType.sunrise:
      case PrayerType.dhuhr:
      case PrayerType.asr:
        return HeroPhase.day;
      case PrayerType.maghrib:
        return HeroPhase.maghrib;
      case PrayerType.isha:
        return HeroPhase.night;
    }
  }

  /// Single background image used for all phases (assets/img/).
  /// Replace or select this one file to change the app background everywhere.
  static const String singleBackgroundAsset = 'assets/img/background.webp';

  /// Asset path for full-screen background image. One file for all phases.
  static String backgroundAsset(HeroPhase phase) {
    return singleBackgroundAsset;
  }

  /// Emerald-only overlay (top to bottom). Same for all phases – Tier 1 emerald branding.
  static List<Color> gradientOverlay(HeroPhase phase) {
    return [
      const Color(0xFF021F1A).withOpacity(0.95),
      const Color(0xFF0A2E28).withOpacity(0.78),
    ];
  }

  /// Fallback color when asset fails to load. Emerald only.
  static Color fallbackColor(HeroPhase phase) {
    return const Color(0xFF0A2E28);
  }
}
