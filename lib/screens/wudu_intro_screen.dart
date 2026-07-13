import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../design/primary_button.dart';
import '../guide/wudu_guide_navigation.dart';
import '../theme/app_theme.dart';
import '../theme/hero_theme.dart';
import '../widgets/glass_card.dart';

const Color _accentChampagneGold = Color(0xFFE5C07B);
const double _outerPadding = 24;
const BorderRadius _buttonRadius = BorderRadius.all(Radius.circular(14));

/// Einstieg in den Wudu-Lernkurs (einmalige Einführung, optional überspringen).
class WuduIntroScreen extends StatefulWidget {
  const WuduIntroScreen({super.key});

  @override
  State<WuduIntroScreen> createState() => _WuduIntroScreenState();
}

class _WuduIntroScreenState extends State<WuduIntroScreen> {
  static const List<String> _overviewItems = [
    'Vorbereitung und Absicht',
    'Waschung Schritt für Schritt',
    'Dua nach der Waschung',
    'Kurze Zusammenfassung',
  ];

  bool _skipIntroNextTime = false;

  Future<void> _completeIntro({required bool stepsOverview}) async {
    await WuduGuideNavigation.completeIntroAndNavigate(
      context,
      skipIntroNextTime: _skipIntroNextTime,
      stepsOverview: stepsOverview,
    );
  }

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
          'Gebetswaschung',
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
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Wudu Schritt für Schritt lernen',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Lerne die Gebetswaschung in deinem eigenen Tempo – mit Bildern, kurzen Erklärungen und Audio.',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          height: 1.45,
                          color: Colors.white.withOpacity(0.78),
                        ),
                      ),
                      const SizedBox(height: 24),
                      GlassCard(
                        borderRadius: 18,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Das erwartet dich',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 14),
                              for (var i = 0;
                                  i < _overviewItems.length;
                                  i++) ...[
                                if (i > 0) const SizedBox(height: 10),
                                _OverviewRow(label: _overviewItems[i]),
                              ],
                              const SizedBox(height: 14),
                              Text(
                                'Dauer: ca. 8–10 Minuten',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: _accentChampagneGold.withOpacity(0.88),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.center,
                        child: PrimaryButton(
                          label: 'Guide starten',
                          onPressed: () => _completeIntro(stepsOverview: false),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _WuduGhostButton(
                        label: 'Alle Schritte ansehen',
                        onPressed: () => _completeIntro(stepsOverview: true),
                      ),
                      const SizedBox(height: 16),
                      _SkipIntroCheckbox(
                        value: _skipIntroNextTime,
                        onChanged: (v) =>
                            setState(() => _skipIntroNextTime = v ?? false),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Dieser Guide folgt der hanafitischen Lehrtradition und dient als Lernhilfe. Bei individuellen Fragen wende dich bitte an eine qualifizierte religiöse Anlaufstelle.',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          height: 1.45,
                          color: Colors.white.withOpacity(0.45),
                        ),
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

class _WuduGhostButton extends StatelessWidget {
  const _WuduGhostButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: _buttonRadius,
          splashColor: Colors.white.withOpacity(0.06),
          highlightColor: Colors.white.withOpacity(0.04),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: _buttonRadius,
              color: Colors.black.withOpacity(0.18),
              border: Border.all(
                color: _accentChampagneGold.withOpacity(0.22),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.list_alt_rounded,
                  size: 18,
                  color: Colors.white.withOpacity(0.78),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.88),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: Colors.white.withOpacity(0.45),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SkipIntroCheckbox extends StatelessWidget {
  const _SkipIntroCheckbox({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: value,
                  onChanged: (v) => onChanged(v ?? false),
                  activeColor: _accentChampagneGold,
                  checkColor: AppColors.emeraldDark,
                  side: BorderSide(
                    color: Colors.white.withOpacity(0.35),
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'Beim nächsten Mal direkt zum Guide',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.35,
                      color: Colors.white.withOpacity(0.68),
                    ),
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

class _OverviewRow extends StatelessWidget {
  const _OverviewRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            Icons.check_circle_outline_rounded,
            size: 16,
            color: _accentChampagneGold.withOpacity(0.75),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.35,
              color: Colors.white.withOpacity(0.82),
            ),
          ),
        ),
      ],
    );
  }
}
