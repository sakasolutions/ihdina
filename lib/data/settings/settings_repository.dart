import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../db/database_provider.dart';
import '../prayer/prayer_models.dart';

const String _keyArabicFontSize = 'arabic_font_size';
const String _keyArabicLineHeight = 'arabic_line_height';
const double _defaultArabicFontSize = 28;
const double _defaultArabicLineHeight = 1.8;

const String _keyPrayerLat = 'prayer_lat';
const String _keyPrayerLng = 'prayer_lng';
const String _keyPrayerLocationLabel = 'prayer_location_label';
const String _keyPrayerMethod = 'prayer_method';
const String _keyPrayerMadhab = 'prayer_madhab';
const String _keyNotificationsEnabled = 'notifications_enabled';
const String _keyDailyAyahReminderEnabled = 'daily_ayah_reminder_enabled';
const String _keySurahIntroAutoShow = 'surah_intro_auto_show';
const String _keySurahIntroAutoShownSurahIds = 'surah_intro_auto_shown_surah_ids';
const String _keyQuranReaderLayout = 'quran_reader_layout';
const String _keyQuranPageScript = 'quran_page_script';
const double _defaultLat = 48.68;
const double _defaultLng = 10.15;
const String _defaultLocationLabel = 'Default';

/// App settings stored in SQLite. Offline-only.
class SettingsRepository {
  SettingsRepository._();

  static final SettingsRepository instance = SettingsRepository._();

  Future<Database> get _db => DatabaseProvider.instance.database;

  Future<double> getArabicFontSize() async {
    final v = await _get(_keyArabicFontSize);
    if (v == null) return _defaultArabicFontSize;
    return double.tryParse(v) ?? _defaultArabicFontSize;
  }

  Future<double> getArabicLineHeight() async {
    final v = await _get(_keyArabicLineHeight);
    if (v == null) return _defaultArabicLineHeight;
    return double.tryParse(v) ?? _defaultArabicLineHeight;
  }

  Future<void> setArabicFontSize(double v) async {
    await _set(_keyArabicFontSize, v.toString());
  }

  Future<void> setArabicLineHeight(double v) async {
    await _set(_keyArabicLineHeight, v.toString());
  }

  Future<PrayerSettings> getPrayerSettings() async {
    final latStr = await _get(_keyPrayerLat);
    final lngStr = await _get(_keyPrayerLng);
    final label = await _get(_keyPrayerLocationLabel);
    final methodStr = await _get(_keyPrayerMethod);
    final madhabStr = await _get(_keyPrayerMadhab);
    assert(() {
      // Debug: prüfen, ob Madhab (Hanafi/Shafi) korrekt aus DB gelesen wird
      debugPrint('[SETTINGS] getPrayerSettings: prayer_madhab aus DB = "${madhabStr ?? "null"}"');
      return true;
    }());

    final lat = latStr != null && latStr.isNotEmpty
        ? (double.tryParse(latStr) ?? _defaultLat)
        : _defaultLat;
    final lng = lngStr != null && lngStr.isNotEmpty
        ? (double.tryParse(lngStr) ?? _defaultLng)
        : _defaultLng;
    final locationLabel = label?.isNotEmpty == true ? label! : _defaultLocationLabel;
    final method = PrayerMethodOption.fromValue(methodStr ?? 'mwl');
    final madhab = MadhabOption.fromValue(madhabStr ?? 'shafi');

    return PrayerSettings(
      latitude: lat,
      longitude: lng,
      locationLabel: locationLabel,
      method: method,
      madhab: madhab,
      useDeviceLocation: false,
    );
  }

  Future<void> setPrayerSettings(PrayerSettings s) async {
    assert(() {
      debugPrint('[SETTINGS] setPrayerSettings: speichere madhab="${s.madhab.name}" (${s.madhab == MadhabOption.hanafi ? "Hanafi/Asr 2x" : "Shafi/Asr 1x"})');
      return true;
    }());
    await _set(_keyPrayerLat, s.latitude.toStringAsFixed(6));
    await _set(_keyPrayerLng, s.longitude.toStringAsFixed(6));
    await _set(_keyPrayerLocationLabel, s.locationLabel);
    await _set(_keyPrayerMethod, s.method.value);
    await _set(_keyPrayerMadhab, s.madhab.name);
  }

