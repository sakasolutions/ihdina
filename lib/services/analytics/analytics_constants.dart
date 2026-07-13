/// Server-Schema v1 — Property-Werte müssen zum Backend-Katalog passen.
class AnalyticsConstants {
  AnalyticsConstants._();

  static const int schemaVersion = 1;
  static const int maxQueueSize = 2000;
  static const int maxBatchSize = 50;
  static const int flushThreshold = 10;
  static const Duration flushInterval = Duration(seconds: 30);
  static const Duration sessionTimeout = Duration(minutes: 30);
  static const Duration maxEventAge = Duration(days: 30);
  static const Duration explanationViewThreshold = Duration(seconds: 2);

  static const Duration retryInitial = Duration(seconds: 5);
  static const Duration retryMax = Duration(minutes: 15);

  static const int priorityScreenViewed = 1;
  static const int priorityVerseOpened = 2;
  static const int priorityExplanationRequested = 3;
  static const int priorityDefault = 10;

  static const Set<String> funnelFlushEvents = {
    'paywall_viewed',
    'purchase_started',
    'purchase_cancelled',
    'purchase_failed',
  };
}

/// Erlaubte `screen`-Werte für `screen_viewed`.
abstract class AnalyticsScreens {
  static const home = 'home';
  static const quran = 'quran';
  static const surahReader = 'surah_reader';
  static const search = 'search';
  static const bookmarks = 'bookmarks';
  static const prayer = 'prayer';
  static const qibla = 'qibla';
  static const tasbih = 'tasbih';
  static const settings = 'settings';
  static const paywall = 'paywall';
  static const explanation = 'explanation';
  static const dua = 'dua';
}

/// `entrySource` für `verse_opened` (Server-Enum).
abstract class AnalyticsVerseEntrySource {
  static const reader = 'reader';
  static const search = 'search';
  static const bookmark = 'bookmark';
  static const daily = 'daily';
  static const home = 'home';
  static const other = 'other';
}

/// `trigger` für `paywall_viewed` (Server-Enum).
abstract class AnalyticsPaywallTrigger {
  static const quota = 'quota';
  static const settings = 'settings';
  static const proRequired = 'pro_required';
  static const softHint = 'soft_hint';
  static const other = 'other';
}
