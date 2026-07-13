import 'dart:io';

import 'package:meta/meta.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Einmalig geladene Geräte-/App-Metadaten für alle Events.
class AnalyticsDeviceContext {
  const AnalyticsDeviceContext({
    required this.platform,
    this.appVersion,
    this.buildNumber,
  });

  final String platform;
  final String? appVersion;
  final String? buildNumber;

  static AnalyticsDeviceContext? _cached;
  static PackageInfoLoader _packageInfoLoader = PackageInfo.fromPlatform;

  @visibleForTesting
  static void resetForTest() {
    _cached = null;
    _packageInfoLoader = PackageInfo.fromPlatform;
  }

  @visibleForTesting
  static void setPackageInfoLoaderForTest(PackageInfoLoader loader) {
    _packageInfoLoader = loader;
  }

  static Future<AnalyticsDeviceContext> load() async {
    if (_cached != null) return _cached!;
    final platform = Platform.isIOS
        ? 'ios'
        : Platform.isAndroid
            ? 'android'
            : 'other';
    String? appVersion;
    String? buildNumber;
    try {
      final info = await _packageInfoLoader();
      final version = info.version.trim();
      final build = info.buildNumber.trim();
      if (version.isNotEmpty) appVersion = version;
      if (build.isNotEmpty) buildNumber = build;
    } catch (_) {
      // Metadaten optional — Events bleiben gültig ohne Version.
    }
    _cached = AnalyticsDeviceContext(
      platform: platform,
      appVersion: appVersion,
      buildNumber: buildNumber,
    );
    return _cached!;
  }
}

typedef PackageInfoLoader = Future<PackageInfo> Function();
