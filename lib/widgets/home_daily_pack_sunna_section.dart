import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/daily_hadith/daily_hadith_entry.dart';
import '../theme/app_theme.dart';

const Color _accentGoldSunna = Color(0xFFE5C07B);

/// Wie KI-/Gebets-Sheet (`explanation_bottom_sheet`, Home-Gebet).
const double _sunnaSheetTopRadius = 24;

/// Footer-Streifen: zweite Rolle (nicht zweiter Tagesvers); Inhalt im Sheet.
class HomeDailyPackSunnaSection extends StatelessWidget {
  const HomeDailyPackSunnaSection({
    super.key,
    required this.entry,
    this.embedOnHeroGlass = false,
  });

  final DailyHadithEntry entry;
  final bool embedOnHeroGlass;

  @override
  Widget build(BuildContext context) {
    final boxDecoration = embedOnHeroGlass
        ? BoxDecoration(
            color: Colors.white.withOpacity(0.035),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _accentGoldSunna.withOpacity(0.11),
              width: 0.5,
            ),
          )
        : BoxDecoration(
            color: const Color(0xFF0F2A1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _accentGoldSunna.withOpacity(0.16),
              width: 0.5,
            ),
          );

    return Padding(
      padding: EdgeInsets.only(top: embedOnHeroGlass ? 12 : 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openSunnaSheet(context, entry),
          borderRadius: BorderRadius.circular(12),
          splashColor: Colors.white.withOpacity(0.06),
          highlightColor: Colors.white.withOpacity(0.03),
          child: DecoratedBox(
            decoration: boxDecoration,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: _accentGoldSunna.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _accentGoldSunna.withOpacity(0.2),
                        width: 0.5,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.wb_sunny_outlined,
                        size: 15,
                        color: _accentGoldSunna.withOpacity(0.95),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'SUNNA ZUM TAG',
                          style: GoogleFonts.inter(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.05,
                            color: _accentGoldSunna.withOpacity(0.58),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Kurzfassung & Kontext',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  height: 1.3,
                                  color: Colors.white.withOpacity(0.72),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                              color: _accentGoldSunna.withOpacity(0.88),
                            ),
                          ],
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
                                  padding: const EdgeInsets.only(left: 10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'HADITH',
                                        style: GoogleFonts.inter(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.1,
                                          color: _accentGoldSunna.withOpacity(0.7),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        entry.referenceDe,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          height: 1.35,
                                          color: Colors.white.withOpacity(0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => Navigator.pop(ctx),
                                  customBorder: const CircleBorder(),
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.08),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.close_rounded,
                                      size: 18,
                                      color: Colors.white.withOpacity(0.72),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
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
    final hasArabic = e.textAr.trim().isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: _expanded
              ? null
              : () => setState(() => _expanded = true),
          behavior: HitTestBehavior.opaque,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                top: -6,
                child: Text(
                  '"',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 28,
                    fontStyle: FontStyle.italic,
                    height: 1,
                    color: _accentGoldSunna.withOpacity(0.3),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 22, top: 10, right: 4),
                child: Text(
                  e.textDe,
                  maxLines: _expanded ? null : 8,
                  overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 17,
                    fontStyle: FontStyle.italic,
                    height: 1.65,
                    color: Colors.white.withOpacity(0.92),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.07),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'EINORDNUNG',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: _accentGoldSunna.withOpacity(0.55),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  e.einordnungDe,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    height: 1.6,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (hasArabic) ...[
          const SizedBox(height: 14),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Text(
                e.textAr,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                style: GoogleFonts.amiri(
                  fontSize: 15,
                  height: 1.7,
                  color: Colors.white.withOpacity(0.75),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (_expanded)
              TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => setState(() => _expanded = false),
                child: Text(
                  'Weniger anzeigen',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: _accentGoldSunna.withOpacity(0.6),
                  ),
                ),
              )
            else
              const SizedBox.shrink(),
            const Spacer(),
            if (e.sourceUrl != null && e.sourceUrl!.isNotEmpty)
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () async {
                  final uri = Uri.parse(e.sourceUrl!);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                icon: Icon(
                  Icons.open_in_new_rounded,
                  size: 14,
                  color: _accentGoldSunna.withOpacity(0.6),
                ),
                label: Text(
                  'Volltext & Kette',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _accentGoldSunna.withOpacity(0.6),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
