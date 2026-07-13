import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../design/primary_button.dart';
import '../guide/purification/content/wudu_live_guide_config.dart';
import '../guide/purification/content/wudu_guide_content.dart';
import '../guide/purification/purification_guide_navigation.dart';
import '../guide/wudu/wudu_step.dart';
import '../guide/wudu/wudu_steps_data.dart';
import '../theme/app_theme.dart';
import '../theme/hero_theme.dart';
import '../widgets/glass_card.dart';

const Color _accentChampagneGold = Color(0xFFE5C07B);
const double _outerPadding = 24;

/// Schrittübersicht für den Wudu-Guide.
class WuduOverviewScreen extends StatelessWidget {
  const WuduOverviewScreen({super.key});

  static const List<WuduSection> _sectionOrder = [
    WuduSection.preparation,
    WuduSection.washing,
    WuduSection.completion,
  ];

  static String _sectionTitle(WuduSection section) {
    return switch (section) {
      WuduSection.preparation => WuduGuideContent.sectionPreparation,
      WuduSection.washing => WuduGuideContent.sectionWashing,
      WuduSection.completion => WuduGuideContent.sectionCompletion,
    };
  }

  static List<WuduStep> get _visibleSteps => wuduSteps
      .where((step) => WuduLiveGuideConfig.isStepNumberEnabled(step.order))
      .toList(growable: false);

  void _startGuide(BuildContext context) {
    PurificationGuideNavigation.openWuduLiveGuide(
      context,
      stepNumber: WuduLiveGuideConfig.activeStepNumbers.first,
    );
  }

  void _openStep(BuildContext context, WuduStep step) {
    PurificationGuideNavigation.openWuduStepDetail(context, step.order);
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
          WuduGuideContent.guideAppBarTitle,
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
                        WuduGuideContent.overviewHeadline,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        WuduGuideContent.overviewSubline,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          height: 1.45,
                          color: Colors.white.withOpacity(0.58),
                        ),
                      ),
                      const SizedBox(height: 24),
                      GlassCard(
                        borderRadius: 18,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                WuduGuideContent.overviewCardTitle,
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                WuduGuideContent.overviewStepCountLabel(
                                  WuduLiveGuideConfig.activeStepCount,
                                ),
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withOpacity(0.82),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                WuduGuideContent.overviewDurationHint,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: _accentChampagneGold.withOpacity(0.88),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Align(
                                alignment: Alignment.center,
                                child: PrimaryButton(
                                  label:
                                      WuduGuideContent.overviewStartButtonLabel,
                                  onPressed: () => _startGuide(context),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        WuduGuideContent.overviewAllStepsHeading,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                          color: Colors.white.withOpacity(0.62),
                        ),
                      ),
                      const SizedBox(height: 16),
                      for (var s = 0; s < _sectionOrder.length; s++) ...[
                        if (s > 0) const SizedBox(height: 20),
                        _WuduSectionBlock(
                          title: _sectionTitle(_sectionOrder[s]),
                          steps: _visibleSteps
                              .where((step) => step.section == _sectionOrder[s])
                              .toList(),
                          onStepTap: (step) => _openStep(context, step),
                        ),
                      ],
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

class _WuduSectionBlock extends StatelessWidget {
  const _WuduSectionBlock({
    required this.title,
    required this.steps,
    required this.onStepTap,
  });

  final String title;
  final List<WuduStep> steps;
  final ValueChanged<WuduStep> onStepTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: _accentChampagneGold.withOpacity(0.88),
          ),
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _WuduStepRow(
            step: steps[i],
            onTap: () => onStepTap(steps[i]),
          ),
        ],
      ],
    );
  }
}

class _WuduStepRow extends StatelessWidget {
  const _WuduStepRow({
    required this.step,
    required this.onTap,
  });

  final WuduStep step;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.black.withOpacity(0.16),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                  '${step.order}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.72),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        color: Colors.white.withOpacity(0.92),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      step.overviewText,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        height: 1.35,
                        color: Colors.white.withOpacity(0.55),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: Colors.white.withOpacity(0.38),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
