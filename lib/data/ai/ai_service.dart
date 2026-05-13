import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../api/ihdina_api_client.dart';
import 'related_ayah_ref.dart';

/// In release builds we must not ship or read any secret API keys from the client.
/// Nur für [chatCompletionOneShot] (Tages-Impuls) in Debug.
String get _openAiApiKey {
  const fromDefine = String.fromEnvironment('OPENAI_API_KEY');
  if (kDebugMode && fromDefine.isNotEmpty) return fromDefine;

  if (kDebugMode) {
    final v = dotenv.env['OPENAI_API_KEY'];
    return v ?? '';
  }

  return '';
}

const String _aiUnavailableMessage = 'AI feature currently unavailable.';

/// Returned in release builds when the API is not available (matches [_aiUnavailableMessage]).
String get aiUnavailableMessage => _aiUnavailableMessage;

/// Thrown when the daily limit for AI explanations is reached.
class AIRateLimitException implements Exception {
  AIRateLimitException([this.message = 'Tägliches Limit für KI-Erklärungen erreicht. Bitte versuche es morgen wieder.']);
  final String message;
  @override
  String toString() => message;
}

/// Thrown on API or network errors.
class AIServiceException implements Exception {
  AIServiceException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// System prompt for the verse explanation chat. Exposed for building conversation history in follow-ups.
const String aiSystemPrompt = r'''Du bist ein hilfsbereiter, islamischer Bildungs-Assistent für eine Premium-Koran-App. Deine Aufgabe ist es, Koranverse basierend auf klassischem, anerkanntem Tafsir (wie Ibn Kathir) auf Deutsch zu erklären. 
REGELN: 1. Erkläre den Kontext und die Bedeutung für das heutige Leben. 2. Du darfst NIEMALS Fiqh-Fragen beantworten, Fatwas erteilen oder Dinge als Haram/Halal deklarieren. Wenn eine Frage in diese Richtung geht, weise höflich darauf hin, dass du eine KI bist und der Nutzer einen qualifizierten Gelehrten fragen soll. 3. Antworte in klarem, respektvollem und leicht verständlichem Deutsch. Formatiere die Antwort mit kurzen Absätzen.''';

const String _cacheKeyPrefix = 'ai_exp_';

/// Ergebnis von [AIService.getExplanation] (Roh-`text` + optionale Verse aus Server-Parsing).
class AiExplanationResult {
  const AiExplanationResult(this.text, {this.relatedAyahs = const []});

  final String text;
  final List<RelatedAyahRef> relatedAyahs;
}

class AiFollowUpResult {
  AiFollowUpResult({
    required this.text,
    required this.remainingFollowUpsForVerse,
    this.relatedAyahs = const [],
  });

  final String text;
  final int remainingFollowUpsForVerse;
  final List<RelatedAyahRef> relatedAyahs;
}

/// Vers-Erklärung und Follow-up über Ihdina-Backend; Tages-Impuls weiterhin optional per OpenAI (nur Debug).
class AIService {
  AIService._();

  static final AIService instance = AIService._();

  static String cacheKey(String surahName, int ayahNumber) {
    return '$_cacheKeyPrefix${surahName}_$ayahNumber';
  }

  /// Ein einzelner Chat-Completion-Call (z. B. kurzer Tages-Impuls). Nur Debug + OpenAI-Key; sonst [aiUnavailableMessage].
  Future<String> chatCompletionOneShot({
    required String systemPrompt,
    required String userPrompt,
    int maxTokens = 150,
    double temperature = 0.45,
  }) {
    return _executeChatCompletion(
      messages: [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userPrompt},
      ],
      maxTokens: maxTokens,
      temperature: temperature,
    );
  }

