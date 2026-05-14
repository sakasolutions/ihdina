import 'package:flutter/painting.dart';

import '../models/verse.dart';

/// Teilt Verse auf „Druckseiten“ nach verfügbarem Platz (TextPainter).
class QuranPagePaginator {
  QuranPagePaginator._();

  static List<List<Verse>> paginate({
    required List<Verse> verses,
    required double maxWidth,
    required double maxHeight,
    required TextStyle verseStyle,
    required double paragraphSpacing,
    required TextDirection direction,
    required TextScaler textScaler,
    required bool useArabicScript,
    /// Zusätzliche Höhe pro Vers im Layout (Nummer, Karten-Padding, Abstand) — muss zu [_VerseBlock] passen.
    double perVerseChromeHeight = 52,
  }) {
    String textFor(Verse v) => useArabicScript ? v.ar : v.de;

    final pages = <List<Verse>>[];
    var i = 0;
    while (i < verses.length) {
      final page = <Verse>[];
      var used = 0.0;
      while (i < verses.length) {
        final v = verses[i];
        final tp = TextPainter(
          text: TextSpan(text: textFor(v), style: verseStyle),
          textDirection: direction,
          textScaler: textScaler,
        )..layout(maxWidth: maxWidth);
        final blockH = tp.height + perVerseChromeHeight + paragraphSpacing;
        if (used + blockH > maxHeight && page.isNotEmpty) {
          break;
        }
        if (used + blockH > maxHeight && page.isEmpty) {
          page.add(v);
          i++;
          break;
        }
        page.add(v);
        used += blockH;
        i++;
      }
      if (page.isNotEmpty) {
        pages.add(page);
      }
    }
    return pages;
  }

  static int pageIndexForAyah(List<List<Verse>> pages, int ayah) {
    for (var pi = 0; pi < pages.length; pi++) {
      if (pages[pi].any((v) => v.ayah == ayah)) return pi;
    }
    return 0;
  }
}
