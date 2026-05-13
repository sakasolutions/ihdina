import 'package:flutter_test/flutter_test.dart';
import 'package:ihdina/utils/search_normalize.dart';

void main() {
  group('SearchNormalize.westLooseContains', () {
    test('al fatiha matches Al-Fatihah', () {
      expect(
        SearchNormalize.westLooseContains('Al-Fatihah', 'al fatiha', minQueryLen: 3),
        isTrue,
      );
    });

    test('ali imran matches Ali apostrophe Imran', () {
      expect(
        SearchNormalize.westLooseContains("Ali 'Imran", 'ali imran', minQueryLen: 3),
        isTrue,
      );
    });

    test('short query below min len', () {
      expect(
        SearchNormalize.westLooseContains('Al-Fatihah', 'al', minQueryLen: 3),
        isFalse,
      );
    });
  });
}
