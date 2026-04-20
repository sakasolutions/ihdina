# Ihdina Flutter App — Context Dump for Tier-1 Visual Redesign

---

## 1. Directory Structure (lib/)

```
lib/
├── config/
│   └── geonames_config.dart
├── data/
│   ├── bookmarks/
│   │   ├── bookmark_item.dart
│   │   ├── bookmark_model.dart
│   │   └── bookmark_repository.dart
│   ├── db/
│   │   └── database_provider.dart
│   ├── location/
│   │   ├── city_search_result.dart
│   │   └── geonames_repository.dart
│   ├── prayer/
│   │   ├── prayer_models.dart
│   │   └── prayer_times_repository.dart
│   ├── quran/
│   │   ├── models/
│   │   │   ├── ayah_model.dart
│   │   │   └── surah_model.dart
│   │   └── quran_repository.dart
│   ├── reading/
│   │   ├── reading_progress.dart
│   │   └── reading_progress_repository.dart
│   ├── search/
│   │   └── search_result.dart
│   └── settings/
│       └── settings_repository.dart
├── debug/
│   └── db_diagnostics.dart
├── design/
│   ├── premium_card.dart
│   └── primary_button.dart
├── main.dart
├── models/
│   ├── surah.dart
│   └── verse.dart
├── prayer/
│   └── prayer_type.dart
├── screens/
│   ├── bootstrap_screen.dart
│   ├── city_search_screen.dart
│   ├── explanation_bottom_sheet.dart
│   ├── home_screen.dart
│   ├── my_verses_screen.dart
│   ├── prayer_screen.dart
│   ├── quran_reader_screen.dart
│   ├── quran_screen.dart
│   ├── root_shell.dart
│   ├── search_screen.dart
│   ├── settings_screen.dart
│   └── sources_screen.dart
├── theme/
│   ├── app_theme.dart
│   ├── hero_theme.dart
│   └── tokens.dart
├── utils/
│   └── basmalah.dart
└── widgets/
    ├── premium_bottom_nav.dart
    └── prayer_chip.dart
```

---

## 2. Architecture Mapping (full file paths)

| Component | Full path |
|-----------|-----------|
| **HomeScreen** | `lib/screens/home_screen.dart` |
| **Hero section** | `lib/screens/home_screen.dart` (widget `HeroSection`, same file) |
| **PrayerTimesRepository** | `lib/data/prayer/prayer_times_repository.dart` |
| **Continue Reading** | `lib/screens/home_screen.dart` — `HomeQuickActionsRow` + `_QuickActionCard` (first card); data from `_loadLastRead()` → `ReadingProgressRepository` / `QuranRepository` |
| **Daily Verse card** | `lib/screens/home_screen.dart` — widget `DailyVerseCard` |
| **AppColors** | `lib/theme/app_theme.dart` |
| **AppGradients** | `lib/theme/app_theme.dart` |
| **AppTokens** | `lib/theme/tokens.dart` |
| **Dynamic Hero Theme** | `lib/theme/hero_theme.dart` |
| **ThemeData (MaterialApp)** | `lib/main.dart` — `ThemeData( colorScheme: ..., surface: AppColors.sandBg )` |

---

## 3. The "Beige Background" Issue

**Color value:** `#F3EBDD` (beige/sand).

**Where it is defined:**

| File | Location | Usage |
|------|----------|--------|
| **lib/theme/tokens.dart** | Line 8 | `static const Color bg = Color(0xFFF3EBDD);` — main token for page background |
| **lib/theme/app_theme.dart** | Line 7 | `static const Color sandBg = Color(0xFFF3EBDD);` — same value |
| **lib/theme/app_theme.dart** | Lines 26, 31–32, 39, 45 | `AppGradients.subtleBackground` and `subtleRadial` use `AppColors.sandBg` |
| **lib/main.dart** | Line 18 | `systemNavigationBarColor: AppColors.sandBg` — system nav bar |
| **lib/main.dart** | Line 37 | `theme: ThemeData( colorScheme: ColorScheme.fromSeed(..., surface: AppColors.sandBg ) )` — global Material surface |

**Where it is used (Scaffold/Container backgrounds):**

