import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

/// Primärer Button — ruhiger Goldton, dunkle Schrift, ohne Verlauf.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.outlined = false,
    this.padding,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool outlined;

  /// Optional; Standardhöhe ca. 56 px über [minimumHeight].
  final EdgeInsetsGeometry? padding;

  static const BorderRadius _radius = BorderRadius.all(Radius.circular(16));
  static const double _minHeight = 56;

  static const Color _filledBackground = AppColors.premiumGoldMid;
  static const Color _filledForeground = Color(0xFF1A2A24);
  static const Color _filledBorder = Color(0x338F7D4E);
  static const Color _filledPressed = AppColors.premiumGoldDeep;

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.premiumGoldMid,
            side: BorderSide(
              color: AppColors.premiumGoldMid.withValues(alpha: 0.45),
              width: 1,
            ),
            minimumSize: const Size.fromHeight(_minHeight),
            padding: padding ??
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: const RoundedRectangleBorder(borderRadius: _radius),
          ),
          child: _ButtonLabel(
            label: label,
            icon: icon,
            color: AppColors.premiumGoldMid,
          ),
        ),
      );
    }

    final enabled = onPressed != null;

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: SizedBox(
        width: double.infinity,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: _radius,
            splashColor: _filledForeground.withValues(alpha: 0.08),
            highlightColor: _filledPressed.withValues(alpha: 0.18),
            child: Ink(
              height: _minHeight,
              decoration: BoxDecoration(
                borderRadius: _radius,
                color: _filledBackground,
                border: Border.all(color: _filledBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.22),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: padding ??
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Center(
                  child: _ButtonLabel(
                    label: label,
                    icon: icon,
                    color: _filledForeground,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ButtonLabel extends StatelessWidget {
  const _ButtonLabel({
    required this.label,
    required this.color,
    this.icon,
  });

  final String label;
  final Color color;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[icon!, const SizedBox(width: 8)],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.15,
              color: color.withValues(alpha: 0.96),
            ),
          ),
        ),
      ],
    );
  }
}
