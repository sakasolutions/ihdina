import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'glass_card.dart';

/// Kompakte „Weiterlesen“-Karte für die Surenliste (oberhalb der Liste).
class QuranContinueReadingCard extends StatelessWidget {
  const QuranContinueReadingCard({
    super.key,
    required this.surahName,
    required this.ayahNumber,
    required this.onTap,
  });

  final String surahName;
  final int ayahNumber;
  final VoidCallback onTap;

  static const Color _accentGold = Color(0xFFE5C07B);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: Colors.white.withOpacity(0.08),
        highlightColor: Colors.white.withOpacity(0.04),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _accentGold.withOpacity(0.22),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _accentGold.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: GlassCard(
            borderRadius: 20,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    Icons.menu_book_rounded,
                    size: 21,
                    color: _accentGold.withOpacity(0.9),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Weiterlesen',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.85,
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '$surahName · Vers $ayahNumber',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.96),
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Weiter beim letzten Vers',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            height: 1.2,
                            color: Colors.white.withOpacity(0.58),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white.withOpacity(0.4),
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
