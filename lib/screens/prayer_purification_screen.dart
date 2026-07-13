import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../theme/hero_theme.dart';
import '../guide/wudu_guide_navigation.dart';
import '../widgets/glass_card.dart';

const Color _accentChampagneGold = Color(0xFFE5C07B);
const Color _guideProminentGold = Color(0xFFEBC980);
const double _outerPadding = 24;

/// Unterseite Reinigung: Wudu, Ghusl und Tayammum (Platzhalter).
class PrayerPurificationScreen extends StatelessWidget {
  const PrayerPurificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const heroPhase = HeroPhase.day;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Reinigung',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: SizedBox.expand(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: AppColors.mainGradient,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: 0.1,
                  child: Image.asset(
                    DynamicHeroTheme.backgroundAsset(heroPhase),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    _outerPadding,
                    8,
                    _outerPadding,
                    32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Schritt für Schritt zur rituellen Reinigung',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Die Inhalte folgen der hanafitischen Lehrtradition und dienen als Lernhilfe.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          height: 1.45,
                          color: Colors.white.withOpacity(0.58),
                        ),
                      ),
                      const SizedBox(height: 28),
                      _PurificationTopicCard(
                        title: 'Gebetswaschung',
                        subtitle: 'Wudu Schritt für Schritt lernen',
                        previewLine:
                            'Vorbereitung · Reihenfolge · Dua · Bilder · Audio',
                        icon: Icons.water_drop_outlined,
                        onTap: () => WuduGuideNavigation.openWuduEntry(context),
                      ),
                      const SizedBox(height: 14),
                      _PurificationTopicCard(
                        title: 'Ghusl',
                        subtitle: 'Die Ganzkörperwaschung lernen',
                        previewLine: 'Voraussetzungen · Ablauf · Hinweise',
                        icon: Icons.shower_outlined,
                        onTap: () => debugPrint('Gebets-Guide: Ghusl geöffnet'),
                      ),
                      const SizedBox(height: 14),
                      _PurificationTopicCard(
                        title: 'Tayammum',
                        subtitle: 'Rituelle Reinigung ohne Wasser',
                        previewLine: 'Wann · Vorbereitung · Ablauf',
                        icon: Icons.landscape_outlined,
                        onTap: () =>
                            debugPrint('Gebets-Guide: Tayammum geöffnet'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PurificationTopicCard extends StatelessWidget {
  const _PurificationTopicCard({
    required this.title,
    required this.subtitle,
    required this.previewLine,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String previewLine;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: GlassCard(
          borderRadius: 20,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _accentChampagneGold.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _guideProminentGold.withOpacity(0.45),
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: _guideProminentGold,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            subtitle,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              height: 1.35,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.88),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 24,
                      color: Colors.white.withOpacity(0.45),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  previewLine,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    height: 1.4,
                    letterSpacing: 0.1,
                    color: Colors.white.withOpacity(0.52),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