| File | Usage |
|------|--------|
| **lib/screens/home_screen.dart** | Body `decoration`: `color: AppTokens.surface`, `colors: [AppTokens.bg, AppTokens.surface]` |
| **lib/screens/bootstrap_screen.dart** | `Scaffold( backgroundColor: AppTokens.bg )` |
| **lib/screens/settings_screen.dart** | `Scaffold( backgroundColor: AppTokens.bg )`, body gradient uses `AppTokens.bg` |
| **lib/screens/quran_screen.dart** | Root `Container` `color: AppTokens.bg`, gradient with `AppTokens.bg` |
| **lib/screens/quran_reader_screen.dart** | `Scaffold( backgroundColor: AppTokens.bg )`, body gradient `AppTokens.bg` |
| **lib/screens/prayer_screen.dart** | `Container` `color: AppTokens.bg`, gradient `AppTokens.bg` |
| **lib/screens/search_screen.dart** | `Scaffold( backgroundColor: AppTokens.bg )`, body gradient `AppTokens.bg` |
| **lib/screens/my_verses_screen.dart** | `Scaffold( backgroundColor: AppTokens.bg )`, body gradient `AppTokens.bg` |
| **lib/screens/city_search_screen.dart** | `Scaffold( backgroundColor: AppTokens.bg )` |
| **lib/screens/sources_screen.dart** | `Scaffold( backgroundColor: AppTokens.bg )` |

**Summary:** Beige is the single source of truth for “page background” via `AppTokens.bg` and `AppColors.sandBg`, and for the global theme surface and system nav bar in `main.dart`. Changing the palette should start from `lib/theme/tokens.dart` and `lib/theme/app_theme.dart`, then `lib/main.dart`, then the screens above.

---

## 4. Code Dump

### lib/screens/home_screen.dart

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/reading/reading_progress_repository.dart';
import '../data/reading/reading_progress.dart';
import '../data/quran/quran_repository.dart';
import '../data/bookmarks/bookmark_repository.dart';
import '../data/prayer/prayer_models.dart';
import '../data/prayer/prayer_times_repository.dart';
import '../prayer/prayer_type.dart';
import '../data/settings/settings_repository.dart';
import '../theme/hero_theme.dart';
import '../theme/tokens.dart';
import '../models/surah.dart';
import 'explanation_bottom_sheet.dart';
import 'quran_reader_screen.dart';
import 'my_verses_screen.dart';
import 'settings_screen.dart';

// ——— Layout constants ———
const double _outerPadding = 24;
const double _sectionGap = 20;
const double _cardRadius = 22;

/// Premium Home: Hero, Next Prayer, Quick Actions, Daily Verse. Subtle borders, no heavy shadows.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ReadingProgress? _lastRead;
  String? _lastReadSurahNameEn;
  String? _lastReadSurahNameAr;
  int _bookmarkCount = 0;
  PrayerTimesResult? _prayerResult;
  Timer? _prayerTimer;

  @override
  void initState() {
    super.initState();
    _loadLastRead();
    _loadBookmarkCount();
    _loadPrayerTimes();
    _prayerTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updatePrayerCountdown());
  }

  @override
  void dispose() {
    _prayerTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPrayerTimes() async {
    final settings = await SettingsRepository.instance.getPrayerSettings();
    if (!mounted) return;
    final now = DateTime.now();
    final result = PrayerTimesRepository.instance.computeToday(settings, now);
    if (mounted) setState(() => _prayerResult = result);
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

  Future<void> _loadBookmarkCount() async {
    final list = await BookmarkRepository.instance.getBookmarks();
    if (mounted) setState(() => _bookmarkCount = list.length);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: AppTokens.surface,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTokens.bg,
              AppTokens.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: HeroSection(
                  greeting: 'Assalamu alaikum',
                  prayerResult: _prayerResult,
                  onSettingsTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
                    ).then((_) => _loadPrayerTimes());
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -24),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTokens.surface,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(_outerPadding, 28, _outerPadding, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          HomeQuickActionsRow(
                    continueSurahName: _lastReadSurahNameEn,
                    continueAyahNumber: _lastRead?.ayahNumber,
                    onContinueTap: _lastRead != null
                        ? () {
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
                        : null,
                    bookmarkCount: _bookmarkCount,
                    onMyVersesTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(builder: (_) => const MyVersesScreen()),
                      ).then((_) => _loadBookmarkCount());
                    },
                  ),
                          const SizedBox(height: _sectionGap),
                          DailyVerseCard(
                    arabic: 'اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ',
                    german: 'Führe uns auf den geraden Weg.',
                    onExplanationTap: () => showExplanationBottomSheet(
                      context,
                      verseTitle: 'Al-Fatiha, Vers 6',
                    ),
                    onBookmarkTap: () {},
                  ),
                          const SizedBox(height: 48),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }
}

