import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../religious_content_copy.dart';
import '../../../theme/app_theme.dart';

const Color _accentChampagneGold = Color(0xFFE5C07B);

/// Nahezu blickdichte Kartenfarbe für Purification-Detail-Overlays (Dark Mode).
Color purificationOverlayCardColor() {
  return Color.lerp(
    AppColors.emeraldDark,
    const Color(0xFF040404),
    0.9,
  )!;
}

/// Leicht abgesetzte Innenfläche für Karten innerhalb eines Overlays.
Color purificationOverlayInnerCardColor() {
  return Color.lerp(
    AppColors.emeraldDark,
    const Color(0xFF0A0A0A),
    0.78,
  )!;
}

/// Blickdichte Karte mit Emerald-Unterton — kein Glassmorphism-Durchscheinen.
class PurificationOverlayCard extends StatelessWidget {
  const PurificationOverlayCard({
    super.key,
    required this.child,
    this.borderRadius = 20,
  });

  final Widget child;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: purificationOverlayCardColor(),
        border: Border.all(
          color: AppColors.cardBorder.withValues(alpha: 0.42),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.58),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: child,
      ),
    );
  }
}

/// Gemeinsamer Modal-Bottom-Sheet-Einstieg mit abgedunkeltem Hintergrund.
Future<T?> showPurificationOverlaySheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.68),
    isScrollControlled: true,
    useSafeArea: true,
    builder: builder,
  );
}

/// Feste Kopfzeile + scrollbarer Inhalt für Purification-Detail-Overlays.
class PurificationOverlaySheetShell extends StatelessWidget {
  const PurificationOverlaySheetShell({
    super.key,
    required this.title,
    required this.child,
    this.maxHeightFraction = 0.78,
  });

  final String title;
  final Widget child;
  final double maxHeightFraction;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * maxHeightFraction;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottom),
      child: PurificationOverlayCard(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 4, 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: ReligiousContentCopy.sourceSheetCloseLabel,
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close_rounded,
                        color: _accentChampagneGold.withValues(alpha: 0.92),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(
                height: 1,
                thickness: 1,
                color: Color(0x1AFFFFFF),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
