import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color _accentChampagneGold = Color(0xFFE5C07B);

/// Fortschrittszeile für Reinigungs-Schrittscreens.
class PurificationProgressHeader extends StatelessWidget {
  const PurificationProgressHeader({
    super.key,
    required this.progressLabel,
    required this.stepTitle,
    this.progressValue,
  });

  final String progressLabel;
  final String stepTitle;
  final double? progressValue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          progressLabel,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
            color: Colors.white.withOpacity(0.58),
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            minHeight: 3,
            backgroundColor: Colors.white.withOpacity(0.08),
            valueColor: AlwaysStoppedAnimation<Color>(
              _accentChampagneGold.withOpacity(0.75),
            ),
            value: progressValue,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          stepTitle,
          style: GoogleFonts.playfairDisplay(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            height: 1.2,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
