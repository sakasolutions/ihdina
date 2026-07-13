import 'package:flutter/foundation.dart';

/// Wählt eine deutsche System-Stimme aus [getVoices].
///
/// **Android:** männliche Google-/Neural-Stimmen.
/// **iOS:** männlich, aber **Enhanced/Premium** — keine billige Compact-Stimme
/// (z. B. Markus ohne Download klingt oft „fremd“).
enum TtsVoicePickMode {
  androidMale,
  iosMaleQuality,
}

class TtsVoiceSelector {
  TtsVoiceSelector._();

  static const _preferredLocales = <String>['de-de', 'de-at', 'de-ch', 'de'];

  static final _excludeLocale = RegExp(
    r'\bnl-|\bnl_|nederland|dutch|vlaams|flemish',
    caseSensitive: false,
  );

  static final _maleHints = RegExp(
    r'male|mann|\-deb\-|\-dem\-|\-dfc\-|\-dfm\-|wavenet-d\b|neural2-d\b|siri_.*male',
    caseSensitive: false,
  );

  static final _femaleHints = RegExp(
    r'female|frau|\-dea\-|\-nhf\-|wavenet-[acf]\b|neural2-[acf]\b|\banna\b|\bvicki\b|\bhelena\b|\bpetra\b',
    caseSensitive: false,
  );

  static final _iosMaleNameHints = RegExp(
    r'\bmartin\b|\bmarkus\b|\botmar\b|\byannick\b|\bfelix\b|\bjan\b',
    caseSensitive: false,
  );

  static final _compactHint = RegExp(r'\bcompact\b', caseSensitive: false);
  static final _markusHint = RegExp(r'\bmarkus\b', caseSensitive: false);

  static Map<String, String>? pickGermanVoice(
    dynamic rawVoices, {
    required TtsVoicePickMode mode,
  }) {
    if (rawVoices is! List) return null;

    final candidates = <Map<String, String>>[];
    for (final item in rawVoices) {
      if (item is! Map) continue;
      final voice = <String, String>{};
      item.forEach((key, value) {
        voice[key.toString()] = value?.toString() ?? '';
      });
      final locale = voice['locale'] ?? voice['language'] ?? '';
      if (!_isGermanLocale(locale)) continue;
      final blob = '${voice['name']} ${voice['identifier']} ${voice['locale']}'
          .toLowerCase();
      if (_excludeLocale.hasMatch(blob)) continue;
      candidates.add(voice);
    }

    if (candidates.isEmpty) return null;

    int score(Map<String, String> v) {
      switch (mode) {
        case TtsVoicePickMode.androidMale:
          return _scoreAndroidMale(v);
        case TtsVoicePickMode.iosMaleQuality:
          return _scoreIosMaleQuality(v);
      }
    }

    candidates.sort((a, b) => score(b).compareTo(score(a)));

    final best = candidates.first;
    if (score(best) < 1) return null;

    if (kDebugMode) {
      debugPrint(
        '[TtsVoiceSelector] ${mode.name} → ${best['name']} (${best['locale']}) '
        'quality=${best['quality'] ?? '-'} id=${best['identifier'] ?? '-'}',
      );
    }

    return _voiceMapForSetVoice(best);
  }

  /// Rückwärtskompatibel.
  static Map<String, String>? pickGermanMaleVoice(dynamic rawVoices) =>
      pickGermanVoice(rawVoices, mode: TtsVoicePickMode.androidMale);

  static Map<String, String> _voiceMapForSetVoice(Map<String, String> voice) {
    final id = voice['identifier']?.trim() ?? '';
    if (id.isNotEmpty) {
      return {
        'identifier': id,
        'name': voice['name'] ?? '',
        'locale': voice['locale'] ?? '',
      };
    }
    return {
      'name': voice['name'] ?? '',
      'locale': voice['locale'] ?? '',
    };
  }

  static bool _isGermanLocale(String locale) {
    final l = locale.toLowerCase().replaceAll('_', '-');
    return _preferredLocales.any((p) => l.startsWith(p));
  }

  static bool _isEnhancedOrPremium(Map<String, String> voice) {
    final q = (voice['quality'] ?? '').toLowerCase();
    return q.contains('premium') || q.contains('enhanced');
  }

  @visibleForTesting
  static int scoreIosMaleQuality(Map<String, String> voice) =>
      _scoreIosMaleQuality(voice);

  /// Männlich, Qualität zuerst — Compact-Markus stark abwerten.
  static int _scoreIosMaleQuality(Map<String, String> voice) {
    final blob =
        '${voice['name']} ${voice['identifier']} ${voice['gender']} ${voice['features']} ${voice['quality']}'
            .toLowerCase();

    var score = 0;
    final enhanced = _isEnhancedOrPremium(voice);
    final quality = (voice['quality'] ?? '').toLowerCase();

    final gender = (voice['gender'] ?? '').toLowerCase();
    if (gender == 'male') score += 100;
    if (gender == 'female') score -= 250;

    if (_femaleHints.hasMatch(blob)) score -= 120;
    if (_maleHints.hasMatch(blob)) score += 40;

    if (enhanced) {
      score += 160;
    } else if (quality.contains('high') || quality.contains('very high')) {
      score += 70;
    } else if (quality.contains('low') || quality.contains('default')) {
      score -= 40;
    }

    if (_iosMaleNameHints.hasMatch(blob)) {
      score += blob.contains('martin') ? 55 : 25;
    }

    // Der „Holländer“: meist Markus **compact** ohne Enhanced.
    if (_markusHint.hasMatch(blob) &&
        _compactHint.hasMatch(blob) &&
        !enhanced) {
      score -= 220;
    } else if (_compactHint.hasMatch(blob) && !enhanced) {
      score -= 90;
    }

    if (enhanced && gender == 'male') score += 50;

    if (voice['network_required'] == '1' && enhanced) score += 35;

    final locale = voice['locale']?.toLowerCase().replaceAll('_', '-') ?? '';
    if (locale.startsWith('de-de')) score += 20;

    return score;
  }

  static int _scoreAndroidMale(Map<String, String> voice) {
    final blob =
        '${voice['name']} ${voice['identifier']} ${voice['gender']} ${voice['features']}'
            .toLowerCase();

    var score = 0;

    final gender = (voice['gender'] ?? '').toLowerCase();
    if (gender == 'male') score += 120;
    if (gender == 'female') score -= 120;

    if (_maleHints.hasMatch(blob)) score += 90;
    if (_femaleHints.hasMatch(blob)) score -= 90;

    final quality = (voice['quality'] ?? '').toLowerCase();
    if (quality.contains('premium') || quality.contains('enhanced')) {
      score += 35;
    } else if (quality.contains('high') || quality.contains('very high')) {
      score += 22;
    } else if (quality.contains('low')) {
      score -= 15;
    }

    if (voice['network_required'] == '1') {
      score -= 8;
    } else {
      score += 12;
    }

    final locale = voice['locale']?.toLowerCase() ?? '';
    if (locale.startsWith('de-de')) score += 10;

    return score;
  }
}
