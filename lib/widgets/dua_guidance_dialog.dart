import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/dua/dua_entry.dart';
import '../data/dua/dua_guidance_copy.dart';
import '../data/dua/dua_type.dart';
import '../theme/app_theme.dart';

const Color _accentChampagneGold = Color(0xFFE5C07B);

/// Hinweise zu Rezitation, Lautschrift und Anleitung — kompakter Dialog statt Bottom-Sheet.
Future<void> showDuaGuidanceDialog(
  BuildContext context, {
  required DuaEntry entry,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => _DuaGuidanceDialog(entry: entry),
  );
}

class _DuaGuidanceDialog extends StatelessWidget {
  const _DuaGuidanceDialog({required this.entry});

  final DuaEntry entry;

  @override
  Widget build(BuildContext context) {
    final transliteration = entry.transliteration?.trim() ?? '';
    final bodyStyle = GoogleFonts.inter(
      fontSize: 14,
      height: 1.5,
      color: Colors.white.withOpacity(0.88),
    );

    return Dialog(
      backgroundColor: AppColors.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: Colors.white.withOpacity(0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Hinweise',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 14),
            Text(DuaGuidanceCopy.detailRecitation, style: bodyStyle),
            if (transliteration.isEmpty) ...[
              const SizedBox(height: 12),
              Text(DuaGuidanceCopy.detailTransliterationSoon, style: bodyStyle),
            ],
            if (entry.type == DuaType.anleitung) ...[
              const SizedBox(height: 12),
              Text(
                'Anleitung mit eingebettetem Sprechtext — nicht nur eine reine Rezitation.',
                style: bodyStyle.copyWith(
                  color: _accentChampagneGold.withOpacity(0.9),
                ),
              ),
            ],
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Schließen',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: _accentChampagneGold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
