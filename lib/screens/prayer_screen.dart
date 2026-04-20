import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/prayer/prayer_models.dart';
import '../data/prayer/prayer_times_repository.dart';
import '../data/settings/settings_repository.dart';
import '../prayer/prayer_type.dart';
import '../theme/app_theme.dart';
import '../theme/hero_theme.dart';
import '../widgets/glass_card.dart';
import 'qibla_screen.dart';
import 'tasbih_screen.dart';
import 'settings_screen.dart';

const double _outerPadding = 24;
const double _sectionGap = 20;

/// Champagne-gold accent for the active/next prayer icon (matches home dashboard pill).
const Color _accentChampagneGold = Color(0xFFE5C07B);
const Duration _karahatSunriseDuration = Duration(minutes: 20);
const Duration _karahatZenithBefore = Duration(minutes: 5);
const Duration _karahatZenithAfter = Duration(minutes: 5);
const Duration _karahatSunsetDuration = Duration(minutes: 20);

enum _PrayerRowStatus { past, current, upcoming }

/// Daily prayer overview: location, date, next prayer + countdown, full list, settings row.
class PrayerScreen extends StatefulWidget {
  const PrayerScreen({super.key});

  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen> {
  PrayerTimesResult? _result;
  PrayerSettings? _settings;
  Timer? _refreshTimer;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) => _load());
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_result != null && mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final settings = await SettingsRepository.instance.getPrayerSettings();
    if (!mounted) return;
    final now = DateTime.now();
    final result = PrayerTimesRepository.instance.computeToday(settings, now);
    if (mounted) {
      setState(() {
        _settings = settings;
        _result = result;
      });
    }
  }

  String getHijriDate() {
    try {
      final now = DateTime.now();
      // Hijri epoch: July 16, 622 CE (Julian)
      final julianDay = _gregorianToJulian(now.year, now.month, now.day);
      final hijriDay = julianDay - 1948440 + 10632;
      final n = ((hijriDay - 1) / 10631).floor();
      final hijriDay2 = hijriDay - 10631 * n + 354;
      final j = ((10985 - hijriDay2) / 5316).floor() * ((50 * hijriDay2) / 17719).floor() +
          (hijriDay2 / 5670).floor() * ((43 * hijriDay2) / 15238).floor();
      final hijriDay3 = hijriDay2 - ((30 - j) / 15).floor() * ((17719 * j) / 50).floor() -
          (j / 16).floor() * ((15238 * j) / 43).floor() + 29;
      final month = (24 * hijriDay3 / 709).floor();
      final day = hijriDay3 - (709 * month / 24).floor();
      final year = 30 * n + j - 1 + (month / 13).floor();
      final monthNum = month % 13 + 1;

      const monthNames = [
        'Muharram', 'Safar', "Rabi' al-Awwal", "Rabi' ath-Thani",
        'Dschumada l-Ula', 'Dschumada th-Thaniya', 'Radschab', "Scha'ban",
        'Ramadan', 'Schawwal', "Dhu l-Qa'da", "Dhu l-Hiddscha",
      ];
      return '$day. ${monthNames[monthNum - 1]} $year H';
    } catch (_) {
      return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    final heroPhase = DynamicHeroTheme.phaseFromPrayer(_result?.nextPrayerType);

    return Scaffold(
      backgroundColor: Colors.transparent,
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
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(_outerPadding, 16, _outerPadding, 0),
                    child: _buildTopSection(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(_outerPadding, _sectionGap, _outerPadding, 0),
                    child: _buildNextPrayerSection(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(_outerPadding, _sectionGap, _outerPadding, 0),
                    child: _buildDailyListHeader(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(_outerPadding, 8, _outerPadding, 0),
                    child: _buildDailyList(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(_outerPadding, 14, _outerPadding, 0),
                    child: _buildKarahatSection(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(_outerPadding, _sectionGap, _outerPadding, 0),
                    child: _buildQiblaButton(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(_outerPadding, 12, _outerPadding, 0),
                    child: _buildTasbihButton(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(_outerPadding, _sectionGap + 8, _outerPadding, 0),
                    child: _buildBottomSection(),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 130)),
              ],
            ),
          ),
        ],
        ),
        ),
      ),
    );
  }

  static const List<Shadow> _textShadow = [
    Shadow(color: Colors.black45, blurRadius: 4),
  ];

  Widget _buildTopSection() {
    final now = DateTime.now();
    final locationLabel = _settings?.locationLabel ?? '—';
    final locationUnset = locationLabel == 'Default';
    final dateStr = _formatGregorian(now);
    final hijriStr = getHijriDate();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
                ).then((_) => _load());
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(
                      locationUnset
                          ? Icons.warning_amber_rounded
                          : Icons.location_on_outlined,
                      size: locationUnset ? 18 : 20,
                      color: locationUnset
                          ? Colors.white.withOpacity(0.45)
                          : _accentChampagneGold,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        locationUnset
                            ? 'Standort nicht gesetzt'
                            : locationLabel,
                        style: GoogleFonts.inter(
                          fontSize: locationUnset ? 13 : 14,
                          fontWeight: FontWeight.w600,
                          color: locationUnset
                              ? Colors.white.withOpacity(0.82)
                              : Colors.white,
                          shadows: _textShadow,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            dateStr,
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              shadows: _textShadow,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.nightlight_round_outlined,
                size: 18,
                color: _accentChampagneGold,
              ),
              const SizedBox(width: 6),
              Text(
                hijriStr,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _accentChampagneGold,
                  shadows: _textShadow,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Islamisches Datum',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.5,
              color: Colors.white.withOpacity(0.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextPrayerSection() {
    if (_result == null) {
      return GlassCard(
        borderRadius: 20,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Center(child: CircularProgressIndicator(color: Colors.white70)),
        ),
      );
    }

    final r = _result!;
    final countdownStr = PrayerTimesRepository.formatCountdown(
      r.nextPrayerTime.difference(DateTime.now()),
    );
    final nextTimeStr = PrayerTimesRepository.instance.formatTime(r.nextPrayerTime);

    return GlassCard(
      borderRadius: 20,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Nächstes Gebet',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    r.nextPrayerType.label,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    nextTimeStr,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              countdownStr,
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: _accentChampagneGold,
                height: 1.05,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyListHeader() {
    return Text(
      'Tagesgebete',
      style: GoogleFonts.playfairDisplay(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        shadows: const [Shadow(color: Colors.black45, blurRadius: 4)],
      ),
    );
  }

  Widget _buildDailyList() {
    if (_result == null) return const SizedBox.shrink();

    final r = _result!;
    final now = DateTime.now();
    final times = r.times;

    // Chronologische Reihenfolge: Fajr, Sonnenaufgang, … (prayerTypeOrderForDisplay).
    final order = prayerTypeOrderForDisplay;
    PrayerType? currentType;
    for (var i = order.length - 1; i >= 0; i--) {
      final type = order[i];
      final t = times[type];
      if (t != null && (now.isAfter(t) || now.isAtSameMomentAs(t))) {
        currentType = type;
        break;
      }
    }

    return GlassCard(
      borderRadius: 20,
      child: Column(
        children: [
          for (var i = 0; i < order.length; i++) ...[
            _buildPrayerRow(
              prayerType: order[i],
              time: times[order[i]] != null
                  ? PrayerTimesRepository.instance.formatTime(times[order[i]]!)
                  : '—',
              status: () {
                final type = order[i];
                final t = times[type];
                if (t == null) return _PrayerRowStatus.past;
                if (now.isBefore(t)) return _PrayerRowStatus.upcoming;
                return type == currentType ? _PrayerRowStatus.current : _PrayerRowStatus.past;
              }(),
            ),
            if (i < order.length - 1)
              Divider(height: 1, color: Colors.white.withOpacity(0.15)),
          ],
        ],
      ),
    );
  }

  Widget _buildPrayerRow({
    required PrayerType prayerType,
    required String time,
    required _PrayerRowStatus status,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                prayerType.icon,
                size: 20,
                color: _accentChampagneGold,
              ),
              const SizedBox(width: 10),
              Text(
                prayerType.label,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Text(
            time,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKarahatSection() {
    final r = _result;
    if (r == null) return const SizedBox.shrink();

    final sunrise = r.times[PrayerType.sunrise];
    final dhuhr = r.times[PrayerType.dhuhr];
    final maghrib = r.times[PrayerType.maghrib];
    if (sunrise == null || dhuhr == null || maghrib == null) {
      return const SizedBox.shrink();
    }

    final windows = <({
      String label,
      DateTime start,
      DateTime end,
    })>[
      (
        label: 'Sonnenaufgang',
        start: sunrise,
        end: sunrise.add(_karahatSunriseDuration),
      ),
      (
        label: 'Zenit',
        start: dhuhr.subtract(_karahatZenithBefore),
        end: dhuhr.add(_karahatZenithAfter),
      ),
      (
        label: 'Sonnenuntergang',
        start: maghrib.subtract(_karahatSunsetDuration),
        end: maghrib,
      ),
    ];

    final now = DateTime.now();
    final isNowKarahat = windows.any(
      (w) => !now.isBefore(w.start) && now.isBefore(w.end),
    );

    return GlassCard(
      borderRadius: 20,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: _accentChampagneGold,
                ),
                const SizedBox(width: 8),
                Text(
                  'Karahat-Zeiten heute',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                if (isNowKarahat)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _accentChampagneGold.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: _accentChampagneGold.withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Jetzt',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _accentChampagneGold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < windows.length; i++) ...[
              _buildKarahatRow(
                label: windows[i].label,
                start: windows[i].start,
                end: windows[i].end,
              ),
              if (i < windows.length - 1)
                Divider(
                  height: 14,
                  color: Colors.white.withOpacity(0.12),
                ),
            ],
            const SizedBox(height: 8),
            Text(
              'Hinweis: Zeiten dienen der Orientierung und können je nach Schule/Quelle leicht variieren.',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                height: 1.35,
                color: Colors.white.withOpacity(0.62),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKarahatRow({
    required String label,
    required DateTime start,
    required DateTime end,
  }) {
    final startStr = PrayerTimesRepository.instance.formatTime(start);
    final endStr = PrayerTimesRepository.instance.formatTime(end);
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.88),
            ),
          ),
        ),
        Text(
          '$startStr–$endStr',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildQiblaButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const QiblaScreen()),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.25),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
          ),
          child: Row(
            children: [
              Icon(Icons.explore_outlined, color: _accentChampagneGold, size: 28),
              const SizedBox(width: 16),
              Text(
                'Qibla-Kompass',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Icon(Icons.chevron_right_rounded, color: Colors.white54, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTasbihButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const TasbihScreen()),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.25),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
          ),
          child: Row(
            children: [
              Icon(Icons.touch_app_rounded, color: _accentChampagneGold, size: 28),
              const SizedBox(width: 16),
              Text(
                'Tasbih / Zikr',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Icon(Icons.chevron_right_rounded, color: Colors.white54, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    final method = _settings?.method.displayName ?? '—';
    final madhab = _settings?.madhab.displayName ?? '—';
    final location = _settings?.locationLabel ?? '—';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
          ).then((_) => _load());
        },
        borderRadius: BorderRadius.circular(20),
        child: GlassCard(
          borderRadius: 20,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Einstellungen',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: Colors.white70, size: 22),
                  ],
                ),
                const SizedBox(height: 14),
                _infoRow('Methode', method),
                const SizedBox(height: 6),
                _infoRow('Asr-Berechnung', madhab),
                const SizedBox(height: 6),
                _infoRow('Standort', location),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 88,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  static String _formatGregorian(DateTime d) {
    const months = [
      'Januar', 'Februar', 'März', 'April', 'Mai', 'Juni',
      'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember',
    ];
    return '${d.day}. ${months[d.month - 1]} ${d.year}';
  }
}

int _gregorianToJulian(int year, int month, int day) {
  final a = ((14 - month) / 12).floor();
  final y = year + 4800 - a;
  final m = month + 12 * a - 3;
  return day + ((153 * m + 2) / 5).floor() + 365 * y +
      (y / 4).floor() - (y / 100).floor() + (y / 400).floor() - 32045;
}
