import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';

/// Zentraler Analytics-Kill-Switch — **kein** Remote Config (wie [ReligiousFeatureFlags]).
///
/// Bei Deaktivierung: keine neuen Events, kein Flush; Queue bleibt erhalten.
class AnalyticsConfig {
  AnalyticsConfig._();

  /// Debug: Analytics standardmäßig aktiv.
  static const bool kAnalyticsDebugEnabled = true;

  /// Release: standardmäßig deaktiviert bis Server-Migration + E2E-Smoke bestanden.
  /// Vor Store-Release auf `true` setzen (siehe docs/flutter_product_analytics.md).
  static const bool kAnalyticsReleaseEnabled = false;

  static bool? _testOverride;
  static bool _debugLogging = false;

  @visibleForTesting
  static set testOverride(bool? value) => _testOverride = value;

  @visibleForTesting
  static set debugLoggingOverride(bool? value) {
    _debugLogging = value ?? false;
  }

  static bool get enabled {
    if (_testOverride != null) return _testOverride!;
    if (kDebugMode) return kAnalyticsDebugEnabled;
    return kAnalyticsReleaseEnabled;
  }

  static bool get debugLogging =>
      _debugLogging || (kDebugMode && kAnalyticsDebugEnabled);
}
