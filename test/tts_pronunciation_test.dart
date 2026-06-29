import 'package:flutter_test/flutter_test.dart';
import 'package:ihdina/data/tts/tts_pronunciation_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TtsPronunciationRepository.instance.clearCache();
  });

  test('Al-Hajj wird als Al-Hadsch gesprochen', () async {
    final out = await TtsPronunciationRepository.instance.apply(
      'Sure Al-Hajj, Vers 41',
    );
    expect(out.toLowerCase(), contains('al-hadsch'));
    expect(out.toLowerCase(), isNot(contains('hajj')));
  });

  test('Hajj allein wird zu Hadsch', () async {
    final out = await TtsPronunciationRepository.instance.apply(
      'Die Pilgerfahrt (Hajj) ist eine Säule.',
    );
    expect(out, contains('Hadsch'));
  });
}
