import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../prayer/prayer_type.dart';
import 'prayer_models.dart';

/// Offline prayer times calculation using adhan_dart.
class PrayerTimesRepository {
  PrayerTimesRepository._();

  static final PrayerTimesRepository instance = PrayerTimesRepository._();


  /// Convert UTC DateTime from adhan to local.
  static DateTime _toLocal(DateTime utc) {
    return DateTime.fromMillisecondsSinceEpoch(
      utc.millisecondsSinceEpoch,
      isUtc: true,
    ).toLocal();
  }

  /// Round to nearest minute so times match common sources (Google, mosques).
  static DateTime _roundToMinute(DateTime t) {
    final sec = t.second + t.millisecond / 1000;
    final addMin = sec >= 30 ? 1 : 0;
    return DateTime(t.year, t.month, t.day, t.hour, t.minute + addMin, 0, 0);
  }

  /// Get CalculationParameters for the given method and madhab.
  /// Madhab wird im Konstruktor gesetzt, damit die Bibliothek Asr korrekt berechnet (Hanafi = 2x Schatten, später).
  CalculationParameters _paramsFromSettings(PrayerSettings settings) {
    CalculationParameters params;
    switch (settings.method) {
      case PrayerMethodOption.mwl:
        params = CalculationMethodParameters.muslimWorldLeague();
        break;
      case PrayerMethodOption.isna:
        params = CalculationMethodParameters.northAmerica();
        break;
      case PrayerMethodOption.egyptian:
        params = CalculationMethodParameters.egyptian();
        break;
      case PrayerMethodOption.ummAlQura:
        params = CalculationMethodParameters.ummAlQura();
        break;
      case PrayerMethodOption.karachi:
        params = CalculationMethodParameters.karachi();
        break;
      case PrayerMethodOption.turkiye:
        params = CalculationMethodParameters.turkiye();
        break;
      case PrayerMethodOption.tehran:
        params = CalculationMethodParameters.tehran();
        break;
    }

    final madhab = settings.madhab == MadhabOption.hanafi ? Madhab.hanafi : Madhab.shafi;
    params.madhab = madhab;

    // User adjustments (minutes)
    if (settings.adjustmentMinutesFajr != null) {
      params.adjustments[Prayer.fajr] = settings.adjustmentMinutesFajr!;
    }
    if (settings.adjustmentMinutesDhuhr != null) {
      params.adjustments[Prayer.dhuhr] = settings.adjustmentMinutesDhuhr!;
    }
    if (settings.adjustmentMinutesAsr != null) {
      params.adjustments[Prayer.asr] = settings.adjustmentMinutesAsr!;
    }
    if (settings.adjustmentMinutesMaghrib != null) {
      params.adjustments[Prayer.maghrib] = settings.adjustmentMinutesMaghrib!;
    }
    if (settings.adjustmentMinutesIsha != null) {
      params.adjustments[Prayer.isha] = settings.adjustmentMinutesIsha!;
    }

    // Frisches CalculationParameters mit madhab im Konstruktor übergeben, damit adhan_dart Asr (Hanafi 2x) zuverlässig nutzt.
    final out = CalculationParameters(
      method: params.method,
      fajrAngle: params.fajrAngle,
      ishaAngle: params.ishaAngle,
      ishaInterval: params.ishaInterval,
      maghribAngle: params.maghribAngle,
      highLatitudeRule: params.highLatitudeRule,
      madhab: madhab,
      adjustments: params.adjustments,
      methodAdjustments: params.methodAdjustments,
    );
    return out;
  }