  Future<String> _executeChatCompletion({
    required List<Map<String, String>> messages,
    int maxTokens = 800,
    double temperature = 0.5,
  }) async {
    if (!kDebugMode) {
      return _aiUnavailableMessage;
    }

    if (_openAiApiKey.isEmpty || _openAiApiKey == 'your_key_here') {
      throw AIServiceException(
        'OpenAI API-Schlüssel nicht konfiguriert. (Debug) Bitte OPENAI_API_KEY via --dart-define setzen oder lokal in einer .env Datei hinterlegen.',
      );
    }

    final body = {
      'model': 'gpt-4o-mini',
      'messages': messages,
      'max_tokens': maxTokens,
      'temperature': temperature,
    };

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_openAiApiKey',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      final errBody = response.body;
      String msg = 'API-Fehler (${response.statusCode})';
      try {
        final decoded = jsonDecode(errBody) as Map<String, dynamic>;
        final error = decoded['error'];
        if (error is Map && error['message'] != null) {
          msg = error['message'] as String;
        }
      } catch (_) {}
      throw AIServiceException(msg);
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = decoded['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw AIServiceException('Keine Antwort von der KI erhalten.');
    }
    final first = choices.first as Map<String, dynamic>;
    final message = first['message'] as Map<String, dynamic>?;
    final content = message?['content'] as String?;
    if (content == null || content.trim().isEmpty) {
      throw AIServiceException('Leere Antwort von der KI.');
    }

    return content.trim();
  }

  /// Lädt die Verserklärung vom Backend. Bei Cache-Treffer: sofortige Rückgabe — kein Backend-Call.
  /// `relatedAyahs` nur bei frischer Server-Antwort; im Cache nicht gespeichert.
  Future<AiExplanationResult> getExplanation(
    String surahName,
    int ayahNumber,
    String textAr,
    String textDe, {
    required String installId,
    required bool isDailyVerse,
    String language = 'de',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = cacheKey(surahName, ayahNumber);
    final cached = prefs.getString(key);
    if (cached != null && cached.trim().isNotEmpty) {
      return AiExplanationResult(cached.trim());
    }

    final client = IhdinaApiClient.instance;
    if (!client.isConfigured) {
      throw AIServiceException(
        'Backend nicht konfiguriert. Setze API_BASE_URL (z. B. --dart-define=API_BASE_URL=https://… oder in Debug .env).',
      );
    }

    try {
      final data = await client.postExplain(
        installId: installId,
        surahName: surahName,
        ayahNumber: ayahNumber,
        textAr: textAr,
        textDe: textDe,
        language: language,
        isDailyVerse: isDailyVerse,
      );
      final text = data['text'] as String? ?? '';
      final trimmed = text.trim();
      if (trimmed.isEmpty) {
        throw AIServiceException('Leere Antwort vom Server.');
      }
      final related = relatedAyahsFromApiJson(data['relatedAyahs']);
      await prefs.setString(key, trimmed);
      return AiExplanationResult(trimmed, relatedAyahs: related);
    } on IhdinaApiException catch (e) {
      if (kDebugMode) {
        debugPrint('[AIService] getExplanation API ${e.code}: ${e.message}');
      }
      rethrow;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[AIService] getExplanation $e');
        debugPrint('$st');
      }
      if (e is AIServiceException) rethrow;
      throw AIServiceException(
        'Netzwerk- oder Serverfehler. Bitte später erneut versuchen.',
      );
    }
  }

  /// Follow-up für einen Vers; [history] ohne die neue Nutzerfrage (Server bekommt [question] separat).
  Future<AiFollowUpResult> askFollowUpForVerse({
    required String installId,
    required String surahName,
    required int ayahNumber,
    required List<Map<String, String>> history,
    required String question,
    String language = 'de',
  }) async {
    final client = IhdinaApiClient.instance;
    if (!client.isConfigured) {
      throw AIServiceException(
        'Backend nicht konfiguriert. Setze API_BASE_URL (z. B. --dart-define=API_BASE_URL=https://… oder in Debug .env).',
      );
    }

    try {
      final data = await client.postFollowUp(
        installId: installId,
        surahName: surahName,
        ayahNumber: ayahNumber,
        history: history,
        question: question,
        language: language,
      );
      final text = data['text'] as String? ?? '';
      final trimmed = text.trim();
      if (trimmed.isEmpty) {
        throw AIServiceException('Leere Antwort vom Server.');
      }
      final remRaw = data['remainingFollowUpsForVerse'];
      final remaining = remRaw is int
          ? remRaw
          : (remRaw is num ? remRaw.toInt() : 0);
      final related = relatedAyahsFromApiJson(data['relatedAyahs']);
      return AiFollowUpResult(
        text: trimmed,
        remainingFollowUpsForVerse: remaining,
        relatedAyahs: related,
      );
    } on IhdinaApiException catch (_) {
      rethrow;
    } catch (e) {
      if (e is AIServiceException) rethrow;
      throw AIServiceException(
        'Netzwerk- oder Serverfehler. Bitte später erneut versuchen.',
      );
    }
  }
}