// ——— HeroSection ———
/// Full-width immersive gradient hero: greeting, time, next prayer, date, prayer chips.
class HeroSection extends StatelessWidget {
  const HeroSection({
    super.key,
    required this.greeting,
    this.prayerResult,
    this.dateSubline,
    this.onSettingsTap,
  });

  final String greeting;
  final PrayerTimesResult? prayerResult;
  final String? dateSubline;
  final VoidCallback? onSettingsTap;

  static const double _height = 300;
  static const double _bottomRadius = 30;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final dateStr = dateSubline ?? _formatDate(now);

    final nextPrayerType = prayerResult?.nextPrayerType;
    final nextLabel = nextPrayerType?.label ?? '—';
    final countdownStr = prayerResult != null
        ? PrayerTimesRepository.formatCountdown(prayerResult!.timeUntilNextPrayer)
        : '—:——';

    final heroPhase = DynamicHeroTheme.phaseFromPrayer(nextPrayerType);
    final gradientColors = DynamicHeroTheme.gradientColors(heroPhase);
    final showStars = DynamicHeroTheme.showStars(heroPhase);
    final showMosque = DynamicHeroTheme.showMosque(heroPhase);

    return Container(
      height: _height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradientColors,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(_bottomRadius),
          bottomRight: Radius.circular(_bottomRadius),
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (showMosque)
            Positioned.fill(
              child: CustomPaint(
                painter: MosqueSilhouettePainter(opacity: 0.06),
              ),
            ),
          if (showStars)
            Positioned.fill(
              child: CustomPaint(
                painter: StarParticlesPainter(opacity: 0.2),
              ),
            ),
          Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    greeting,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.6,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                  if (onSettingsTap != null)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onSettingsTap,
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.settings_outlined,
                            size: 22,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                timeStr,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 48,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$nextLabel in $countdownStr',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.95),
                      ),
                    ),
                  ),
                  if (nextPrayerType != null)
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        nextPrayerType.icon,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                dateStr,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: prayerTypeOrder.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final prayerType = prayerTypeOrder[index];
                    final isNext = nextPrayerType == prayerType;
                    final chipTime = prayerResult != null && prayerResult!.timeFor(prayerType) != null
                        ? PrayerTimesRepository.instance.formatTime(prayerResult!.timeFor(prayerType)!)
                        : null;
                    final label = chipTime != null ? '${prayerType.label} $chipTime' : prayerType.label;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isNext
                            ? Colors.white.withOpacity(0.25)
                            : Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: isNext
                            ? Border.all(color: Colors.white.withOpacity(0.4), width: 1)
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            prayerType.icon,
                            size: 16,
                            color: Colors.white.withOpacity(isNext ? 1.0 : 0.8),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            label,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: isNext ? FontWeight.w600 : FontWeight.w500,
                              color: Colors.white.withOpacity(isNext ? 1.0 : 0.8),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun', 'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'];
    return '${d.day}. ${months[d.month - 1]} ${d.year}';
  }
}

// ——— HomeQuickActionsRow ———
/// Two equal premium buttons: Weiterlesen | Meine Verse. Same height, icons, min 48 touch.
class HomeQuickActionsRow extends StatelessWidget {
  const HomeQuickActionsRow({
    super.key,
    this.continueSurahName,
    this.continueAyahNumber,
    this.onContinueTap,
    this.bookmarkCount = 0,
    required this.onMyVersesTap,
  });

