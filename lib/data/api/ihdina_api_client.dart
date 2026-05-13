import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Backend-Fehlercodes (V1) — Server ist maßgeblich.
abstract class IhdinaApiErrorCodes {
  static const freeLimitReached = 'FREE_LIMIT_REACHED';
  static const proRequired = 'PRO_REQUIRED';
  static const followupLimitReached = 'FOLLOWUP_LIMIT_REACHED';
  static const invalidInput = 'INVALID_INPUT';
  static const aiTemporarilyUnavailable = 'AI_TEMPORARILY_UNAVAILABLE';
}

/// Antwort mit strukturiertem Fehlercode vom Ihdina-Backend.
class IhdinaApiException implements Exception {
  IhdinaApiException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => message;
}

/// Minimaler HTTP-Client für `/api/v1/*` (keine Secrets im Client).
class IhdinaApiClient {
  IhdinaApiClient._();

  static final IhdinaApiClient instance = IhdinaApiClient._();

  static const Duration _timeout = Duration(seconds: 12);
  /// KI-Endpunkte (OpenAI) brauchen auf Mobilfunk oft länger als Health/Entitlement.
  static const Duration _timeoutAi = Duration(seconds: 45);

  /// Ohne abschließenden Slash. Priorität: `--dart-define=API_BASE_URL=`, sonst Debug-`.env`.
  String get baseUrl {
    const fromDefine = String.fromEnvironment('API_BASE_URL');
    if (fromDefine.trim().isNotEmpty) {
      return fromDefine.trim().replaceAll(RegExp(r'/+$'), '');
    }
    // dotenv.env wirft NotInitializedError, wenn load() fehlgeschlagen hat / .env fehlt (z. B. Gerät).
    if (kDebugMode && dotenv.isInitialized) {
      final fromDot = dotenv.env['API_BASE_URL']?.trim();
      if (fromDot != null && fromDot.isNotEmpty) {
        return fromDot.replaceAll(RegExp(r'/+$'), '');
      }
    }
    return 'https://api.ihdina.app';
  }

  bool get isConfigured => baseUrl.isNotEmpty;

  Uri _uri(String path) {
    final root = baseUrl;
    if (path.startsWith('/')) {
      return Uri.parse('$root$path');
    }
    return Uri.parse('$root/$path');
  }

  Future<Map<String, dynamic>> fetchEntitlement(String installId) async {
    final res = await http
        .get(
          _uri('/api/v1/entitlement/${Uri.encodeComponent(installId)}'),
          headers: const {'Accept': 'application/json'},
        )
        .timeout(_timeout);
    return _parseJsonObjectResponse(res);
  }

  Future<Map<String, dynamic>> postExplain({
    required String installId,
    required String surahName,
    required int ayahNumber,
    required String textAr,
    required String textDe,
    required String language,
    required bool isDailyVerse,
  }) async {
    final uri = _uri('/api/v1/explain');
    try {
      final res = await http
          .post(
            uri,
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'installId': installId,
              'surahName': surahName,
              'ayahNumber': ayahNumber,
              'textAr': textAr,
              'textDe': textDe,
              'language': language,
              'isDailyVerse': isDailyVerse,
            }),
          )
          .timeout(_timeoutAi);
      return _parseJsonObjectResponse(res, context: 'postExplain', uri: uri);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[IhdinaApi] postExplain FEHLER url=$uri → $e');
        debugPrint('$st');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> postFollowUp({
    required String installId,
    required String surahName,
    required int ayahNumber,
    required List<Map<String, String>> history,
    required String question,
    required String language,
  }) async {
    final res = await http
        .post(
          _uri('/api/v1/follow-up'),
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'installId': installId,
            'surahName': surahName,
            'ayahNumber': ayahNumber,
            'history': history,
            'question': question,
            'language': language,
          }),
        )
        .timeout(_timeoutAi);
    return _parseJsonObjectResponse(res, context: 'postFollowUp');
  }

  /// In-App-Feedback (öffentlich, kein Admin-Key). [rating]: z. B. -1 / 0 / 1 oder 1–5.
  Future<Map<String, dynamic>> postFeedback({
    required String installId,
    int? rating,
    String? comment,
    String? screen,
    String? context,
  }) async {
    final body = <String, dynamic>{'installId': installId};
    if (rating != null) body['rating'] = rating;
    if (comment != null && comment.trim().isNotEmpty) {
      body['comment'] = comment.trim();
    }
    if (screen != null && screen.trim().isNotEmpty) {
      body['screen'] = screen.trim();
    }
    if (context != null && context.trim().isNotEmpty) {
      body['context'] = context.trim();
    }
    final res = await http
        .post(
          _uri('/api/v1/feedback'),
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(_timeout);
    return _parseJsonObjectResponse(res, context: 'postFeedback');
  }

  Future<Map<String, dynamic>> postTakeaway({
    required String surahName,
    required int ayahNumber,
    required String textAr,
    required String textDe,
  }) async {
    final res = await http
        .post(
          _uri('/api/v1/takeaway'),
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'surahName': surahName,
            'ayahNumber': ayahNumber,
            'textAr': textAr,
            'textDe': textDe,
          }),
        )
        .timeout(_timeout);
    return _parseJsonObjectResponse(res, context: 'postTakeaway');
  }

  Map<String, dynamic> _parseJsonObjectResponse(
    http.Response res, {
    String context = 'api',
    Uri? uri,
  }) {
    Map<String, dynamic>? decoded;
    try {
      final raw = jsonDecode(res.body);
      if (raw is Map<String, dynamic>) decoded = raw;
    } catch (_) {}

    if (decoded == null) {
      if (kDebugMode) {
        final b = res.body;
        final snippet = b.length > 600 ? '${b.substring(0, 600)}…' : b;
        debugPrint(
          '[IhdinaApi] $context: kein JSON (HTTP ${res.statusCode}) url=${uri ?? "?"} body=$snippet',
        );
      }
      throw IhdinaApiException(
        IhdinaApiErrorCodes.aiTemporarilyUnavailable,
        'Ungültige Server-Antwort.',
      );
    }

    final success = decoded['success'];
    if (success == true) {
      final data = decoded['data'];
      if (data is Map<String, dynamic>) return data;
      return <String, dynamic>{};
    }

    final err = decoded['error'];
    if (err is Map<String, dynamic>) {
      final code = err['code'] as String? ?? IhdinaApiErrorCodes.invalidInput;
      final message = err['message'] as String? ?? 'Anfrage fehlgeschlagen.';
      if (kDebugMode) {
        debugPrint(
          '[IhdinaApi] $context: success=false HTTP ${res.statusCode} code=$code msg=$message url=${uri ?? "?"}',
        );
      }
      throw IhdinaApiException(code, message);
    }

    if (res.statusCode >= 500) {
      if (kDebugMode) {
        final b = res.body;
        final snippet = b.length > 400 ? '${b.substring(0, 400)}…' : b;
        debugPrint(
          '[IhdinaApi] $context: HTTP ${res.statusCode} (kein error-Objekt) url=${uri ?? "?"} body=$snippet',
        );
      }
      throw IhdinaApiException(
        IhdinaApiErrorCodes.aiTemporarilyUnavailable,
        'Server vorübergehend nicht erreichbar.',
      );
    }

    if (kDebugMode) {
      debugPrint(
        '[IhdinaApi] $context: HTTP ${res.statusCode} success=${decoded['success']} url=${uri ?? "?"}',
      );
    }
    throw IhdinaApiException(
      IhdinaApiErrorCodes.invalidInput,
      'Anfrage fehlgeschlagen (HTTP ${res.statusCode}).',
    );
  }
}
