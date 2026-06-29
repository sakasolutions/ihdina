import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'tts_pronunciation_rule.dart';

/// Offline-Aussprachehilfe: ersetzt Transliterationen durch für deutsche TTS
/// gut lesbare Formen (z. B. „Al-Hajj“ → „Al-Hadsch“), bevor [TtsService] spricht.
class TtsPronunciationRepository {
  TtsPronunciationRepository._();

  static final TtsPronunciationRepository instance = TtsPronunciationRepository._();

  static const String _assetPath = 'assets/data/tts_pronunciations.json';

  List<TtsPronunciationRule>? _rules;

  /// Kritische Regeln immer im Bundle (JSON optional erweiterbar).
  static const List<TtsPronunciationRule> _builtIn = [
    TtsPronunciationRule(from: 'Al-Hajj', to: 'Al-Hadsch'),
    TtsPronunciationRule(from: 'Hajj', to: 'Hadsch'),
    TtsPronunciationRule(from: 'Al-Hijr', to: 'Al-Hidschr'),
    TtsPronunciationRule(from: "Al-Jumu'ah", to: 'Al-Dschumua'),
    TtsPronunciationRule(from: 'Al-Qalam', to: 'Al-Kalam'),
    TtsPronunciationRule(from: 'Al-Qadr', to: 'Al-Kader'),
    TtsPronunciationRule(from: 'Al-Qiyamah', to: 'Al-Kijama'),
    TtsPronunciationRule(from: 'Al-Kawthar', to: 'Al-Kauthar'),
    TtsPronunciationRule(from: 'Al-Qamar', to: 'Al-Kamar'),
    TtsPronunciationRule(from: 'Al-Qasas', to: 'Al-Kasas'),
    TtsPronunciationRule(from: 'Al-Quraysh', to: 'Al-Kuraisch'),
    TtsPronunciationRule(from: "Al-Qari'ah", to: 'Al-Karia'),
    TtsPronunciationRule(from: 'Al-Hujurat', to: 'Al-Hudschrurat'),
    TtsPronunciationRule(from: 'Al-Jathiyah', to: 'Al-Dschathija'),
    TtsPronunciationRule(from: "Al-A'raf", to: 'Al-Araf'),
    TtsPronunciationRule(from: "Al-An'am", to: 'Al-Anam'),
    TtsPronunciationRule(from: "Al-'Ankabut", to: 'Al-Ankabut'),
    TtsPronunciationRule(from: "Al-Waqi'ah", to: 'Al-Wakia'),
    TtsPronunciationRule(from: "Al-Ma'arij", to: 'Al-Maaridsch'),
    TtsPronunciationRule(from: "An-Nazi'at", to: 'An-Naziat'),
    TtsPronunciationRule(from: "Al-'Adiyat", to: 'Al-Adiyat'),
    TtsPronunciationRule(from: "Al-'Asr", to: 'Al-Assr'),
    TtsPronunciationRule(from: "Al-Ma'un", to: 'Al-Maun'),
    TtsPronunciationRule(from: "Ash-Shu'ara", to: 'Asch-Schuara'),
    TtsPronunciationRule(from: "Ali 'Imran", to: 'Ali Imran'),
    TtsPronunciationRule(from: 'Al-Inshirah', to: 'Al-Inschirah'),
    TtsPronunciationRule(from: 'Ash-Sharh', to: 'Asch-Scharh'),
    TtsPronunciationRule(from: 'Al-Ghashiyah', to: 'Al-Gaschija'),
    TtsPronunciationRule(from: 'Quran', to: 'Koran'),
    TtsPronunciationRule(from: 'Qur\'an', to: 'Koran'),
    TtsPronunciationRule(from: 'Ayah', to: 'Aya'),
    TtsPronunciationRule(from: 'Ayahs', to: 'Ayas'),
    TtsPronunciationRule(from: 'Dhuhr', to: 'Duhur'),
    TtsPronunciationRule(from: 'Maghrib', to: 'Magrib'),
    TtsPronunciationRule(from: 'Fajr', to: 'Fadschr'),
    TtsPronunciationRule(from: 'Isha', to: 'Ischa'),
    TtsPronunciationRule(from: 'Karahat', to: 'Karaha'),
    TtsPronunciationRule(from: 'Tafsir', to: 'Tafsier'),
    TtsPronunciationRule(from: 'Hadith', to: 'Hadis'),
    TtsPronunciationRule(from: 'Sunnah', to: 'Sunna'),
    TtsPronunciationRule(from: 'Hijra', to: 'Hidschra'),
    TtsPronunciationRule(from: 'Hidschra', to: 'Hidschra'),
    TtsPronunciationRule(from: 'Zakah', to: 'Sakka'),
    TtsPronunciationRule(from: 'Sawm', to: 'Saum'),
    TtsPronunciationRule(from: 'Salah', to: 'Salah'),
    TtsPronunciationRule(from: 'Du\'a', to: 'Dua'),
    TtsPronunciationRule(from: "Du'a", to: 'Dua'),
    TtsPronunciationRule(from: 'Mushaf', to: 'Muschaf'),
    TtsPronunciationRule(from: 'Basmala', to: 'Basmala'),
    TtsPronunciationRule(from: 'Ka\'bah', to: 'Kaaba'),
    TtsPronunciationRule(from: 'Kaaba', to: 'Kaaba'),
    TtsPronunciationRule(from: 'Fiqh', to: 'Fikh'),
  ];

  Future<void> ensureLoaded() async {
    if (_rules != null) return;
    final merged = <String, TtsPronunciationRule>{};

    void addRule(TtsPronunciationRule r) {
      final key = r.from.toLowerCase();
      merged[key] = r;
    }

    for (final r in _builtIn) {
      addRule(r);
    }

    try {
      final raw = await rootBundle.loadString(_assetPath);
      final decoded = json.decode(raw);
      if (decoded is Map<String, dynamic>) {
        final list = decoded['replacements'] as List<dynamic>? ?? [];
        for (final item in list) {
          if (item is! Map<String, dynamic>) continue;
          final from = (item['from'] as String?)?.trim() ?? '';
          final to = (item['to'] as String?)?.trim() ?? '';
          if (from.isEmpty || to.isEmpty) continue;
          addRule(TtsPronunciationRule(from: from, to: to));
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[TtsPronunciation] JSON optional: $e');
      }
    }

    _rules = merged.values.toList()
      ..sort((a, b) => b.from.length.compareTo(a.from.length));
  }

  /// Wendet alle Regeln auf [text] an (Markdown sollte bereits bereinigt sein).
  Future<String> apply(String text) async {
    await ensureLoaded();
    var result = text;
    for (final rule in _rules!) {
      result = result.replaceAll(rule.pattern, rule.to);
    }
    return result;
  }

  void clearCache() => _rules = null;
}
