import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';

/// Dezente Textaktion für den Live-Begleiter (z. B. „Mehr dazu“).
class PurificationGuideTextAction extends StatelessWidget {
  const PurificationGuideTextAction({
    super.key,
    required this.label,
    this.onPressed,
    this.icon = Icons.info_outline_rounded,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData icon;

  static const Color _labelColor = AppColors.premiumGoldMid;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          splashColor: _labelColor.withValues(alpha: 0.12),
          highlightColor: Colors.white.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: _labelColor.withValues(alpha: 0.92),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                    color: _labelColor.withValues(alpha: 0.94),
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
