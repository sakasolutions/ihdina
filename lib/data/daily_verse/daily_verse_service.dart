import 'dart:math' show Random;

import 'package:shared_preferences/shared_preferences.dart';

import '../quran/models/ayah_model.dart';
import '../quran/models/surah_model.dart';
import '../quran/quran_repository.dart';
import '../quran/translation_service.dart';

const String _keyDate = 'daily_verse_date';
const String _keySurah = 'daily_surah';
const String _keyAyah = 'daily_ayah';

/// Verse of the day: same verse for 24h (local date), stored in SharedPreferences.
class DailyVerseService {
  DailyVerseService._();

  static final DailyVerseService instance = DailyVerseService._();

  static final Random _random = Random();

  /// Returns today's verse (cached by date). Map keys: surahId, surahNameEn, surahNameAr, ayahNumber, textAr, textDe.
  Future<Map<String, dynamic>> getVerseOfTheDay() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString(_keyDate);

    int surahId;
    int ayahNumber;

    if (savedDate == today) {
      final s = prefs.getInt(_keySurah);
      final a = prefs.getInt(_keyAyah);
      if (s != null && a != null && s >= 1 && s <= 114) {
        surahId = s;
        ayahNumber = a;
      } else {
        final generated = await _pickAndSaveNewVerse(prefs, today);
        surahId = generated.$1;
        ayahNumber = generated.$2;
      }
    } else {
      final generated = await _pickAndSaveNewVerse(prefs, today);
      surahId = generated.$1;
      ayahNumber = generated.$2;
    }

    return _fetchVerseData(surahId, ayahNumber);
  }

  Future<(int, int)> _pickAndSaveNewVerse(SharedPreferences prefs, String today) async {
    final surahs = await QuranRepository.instance.getAllSurahs();
    if (surahs.isEmpty) {
      await prefs.setString(_keyDate, today);
      await prefs.setInt(_keySurah, 1);
      await prefs.setInt(_keyAyah, 1);
      return (1, 1);
    }

    final surah = surahs[_random.nextInt(surahs.length)];
    final count = surah.ayahCount > 0 ? surah.ayahCount : 1;
    final ayah = 1 + _random.nextInt(count);

    await prefs.setString(_keyDate, today);
    await prefs.setInt(_keySurah, surah.id);
    await prefs.setInt(_keyAyah, ayah);
    return (surah.id, ayah);
  }

  Future<Map<String, dynamic>> _fetchVerseData(int surahId, int ayahNumber) async {
    await TranslationService.instance.ensureLoaded();
    final surahs = await QuranRepository.instance.getAllSurahs();
    SurahModel? surahModel;
    for (final s in surahs) {
      if (s.id == surahId) {
        surahModel = s;
        break;
      }
    }
    final surahNameEn = surahModel?.nameEn ?? 'Sure $surahId';
    final surahNameAr = surahModel?.nameAr ?? '';

    final ayahs = await QuranRepository.instance.getAyahsBySurahId(surahId);
    AyahModel? ayahModel;
    for (final a in ayahs) {
      if (a.ayahNumber == ayahNumber) {
        ayahModel = a;
        break;
      }
    }
    final textAr = ayahModel?.textAr ?? '';

    final textDe = TranslationService.instance.getTranslation(surahId, ayahNumber);

    return {
      'surahId': surahId,
      'surahNameEn': surahNameEn,
      'surahNameAr': surahNameAr,
      'ayahNumber': ayahNumber,
      'textAr': textAr,
      'textDe': textDe.isNotEmpty ? textDe : '—',
    };
  }
}
