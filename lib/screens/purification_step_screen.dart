import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../design/primary_button.dart';
import '../guide/purification/content/wudu_live_guide_config.dart';
import '../guide/purification/content/wudu_step_contents.dart';
import '../guide/purification/purification_guide_navigation.dart';
import '../guide/purification/purification_step_content.dart';
import '../guide/purification/religious_content_copy.dart';
import '../guide/purification/widgets/purification_check_item_card.dart';
import '../guide/purification/widgets/purification_progress_header.dart';
import '../guide/purification/widgets/religious_content_notice.dart';
import '../guide/purification/widgets/source_reference_sheet.dart';
import '../theme/app_theme.dart';
import '../theme/hero_theme.dart';

const double _outerPadding = 24;
const Color _accentChampagneGold = Color(0xFFE5C07B);

/// Generischer Screen für einen interaktiven Reinigungsschritt.
class PurificationStepScreen extends StatelessWidget {
  const PurificationStepScreen({
    super.key,
    required this.content,
  });

  final PurificationStepContent content;

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
          content.guideAppBarTitle,
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: Semantics(
        namesRoute: true,
        label:
            '${WuduLiveGuideConfig.progressLabel(content.stepNumber)}: ${content.title}',
        child: SizedBox.expand(
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
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(
                            _outerPadding,
                            8,
                            _outerPadding,
                            16,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              PurificationProgressHeader(
                                progressLabel:
                                    WuduLiveGuideConfig.progressLabel(
                                  content.stepNumber,
                                ),
                                stepTitle: content.title,
                                progressValue:
                                    WuduLiveGuideConfig.progressValue(
                                  content.stepNumber,
                                ),
                              ),
                              if (content.categoryLabel != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  content.categoryLabel!,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                    color:
                                        _accentChampagneGold.withOpacity(0.85),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 14),
                              Text(
                                content.introduction,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  height: 1.45,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withOpacity(0.88),
                                ),
                              ),
                              if (content.detailBody != null) ...[
                                const SizedBox(height: 14),
                                Text(
                                  content.detailBody!,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    height: 1.45,
                                    color: Colors.white.withOpacity(0.78),
                                  ),
                                ),
                              ],
                              if (content.memoryAid != null) ...[
                                const SizedBox(height: 18),
                                _MemoryAidCard(text: content.memoryAid!),
                              ],
                              if (content.items.isNotEmpty) ...[
                                const SizedBox(height: 22),
                                for (var i = 0;
                                    i < content.items.length;
                                    i++) ...[
                                  if (i > 0) const SizedBox(height: 10),
                                  PurificationCheckItemCard(
                                    item: content.items[i],
                                    onDetailTap: content.items[i].hasDetailSheet
                                        ? () => showPurificationDetailSheet(
                                              context,
                                              item: content.items[i],
                                            )
                                        : null,
                                  ),
                                ],
                              ],
                              if (content.userVisibleHint != null) ...[
                                const SizedBox(height: 18),
                                ReligiousContentNotice(
                                  message: content.userVisibleHint!,
                                ),
                              ],
                              if (content.userVisibleAttributionNotice !=
                                  null) ...[
                                const SizedBox(height: 22),
                                ReligiousContentNotice(
                                  message:
                                      content.userVisibleAttributionNotice!,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          _outerPadding,
                          8,
                          _outerPadding,
                          16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (content.whyImportantTitle != null)
                              Align(
                                alignment: Alignment.center,
                                child: TextButton(
                                  onPressed: () => showPurificationSourceSheet(
                                    context,
                                    title: content.whyImportantTitle!,
                                    body: content.whyImportantBody ?? '',
                                    sources: content.sources,
                                  ),
                                  child: Text(
                                    content.whyImportantTitle!,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withOpacity(0.72),
                                    ),
                                  ),
                                ),
                              ),
                            if (content.isCompletionStep &&
                                content.secondaryActionLabel != null) ...[
                              PrimaryButton(
                                label: content.primaryActionLabel,
                                onPressed: () => _onPrimaryAction(context),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                              ),
                              const SizedBox(height: 10),
                              PrimaryButton(
                                label: content.secondaryActionLabel!,
                                outlined: true,
                                onPressed: () => _onSecondaryAction(context),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                              ),
                            ] else
                              PrimaryButton(
                                label: content.primaryActionLabel,
                                onPressed: () => _onPrimaryAction(context),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                              ),
                          ],
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
    );
  }

  void _onPrimaryAction(BuildContext context) {
    if (content.isCompletionStep) {
      PurificationGuideNavigation.popToWuduOverview(context);
      return;
    }

    if (content.guideId == PurificationGuideIds.wudu) {
      PurificationGuideNavigation.openNextWuduStep(
        context,
        currentStepNumber: content.stepNumber,
      );
      return;
    }

    PurificationGuideNavigation.openPlaceholder(
      context,
      guideAppBarTitle: content.guideAppBarTitle,
      stepNumber: content.stepNumber + 1,
      totalSteps: content.totalSteps,
      stepTitle: 'Nächster Schritt',
    );
  }

  void _onSecondaryAction(BuildContext context) {
    if (content.isCompletionStep) {
      PurificationGuideNavigation.restartWuduGuideFromOverview(context);
    }
  }
}

class _MemoryAidCard extends StatelessWidget {
  const _MemoryAidCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        color: Colors.white.withOpacity(0.06),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ReligiousContentCopy.memoryAidLabel,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: _accentChampagneGold.withOpacity(0.85),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.4,
              color: Colors.white.withOpacity(0.82),
            ),
          ),
        ],
      ),
    );
  }
}
