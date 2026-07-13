import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Diskreter Hinweis: Lernhilfe, noch nicht fachlich endgeprüft.
class ReligiousContentNotice extends StatelessWidget {
  const ReligiousContentNotice({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.info_outline_rounded,
          size: 16,
          color: Colors.white.withOpacity(0.42),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              height: 1.4,
              color: Colors.white.withOpacity(0.48),
            ),
          ),
        ),
      ],
    );
  }
}
