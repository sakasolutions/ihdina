import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../design/primary_button.dart';
import '../guide/purification/content/wudu_guide_content.dart';
import '../guide/purification/content/wudu_live_guide_config.dart';
import '../guide/purification/content/wudu_step_contents.dart';
import '../guide/purification/purification_step_content.dart';
import '../guide/purification/widgets/purification_live_detail_sheet.dart';
import '../guide/purification/widgets/purification_live_visual.dart';
import '../guide/purification/widgets/purification_liturgical_text_block.dart';
import '../guide/purification/widgets/purification_guide_text_action.dart';
import '../guide/purification/widgets/purification_live_visual_placeholder.dart';

const Color _accentChampagneGold = Color(0xFFE5C07B);

/// Fokussierter Live-Begleitmodus — ein Schritt, große Texte, scrollbarer Inhalt.
class PurificationLiveGuideScreen extends StatefulWidget {
  const PurificationLiveGuideScreen({
    super.key,
    required this.initialStepNumber,
  });

  final int initialStepNumber;

  @override
  State<PurificationLiveGuideScreen> createState() =>
      _PurificationLiveGuideScreenState();
}

class _PurificationLiveGuideScreenState
    extends State<PurificationLiveGuideScreen> {
  late int _stepNumber;

  @override
  void initState() {
    super.initState();
    _stepNumber =
        WuduLiveGuideConfig.normalizeStepNumber(widget.initialStepNumber);
  }

  PurificationStepContent? get _content =>
      WuduStepContents.byStepNumber(_stepNumber);

  void _close() {
    Navigator.of(context).pop();
  }

  void _goBack() {
    final previous = WuduLiveGuideConfig.previousStepNumber(_stepNumber);
    if (previous == null) return;
    setState(() => _stepNumber = previous);
  }

  void _goForward() {
    final content = _content;
    if (content == null) return;

    if (content.isCompletionStep) {
      _returnToOverview();
      return;
    }

    final next = WuduLiveGuideConfig.nextStepNumber(_stepNumber);
    if (next == null) return;
    setState(() => _stepNumber = next);
  }

  void _restartGuide() {
    setState(() => _stepNumber = WuduLiveGuideConfig.activeStepNumbers.first);
  }

  void _returnToOverview() {
    Navigator.of(context).pop();
  }

  String _primaryLabel(PurificationStepContent content) {
    if (content.isCompletionStep) {
      return content.primaryActionLabel;
    }
    return content.livePresentation?.primaryActionLabel ??
        WuduGuideContent.livePrimaryContinue;
  }

  @override
  Widget build(BuildContext context) {
    final content = _content;
    final media = MediaQuery.of(context);
    final textScale = media.textScaler.scale(1.0).clamp(1.0, 1.4);

    return Semantics(
      namesRoute: true,
      label: content?.title ?? 'Wudu-Begleiter',
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _close,
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: ColoredBox(
                      color: Colors.black.withValues(alpha: 0.48),
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 440,
                      maxHeight: media.size.height * 0.88,
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final cardHeight =
                            constraints.maxHeight.clamp(380.0, 680.0);
                        return SizedBox(
                          height: cardHeight,
                          width: constraints.maxWidth,
                          child: content == null ||
                                  content.livePresentation == null
                              ? _UnavailableStepCard(onClose: _close)
                              : _LiveStepCard(
                                  content: content,
                                  textScale: textScale,
                                  onClose: _close,
                                  onBack: _goBack,
                                  onMore: () => showPurificationLiveDetailSheet(
                                    context,
                                    content: content,
                                  ),
                                  onPrimary: _goForward,
                                  onSecondary: content.isCompletionStep
                                      ? _restartGuide
                                      : null,
                                  primaryLabel: _primaryLabel(content),
                                  showBack:
                                      WuduLiveGuideConfig.previousStepNumber(
                                            _stepNumber,
                                          ) !=
                                          null,
                                ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveStepCard extends StatelessWidget {
  const _LiveStepCard({
    required this.content,
    required this.textScale,
    required this.onClose,
    required this.onBack,
    required this.onMore,
    required this.onPrimary,
    required this.primaryLabel,
    required this.showBack,
    this.onSecondary,
  });

  final PurificationStepContent content;
  final double textScale;
  final VoidCallback onClose;
  final VoidCallback onBack;
  final VoidCallback onMore;
  final VoidCallback onPrimary;
  final String primaryLabel;
  final bool showBack;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final live = content.livePresentation!;
    final progress = WuduLiveGuideConfig.progressValue(content.stepNumber) ?? 0;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: purificationLiveCardColor(),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          WuduLiveGuideConfig.progressLabel(content.stepNumber),
                          style: GoogleFonts.inter(
                            fontSize: 12 * textScale,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.58),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            minHeight: 3,
                            value: progress,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.08),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _accentChampagneGold.withValues(alpha: 0.75),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: WuduGuideContent.liveCloseTooltip,
                    onPressed: onClose,
                    icon: Icon(
                      Icons.close_rounded,
                      color: Colors.white.withValues(alpha: 0.72),
                    ),
                  ),
                ],
              ),
              if (live.sectionLabel != null) ...[
                const SizedBox(height: 4),
                Text(
                  live.sectionLabel!,
                  style: GoogleFonts.inter(
                    fontSize: 11 * textScale,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: _accentChampagneGold.withValues(alpha: 0.85),
                  ),
                ),
              ],
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final visualHeight = purificationLiveVisualHeight(
                      presentation: live,
                      maxHeight: constraints.maxHeight,
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (visualHeight > 0) ...[
                          SizedBox(
                            height: visualHeight,
                            child: PurificationLiveVisual(
                              presentation: live,
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        Expanded(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.zero,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight - visualHeight,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    content.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.playfairDisplay(
                                      fontSize: 24 * textScale,
                                      fontWeight: FontWeight.w600,
                                      height: 1.15,
                                      color: Colors.white,
                                    ),
                                  ),
                                  if (content.liturgicalTexts.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    PurificationLiturgicalTextList(
                                      texts: content.liturgicalTexts,
                                      textScale: textScale,
                                      compact: true,
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Text(
                                    live.actionText,
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 17 * textScale,
                                      height: 1.35,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          Colors.white.withValues(alpha: 0.94),
                                    ),
                                  ),
                                  if (live.attentionText != null &&
                                      live.attentionText!.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      live.attentionText!,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 14 * textScale,
                                        height: 1.4,
                                        color: Colors.white
                                            .withValues(alpha: 0.72),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: primaryLabel,
                onPressed: onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
              if (onSecondary != null &&
                  content.secondaryActionLabel != null) ...[
                const SizedBox(height: 10),
                PrimaryButton(
                  label: content.secondaryActionLabel!,
                  outlined: true,
                  onPressed: onSecondary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Center(
                child: PurificationGuideTextAction(
                  label: WuduGuideContent.liveMoreLabel,
                  onPressed: onMore,
                ),
              ),
              if (showBack) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: onBack,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white.withValues(alpha: 0.62),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                    ),
                    child: Text(
                      WuduGuideContent.liveBackLabel,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _UnavailableStepCard extends StatelessWidget {
  const _UnavailableStepCard({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: purificationLiveCardColor(),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
            Text(
              'Dieser Schritt ist im Live-Begleiter noch nicht verfügbar.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.82),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
