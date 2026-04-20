import 'package:flutter/material.dart';

/// Central source of truth for prayer time slots: labels and icons.
enum PrayerType {
  imsak,
  fajr,
  sunrise,
  dhuhr,
  asr,
  maghrib,
  isha,
}

/// Display order: Fajr, Sonnenaufgang, Dhuhr, Asr, Maghrib, Isha (ohne Imsak).
const List<PrayerType> prayerTypeOrderForDisplay = [
  PrayerType.fajr,
  PrayerType.sunrise,
  PrayerType.dhuhr,
  PrayerType.asr,
  PrayerType.maghrib,
  PrayerType.isha,
];

@Deprecated('Use prayerTypeOrderForDisplay')
const List<PrayerType> prayerTypeOrder = prayerTypeOrderForDisplay;

extension PrayerTypeX on PrayerType {
  String get label {
    switch (this) {
      case PrayerType.imsak:
        return 'Imsak';
      case PrayerType.fajr:
        return 'Fajr';
      case PrayerType.sunrise:
        return 'Sonnenaufgang';
      case PrayerType.dhuhr:
        return 'Dhuhr';
      case PrayerType.asr:
        return 'Asr';
      case PrayerType.maghrib:
        return 'Maghrib';
      case PrayerType.isha:
        return 'Isha';
    }
  }

  IconData get icon {
    switch (this) {
      case PrayerType.imsak:
        return Icons.bedtime_outlined;
      case PrayerType.fajr:
        return Icons.wb_twilight_outlined;
      case PrayerType.sunrise:
        return Icons.wb_sunny_outlined;
      case PrayerType.dhuhr:
        return Icons.light_mode_outlined;
      case PrayerType.asr:
        return Icons.schedule_outlined;
      case PrayerType.maghrib:
        return Icons.nights_stay_outlined;
      case PrayerType.isha:
        return Icons.dark_mode_outlined;
    }
  }
}
