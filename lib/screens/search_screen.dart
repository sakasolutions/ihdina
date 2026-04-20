import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/quran/quran_repository.dart';
import '../data/quran/translation_service.dart';
import '../data/quran/models/surah_model.dart';
import '../data/bookmarks/bookmark_repository.dart';
import '../data/search/search_result.dart';
import '../data/settings/settings_repository.dart';
import '../data/prayer/prayer_models.dart';
import '../data/prayer/prayer_times_repository.dart';
import '../theme/app_theme.dart';
import '../theme/hero_theme.dart';
import '../widgets/glass_card.dart';
import '../models/surah.dart';
import 'quran_reader_screen.dart';

const Color _accentChampagneGold = Color(0xFFE5C07B);

/// Filters surahs by query: number, name_en (case-insensitive), name_ar (contains).
List<Surah> filterSurahs(List<Surah> surahs, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return surahs;
  final digitOnly = q.replaceAll(RegExp(r'[^0-9]'), '');
  return surahs.where((s) {
    if (digitOnly.isNotEmpty && '${s.number}'.contains(digitOnly)) return true;
    if (s.nameDe.toLowerCase().contains(q)) return true;
    if (s.nameAr.contains(query.trim())) return true;
    return false;
  }).toList();
}

/// Unified search: segment "Suren" (filter list) or "Verse" (global ayah search).
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const double _outerPadding = 24;
  static const double _sectionGap = 16;
  static const int _verseDebounceMs = 300;

  int _segmentIndex = 0; // 0 = Suren, 1 = Verse
  final TextEditingController _controller = TextEditingController();
  List<Surah>? _surahs;
  Map<int, int> _bookmarkCounts = {};
  List<SearchResult> _verseResults = [];
  bool _verseLoading = false;
  Timer? _debounce;
  double _arabicFontSize = 28;
  double _arabicLineHeight = 1.8;
  PrayerTimesResult? _prayerResult;

  @override
  void initState() {
    super.initState();
    _loadSurahs();
    _loadSettings();
    _loadPrayerTimes();
  }

  Future<void> _loadPrayerTimes() async {
    final settings = await SettingsRepository.instance.getPrayerSettings();
    if (!mounted) return;
    final now = DateTime.now();
    final result = PrayerTimesRepository.instance.computeToday(settings, now);
    if (mounted) setState(() => _prayerResult = result);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadSurahs() async {
    try {
      final results = await Future.wait([
        QuranRepository.instance.getAllSurahs(),
        BookmarkRepository.instance.getBookmarkCountsPerSurah(),
      ]);
      final rows = results[0] as List<SurahModel>;
      final counts = results[1] as Map<int, int>;
      if (mounted) {
        setState(() {
          _surahs = rows
              .map((r) => Surah(
                    number: r.id,
                    nameDe: r.nameEn,
                    nameAr: r.nameAr,
                    verses: const [],
                  ))
              .toList();
          _bookmarkCounts = counts;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _surahs = []);
    }
  }

  Future<void> _loadSettings() async {
    final repo = SettingsRepository.instance;
    final results = await Future.wait([
      repo.getArabicFontSize(),
      repo.getArabicLineHeight(),
    ]);
    if (mounted) {
      setState(() {
        _arabicFontSize = results[0] as double;
        _arabicLineHeight = results[1] as double;
      });
    }
  }

  void _onQueryChanged(String text) {
    if (_segmentIndex == 0) {
      setState(() {});
      return;
    }
    _debounce?.cancel();
    if (text.trim().length < 2) {
      setState(() {
        _verseResults = [];
        _verseLoading = false;
      });
      return;
    }
    setState(() => _verseLoading = true);
    final query = text.trim();
    _debounce = Timer(const Duration(milliseconds: _verseDebounceMs), () async {
      final list = await _searchVersesOffline(query, limit: 50);
      if (mounted) {
        setState(() {
          _verseResults = list;
          _verseLoading = false;
        });
      }
    });
  }

  /// Offline verse search: Arabic + German. Iterates surahs/ayahs and uses TranslationService.
  Future<List<SearchResult>> _searchVersesOffline(String query, {int limit = 50}) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];
    await TranslationService.instance.ensureLoaded();
    final surahs = await QuranRepository.instance.getAllSurahs();
    final results = <SearchResult>[];
    for (final sm in surahs) {
      if (results.length >= limit) break;
      final ayahs = await QuranRepository.instance.getAyahsBySurahId(sm.id);
      for (final ayah in ayahs) {
        if (results.length >= limit) break;
        final textAr = ayah.textAr;
        final textDe = TranslationService.instance.getTranslation(sm.id, ayah.ayahNumber);
        final matchAr = textAr.toLowerCase().contains(q);
        final matchDe = textDe.isNotEmpty && textDe.toLowerCase().contains(q);
        if (matchAr || matchDe) {
          results.add(SearchResult(
            surahId: sm.id,
            ayahNumber: ayah.ayahNumber,
            surahNameEn: sm.nameEn,
            surahNameAr: sm.nameAr,
            textAr: textAr,
            textDe: textDe.isNotEmpty ? textDe : null,
          ));
        }
      }
    }
    return results;
  }

  List<Surah> get _filteredSurahs {
    final list = _surahs;
    if (list == null) return [];
    return filterSurahs(list, _controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final heroPhase = DynamicHeroTheme.phaseFromPrayer(_prayerResult?.nextPrayerType);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Suche',
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(_outerPadding, 16, _outerPadding, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _SegmentButton(
                          label: 'Suren',
                          selected: _segmentIndex == 0,
                          onTap: () => setState(() => _segmentIndex = 0),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _SegmentButton(
                          label: 'Verse',
                          selected: _segmentIndex == 1,
                          onTap: () => setState(() => _segmentIndex = 1),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(_outerPadding, 16, _outerPadding, 0),
                  child: TextField(
                    controller: _controller,
                    onChanged: _onQueryChanged,
                    decoration: InputDecoration(
                      hintText: _segmentIndex == 0 ? 'Sure suchen' : 'Vers oder Stichwort suchen...',
                      hintStyle: GoogleFonts.inter(fontSize: 15, color: Colors.white70),
                      prefixIcon: const Icon(Icons.search_rounded, size: 22, color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.15),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    style: GoogleFonts.inter(fontSize: 15, color: Colors.white),
                  ),
                ),
                const SizedBox(height: _sectionGap),
                Expanded(
                  child: _segmentIndex == 0 ? _buildSurenList() : _buildVerseList(),
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

  Widget _buildSurenList() {
    if (_surahs == null) {
      return const Center(child: CircularProgressIndicator(color: Colors.white70));
    }
    final list = _filteredSurahs;
    if (list.isEmpty) {
      return Center(
        child: Text(
          _controller.text.trim().isEmpty ? 'Keine Suren.' : 'Keine Treffer für „${_controller.text.trim()}".',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(_outerPadding, 0, _outerPadding, 130),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final surah = list[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: _sectionGap),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => QuranReaderScreen(surah: surah),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(22),
              child: GlassCard(
                borderRadius: 22,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.25),
              borderRadius: BorderRadius.circular(12),
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
                            color: Colors.white,
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
                        const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Icon(Icons.bookmark_rounded, size: 18, color: Colors.white),
                        ),
                      const Icon(Icons.chevron_right_rounded, color: Colors.white70, size: 24),
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

  Widget _buildVerseList() {
    if (_verseLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white70));
    }
    final q = _controller.text.trim();
    if (q.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Tippe, um Verse zu suchen.',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
          ),
        ),
      );
    }
    if (q.length < 2) {
      return Center(
        child: Text(
          'Mindestens 2 Zeichen eingeben.',
          style: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
        ),
      );
    }
    if (_verseResults.isEmpty) {
      return Center(
        child: Text(
          'Keine Treffer.',
          style: GoogleFonts.inter(fontSize: 16, color: Colors.white70),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(_outerPadding, 0, _outerPadding, 130),
      itemCount: _verseResults.length,
      itemBuilder: (context, index) {
        final r = _verseResults[index];
        return _VerseResultTile(
          result: r,
          arabicFontSize: _arabicFontSize,
          arabicLineHeight: _arabicLineHeight,
          onTap: () {
            final surah = Surah(
              number: r.surahId,
              nameDe: r.surahNameEn,
              nameAr: r.surahNameAr,
              verses: const [],
            );
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => QuranReaderScreen(
                  surah: surah,
                  initialAyahNumber: r.ayahNumber,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.25),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? Colors.white : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }
}

class _VerseResultTile extends StatelessWidget {
  const _VerseResultTile({
    required this.result,
    required this.arabicFontSize,
    required this.arabicLineHeight,
    required this.onTap,
  });

  final SearchResult result;
  final double arabicFontSize;
  final double arabicLineHeight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.25),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${result.surahNameEn} • Vers ${result.ayahNumber}',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _accentChampagneGold,
                  ),
                ),
                const SizedBox(height: 10),
                if (result.textDe != null && result.textDe!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      result.textDe!,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        height: 1.45,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    result.textAr,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.amiri(
                      fontSize: arabicFontSize,
                      height: arabicLineHeight,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: Icon(Icons.chevron_right_rounded, color: Colors.white54, size: 22),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
