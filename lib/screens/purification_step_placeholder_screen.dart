import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import '../theme/hero_theme.dart';
import '../widgets/glass_card.dart';

const double _outerPadding = 24;

/// Platzhalter für noch nicht implementierte Reinigungsschritte (Entwicklung).
class PurificationStepPlaceholderScreen extends StatelessWidget {
  const PurificationStepPlaceholderScreen({
    super.key,
    required this.guideAppBarTitle,
    required this.stepNumber,
    required this.totalSteps,
    required this.stepTitle,
  });

  final String guideAppBarTitle;
  final int stepNumber;
  final int totalSteps;
  final String stepTitle;

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
          guideAppBarTitle,
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: SizedBox.expand(
        child: Container(
          decoration: const BoxDecoration(gradient: AppColors.mainGradient),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: 0.1,
                  child: Image.asset(
                    DynamicHeroTheme.backgroundAsset(heroPhase),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    _outerPadding,
                    24,
                    _outerPadding,
                    32,
                  ),
                  child: GlassCard(
                    borderRadius: 18,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Schritt $stepNumber von $totalSteps',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.55),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            stepTitle,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Der nächste Schritt wird gerade vorbereitet.',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              height: 1.45,
                              color: Colors.white.withOpacity(0.78),
                            ),
                          ),
                        ],
                      ),
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
