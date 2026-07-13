import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';
import '../purification_check_item.dart';
import '../religious_liturgical_text.dart';
import 'purification_liturgical_text_block.dart';
import 'purification_overlay_sheet.dart';

const Color _accentChampagneGold = Color(0xFFE5C07B);

class PurificationCheckItemCard extends StatelessWidget {
  const PurificationCheckItemCard({
    super.key,
    required this.item,
    this.onDetailTap,
    this.opaqueSurface = false,
  });

  final PurificationCheckItem item;
  final VoidCallback? onDetailTap;
  final bool opaqueSurface;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: opaqueSurface
            ? purificationOverlayInnerCardColor()
            : Colors.black.withValues(alpha: 0.16),
        border: Border.all(
          color: opaqueSurface
              ? AppColors.cardBorder.withValues(alpha: 0.28)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (item.liturgicalText != null) ...[
            PurificationLiturgicalTextBlock(
              text: item.liturgicalText!,
              compact: true,
              arabicFontSize: 24,
            ),
            const SizedBox(height: 12),
          ] else ...[
            Text(
              item.title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.92),
              ),
            ),
            const SizedBox(height: 6),
          ],
          Text(
            item.body,
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.42,
              color: Colors.white.withOpacity(0.72),
            ),
          ),
          if (item.hasDetailSheet && onDetailTap != null) ...[
            const SizedBox(height: 10),
            TextButton(
              onPressed: onDetailTap,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                item.detailActionLabel!,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _accentChampagneGold.withOpacity(0.92),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
