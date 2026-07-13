import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';
import '../religious_liturgical_text.dart';

const Color _accentChampagneGold = Color(0xFFE5C07B);

/// Darstellung eines [ReligiousLiturgicalText] — Arabisch, Umschrift, Bedeutung.
///
/// Folgt der Typografie aus Du'a- und Koran-Leser (Amiri + Inter-Kursiv).
/// Liturgische Texte werden nie abgeschnitten — natürlicher Zeilenumbruch.
class PurificationLiturgicalTextBlock extends StatelessWidget {
  const PurificationLiturgicalTextBlock({
    super.key,
    required this.text,
    this.textScale = 1.0,
    this.arabicFontSize = 28,
    this.compact = false,
  });

  final ReligiousLiturgicalText text;
  final double textScale;
  final double arabicFontSize;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final scale = textScale.clamp(0.9, 1.4);
    final arabicSize = scaler.scale(arabicFontSize * scale);
    final transliterationSize = scaler.scale(15 * scale);
    final translationSize = scaler.scale(13 * scale);
    final hintSize = scaler.scale(11.5 * scale);
    final arabicHeight = (1.68 + 0.12).clamp(1.75, 2.35);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (text.label != null && text.label!.isNotEmpty) ...[
          Text(
            text.label!,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: scaler.scale(11 * scale),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: _accentChampagneGold.withValues(alpha: 0.88),
            ),
          ),
          SizedBox(height: compact ? 8 : 10),
        ],
        Semantics(
          label: 'Arabisch: ${text.arabicText}',
          child: ExcludeSemantics(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                text.arabicText,
                textAlign: TextAlign.center,
                softWrap: true,
                style: GoogleFonts.amiri(
                  fontSize: arabicSize,
                  height: arabicHeight,
                  letterSpacing: 0.4,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: compact ? 6 : 10),
        Semantics(
          label: 'Umschrift: ${text.transliteration}',
          child: ExcludeSemantics(
            child: Text(
              text.transliteration,
              textAlign: TextAlign.center,
              softWrap: true,
              style: GoogleFonts.inter(
                fontSize: transliterationSize,
                height: 1.45,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
        SizedBox(height: compact ? 4 : 8),
        Semantics(
          label: 'Bedeutung: ${text.translation}',
          child: ExcludeSemantics(
            child: Text(
              text.translation,
              textAlign: TextAlign.center,
              softWrap: true,
              style: GoogleFonts.inter(
                fontSize: translationSize,
                height: 1.4,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.72),
              ),
            ),
          ),
        ),
        if (text.pronunciationHint != null &&
            text.pronunciationHint!.isNotEmpty) ...[
          SizedBox(height: compact ? 4 : 6),
          Semantics(
            label: 'Aussprachehinweis: ${text.pronunciationHint}',
            child: ExcludeSemantics(
              child: Text(
                text.pronunciationHint!,
                textAlign: TextAlign.center,
                softWrap: true,
                style: GoogleFonts.inter(
                  fontSize: hintSize,
                  height: 1.35,
                  color: Colors.white.withValues(alpha: 0.52),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Mehrere liturgische Texte untereinander.
class PurificationLiturgicalTextList extends StatelessWidget {
  const PurificationLiturgicalTextList({
    super.key,
    required this.texts,
    this.textScale = 1.0,
    this.compact = false,
  });

  final List<ReligiousLiturgicalText> texts;
  final double textScale;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (texts.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < texts.length; i++) ...[
          if (i > 0) SizedBox(height: compact ? 14 : 18),
          PurificationLiturgicalTextBlock(
            text: texts[i],
            textScale: textScale,
            compact: compact,
          ),
        ],
      ],
    );
  }
}
