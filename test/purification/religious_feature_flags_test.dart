import 'package:flutter_test/flutter_test.dart';
import 'package:ihdina/config/religious_feature_flags.dart';

void main() {
  tearDown(() {
    ReligiousFeatureFlags.testOverride = null;
  });

  group('ReligiousFeatureFlags.religiousPurificationGuideEnabled', () {
    test('Release-Standard ist deaktiviert', () {
      expect(
        ReligiousFeatureFlags.kReligiousPurificationGuideReleaseEnabled,
        isFalse,
      );
    });

    test('Debug-Standard ist deaktiviert', () {
      expect(
        ReligiousFeatureFlags.kReligiousPurificationGuideDebugEnabled,
        isFalse,
      );
    });

    test('testOverride simuliert Freigabe unabhängig vom Build-Modus', () {
      ReligiousFeatureFlags.testOverride = false;
      expect(ReligiousFeatureFlags.religiousPurificationGuideEnabled, isFalse);

      ReligiousFeatureFlags.testOverride = true;
      expect(ReligiousFeatureFlags.religiousPurificationGuideEnabled, isTrue);
    });
  });
}
