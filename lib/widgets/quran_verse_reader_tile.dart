import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/verse.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

/// Anzeigemodus der Karten-Kachel: Tap-Cycle im Inhaltsbereich.
enum VerseCardContentMode {
  arabicAndGerman,
  arabicAndTransliteration,
  transliterationAndGerman,
}

/// Nächster globaler Modus (immer Zyklus durch alle drei).
VerseCardContentMode nextVerseCardContentMode(VerseCardContentMode current) {
  final values = VerseCardContentMode.values;
  return values[(values.indexOf(current) + 1) % values.length];
}

/// Vers-Kachel im Karten-Lesemodus: Arabisch / Lautschrift / Deutsch per Tap-Cycle.
class QuranVerseReaderTile extends StatelessWidget {
  const QuranVerseReaderTile({
    super.key,
    required this.verse,
    required this.contentMode,
    required this.contentModeRevision,
    required this.animateFlip,
    required this.onContentModeTap,
    required this.isBookmarked,
    required this.arabicFontSize,
    required this.arabicLineHeight,
    required this.isPlaying,
    required this.isLoading,
    required this.showJumpHighlight,
    required this.onVerstehenTap,
    required this.onBookmarkTap,
    required this.onPlayTap,
  });

  final Verse verse;
  final VerseCardContentMode contentMode;
  final int contentModeRevision;
  final bool animateFlip;
  final VoidCallback onContentModeTap;
  final bool isBookmarked;
  final double arabicFontSize;
  final double arabicLineHeight;
  final bool isPlaying;
  final bool isLoading;
  final bool showJumpHighlight;
  final VoidCallback onVerstehenTap;
  final VoidCallback onBookmarkTap;
  final VoidCallback onPlayTap;

  static const Color _accentChampagneGold = Color(0xFFE5C07B);
  static const List<VerseCardContentMode> _allModes = VerseCardContentMode.values;

