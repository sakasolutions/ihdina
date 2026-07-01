import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/daily_hadith/daily_hadith_entry.dart';
import '../theme/app_theme.dart';
import '../utils/daily_verse_takeaway.dart';
import 'glass_card.dart';
import 'home_daily_pack_sunna_section.dart';
import 'home_verse_secondary_actions.dart';

/// Anzeige-Name der Sure (deutsch klar lesbar: immer „Sure …“).
String displaySureNameForHome(String surahNameEn) {
  final t = surahNameEn.trim();
  if (t.isEmpty) return '';
  final lower = t.toLowerCase();
  if (lower.startsWith('sure ') ||
      lower.startsWith('surah ') ||
      lower.startsWith('sura ')) {
    return t;
  }
  return 'Sure $t';
}

/// Auf **`false`** setzen, um die **vorherige** Tagesvers-Karten-Optik wiederzuzeigen (Rollback ohne Git).
const bool kHomeDailyVerseHeroTier1Layout = true;

/// Kurzvers-Aufwertung in Tier‑1: Arabisch, „Für dich heute“, kompakteres Layout oben.
/// Auf **`false`** setzen = Tier‑1 wie zuvor (nur DE zentriert, volle Kartenhöhe, kein Impuls).
const bool kHomeDailyVerseHeroShortVerseFill = true;

/// Dominant daily-verse block: spiritual centerpiece with clear typography hierarchy.
class HomeDailyVerseHero extends StatelessWidget {
  const HomeDailyVerseHero({
    super.key,
    required this.surahNameEn,
    required this.ayahNumber,
    required this.arabic,
    required this.german,
    /// Optional KI-/Impuls-Zeile; sonst [dailyTakeawayPlaceholder].
    this.personalTakeaway,
    /// Wenn true: kein echter KI-Impuls (Laden oder Standard-Fallback-Text) – dezentere Typo, gleiche Fläche.
    this.takeawayNeutralPresentation = false,
    required this.onMehrVerstehen,
    this.onBookmarkTap,
    this.onWeiterlesen,
    required this.onSpeichern,
    this.dailyHadith,
  });

  final String surahNameEn;
  final int ayahNumber;
  final String arabic;
  final String german;
  final String? personalTakeaway;
  final bool takeawayNeutralPresentation;
  final VoidCallback onMehrVerstehen;
  final VoidCallback? onBookmarkTap;
  final VoidCallback? onWeiterlesen;
  final VoidCallback onSpeichern;
  /// Optional: Sunna-Block in derselben Gold-Karte (Tagespaket).
  final DailyHadithEntry? dailyHadith;

  static const double _radius = 26;
  static const double _goldRingWidth = 1.25;
  static const double _outerRadius = _radius + _goldRingWidth;

  /// Akzent-Gold (Rand/Glow), keine Vollfläche.
  static const Color _accentGold = Color(0xFFD4AF37);

  /// Max. Innenhöhe Tagespaket — etwas niedriger, da Sunna nur noch Streifen ist.
  static const double _maxTier1PackInnerHeight = 440;

  /// Kompaktere Tier‑1-Höhe bei kurzem Vers (mit [kHomeDailyVerseHeroShortVerseFill]).
  static const double _maxTier1PackInnerHeightShort = 368;

  /// Ab dieser Länge gilt der deutsche Auszug als „kurz“ (Arabisch + Top-Layout).
  static const int _shortVerseGermanMaxChars = 120;

  /// Legacy-Karten-Inhalt (ohne Hadith-Paket in gleicher Karte wie Tier‑1).
  static const double _maxInnerContentHeight = 452;

  bool _isShortGermanVerse(String text) {
    final t = text.trim();
    if (t.isEmpty) return true;
    if (t.length <= _shortVerseGermanMaxChars) return true;
    final lines = t.split('\n').where((l) => l.trim().isNotEmpty).length;
    return lines <= 2 && t.length <= 160;
  }

  String _resolvedTakeawayLine() =>
      takeawayOneLine(personalTakeaway) ??
      dailyTakeawayPlaceholder(surahNameEn, ayahNumber);

