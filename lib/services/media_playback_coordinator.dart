import 'audio_service.dart';
import 'tts_service.dart';

/// Stellt sicher, dass Rezitation und Vorlesen nicht parallel laufen.
class MediaPlaybackCoordinator {
  MediaPlaybackCoordinator._();

  static final MediaPlaybackCoordinator instance = MediaPlaybackCoordinator._();

  Future<void> stopAll() async {
    await Future.wait([
      AudioService.instance.stop(),
      TtsService.instance.stop(),
    ]);
  }

  Future<void> playVerseRecitation(int surahId, int ayahNumber) async {
    await TtsService.instance.stop();
    await AudioService.instance.playVerse(surahId, ayahNumber);
  }
}
