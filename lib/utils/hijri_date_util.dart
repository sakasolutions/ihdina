/// Einfache Hijri-Umrechnung (Tabular, wie in [PrayerScreen]) — für Kalender-Features offline.
class HijriDateUtil {
  HijriDateUtil._();

  static int _gregorianToJulian(int year, int month, int day) {
    if (month <= 2) {
      year -= 1;
      month += 12;
    }
    final a = (year / 100).floor();
    final b = 2 - a + (a / 4).floor();
    return (365.25 * (year + 4716)).floor() +
        (30.6001 * (month + 1)).floor() +
        day +
        b -
        1524;
  }

  /// Hijri-Monat 1–12 (9 = Ramadan).
  static int hijriMonth(DateTime date) {
    final julianDay = _gregorianToJulian(date.year, date.month, date.day);
    final hijriDay = julianDay - 1948440 + 10632;
    final n = ((hijriDay - 1) / 10631).floor();
    final hijriDay2 = hijriDay - 10631 * n + 354;
    final j = ((10985 - hijriDay2) / 5316).floor() *
            ((50 * hijriDay2) / 17719).floor() +
        (hijriDay2 / 5670).floor() * ((43 * hijriDay2) / 15238).floor();
    final hijriDay3 = hijriDay2 -
        ((30 - j) / 15).floor() * ((17719 * j) / 50).floor() -
        (j / 16).floor() * ((15238 * j) / 43).floor() +
        29;
    final month = (24 * hijriDay3 / 709).floor();
    return month % 13 + 1;
  }

  static bool isRamadan(DateTime date) => hijriMonth(date) == 9;
}
