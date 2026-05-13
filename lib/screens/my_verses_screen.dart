import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/bookmarks/bookmark_repository.dart';
import '../data/bookmarks/bookmark_item.dart';
import '../data/quran/translation_service.dart';
import '../data/reading/reading_progress_repository.dart';
import '../models/surah.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';
import '../theme/hero_theme.dart';
import '../widgets/bookmark_note_sheet.dart';
import 'explanation_bottom_sheet.dart';
import 'quran_reader_screen.dart';

/// Sure-Gruppe: Verse sortiert nach Aya-Nummer (Lesereihenfolge).
class _BookmarkSurahSection {
  const _BookmarkSurahSection({
    required this.surahId,
    required this.surahNameEn,
    required this.surahNameAr,
    required this.verses,
  });

  final int surahId;
  final String surahNameEn;
  final String surahNameAr;
  final List<BookmarkItem> verses;
}

List<_BookmarkSurahSection> _groupBookmarksBySurah(List<BookmarkItem> items) {
  if (items.isEmpty) {
    return const [];
  }
  final sorted = List<BookmarkItem>.from(items)
    ..sort((a, b) {
      final bySurah = a.surahId.compareTo(b.surahId);
      if (bySurah != 0) {
        return bySurah;
      }
      return a.ayahNumber.compareTo(b.ayahNumber);
    });
  final out = <_BookmarkSurahSection>[];
  var curSurah = sorted.first.surahId;
  var bucket = <BookmarkItem>[sorted.first];
  for (var i = 1; i < sorted.length; i++) {
    final e = sorted[i];
    if (e.surahId != curSurah) {
      out.add(
        _BookmarkSurahSection(
          surahId: curSurah,
          surahNameEn: bucket.first.surahNameEn,
          surahNameAr: bucket.first.surahNameAr,
          verses: List<BookmarkItem>.from(bucket),
        ),
      );
      curSurah = e.surahId;
      bucket = [e];
    } else {
      bucket.add(e);
    }
  }
  out.add(
    _BookmarkSurahSection(
      surahId: curSurah,
      surahNameEn: bucket.first.surahNameEn,
      surahNameAr: bucket.first.surahNameAr,
      verses: List<BookmarkItem>.from(bucket),
    ),
  );
  return out;
}

/// Sammlung: kompakte, einklappbare Suren-Blöcke (schnell scannbar); voller Vers im Leser.
class MyVersesScreen extends StatefulWidget {
  const MyVersesScreen({super.key});

  @override
  State<MyVersesScreen> createState() => _MyVersesScreenState();
}

class _MyVersesScreenState extends State<MyVersesScreen> {
  List<BookmarkItem>? _items;
  Object? _error;

  @override
  void initState() {
    super.initState();
    AudioService.instance.state.addListener(_onAudioStateChanged);
    _load();
  }

  @override
  void dispose() {
    AudioService.instance.state.removeListener(_onAudioStateChanged);
    super.dispose();
  }

  void _onAudioStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _load() async {
    try {
      await TranslationService.instance.ensureLoaded();
      final raw = await BookmarkRepository.instance.getBookmarksDetailed();
      final tr = TranslationService.instance;
      final list = raw.map((e) {
        final de = tr.getTranslation(e.surahId, e.ayahNumber).trim();
        if (de.isEmpty) {
          return e;
        }
        return e.copyWith(ayahTextDe: de);
      }).toList();
      if (mounted) {
        setState(() {
          _items = list;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _items = null;
          _error = e;
        });
      }
    }
  }

  void _onVerstehen(BookmarkItem item) {
    ReadingProgressRepository.instance.setLastRead(
      surahId: item.surahId,
      ayahNumber: item.ayahNumber,
    );
    showAiExplanationWithQuotaCheck(
      context,
      verseTitle: '${item.surahNameEn}, Vers ${item.ayahNumber}',
      surahName: item.surahNameEn,
      ayahNumber: item.ayahNumber,
      textAr: item.ayahTextAr ?? '',
      textDe: item.ayahTextDe ?? '',
      isFreeDailyVerse: false,
      showVerseHeader: false,
    );
  }

  Future<void> _toggleBookmark(BookmarkItem item) async {
    await BookmarkRepository.instance.removeBookmark(item.surahId, item.ayahNumber);
    if (!mounted) {
      return;
    }
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Aus Sammlung entfernt',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
    _load();
  }

