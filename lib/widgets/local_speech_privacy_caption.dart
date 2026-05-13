import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Kurzer Hinweis unter Suchfeldern mit Spracheingabe — hilfreich für Nutzertransparenz
/// (App Store Review, Datenschutz, Barrierefreiheit neben [Semantics] am Mikro).
class LocalSpeechPrivacyCaption extends StatelessWidget {
  const LocalSpeechPrivacyCaption({
    super.key,
    this.padding = const EdgeInsets.only(top: 6),
  });

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(
        'Spracheingabe: Texterkennung nur auf diesem Gerät (ohne Ihdina-Server).',
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontSize: 11,
          height: 1.3,
          color: Colors.white.withOpacity(0.42),
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}
