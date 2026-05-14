import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/verse.dart';
import '../reading/quran_page_paginator.dart';
import '../theme/app_theme.dart';

typedef VerseActionCallback = void Function(Verse verse);

/// Seitenweises Lesen (Beta): umblättern wie eine Druckseite, ein Fließtext pro Sprache.
/// **Tippen auf den Vers** öffnet die KI-Erklärung; **länger drücken** öffnet Wiedergabe & Lesezeichen.
class QuranPrintedPageReader extends StatefulWidget {
  const QuranPrintedPageReader({
    super.key,
    required this.verses,
    required this.useArabicScript,
    required this.arabicFontSize,
    required this.arabicLineHeight,
    required this.surahNameDe,
    required this.bookmarkedAyahNumbers,
    required this.onVerstehenTap,
    required this.onPlayTap,
    required this.onBookmarkTap,
    required this.onPageCommit,
    this.initialAyah,
    this.playingAyah,
    this.loadingAyah,
    this.showSwipeHint = true,
  });

  final List<Verse> verses;
  final bool useArabicScript;
  final double arabicFontSize;
  final double arabicLineHeight;
  final String surahNameDe;
  final Set<int> bookmarkedAyahNumbers;
  final VerseActionCallback onVerstehenTap;
  final VerseActionCallback onPlayTap;
  final VerseActionCallback onBookmarkTap;
  /// Letzter Vers auf der sichtbaren Seite (Lesefortschritt).
  final void Function(int lastAyahOnPage) onPageCommit;
  final int? initialAyah;
  final int? playingAyah;
  final int? loadingAyah;
  final bool showSwipeHint;

  @override
  State<QuranPrintedPageReader> createState() => QuranPrintedPageReaderState();
}

class QuranPrintedPageReaderState extends State<QuranPrintedPageReader> {
  PageController? _controller;
  List<List<Verse>>? _pages;
  int? _cacheKey;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void jumpToAyah(int ayah) {
    final pages = _pages;
    final c = _controller;
    if (pages == null || c == null || !c.hasClients) return;
    final p = QuranPagePaginator.pageIndexForAyah(pages, ayah).clamp(0, pages.length - 1);
    c.jumpToPage(p);
  }

