import 'dart:async';
import 'dart:ui' show FontFeature, ImageFilter;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/reading/reading_progress_repository.dart';
import '../data/reading/reading_progress.dart';
import '../data/quran/quran_repository.dart';
import '../data/ai/takeaway_service.dart';
import '../data/prayer/notification_service.dart';
import '../data/prayer/prayer_models.dart';
import '../data/prayer/prayer_times_repository.dart';
import '../prayer/prayer_type.dart';
import '../data/settings/settings_repository.dart';
import '../theme/app_theme.dart';
import '../theme/hero_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/home_daily_verse_hero.dart';
import '../widgets/home_daily_hadith_card.dart' show kShowDailyHadithOnHome;
import '../models/surah.dart';
import '../data/daily_verse/daily_verse_service.dart';
import '../data/daily_hadith/daily_hadith_entry.dart';
import '../data/daily_hadith/daily_hadith_service.dart';
import 'explanation_bottom_sheet.dart';
import 'quran_reader_screen.dart';
import 'my_verses_screen.dart';

// ——— Layout constants ———
const double _outerPadding = 24;
const double _heroCardRadius = 26;
const double _greetingToHeroGap = 40;
const double _heroToPrayerGap = 20;
const double _scrollBottomBreathing = 28;
/// Abstand unter der Gebetsleiste: schwebende Tabbar (PremiumBottomNav ~72 + Rand 24) + Puffer.
const double _floatingNavClearance = 112;
const Duration _karahatSunriseDuration = Duration(minutes: 20);
const Duration _karahatZenithBefore = Duration(minutes: 5);
const Duration _karahatZenithAfter = Duration(minutes: 5);
const Duration _karahatSunsetDuration = Duration(minutes: 20);

/// Obere Rundung wie KI-Erklärungs-Sheet (`explanation_bottom_sheet.dart`).
const double _prayerSheetTopRadius = 24;

class _KarahatInlineInfo {
  const _KarahatInlineInfo({
    required this.label,
    required this.timeRange,
    required this.isActive,
  });

  final String label;
  final String timeRange;
  final bool isActive;
}

/// Premium champagne-gold accent (e.g. next prayer, AI CTA).
const Color _accentChampagneGold = Color(0xFFE5C07B);

