import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/app_feedback_service.dart';

const Color _accentChampagneGold = Color(0xFFE5C07B);

/// Fester Hinweis unter KI-generierten Inhalten — immer sichtbar, nicht wegklickbar.
class AiDisclaimerCaption extends StatelessWidget {
  const AiDisclaimerCaption({super.key});

  static const String text =
      'KI-generierte Zusammenfassung auf Grundlage von Vers, Kontext und angebundenem Tafsir. Keine Fatwa. Bei Unsicherheit einen Gelehrten fragen.';

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 10.5,
        fontWeight: FontWeight.w400,
        height: 1.35,
        color: Colors.white38,
      ),
    );
  }
}

/// Dezente Quellenzeile unter KI-Erklärungen (z. B. angebundener Tafsir).
class AiSourceCaption extends StatelessWidget {
  const AiSourceCaption({super.key, required this.source});

  final String source;

  @override
  Widget build(BuildContext context) {
    final trimmed = source.trim();
    if (trimmed.isEmpty) return const SizedBox.shrink();

    return Text(
      trimmed.startsWith('Quelle:') ? trimmed : 'Quelle: $trimmed',
      style: GoogleFonts.inter(
        fontSize: 10.5,
        fontWeight: FontWeight.w400,
        height: 1.35,
        color: Colors.white.withOpacity(0.48),
      ),
    );
  }
}

/// Daumen hoch/runter → [AppFeedbackService.send] mit [screen] + [context].
class AiInlineFeedbackRow extends StatefulWidget {
  const AiInlineFeedbackRow({
    super.key,
    required this.screen,
    this.context,
    this.prompt = 'War die Erklärung hilfreich?',
    this.onSent,
  });

  final String screen;
  final String? context;
  final String prompt;
  final VoidCallback? onSent;

  @override
  State<AiInlineFeedbackRow> createState() => _AiInlineFeedbackRowState();
}

class _AiInlineFeedbackRowState extends State<AiInlineFeedbackRow> {
  bool _sent = false;
  bool _sending = false;

  Future<void> _submit(int rating) async {
    if (_sent || _sending) return;
    setState(() => _sending = true);
    final ok = await AppFeedbackService.send(
      rating: rating,
      screen: widget.screen,
      context: widget.context,
    );
    if (!mounted) return;
    setState(() {
      _sending = false;
      if (ok) _sent = true;
    });
    if (ok) {
      widget.onSent?.call();
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Danke für dein Feedback!')),
      );
    } else {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          content: Text('Konnte nicht senden. Bitte später erneut versuchen.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_sent) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: Text(
            widget.prompt,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.72),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Ja',
          onPressed: _sending ? null : () => _submit(1),
          icon: Icon(
            Icons.thumb_up_outlined,
            color: _accentChampagneGold,
            size: 22,
          ),
        ),
        IconButton(
          tooltip: 'Nein',
          onPressed: _sending ? null : () => _submit(-1),
          icon: const Icon(
            Icons.thumb_down_outlined,
            color: Colors.white54,
            size: 22,
          ),
        ),
      ],
    );
  }
}