  /// Gebetszeiten für einen **lokalen Kalendertag** (nur Jahr/Monat/Tag; Uhrzeit wird ignoriert).
  /// Gleiche Rundung und Koordinaten/Methode wie [computeToday]. Für Benachrichtigungen über Tagesgrenzen.
  Map<PrayerType, DateTime> computePrayerTimesMapForDate(
    PrayerSettings settings,
    DateTime localCalendarDate,
  ) {
    final coordinates = Coordinates(settings.latitude, settings.longitude);
    final params = _paramsFromSettings(settings);
    final date = DateTime(
      localCalendarDate.year,
      localCalendarDate.month,
      localCalendarDate.day,
    );

    final pt = PrayerTimes(
      date: date,
      coordinates: coordinates,
      calculationParameters: params,
      precision: true,
    );

    return <PrayerType, DateTime>{
      PrayerType.fajr: _roundToMinute(_toLocal(pt.fajr)),
      PrayerType.sunrise: _roundToMinute(_toLocal(pt.sunrise)),
      PrayerType.dhuhr: _roundToMinute(_toLocal(pt.dhuhr)),
      PrayerType.asr: _roundToMinute(_toLocal(pt.asr)),
      PrayerType.maghrib: _roundToMinute(_toLocal(pt.maghrib)),
      PrayerType.isha: _roundToMinute(_toLocal(pt.isha)),
    };
  }

  /// Compute prayer times for the given date using settings. Returns times in local timezone.
  PrayerTimesResult computeToday(PrayerSettings settings, DateTime now) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('[PRAYER] using lat=${settings.latitude} lng=${settings.longitude} label=${settings.locationLabel}');
    }

    final times = computePrayerTimesMapForDate(
      settings,
      DateTime(now.year, now.month, now.day),
    );

    final params = _paramsFromSettings(settings);
    if (kDebugMode) {
      debugPrint('[PRAYER] params.madhab=${params.madhab?.name ?? "null"} (vor PrayerTimes)');
    }

    final fajr = times[PrayerType.fajr]!;
    final isha = times[PrayerType.isha]!;

    PrayerType nextPrayerType = PrayerType.fajr;
    DateTime nextPrayerTime = fajr;

    for (final type in prayerTypeOrderForDisplay) {
      final t = times[type]!;
      if (now.isBefore(t)) {
        nextPrayerType = type;
        nextPrayerTime = t;
        break;
      }
    }
    if (now.isAfter(isha)) {
      nextPrayerType = PrayerType.fajr;
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      final tomorrowTimes = computePrayerTimesMapForDate(settings, tomorrow);
      nextPrayerTime = tomorrowTimes[PrayerType.fajr]!;
    }

    final timeUntilNextPrayer = nextPrayerTime.difference(now);

    if (kDebugMode) {
      debugPrint(
        '[PRAYER] lat=${settings.latitude}, lng=${settings.longitude}, '
        'method=${settings.method.value}, madhab=${settings.madhab.name} (Asr ${settings.madhab == MadhabOption.hanafi ? "2x Schatten" : "1x Schatten"})',
      );
      for (final type in prayerTypeOrderForDisplay) {
        final t = times[type];
        if (t != null) debugPrint('[PRAYER] ${type.label}=${_formatTime(t)}');
      }
      debugPrint(
        '[PRAYER] next=${nextPrayerType.label} in ${timeUntilNextPrayer.inMinutes ~/ 60}:${(timeUntilNextPrayer.inMinutes % 60).toString().padLeft(2, '0')}',
      );
    }

    return PrayerTimesResult(
      times: times,
      now: now,
      nextPrayerType: nextPrayerType,
      nextPrayerTime: nextPrayerTime,
      timeUntilNextPrayer: timeUntilNextPrayer,
    );
  }

  /// Format time as HH:mm using intl.
  String formatTime(DateTime t) {
    return DateFormat('HH:mm').format(t);
  }

  static String _formatTime(DateTime t) {
    return DateFormat('HH:mm').format(t);
  }

  /// Format countdown duration as MM:SS or HH:MM depending on length.
  static String formatCountdown(Duration d) {
    if (d.isNegative) return '0:00';
    final totalMinutes = d.inMinutes;
    if (totalMinutes >= 60) {
      final h = totalMinutes ~/ 60;
      final m = totalMinutes % 60;
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
    }
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
