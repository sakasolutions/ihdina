import 'dart:async';

import 'analytics_constants.dart';
import 'analytics_service.dart';

typedef TrackExplanationViewedFn = Future<void> Function({
  required int surahNumber,
  required int ayahNumber,
  required bool isDailyVerse,
  required String contentSource,
  int? surahId,
});

/// Startet 2-Sekunden-Timer für `explanation_viewed` — einmal pro Session/Vers/Typ.
class ExplanationViewedTracker {
  ExplanationViewedTracker({
    required this.surahNumber,
    required this.ayahNumber,
    required this.isDailyVerse,
    required this.contentSource,
    this.surahId,
    AnalyticsService? analytics,
    TrackExplanationViewedFn? trackFn,
  })  : _analytics = analytics ?? AnalyticsService.instance,
        _trackFn = trackFn;

  final int surahNumber;
  final int ayahNumber;
  final bool isDailyVerse;
  final String contentSource;
  final int? surahId;
  final AnalyticsService _analytics;
  final TrackExplanationViewedFn? _trackFn;

  Timer? _timer;
  bool _fired = false;
  bool _cancelled = false;

  void onExplanationRendered() {
    if (_fired || _cancelled) return;
    _timer?.cancel();
    _timer = Timer(AnalyticsConstants.explanationViewThreshold, () {
      if (_cancelled || _fired) return;
      _fired = true;
      unawaited(
        (_trackFn ?? _analytics.trackExplanationViewed)(
          surahNumber: surahNumber,
          ayahNumber: ayahNumber,
          isDailyVerse: isDailyVerse,
          contentSource: contentSource,
          surahId: surahId,
        ),
      );
    });
  }

  void cancel() {
    _cancelled = true;
    _timer?.cancel();
  }

  void dispose() {
    cancel();
  }
}
