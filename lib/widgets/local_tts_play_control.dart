import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/tts_service.dart';

/// Kompakte Vorlesen-Zeile (System-TTS, lokal) — Stil wie Koran-Wiedergabe.
class LocalTtsPlayControl extends StatelessWidget {
  const LocalTtsPlayControl({
    super.key,
    required this.label,
    required this.sourceKey,
    required this.kind,
    required this.text,
    required this.ttsState,
    required this.onSpeak,
    required this.onStop,
    this.caption,
  });

  final String label;
  final String sourceKey;
  final TtsContentKind kind;
  final String text;
  final TtsPlaybackState ttsState;
  final VoidCallback onSpeak;
  final VoidCallback onStop;
  final String? caption;

  static const Color _accentGold = Color(0xFFE5C07B);

  bool get _isActive => ttsState.matches(sourceKey, kind);
  bool get _isBusy => _isActive && (ttsState.isSpeaking || ttsState.isInitializing);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: text.trim().isEmpty
            ? null
            : () {
                if (_isBusy) {
                  onStop();
                } else {
                  onSpeak();
                }
              },
        borderRadius: BorderRadius.circular(14),
        splashColor: Colors.white.withOpacity(0.06),
        highlightColor: Colors.white.withOpacity(0.03),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: _isActive ? Colors.white.withOpacity(0.07) : Colors.white.withOpacity(0.04),
            border: Border.all(
              color: _isActive
                  ? _accentGold.withOpacity(0.42)
                  : Colors.white.withOpacity(0.1),
              width: _isActive ? 1.1 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: ttsState.isInitializing && _isActive
                      ? Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _accentGold.withOpacity(0.9),
                            ),
                          ),
                        )
                      : Icon(
                          _isBusy ? Icons.stop_circle_outlined : Icons.volume_up_rounded,
                          size: 24,
                          color: _isActive
                              ? _accentGold.withOpacity(0.95)
                              : Colors.white.withOpacity(0.72),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _isActive
                              ? const Color(0xFFEFD9A7)
                              : Colors.white.withOpacity(0.88),
                        ),
                      ),
                      if (caption != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          caption!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.38),
                          ),
                        ),
                      ],
                    ],
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
