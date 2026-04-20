import 'dart:convert';

import 'package:flutter/foundation.dart';
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
    final res = await http
        .post(
          _uri('/api/v1/explain'),
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
        .timeout(_timeout);
    return _parseJsonObjectResponse(res);
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
        .timeout(_timeout);
    return _parseJsonObjectResponse(res);
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
    return _parseJsonObjectResponse(res);
  }

  Map<String, dynamic> _parseJsonObjectResponse(http.Response res) {
    Map<String, dynamic>? decoded;
    try {
      final raw = jsonDecode(res.body);
      if (raw is Map<String, dynamic>) decoded = raw;
    } catch (_) {}

    if (decoded == null) {
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
      throw IhdinaApiException(code, message);
    }

    if (res.statusCode >= 500) {
      throw IhdinaApiException(
        IhdinaApiErrorCodes.aiTemporarilyUnavailable,
        'Server vorübergehend nicht erreichbar.',
      );
    }

    throw IhdinaApiException(
      IhdinaApiErrorCodes.invalidInput,
      'Anfrage fehlgeschlagen (HTTP ${res.statusCode}).',
    );
  }
}
