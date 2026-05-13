import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/verse.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

/// Gleiche Vers-Kachel wie im [QuranReaderScreen]: GlassCard, Aya-Badge, Arabisch, DE/Transliteration, Zeile mit Verstehen + Wiedergabe + Lesezeichen.
class QuranVerseReaderTile extends StatelessWidget {
  const QuranVerseReaderTile({
    super.key,
    required this.verse,
    required this.isBookmarked,
    required this.arabicFontSize,
    required this.arabicLineHeight,
    required this.showTransliteration,
    required this.isPlaying,
    required this.isLoading,
    required this.showJumpHighlight,
    required this.onVerstehenTap,
    required this.onBookmarkTap,
    required this.onPlayTap,
  });

  final Verse verse;
  final bool isBookmarked;
  final double arabicFontSize;
  final double arabicLineHeight;
  final bool showTransliteration;
  final bool isPlaying;
  final bool isLoading;
  final bool showJumpHighlight;
  final VoidCallback onVerstehenTap;
  final VoidCallback onBookmarkTap;
  final VoidCallback onPlayTap;

  static const Color _accentChampagneGold = Color(0xFFE5C07B);

  @override
  Widget build(BuildContext context) {
    final audioActive = isPlaying || isLoading;
    final framed = audioActive || showJumpHighlight;
    final arabicHeight = (arabicLineHeight + 0.12).clamp(1.75, 2.35);

    final playBookmarkRow = SizedBox(
      height: 32,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: isLoading
                ? Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _accentChampagneGold,
                      ),
                    ),
                  )
                : Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onPlayTap,
                      customBorder: const CircleBorder(),
                      splashColor: Colors.white.withOpacity(0.14),
                      highlightColor: Colors.white.withOpacity(0.06),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isPlaying
                              ? _accentChampagneGold.withOpacity(0.11)
                              : Colors.transparent,
                          border: isPlaying
                              ? Border.all(
                                  color: _accentChampagneGold.withOpacity(0.36),
                                  width: 1,
                                )
                              : null,
                          boxShadow: isPlaying
                              ? [
                                  BoxShadow(
                                    color: _accentChampagneGold.withOpacity(0.12),
                                    blurRadius: 6,
                                    spreadRadius: 0,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          isPlaying
                              ? Icons.stop_circle_outlined
                              : Icons.play_circle_outline_rounded,
                          size: 24,
                          color: isPlaying
                              ? _accentChampagneGold
                              : AppColors.emeraldLight,
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 28,
            height: 28,
            child: IconButton(
              icon: Icon(
                isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                size: 20,
                color: isBookmarked ? Colors.white : Colors.white70,
              ),
              onPressed: onBookmarkTap,
              padding: EdgeInsets.zero,
              style: IconButton.styleFrom(
                minimumSize: const Size(28, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );

    final tileContent = GlassCard(
      borderRadius: 22,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 30, 22, 28),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 30),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      verse.ar,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.amiri(
                        fontSize: arabicFontSize,
                        height: arabicHeight,
                        letterSpacing: 0.4,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                if (showTransliteration &&
                    verse.transliteration != null &&
                    verse.transliteration!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    verse.transliteration!,
                    textAlign: TextAlign.left,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ] else if (verse.de.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    verse.de,
                    textAlign: TextAlign.left,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      height: 1.55,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onVerstehenTap,
                        borderRadius: BorderRadius.circular(14),
                        splashColor: Colors.white.withOpacity(0.06),
                        highlightColor: Colors.white.withOpacity(0.04),
                        child: Ink(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: Colors.white.withOpacity(0.045),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.09),
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  size: 16,
                                  color: _accentChampagneGold.withOpacity(0.92),
                                ),
                                const SizedBox(width: 9),
                                Text(
                                  'Verstehen',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.15,
                                    color: Colors.white.withOpacity(0.82),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    playBookmarkRow,
                  ],
                ),
              ],
            ),
            Positioned(
              top: 2,
              left: 0,
              child: Opacity(
                opacity: 0.65,
                child: _AyahBadge(ayah: verse.ayah),
              ),
            ),
          ],
        ),
      ),
    );

    if (!framed) {
      return tileContent;
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: _accentChampagneGold.withOpacity(0.042),
        border: Border.all(
          color: _accentChampagneGold.withOpacity(0.22),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _accentChampagneGold.withOpacity(0.08),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: tileContent,
    );
  }
}

class _AyahBadge extends StatelessWidget {
  const _AyahBadge({required this.ayah});

  final int ayah;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 21,
      height: 21,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.18),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.07),
          width: 1,
        ),
      ),
      child: Text(
        '$ayah',
        style: GoogleFonts.inter(
          fontSize: 8.5,
          fontWeight: FontWeight.w600,
          color: Colors.white.withOpacity(0.42),
        ),
      ),
    );
  }
}
