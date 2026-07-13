import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../purification_check_item.dart';
import '../religious_content_copy.dart';
import '../religious_source_reference.dart';
import 'purification_overlay_sheet.dart';

const Color _accentChampagneGold = Color(0xFFE5C07B);

/// Zeigt kompakte Quellen und optionalen Begleittext aus dem Content-Modell.
Future<void> showPurificationSourceSheet(
  BuildContext context, {
  required String title,
  required String body,
  required List<ReligiousSourceReference> sources,
}) {
  return showPurificationOverlaySheet<void>(
    context,
    builder: (context) => _SourceReferenceSheet(
      title: title,
      body: body,
      sources: sources,
    ),
  );
}

Future<void> showPurificationDetailSheet(
  BuildContext context, {
  required PurificationCheckItem item,
}) {
  return showPurificationOverlaySheet<void>(
    context,
    builder: (context) => _SourceReferenceSheet(
      title: item.detailSheetTitle ?? item.title,
      body: item.detailSheetBody ?? item.body,
      sources: const [],
      compact: true,
    ),
  );
}

class _SourceReferenceSheet extends StatelessWidget {
  const _SourceReferenceSheet({
    required this.title,
    required this.body,
    required this.sources,
    this.compact = false,
  });

  final String title;
  final String body;
  final List<ReligiousSourceReference> sources;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return PurificationOverlaySheetShell(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (body.isNotEmpty)
            Text(
              body,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.45,
                color: Colors.white.withValues(alpha: 0.92),
              ),
            ),
          if (!compact && sources.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              ReligiousContentCopy.sourcesSectionTitle,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
                color: _accentChampagneGold.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 8),
            for (final source in sources) ...[
              Text(
                '• ${source.displayLine}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  height: 1.4,
                  color: Colors.white.withValues(alpha: 0.72),
                ),
              ),
              const SizedBox(height: 4),
            ],
          ],
        ],
      ),
    );
  }
}
