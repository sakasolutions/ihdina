import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// Current playback state for verse audio (EveryAyah.com).
class AudioPlaybackState {
  const AudioPlaybackState({
    this.surahId,
    this.ayahNumber,
    this.isLoading = false,
    this.isPlaying = false,
  });

  final int? surahId;
  final int? ayahNumber;
  final bool isLoading;
  final bool isPlaying;

  bool get isIdle => surahId == null && ayahNumber == null;
  bool isVerse(int s, int a) => surahId == s && ayahNumber == a;
}

/// Global audio service for verse-by-verse streaming (Mishary Alafasy via EveryAyah.com).
/// A single [AudioPlayer] ensures only one verse plays at a time.
class AudioService {
  AudioService._() {
    _player.playerStateStream.listen(_onPlayerStateChanged);
    _player.processingStateStream.listen(_onProcessingStateChanged);
  }

  static final AudioService instance = AudioService._();

  static const String _baseUrl = 'https://everyayah.com/data/Alafasy_128kbps/';

  final AudioPlayer _player = AudioPlayer();

  final ValueNotifier<AudioPlaybackState> state = ValueNotifier(const AudioPlaybackState());

  int? _currentSurahId;
  int? _currentAyahNumber;

  /// Pads number to 3 digits (e.g. 2 -> "002").
  static String _pad3(int n) => n.toString().padLeft(3, '0');

  /// Builds EveryAyah.com URL for a verse (e.g. 002005.mp3).
  static String urlForVerse(int surahId, int ayahNumber) {
    return '$_baseUrl${_pad3(surahId)}${_pad3(ayahNumber)}.mp3';
  }

  void _onPlayerStateChanged(PlayerState ps) {
    final loading = ps.processingState == ProcessingState.loading ||
        ps.processingState == ProcessingState.buffering;
    final playing = ps.playing && ps.processingState == ProcessingState.ready;
    state.value = AudioPlaybackState(
      surahId: _currentSurahId,
      ayahNumber: _currentAyahNumber,
      isLoading: loading,
      isPlaying: playing,
    );
  }

  void _onProcessingStateChanged(ProcessingState ps) {
    if (ps == ProcessingState.completed || ps == ProcessingState.idle) {
      if (ps == ProcessingState.completed) {
        _currentSurahId = null;
        _currentAyahNumber = null;
      }
      state.value = AudioPlaybackState(
        surahId: _currentSurahId,
        ayahNumber: _currentAyahNumber,
        isLoading: false,
        isPlaying: false,
      );
    }
  }

  /// Plays the given verse. If the same verse is already playing, stops it.
  /// If another verse is playing, it is stopped and the new one is loaded and played.
  Future<void> playVerse(int surahId, int ayahNumber) async {
    if (_currentSurahId == surahId && _currentAyahNumber == ayahNumber) {
      if (state.value.isPlaying || state.value.isLoading) {
        await stop();
        return;
      }
    }

    await _player.stop();
    _currentSurahId = surahId;
    _currentAyahNumber = ayahNumber;
    state.value = AudioPlaybackState(
      surahId: surahId,
      ayahNumber: ayahNumber,
      isLoading: true,
      isPlaying: false,
    );

    final url = urlForVerse(surahId, ayahNumber);
    try {
      await _player.setUrl(url);
      _player.play();
    } catch (e) {
      if (kDebugMode) debugPrint('[AudioService] setUrl/play error: $e');
      _currentSurahId = null;
      _currentAyahNumber = null;
      state.value = const AudioPlaybackState();
    }
  }

  /// Stops playback and clears current verse.
  Future<void> stop() async {
    await _player.stop();
    _currentSurahId = null;
    _currentAyahNumber = null;
    state.value = const AudioPlaybackState();
  }

  void dispose() {
    _player.dispose();
  }
}
