class AnalyticsIngestResponse {
  const AnalyticsIngestResponse({
    required this.accepted,
    required this.duplicates,
    required this.rejected,
  });

  factory AnalyticsIngestResponse.fromJson(Map<String, dynamic> data) {
    final rejectedRaw = data['rejected'];
    final rejected = <AnalyticsRejectedItem>[];
    if (rejectedRaw is List) {
      for (final item in rejectedRaw) {
        if (item is Map<String, dynamic>) {
          rejected.add(AnalyticsRejectedItem.fromJson(item));
        }
      }
    }
    return AnalyticsIngestResponse(
      accepted: _asInt(data['accepted']),
      duplicates: _asInt(data['duplicates']),
      rejected: rejected,
    );
  }

  final int accepted;
  final int duplicates;
  final List<AnalyticsRejectedItem> rejected;

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }
}

/// Prüft HTTP-200-Batchantworten auf Vollständigkeit.
class AnalyticsBatchResponseValidator {
  const AnalyticsBatchResponseValidator._();

  static BatchValidationResult validate({
    required AnalyticsIngestResponse response,
    required List<String> batchEventIds,
  }) {
    if (batchEventIds.isEmpty) {
      return const BatchValidationResult.consistent(removeEventIds: []);
    }

    final batchSet = batchEventIds.toSet();
    final accounted =
        response.accepted + response.duplicates + response.rejected.length;
    if (accounted != batchEventIds.length) {
      return const BatchValidationResult.inconsistent('count_mismatch');
    }

    for (final item in response.rejected) {
      if (!batchSet.contains(item.eventId)) {
        return const BatchValidationResult.inconsistent('unknown_rejected_id');
      }
    }

    return BatchValidationResult.consistent(removeEventIds: batchEventIds);
  }
}

class BatchValidationResult {
  const BatchValidationResult._({
    required this.isConsistent,
    required this.removeEventIds,
    this.reason,
  });

  const BatchValidationResult.consistent({required List<String> removeEventIds})
      : this._(isConsistent: true, removeEventIds: removeEventIds);

  const BatchValidationResult.inconsistent(String reason)
      : this._(
          isConsistent: false,
          removeEventIds: const [],
          reason: reason,
        );

  final bool isConsistent;
  final List<String> removeEventIds;
  final String? reason;
}

class AnalyticsRejectedItem {
  const AnalyticsRejectedItem({
    required this.eventId,
    required this.reason,
    this.detail,
  });

  factory AnalyticsRejectedItem.fromJson(Map<String, dynamic> json) {
    return AnalyticsRejectedItem(
      eventId: json['eventId'] as String? ?? 'unknown',
      reason: json['reason'] as String? ?? 'UNKNOWN',
      detail: json['detail'] as String?,
    );
  }

  final String eventId;
  final String reason;
  final String? detail;
}