  TextStyle _verseStyle(TextScaler scaler) {
    if (widget.useArabicScript) {
      return GoogleFonts.amiri(
        fontSize: widget.arabicFontSize,
        height: widget.arabicLineHeight,
        color: Colors.white.withOpacity(0.95),
      );
    }
    final deSize = (widget.arabicFontSize * 0.62).clamp(15.0, 22.0);
    return GoogleFonts.inter(
      fontSize: deSize,
      height: 1.45,
      color: Colors.white.withOpacity(0.94),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.verses.isEmpty) {
      return const Center(child: Text('Keine Verse', style: TextStyle(color: Colors.white54)));
    }

    final scaler = MediaQuery.textScalerOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        const horizontalPad = 24.0;
        const topPad = 8.0;
        const swipeHintHeight = 32.0;
        const pageInnerVerticalPad = 8.0 + 16.0;
        const surahTitleBlock = 40.0;
        /// Zusatzhöhe pro Vers: Rand‑Ayah‑Markierung, Innenabstand — muss zu [QuranPagePaginator.paginate] passen.
        const perVerseChrome = 36.0;
        final maxW = (constraints.maxWidth - horizontalPad * 2).clamp(120.0, 800.0);
        final hintBar = widget.showSwipeHint ? swipeHintHeight : 0.0;
        final pageViewViewport =
            (constraints.maxHeight - hintBar).clamp(160.0, 4000.0);
        final verseColumnMaxH =
            (pageViewViewport - pageInnerVerticalPad - surahTitleBlock).clamp(80.0, 4000.0);

        final direction = widget.useArabicScript ? TextDirection.rtl : TextDirection.ltr;
        final style = _verseStyle(scaler);
        final cacheKey = Object.hash(
          maxW.round(),
          verseColumnMaxH.round(),
          hintBar.round(),
          widget.verses.length,
          widget.arabicFontSize.round(),
          (widget.arabicLineHeight * 100).round(),
          widget.useArabicScript,
          widget.showSwipeHint,
        );

        final same = _cacheKey == cacheKey && _pages != null && _controller != null;

        if (!same) {
          _pages = QuranPagePaginator.paginate(
            verses: widget.verses,
            maxWidth: maxW,
            maxHeight: verseColumnMaxH,
            verseStyle: style,
            paragraphSpacing: 12,
            direction: direction,
            textScaler: scaler,
            useArabicScript: widget.useArabicScript,
            perVerseChromeHeight: perVerseChrome,
          );
          _cacheKey = cacheKey;
          _controller?.dispose();
          final initialPage = widget.initialAyah == null || _pages!.isEmpty
              ? 0
              : QuranPagePaginator.pageIndexForAyah(_pages!, widget.initialAyah!).clamp(0, _pages!.length - 1);
          _controller = PageController(initialPage: initialPage);
        }

        final pages = _pages!;
        final controller = _controller!;

        return Column(
          children: [
            if (widget.showSwipeHint)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '← Seiten wischen →',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withOpacity(0.45)),
                ),
              ),
            Expanded(
              child: PageView.builder(
                controller: controller,
                itemCount: pages.length,
                physics: const PageScrollPhysics(),
                onPageChanged: (i) {
                  widget.onPageCommit(pages[i].last.ayah);
                },
                itemBuilder: (context, pageIndex) {
                  final slice = pages[pageIndex];
                  return Directionality(
                    textDirection: direction,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(horizontalPad, topPad, horizontalPad, 16),
                      child: Column(
                        crossAxisAlignment:
                            widget.useArabicScript ? CrossAxisAlignment.stretch : CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.surahNameDe,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.55),
                            ),
                            textAlign: widget.useArabicScript ? TextAlign.right : TextAlign.left,
                          ),
                          const SizedBox(height: 10),
                          ...slice.map(
                            (v) => _FlowVerseParagraph(
                              verse: v,
                              useArabic: widget.useArabicScript,
                              verseStyle: style,
                              isBookmarked: widget.bookmarkedAyahNumbers.contains(v.ayah),
                              isPlaying: widget.playingAyah == v.ayah,
                              isLoading: widget.loadingAyah == v.ayah,
                              onVerstehenTap: () => widget.onVerstehenTap(v),
                              onPlayTap: () => widget.onPlayTap(v),
                              onBookmarkTap: () => widget.onBookmarkTap(v),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FlowVerseParagraph extends StatelessWidget {
  const _FlowVerseParagraph({
    required this.verse,
    required this.useArabic,
    required this.verseStyle,
    required this.isBookmarked,
    required this.isPlaying,
    required this.isLoading,
    required this.onVerstehenTap,
    required this.onPlayTap,
    required this.onBookmarkTap,
  });

  final Verse verse;
  final bool useArabic;
  final TextStyle verseStyle;
  final bool isBookmarked;
  final bool isPlaying;
  final bool isLoading;
  final VoidCallback onVerstehenTap;
  final VoidCallback onPlayTap;
  final VoidCallback onBookmarkTap;

  static const Color _accentGold = Color(0xFFE5C07B);

  @override
  Widget build(BuildContext context) {
    final text = useArabic ? verse.ar : verse.de;
    final align = useArabic ? TextAlign.right : TextAlign.left;
    final audioActive = isPlaying || isLoading;

    final bodyStyle = verseStyle.merge(TextStyle(
      backgroundColor: audioActive ? _accentGold.withOpacity(0.14) : Colors.transparent,
    ));

    return Padding(
      padding: EdgeInsets.only(bottom: useArabic ? 10 : 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onVerstehenTap,
          onLongPress: () => _showPrintedVerseToolSheet(
            context,
            verse: verse,
            isBookmarked: isBookmarked,
            isPlaying: isPlaying,
            isLoading: isLoading,
            onPlay: onPlayTap,
            onBookmark: onBookmarkTap,
            onVerstehen: onVerstehenTap,
          ),
          splashColor: Colors.white.withOpacity(0.07),
          highlightColor: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Row(
              textDirection: useArabic ? TextDirection.rtl : TextDirection.ltr,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AyahMarginMark(
                  ayah: verse.ayah,
                  isBookmarked: isBookmarked,
                  isPlaying: isPlaying,
                  isLoading: isLoading,
                ),
                SizedBox(width: useArabic ? 12 : 10),
                Expanded(
                  child: Text(text, style: bodyStyle, textAlign: align),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AyahMarginMark extends StatelessWidget {
  const _AyahMarginMark({
    required this.ayah,
    required this.isBookmarked,
    required this.isPlaying,
    required this.isLoading,
  });

  final int ayah;
  final bool isBookmarked;
  final bool isPlaying;
  final bool isLoading;

  static const Color _accentGold = Color(0xFFE5C07B);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(
              color: isPlaying
                  ? _accentGold.withOpacity(0.55)
                  : isBookmarked
                      ? Colors.white.withOpacity(0.28)
                      : Colors.white.withOpacity(0.08),
              width: isPlaying ? 1.5 : 1,
            ),
          ),
          child: isLoading
              ? SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.8,
                    color: _accentGold.withOpacity(0.95),
                  ),
                )
              : Text(
                  '$ayah',
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.45),
                  ),
                ),
        ),
        if (isBookmarked && !isLoading) ...[
          const SizedBox(height: 4),
          Icon(Icons.bookmark_rounded, size: 11, color: Colors.white.withOpacity(0.5)),
        ],
      ],
    );
  }
}

Future<void> _showPrintedVerseToolSheet(
  BuildContext context, {
  required Verse verse,
  required bool isBookmarked,
  required bool isPlaying,
  required bool isLoading,
  required VoidCallback onPlay,
  required VoidCallback onBookmark,
  required VoidCallback onVerstehen,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.45),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.paddingOf(ctx).bottom + 16,
        ),
        child: Material(
          color: AppColors.emeraldDark.withOpacity(0.97),
          borderRadius: BorderRadius.circular(20),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                  child: Row(
                    children: [
                      Text(
                        'Vers ${verse.ayah}',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: Icon(Icons.close_rounded, color: Colors.white.withOpacity(0.65)),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Text(
                    'Kurz tippen: Verstehen · hier: weitere Aktionen',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      height: 1.35,
                      color: Colors.white.withOpacity(0.48),
                    ),
                  ),
                ),
                ListTile(
                  leading: isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: const Color(0xFFE5C07B).withOpacity(0.9),
                          ),
                        )
                      : Icon(
                          isPlaying ? Icons.stop_circle_outlined : Icons.play_circle_outline_rounded,
                          color: isPlaying ? const Color(0xFFE5C07B) : AppColors.emeraldLight,
                        ),
                  title: Text(
                    isPlaying ? 'Wiedergabe stoppen' : 'Wiedergabe',
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white),
                  ),
                  onTap: isLoading
                      ? null
                      : () {
                          Navigator.pop(ctx);
                          onPlay();
                        },
                ),
                ListTile(
                  leading: Icon(
                    isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    color: Colors.white70,
                  ),
                  title: Text(
                    isBookmarked ? 'Lesezeichen entfernen' : 'Lesezeichen',
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    onBookmark();
                  },
                ),
                ListTile(
                  leading: Icon(Icons.auto_awesome, color: const Color(0xFFE5C07B).withOpacity(0.92)),
                  title: Text(
                    'Verstehen',
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    onVerstehen();
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      );
    },
  );
}
