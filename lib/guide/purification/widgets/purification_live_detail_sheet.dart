import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../content/wudu_guide_content.dart';
import '../purification_step_content.dart';
import '../widgets/purification_check_item_card.dart';
import '../widgets/purification_overlay_sheet.dart';
import '../widgets/religious_content_notice.dart';
import '../widgets/source_reference_sheet.dart';

const Color _accentChampagneGold = Color(0xFFE5C07B);

/// Ausführliche Lerninhalte für „Mehr dazu“ im Live-Begleitmodus.
Future<void> showPurificationLiveDetailSheet(
  BuildContext context, {
  required PurificationStepContent content,
}) {
  return showPurificationOverlaySheet<void>(
    context,
    builder: (context) => _PurificationLiveDetailSheet(content: content),
  );
}

class _PurificationLiveDetailSheet extends StatelessWidget {
  const _PurificationLiveDetailSheet({required this.content});

  final PurificationStepContent content;

  @override
  Widget build(BuildContext context) {
    return PurificationOverlaySheetShell(
      title: WuduGuideContent.liveMoreLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (content.categoryLabel != null) ...[
            Text(
              content.categoryLabel!,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
                color: _accentChampagneGold.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 14),
          ],
          if (content.detailBody != null) ...[
            Text(
              content.detailBody!,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.45,
                color: Colors.white.withValues(alpha: 0.92),
              ),
            ),
          ],
          if (content.items.isNotEmpty) ...[
            const SizedBox(height: 18),
            for (var i = 0; i < content.items.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              PurificationCheckItemCard(
                item: content.items[i],
                opaqueSurface: true,
                onDetailTap: content.items[i].hasDetailSheet
                    ? () => showPurificationDetailSheet(
                          context,
                          item: content.items[i],
                        )
                    : null,
              ),
            ],
          ],
          if (content.memoryAid != null) ...[
            const SizedBox(height: 16),
            Text(
              'Merksatz',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
                color: _accentChampagneGold.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              content.memoryAid!,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.4,
                color: Colors.white.withValues(alpha: 0.86),
              ),
            ),
          ],
          if (content.userVisibleHint != null) ...[
            const SizedBox(height: 16),
            ReligiousContentNotice(message: content.userVisibleHint!),
          ],
          if (content.whyImportantTitle != null) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => showPurificationSourceSheet(
                context,
                title: content.whyImportantTitle!,
                body: content.whyImportantBody ?? '',
                sources: content.sources,
              ),
              child: Text(
                content.whyImportantTitle == WuduGuideContent.sourcesLinkLabel
                    ? WuduGuideContent.sourcesLinkLabel
                    : content.whyImportantTitle!,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.78),
                ),
              ),
            ),
          ],
          if (content.userVisibleAttributionNotice != null) ...[
            const SizedBox(height: 12),
            ReligiousContentNotice(
              message: content.userVisibleAttributionNotice!,
            ),
          ],
        ],
      ),
    );
  }
}
