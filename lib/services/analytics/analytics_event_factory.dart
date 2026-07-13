import 'analytics_constants.dart';

/// Baut Event-Payloads gemäß Server-Schema v1.
class AnalyticsEventFactory {
  AnalyticsEventFactory._();

  static Map<String, dynamic> baseEvent({
    required String eventId,
    required String eventName,
    required String sessionId,
    required DateTime occurredAt,
    required String platform,
    String? appVersion,
    String? buildNumber,
    bool? isProSnapshot,
    String? source,
    int? surahNumber,
    int? ayahNumber,
    Map<String, dynamic>? properties,
  }) {
    final event = <String, dynamic>{
      'eventVersion': AnalyticsConstants.schemaVersion,
      'eventId': eventId,
      'eventName': eventName,
      'sessionId': sessionId,
      'occurredAt': _formatOccurredAt(occurredAt),
      'platform': platform,
    };
    if (appVersion != null) event['appVersion'] = appVersion;
    if (buildNumber != null) event['buildNumber'] = buildNumber;
    if (isProSnapshot != null) event['isProSnapshot'] = isProSnapshot;
    if (source != null) event['source'] = source;
    if (surahNumber != null) event['surahNumber'] = surahNumber;
    if (ayahNumber != null) event['ayahNumber'] = ayahNumber;
    if (properties != null && properties.isNotEmpty) {
      event['properties'] = properties;
    }
    return event;
  }

  static String _formatOccurredAt(DateTime dt) {
    final u = dt.toUtc();
    final ms = u.millisecond;
    if (ms == 0) {
      return '${u.toIso8601String().split('.').first}Z';
    }
    return '${u.toIso8601String().substring(0, 23)}Z';
  }

  static int priorityForEvent(String eventName) {
    return switch (eventName) {
      'screen_viewed' => AnalyticsConstants.priorityScreenViewed,
      'verse_opened' => AnalyticsConstants.priorityVerseOpened,
      'explanation_requested' => AnalyticsConstants.priorityExplanationRequested,
      _ => AnalyticsConstants.priorityDefault,
    };
  }
}
