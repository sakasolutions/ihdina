import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Gemeinsame **lokal-only** Spracherkennung ([SpeechListenOptions.onDevice]).
/// Kein Cloud-STT über diese API — wenn das Gerät keine Offline-Modelle hat, schlägt [listen] fehl.
///
/// **Store-Hinweis:** App Store Connect / Play-Datenschutz: Sprachdaten werden für die
/// Texterkennung auf dem Gerät verarbeitet; Ihdina lädt dafür **keine** Audioaufnahmen auf
/// eigene Server hoch. (Den anschließend eingegebenen **Text** einer KI-Folgefrage sendet
/// die App wie bisher an euer Backend — in der Privacy Policy separat beschreiben.)
class LocalSpeechService {
  LocalSpeechService._();
  static final LocalSpeechService instance = LocalSpeechService._();

  final SpeechToText _speech = SpeechToText();
  bool _initAttempted = false;

  /// Status: `listening`, `notListening`, `done`, … (vom Plugin).
  final ValueNotifier<String?> status = ValueNotifier<String?>(null);

  SpeechToText get speech => _speech;

  bool get isAvailable => _speech.isAvailable;

  Future<bool> ensureInitialized() async {
    if (_speech.isAvailable) return true;
    if (_initAttempted) return false;
    _initAttempted = true;
    final ok = await _speech.initialize(
      onStatus: (s) => status.value = s,
      onError: (e) => status.value = 'error:${e.errorMsg}',
      debugLogging: false,
      options: kIsWeb ? null : [SpeechToText.androidNoBluetooth],
    );
    if (!ok) _initAttempted = false;
    return ok;
  }

  /// Bevorzugt System-Locale, sonst erstes `de_*`, sonst null (Plugin-Default).
  Future<String?> preferredLocaleId() async {
    if (!_speech.isAvailable) return null;
    final list = await _speech.locales();
    if (list.isEmpty) return null;
    final system = await _speech.systemLocale();
    if (system != null &&
        list.any((l) => l.localeId.toLowerCase() == system.localeId.toLowerCase())) {
      return system.localeId;
    }
    for (final l in list) {
      if (l.localeId.toLowerCase().startsWith('de')) return l.localeId;
    }
    return list.first.localeId;
  }

  Future<void> stop() => _speech.stop();

  Future<void> cancel() => _speech.cancel();
}