  @override
  Widget build(BuildContext context) {
    final audioActive = isPlaying || isLoading;
    final framed = audioActive || showJumpHighlight;
    final arabicHeight = (arabicLineHeight + 0.12).clamp(1.75, 2.35);

    Widget card = animateFlip
        ? _FlippingCardPanel(
            key: ValueKey('flip-card-${verse.ayah}'),
            mode: contentMode,
            modeRevision: contentModeRevision,
            onContentTap: onContentModeTap,
            cardFaceBuilder: (displayMode, onContentTap) => _buildCardFace(
              mode: displayMode,
              arabicHeight: arabicHeight,
              onContentTap: onContentTap,
            ),
          )
        : _buildCardFace(
            mode: contentMode,
            arabicHeight: arabicHeight,
            onContentTap: onContentModeTap,
          );

    if (!framed) {
      return card;
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: _accentChampagneGold.withOpacity(0.042),
        border: Border.all(
          color: _accentChampagneGold.withOpacity(0.22),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _accentChampagneGold.withOpacity(0.08),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: card,
    );
  }

  Widget _buildCardFace({
    required VerseCardContentMode mode,
    required double arabicHeight,
    required VoidCallback onContentTap,
  }) {
    return GlassCard(
      borderRadius: 22,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 30, 22, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onContentTap,
                splashColor: Colors.white.withOpacity(0.06),
                highlightColor: Colors.white.withOpacity(0.03),
                child: _VerseCardContentPanel(
                  verse: verse,
                  mode: mode,
                  arabicFontSize: arabicFontSize,
                  arabicHeight: arabicHeight,
                  availableModes: _allModes,
                ),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onVerstehenTap,
                    borderRadius: BorderRadius.circular(14),
                    splashColor: Colors.white.withOpacity(0.06),
                    highlightColor: Colors.white.withOpacity(0.04),
                    child: Ink(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: Colors.white.withOpacity(0.045),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.09),
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 16,
                              color: _accentChampagneGold.withOpacity(0.92),
                            ),
                            const SizedBox(width: 9),
                            Text(
                              'Verstehen',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.15,
                                color: Colors.white.withOpacity(0.82),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                _playBookmarkRow(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _playBookmarkRow() {
    return SizedBox(
      height: 32,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: isLoading
                ? Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _accentChampagneGold,
                      ),
                    ),
                  )
                : Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onPlayTap,
                      customBorder: const CircleBorder(),
                      splashColor: Colors.white.withOpacity(0.14),
                      highlightColor: Colors.white.withOpacity(0.06),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isPlaying
                              ? _accentChampagneGold.withOpacity(0.11)
                              : Colors.transparent,
                          border: isPlaying
                              ? Border.all(
                                  color: _accentChampagneGold.withOpacity(0.36),
                                  width: 1,
                                )
                              : null,
                          boxShadow: isPlaying
                              ? [
                                  BoxShadow(
                                    color: _accentChampagneGold.withOpacity(0.12),
                                    blurRadius: 6,
                                    spreadRadius: 0,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          isPlaying
                              ? Icons.stop_circle_outlined
                              : Icons.play_circle_outline_rounded,
                          size: 24,
                          color: isPlaying
                              ? _accentChampagneGold
                              : AppColors.emeraldLight,
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 28,
            height: 28,
            child: IconButton(
              icon: Icon(
                isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                size: 20,
                color: isBookmarked ? Colors.white : Colors.white70,
              ),
              onPressed: onBookmarkTap,
              padding: EdgeInsets.zero,
              style: IconButton.styleFrom(
                minimumSize: const Size(28, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Wechselt die komplette [GlassCard] per Pseudo-Flip (scaleX, kein 3D-Ghost).
class _FlippingCardPanel extends StatefulWidget {
  const _FlippingCardPanel({
    super.key,
    required this.mode,
    required this.modeRevision,
    required this.onContentTap,
    required this.cardFaceBuilder,
  });

  final VerseCardContentMode mode;
  final int modeRevision;
  final VoidCallback onContentTap;
  final Widget Function(VerseCardContentMode mode, VoidCallback onContentTap) cardFaceBuilder;

  @override
  State<_FlippingCardPanel> createState() => _FlippingCardPanelState();
}

class _FlippingCardPanelState extends State<_FlippingCardPanel>
    with SingleTickerProviderStateMixin {
  static const Duration _flipDuration = Duration(milliseconds: 300);

  late final AnimationController _controller;
  late final Animation<double> _progress;
  int _handledRevision = 0;
  bool _tapLocked = false;
  Widget? _fromFace;
  Widget? _toFace;

  @override
  void initState() {
    super.initState();
    _handledRevision = widget.modeRevision;
    _controller = AnimationController(vsync: this, duration: _flipDuration);
    _progress = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.addStatusListener(_onAnimationStatus);
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
      if (mounted) setState(() => _tapLocked = false);
    }
  }

  void _startFlip(VerseCardContentMode fromMode, VerseCardContentMode toMode) {
    _fromFace = widget.cardFaceBuilder(fromMode, _handleContentTap);
    _toFace = widget.cardFaceBuilder(toMode, _handleContentTap);
    _tapLocked = true;
    _controller
      ..stop()
      ..reset()
      ..forward();
    Future<void>.delayed(_flipDuration + const Duration(milliseconds: 80), () {
      if (mounted) setState(() => _tapLocked = false);
    });
  }

  @override
  void didUpdateWidget(covariant _FlippingCardPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.modeRevision != _handledRevision) {
      _handledRevision = widget.modeRevision;
      if (oldWidget.mode != widget.mode) {
        _startFlip(oldWidget.mode, widget.mode);
      }
    } else if (oldWidget.mode != widget.mode && !_controller.isAnimating) {
      _fromFace = widget.cardFaceBuilder(widget.mode, _handleContentTap);
      _toFace = _fromFace;
      _controller.value = 0;
    }
  }

  void _handleContentTap() {
    if (_tapLocked) return;
    widget.onContentTap();
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onAnimationStatus);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fromFace = _fromFace ?? widget.cardFaceBuilder(widget.mode, _handleContentTap);
    final toFace = _toFace ?? fromFace;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _progress,
        builder: (context, _) {
          final t = _progress.value;
          final pastHalf = t >= 0.5;
          final scaleX = (pastHalf ? (t - 0.5) * 2 : (1 - t * 2)).clamp(0.0, 1.0);
          // Bei schmaler Card zusätzlich ausblenden — verhindert milchigen Streifen
          // aus der halbtransparenten GlassCard in der Drehmitte.
          final face = pastHalf ? toFace : fromFace;

          return ClipRect(
            child: Opacity(
              opacity: scaleX,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()..scale(scaleX == 0 ? 0.001 : scaleX, 1.0, 1.0),
                child: face,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _VerseCardContentPanel extends StatelessWidget {
  const _VerseCardContentPanel({
    required this.verse,
    required this.mode,
    required this.arabicFontSize,
    required this.arabicHeight,
    required this.availableModes,
  });

  final Verse verse;
  final VerseCardContentMode mode;
  final double arabicFontSize;
  final double arabicHeight;
  final List<VerseCardContentMode> availableModes;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ..._VerseCardContent.buildBlocks(
              verse: verse,
              mode: mode,
              arabicFontSize: arabicFontSize,
              arabicHeight: arabicHeight,
            ),
            const SizedBox(height: 14),
            _ModeDots(
              activeMode: mode,
              availableModes: availableModes,
            ),
          ],
        ),
        Positioned(
          top: 2,
          left: 0,
          child: Opacity(
            opacity: 0.65,
            child: _AyahBadge(ayah: verse.ayah),
          ),
        ),
      ],
    );
  }
}

abstract final class _VerseCardContent {
  static List<Widget> buildBlocks({
    required Verse verse,
    required VerseCardContentMode mode,
    required double arabicFontSize,
    required double arabicHeight,
  }) {
    final transliteration = verse.transliteration?.trim() ?? '';
    final german = verse.de.trim();
    final hasTransliteration = transliteration.isNotEmpty;
    final hasGerman = german.isNotEmpty;

    switch (mode) {
      case VerseCardContentMode.arabicAndGerman:
        return [
          _arabicBlock(verse.ar, arabicFontSize, arabicHeight),
          if (hasGerman) ...[
            const SizedBox(height: 20),
            _germanBlock(german),
          ],
        ];
      case VerseCardContentMode.arabicAndTransliteration:
        return [
          _arabicBlock(verse.ar, arabicFontSize, arabicHeight),
          if (hasTransliteration) ...[
            const SizedBox(height: 20),
            _transliterationBlock(transliteration),
          ],
        ];
      case VerseCardContentMode.transliterationAndGerman:
        return [
          if (hasTransliteration) _transliterationBlock(transliteration),
          if (hasGerman) ...[
            if (hasTransliteration) const SizedBox(height: 20),
            _germanBlock(german),
          ],
        ];
    }
  }

  static Widget _arabicBlock(String ar, double arabicFontSize, double arabicHeight) {
    return Padding(
      padding: const EdgeInsets.only(left: 30),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Text(
          ar,
          textAlign: TextAlign.right,
          style: GoogleFonts.amiri(
            fontSize: arabicFontSize,
            height: arabicHeight,
            letterSpacing: 0.4,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  static Widget _transliterationBlock(String text) {
    return Text(
      text,
      textAlign: TextAlign.left,
      style: GoogleFonts.inter(
        fontSize: 15,
        height: 1.5,
        fontStyle: FontStyle.italic,
        color: AppColors.textSecondary,
      ),
    );
  }

  static Widget _germanBlock(String text) {
    return Text(
      text,
      textAlign: TextAlign.left,
      style: GoogleFonts.inter(
        fontSize: 16,
        height: 1.55,
        color: Colors.white.withOpacity(0.85),
      ),
    );
  }
}

class _ModeDots extends StatelessWidget {
  const _ModeDots({
    required this.activeMode,
    required this.availableModes,
  });

  final VerseCardContentMode activeMode;
  final List<VerseCardContentMode> availableModes;

  static const List<VerseCardContentMode> _allModes = VerseCardContentMode.values;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < _allModes.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          _dot(_allModes[i]),
        ],
      ],
    );
  }

  Widget _dot(VerseCardContentMode mode) {
    final available = availableModes.contains(mode);
    final active = activeMode == mode;
    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active
            ? Colors.white.withOpacity(0.42)
            : available
                ? Colors.white.withOpacity(0.16)
                : Colors.white.withOpacity(0.06),
      ),
    );
  }
}

class _AyahBadge extends StatelessWidget {
  const _AyahBadge({required this.ayah});

  final int ayah;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 21,
      height: 21,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.18),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.07),
          width: 1,
        ),
      ),
      child: Text(
        '$ayah',
        style: GoogleFonts.inter(
          fontSize: 8.5,
          fontWeight: FontWeight.w600,
          color: Colors.white.withOpacity(0.42),
        ),
      ),
    );
  }
}
