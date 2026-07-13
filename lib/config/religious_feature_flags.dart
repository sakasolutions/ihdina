import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';

/// Lokale Schalter für religiöse Lernbegleiter — **kein** Remote Config.
///
/// Freigabe für Produktion: [kReligiousPurificationGuideReleaseEnabled] auf
/// `true` setzen (einzige Release-Konfigurationsstelle).
class ReligiousFeatureFlags {
  ReligiousFeatureFlags._();

  /// Debug-Standard: bis zur Freigabe `false` — Card und Einstieg ausblenden.
  static const bool kReligiousPurificationGuideDebugEnabled = false;

  /// Release-Standard: bis zur Produktfreigabe `false` lassen.
  static const bool kReligiousPurificationGuideReleaseEnabled = false;

  static bool? _testOverride;

  /// Nur in Tests: Flag-Verhalten simulieren ohne Build-Modus zu wechseln.
  @visibleForTesting
  static set testOverride(bool? value) => _testOverride = value;

  /// Interaktiver Wudu/Tayammum/Ghusl-Schrittguide.
  static bool get religiousPurificationGuideEnabled {
    if (_testOverride != null) return _testOverride!;
    if (kDebugMode) return kReligiousPurificationGuideDebugEnabled;
    return kReligiousPurificationGuideReleaseEnabled;
  }
}
