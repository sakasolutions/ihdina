import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Kompakte Sekundäraktionen direkt unter dem Tagesvers-CTA (Weiterlesen / Sammlung).
class HomeVerseSecondaryActionsRow extends StatelessWidget {
  const HomeVerseSecondaryActionsRow({
    super.key,
    this.onWeiterlesen,
    required this.onSpeichern,
  });

  final VoidCallback? onWeiterlesen;
  final VoidCallback onSpeichern;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SecondaryPillButton(
            icon: Icons.menu_book_rounded,
            label: 'Weiterlesen',
            enabled: onWeiterlesen != null,
            onTap: onWeiterlesen,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SecondaryPillButton(
            icon: Icons.bookmark_outline_rounded,
            label: 'Sammlung',
            enabled: true,
            onTap: onSpeichern,
          ),
        ),
      ],
    );
  }
}

class _SecondaryPillButton extends StatelessWidget {
  const _SecondaryPillButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(22),
        splashColor: Colors.white.withOpacity(0.1),
        highlightColor: Colors.white.withOpacity(0.05),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: enabled ? 1 : 0.42,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: Colors.white.withOpacity(0.055),
              border: Border.all(
                color: Colors.white.withOpacity(0.11),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 17, color: Colors.white.withOpacity(0.88)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.15,
                        color: Colors.white.withOpacity(0.9),
                      ),
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