  /// Returns stored prayer location (label + lat/lng). Uses defaults if never set.
  Future<({String label, double lat, double lng})> getPrayerLocation() async {
    final settings = await getPrayerSettings();
    return (label: settings.locationLabel, lat: settings.latitude, lng: settings.longitude);
  }

  Future<bool> getNotificationsEnabled() async {
    final v = await _get(_keyNotificationsEnabled);
    if (v == null) return true;
    return v == 'true';
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _set(_keyNotificationsEnabled, enabled ? 'true' : 'false');
  }

  Future<bool> getDailyAyahReminderEnabled() async {
    final v = await _get(_keyDailyAyahReminderEnabled);
    if (v == null) return false;
    return v == 'true';
  }

  Future<void> setDailyAyahReminderEnabled(bool enabled) async {
    await _set(_keyDailyAyahReminderEnabled, enabled ? 'true' : 'false');
  }

  /// Sure-Kurzintro beim ersten Öffnen einer Sure im Reader (Standard: an).
  Future<bool> getSurahIntroAutoShow() async {
    final v = await _get(_keySurahIntroAutoShow);
    if (v == null) return true;
    return v == 'true' || v == '1';
  }

  Future<void> setSurahIntroAutoShow(bool enabled) async {
    await _set(_keySurahIntroAutoShow, enabled ? 'true' : 'false');
  }

  /// Sure-IDs, für die das Intro bereits automatisch gezeigt wurde (kommagetrennt).
  Future<Set<int>> getSurahIntroAutoShownSurahIds() async {
    final v = await _get(_keySurahIntroAutoShownSurahIds);
    if (v == null || v.trim().isEmpty) return {};
    return v
        .split(',')
        .map((s) => int.tryParse(s.trim()))
        .whereType<int>()
        .toSet();
  }

  Future<void> addSurahIntroAutoShownSurahId(int surahId) async {
    final set = await getSurahIntroAutoShownSurahIds();
    set.add(surahId);
    final sorted = set.toList()..sort();
    await _set(_keySurahIntroAutoShownSurahIds, sorted.join(','));
  }

  /// `cards` = Standard (Vers für Vers), `page` = Seitenlesen (Beta).
  Future<String> getQuranReaderLayout() async {
    final v = await _get(_keyQuranReaderLayout);
    if (v == null || v.isEmpty) return 'cards';
    return v == 'page' ? 'page' : 'cards';
  }

  Future<void> setQuranReaderLayout(String layout) async {
    await _set(_keyQuranReaderLayout, layout == 'page' ? 'page' : 'cards');
  }

  /// Nur Seitenmodus: welcher Fließtext — `arabic` oder `german`.
  Future<String> getQuranPageScript() async {
    final v = await _get(_keyQuranPageScript);
    if (v == null || v.isEmpty) return 'arabic';
    return v == 'german' ? 'german' : 'arabic';
  }

  Future<void> setQuranPageScript(String script) async {
    await _set(_keyQuranPageScript, script == 'german' ? 'german' : 'arabic');
  }

  /// Saves selected city/location for prayer times (label + lat/lng). Keeps method/madhab unchanged.
  Future<void> setPrayerLocation(String label, double lat, double lng) async {
    final current = await getPrayerSettings();
    await setPrayerSettings(current.copyWith(
      locationLabel: label,
      latitude: lat,
      longitude: lng,
    ));
  }

  Future<String?> _get(String key) async {
    final db = await _db;
    final rows = await db.query(
      'settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> _set(String key, String value) async {
    final db = await _db;
    await db.rawInsert(
      'INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)',
      [key, value],
    );
  }
}
