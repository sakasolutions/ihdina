import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

/// Primärer Button im Premium-Stil (KI-CTA: tiefer Smaragd, Goldrand, weiches Licht).
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
  /// Optional; z. B. etwas mehr vertikales Padding im Hero-CTA.
  final EdgeInsetsGeometry? padding;

  static const BorderRadius _radius = BorderRadius.all(Radius.circular(14));

  /// Logo-Smaragd, abgedunkelt – kein greller Tailwind-Grünton.
  static const LinearGradient _filledGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.42, 1.0],
    colors: [
      Color(0xFF1F5646),
      Color(0xFF123A32),
      Color(0xFF071A16),
    ],
  );

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accent,
          side: const BorderSide(color: AppColors.accent, width: 1.5),
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: const RoundedRectangleBorder(borderRadius: _radius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[icon!, const SizedBox(width: 8)],
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    final effectivePadding =
        padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 14);
    final enabled = onPressed != null;

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: _radius,
          splashColor: AppColors.premiumGoldMid.withOpacity(0.22),
          highlightColor: Colors.white.withOpacity(0.06),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: _radius,
              gradient: _filledGradient,
              border: Border.all(
                color: AppColors.premiumGoldMid.withOpacity(0.38),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.55),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: AppColors.premiumGoldMid.withOpacity(0.16),
                  blurRadius: 22,
                  spreadRadius: -4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: effectivePadding,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[icon!, const SizedBox(width: 8)],
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                      color: Colors.white.withOpacity(0.96),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
