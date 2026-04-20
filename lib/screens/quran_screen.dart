import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/quran/quran_repository.dart';
import '../data/bookmarks/bookmark_repository.dart';
import '../data/reading/reading_progress.dart';
import '../data/reading/reading_progress_repository.dart';
import '../data/prayer/prayer_models.dart';
import '../data/prayer/prayer_times_repository.dart';
import '../data/settings/settings_repository.dart';
import '../theme/app_theme.dart';
import '../theme/hero_theme.dart';
import '../widgets/quran_continue_reading_card.dart';
import '../models/surah.dart';
import 'quran_reader_screen.dart';
import 'my_verses_screen.dart';
import 'search_screen.dart';

/// Koran-Tab: Surenliste from QuranRepository. Tap → Reader. Search via "Suche" → SearchScreen.
class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

/// Champagne-gold accent for number indicator (matches dashboard).
const Color _accentChampagneGold = Color(0xFFE5C07B);

class _QuranScreenState extends State<QuranScreen> {
  static const double _outerPadding = 24;
  static const double _sectionGap = 16;

  List<Surah>? _surahs;
  Object? _error;
  Map<int, int> _bookmarkCounts = {};
  PrayerTimesResult? _prayerResult;
  ReadingProgress? _lastRead;

  @override
  void initState() {
    super.initState();
    _load();
    _loadPrayerTimes();
  }

  Future<void> _loadPrayerTimes() async {
    final settings = await SettingsRepository.instance.getPrayerSettings();
    if (!mounted) return;
    final now = DateTime.now();
    final result = PrayerTimesRepository.instance.computeToday(settings, now);
    if (mounted) setState(() => _prayerResult = result);
  }

  Future<void> _load() async {
    try {
      final bookmarkRepo = BookmarkRepository.instance;
      final results = await Future.wait([
        QuranRepository.instance.getAllSurahs(),
        bookmarkRepo.getBookmarkCountsPerSurah(),
        ReadingProgressRepository.instance.getLastRead(),
      ]);
      final rows = results[0] as List;
      final counts = results[1] as Map<int, int>;
      final progress = results[2] as ReadingProgress?;
      if (mounted) {
        final surahs = rows
            .map((r) => Surah(
                  number: r.id,
                  nameDe: r.nameEn,
                  nameAr: r.nameAr,
                  verses: const [],
                ))
            .toList();
        setState(() {
          _surahs = surahs;
          _bookmarkCounts = counts;
          _lastRead = progress;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _surahs = null;
          _error = e;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(_outerPadding, 20, _outerPadding, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Koran',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          shadows: const [
                            Shadow(color: Colors.black45, blurRadius: 4),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                            child: IconButton(
                              icon: Icon(
                                Icons.search_rounded,
                                size: 26,
                                color: Colors.white,
                              ),
                              tooltip: 'Suche',
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute<void>(builder: (_) => const SearchScreen()),
                              ),
                              style: IconButton.styleFrom(
                                minimumSize: const Size(52, 52),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.bookmark_border_rounded,
                              size: 24,
                              color: Colors.white,
                            ),
                            tooltip: 'Sammlung',
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(builder: (_) => const MyVersesScreen()),
                            ),
                            style: IconButton.styleFrom(
                              minimumSize: const Size(48, 48),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: _sectionGap),
                Expanded(
                  child: _buildList(),
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

  Widget _buildList() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Fehler beim Laden.',
            style: GoogleFonts.inter(color: Colors.white70),
          ),
        ),
      );
    }
    if (_surahs == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white70),
      );
    }
    final list = _surahs!;
    if (list.isEmpty) {
      return Center(
        child: Text(
          'Keine Suren.',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
      );
    }
    Surah? continueSurah;
    if (_lastRead != null) {
      final m = list.where((s) => s.number == _lastRead!.surahId);
      continueSurah = m.isEmpty ? null : m.first;
    }
    final hasContinue = continueSurah != null;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(_outerPadding, 0, _outerPadding, 150),
      itemCount: (hasContinue ? 1 : 0) + list.length,
      itemBuilder: (context, index) {
        if (hasContinue && index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: _sectionGap + 4),
            child: QuranContinueReadingCard(
              surahName: continueSurah!.nameDe,
              ayahNumber: _lastRead!.ayahNumber,
              onTap: () => _openReader(continueSurah!, initialAyah: _lastRead!.ayahNumber),
            ),
          );
        }
        final surahIndex = hasContinue ? index - 1 : index;
        final surah = list[surahIndex];
        final lastOpenId = _lastRead?.surahId;
        final bookmarkCount = _bookmarkCounts[surah.number] ?? 0;
        final isLastOpened = lastOpenId == surah.number;
        final hasBookmarksOnly = bookmarkCount > 0 && !isLastOpened;

        return Padding(
          padding: const EdgeInsets.only(bottom: _sectionGap),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _openReader(surah),
              borderRadius: BorderRadius.circular(22),
              child: Container(
                decoration: BoxDecoration(
                  color: isLastOpened
                      ? Colors.white.withOpacity(0.07)
                      : hasBookmarksOnly
                          ? Colors.white.withOpacity(0.04)
                          : Colors.black.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isLastOpened
                        ? _accentChampagneGold.withOpacity(0.22)
                        : hasBookmarksOnly
                            ? Colors.white.withOpacity(0.13)
                            : Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                  boxShadow: isLastOpened
                      ? [
                          BoxShadow(
                            color: _accentChampagneGold.withOpacity(0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(0.25),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '${surah.number}',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _accentChampagneGold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              surah.nameDe,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              surah.nameAr,
                              textDirection: TextDirection.rtl,
                              style: GoogleFonts.amiri(
                                fontSize: 20,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_bookmarkCounts.containsKey(surah.number))
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.bookmark_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                              if ((_bookmarkCounts[surah.number] ?? 0) > 1) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${_bookmarkCounts[surah.number]}',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      Icon(Icons.chevron_right_rounded, color: Colors.white54, size: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _openReader(Surah surah, {int? initialAyah}) {
    Navigator.of(context)
        .push(
      MaterialPageRoute<void>(
        builder: (context) => QuranReaderScreen(
          surah: surah,
          initialAyahNumber: initialAyah,
        ),
      ),
    )
        .then((_) {
      if (mounted) _load();
    });
  }
}
