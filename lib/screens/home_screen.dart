import 'dart:async';

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
import '../models/surah.dart';
import '../data/daily_verse/daily_verse_service.dart';
import 'explanation_bottom_sheet.dart';
import 'quran_reader_screen.dart';
import 'my_verses_screen.dart';

// ——— Layout constants ———
const double _outerPadding = 24;
const double _heroCardRadius = 26;
const double _greetingToHeroGap = 48;
const double _heroToPrayerGap = 40;
const double _bottomScrollInset = 120;

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
  final List<GlobalKey> _prayerKeys = List.generate(6, (_) => GlobalKey());
  final ScrollController _prayerScrollController = ScrollController();
  final ScrollController _mainScrollController = ScrollController();
  // Initial true: kein Scroll aus build(); Chip-Ausrichtung nur in _loadPrayerTimes.
  // ignore: unused_field, prefer_final_fields
  bool _prayerScrollDone = true;
  late final Future<Map<String, dynamic>> _verseOfTheDayFuture;
  Future<String>? _dailyTakeawayFuture;

  @override
  void initState() {
    super.initState();
    _verseOfTheDayFuture = DailyVerseService.instance.getVerseOfTheDay();
    _loadLastRead();
    _loadPrayerTimes();
    _prayerTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updatePrayerCountdown());
  }

  @override
  void dispose() {
    _prayerTimer?.cancel();
    _prayerScrollController.dispose();
    _mainScrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentPrayer(int currentIndex) {
    if (currentIndex < 0 || currentIndex >= _prayerKeys.length) return;
    final keyContext = _prayerKeys[currentIndex].currentContext;
    if (keyContext != null) {
      Scrollable.ensureVisible(
        keyContext,
        alignment: 0.5,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      final pos = _prayerScrollController.hasClients
          ? _prayerScrollController.position
          : null;
      if (pos != null) {
        const approxItemWidth = 93.0;
        final viewportWidth = pos.viewportDimension;
        var offset = currentIndex * approxItemWidth - viewportWidth / 2 + approxItemWidth / 2;
        offset = offset.clamp(0.0, pos.maxScrollExtent);
        _prayerScrollController.animateTo(
          offset,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  Future<void> _loadPrayerTimes() async {
    final settings = await SettingsRepository.instance.getPrayerSettings();
    if (!mounted) return;
    final now = DateTime.now();
    final result = PrayerTimesRepository.instance.computeToday(settings, now);
    if (mounted) {
      setState(() => _prayerResult = result);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _prayerResult == null) return;
        final nextIdx = prayerTypeOrderForDisplay.indexOf(_prayerResult!.nextPrayerType);
        if (nextIdx >= 0) {
          final currIdx = (nextIdx - 1 + prayerTypeOrderForDisplay.length) % prayerTypeOrderForDisplay.length;
          _scrollToCurrentPrayer(currIdx);
        }
      });
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
            clipBehavior: Clip.none,
            children: [
            // Layer 1: Pure mosque image, no color filter – faint so gradient stays vibrant
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
          // Layer 2: Dashboard (vertikal nicht scrollbar)
          SafeArea(
            child: CustomScrollView(
              controller: _mainScrollController,
              physics: const NeverScrollableScrollPhysics(),
              // Schatten des Tagesvers-Hero (Gold-Glow) liegen außerhalb der Box — sonst clippt die Viewport.
              clipBehavior: Clip.none,
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    _outerPadding,
                    _greetingToHeroGap,
                    _outerPadding,
                    _heroToPrayerGap,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: FutureBuilder<Map<String, dynamic>>(
                      future: _verseOfTheDayFuture,
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
                        final data = snapshot.data;
                        if (data == null) {
                          return const SizedBox.shrink();
                        }
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
                            MaterialPageRoute<void>(builder: (_) => const MyVersesScreen()),
                          );
                        }

                        return FutureBuilder<String>(
                          future: _dailyTakeawayFuture,
                          builder: (context, takeawaySnap) {
                            final loadingTakeaway =
                                takeawaySnap.connectionState == ConnectionState.waiting;
                            final takeawayRaw = takeawaySnap.data;
                            final takeawayLine =
                                loadingTakeaway ? '...' : (takeawayRaw ?? '...');
                            final takeawayNeutral = loadingTakeaway ||
                                takeawayRaw == null ||
                                takeawayRaw == TakeawayService.fallbackMessage;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
                              child: HomeDailyVerseHero(
                                surahNameEn: surahNameEn,
                                ayahNumber: ayahNumber,
                                arabic: textAr,
                                german: textDe,
                                personalTakeaway: takeawayLine,
                                takeawayNeutralPresentation: takeawayNeutral,
                                onMehrVerstehen: openExplanation,
                                onBookmarkTap: () {},
                                onWeiterlesen: _lastRead != null ? openWeiterlesen : null,
                                onSpeichern: openSpeichern,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildPrayerSummarySecondary(),
                ),
                SliverToBoxAdapter(
                  child: _buildPrayerChips(),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 16),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(height: 24 + _bottomScrollInset),
                ),
              ],
            ),
          ),
        ],
        ),
        ),
      ),
    );
  }

  /// Zeit, nächstes Gebet und Countdown — bewusst zurückhaltender als der Tagesvers-Hero.
  Widget _buildPrayerSummarySecondary() {
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final nextPrayerType = _prayerResult?.nextPrayerType;
    final nextLabel = nextPrayerType?.label ?? '—';
    final countdownStr = _prayerResult != null
        ? PrayerTimesRepository.formatCountdown(_prayerResult!.timeUntilNextPrayer)
        : '—:——';

    return Padding(
      padding: const EdgeInsets.fromLTRB(_outerPadding, 0, _outerPadding, 14),
      child: Opacity(
        opacity: 0.86,
        child: GlassCard(
          borderRadius: 18,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  timeStr,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.92),
                    letterSpacing: -0.4,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    width: 1,
                    height: 36,
                    color: Colors.white.withOpacity(0.12),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nächstes Gebet',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.9,
                          color: Colors.white.withOpacity(0.45),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$nextLabel in $countdownStr',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                          color: Colors.white.withOpacity(0.82),
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
    );
  }

  Widget _buildPrayerChips() {
    final nextPrayerType = _prayerResult?.nextPrayerType;
    final nextPrayerIndex = nextPrayerType != null
        ? prayerTypeOrderForDisplay.indexOf(nextPrayerType)
        : -1;
    final currentPrayerIndex = nextPrayerIndex >= 0
        ? (nextPrayerIndex - 1 + prayerTypeOrderForDisplay.length) % prayerTypeOrderForDisplay.length
        : -1;
    final currentPrayerType = currentPrayerIndex >= 0
        ? prayerTypeOrderForDisplay[currentPrayerIndex]
        : null;

    return Opacity(
      opacity: 0.88,
      child: SizedBox(
        height: 44,
        child: ListView.separated(
        key: const PageStorageKey<String>('prayer_chips'),
        controller: _prayerScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: prayerTypeOrderForDisplay.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final prayerType = prayerTypeOrderForDisplay[index];
          final isCurrent = currentPrayerType == prayerType;
          final chipTime = _prayerResult != null && _prayerResult!.timeFor(prayerType) != null
              ? PrayerTimesRepository.instance.formatTime(_prayerResult!.timeFor(prayerType)!)
              : null;
          final label = chipTime != null ? '${prayerType.label} $chipTime' : prayerType.label;
          return Container(
            key: _prayerKeys[index],
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isCurrent ? Colors.white.withOpacity(0.18) : Colors.white.withOpacity(0.08),
              border: Border.all(
                color: isCurrent ? _accentChampagneGold.withOpacity(0.45) : Colors.white.withOpacity(0.12),
                width: isCurrent ? 0.85 : 0.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    prayerType.icon,
                    size: 15,
                    color: isCurrent ? _accentChampagneGold.withOpacity(0.95) : Colors.white.withOpacity(0.88),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                      color: Colors.white.withOpacity(isCurrent ? 0.95 : 0.85),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      ),
    );
  }
}
