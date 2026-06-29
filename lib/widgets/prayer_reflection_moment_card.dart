import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/ai/reflection_moment_service.dart';
import 'glass_card.dart';

const Color _accentGold = Color(0xFFE5C07B);

/// Nachdenk-Impuls auf dem Gebet-Tab (Freitag: Jumuʿah-Bezug, sonst allgemein).
class PrayerReflectionMomentCard extends StatelessWidget {
  const PrayerReflectionMomentCard({
    super.key,
    required this.moment,
  });

  final ReflectionMoment moment;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 20,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _accentGold.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _accentGold.withOpacity(0.22)),
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
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
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
              ],
            ),
            const SizedBox(height: 14),
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
        ),
      ),
    );
  }
}

/// Lädt [ReflectionMoment] und zeigt Karte oder dezenten Ladezustand.
class PrayerReflectionMomentSection extends StatefulWidget {
  const PrayerReflectionMomentSection({super.key});

  @override
  State<PrayerReflectionMomentSection> createState() =>
      _PrayerReflectionMomentSectionState();
}

class _PrayerReflectionMomentSectionState extends State<PrayerReflectionMomentSection> {
  late Future<ReflectionMoment> _future;

  @override
  void initState() {
    super.initState();
    _future = ReflectionMomentService.instance.fetchMoment();
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
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
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
        return PrayerReflectionMomentCard(moment: moment);
      },
    );
  }
}
