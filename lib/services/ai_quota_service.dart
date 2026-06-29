import 'package:shared_preferences/shared_preferences.dart';

/// Freemium AI daily quota: 2 free requests per day (resets at midnight local).
/// Verse of the Day is always free and does not consume tokens.
class AiQuotaService {
  AiQuotaService._();

  static final AiQuotaService instance = AiQuotaService._();

  static const String _lastDateKey = 'ai_quota_last_date';
  static const String _tokensUsedKey = 'ai_quota_tokens_used';
  static const int _dailyLimit = 2;

  /// Ensures date is current; resets tokens if a new calendar day has started.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final savedDate = prefs.getString(_lastDateKey);

    if (savedDate != today || savedDate == null) {
      await prefs.setString(_lastDateKey, today);
      await prefs.setInt(_tokensUsedKey, 0);
    }
  }

  /// Returns remaining free tokens for today (0 to [_dailyLimit]).
  Future<int> getRemainingTokens() async {
    await init();
    final prefs = await SharedPreferences.getInstance();
    final used = prefs.getInt(_tokensUsedKey) ?? 0;
    return (_dailyLimit - used).clamp(0, _dailyLimit);
  }

  /// Returns true if the user can make another free API call today.
  Future<bool> canUseApi() async {
    return (await getRemainingTokens()) > 0;
  }

  /// Records one token use. Call after a non–Verse-of-the-Day AI request.
  Future<void> consumeToken() async {
    await init();
    final prefs = await SharedPreferences.getInstance();
    final used = (prefs.getInt(_tokensUsedKey) ?? 0) + 1;
    await prefs.setInt(_tokensUsedKey, used);
  }
}
