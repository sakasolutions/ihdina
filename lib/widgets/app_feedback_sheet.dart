import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/app_feedback_service.dart';

const Color _gold = Color(0xFFE5C07B);

/// Allgemeines Feedback (Rating + optionaler Text). [screenTag] für Admin-Panel (z. B. `settings`).
Future<void> showAppFeedbackSheet(
  BuildContext context, {
  String screenTag = 'settings',
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _FeedbackSheetBody(screenTag: screenTag),
  );
}

class _FeedbackSheetBody extends StatefulWidget {
  const _FeedbackSheetBody({required this.screenTag});

  final String screenTag;

  @override
  State<_FeedbackSheetBody> createState() => _FeedbackSheetBodyState();
}

class _FeedbackSheetBodyState extends State<_FeedbackSheetBody> {
  int? _rating;
  final _comment = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == null || _sending) return;
    setState(() => _sending = true);
    final ok = await AppFeedbackService.send(
      rating: _rating!,
      comment: _comment.text,
      screen: widget.screenTag,
    );
    if (!mounted) return;
    setState(() => _sending = false);
    if (ok) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      Navigator.of(context).pop();
      messenger?.showSnackBar(
        const SnackBar(content: Text('Danke für dein Feedback!')),
      );
    } else {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          content: Text(
            'Konnte nicht senden. Bitte später erneut versuchen oder Internet prüfen.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + bottom),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF0E2520),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Feedback',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Wie zufrieden bist du mit Ihdina?',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.35,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Thumb(
                    selected: _rating == -1,
                    icon: Icons.thumb_down_outlined,
                    label: 'Kritik',
                    onTap: () => setState(() => _rating = -1),
                  ),
                  const SizedBox(width: 20),
                  _Thumb(
                    selected: _rating == 1,
                    icon: Icons.thumb_up_outlined,
                    label: 'Top',
                    onTap: () => setState(() => _rating = 1),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _comment,
                maxLines: 4,
                maxLength: 2000,
                style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
                cursorColor: _gold,
                decoration: InputDecoration(
                  hintText: 'Optional: Was können wir verbessern?',
                  hintStyle: GoogleFonts.inter(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _gold.withOpacity(0.5)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _rating == null || _sending ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: _gold,
                  foregroundColor: const Color(0xFF1A1A1A),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _sending
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF1A1A1A),
                        ),
                      )
                    : Text(
                        'Senden',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
              TextButton(
                onPressed: _sending ? null : () => Navigator.of(context).pop(),
                child: Text(
                  'Schließen',
                  style: GoogleFonts.inter(color: Colors.white54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      selected: selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: selected ? _gold.withOpacity(0.22) : Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? _gold.withOpacity(0.7) : Colors.white.withOpacity(0.12),
              ),
            ),
            child: Icon(
              icon,
              size: 28,
              color: selected ? _gold : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }
}