  void _onPlayVerse(BookmarkItem item) {
    final s = AudioService.instance.state.value;
    if (s.surahId == item.surahId &&
        s.ayahNumber == item.ayahNumber &&
        (s.isPlaying || s.isLoading)) {
      AudioService.instance.stop();
    } else {
      AudioService.instance.playVerse(item.surahId, item.ayahNumber);
    }
  }

  Future<void> _editNote(BookmarkItem item) async {
    final changed = await showBookmarkNoteSheet(context, item: item);
    if (changed && mounted) {
      _load();
    }
  }

  void _openReader(BookmarkItem item) {
    final surah = Surah(
      number: item.surahId,
      nameDe: item.surahNameEn,
      nameAr: item.surahNameAr,
      verses: const [],
    );
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => QuranReaderScreen(
          surah: surah,
          initialAyahNumber: item.ayahNumber,
        ),
      ),
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    const heroPhase = HeroPhase.day;

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
          'Sammlung',
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
                child: _buildBody(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
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
    if (_items == null) {
      return const Center(child: CircularProgressIndicator(color: Colors.white70));
    }
    final list = _items!;
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bookmark_outline, size: 48, color: Colors.white54),
              const SizedBox(height: 16),
              Text(
                'Deine Sammlung ist noch leer',
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Hier erscheinen die Verse aus deiner Sammlung. Tippe im Koran-Leser auf das Lesezeichen neben einem Vers.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.45,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      );
    }
    final sections = _groupBookmarksBySurah(list);
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
            child: _CollectionOverview(
              verseCount: list.length,
              surahCount: sections.length,
            ),
          ),
        ),
        ...sections.map(
          (section) => SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
              child: _SurahBookmarksExpansion(
                key: PageStorageKey<String>('sammlung_sure_${section.surahId}'),
                section: section,
                onOpenReader: _openReader,
                onVerstehen: _onVerstehen,
                onPlay: _onPlayVerse,
                onRemoveBookmark: _toggleBookmark,
                onEditNote: _editNote,
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

const Color _accentChampagneGold = Color(0xFFE5C07B);

class _CollectionOverview extends StatelessWidget {
  const _CollectionOverview({
    required this.verseCount,
    required this.surahCount,
  });

  final int verseCount;
  final int surahCount;

  @override
  Widget build(BuildContext context) {
    final verseLabel = verseCount == 1 ? '1 Vers' : '$verseCount Verse';
    final surahLabel = surahCount == 1 ? '1 Sure' : '$surahCount Suren';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.09)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.menu_book_rounded,
              size: 20,
              color: _accentChampagneGold.withOpacity(0.9),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$verseLabel in $surahLabel',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                      color: Colors.white.withOpacity(0.92),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Suren einklappbar; eigene Notizen pro Vers. Voller Text im Leser.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      height: 1.35,
                      color: Colors.white.withOpacity(0.52),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Eine Sure: Kopfzeile + [ExpansionTile], innen kompakte Verszeilen.
class _SurahBookmarksExpansion extends StatelessWidget {
  const _SurahBookmarksExpansion({
    super.key,
    required this.section,
    required this.onOpenReader,
    required this.onVerstehen,
    required this.onPlay,
    required this.onRemoveBookmark,
    required this.onEditNote,
  });

  final _BookmarkSurahSection section;
  final void Function(BookmarkItem) onOpenReader;
  final void Function(BookmarkItem) onVerstehen;
  final void Function(BookmarkItem) onPlay;
  final void Function(BookmarkItem) onRemoveBookmark;
  final void Function(BookmarkItem) onEditNote;

  @override
  Widget build(BuildContext context) {
    final s = section;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: s.verses.length <= 4,
          onExpansionChanged: (_) => HapticFeedback.selectionClick(),
          tilePadding: const EdgeInsets.fromLTRB(14, 4, 8, 4),
          childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          iconColor: _accentChampagneGold,
          collapsedIconColor: _accentChampagneGold.withOpacity(0.85),
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SURE ${s.surahId}',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.55,
                        color: _accentChampagneGold.withOpacity(0.88),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.surahNameEn,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.95),
                      ),
                    ),
                  ],
                ),
              ),
              if (s.surahNameAr.isNotEmpty)
                Expanded(
                  flex: 4,
                  child: Text(
                    s.surahNameAr,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.amiri(
                      fontSize: 19,
                      height: 1.1,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6, right: 28),
            child: Text(
              s.verses.length == 1 ? '1 Vers in der Sammlung' : '${s.verses.length} Verse in der Sammlung',
              style: GoogleFonts.inter(
                fontSize: 11,
                height: 1.3,
                color: Colors.white.withOpacity(0.45),
              ),
            ),
          ),
          children: [
            for (var i = 0; i < s.verses.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              _CompactBookmarkRow(
                item: s.verses[i],
                onOpenReader: onOpenReader,
                onVerstehen: onVerstehen,
                onPlay: onPlay,
                onRemoveBookmark: onRemoveBookmark,
                onEditNote: onEditNote,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CompactBookmarkRow extends StatelessWidget {
  const _CompactBookmarkRow({
    required this.item,
    required this.onOpenReader,
    required this.onVerstehen,
    required this.onPlay,
    required this.onRemoveBookmark,
    required this.onEditNote,
  });

  final BookmarkItem item;
  final void Function(BookmarkItem) onOpenReader;
  final void Function(BookmarkItem) onVerstehen;
  final void Function(BookmarkItem) onPlay;
  final void Function(BookmarkItem) onRemoveBookmark;
  final void Function(BookmarkItem) onEditNote;

  @override
  Widget build(BuildContext context) {
    final audio = AudioService.instance.state.value;
    final isPlaying =
        audio.surahId == item.surahId && audio.ayahNumber == item.ayahNumber && audio.isPlaying;
    final isLoading =
        audio.surahId == item.surahId && audio.ayahNumber == item.ayahNumber && audio.isLoading;
    final de = (item.ayahTextDe ?? '').trim();
    final snippet = de.isNotEmpty ? de : 'Tippe für den vollen Vers im Leser.';
    final noteTrim = (item.noteBody ?? '').trim();
    final hasNote = noteTrim.isNotEmpty;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onOpenReader(item),
          borderRadius: BorderRadius.circular(12),
          splashColor: Colors.white.withOpacity(0.06),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.25),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Text(
                    '${item.ayahNumber}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _accentChampagneGold.withOpacity(0.95),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vers ${item.ayahNumber}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _accentChampagneGold.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        snippet,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          height: 1.35,
                          color: Colors.white.withOpacity(de.isNotEmpty ? 0.78 : 0.42),
                          fontStyle: de.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                        ),
                      ),
                      if (hasNote) ...[
                        const SizedBox(height: 4),
                        Text(
                          noteTrim.contains('\n') ? '${noteTrim.split('\n').first} …' : noteTrim,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            height: 1.3,
                            fontStyle: FontStyle.italic,
                            color: _accentChampagneGold.withOpacity(0.82),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(
                  width: 36,
                  height: 36,
                  child: IconButton(
                    tooltip: hasNote ? 'Notiz bearbeiten' : 'Notiz hinzufügen',
                    padding: EdgeInsets.zero,
                    onPressed: () => onEditNote(item),
                    icon: Icon(
                      hasNote ? Icons.edit_note_rounded : Icons.edit_note_outlined,
                      size: 22,
                      color: hasNote
                          ? _accentChampagneGold.withOpacity(0.95)
                          : Colors.white.withOpacity(0.62),
                    ),
                  ),
                ),
                SizedBox(
                  width: 36,
                  height: 36,
                  child: IconButton(
                    tooltip: 'Verstehen',
                    padding: EdgeInsets.zero,
                    onPressed: () => onVerstehen(item),
                    icon: Icon(
                      Icons.auto_awesome_rounded,
                      size: 20,
                      color: Colors.white.withOpacity(0.72),
                    ),
                  ),
                ),
                SizedBox(
                  width: 36,
                  height: 36,
                  child: isLoading
                      ? const Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _accentChampagneGold,
                            ),
                          ),
                        )
                      : IconButton(
                          tooltip: isPlaying ? 'Stopp' : 'Wiedergabe',
                          padding: EdgeInsets.zero,
                          onPressed: () => onPlay(item),
                          icon: Icon(
                            isPlaying ? Icons.stop_circle_outlined : Icons.play_circle_outline_rounded,
                            size: 22,
                            color: isPlaying
                                ? _accentChampagneGold
                                : AppColors.emeraldLight.withOpacity(0.95),
                          ),
                        ),
                ),
                SizedBox(
                  width: 36,
                  height: 36,
                  child: IconButton(
                    tooltip: 'Aus Sammlung entfernen',
                    padding: EdgeInsets.zero,
                    onPressed: () => onRemoveBookmark(item),
                    icon: Icon(
                      Icons.bookmark_rounded,
                      size: 20,
                      color: Colors.white.withOpacity(0.75),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
