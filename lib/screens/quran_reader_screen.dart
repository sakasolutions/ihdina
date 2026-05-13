import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/quran/quran_repository.dart';
import '../data/quran/surah_intro_repository.dart';
import '../data/quran/translation_service.dart';
import '../data/quran/models/ayah_model.dart';
import '../data/bookmarks/bookmark_repository.dart';
import '../data/reading/reading_progress_repository.dart';
import '../data/settings/settings_repository.dart';
import '../data/prayer/prayer_models.dart';
import '../data/prayer/prayer_times_repository.dart';
import '../theme/app_theme.dart';
import '../theme/hero_theme.dart';
import '../widgets/quran_verse_reader_tile.dart';
import '../widgets/surah_intro_bottom_sheet.dart';
import '../models/surah.dart';
import '../models/verse.dart';
import '../services/audio_service.dart';
import 'explanation_bottom_sheet.dart';

/// Reader: ayahs from QuranRepository only. Bookmark toggle per verse.
/// [initialAyahNumber] selects the initial page in the verse [PageView].
class QuranReaderScreen extends StatefulWidget {
  const QuranReaderScreen({super.key, required this.surah, this.initialAyahNumber});

  final Surah surah;
  final int? initialAyahNumber;

  @override
  State<QuranReaderScreen> createState() => _QuranReaderScreenState();
}

class _QuranReaderScreenState extends State<QuranReaderScreen> {
  List<Verse>? _verses;
  Set<int> _bookmarkedAyahNumbers = {};
  PageController? _pageController;
  int _currentVerseIndex = 0;
  bool _showSwipeHint = true;
  double _arabicFontSize = 28;
  double _arabicLineHeight = 1.8;
  PrayerTimesResult? _prayerResult;
  /// When true, show Latin transliteration instead of German translation in verse tiles.
  bool _showTransliteration = false;

  Timer? _debounceArabicFont;
  Timer? _debounceArabicLine;
  Timer? _jumpHighlightTimer;

  /// Zeigt nach „Zu Vers springen“ kurz den gleichen Rahmen wie bei aktivem Audio (nur visuell).
  int? _jumpHighlightAyah;

  static const int _arabicTypographyDebounceMs = 150;
  static const Duration _jumpHighlightDuration = Duration(seconds: 2);

  int? get _playingAyahNumber {
    final s = AudioService.instance.state.value;
    return s.surahId == widget.surah.number ? s.ayahNumber : null;
  }

  int? get _loadingAyahNumber {
    final s = AudioService.instance.state.value;
    return s.isLoading && s.surahId == widget.surah.number ? s.ayahNumber : null;
  }

