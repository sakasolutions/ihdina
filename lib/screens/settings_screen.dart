import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_keys.dart';
import '../data/prayer/notification_service.dart';
import '../data/prayer/prayer_models.dart';
import '../data/prayer/prayer_times_repository.dart';
import '../data/settings/settings_repository.dart';
import '../services/revenuecat_service.dart';
import '../theme/app_theme.dart';
import '../theme/hero_theme.dart';
import '../widgets/glass_card.dart';
import 'city_search_screen.dart';
import 'paywall_screen.dart';
import 'sources_screen.dart';

const Color _accentChampagneGold = Color(0xFFE5C07B);

/// Dezente Trennung zwischen großen Blöcken (Koran · Gebet · Lernen · Quellen).
Widget _settingsSectionDivider() {
  return Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 20),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        height: 1,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(1),
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              Colors.white.withOpacity(0.14),
              Colors.transparent,
            ],
          ),
        ),
      ),
    ),
  );
}

/// Einheitliche, etwas leichtere Dropdown-Dekoration.
InputDecoration _settingsDropdownDecoration() {
  return InputDecoration(
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    filled: true,
    fillColor: Colors.white.withOpacity(0.055),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.white.withOpacity(0.18)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.white.withOpacity(0.18)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.white.withOpacity(0.28)),
    ),
  );
}

