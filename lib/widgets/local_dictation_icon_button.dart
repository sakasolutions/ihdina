import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../services/local_speech_service.dart';

/// Mikrofon: **nur lokale** Spracherkennung (siehe [LocalSpeechService]).
class LocalDictationIconButton extends StatefulWidget {
  const LocalDictationIconButton({
    super.key,
    required this.controller,
    required this.listenMode,
    this.enabled = true,
    this.iconColor,
    this.iconSize = 22,
    this.padding = const EdgeInsets.all(8),
  });

  final TextEditingController controller;
  final ListenMode listenMode;
  final bool enabled;
  final Color? iconColor;
  final double iconSize;
  final EdgeInsetsGeometry padding;

  @override
  State<LocalDictationIconButton> createState() => _LocalDictationIconButtonState();
}

class _LocalDictationIconButtonState extends State<LocalDictationIconButton> {
  final LocalSpeechService _svc = LocalSpeechService.instance;
  String _baseText = '';
  bool _listening = false;

  @override
  void initState() {
    super.initState();
    _svc.status.addListener(_onSpeechStatus);
  }

  void _onSpeechStatus() {
    final s = _svc.status.value;
    final nowListening = s == SpeechToText.listeningStatus;
    if (!mounted || nowListening == _listening) return;
    setState(() => _listening = nowListening);
  }

  @override
  void dispose() {
    _svc.status.removeListener(_onSpeechStatus);
    if (_listening) {
      unawaited(_svc.cancel());
    }
    super.dispose();
  }

  void _showSnack(String message) {
    final m = ScaffoldMessenger.maybeOf(context);
    if (m != null) {
      m.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _toggle() async {
    if (!widget.enabled) return;
    if (kIsWeb) {
      _showSnack('Spracheingabe ist im Web nicht verfügbar.');
      return;
    }

    final speech = _svc.speech;
    if (speech.isListening) {
      await _svc.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }

    final ok = await _svc.ensureInitialized();
    if (!ok || !mounted) {
      _showSnack(
        'Spracherkennung nicht verfügbar oder keine Berechtigung. '
        'Bitte in den Systemeinstellungen Mikrofon und Spracherkennung prüfen.',
      );
      return;
    }

    _baseText = widget.controller.text;
    final localeId = await _svc.preferredLocaleId();

    try {
      await speech.listen(
        onResult: (r) {
          final words = r.recognizedWords;
          final sep = _baseText.isEmpty || _baseText.endsWith(' ') ? '' : ' ';
          final combined =
              _baseText.isEmpty ? words : '$_baseText$sep$words';
          widget.controller.value = TextEditingValue(
            text: combined,
            selection: TextSelection.collapsed(offset: combined.length),
          );
        },
        listenFor: const Duration(seconds: 45),
        pauseFor: const Duration(seconds: 3),
        localeId: localeId,
        listenOptions: SpeechListenOptions(
          partialResults: true,
          onDevice: true,
          listenMode: widget.listenMode,
          cancelOnError: true,
        ),
      );
      if (mounted) setState(() => _listening = true);
    } on ListenFailedException catch (e) {
      if (mounted) {
        setState(() => _listening = false);
        _showSnack(
          'Lokale Spracherkennung startet hier nicht (${e.message ?? "unbekannt"}). '
          'Tippe den Text, oder prüfe, ob auf dem Gerät Offline-Sprache installiert ist.',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _listening = false);
        _showSnack('Spracheingabe fehlgeschlagen: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.iconColor ?? Colors.white70;
    final active = _listening;
    final semanticsLabel = active
        ? 'Diktat beenden'
        : 'Spracheingabe. Texterkennung nur auf diesem Gerät, nicht auf Ihdina-Servern.';
    return Semantics(
      label: semanticsLabel,
      button: true,
      child: IconButton(
        onPressed: widget.enabled ? _toggle : null,
        padding: widget.padding,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        tooltip: active ? 'Diktat beenden' : 'Spracheingabe (nur auf dem Gerät)',
        icon: Icon(
          active ? Icons.mic_rounded : Icons.mic_none_rounded,
          size: widget.iconSize,
          color: active ? const Color(0xFFE5C07B) : color,
        ),
      ),
    );
  }
}
