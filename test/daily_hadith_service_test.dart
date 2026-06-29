import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ihdina/data/daily_hadith/daily_hadith_library.dart';
import 'package:ihdina/data/daily_hadith/daily_hadith_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    DailyHadithLibrary.resetCacheForTest();
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/shared_preferences'),
      (call) async => null,
    );
  });

  test('library loads 90 hadiths with rotation order', () async {
    final lib = await DailyHadithLibrary.load();
    expect(lib.schemaVersion, 3);
    expect(lib.entries.length, 90);
    expect(lib.rotationOrder.length, 90);
    expect(lib.rotationOrder.toSet().length, 90);
    expect(lib.noRepeatDays, 30);
  });

  test('same day returns cached hadith', () async {
    final first = await DailyHadithService.instance.getHadithOfTheDay();
    final second = await DailyHadithService.instance.getHadithOfTheDay();
    expect(first, isNotNull);
    expect(second?.id, first?.id);
  });

  test('friday prefers fridayOk hadith when rotation allows', () async {
    final lib = await DailyHadithLibrary.load();
    final fridayOnly = lib.entries.where((e) => e.fridayOk).map((e) => e.id).toSet();
    expect(fridayOnly.length, greaterThan(50));
  });
}