  @override
  Widget build(BuildContext context) {
    final tier1ShortFill =
        kHomeDailyVerseHeroTier1Layout && kHomeDailyVerseHeroShortVerseFill;
    final shortVerse = tier1ShortFill && _isShortGermanVerse(german);
    final tier1MaxHeight = shortVerse
        ? _maxTier1PackInnerHeightShort
        : _maxTier1PackInnerHeight;

    return _DailyVerseHeroChrome(
      maxInnerHeight: kHomeDailyVerseHeroTier1Layout
          ? tier1MaxHeight
          : _maxInnerContentHeight,
      fadeOverflowClip: kHomeDailyVerseHeroTier1Layout,
      outerRadius: _outerRadius,
      radius: _radius,
      goldRingWidth: _goldRingWidth,
      accentGold: _accentGold,
      innerPadding: kHomeDailyVerseHeroTier1Layout
          ? const EdgeInsets.fromLTRB(20, 20, 20, 18)
          : const EdgeInsets.fromLTRB(18, 20, 18, 18),
      child: kHomeDailyVerseHeroTier1Layout
          ? _Tier1AdaptivePackBody(
              maxHeight: tier1MaxHeight,
              compactVerseLayout: shortVerse,
              header: _buildHeaderRow(),
              verseBlock: _buildTier1VerseBlock(showArabic: shortVerse),
              middleBlock: null,
              pinnedBlock: _buildTier1PinnedBlock(compactTopGap: shortVerse),
            )
          : _buildLegacyColumn(
              _resolvedTakeawayLine(),
              takeawayNeutralPresentation,
            ),
    );
  }

  Widget _buildHeaderRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tagesvers heute',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: Colors.white.withOpacity(0.4),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${displaySureNameForHome(surahNameEn)} · Vers $ayahNumber',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 21,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
        if (onBookmarkTap != null)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onBookmarkTap,
              borderRadius: BorderRadius.circular(22),
              splashColor: Colors.white.withOpacity(0.1),
              highlightColor: Colors.white.withOpacity(0.05),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.bookmark_border_rounded,
                  size: 22,
                  color: Colors.white.withOpacity(0.88),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Erste Ebene: nur Auszug — Länge im Sheet / Lesemodus.
  static const int _tier1GermanPreviewMaxLines = 5;

  Widget _buildGermanQuoteTier1({bool emphasizeShort = false}) {
    return Text(
      german,
      textAlign: TextAlign.center,
      maxLines: _tier1GermanPreviewMaxLines,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.inter(
        fontSize: emphasizeShort ? 16 : 15,
        fontWeight: FontWeight.w500,
        height: emphasizeShort ? 1.48 : 1.5,
        color: Colors.white.withOpacity(emphasizeShort ? 0.92 : 0.88),
      ),
    );
  }

  Widget _buildTier1ArabicQuote() {
    final t = arabic.trim();
    if (t.isEmpty) return const SizedBox.shrink();
    return Text(
      t,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.center,
      maxLines: 4,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.amiri(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        height: 1.55,
        color: Colors.white.withOpacity(0.82),
      ),
    );
  }

  Widget _buildTier1VerseBlock({required bool showArabic}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildGermanQuoteTier1(emphasizeShort: showArabic),
        if (showArabic && arabic.trim().isNotEmpty) ...[
          const SizedBox(height: 18),
          _buildTier1ArabicQuote(),
        ],
      ],
    );
  }

  Widget _buildTier1TakeawayBlock(String takeawayLine, bool soft) {
    return _buildLegacyTakeawayBlock(takeawayLine, soft);
  }

  Widget _buildGermanQuoteLegacy() {
    return Text(
      german,
      textAlign: TextAlign.center,
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.45,
        color: Colors.white,
      ),
    );
  }

  Widget _buildLegacyTakeawayBlock(String takeawayLine, bool soft) {
    return Container(
      padding: const EdgeInsets.only(top: 14),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Für dich heute',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 7.5,
              fontWeight: soft ? FontWeight.w400 : FontWeight.w500,
              letterSpacing: soft ? 1.25 : 1.3,
              color: Colors.white.withOpacity(soft ? 0.2 : 0.24),
            ),
          ),
          const SizedBox(height: 14),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white.withOpacity(soft ? 0.03 : 0.04),
              border: Border.all(
                color: Colors.white.withOpacity(soft ? 0.055 : 0.07),
                width: 1,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: soft ? 9.5 : 10,
              ),
              child: Text(
                takeawayLine,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: soft ? 14.5 : 15,
                  height: 1.42,
                  fontWeight: soft ? FontWeight.w400 : FontWeight.w500,
                  letterSpacing: soft ? 0.08 : 0.15,
                  color: Colors.white.withOpacity(soft ? 0.78 : 0.94),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// CTAs direkt auf der Hero-Glasfläche; nur eine feine Linie trennt vom Vers (kein „Card in Card“).
  Widget _buildTier1PinnedBlock({bool compactTopGap = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: compactTopGap ? 6 : 10),
        Container(height: 1, color: Colors.white.withOpacity(0.07)),
        const SizedBox(height: 14),
        Center(child: _MehrVerstehenGlassButton(onPressed: onMehrVerstehen)),
        const SizedBox(height: 10),
        HomeVerseSecondaryActionsRow(
          onWeiterlesen: onWeiterlesen,
          onSpeichern: onSpeichern,
        ),
        if (dailyHadith != null)
          HomeDailyPackSunnaSection(
            entry: dailyHadith!,
            embedOnHeroGlass: true,
          ),
      ],
    );
  }

  Widget _buildLegacyColumn(String takeawayLine, bool soft) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeaderRow(),
        const SizedBox(height: 14),
        _buildGermanQuoteLegacy(),
        const SizedBox(height: 16),
        _buildLegacyTakeawayBlock(takeawayLine, soft),
        const SizedBox(height: 18),
        Center(child: _MehrVerstehenGlassButton(onPressed: onMehrVerstehen)),
        const SizedBox(height: 12),
        HomeVerseSecondaryActionsRow(
          onWeiterlesen: onWeiterlesen,
          onSpeichern: onSpeichern,
        ),
        if (dailyHadith != null) HomeDailyPackSunnaSection(entry: dailyHadith!),
      ],
    );
  }
}

