import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/dua/dua_bookmark_repository.dart';
import '../data/dua/dua_entry.dart';
import '../data/dua/dua_repository.dart';
import '../theme/app_theme.dart';
import '../theme/hero_theme.dart';
import '../widgets/dua_detail_dialog.dart';
import '../widgets/dua_list_row.dart';

const Color _accentChampagneGold = Color(0xFFE5C07B);

/// Gefilterte Dua-Liste für eine [situation] — kompakte Zeilen, Card im Dialog.
class DuaListScreen extends StatefulWidget {
  const DuaListScreen({
    super.key,
    required this.title,
    required this.situation,
  });

  final String title;
  final String situation;

  @override
  State<DuaListScreen> createState() => _DuaListScreenState();
}

class _DuaListScreenState extends State<DuaListScreen> {
  static const double _outerPadding = 24;
  static const double _sectionGap = 16;
  static const double _listBottomPadding = 48;

  List<DuaEntry> _entries = [];
  Set<int> _bookmarkedIds = {};
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool forceReload = false}) async {
    try {
      final results = await Future.wait([
        DuaRepository.instance.getBySituation(
          widget.situation,
          forceReload: forceReload,
        ),
        DuaBookmarkRepository.instance.getBookmarkedIds(),
      ]);
      if (!mounted) return;
      setState(() {
        _entries = results[0] as List<DuaEntry>;
        _bookmarkedIds = results[1] as Set<int>;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _retry() async {
    DuaRepository.instance.clearCache();
    setState(() {
      _loading = true;
      _error = null;
    });
    await _load(forceReload: true);
  }

  Future<void> _refreshBookmarks() async {
    final ids = await DuaBookmarkRepository.instance.getBookmarkedIds();
    if (!mounted) return;
    setState(() => _bookmarkedIds = ids);
  }

  Future<void> _openDetail(DuaEntry entry, int listIndex) async {
    HapticFeedback.lightImpact();
    await showDuaDetailDialog(
      context,
      entry: entry,
      listIndex: listIndex,
      onBookmarkChanged: _refreshBookmarks,
    );
    await _refreshBookmarks();
  }

  @override
  Widget build(BuildContext context) {
    final heroPhase = HeroPhase.day;

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
                      padding: const EdgeInsets.fromLTRB(
                        _outerPadding - 8,
                        20,
                        _outerPadding,
                        0,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              size: 26,
                              color: Colors.white,
                            ),
                            tooltip: 'Zurück',
                            onPressed: () => Navigator.pop(context),
                            style: IconButton.styleFrom(
                              minimumSize: const Size(48, 48),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              widget.title,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 28,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                shadows: const [
                                  Shadow(color: Colors.black45, blurRadius: 4),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: _sectionGap),
                    Expanded(child: _buildBody()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: _accentChampagneGold),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(_outerPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Duas konnten nicht geladen werden.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _retry,
                child: Text(
                  'Erneut versuchen',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: _accentChampagneGold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_entries.isEmpty) {
      return Center(
        child: Text(
          'Keine Duas in dieser Kategorie.',
          style: GoogleFonts.inter(
            fontSize: 15,
            color: Colors.white70,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        _outerPadding,
        0,
        _outerPadding,
        _listBottomPadding,
      ),
      itemCount: _entries.length,
      itemBuilder: (context, index) {
        final entry = _entries[index];
        final listIndex = index + 1;
        return Padding(
          padding: const EdgeInsets.only(bottom: _sectionGap),
          child: DuaListRow(
            entry: entry,
            listIndex: listIndex,
            isBookmarked: _bookmarkedIds.contains(entry.id),
            onTap: () => _openDetail(entry, listIndex),
          ),
        );
      },
    );
  }
}