/// Premium Home: full-screen gradient, glassmorphism cards, integrated hero.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  ReadingProgress? _lastRead;
  String? _lastReadSurahNameEn;
  String? _lastReadSurahNameAr;
  PrayerTimesResult? _prayerResult;
  Timer? _prayerTimer;
  final ScrollController _mainScrollController = ScrollController();
  late final Future<_HomeDailyPack> _homeDailyPackFuture;
  Future<String>? _dailyTakeawayFuture;

  @override
  void initState() {
    super.initState();
    _homeDailyPackFuture = _loadHomeDailyPack();
    _loadLastRead();
    _loadPrayerTimes();
    _prayerTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updatePrayerCountdown());
  }

  @override
  void dispose() {
    _prayerTimer?.cancel();
    _mainScrollController.dispose();
    super.dispose();
  }

  Future<_HomeDailyPack> _loadHomeDailyPack() async {
    final verse = await DailyVerseService.instance.getVerseOfTheDay();
    DailyHadithEntry? hadith;
    if (kShowDailyHadithOnHome) {
      hadith = await DailyHadithService.instance.getHadithOfTheDay();
    }
    return _HomeDailyPack(verse: verse, hadith: hadith);
  }

  Future<void> _loadPrayerTimes() async {
    final settings = await SettingsRepository.instance.getPrayerSettings();
    if (!mounted) return;
    final now = DateTime.now();
    final result = PrayerTimesRepository.instance.computeToday(settings, now);
    if (mounted) {
      setState(() => _prayerResult = result);
    }
    final enabled = await SettingsRepository.instance.getNotificationsEnabled();
    if (mounted && enabled) {
      await NotificationService.instance.schedulePrayerNotifications(result, settings);
    }
  }

  void _updatePrayerCountdown() {
    if (_prayerResult == null) return;
    final now = DateTime.now();
    final next = _prayerResult!.nextPrayerTime;
    final d = next.difference(now);
    if (d.inSeconds != _prayerResult!.timeUntilNextPrayer.inSeconds && mounted) {
      setState(() {
        _prayerResult = PrayerTimesResult(
          times: _prayerResult!.times,
          now: now,
          nextPrayerType: _prayerResult!.nextPrayerType,
          nextPrayerTime: next,
          timeUntilNextPrayer: d,
        );
      });
    }
    if (now.day != _prayerResult!.now.day && mounted) {
      _loadPrayerTimes();
    }
  }

  Future<void> _loadLastRead() async {
    final progress = await ReadingProgressRepository.instance.getLastRead();
    if (progress == null || !mounted) return;
    final surahs = await QuranRepository.instance.getAllSurahs();
    final match = surahs.where((s) => s.id == progress.surahId);
    final nameEn = match.isEmpty ? null : match.first.nameEn;
    final nameAr = match.isEmpty ? null : match.first.nameAr;
    if (mounted) {
      setState(() {
        _lastRead = progress;
        _lastReadSurahNameEn = nameEn;
        _lastReadSurahNameAr = nameAr;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final heroPhase = DynamicHeroTheme.phaseFromPrayer(_prayerResult?.nextPrayerType);

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
            clipBehavior: Clip.hardEdge,
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
              Positioned.fill(
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Stack(
                          fit: StackFit.expand,
                          clipBehavior: Clip.hardEdge,
                          children: [
                            CustomScrollView(
                              controller: _mainScrollController,
                              physics: const BouncingScrollPhysics(
                                parent: AlwaysScrollableScrollPhysics(),
                              ),
                              clipBehavior: Clip.hardEdge,
                              slivers: [
                                SliverPadding(
                                  padding: const EdgeInsets.fromLTRB(
                                    _outerPadding,
                                    _greetingToHeroGap,
                                    _outerPadding,
                                    _heroToPrayerGap,
                                  ),
                                  sliver: SliverToBoxAdapter(
                                    child: FutureBuilder<_HomeDailyPack>(
                                      future: _homeDailyPackFuture,
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return GlassCard(
                                            borderRadius: _heroCardRadius,
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 48),
                                              child: Center(
                                                child: SizedBox(
                                                  width: 22,
                                                  height: 22,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: _accentChampagneGold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        }
                                        final pack = snapshot.data;
                                        if (pack == null) {
                                          return const SizedBox.shrink();
                                        }
                                        final data = pack.verse;
                                        final surahNameEn = data['surahNameEn'] as String? ?? '';
                                        final ayahNumber = data['ayahNumber'] as int? ?? 0;
                                        final textAr = data['textAr'] as String? ?? '';
                                        final textDe = data['textDe'] as String? ?? '—';
                                        _dailyTakeawayFuture ??= TakeawayService.generateTakeaway(
                                          arabic: textAr,
                                          translation: textDe,
                                          surahName: surahNameEn,
                                          ayahNumber: ayahNumber,
                                        );
                                        void openExplanation() => showAiExplanationWithQuotaCheck(
                                              context,
                                              verseTitle: '$surahNameEn, Vers $ayahNumber',
                                              surahName: surahNameEn,
                                              ayahNumber: ayahNumber,
                                              textAr: textAr,
                                              textDe: textDe,
                                              isFreeDailyVerse: true,
                                            );
                                        void openWeiterlesen() {
                                          final p = _lastRead!;
                                          final surah = Surah(
                                            number: p.surahId,
                                            nameDe: _lastReadSurahNameEn ?? 'Sure ${p.surahId}',
                                            nameAr: _lastReadSurahNameAr ?? '',
                                            verses: const [],
                                          );
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute<void>(
                                              builder: (_) => QuranReaderScreen(
                                                surah: surah,
                                                initialAyahNumber: p.ayahNumber,
                                              ),
                                            ),
                                          ).then((_) => _loadLastRead());
                                        }

                                        void openSpeichern() {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute<void>(
                                                builder: (_) => const MyVersesScreen()),
                                          );
                                        }

                                        return FutureBuilder<String>(
                                          future: _dailyTakeawayFuture,
                                          builder: (context, takeawaySnap) {
                                            final loadingTakeaway = takeawaySnap.connectionState ==
                                                ConnectionState.waiting;
                                            final takeawayRaw = takeawaySnap.data;
                                            final takeawayLine =
                                                loadingTakeaway ? '...' : (takeawayRaw ?? '...');
                                            final takeawayNeutral = loadingTakeaway ||
                                                takeawayRaw == null ||
                                                takeawayRaw == TakeawayService.fallbackMessage;
                                            return Padding(
                                              padding: const EdgeInsets.symmetric(
                                                  vertical: 8, horizontal: 2),
                                              child: HomeDailyVerseHero(
                                                surahNameEn: surahNameEn,
                                                ayahNumber: ayahNumber,
                                                arabic: textAr,
                                                german: textDe,
                                                personalTakeaway: takeawayLine,
                                                takeawayNeutralPresentation: takeawayNeutral,
                                                onMehrVerstehen: openExplanation,
                                                onBookmarkTap: () {},
                                                onWeiterlesen:
                                                    _lastRead != null ? openWeiterlesen : null,
                                                onSpeichern: openSpeichern,
                                                dailyHadith:
                                                    kShowDailyHadithOnHome ? pack.hadith : null,
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                const SliverToBoxAdapter(
                                  child: SizedBox(height: 16),
                                ),
                                const SliverToBoxAdapter(
                                  child: SizedBox(height: _scrollBottomBreathing),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SafeArea(
                        top: false,
                        child: _buildPrayerDock(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrayerTimesHalfSheet(BuildContext context) {
    final media = MediaQuery.of(context);
    final h = media.size.height;
    final bottomInset = media.padding.bottom;
    final keyboardBottom = media.viewInsets.bottom;
    final maxScrollRegion = h * 0.58;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (ctx) {
        final sheetTint = Color.lerp(
          AppColors.emeraldDark,
          Colors.black,
          0.28,
        )!.withOpacity(0.93);

        return SizedBox(
          height: h,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.pop(ctx),
                  child: ColoredBox(
                    color: Colors.black.withOpacity(0.35),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 8 + bottomInset + keyboardBottom,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(_prayerSheetTopRadius),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      decoration: BoxDecoration(
                        color: sheetTint,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(_prayerSheetTopRadius),
                        ),
                        border: Border(
                          top: BorderSide(
                            color: Colors.white.withOpacity(0.28),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 14,
                          right: 14,
                          top: 12,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 8),
                            Center(
                              child: Container(
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.45),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ConstrainedBox(
                              constraints: BoxConstraints(maxHeight: maxScrollRegion),
                              child: CustomScrollView(
                                shrinkWrap: true,
                                physics: const BouncingScrollPhysics(),
                                slivers: [
                                  SliverPadding(
                                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 16),
                                    sliver: SliverToBoxAdapter(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          _buildPrayerSummaryPaddedBody(
                                            showChevron: false,
                                            contextForKarahat: ctx,
                                          ),
                                          _prayerExpandedSoftDivider(),
                                          _buildPrayerDayOverview(),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPrayerDock() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 10, 0, _floatingNavClearance),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(_outerPadding, 0, _outerPadding, 6),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => _showPrayerTimesHalfSheet(context),
            splashColor: Colors.white.withOpacity(0.06),
            highlightColor: Colors.white.withOpacity(0.03),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: AppColors.emeraldDark.withOpacity(0.94),
                border: Border.all(color: Colors.white.withOpacity(0.14)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.28),
                    blurRadius: 18,
                    spreadRadius: -2,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: _buildPrayerSummaryPaddedBody(showChevron: true),
            ),
          ),
        ),
      ),
    );
  }

  Widget _prayerExpandedSoftDivider() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 2),
      child: Container(
        height: 1,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(1),
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              Colors.white.withOpacity(0.07),
              Colors.white.withOpacity(0.1),
              Colors.white.withOpacity(0.07),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  void _showKarahatDetail(BuildContext context, _KarahatInlineInfo k) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bottom = MediaQuery.paddingOf(ctx).bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + bottom),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.emeraldDark,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Karahat',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.96),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    k.label,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.88),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    k.timeRange,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: k.isActive ? _accentChampagneGold : Colors.white.withOpacity(0.9),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        'Schließen',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _accentChampagneGold.withOpacity(0.95),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrayerSummaryPaddedBody({
    bool showChevron = false,
    bool chevronOpen = false,
    BuildContext? contextForKarahat,
  }) {
    final ctx = contextForKarahat ?? context;
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final nextPrayerType = _prayerResult?.nextPrayerType;
    final nextLabel = nextPrayerType?.label ?? '—';
    final countdownStr = _prayerResult != null
        ? PrayerTimesRepository.formatCountdown(_prayerResult!.timeUntilNextPrayer)
        : '—:——';
    final karahat = _buildKarahatInlineInfo(_prayerResult);

    final chevron = Icon(
      chevronOpen ? Icons.expand_less_rounded : Icons.expand_more_rounded,
      size: 26,
      color: Colors.white.withOpacity(0.52),
    );

    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          timeStr,
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.92),
            letterSpacing: -0.35,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 8,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 2, 12, 0),
          child: Container(
            width: 1,
            height: 40,
            color: Colors.white.withOpacity(0.14),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Nächstes Gebet',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.85,
                  color: Colors.white.withOpacity(0.48),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$nextLabel in $countdownStr',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  height: 1.28,
                  color: Colors.white.withOpacity(0.88),
                ),
              ),
              if (karahat != null) ...[
                const SizedBox(height: 6),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showKarahatDetail(ctx, karahat),
                    borderRadius: BorderRadius.circular(8),
                    splashColor: Colors.white.withOpacity(0.08),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 2),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 13,
                            color: karahat.isActive
                                ? _accentChampagneGold
                                : Colors.white.withOpacity(0.76),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              karahat.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.86),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            karahat.timeRange,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: karahat.isActive
                                  ? _accentChampagneGold
                                  : Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (showChevron) Padding(padding: const EdgeInsets.only(left: 2, top: 6), child: chevron),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: row,
    );
  }

  _KarahatInlineInfo? _buildKarahatInlineInfo(PrayerTimesResult? r) {
    if (r == null) return null;

    final sunrise = r.times[PrayerType.sunrise];
    final dhuhr = r.times[PrayerType.dhuhr];
    final maghrib = r.times[PrayerType.maghrib];
    if (sunrise == null || dhuhr == null || maghrib == null) return null;

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
    final active = windows.where((w) => !now.isBefore(w.start) && now.isBefore(w.end)).toList();
    final upcoming = windows.where((w) => now.isBefore(w.start)).toList()
      ..sort((a, b) => a.start.compareTo(b.start));

    final activeWindow = active.isNotEmpty ? active.first : null;
    final nextWindow = upcoming.isNotEmpty ? upcoming.first : null;

    final isActive = activeWindow != null;
    final label = isActive
        ? 'Karahat jetzt (${activeWindow.label})'
        : (nextWindow != null ? 'Nächste Karahat (${nextWindow.label})' : 'Karahat heute');
    final DateTime? start = isActive ? activeWindow.start : nextWindow?.start;
    final DateTime? end = isActive ? activeWindow.end : nextWindow?.end;
    final timeRange = (start != null && end != null)
        ? '${PrayerTimesRepository.instance.formatTime(start)}–${PrayerTimesRepository.instance.formatTime(end)}'
        : 'Heute beendet';
    return _KarahatInlineInfo(
      label: label,
      timeRange: timeRange,
      isActive: isActive,
    );
  }

  Widget _buildPrayerDayOverview() {
    final current = _currentPrayerBlockType();
    const mid = 3;
    final row1 = prayerTypeOrderForDisplay.sublist(0, mid);
    final row2 = prayerTypeOrderForDisplay.sublist(mid);

    return Padding(
      padding: const EdgeInsets.fromLTRB(_outerPadding - 2, 0, _outerPadding - 2, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < row1.length; i++) ...[
                if (i > 0) _prayerGridVerticalRule(),
                Expanded(
                  child: _PrayerOverviewSlot(
                    prayerType: row1[i],
                    result: _prayerResult,
                    isCurrent: row1[i] == current,
                  ),
                ),
              ],
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, thickness: 1, color: Colors.white.withOpacity(0.06)),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < row2.length; i++) ...[
                if (i > 0) _prayerGridVerticalRule(),
                Expanded(
                  child: _PrayerOverviewSlot(
                    prayerType: row2[i],
                    result: _prayerResult,
                    isCurrent: row2[i] == current,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _prayerGridVerticalRule() {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 6),
      child: Center(
        child: Container(
          width: 1,
          height: 44,
          color: Colors.white.withOpacity(0.09),
        ),
      ),
    );
  }

  PrayerType? _currentPrayerBlockType() {
    final nextPrayerType = _prayerResult?.nextPrayerType;
    final nextPrayerIndex =
        nextPrayerType != null ? prayerTypeOrderForDisplay.indexOf(nextPrayerType) : -1;
    final currentPrayerIndex = nextPrayerIndex >= 0
        ? (nextPrayerIndex - 1 + prayerTypeOrderForDisplay.length) %
            prayerTypeOrderForDisplay.length
        : -1;
    if (currentPrayerIndex < 0) return null;
    return prayerTypeOrderForDisplay[currentPrayerIndex];
  }
}

class _PrayerOverviewSlot extends StatelessWidget {
  const _PrayerOverviewSlot({
    required this.prayerType,
    required this.result,
    required this.isCurrent,
  });

  final PrayerType prayerType;
  final PrayerTimesResult? result;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final t = result?.timeFor(prayerType);
    final timeStr = t != null ? PrayerTimesRepository.instance.formatTime(t) : '—';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            prayerType.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.35,
              color: isCurrent
                  ? _accentChampagneGold.withOpacity(0.9)
                  : Colors.white.withOpacity(0.44),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            timeStr,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
              letterSpacing: 0.15,
              color: isCurrent
                  ? Colors.white.withOpacity(0.96)
                  : Colors.white.withOpacity(0.86),
            ),
          ),
          const SizedBox(height: 7),
          Container(
            height: 2.5,
            width: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: isCurrent
                  ? _accentChampagneGold.withOpacity(0.92)
                  : Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeDailyPack {
  const _HomeDailyPack({required this.verse, this.hadith});

  final Map<String, dynamic> verse;
  final DailyHadithEntry? hadith;
}
