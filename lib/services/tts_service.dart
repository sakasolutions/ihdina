import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../data/tts/tts_pronunciation_repository.dart';
import '../utils/tts_text_sanitizer.dart';
import 'audio_service.dart';
import 'tts_voice_selector.dart';

/// Inhalt, der gerade oder zuletzt per System-TTS vorgelesen wird.
enum TtsContentKind {
  verseGerman,
  explanationTab,
}

/// Lokale Sprachausgabe (System-TTS, bevorzugt auf dem Gerät).
class TtsPlaybackState {
  const TtsPlaybackState({
    this.kind,
    this.sourceKey,
    this.isSpeaking = false,
    this.isInitializing = false,
  });

  final TtsContentKind? kind;
  final String? sourceKey;
  final bool isSpeaking;
  final bool isInitializing;

  bool get isIdle => !isSpeaking && !isInitializing;

  bool matches(String sourceKey, TtsContentKind kind) =>
      isSpeaking && this.sourceKey == sourceKey && this.kind == kind;

  static const idle = TtsPlaybackState();
}

/// Ein [FlutterTts]-Player für Vorlesen auf Deutsch (Vers, Erklärung).
/// Kein Upload — Verarbeitung über die System-Sprachausgabe.
class TtsService {
  TtsService._();

  static final TtsService instance = TtsService._();

  final FlutterTts _tts = FlutterTts();

  final ValueNotifier<TtsPlaybackState> state =
      ValueNotifier<TtsPlaybackState>(TtsPlaybackState.idle);

  bool _initDone = false;
  bool _initInFlight = false;
  bool _cancelled = false;
  bool _nativeQueueEnabled = false;
  List<String> _queue = [];
  int _queueIndex = 0;

  Future<bool> ensureInitialized() async {
    if (_initDone) return true;
    if (_initInFlight) {
      while (_initInFlight) {
        await Future<void>.delayed(const Duration(milliseconds: 40));
      }
      return _initDone;
    }
    _initInFlight = true;
    try {
      // Optionale Plattform-Calls dürfen Init nicht abbrechen (Hot Reload / ältere Engine).
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        await _tryOptionalTts(
            'setSharedInstance', () => _tts.setSharedInstance(true));
      }
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        _nativeQueueEnabled = await _tryOptionalTtsBool(
          'setQueueMode',
          () => _tts.setQueueMode(1),
        );
      }
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        await _tryOptionalTts('iosAudioCategory', () async {
          await _tts.setIosAudioCategory(
            IosTextToSpeechAudioCategory.playback,
            [IosTextToSpeechAudioCategoryOptions.defaultToSpeaker],
            IosTextToSpeechAudioMode.spokenAudio,
          );
        });
      }
      await _tryOptionalTts(
          'awaitSpeakCompletion', () => _tts.awaitSpeakCompletion(true));
      await _tts.setSpeechRate(_defaultSpeechRate);
      await _tts.setPitch(0.96);
      await _tts.setVolume(1.0);

      await _applyGermanVoice();

      _tts.setCompletionHandler(_onUtteranceComplete);
      _tts.setErrorHandler((msg) {
        if (kDebugMode) debugPrint('[TtsService] error: $msg');
        _finishPlayback();
      });
      _tts.setCancelHandler(_finishPlayback);

      _initDone = true;
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[TtsService] init failed: $e');
      return false;
    } finally {
      _initInFlight = false;
    }
  }

  Future<void> _tryOptionalTts(
      String name, Future<dynamic> Function() call) async {
    try {
      await call();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[TtsService] optional $name skipped: $e');
      }
    }
  }

  Future<bool> _tryOptionalTtsBool(
      String name, Future<dynamic> Function() call) async {
    try {
      await call();
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[TtsService] optional $name skipped: $e');
      }
      return false;
    }
  }

  /// Etwas zügiger als „Langsam-Vorlesen“, aber noch gut verständlich.
  static double get _defaultSpeechRate {
    if (kIsWeb) return 0.52;
    if (defaultTargetPlatform == TargetPlatform.iOS) return 0.52;
    if (defaultTargetPlatform == TargetPlatform.android) return 0.58;
    return 0.52;
  }

  Future<void> _applyGermanVoice() async {
    try {
      final voices = await _tts.getVoices;
      final mode = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS
          ? TtsVoicePickMode.iosMaleQuality
          : TtsVoicePickMode.androidMale;
      final picked = TtsVoiceSelector.pickGermanVoice(voices, mode: mode);
      if (picked != null) {
        final ok = await _tts.setVoice(picked);
        if (ok == 1) return;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[TtsService] setVoice: $e');
    }
    await _tts.setLanguage('de-DE');
  }

  /// Vorlesen mit Toggle: gleicher [sourceKey] + laufend → Stopp.
  Future<void> speak({
    required String text,
    required String sourceKey,
    required TtsContentKind kind,
  }) async {
    if (text.trim().isEmpty) return;

    if (state.value.matches(sourceKey, kind)) {
      await stop();
      return;
    }

    await AudioService.instance.stop();
    await stop();

    state.value = TtsPlaybackState(
      kind: kind,
      sourceKey: sourceKey,
      isInitializing: true,
    );

    final ready = await ensureInitialized();
    if (!ready || _cancelled) {
      state.value = TtsPlaybackState.idle;
      return;
    }

    final plain = TtsTextSanitizer.plainFromMarkdown(text);
    final spoken = await TtsPronunciationRepository.instance.apply(plain);
    final chunks = TtsTextSanitizer.chunksForSpeech(spoken);
    if (chunks.isEmpty) {
      state.value = TtsPlaybackState.idle;
      return;
    }

    _queue = chunks;
    _queueIndex = 0;
    _cancelled = false;

    state.value = TtsPlaybackState(
      kind: kind,
      sourceKey: sourceKey,
      isSpeaking: true,
    );

    if (_nativeQueueEnabled && _queue.length > 1) {
      await _speakQueuedNative();
    } else {
      await _speakCurrentChunk();
    }
  }

  /// Android: alle Abschnitte in die System-Warteschlange — weniger Pausen zwischen Chunks.
  Future<void> _speakQueuedNative() async {
    try {
      for (final chunk in _queue) {
        if (_cancelled) break;
        await _tts.speak(chunk);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[TtsService] native queue speak error: $e');
      _finishPlayback();
    }
  }

  Future<void> _speakCurrentChunk() async {
    if (_cancelled || _queueIndex >= _queue.length) {
      _finishPlayback();
      return;
    }
    final chunk = _queue[_queueIndex];
    try {
      await _tts.speak(chunk);
    } catch (e) {
      if (kDebugMode) debugPrint('[TtsService] speak error: $e');
      _finishPlayback();
    }
  }

  void _onUtteranceComplete() {
    if (_cancelled) return;
    _queueIndex++;
    if (_queueIndex < _queue.length) {
      _speakCurrentChunk();
    } else {
      _finishPlayback();
    }
  }

  void _finishPlayback() {
    _queue = [];
    _queueIndex = 0;
    if (!_cancelled) {
      state.value = TtsPlaybackState.idle;
    }
  }

  Future<void> stop() async {
    _cancelled = true;
    try {
      await _tts.stop();
    } catch (_) {}
    _queue = [];
    _queueIndex = 0;
    state.value = TtsPlaybackState.idle;
    _cancelled = false;
  }
}