  final String? continueSurahName;
  final int? continueAyahNumber;
  final VoidCallback? onContinueTap;
  final int bookmarkCount;
  final VoidCallback onMyVersesTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            icon: Icons.menu_book_rounded,
            title: 'Weiterlesen',
            subtitle: (continueSurahName != null && continueAyahNumber != null)
                ? '$continueSurahName • Vers $continueAyahNumber'
                : 'Fortsetzen',
            onTap: onContinueTap ?? () {},
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.bookmark_border_rounded,
            title: 'Meine Verse',
            subtitle: bookmarkCount > 0 ? '$bookmarkCount gespeichert' : null,
            onTap: onMyVersesTap,
          ),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_cardRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
          constraints: const BoxConstraints(minHeight: 120),
          decoration: BoxDecoration(
            color: AppTokens.surface,
            borderRadius: BorderRadius.circular(_cardRadius),
            border: Border.all(color: AppTokens.primary.withOpacity(0.08), width: 1),
            boxShadow: const [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 26, color: AppTokens.primary),
              const SizedBox(height: 12),
              Text(
                title,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppTokens.textPrimary,
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTokens.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ——— DailyVerseCard ———
/// Tagesvers: title row, Arabic centered, translation, CTA Erklärung + bookmark icon.
class DailyVerseCard extends StatelessWidget {
  const DailyVerseCard({
    super.key,
    required this.arabic,
    required this.german,
    this.onExplanationTap,
    this.onBookmarkTap,
    this.onShareTap,
  });

  final String arabic;
  final String german;
  final VoidCallback? onExplanationTap;
  final VoidCallback? onBookmarkTap;
  final VoidCallback? onShareTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 22),
      decoration: BoxDecoration(
        color: AppTokens.surface,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: AppTokens.primary.withOpacity(0.08), width: 1),
        boxShadow: const [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Tagesvers',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppTokens.textPrimary,
                    ),
                  ),
                  if (onBookmarkTap != null)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onBookmarkTap,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.bookmark_border_rounded,
                            size: 22,
                            color: AppTokens.textMuted.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
          const SizedBox(height: 20),
          Text(
            arabic,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: GoogleFonts.amiri(
              fontSize: 28,
              fontWeight: FontWeight.w500,
              color: AppTokens.textPrimary,
              height: 1.65,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            german,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: AppTokens.textMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          if (onExplanationTap != null)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onExplanationTap,
                borderRadius: BorderRadius.circular(AppTokens.radiusChip),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTokens.primary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(AppTokens.radiusChip),
                    border: Border.all(color: AppTokens.primary.withOpacity(0.2), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.smart_toy_outlined, size: 18, color: AppTokens.primary),
                      const SizedBox(width: 8),
                      Text(
                        'KI-Erklärung',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTokens.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
```

---

### lib/theme/tokens.dart

```dart
import 'package:flutter/material.dart';

/// Design-Tokens: Farben, Radii, Shadows. Sand/Emerald/Gold, keine harten Weiß-Kontraste.
class AppTokens {
  AppTokens._();

  // ——— Colors ———
  static const Color bg = Color(0xFFF3EBDD);
  static const Color surface = Color(0xFFFAF7F2);
  static const Color surfaceVariant = Color(0xFFF5F0E8);
  static const Color primary = Color(0xFF2D5A3D);
  static const Color primaryLight = Color(0xFF3D7A52);
  static const Color accent = Color(0xFFB8860B);
  static const Color accentLight = Color(0xFFD4A84B);
  static const Color divider = Color(0xFFE8E2D8);
  static const Color textPrimary = Color(0xFF2C2C2C);
  static const Color textSecondary = Color(0xFF5C5C5C);
  static const Color textMuted = Color(0xFF787878);

  // ——— Radii ———
  static const double radiusMd = 16;
  static const double radiusLg = 24;
  static const double radiusChip = 14;
  static const double radiusPill = 20;

  // ——— Shadows (weich, feine Borders) ———
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: divider.withOpacity(0.8),
          blurRadius: 1,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get heroShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.07),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get chipGlow => [
        BoxShadow(
          color: primary.withOpacity(0.15),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];
}
```

---

### lib/theme/app_theme.dart

```dart
import 'package:flutter/material.dart';

/// Sand-basierte Premium-Farbpalette
class AppColors {
  AppColors._();

  static const Color sandBg = Color(0xFFF3EBDD);
  static const Color sandLight = Color(0xFFFAF7F0);
  static const Color sandDark = Color(0xFFE8E0D0);
  static const Color accent = Color(0xFF2D5A3D);
  static const Color accentLight = Color(0xFF3D7A52);
  static const Color gold = Color(0xFFB8860B);
  static const Color goldLight = Color(0xFFD4A84B);
  static const Color textPrimary = Color(0xFF2C2C2C);
  static const Color textSecondary = Color(0xFF5C5C5C);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color chipBg = Color(0xFFF0EBE3);
  static const Color cardBorder = Color(0xFFE8E2D8);
}

/// Sehr subtiler Gradient (low opacity) für Hintergründe
class AppGradients {
  AppGradients._();

  static BoxDecoration get subtleBackground => BoxDecoration(
        color: AppColors.sandBg,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.sandBg,
            AppColors.sandBg.withOpacity(0.98),
            AppColors.sandLight.withOpacity(0.3),
          ],
        ),
      );

  static BoxDecoration get subtleRadial => BoxDecoration(
        color: AppColors.sandBg,
        gradient: RadialGradient(
          center: Alignment.topRight,
          radius: 1.2,
          colors: [
            AppColors.goldLight.withOpacity(0.06),
            AppColors.sandBg,
          ],
        ),
      );
}
```

---

### lib/theme/hero_theme.dart

```dart
import 'package:flutter/material.dart';

import '../prayer/prayer_type.dart';
import 'tokens.dart';

/// Maps prayer phase / time-of-day to hero visuals. Lightweight: gradients + optional overlay.
enum HeroPhase {
  night,   // Isha, pre-Fajr (imsak) — dark, stars
  fajr,    // Fajr / early morning
  day,     // Sunrise, Dhuhr, Asr — bright
  maghrib, // Maghrib / dusk
}

/// Dynamic hero theme: gradient + show mosque silhouette + show stars (night only).
class DynamicHeroTheme {
  DynamicHeroTheme._();

  static HeroPhase phaseFromPrayer(PrayerType? next) {
    if (next == null) return HeroPhase.day;
    switch (next) {
      case PrayerType.imsak:
      case PrayerType.fajr:
        return HeroPhase.fajr;
      case PrayerType.sunrise:
      case PrayerType.dhuhr:
      case PrayerType.asr:
        return HeroPhase.day;
      case PrayerType.maghrib:
        return HeroPhase.maghrib;
      case PrayerType.isha:
        return HeroPhase.night;
    }
  }

  /// Top-to-bottom gradient colors for the hero area.
  static List<Color> gradientColors(HeroPhase phase) {
    switch (phase) {
      case HeroPhase.night:
        return [
          const Color(0xFF0D1B12),
          const Color(0xFF1A3326),
          AppTokens.primary.withOpacity(0.85),
        ];
      case HeroPhase.fajr:
        return [
          const Color(0xFF1A2E22),
          const Color(0xFF243D2E),
          AppTokens.primary,
          AppTokens.primaryLight.withOpacity(0.9),
        ];
      case HeroPhase.day:
        return [
          const Color(0xFF1A3326),
          AppTokens.primary,
          AppTokens.primaryLight.withOpacity(0.9),
        ];
      case HeroPhase.maghrib:
        return [
          const Color(0xFF2D2318),
          const Color(0xFF2A3D2A),
          AppTokens.primary.withOpacity(0.95),
          AppTokens.primaryLight.withOpacity(0.85),
        ];
    }
  }

  static bool showStars(HeroPhase phase) => phase == HeroPhase.night;
  static bool showMosque(HeroPhase phase) => true;
}

/// Simple mosque silhouette via CustomPainter (no asset). Subtle, bottom of hero.
class MosqueSilhouettePainter extends CustomPainter {
  MosqueSilhouettePainter({this.opacity = 0.08});

  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    final path = Path();

    final baseY = h * 0.75;
    final domeCenter = w * 0.5;
    final domeRadius = w * 0.22;
    path.moveTo(domeCenter - domeRadius, baseY);
    path.quadraticBezierTo(domeCenter - domeRadius, baseY - domeRadius * 1.6, domeCenter, baseY - domeRadius * 1.2);
    path.quadraticBezierTo(domeCenter + domeRadius, baseY - domeRadius * 1.6, domeCenter + domeRadius, baseY);
    path.lineTo(w * 0.85, baseY);
    path.lineTo(w * 0.85, h);
    path.lineTo(w * 0.15, h);
    path.lineTo(w * 0.15, baseY);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Very subtle star dots for night phase. Few circles, low opacity.
class StarParticlesPainter extends CustomPainter {
  StarParticlesPainter({this.opacity = 0.25});

  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    final random = _SeededRandom(42);
    for (var i = 0; i < 24; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height * 0.6;
      final r = 1.0 + random.nextDouble() * 1.2;
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SeededRandom {
  _SeededRandom(this._seed);
  int _seed;

  double nextDouble() {
    _seed = (_seed * 1103515245 + 12345) & 0x7FFFFFFF;
    return _seed / 0x7FFFFFFF;
  }
}
```

---

### lib/main.dart (ThemeData)

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'debug/db_diagnostics.dart';
import 'theme/app_theme.dart';
import 'screens/bootstrap_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) {
    await runDbDiagnostics();
  }
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.sandBg,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const IhdinaApp());
}

class IhdinaApp extends StatelessWidget {
  const IhdinaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ihdina',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accent,
          primary: AppColors.accent,
          surface: AppColors.sandBg,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const BootstrapScreen(),
    );
  }
}
```

---

### lib/data/prayer/prayer_times_repository.dart

```dart
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

  /// Get CalculationParameters for the given method and madhab.
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
    params.madhab = settings.madhab == MadhabOption.hanafi ? Madhab.hanafi : Madhab.shafi;
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
    return params;
  }

  /// Compute prayer times for the given date using settings. Returns times in local timezone.
  PrayerTimesResult computeToday(PrayerSettings settings, DateTime now) {
    if (kDebugMode) {
      print('[PRAYER] using lat=${settings.latitude} lng=${settings.longitude} label=${settings.locationLabel}');
    }
    final coordinates = Coordinates(settings.latitude, settings.longitude);
    final params = _paramsFromSettings(settings);
    final date = DateTime(now.year, now.month, now.day);

    final pt = PrayerTimes(
      date: date,
      coordinates: coordinates,
      calculationParameters: params,
      precision: true,
    );

    final fajr = _toLocal(pt.fajr);
    final sunrise = _toLocal(pt.sunrise);
    final dhuhr = _toLocal(pt.dhuhr);
    final asr = _toLocal(pt.asr);
    final maghrib = _toLocal(pt.maghrib);
    final isha = _toLocal(pt.isha);
    final fajrAfter = _toLocal(pt.fajrAfter);
    final imsak = fajr.subtract(const Duration(minutes: 10));

    final times = <PrayerType, DateTime>{
      PrayerType.imsak: imsak,
      PrayerType.fajr: fajr,
      PrayerType.sunrise: sunrise,
      PrayerType.dhuhr: dhuhr,
      PrayerType.asr: asr,
      PrayerType.maghrib: maghrib,
      PrayerType.isha: isha,
    };

    PrayerType nextPrayerType = PrayerType.fajr;
    DateTime nextPrayerTime = fajrAfter;

    for (final type in prayerTypeOrder) {
      final t = times[type]!;
      if (now.isBefore(t)) {
        nextPrayerType = type;
        nextPrayerTime = t;
        break;
      }
    }
    if (now.isAfter(isha)) {
      nextPrayerType = PrayerType.fajr;
      nextPrayerTime = fajrAfter;
    }

    final timeUntilNextPrayer = nextPrayerTime.difference(now);

    if (kDebugMode) {
      debugPrint(
        '[PRAYER] lat=${settings.latitude}, lng=${settings.longitude}, '
        'method=${settings.method.value}, madhab=${settings.madhab.name}',
      );
      for (final type in prayerTypeOrder) {
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
```

---

**End of context dump.**