class _DailyVerseHeroChrome extends StatelessWidget {
  const _DailyVerseHeroChrome({
    required this.child,
    required this.maxInnerHeight,
    this.fadeOverflowClip = false,
    required this.outerRadius,
    required this.radius,
    required this.goldRingWidth,
    required this.accentGold,
    required this.innerPadding,
  });

  final Widget child;
  final double maxInnerHeight;
  final bool fadeOverflowClip;
  final double outerRadius;
  final double radius;
  final double goldRingWidth;
  final Color accentGold;
  final EdgeInsets innerPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(outerRadius),
        color: AppColors.emeraldDark,
        border: Border.all(
          color: accentGold.withOpacity(0.26),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: accentGold.withOpacity(0.22),
            blurRadius: 28,
            spreadRadius: -2,
            offset: Offset.zero,
          ),
          BoxShadow(
            color: AppColors.premiumGoldHighlight.withOpacity(0.06),
            blurRadius: 42,
            spreadRadius: 0,
            offset: Offset.zero,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(outerRadius),
        child: Padding(
          padding: EdgeInsets.all(goldRingWidth),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: GlassCard(
              borderRadius: radius,
              child: Padding(
                padding: innerPadding,
                child: fadeOverflowClip
                    ? child
                    : ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: maxInnerHeight),
                        child: ClipRect(child: child),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tier‑1: Kopf oben; Vers zentriert (lang) oder oben gebündelt (kurz mit Fill-Flag).
/// Langer Fließtext bleibt im [SingleChildScrollView] scrollbar. CTA-Band fix unten.
class _Tier1AdaptivePackBody extends StatelessWidget {
  const _Tier1AdaptivePackBody({
    required this.maxHeight,
    required this.header,
    required this.verseBlock,
    this.middleBlock,
    required this.pinnedBlock,
    this.compactVerseLayout = false,
  });

  final double maxHeight;
  final Widget header;
  final Widget verseBlock;
  final Widget? middleBlock;
  final Widget pinnedBlock;
  final bool compactVerseLayout;

  Widget _scrollableMainContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        verseBlock,
        if (middleBlock != null) ...[
          const SizedBox(height: 16),
          middleBlock!,
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (compactVerseLayout) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: ClipRect(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: _scrollableMainContent(),
                ),
              ),
              pinnedBlock,
            ],
          ),
        ),
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: ClipRect(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  header,
                  const SizedBox(height: 22),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                        child: _scrollableMainContent(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            pinnedBlock,
          ],
        ),
      ),
    );
  }
}

const Color _ctaSoftGold = Color(0xFFEFD9A7);
const Color _ctaGoldBorder = Color(0xFFD4AF37);

class _MehrVerstehenGlassButton extends StatefulWidget {
  const _MehrVerstehenGlassButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_MehrVerstehenGlassButton> createState() => _MehrVerstehenGlassButtonState();
}

class _MehrVerstehenGlassButtonState extends State<_MehrVerstehenGlassButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    await _pulse.forward();
    await _pulse.reverse();
    if (mounted) widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = Curves.easeOut.transform(_pulse.value);
        final borderOp = 0.25 + t * 0.18;
        final glowOp = 0.08 + t * 0.14;
        final topSheen = 0.06 + t * 0.04;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _handleTap,
            borderRadius: BorderRadius.circular(14),
            splashColor: Colors.white.withOpacity(0.06),
            highlightColor: Colors.white.withOpacity(0.04),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(topSheen),
                    Colors.white.withOpacity(0.055),
                  ],
                ),
                border: Border.all(
                  color: _ctaGoldBorder.withOpacity(borderOp),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _ctaGoldBorder.withOpacity(glowOp),
                    blurRadius: 14 + t * 10,
                    spreadRadius: t * 1.5,
                    offset: Offset.zero,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 17,
                      color: _ctaSoftGold.withOpacity(0.95),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Mehr verstehen',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                        color: _ctaSoftGold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
