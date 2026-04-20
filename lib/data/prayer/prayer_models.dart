import '../../prayer/prayer_type.dart';

/// Prayer calculation method (maps to adhan_dart calculation methods).
enum PrayerMethodOption {
  mwl('Muslim World League (MWL)', 'mwl'),
  isna('ISNA', 'isna'),
  egyptian('Ägyptisch', 'egyptian'),
  ummAlQura('Umm al-Qura', 'ummAlQura'),
  karachi('Karachi', 'karachi'),
  turkiye('Diyanet (offizielle Zeiten)', 'turkiye'),
  tehran('Tehran', 'tehran');

  const PrayerMethodOption(this.displayName, this.value);
  final String displayName;
  final String value;

  /// Nur astronomische / tabellarische Näherungen — ohne [turkiye].
  static const List<PrayerMethodOption> calculatedMethods = [
    mwl,
    isna,
    egyptian,
    ummAlQura,
    karachi,
    tehran,
  ];

  static PrayerMethodOption fromValue(String v) {
    return PrayerMethodOption.values.firstWhere(
      (e) => e.value == v,
      orElse: () => PrayerMethodOption.mwl,
    );
  }
}

/// Kurzer, methodenspezifischer UI-Hinweis (entspricht adhan_dart `CalculationMethodParameters`).
extension PrayerMethodOptionCalculationHint on PrayerMethodOption {
  String get calculationHint {
    switch (this) {
      case PrayerMethodOption.mwl:
        return 'Internationale Berechnungsmethode basierend auf astronomischen Winkeln (Fajr 18°, Isha 17°).';
      case PrayerMethodOption.isna:
        return 'In Nordamerika verbreitete Berechnungsmethode.';
      case PrayerMethodOption.egyptian:
        return 'Ägyptische Berechnungsmethode mit angepassten Winkeln für Fajr und Isha.';
      case PrayerMethodOption.ummAlQura:
        return 'In Saudi-Arabien verwendete Methode. Isha wird als fester Abstand nach Sonnenuntergang berechnet.';
      case PrayerMethodOption.karachi:
        return 'In Pakistan und Südostasien verbreitete Berechnungsmethode.';
      case PrayerMethodOption.turkiye:
        return 'Offizielle Gebetszeiten der türkischen Religionsbehörde (Diyanet). Entspricht den Zeiten vieler Moscheen.';
      case PrayerMethodOption.tehran:
        return 'In Iran verwendete Methode mit eigenen Berechnungsparametern.';
    }
  }
}

/// Madhab for Asr calculation.
enum MadhabOption {
  shafi('Standard (Shafi/Maliki/Hanbali)'),
  hanafi('Hanafi');

  const MadhabOption(this.displayName);
  final String displayName;

  static MadhabOption fromValue(String v) {
    return MadhabOption.values.firstWhere(
      (e) => e.name == v,
      orElse: () => MadhabOption.shafi,
    );
  }
}

extension MadhabOptionAsrHint on MadhabOption {
  String get asrCalculationHint {
    switch (this) {
      case MadhabOption.shafi:
        return 'Asr früher: einfache Schattenlänge (üblich bei Schafi, Maliki, Hanbali).';
      case MadhabOption.hanafi:
        return 'Asr später: doppelte Schattenlänge (Hanafi).';
    }
  }
}

/// User settings for prayer time calculation.
class PrayerSettings {
  const PrayerSettings({
    required this.latitude,
    required this.longitude,
    required this.locationLabel,
    required this.method,
    required this.madhab,
    this.adjustmentMinutesFajr,
    this.adjustmentMinutesDhuhr,
    this.adjustmentMinutesAsr,
    this.adjustmentMinutesMaghrib,
    this.adjustmentMinutesIsha,
    this.useDeviceLocation = false,
  });

  final double latitude;
  final double longitude;
  final String locationLabel;
  final PrayerMethodOption method;
  final MadhabOption madhab;
  final int? adjustmentMinutesFajr;
  final int? adjustmentMinutesDhuhr;
  final int? adjustmentMinutesAsr;
  final int? adjustmentMinutesMaghrib;
  final int? adjustmentMinutesIsha;
  final bool useDeviceLocation;

  PrayerSettings copyWith({
    double? latitude,
    double? longitude,
    String? locationLabel,
    PrayerMethodOption? method,
    MadhabOption? madhab,
    int? adjustmentMinutesFajr,
    int? adjustmentMinutesDhuhr,
    int? adjustmentMinutesAsr,
    int? adjustmentMinutesMaghrib,
    int? adjustmentMinutesIsha,
    bool? useDeviceLocation,
  }) {
    return PrayerSettings(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationLabel: locationLabel ?? this.locationLabel,
      method: method ?? this.method,
      madhab: madhab ?? this.madhab,
      adjustmentMinutesFajr: adjustmentMinutesFajr ?? this.adjustmentMinutesFajr,
      adjustmentMinutesDhuhr: adjustmentMinutesDhuhr ?? this.adjustmentMinutesDhuhr,
      adjustmentMinutesAsr: adjustmentMinutesAsr ?? this.adjustmentMinutesAsr,
      adjustmentMinutesMaghrib: adjustmentMinutesMaghrib ?? this.adjustmentMinutesMaghrib,
      adjustmentMinutesIsha: adjustmentMinutesIsha ?? this.adjustmentMinutesIsha,
      useDeviceLocation: useDeviceLocation ?? this.useDeviceLocation,
    );
  }
}

/// Result of prayer times computation for a day.
class PrayerTimesResult {
  const PrayerTimesResult({
    required this.times,
    required this.now,
    required this.nextPrayerType,
    required this.nextPrayerTime,
    required this.timeUntilNextPrayer,
  });

  /// All times for the day (imsak, fajr, sunrise, dhuhr, asr, maghrib, isha).
  final Map<PrayerType, DateTime> times;
  final DateTime now;
  final PrayerType nextPrayerType;
  final DateTime nextPrayerTime;
  final Duration timeUntilNextPrayer;

  DateTime? timeFor(PrayerType type) => times[type];
}
