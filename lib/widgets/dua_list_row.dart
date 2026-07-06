import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/dua/dua_entry.dart';

const Color _accentChampagneGold = Color(0xFFE5C07B);

String duaGermanPreview(String german, {int maxLength = 55}) {
  final text = german.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (text.length <= maxLength) return text;
  return '${text.substring(0, maxLength).trimRight()}…';
}

/// Kompakte Listenzeile für Duas (Kategorie-Liste oder Favoriten).
class DuaListRow extends StatelessWidget {
  const DuaListRow({
    super.key,
    required this.entry,
    required this.listIndex,
    required this.onTap,
    this.isBookmarked = false,
  });

  final DuaEntry entry;
  final int listIndex;
  final VoidCallback onTap;
  final bool isBookmarked;

  @override
  Widget build(BuildContext context) {
    final preview = duaGermanPreview(entry.german);
    final category = entry.category.trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.25),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isBookmarked
                  ? _accentChampagneGold.withOpacity(0.2)
                  : Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.25),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '$listIndex',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: listIndex >= 10 ? 15 : 18,
                      fontWeight: FontWeight.w700,
                      color: _accentChampagneGold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        preview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                          color: Colors.white,
                        ),
                      ),
                      if (category.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isBookmarked)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      Icons.bookmark_rounded,
                      size: 18,
                      color: _accentChampagneGold.withOpacity(0.85),
                    ),
                  ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white54,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
