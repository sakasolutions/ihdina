import 'package:flutter_test/flutter_test.dart';
import 'package:ihdina/services/tts_voice_selector.dart';

void main() {
  final voices = [
    {
      'name': 'Markus',
      'locale': 'de-DE',
      'identifier': 'com.apple.voice.compact.de-DE.Markus',
      'gender': 'male',
      'quality': 'default',
    },
    {
      'name': 'Martin',
      'locale': 'de-DE',
      'identifier': 'com.apple.ttsbundle.siri_male_de-DE_premium',
      'gender': 'male',
      'quality': 'enhanced',
      'network_required': '1',
    },
    {
      'name': 'Anna',
      'locale': 'de-DE',
      'identifier': 'com.apple.voice.compact.de-DE.Anna',
      'gender': 'female',
      'quality': 'enhanced',
    },
  ];

  test('iOS male quality prefers enhanced Martin over compact Markus', () {
    final martin = voices[1] as Map<String, String>;
    final markus = voices[0] as Map<String, String>;
    expect(
      TtsVoiceSelector.scoreIosMaleQuality(martin),
      greaterThan(TtsVoiceSelector.scoreIosMaleQuality(markus)),
    );

    final picked = TtsVoiceSelector.pickGermanVoice(
      voices,
      mode: TtsVoicePickMode.iosMaleQuality,
    );
    expect(picked?['name'], 'Martin');
  });

  test('Android prefers male neural over female', () {
    final androidVoices = [
      {
        'name': 'de-DE-Neural2-A',
        'locale': 'de-DE',
        'identifier': 'de-DE-Neural2-A',
        'gender': 'female',
      },
      {
        'name': 'de-DE-Neural2-D',
        'locale': 'de-DE',
        'identifier': 'de-DE-Neural2-D',
        'gender': 'male',
      },
    ];
    final picked = TtsVoiceSelector.pickGermanVoice(
      androidVoices,
      mode: TtsVoicePickMode.androidMale,
    );
    expect(picked?['name'], 'de-DE-Neural2-D');
  });
}
