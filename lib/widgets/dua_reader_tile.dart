import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/dua/dua_entry.dart';
import '../theme/app_theme.dart';
import 'dua_guidance_dialog.dart';
import 'glass_card.dart';

/// Dua-Kachel im Stil von [QuranVerseReaderTile]: GlassCard, Badge, Arabisch, Übersetzung.
class DuaReaderTile extends StatelessWidget {
  const DuaReaderTile({
    super.key,
    required this.entry,
    required this.listIndex,
    this.arabicFontSize = 26,
    this.arabicLineHeight = 1.68,
    this.embedded = false,
    this.isBookmarked = false,
    this.onBookmarkTap,
  });

  final DuaEntry entry;
  final int listIndex;
  final double arabicFontSize;
  final double arabicLineHeight;

  /// Ohne [GlassCard]-Hülle — z. B. in einem opaken Dialog-Shell.
  final bool embedded;
  final bool isBookmarked;
  final VoidCallback? onBookmarkTap;

  static const Color _accentChampagneGold = Color(0xFFE5C07B);

  @override
  Widget build(BuildContext context) {
    final arabic = entry.arabic.trim();
    final german = entry.german.trim();
    final source = entry.sourceRaw.trim();
    final transliteration = entry.transliteration?.trim() ?? '';
    final category = entry.category.trim();
    final arabicHeight = (arabicLineHeight + 0.12).clamp(1.75, 2.35);

    final content = Padding(
      padding: const EdgeInsets.fromLTRB(22, 30, 22, 28),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (category.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 30, bottom: 8),
                  child: Text(
                    category,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white54,
                    ),
                  ),
                ),
              ],
              if (arabic.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 30),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      arabic,
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
              if (transliteration.isNotEmpty) ...[
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.only(left: 30),
                  child: Text(
                    transliteration,
                    textAlign: TextAlign.left,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
              if (german.isNotEmpty) ...[
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.only(left: 30),
                  child: Text(
                    german,
                    textAlign: TextAlign.left,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      height: 1.55,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ),
              ],
              if (source.isNotEmpty) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(left: 30),
                  child: Text(
                    source,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      height: 1.45,
                      color: Colors.white60,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 22),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 30),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () =>
                            showDuaGuidanceDialog(context, entry: entry),
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
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 12,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 16,
                                  color: _accentChampagneGold.withOpacity(0.92),
                                ),
                                const SizedBox(width: 9),
                                Text(
                                  'Hinweise',
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
                  ),
                  if (onBookmarkTap != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 2),
                      child: SizedBox(
                        width: 32,
                        height: 32,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          icon: Icon(
                            isBookmarked
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            size: 22,
                            color: isBookmarked ? Colors.white : Colors.white70,
                          ),
                          onPressed: onBookmarkTap,
                          tooltip: isBookmarked
                              ? 'Aus Favoriten entfernen'
                              : 'Zu Favoriten hinzufügen',
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 2,
            left: 0,
            child: Opacity(
              opacity: 0.65,
              child: _DuaIndexBadge(index: listIndex),
            ),
          ),
        ],
      ),
    );

    if (embedded) return content;

    return GlassCard(
      borderRadius: 22,
      child: content,
    );
  }
}

class _DuaIndexBadge extends StatelessWidget {
  const _DuaIndexBadge({required this.index});

  final int index;

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
        '$index',
        style: GoogleFonts.inter(
          fontSize: index >= 10 ? 7.5 : 8.5,
          fontWeight: FontWeight.w600,
          color: Colors.white.withOpacity(0.42),
        ),
      ),
    );
  }
}
