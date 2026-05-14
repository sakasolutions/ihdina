import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/daily_hadith/daily_hadith_entry.dart';
import '../theme/app_theme.dart';

const Color _accentGoldSunna = Color(0xFFE5C07B);

/// Wie KI-/Gebets-Sheet (`explanation_bottom_sheet`, Home-Gebet).
const double _sunnaSheetTopRadius = 24;

/// Kompakte Sunna-Zeile in der Tagespaket-Karte; Details im Bottom Sheet (Tier‑1, weniger Lärm).
class HomeDailyPackSunnaSection extends StatelessWidget {
  const HomeDailyPackSunnaSection({super.key, required this.entry});

  final DailyHadithEntry entry;

  @override
  Widget build(BuildContext context) {
    final e = entry;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Divider(height: 1, thickness: 1, color: Colors.white.withOpacity(0.08)),
        ),
        const SizedBox(height: 14),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openSunnaSheet(context, e),
            borderRadius: BorderRadius.circular(18),
            splashColor: Colors.white.withOpacity(0.06),
            highlightColor: Colors.white.withOpacity(0.03),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 10, 4, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.wb_sunny_outlined,
                        size: 20,
                        color: _accentGoldSunna.withOpacity(0.9),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Hadith zum Mitnehmen',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.15,
                            color: Colors.white.withOpacity(0.4),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (e.textDe.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      e.textDe.trim(),
                      textAlign: TextAlign.left,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        height: 1.48,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Quelle, Kontext & Arabisch',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: _accentGoldSunna.withOpacity(0.95),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 10,
                        color: _accentGoldSunna.withOpacity(0.85),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

Future<void> _openSunnaSheet(BuildContext context, DailyHadithEntry entry) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: false,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.transparent,
    builder: (ctx) {
      final media = MediaQuery.of(ctx);
      final h = media.size.height;
      final bottomInset = media.padding.bottom;
      final keyboardBottom = media.viewInsets.bottom;
      final maxScrollRegion = h * 0.62;
      final sheetTint = Color.lerp(
        AppColors.emeraldDark,
        Colors.black,
        0.28,
      )!.withOpacity(0.93);

      return SizedBox(
        height: h,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.pop(ctx),
                child: ColoredBox(
                  color: Colors.black.withOpacity(0.35),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 8 + bottomInset + keyboardBottom,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(_sunnaSheetTopRadius),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    decoration: BoxDecoration(
                      color: sheetTint,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(_sunnaSheetTopRadius),
                      ),
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withOpacity(0.28),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 14,
                        right: 14,
                        top: 12,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 8),
                          Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.45),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 10, top: 2),
                                  child: Text(
                                    'Sunna heute',
                                    style: GoogleFonts.playfairDisplay(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withOpacity(0.96),
                                      height: 1.2,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                onPressed: () => Navigator.pop(ctx),
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: Colors.white.withOpacity(0.72),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ConstrainedBox(
                            constraints: BoxConstraints(maxHeight: maxScrollRegion),
                            child: CustomScrollView(
                              shrinkWrap: true,
                              physics: const BouncingScrollPhysics(),
                              slivers: [
                                SliverPadding(
                                  padding: const EdgeInsets.fromLTRB(10, 14, 10, 18),
                                  sliver: SliverToBoxAdapter(
                                    child: _HomeDailySunnaSheetBody(entry: entry),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _HomeDailySunnaSheetBody extends StatefulWidget {
  const _HomeDailySunnaSheetBody({required this.entry});

  final DailyHadithEntry entry;

  @override
  State<_HomeDailySunnaSheetBody> createState() => _HomeDailySunnaSheetBodyState();
}

class _HomeDailySunnaSheetBodyState extends State<_HomeDailySunnaSheetBody> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Quelle',
          style: GoogleFonts.inter(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: _accentGoldSunna.withOpacity(0.88),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          e.referenceDe,
          style: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.94),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Einordnung',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
            color: Colors.white.withOpacity(0.4),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          e.einordnungDe,
          maxLines: _expanded ? 24 : 3,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 14,
            height: 1.45,
            color: Colors.white.withOpacity(0.78),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Kurzfassung',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
            color: Colors.white.withOpacity(0.4),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          e.textDe,
          maxLines: _expanded ? 32 : 5,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 15,
            height: 1.48,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        if (_expanded && e.textAr.trim().isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            e.textAr,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: GoogleFonts.amiri(
              fontSize: 17,
              height: 1.55,
              color: Colors.white.withOpacity(0.86),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => setState(() => _expanded = !_expanded),
            child: Text(
              _expanded ? 'Weniger anzeigen' : 'Mehr anzeigen (Arabisch)',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _accentGoldSunna.withOpacity(0.95),
              ),
            ),
          ),
        ),
        if (e.sourceUrl != null && e.sourceUrl!.isNotEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () async {
                final uri = Uri.parse(e.sourceUrl!);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              icon: Icon(Icons.open_in_new_rounded, size: 16, color: _accentGoldSunna.withOpacity(0.9)),
              label: Text(
                'Volltext & Kette',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _accentGoldSunna.withOpacity(0.95),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