/// App settings. Arabische Lese-Typo wird im [QuranReaderScreen] angepasst.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.rootTabMode = false});

  /// Im [RootShell]-Tab: kein Zurück-Pfeil, Titel „Mehr“. Bei [Navigator.push] weiterhin „Einstellungen“ + Zurück.
  final bool rootTabMode;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  PrayerSettings? _prayerSettings;
  PrayerTimesResult? _prayerResult;
  bool _notificationsEnabled = true;
  bool _dailyAyahReminderEnabled = false;
  bool _locationLoading = false;

  @override
  void initState() {
    super.initState();
    RevenueCatService.updateCustomerStatus().then((_) {
      if (mounted) setState(() {});
    });
    _load();
    _loadPrayerTimes();
  }

  Widget _buildProSettingsCard() {
    final isPro = RevenueCatService.isPro;
    return GlassCard(
      borderRadius: 20,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            await Navigator.push<void>(
              context,
              MaterialPageRoute<void>(builder: (_) => const PaywallScreen()),
            );
            await RevenueCatService.updateCustomerStatus();
            if (mounted) setState(() {});
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                Icon(
                  isPro ? Icons.verified_outlined : Icons.workspace_premium_outlined,
                  color: _accentChampagneGold,
                  size: 26,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ihdina Pro',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isPro
                            ? 'Aktiv · Abo und Wiederherstellung'
                            : 'Voller Zugang zu Erklärungen und Follow-ups',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          height: 1.35,
                          color: Colors.white.withOpacity(0.58),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadPrayerTimes() async {
    final settings = await SettingsRepository.instance.getPrayerSettings();
    if (!mounted) return;
    final now = DateTime.now();
    final result = PrayerTimesRepository.instance.computeToday(settings, now);
    if (mounted) setState(() => _prayerResult = result);
  }

  Widget _buildOfficialDiyanetTile() {
    final officialSelected = _prayerSettings!.method == PrayerMethodOption.turkiye;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final updated = _prayerSettings!.copyWith(method: PrayerMethodOption.turkiye);
          await SettingsRepository.instance.setPrayerSettings(updated);
          if (mounted) setState(() => _prayerSettings = updated);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: officialSelected
                ? Colors.white.withOpacity(0.08)
                : Colors.white.withOpacity(0.055),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: officialSelected
                  ? _accentChampagneGold.withOpacity(0.45)
                  : Colors.white.withOpacity(0.18),
            ),
          ),
          child: Row(
            children: [
              Icon(
                officialSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: 20,
                color: officialSelected ? _accentChampagneGold : Colors.white54,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  PrayerMethodOption.turkiye.displayName,
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _determinePosition() async {
    if (_locationLoading) return;
    if (!mounted) return;
    setState(() => _locationLoading = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => _locationLoading = false);
        rootScaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text('Standortdienste sind deaktiviert.')),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _locationLoading = false);
        rootScaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text('Standortberechtigung verweigert.')),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      String locationLabel = 'Standort';
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = <String>[];
        if (p.locality != null && p.locality!.isNotEmpty) parts.add(p.locality!);
        if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty) {
          parts.add(p.administrativeArea!);
        }
        if (p.country != null && p.country!.isNotEmpty) parts.add(p.country!);
        if (parts.isNotEmpty) locationLabel = parts.join(', ');
      }

      final updated = _prayerSettings!.copyWith(
        latitude: position.latitude,
        longitude: position.longitude,
        locationLabel: locationLabel,
      );
      await SettingsRepository.instance.setPrayerSettings(updated);
      if (mounted) {
        setState(() {
          _prayerSettings = updated;
          _locationLoading = false;
        });
        await _loadPrayerTimes();
        if (mounted && _notificationsEnabled && _prayerResult != null) {
          await NotificationService.instance.schedulePrayerNotifications(_prayerResult!, updated);
        }
        rootScaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text('Standort gesetzt: $locationLabel')),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _locationLoading = false);
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Standort konnte nicht ermittelt werden: $e')),
      );
    }
  }

  Future<void> _load() async {
    final repo = SettingsRepository.instance;
    final results = await Future.wait([
      repo.getPrayerSettings(),
      repo.getNotificationsEnabled(),
      repo.getDailyAyahReminderEnabled(),
    ]);
    if (mounted) {
      setState(() {
        _prayerSettings = results[0] as PrayerSettings;
        _notificationsEnabled = results[1] as bool;
        _dailyAyahReminderEnabled = results[2] as bool;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final heroPhase = DynamicHeroTheme.phaseFromPrayer(_prayerResult?.nextPrayerType);

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ));

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: !widget.rootTabMode,
        iconTheme: const IconThemeData(color: Colors.white),
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        title: Text(
          widget.rootTabMode ? 'Mehr' : 'Einstellungen',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: SizedBox.expand(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: AppColors.mainGradient,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.1,
                child: Image.asset(
                  DynamicHeroTheme.backgroundAsset(heroPhase),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
            SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 130),
              children: [
                _buildProSettingsCard(),
                const SizedBox(height: 16),
                if (_prayerSettings != null)
                  GlassCard(
                    borderRadius: 20,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gebet',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Gebets-Erinnerungen',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                              Switch(
                                value: _notificationsEnabled,
                                onChanged: (bool value) async {
                                  if (mounted) setState(() => _notificationsEnabled = value);
                                  try {
                                    await SettingsRepository.instance.setNotificationsEnabled(value);
                                    if (!value) {
                                      try {
                                        await NotificationService.instance.cancelAllPrayerNotifications();
                                      } catch (_) { /* cancel löst auf manchen Geräten „Missing type parameter“ aus */ }
                                      debugPrint('[NOTIF] Gebets-Erinnerungen aus');
                                      rootScaffoldMessengerKey.currentState?.showSnackBar(
                                        const SnackBar(
                                          content: Text('Gebets-Erinnerungen deaktiviert'),
                                          backgroundColor: Colors.white24,
                                          behavior: SnackBarBehavior.floating,
                                          duration: const Duration(seconds: 3),
                                        ),
                                      );
                                    } else {
                                      await NotificationService.instance.showImmediateConfirmationNotification();
                                      rootScaffoldMessengerKey.currentState?.showSnackBar(
                                        const SnackBar(
                                          content: Text('Sofort-Benachrichtigung gesendet!'),
                                          backgroundColor: Colors.green,
                                          behavior: SnackBarBehavior.floating,
                                          duration: const Duration(seconds: 4),
                                        ),
                                      );
                                      final settings = await SettingsRepository.instance.getPrayerSettings();
                                      final now = DateTime.now();
                                      final result = PrayerTimesRepository.instance.computeToday(settings, now);
                                      if (mounted) {
                                        await NotificationService.instance.schedulePrayerNotifications(
                                          result,
                                          settings,
                                        );
                                        debugPrint('[NOTIF] Gebets-Erinnerungen geplant');
                                      }
                                    }
                                  } catch (e, st) {
                                    debugPrint('[NOTIF] Fehler: $e');
                                    debugPrint('$st');
                                    // Nur bei „Aus“ den Schalter zurücksetzen. Bei „An“ bleibt er an (Sofort-Benachrichtigung war schon erfolgreich).
                                    if (!value && mounted) setState(() => _notificationsEnabled = true);
                                    // Bei „An“ keine rote Meldung – grüne Snackbar + Vibration waren schon Erfolg.
                                    if (!value) {
                                      rootScaffoldMessengerKey.currentState?.showSnackBar(
                                        SnackBar(
                                          content: Text('Fehler: $e'),
                                          backgroundColor: Colors.red,
                                          behavior: SnackBarBehavior.floating,
                                          duration: const Duration(seconds: 5),
                                        ),
                                      );
                                    }
                                  }
                                },
                                activeColor: Colors.white,
                                activeTrackColor: Colors.white.withOpacity(0.4),
                                inactiveThumbColor: Colors.white54,
                                inactiveTrackColor: Colors.white.withOpacity(0.2),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Standort',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.72),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _prayerSettings!.locationLabel,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Tooltip(
                                message: 'Stadt auswählen',
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () async {
                                      final result = await Navigator.push<bool>(
                                        context,
                                        MaterialPageRoute<bool>(builder: (_) => const CitySearchScreen()),
                                      );
                                      if (result == true && mounted) {
                                        await _load();
                                        await _loadPrayerTimes();
                                        if (mounted &&
                                            _notificationsEnabled &&
                                            _prayerResult != null &&
                                            _prayerSettings != null) {
                                          await NotificationService.instance.schedulePrayerNotifications(
                                            _prayerResult!,
                                            _prayerSettings!,
                                          );
                                        }
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(24),
                                    child: Container(
                                      width: 44,
                                      height: 44,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.25),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.1),
                                          width: 1,
                                        ),
                                      ),
                                      child: Icon(Icons.location_city_outlined, size: 22, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Tooltip(
                                message: 'Standort orten',
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _locationLoading ? null : _determinePosition,
                                    borderRadius: BorderRadius.circular(24),
                                    child: Container(
                                      width: 44,
                                      height: 44,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.25),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.1),
                                          width: 1,
                                        ),
                                      ),
                                      child: _locationLoading
                                          ? SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: _accentChampagneGold,
                                              ),
                                            )
                                          : Icon(Icons.my_location, size: 22, color: _accentChampagneGold),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Gebetszeiten',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.72),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Offizielle Quellen',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.4,
                              color: Colors.white.withOpacity(0.55),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildOfficialDiyanetTile(),
                          const SizedBox(height: 16),
                          Text(
                            'Berechnete Methoden',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.4,
                              color: Colors.white.withOpacity(0.55),
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<PrayerMethodOption?>(
                            value: _prayerSettings!.method == PrayerMethodOption.turkiye
                                ? null
                                : _prayerSettings!.method,
                            hint: Text(
                              'Berechnete Methode wählen',
                              style: GoogleFonts.inter(fontSize: 14, color: Colors.white54),
                            ),
                            dropdownColor: const Color(0xFF0A2E28),
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 22),
                            decoration: _settingsDropdownDecoration(),
                            style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
                            items: PrayerMethodOption.calculatedMethods
                                .map((m) => DropdownMenuItem(
                                      value: m,
                                      child: Text(
                                        m.displayName,
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ))
                                .toList(),
                            onChanged: (v) async {
                              if (v == null) return;
                              final updated = _prayerSettings!.copyWith(method: v);
                              await SettingsRepository.instance.setPrayerSettings(updated);
                              if (mounted) setState(() => _prayerSettings = updated);
                            },
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _prayerSettings!.method.calculationHint,
                            style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.58),
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Lokale Unterschiede zu einzelnen Kalendern sind möglich.',
                            style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.52),
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Asr-Berechnung',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.72),
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<MadhabOption>(
                            value: _prayerSettings!.madhab,
                            dropdownColor: const Color(0xFF0A2E28),
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 22),
                            decoration: _settingsDropdownDecoration(),
                            style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
                            items: MadhabOption.values
                                .map((m) => DropdownMenuItem(
                                      value: m,
                                      child: Text(
                                        m.displayName,
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ))
                                .toList(),
                            onChanged: (v) async {
                              if (v == null) return;
                              final updated = _prayerSettings!.copyWith(madhab: v);
                              await SettingsRepository.instance.setPrayerSettings(updated);
                              if (mounted) setState(() => _prayerSettings = updated);
                            },
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _prayerSettings!.madhab.asrCalculationHint,
                            style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.58),
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                _settingsSectionDivider(),
                GlassCard(
                  borderRadius: 20,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lernen & Motivation',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tagesvers-Erinnerung',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Täglich um 10:00',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.58),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _dailyAyahReminderEnabled,
                              onChanged: (bool value) async {
                                await SettingsRepository.instance.setDailyAyahReminderEnabled(value);
                                if (!value) {
                                  await NotificationService.instance.cancelDailyAyahReminder();
                                } else {
                                  await NotificationService.instance.scheduleDailyAyahReminder();
                                }
                                if (mounted) setState(() => _dailyAyahReminderEnabled = value);
                              },
                              activeColor: Colors.white,
                              activeTrackColor: Colors.white.withOpacity(0.4),
                              inactiveThumbColor: Colors.white54,
                              inactiveTrackColor: Colors.white.withOpacity(0.2),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                _settingsSectionDivider(),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(builder: (_) => const SourcesScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: GlassCard(
                      borderRadius: 20,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 22,
                              color: const Color(0xFFE5C07B),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Quellen & Lizenzen',
                                    style: GoogleFonts.playfairDisplay(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Koran, Übersetzung & KI',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.58),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              size: 24,
                              color: Colors.white54,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Made with Sabr & Code',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Koran-Text: Tanzil.net | Übersetzung: Bubenheim (QuranEnc)',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: Colors.white38,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
        ),
        ),
      ),
    );
  }
}
