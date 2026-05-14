import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/daily_hadith/daily_hadith_entry.dart';
import 'glass_card.dart';

/// Auf `false` setzen, um die Hadith-Karte auf dem Home-Screen auszublenden (ohne Daten zu löschen).
const bool kShowDailyHadithOnHome = true;

/// Block unter dem Tagesvers: Einordnung (redaktionell) + Kurzfassung + optional Arabisch.
class HomeDailyHadithCard extends StatelessWidget {
  const HomeDailyHadithCard({super.key, required this.entry});

  final DailyHadithEntry entry;

  static const Color _accentGold = Color(0xFFE5C07B);

  @override
  Widget build(BuildContext context) {
    final hasEinordnung = entry.einordnungDe.trim().isNotEmpty;

    return GlassCard(
      borderRadius: 20,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.format_quote_rounded, size: 20, color: _accentGold.withOpacity(0.85)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sunna · zum Mitnehmen',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.1,
                      color: Colors.white.withOpacity(0.42),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              entry.referenceDe,
              style: GoogleFonts.playfairDisplay(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.95),
              ),
            ),
            if (hasEinordnung) ...[
              const SizedBox(height: 12),
              Text(
                'Einordnung',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.05,
                  color: Colors.white.withOpacity(0.38),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                entry.einordnungDe,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  height: 1.45,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withOpacity(0.78),
                ),
              ),
            ],
            const SizedBox(height: 14),
            Divider(height: 1, thickness: 1, color: Colors.white.withOpacity(0.08)),
            const SizedBox(height: 12),
            Text(
              'Kurzfassung der Überlieferung',
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.05,
                color: Colors.white.withOpacity(0.38),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              entry.textDe,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 14.5,
                height: 1.48,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            if (entry.textAr.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                entry.textAr,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.amiri(
                  fontSize: 15,
                  height: 1.55,
                  color: Colors.white.withOpacity(0.82),
                ),
              ),
            ],
            if (entry.sourceUrl != null && entry.sourceUrl!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () async {
                    final uri = Uri.parse(entry.sourceUrl!);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: Icon(Icons.open_in_new_rounded, size: 14, color: _accentGold.withOpacity(0.9)),
                  label: Text(
                    'Volltext & Kette nachlesen',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _accentGold.withOpacity(0.95),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
