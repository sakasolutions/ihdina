import '../religious_liturgical_text.dart';

/// Zentral gepflegte liturgische Texte für den Wudu-Guide.
abstract final class WuduLiturgicalTexts {
  WuduLiturgicalTexts._();

  /// Vollständige Basmala zu Beginn des Wudu (Schritt 3).
  static const ReligiousLiturgicalText basmala = ReligiousLiturgicalText(
    label: 'Basmala',
    arabicText: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
    transliteration: 'Bismillāhi r-raḥmāni r-raḥīm.',
    translation: 'Im Namen Allahs, des Allerbarmers, des Barmherzigen.',
  );
}
