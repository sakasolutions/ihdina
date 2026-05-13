import 'package:flutter/foundation.dart';

import '../data/api/ihdina_api_client.dart';
import 'install_id_service.dart';

/// Sendet In-App-Feedback ans Ihdina-Backend ([IhdinaApiClient.postFeedback] → `AppFeedback` / Admin-Panel).
class AppFeedbackService {
  AppFeedbackService._();

  /// `true`, wenn der Server „success“ zurückgab.
  static Future<bool> send({
    required int rating,
    String? comment,
    String? screen,
    String? context,
  }) async {
    try {
      final installId = await InstallIdService.instance.getOrCreate();
      await IhdinaApiClient.instance.postFeedback(
        installId: installId,
        rating: rating,
        comment: comment,
        screen: screen,
        context: context,
      );
      return true;
    } on IhdinaApiException catch (e, st) {
      if (kDebugMode) {
        debugPrint('[Feedback] API: ${e.code} ${e.message}');
        debugPrint('$st');
      }
      return false;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[Feedback] $e');
        debugPrint('$st');
      }
      return false;
    }
  }
}
