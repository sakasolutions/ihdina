import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/dua/dua_bookmark_repository.dart';
import '../data/dua/dua_entry.dart';
import '../theme/app_theme.dart';
import '../theme/hero_theme.dart';
import '../widgets/dua_detail_dialog.dart';
import '../widgets/dua_list_row.dart';

const Color _accentChampagneGold = Color(0xFFE5C07B);

/// Gespeicherte Dua-Favoriten.
class DuaFavoritesScreen extends StatefulWidget {
  const DuaFavoritesScreen({super.key});

  @override
  State<DuaFavoritesScreen> createState() => _DuaFavoritesScreenState();
}

class _DuaFavoritesScreenState extends State<DuaFavoritesScreen> {
  static const double _outerPadding = 24;
  static const double _sectionGap = 16;
  static const double _listBottomPadding = 48;

  List<DuaEntry> _entries = [];
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final entries =
          await DuaBookmarkRepository.instance.getBookmarkedEntries();
      if (!mounted) return;
      setState(() {
        _entries = entries;
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

  Future<void> _openDetail(DuaEntry entry, int listIndex) async {
    HapticFeedback.lightImpact();
    await showDuaDetailDialog(
      context,
      entry: entry,
      listIndex: listIndex,
      onBookmarkChanged: _load,
    );
    if (!mounted) return;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final heroPhase = HeroPhase.day;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SizedBox.expand(
        child: Container(
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
                              'Meine Duas',
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
        child: Text(
          'Favoriten konnten nicht geladen werden.',
          style: GoogleFonts.inter(fontSize: 15, color: Colors.white70),
        ),
      );
    }

    if (_entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(_outerPadding),
          child: Text(
            'Noch keine Favoriten.\nTippe in einer Dua auf das Lesezeichen.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              height: 1.45,
              color: Colors.white70,
            ),
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
        return Padding(
          padding: const EdgeInsets.only(bottom: _sectionGap),
          child: DuaListRow(
            entry: entry,
            listIndex: index + 1,
            isBookmarked: true,
            onTap: () => _openDetail(entry, index + 1),
          ),
        );
      },
    );
  }
}