  void _onPlayVerse(int ayahNumber) {
    final s = AudioService.instance.state.value;
    if (s.surahId == widget.surah.number && s.ayahNumber == ayahNumber && (s.isPlaying || s.isLoading)) {
      AudioService.instance.stop();
    } else {
      AudioService.instance.playVerse(widget.surah.number, ayahNumber);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
    _loadPrayerTimes();
    AudioService.instance.state.addListener(_onAudioStateChanged);
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showSwipeHint = false);
    });
  }

  @override
  void dispose() {
    _debounceArabicFont?.cancel();
    _debounceArabicLine?.cancel();
    _jumpHighlightTimer?.cancel();
    _pageController?.dispose();
    AudioService.instance.state.removeListener(_onAudioStateChanged);
    super.dispose();
  }

  /// Gleiche Persistenz wie zuvor in [SettingsScreen] (150 ms Debounce pro Kanal).
  void _applyArabicFontSizeLive(double v) {
    setState(() => _arabicFontSize = v);
    _debounceArabicFont?.cancel();
    _debounceArabicFont = Timer(
      const Duration(milliseconds: _arabicTypographyDebounceMs),
      () => SettingsRepository.instance.setArabicFontSize(v),
    );
  }

  void _applyArabicLineHeightLive(double v) {
    setState(() => _arabicLineHeight = v);
    _debounceArabicLine?.cancel();
    _debounceArabicLine = Timer(
      const Duration(milliseconds: _arabicTypographyDebounceMs),
      () => SettingsRepository.instance.setArabicLineHeight(v),
    );
  }

  void _showReaderTypographyBottomSheet() {
    double sheetFont = _arabicFontSize;
    double sheetLineHeight = _arabicLineHeight;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.45),
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.paddingOf(ctx).bottom + 16,
          ),
          child: StatefulBuilder(
            builder: (ctx, setModal) {
              final sliderTheme = SliderTheme.of(ctx).copyWith(
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.white.withOpacity(0.2),
                thumbColor: Colors.white,
                overlayColor: Colors.white.withOpacity(0.2),
              );
              return Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.emeraldDark.withOpacity(0.97),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.35),
                        blurRadius: 24,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.22),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Lesen im Koran',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Arabische Schriftgröße und Zeilenabstand',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          height: 1.35,
                          color: Colors.white.withOpacity(0.55),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Arabische Schriftgröße',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.72),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SliderTheme(
                        data: sliderTheme,
                        child: Slider(
                          value: sheetFont.clamp(20, 40),
                          min: 20,
                          max: 40,
                          divisions: 20,
                          onChanged: (v) {
                            sheetFont = v;
                            setModal(() {});
                            _applyArabicFontSizeLive(v);
                          },
                        ),
                      ),
                      Text(
                        '${sheetFont.clamp(20, 40).toInt()}',
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.white60),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Zeilenabstand (Arabisch)',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.72),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SliderTheme(
                        data: sliderTheme,
                        child: Slider(
                          value: sheetLineHeight.clamp(1.2, 2.4),
                          min: 1.2,
                          max: 2.4,
                          divisions: 12,
                          onChanged: (v) {
                            sheetLineHeight = v;
                            setModal(() {});
                            _applyArabicLineHeightLive(v);
                          },
                        ),
                      ),
                      Text(
                        sheetLineHeight.clamp(1.2, 2.4).toStringAsFixed(1),
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.white60),
                      ),
                      const SizedBox(height: 14),
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: Text(
                          'اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.amiri(
                            fontSize: sheetFont.clamp(20, 40),
                            height: sheetLineHeight.clamp(1.2, 2.4),
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showReaderToolsSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.45),
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.paddingOf(sheetContext).bottom + 16,
          ),
          child: StatefulBuilder(
            builder: (ctx, setModal) {
              final verses = _verses;
              return Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.emeraldDark.withOpacity(0.97),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.35),
                        blurRadius: 24,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(8, 14, 8, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.22),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
                        child: Text(
                          'Lesen & Darstellung',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 19,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      ListTile(
                        enabled: verses != null,
                        leading: Icon(
                          Icons.format_list_numbered_rounded,
                          color: verses != null ? Colors.white70 : Colors.white30,
                        ),
                        title: Text(
                          'Zu Vers springen',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: verses != null ? Colors.white : Colors.white38,
                          ),
                        ),
                        onTap: verses == null
                            ? null
                            : () {
                                Navigator.pop(sheetContext);
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (mounted) _showJumpToVerseDialog();
                                });
                              },
                      ),
                      ListTile(
                        leading: Icon(Icons.info_outline_rounded, color: Colors.white.withOpacity(0.7)),
                        title: Text(
                          'Einordnung vor dem Lesen',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        subtitle: Text(
                          'Kurzer Orientierungstext zur Sure – kein Tafsir',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            height: 1.35,
                            color: Colors.white.withOpacity(0.55),
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(sheetContext);
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) _openSurahIntroManual();
                          });
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.format_size_rounded, color: Colors.white.withOpacity(0.7)),
                        title: Text(
                          'Arabische Schrift & Zeilenabstand',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(sheetContext);
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) _showReaderTypographyBottomSheet();
                          });
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                        child: Divider(height: 1, color: Colors.white.withOpacity(0.12)),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                        child: Text(
                          'Unter dem Vers anzeigen',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.55),
                          ),
                        ),
                      ),
                      Center(
                        child: _TransliterationToggle(
                          showTransliteration: _showTransliteration,
                          onChanged: (value) {
                            setState(() => _showTransliteration = value);
                            setModal(() {});
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  List<Widget> _buildCompactReaderAppBarActions() {
    return [
      Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Tooltip(
          message: 'Lesen & Darstellung',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _showReaderToolsSheet,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.more_vert_rounded,
                  size: 22,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ),
          ),
        ),
      ),
    ];
  }

  void _onAudioStateChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadPrayerTimes() async {
    final settings = await SettingsRepository.instance.getPrayerSettings();
    if (!mounted) return;
    final now = DateTime.now();
    final result = PrayerTimesRepository.instance.computeToday(settings, now);
    if (mounted) setState(() => _prayerResult = result);
  }

  Future<void> _load() async {
    final surahId = widget.surah.number;
    final repo = QuranRepository.instance;
    final bookmarkRepo = BookmarkRepository.instance;
    final settingsRepo = SettingsRepository.instance;
    final results = await Future.wait([
      repo.getAyahsBySurahId(surahId),
      bookmarkRepo.getBookmarkedAyahNumbersForSurah(surahId),
      settingsRepo.getArabicFontSize(),
      settingsRepo.getArabicLineHeight(),
      TranslationService.instance.ensureLoaded(),
    ]);
    final ayahs = results[0] as List<AyahModel>;
    final bookmarked = results[1] as Set<int>;
    final fontSize = results[2] as double;
    final lineHeight = results[3] as double;
    if (!mounted) return;
    final translation = TranslationService.instance;
    final verses = ayahs
        .map((a) => Verse(
              ayah: a.ayahNumber,
              ar: a.textAr,
              de: translation.getTranslation(surahId, a.ayahNumber),
              transliteration: a.textTranslit?.isNotEmpty == true ? a.textTranslit : null,
            ))
        .toList();
    final initialListIndex = verses.indexWhere((v) => v.ayah == widget.initialAyahNumber);
    final initialIndex = verses.isEmpty
        ? 0
        : (initialListIndex < 0
            ? 0
            : initialListIndex.clamp(0, verses.length - 1));
    _pageController?.dispose();
    _pageController = PageController(initialPage: initialIndex);
    setState(() {
      _verses = verses;
      _bookmarkedAyahNumbers = bookmarked;
      _arabicFontSize = fontSize;
      _arabicLineHeight = lineHeight;
      _currentVerseIndex = initialIndex;
    });
    await ReadingProgressRepository.instance.setLastRead(
      surahId: surahId,
      ayahNumber: widget.initialAyahNumber ?? 1,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryAutoShowSurahIntro());
  }

  /// Einmal pro Sure automatisch, wenn Text vorliegt und Nutzer das nicht deaktiviert hat.
  Future<void> _tryAutoShowSurahIntro() async {
    final id = widget.surah.number;
    final body = await SurahIntroRepository.instance.getIntroDe(id);
    if (!mounted || body == null) return;
    final auto = await SettingsRepository.instance.getSurahIntroAutoShow();
    if (!auto) return;
    final shown = await SettingsRepository.instance.getSurahIntroAutoShownSurahIds();
    if (shown.contains(id)) return;
    if (!mounted) return;

    await showSurahIntroBottomSheet(
      context,
      surahNameDe: widget.surah.nameDe,
      bodyDe: body,
      showAutoOptOut: true,
      onClose: ({required bool disableAutoShow}) async {
        if (disableAutoShow) {
          await SettingsRepository.instance.setSurahIntroAutoShow(false);
        }
      },
    );
    if (!mounted) return;
    await SettingsRepository.instance.addSurahIntroAutoShownSurahId(id);
  }

  Future<void> _openSurahIntroManual() async {
    final body = await SurahIntroRepository.instance.getIntroDe(widget.surah.number);
    if (!mounted) return;
    if (body == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Für „${widget.surah.nameDe}“ liegt noch keine Kurz-Einführung vor.',
            style: GoogleFonts.inter(),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (!mounted) return;
    await showSurahIntroBottomSheet(
      context,
      surahNameDe: widget.surah.nameDe,
      bodyDe: body,
      showAutoOptOut: false,
    );
  }

  void _onVerseTap(int index, Verse verse) {
    ReadingProgressRepository.instance.setLastRead(
      surahId: widget.surah.number,
      ayahNumber: verse.ayah,
    );
    showAiExplanationWithQuotaCheck(
      context,
      verseTitle: '${widget.surah.nameDe}, Vers ${verse.ayah}',
      surahName: widget.surah.nameDe,
      ayahNumber: verse.ayah,
      textAr: verse.ar,
      textDe: verse.de,
      isFreeDailyVerse: false,
      showVerseHeader: false,
    );
  }

  void _startJumpHighlight(int ayahNumber) {
    _jumpHighlightTimer?.cancel();
    if (!mounted) return;
    setState(() => _jumpHighlightAyah = ayahNumber);
    _jumpHighlightTimer = Timer(_jumpHighlightDuration, () {
      if (!mounted) return;
      setState(() => _jumpHighlightAyah = null);
    });
  }

  Future<void> _toggleBookmark(int ayahNumber) async {
    final surahId = widget.surah.number;
    final repo = BookmarkRepository.instance;
    final wasBookmarked = _bookmarkedAyahNumbers.contains(ayahNumber);
    if (wasBookmarked) {
      await repo.removeBookmark(surahId, ayahNumber);
      if (mounted) setState(() => _bookmarkedAyahNumbers = _bookmarkedAyahNumbers..remove(ayahNumber));
    } else {
      await repo.addBookmark(surahId, ayahNumber);
      if (mounted) setState(() => _bookmarkedAyahNumbers = _bookmarkedAyahNumbers..add(ayahNumber));
    }
    if (!mounted) return;
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          wasBookmarked ? 'Aus Sammlung entfernt' : 'Zur Sammlung hinzugefügt',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showJumpToVerseDialog() async {
    final verses = _verses;
    if (verses == null || _pageController == null || !mounted) return;

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) {
        final tc = TextEditingController();
        String? error;
        return Dialog(
          backgroundColor: AppColors.emeraldDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          child: StatefulBuilder(
            builder: (context, setStateDialog) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Zu Vers springen',
                      style: GoogleFonts.playfairDisplay(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: tc,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: '1 – ${verses.length}',
                              hintStyle: const TextStyle(color: Colors.white38),
                              enabledBorder: OutlineInputBorder(
                                borderSide: const BorderSide(color: Colors.white24),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(color: Color(0xFFE5C07B)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          if (error != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              error!,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text(
                            'Abbrechen',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            final n = int.tryParse(tc.text.trim());
                            if (n == null || n < 1 || n > verses.length) {
                              setStateDialog(
                                () => error =
                                    'Bitte 1 – ${verses.length} eingeben',
                              );
                              return;
                            }
                            Navigator.pop(ctx);
                            Future.microtask(() async {
                              await _pageController!.animateToPage(
                                n - 1,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                              if (mounted) _startJumpHighlight(n);
                            });
                          },
                          child: const Text(
                            'Springen',
                            style: TextStyle(
                              color: Color(0xFFE5C07B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final surah = widget.surah;
    final verses = _verses;
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              surah.nameDe,
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                shadows: const [Shadow(color: Colors.black45, blurRadius: 4)],
              ),
            ),
            Text(
              surah.nameAr,
              textDirection: TextDirection.rtl,
              style: GoogleFonts.amiri(
                fontSize: 16,
                color: Colors.white,
                shadows: const [Shadow(color: Colors.black45, blurRadius: 4)],
              ),
            ),
          ],
        ),
        titleSpacing: 0,
        actions: _buildCompactReaderAppBarActions(),
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
              child: verses == null || _pageController == null
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white70),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Visibility(
                          visible: _showSwipeHint,
                          maintainSize: false,
                          maintainAnimation: false,
                          maintainState: false,
                          child: Center(
                            child: Text(
                              '← Wischen zum Blättern →',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              PageView.builder(
                                controller: _pageController!,
                                onPageChanged: (index) {
                                  setState(() => _currentVerseIndex = index);
                                  HapticFeedback.lightImpact();
                                },
                                itemCount: verses.length,
                                itemBuilder: (context, index) {
                                  final verse = verses[index];
                                    return SingleChildScrollView(
                                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 150),
                                    child: QuranVerseReaderTile(
                                      verse: verse,
                                      isBookmarked: _bookmarkedAyahNumbers.contains(verse.ayah),
                                      arabicFontSize: _arabicFontSize,
                                      arabicLineHeight: _arabicLineHeight,
                                      showTransliteration: _showTransliteration,
                                      isPlaying: _playingAyahNumber == verse.ayah,
                                      isLoading: _loadingAyahNumber == verse.ayah,
                                      showJumpHighlight: _jumpHighlightAyah == verse.ayah,
                                      onVerstehenTap: () => _onVerseTap(index, verse),
                                      onBookmarkTap: () => _toggleBookmark(verse.ayah),
                                      onPlayTap: () => _onPlayVerse(verse.ayah),
                                    ),
                                  );
                                },
                              ),
                              Positioned(
                                bottom: 100,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                                    ),
                                    child: Text(
                                      'Vers ${verses[_currentVerseIndex].ayah} / ${verses.length}',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Colors.white.withOpacity(0.7),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
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
}

class _TransliterationToggle extends StatelessWidget {
  const _TransliterationToggle({
    required this.showTransliteration,
    required this.onChanged,
  });

  final bool showTransliteration;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Segment(
            label: 'DE',
            selected: !showTransliteration,
            onTap: () => onChanged(false),
          ),
          _Segment(
            label: "A'",
            selected: showTransliteration,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFE5C07B).withOpacity(0.25) : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? const Color(0xFFE5C07B) : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }
}
