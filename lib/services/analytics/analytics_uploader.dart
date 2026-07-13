import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';

import '../../data/api/ihdina_api_client.dart';
import 'analytics_constants.dart';
import 'analytics_ingest_response.dart';
import 'analytics_queue_store.dart';

typedef AnalyticsUploadFn = Future<AnalyticsIngestResponse> Function(
  String installId,
  List<Map<String, dynamic>> events,
);

/// Lädt Batches hoch mit Retry/Backoff.
class AnalyticsUploader {
  AnalyticsUploader({
    AnalyticsUploadFn? uploadFn,
    Random? random,
  })  : _uploadFn = uploadFn ?? _defaultUpload,
        _random = random ?? Random();

  final AnalyticsUploadFn _uploadFn;
  final Random _random;

  Duration _backoff = AnalyticsConstants.retryInitial;
  DateTime? _retryAfter;

  static Future<AnalyticsIngestResponse> _defaultUpload(
    String installId,
    List<Map<String, dynamic>> events,
  ) async {
    final data = await IhdinaApiClient.instance.postAnalyticsEvents(
      installId: installId,
      events: events,
    );
    return AnalyticsIngestResponse.fromJson(data);
  }

  bool get canAttemptNow {
    if (_retryAfter == null) return true;
    return DateTime.now().toUtc().isAfter(_retryAfter!);
  }

  Future<UploadAttemptResult> uploadBatch({
    required String installId,
    required List<QueuedAnalyticsEvent> batch,
    int? retryAfterSeconds,
  }) async {
    if (!canAttemptNow) {
      return const UploadAttemptResult.networkFailure();
    }
    try {
      final response = await _uploadFn(
        installId,
        batch.map((e) => e.payload).toList(),
      );
      _backoff = AnalyticsConstants.retryInitial;
      _retryAfter = null;

      final batchIds = batch.map((e) => e.eventId).toList();
      final validation = AnalyticsBatchResponseValidator.validate(
        response: response,
        batchEventIds: batchIds,
      );
      if (!validation.isConsistent) {
        if (kDebugMode) {
          debugPrint(
            '[Analytics] inconsistent batch response: ${validation.reason}',
          );
        }
        return UploadAttemptResult.inconsistentResponse();
      }

      return UploadAttemptResult.success(
        removeEventIds: validation.removeEventIds,
        permanentlyRejected: response.rejected,
      );
    } on IhdinaApiException catch (e) {
      if (e.code == 'RATE_LIMIT_EXCEEDED') {
        final match = RegExp(r'retry after (\d+)').firstMatch(e.message);
        final sec = int.tryParse(match?.group(1) ?? '');
        return _handleHttpFailure(sec);
      }
      if (e.code == IhdinaApiErrorCodes.aiTemporarilyUnavailable) {
        return _handleHttpFailure(retryAfterSeconds);
      }
      return const UploadAttemptResult.networkFailure();
    } catch (_) {
      return _handleHttpFailure(retryAfterSeconds);
    }
  }

  UploadAttemptResult _handleHttpFailure(int? retryAfterSeconds) {
    final base = retryAfterSeconds != null
        ? Duration(seconds: retryAfterSeconds)
        : _backoff;
    final jitterMs = _random.nextInt(1000);
    _retryAfter =
        DateTime.now().toUtc().add(base + Duration(milliseconds: jitterMs));
    _backoff = Duration(
      milliseconds: min(
        _backoff.inMilliseconds * 2,
        AnalyticsConstants.retryMax.inMilliseconds,
      ),
    );
    return const UploadAttemptResult.networkFailure();
  }

  @visibleForTesting
  void resetBackoff() {
    _backoff = AnalyticsConstants.retryInitial;
    _retryAfter = null;
  }
}

class UploadAttemptResult {
  const UploadAttemptResult._({
    required this.success,
    this.removeEventIds = const [],
    this.permanentlyRejected = const [],
    this.inconsistentResponse = false,
  });

  const UploadAttemptResult.success({
    required List<String> removeEventIds,
    required List<AnalyticsRejectedItem> permanentlyRejected,
  }) : this._(
          success: true,
          removeEventIds: removeEventIds,
          permanentlyRejected: permanentlyRejected,
        );

  const UploadAttemptResult.networkFailure() : this._(success: false);

  const UploadAttemptResult.inconsistentResponse()
      : this._(success: false, inconsistentResponse: true);

  final bool success;
  final List<String> removeEventIds;
  final List<AnalyticsRejectedItem> permanentlyRejected;
  final bool inconsistentResponse;
}
