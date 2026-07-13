import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import '../theme/hero_theme.dart';
import '../widgets/glass_card.dart';
import 'prayer_purification_screen.dart';

const Color _accentChampagneGold = Color(0xFFE5C07B);
const Color _guideProminentGold = Color(0xFFEBC980);
const double _outerPadding = 24;
const double _sectionGap = 20;

/// Einstieg in den Gebets-Guide: Reinigung und Gebet (Platzhalter).
class PrayerGuideScreen extends StatelessWidget {
  const PrayerGuideScreen({super.key});

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
          'Gebets-Guide',
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
                        'Waschung und Gebet Schritt für Schritt lernen',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Dieser Guide folgt der hanafitischen Lehrtradition.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          height: 1.45,
                          color: Colors.white.withOpacity(0.58),
                        ),
                      ),
                      const SizedBox(height: 28),
                      _GuideSectionCard(
                        title: 'Reinigung',
                        subtitle: 'Gebetswaschung, Ghusl und Tayammum',
                        previewLine: 'Wudu · Ghusl · Tayammum',
                        icon: Icons.water_drop_outlined,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const PrayerPurificationScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      _GuideSectionCard(
                        title: 'Gebet',
                        subtitle:
                            'Bewegungen, Texte und die fünf täglichen Gebete',
                        previewLine: 'Grundlagen · Audio · Fard · Sunnah',
                        icon: Icons.mosque_outlined,
                        onTap: () => debugPrint('Gebets-Guide: Gebet geöffnet'),
                      ),
                      const SizedBox(height: 32),
                      const _GuideHowItWorksSection(),
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

class _GuideHowItWorksSection extends StatelessWidget {
  const _GuideHowItWorksSection();

  static const List<({IconData icon, String label})> _steps = [
    (icon: Icons.touch_app_outlined, label: 'Schritt auswählen'),
    (icon: Icons.play_circle_outline_rounded, label: 'Bild und Audio folgen'),
    (icon: Icons.schedule_outlined, label: 'Im eigenen Tempo üben'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'So funktioniert der Guide',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
            color: Colors.white.withOpacity(0.62),
          ),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < _steps.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _GuideHowItWorksRow(
            stepNumber: i + 1,
            icon: _steps[i].icon,
            label: _steps[i].label,
          ),
        ],
      ],
    );
  }
}

class _GuideHowItWorksRow extends StatelessWidget {
  const _GuideHowItWorksRow({
    required this.stepNumber,
    required this.icon,
    required this.label,
  });

  final int stepNumber;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.06),
            border: Border.all(
              color: _accentChampagneGold.withOpacity(0.22),
            ),
          ),
          child: Text(
            '$stepNumber',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.72),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Icon(
          icon,
          size: 18,
          color: Colors.white.withOpacity(0.4),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.35,
              color: Colors.white.withOpacity(0.68),
            ),
          ),
        ),
      ],
    );
  }
}

class _GuideSectionCard extends StatelessWidget {
  const _GuideSectionCard({
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
