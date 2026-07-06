import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/ai/reflection_moment_service.dart';
import 'glass_card.dart';

const Color _accentGold = Color(0xFFE5C07B);

/// Nachdenk-Impuls — aufklappbar (Dua-Tab; Freitag standardmäßig offen).
class CollapsibleReflectionMomentSection extends StatefulWidget {
  const CollapsibleReflectionMomentSection({super.key});

  @override
  State<CollapsibleReflectionMomentSection> createState() =>
      _CollapsibleReflectionMomentSectionState();
}

class _CollapsibleReflectionMomentSectionState
    extends State<CollapsibleReflectionMomentSection> {
  late Future<ReflectionMoment> _future;
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = ReflectionMomentService.defaultExpanded;
    _future = ReflectionMomentService.instance.fetchMoment();
    if (_expanded) {
      ReflectionMomentService.instance.recordExpand();
    }
  }

  void _setExpanded(bool value) {
    if (_expanded == value) return;
    HapticFeedback.selectionClick();
    setState(() => _expanded = value);
    if (value) {
      ReflectionMomentService.instance.recordExpand();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ReflectionMoment>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return GlassCard(
            borderRadius: 20,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _accentGold.withOpacity(0.85),
                  ),
                ),
              ),
            ),
          );
        }

        final moment = snap.data;
        if (moment == null || moment.body.isEmpty) {
          return const SizedBox.shrink();
        }

        return _ReflectionMomentCard(
          moment: moment,
          expanded: _expanded,
          onToggle: () => _setExpanded(!_expanded),
        );
      },
    );
  }
}

class _ReflectionMomentCard extends StatelessWidget {
  const _ReflectionMomentCard({
    required this.moment,
    required this.expanded,
    required this.onToggle,
  });

  final ReflectionMoment moment;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: expanded ? null : onToggle,
        borderRadius: BorderRadius.circular(20),
        child: GlassCard(
          borderRadius: 20,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InkWell(
                  onTap: onToggle,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4, bottom: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _accentGold.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _accentGold.withOpacity(0.22),
                            ),
                          ),
                          child: Icon(
                            moment.isFriday
                                ? Icons.people_outline_rounded
                                : Icons.self_improvement_outlined,
                            size: 18,
                            color: _accentGold.withOpacity(0.95),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ReflectionMomentService.displayTitle,
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                ReflectionMomentService.displaySubtitle,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.6,
                                  color: Colors.white.withOpacity(0.42),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          expanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: Colors.white54,
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),
                if (expanded) ...[
                  const SizedBox(height: 12),
                  Text(
                    moment.body,
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                      height: 1.48,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Keine Predigt · keine Rechtsauskunft · bei Tiefe Gelehrte fragen',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                      color: Colors.white.withOpacity(0.28),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
