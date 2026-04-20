import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';

import '../../prayer/prayer_type.dart';
import '../settings/settings_repository.dart';
import 'prayer_models.dart';
import 'prayer_times_repository.dart';

/// Base notification ID for prayer reminders. One ID pro Gebetszeit (Fajr=1, Sonnenaufgang=2, …).
const int _prayerNotificationIdBase = 1000;

/// IDs 990–998 used in rotation for immediate test notifications (no cancel before show).
const int _testNotificationIdNowBase = 990;
const int _testNotificationIdNowCount = 9;

/// Fixed ID for the daily Tagesvers (Ayah) reminder. Does not clash with prayer IDs (1000+).
const int _dailyAyahReminderId = 8888;

/// ID for the "test in 1 minute" scheduled notification (zum Vergleich mit Sofort-Test).
const int _testInOneMinuteId = 7777;

/// **Test-Hilfen (Kategorien):**
/// - **Sofort (`show`)** – nur Anzeige im Moment, **kein** System-Alarm:
///   [showTestNotificationNow], [showImmediateConfirmationNotification], [showTestNotification].
/// - **Geplant (`zonedSchedule`)** – gleiche Mechanik-Kategorie wie Gebets-Erinnerungen:
///   [scheduleTestNotificationInOneMinute] (`AndroidScheduleMode.exactAllowWhileIdle` wie [schedulePrayerNotifications]).
/// - **Timer + `show`** – nur Diagnose, **kein** Ersatz für Hintergrund-Test: [showTestNotificationInOneMinuteViaTimer].

/// Local prayer time notifications. Offline-first; plant alle **zukünftigen** Slots aus
/// heute **und** morgen (ein Slot pro Gebetsart, feste IDs), damit das Fenster nach Tagesende vollständig bleibt.
///
/// ## Reboot, Update, lange Pause (ohne WorkManager)
///
/// **Android – `flutter_local_notifications` `ScheduledNotificationBootReceiver`:**
/// Im Manifest sind u. a. `BOOT_COMPLETED`, `MY_PACKAGE_REPLACED` (nach App-Update) und
/// Quick-Boot-Intents registriert. Das Plugin **stellt persistierte Alarme wieder her** —
/// es werden **keine** Gebetszeiten neu aus SQLite/adhan berechnet. Vorteil: Benachrichtigungen
/// können ohne App-Öffnung wieder anstehen. Nachteil: Zeiten können **veraltet** sein
/// (Mitternacht, Standortwechsel, Sommerzeit), bis Dart-Code wieder plant.
///
/// **Frische Berechnung** (Standort + heute/morgen) läuft nur im Flutter-Prozess:
/// - [reschedulePrayerNotificationsOnAppStartup] vom [BootstrapScreen] nach DB-Start
/// - [maybeReschedulePrayerNotificationsOnAppResume] bei [AppLifecycleState.resumed]
///   (Mindestabstand [resumeRescheduleMinGap], um Doppelplanung direkt nach Cold Start zu vermeiden)
/// - bestehende Aufrufe von Home/Einstellungen (unverändert)
///
/// **iOS:** Kein gleichwertiger Boot-Receiver; Zuverlässigkeit hängt vom System und vom
/// zuletzt gesetzten Schedule ab. App-Start bzw. Resume aktualisiert wie oben.
///
/// **OS/Hersteller:** Doze, Akku-Optimierung, fehlende „exakte Alarme“-Berechtigung oder
/// OEM-Einschränkungen können Alarme **verschieben** — das ist ohne Hintergrund-Worker nicht
/// vollständig behebbar.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  int _immediateTestCounter = 0;

  /// Letzter Lauf von [reschedulePrayerNotificationsOnAppStartup] (für Resume-Drosselung).
  DateTime? _lastPrayerRescheduleRunAt;

  /// Mindestabstand, bevor [maybeReschedulePrayerNotificationsOnAppResume] erneut plant
  /// (vermeidet Doppelplanung direkt nach Cold Start: Bootstrap + sofortiges `resumed`).
  static const Duration resumeRescheduleMinGap = Duration(minutes: 30);

  /// Call once at app startup (e.g. from main() or first screen).
  /// Timezones must be initialized before any zonedSchedule call.
  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    try {
      final zoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zoneName));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Europe/Berlin'));
    }

    const AndroidInitializationSettings android =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: false,
    );
    const initSettings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (_) {},
    );

    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              'prayer_channel_id',
              'Gebetszeiten',
              description: 'Erinnerungen für die täglichen Gebete',
              importance: Importance.max,
            ),
          );
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        await androidImpl.requestExactAlarmsPermission();
      }
    }

    _initialized = true;
  }

  /// Nach geöffneter SQLite-DB (z. B. [BootstrapScreen]): Gebetszeiten neu berechnen und
  /// Erinnerungen setzen, **nur** wenn Gebets-Benachrichtigungen in den Einstellungen an sind.
  /// Die **Tagesvers-Erinnerung** wird unabhängig davon neu geplant, wenn sie in den Einstellungen
  /// aktiviert ist (kann z. B. laufen, wenn Gebets-Benachrichtigungen aus sind).
  ///
  /// Fehler werden geloggt und fressen keinen Start; doppelte Aufrufe mit Screen-Logik sind unkritisch.
  Future<void> reschedulePrayerNotificationsOnAppStartup() async {
    debugPrint('[NOTIF][startup] reschedulePrayerNotificationsOnAppStartup: Start');
    try {
      final settingsRepo = SettingsRepository.instance;
      final notificationsOn = await settingsRepo.getNotificationsEnabled();
      if (notificationsOn) {
        final settings = await settingsRepo.getPrayerSettings();
        final lat = settings.latitude;
        final lng = settings.longitude;
        if (lat.isNaN || lng.isNaN || !lat.isFinite || !lng.isFinite) {
          debugPrint(
            '[NOTIF][startup] Gebets-Slots übersprungen: ungültige Koordinaten (lat=$lat, lng=$lng)',
          );
        } else {
          if (settings.locationLabel == 'Default') {
            debugPrint(
              '[NOTIF][startup] Hinweis: Standort-Label noch „Default“ — Berechnung mit gespeicherten/Fallback-Koordinaten',
            );
          }

          final now = DateTime.now();
          final result = PrayerTimesRepository.instance.computeToday(settings, now);
          final scheduled = await schedulePrayerNotifications(result, settings);
          debugPrint(
            '[NOTIF][startup] abgeschlossen: $scheduled Gebets-Slot(s) geplant '
            '(location=${settings.locationLabel})',
          );
        }
      } else {
        debugPrint(
          '[NOTIF][startup] Gebets-Erinnerungen in den Einstellungen deaktiviert — keine Gebets-Slots',
        );
      }

      final dailyAyahOn = await settingsRepo.getDailyAyahReminderEnabled();
      if (dailyAyahOn) {
        await scheduleDailyAyahReminder();
        debugPrint(
          '[NOTIF][startup] Tagesvers-Erinnerung neu geplant (gleiche Berechtigungs-/Schedule-Logik)',
        );
      }
    } catch (e, st) {
      debugPrint('[NOTIF][startup] Fehler beim Neuplanen (App läuft weiter): $e');
      debugPrint('[NOTIF][startup] $st');
    } finally {
      _lastPrayerRescheduleRunAt = DateTime.now();
    }
  }

  /// Bei Rückkehr in den Vordergrund (`AppLifecycleState.resumed`): wie Startup neu planen,
  /// aber nur wenn der letzte Lauf mindestens [resumeRescheduleMinGap] her ist — sonst Log + Return.
  ///
  /// Hilft nach **langer Hintergrundpause** (Prozess noch warm), ohne nach jedem Tab-Wechsel
  /// neu zu planen. **Kein Ersatz** für Android-Boot-Restore (s. Dateikopf-Kommentar).
  Future<void> maybeReschedulePrayerNotificationsOnAppResume() async {
    final last = _lastPrayerRescheduleRunAt;
    final now = DateTime.now();
    if (last != null && now.difference(last) < resumeRescheduleMinGap) {
      debugPrint(
        '[NOTIF][lifecycle] AppLifecycle.resumed: Neuplanung übersprungen '
        '(${now.difference(last).inMinutes} min seit letztem Startup/Resume-Lauf; '
        'Mindestabstand ${resumeRescheduleMinGap.inMinutes} min)',
      );
      return;
    }
    debugPrint(
      '[NOTIF][lifecycle] AppLifecycle.resumed → Gebets-Neuplanung (warm resume / nach Pause)',
    );
    await reschedulePrayerNotificationsOnAppStartup();
  }

  /// Request notification permissions (iOS, Android 13+) and exact alarm (Android 14).
  /// [logPrayerDebug]: zusätzliche [debugPrint]-Ausgaben der Plugin-Rückgaben (Gebets-Scheduling-Flow).
  Future<bool> requestPermissions({bool logPrayerDebug = false}) async {
    if (Platform.isIOS) {
      final impl = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final result = await impl?.requestPermissions(alert: true, badge: false);
      if (logPrayerDebug) {
        debugPrint('[NOTIF][perm] iOS requestPermissions(alert:true) → $result (null = kein Plugin)');
      }
      return result == true;
    }
    if (Platform.isAndroid) {
      final impl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final notifResult = await impl?.requestNotificationsPermission();
      if (logPrayerDebug) {
        debugPrint(
          '[NOTIF][perm] Android requestNotificationsPermission → $notifResult '
          '(true=gewährt, false=verweigert, null=unbekannt/nicht unterstützt)',
        );
      }
      if (impl != null) {
        if (logPrayerDebug) {
          final exactResult = await impl.requestExactAlarmsPermission();
          debugPrint(
            '[NOTIF][perm] Android requestExactAlarmsPermission → $exactResult '
            '(Plugin-Rückgabe; kann null sein)',
          );
        } else {
          await impl.requestExactAlarmsPermission();
        }
      } else if (logPrayerDebug) {
        debugPrint('[NOTIF][perm] Android implementation null – keine Request-Calls');
      }
      if (logPrayerDebug && impl != null) {
        try {
          final enabled = await impl.areNotificationsEnabled();
          final canExact = await impl.canScheduleExactNotifications();
          debugPrint(
            '[NOTIF][perm] Android areNotificationsEnabled → $enabled '
            '(Zustand nach Request, kein zweiter Dialog)',
          );
          debugPrint(
            '[NOTIF][perm] Android canScheduleExactNotifications → $canExact '
            '(false oft: „Alarms & reminders“ / Akku – exakte Alarme eingeschränkt)',
          );
        } catch (e, st) {
          debugPrint('[NOTIF][perm] Android Zusatz-Abfrage fehlgeschlagen: $e');
          debugPrint('[NOTIF][perm] $st');
        }
      }
      // false = explizit verweigert; true/null = gewährt oder ältere APIs / unbekannt (nicht blockieren).
      return notifResult != false;
    }
    if (logPrayerDebug) {
      debugPrint('[NOTIF][perm] Plattform weder iOS noch Android – übersprungen');
    }
    return true;
  }

  /// Nach [requestPermissions]: prüft, ob das System Anzeige von Benachrichtigungen zulässt.
  /// Wird im Gebets-Scheduling verwendet; bei false → kein [zonedSchedule] (vermeidet „stilles“ Planen).
  Future<bool> _notificationsPermittedForPrayerScheduling() async {
    if (Platform.isAndroid) {
      final impl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (impl == null) {
        debugPrint(
          '[NOTIF][perm] _notificationsPermittedForPrayerScheduling: Android-Implementation null → false',
        );
        return false;
      }
      try {
        final enabled = await impl.areNotificationsEnabled();
        if (enabled == false) {
          debugPrint(
            '[NOTIF][perm] Android areNotificationsEnabled() == false → Gebets-Scheduling nicht sinnvoll',
          );
          return false;
        }
        if (enabled == null) {
          debugPrint(
            '[NOTIF][perm] Android areNotificationsEnabled() == null → true angenommen (API unklar)',
          );
          return true;
        }
        return true;
      } catch (e, st) {
        debugPrint(
          '[NOTIF][perm] Android areNotificationsEnabled Fehler – Scheduling abgebrochen: $e',
        );
        debugPrint('[NOTIF][perm] $st');
        return false;
      }
    }
    if (Platform.isIOS) {
      final impl = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (impl == null) {
        debugPrint(
          '[NOTIF][perm] _notificationsPermittedForPrayerScheduling: iOS-Implementation null → false',
        );
        return false;
      }
      try {
        final opts = await impl.checkPermissions();
        if (opts == null) {
          debugPrint(
            '[NOTIF][perm] iOS checkPermissions() == null → true angenommen (unklar)',
          );
          return true;
        }
        final appAllows = opts.isEnabled || opts.isProvisionalEnabled;
        if (!appAllows) {
          debugPrint(
            '[NOTIF][perm] iOS: weder isEnabled noch isProvisionalEnabled → kein Gebets-Scheduling '
            '(isEnabled=${opts.isEnabled}, isProvisionalEnabled=${opts.isProvisionalEnabled})',
          );
          return false;
        }
        if (!opts.isAlertEnabled && !opts.isProvisionalEnabled) {
          debugPrint(
            '[NOTIF][perm] iOS: Alerts aus (isAlertEnabled=false, kein Provisional) → kein sichtbares Scheduling',
          );
          return false;
        }
        return true;
      } catch (e, st) {
        debugPrint(
          '[NOTIF][perm] iOS checkPermissions Fehler – Scheduling abgebrochen: $e',
        );
        debugPrint('[NOTIF][perm] $st');
        return false;
      }
    }
    return true;
  }

  /// Plant bis zu eine Benachrichtigung pro Gebetsart ([prayerTypeOrderForDisplay]), mit
  /// fester ID (`_prayerNotificationIdBase` + Index).
  ///
  /// [result.times] = heute (lokal, wie [PrayerTimesRepository.computeToday]). Für jeden Typ
  /// wird die **nächste** Wandzeit gewählt: zuerst heute, falls nicht mehr in der Zukunft
  /// (bzw. bei Sunrise: „Sunrise−10 min“ nicht mehr in der Zukunft) → **morgen** via
  /// [PrayerTimesRepository.computePrayerTimesMapForDate].
  ///
  /// **Hinweis (Android):** [ScheduledNotificationBootReceiver] stellt nach Reboot/Update
  /// **persistierte** Alarme wieder her — ohne diese Neuberechnung. [schedulePrayerNotifications]
  /// ersetzt Alarme durch frisch berechnete Zeiten und schreibt wieder persistiert.
  Future<int> schedulePrayerNotifications(
    PrayerTimesResult result,
    PrayerSettings settings,
  ) async {
    if (!_initialized) await initialize();

    debugPrint('[NOTIF][prayer] ========== schedulePrayerNotifications START ==========');
    debugPrint('[NOTIF][prayer] tz.local=${tz.local.name}');
    final aggregateGranted = await requestPermissions(logPrayerDebug: true);
    debugPrint(
      '[NOTIF][prayer] requestPermissions() aggregiert (false = explizit verweigert / iOS ohne Alert): '
      'mayProceed=$aggregateGranted',
    );

    try {
      await cancelAllPrayerNotifications();
      debugPrint('[NOTIF][prayer] cancelAllPrayerNotifications: OK');
    } catch (e, st) {
      debugPrint(
        '[NOTIF][prayer] cancelAllPrayerNotifications: FEHLER (Planung geht trotzdem weiter): $e',
      );
      debugPrint('[NOTIF][prayer] $st');
    }

    if (!aggregateGranted) {
      debugPrint(
        '[NOTIF][prayer] ABORT: Kein Gebets-Scheduling – requestPermissions() meldet keine Zustimmung '
        '(Android: POST_NOTIFICATIONS verweigert; iOS: alert-Berechtigung nicht erteilt).',
      );
      return 0;
    }

    final displayPermitted = await _notificationsPermittedForPrayerScheduling();
    if (!displayPermitted) {
      debugPrint(
        '[NOTIF][prayer] ABORT: Kein Gebets-Scheduling – System meldet, dass Benachrichtigungen '
        'nicht angezeigt werden dürfen (s. [NOTIF][perm] Logs oben).',
      );
      return 0;
    }

    // Exakte Alarme: nur hinweisen, kein harter Abbruch (Inexact kann je nach OS greifen).
    if (Platform.isAndroid) {
      final impl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      try {
        final canExact = await impl?.canScheduleExactNotifications();
        if (canExact == false) {
          debugPrint(
            '[NOTIF][prayer] HINWEIS: canScheduleExactNotifications == false – geplante Zeiten können '
            'verspätet erscheinen (Akku / „Alarms & reminders“). Scheduling wird trotzdem versucht.',
          );
        }
      } catch (e) {
        debugPrint('[NOTIF][prayer] canScheduleExactNotifications Abfrage übersprungen: $e');
      }
    }

    debugPrint('[NOTIF][prayer] Berechtigungen OK – Planung wird fortgesetzt.');

    final now = result.now;
    final nowTz = tz.TZDateTime.from(now, tz.local);
    debugPrint('[NOTIF][prayer] result.now (local DateTime)=$now');
    debugPrint('[NOTIF][prayer] now as TZDateTime=$nowTz');

    final todayMap = result.times;
    final todayCalendar = DateTime(now.year, now.month, now.day);
    final tomorrowCalendar = todayCalendar.add(const Duration(days: 1));
    final tomorrowMap = PrayerTimesRepository.instance.computePrayerTimesMapForDate(
      settings,
      tomorrowCalendar,
    );
    debugPrint(
      '[NOTIF][prayer] Fenster: heute=$todayCalendar morgen=$tomorrowCalendar (lokaler Kalender); '
      'morgige Zeiten aus computePrayerTimesMapForDate',
    );

    const details = NotificationDetails(
      android: _androidDetails,
      iOS: DarwinNotificationDetails(),
    );
    int count = 0;

    for (var i = 0; i < prayerTypeOrderForDisplay.length; i++) {
      final type = prayerTypeOrderForDisplay[i];
      final id = _prayerNotificationIdBase + i;
      final tToday = todayMap[type];
      final tTomorrow = tomorrowMap[type];

      if (tToday == null || tTomorrow == null) {
        debugPrint(
          '[NOTIF][prayer] ${type.label} id=$id SKIPPED reason=fehlende Zeit in heute/morgen-Map',
        );
        continue;
      }

      tz.TZDateTime? scheduledTz;
      String? daySource;
      DateTime? wallSunriseForLog;

      if (type == PrayerType.sunrise) {
        tz.TZDateTime sunriseMinus10(DateTime sunriseLocal) {
          final origTz = tz.TZDateTime.from(sunriseLocal, tz.local);
          return origTz.subtract(const Duration(minutes: 10));
        }

        final shiftToday = sunriseMinus10(tToday);
        if (shiftToday.isAfter(nowTz)) {
          scheduledTz = shiftToday;
          daySource = 'heute';
          wallSunriseForLog = tToday;
        } else {
          final shiftTomorrow = sunriseMinus10(tTomorrow);
          if (shiftTomorrow.isAfter(nowTz)) {
            scheduledTz = shiftTomorrow;
            daySource = 'morgen';
            wallSunriseForLog = tTomorrow;
          } else {
            debugPrint(
              '[NOTIF][prayer] ${type.label} id=$id SKIPPED reason=Sunrise−10 min weder heute noch morgen '
              'strikt nach now (heute shift=$shiftToday, morgen shift=$shiftTomorrow, nowTz=$nowTz)',
            );
            continue;
          }
        }
        debugPrint(
          '[NOTIF][prayer][sunrise] ${type.label} id=$id Quelle=$daySource '
          'sunriseWallLocal=$wallSunriseForLog → triggerTz=$scheduledTz (minus 10 min)',
        );
      } else {
        if (!tToday.isBefore(now)) {
          scheduledTz = tz.TZDateTime.from(tToday, tz.local);
          daySource = 'heute';
        } else if (!tTomorrow.isBefore(now)) {
          scheduledTz = tz.TZDateTime.from(tTomorrow, tz.local);
          daySource = 'morgen';
        } else {
          debugPrint(
            '[NOTIF][prayer] ${type.label} id=$id SKIPPED reason=heute und morgen nicht ≥ now '
            '(heute=$tToday, morgen=$tTomorrow, now=$now)',
          );
          continue;
        }

        final chosen = scheduledTz;
        if (!chosen.isAfter(nowTz)) {
          debugPrint(
            '[NOTIF][prayer] ${type.label} id=$id SKIPPED reason=nach Auswahl nicht strikt nach nowTz '
            '(Quelle=$daySource, scheduledTz=$chosen, nowTz=$nowTz)',
          );
          continue;
        }
        scheduledTz = chosen;
        debugPrint(
          '[NOTIF][prayer] ${type.label} id=$id Quelle=$daySource wallLocal='
          '${daySource == 'heute' ? tToday : tTomorrow} → tz=$chosen',
        );
      }

      final scheduledTime = scheduledTz;
      String title = 'Zeit für ${type.label}';
      String body = 'Das ${type.label}-Gebet hat begonnen.';

      if (type == PrayerType.sunrise) {
        title = 'Fajr endet bald! ⏳';
        body = 'Die Sonne geht in 10 Minuten auf. Letzte Chance für das Morgengebet.';
      }

      try {
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          scheduledTime,
          details,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
        count++;
        debugPrint(
          '[NOTIF][prayer] ${type.label} id=$id SCHEDULED Quelle=$daySource finalTz=$scheduledTime',
        );
      } catch (e, st) {
        debugPrint(
          '[NOTIF][prayer] ${type.label} id=$id SCHEDULE_ERROR zonedSchedule fehlgeschlagen: $e',
        );
        debugPrint('[NOTIF][prayer] $st');
        rethrow;
      }
    }

    if (count == 0) {
      debugPrint(
        '[NOTIF][prayer] scheduledCount=0: Kein Slot aus heute/morgen konnte geplant werden '
        '(s. SKIPPED-Logs oben; ggf. Uhrzeit/Sync prüfen).',
      );
    }

    debugPrint(
      '[NOTIF][prayer] ========== schedulePrayerNotifications ENDE: '
      'scheduledCount=$count (max ${prayerTypeOrderForDisplay.length} Slots, heute+morgen) ==========',
    );
    return count;
  }

  /// Cancels all scheduled prayer notifications.
  Future<void> cancelAllPrayerNotifications() async {
    for (var i = 0; i < prayerTypeOrderForDisplay.length; i++) {
      await _plugin.cancel(_prayerNotificationIdBase + i);
    }
  }

  /// Schedules a daily recurring notification for the Tagesvers reminder at [hour]:[minute].
  /// Gleiche Berechtigungs- und Android-Schedule-Mechanik wie [schedulePrayerNotifications]
  /// (`requestPermissions`, [_notificationsPermittedForPrayerScheduling],
  /// [AndroidScheduleMode.exactAllowWhileIdle]).
  /// Uses [DateTimeComponents.time] so it repeats every day at that time.
  Future<void> scheduleDailyAyahReminder({int hour = 10, int minute = 0}) async {
    if (!_initialized) await initialize();

    debugPrint('[NOTIF][dailyAyah] ========== scheduleDailyAyahReminder START ==========');
    final aggregateGranted = await requestPermissions(logPrayerDebug: true);
    if (!aggregateGranted) {
      debugPrint(
        '[NOTIF][dailyAyah] ABORT: Kein Scheduling – requestPermissions() meldet keine Zustimmung.',
      );
      return;
    }

    final displayPermitted = await _notificationsPermittedForPrayerScheduling();
    if (!displayPermitted) {
      debugPrint(
        '[NOTIF][dailyAyah] ABORT: System meldet, dass Benachrichtigungen nicht angezeigt werden dürfen.',
      );
      return;
    }

    if (Platform.isAndroid) {
      final impl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      try {
        final canExact = await impl?.canScheduleExactNotifications();
        if (canExact == false) {
          debugPrint(
            '[NOTIF][dailyAyah] HINWEIS: canScheduleExactNotifications == false – wie bei Gebetszeiten.',
          );
        }
      } catch (e) {
        debugPrint('[NOTIF][dailyAyah] canScheduleExactNotifications: $e');
      }
    }

    await cancelDailyAyahReminder();

    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now) || scheduled.isAtSameMomentAs(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const details = NotificationDetails(
      android: _androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      _dailyAyahReminderId,
      'Dein Tagesvers wartet 📖',
      'Hast du heute schon deine Ayah gelesen und verstanden? Nimm dir eine Minute Zeit.',
      scheduled,
      details,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    debugPrint(
      '[NOTIF][dailyAyah] SCHEDULED firstTz=$scheduled (täglich $hour:${minute.toString().padLeft(2, '0')}, exactAllowWhileIdle)',
    );
    debugPrint('[NOTIF][dailyAyah] ========== scheduleDailyAyahReminder ENDE ==========');
  }

  /// Cancels the daily Tagesvers reminder (ID 8888).
  Future<void> cancelDailyAyahReminder() async {
    await _plugin.cancel(_dailyAyahReminderId);
  }

  /// Geplanter Test in 1 Minute – `zonedSchedule` mit [AndroidScheduleMode.exactAllowWhileIdle],
  /// wie [schedulePrayerNotifications]. Zum Prüfen von Hintergrund / exakten Alarmen (App darf vorher zu sein).
  Future<void> scheduleTestNotificationInOneMinute() async {
    if (!_initialized) await initialize();
    await requestPermissions();
    await _plugin.cancel(_testInOneMinuteId);

    final when = tz.TZDateTime.now(tz.local).add(const Duration(minutes: 1));
    const details = NotificationDetails(
      android: _androidDetails,
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.zonedSchedule(
      _testInOneMinuteId,
      'Test: geplante Erinnerung',
      'Gleiche Planungsart wie Gebetszeiten. Du kannst die App vorher schließen.',
      when,
      details,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
    debugPrint('[NOTIF] zonedSchedule-Test geplant für $when');
  }

  /// Nur Diagnose: nach 1 Minute **`show()`** aus dem Flutter-Prozess – **kein** AlarmManager.
  /// Ersetzt **nicht** [scheduleTestNotificationInOneMinute] für echte Hintergrund-Tests.
  Future<void> showTestNotificationInOneMinuteViaTimer() async {
    if (!_initialized) await initialize();
    await requestPermissions();
    debugPrint('[NOTIF] Timer gestartet – in 1 Min erscheint Benachrichtigung (App offen lassen).');
    Future.delayed(const Duration(minutes: 1), () async {
      await _plugin.cancel(_testInOneMinuteId);
      await _plugin.show(
        _testInOneMinuteId,
        'Test in 1 Minute ✓ (Timer)',
        'App war noch aktiv – wenn du das siehst, funktioniert show() nach Verzögerung.',
        _testDetails,
      );
      debugPrint('[NOTIF] Timer abgelaufen – show() ausgeführt.');
    });
  }

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
    'prayer_channel_id',
    'Gebetszeiten',
    channelDescription: 'Erinnerungen für die täglichen Gebete',
    importance: Importance.max,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
  );

  static const _testDetails = NotificationDetails(
    android: _androidDetails,
    iOS: DarwinNotificationDetails(),
  );

  /// Eine sofortige Benachrichtigung (show) – für Test-Button und Toggle „Gebets-Erinnerungen an“.
  /// ID 999; gleicher Kanal wie Gebete. Kein Scheduling.
  /// Kein cancel(999) vorher – löst auf manchen Android-Geräten „Missing type parameter“ im Plugin aus.
  Future<void> showImmediateConfirmationNotification() async {
    if (!_initialized) await initialize();
    await requestPermissions();
    await _plugin.show(
      999,
      'Gebets-Erinnerungen aktiv',
      'Benachrichtigung funktioniert.',
      _testDetails,
    );
  }

  /// Sofort-Test: **`show()`** – prüft Kanal, Berechtigung, Icon. **Kein** geplanter System-Alarm (nicht vergleichbar mit Gebets-Erinnerungen).
  /// Rotierende IDs 990–998 (kein cancel vor show).
  Future<void> showTestNotificationNow() async {
    if (!_initialized) await initialize();
    await requestPermissions();

    final id = _testNotificationIdNowBase + (_immediateTestCounter++ % _testNotificationIdNowCount);
    await _plugin.show(
      id,
      'Sofort-Test',
      'Direkt aus der App – kein Hintergrund-Alarm. Nur für Anzeige & Berechtigung.',
      _testDetails,
    );
  }

  /// Debug: sofortige Benachrichtigung per **`show()`** (z. B. Emulator) – gleiche Kategorie wie [showTestNotificationNow].
  Future<void> showTestNotification(BuildContext context) async {
    // ignore: avoid_print
    print('[NOTIF_TEST] showTestNotification called');
    if (!_initialized) {
      // ignore: avoid_print
      print('[NOTIF_TEST] initializing...');
      await initialize();
      // ignore: avoid_print
      print('[NOTIF_TEST] initialized');
    }
    // ignore: avoid_print
    print('[NOTIF_TEST] requesting permissions...');
    final granted = await requestPermissions();
    // ignore: avoid_print
    print('[NOTIF_TEST] requestPermissions result: $granted');

    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'prayer_channel_id',
        'Gebetszeiten',
        channelDescription: 'Erinnerungen für die täglichen Gebete',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

      // ignore: avoid_print
      print('[NOTIF_TEST] calling _plugin.show(999)...');
      await _plugin.show(
        999,
        'Sofort-Test',
        'Direkt aus der App (kein geplanter Alarm).',
        platformDetails,
      );
      // ignore: avoid_print
      print('[NOTIF_TEST] show() returned OK');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sofort-Benachrichtigung gesendet!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, st) {
      // ignore: avoid_print
      print('🚨 NOTIFICATION ERROR: $e');
      // ignore: avoid_print
      print('🚨 STACK: $st');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
