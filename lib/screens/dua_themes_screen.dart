import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/dua/dua_bookmark_repository.dart';
import '../data/dua/dua_repository.dart';
import '../theme/app_theme.dart';
import '../theme/hero_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/prayer_reflection_moment_card.dart';
import 'dua_favorites_screen.dart';
import 'dua_list_screen.dart';

const Color _accentChampagneGold = Color(0xFFE5C07B);

class DuaSituationTopic {
  const DuaSituationTopic({
    required this.title,
    required this.situation,
    required this.icon,
  });

  final String title;
  final String situation;
  final IconData icon;
}

/// Dua-Tab: Themen-Raster nach Tagesablauf.
class DuaThemesScreen extends StatefulWidget {
  const DuaThemesScreen({super.key});

  static const List<DuaSituationTopic> topics = [
    DuaSituationTopic(
      title: 'Morgen',
      situation: 'morgen',
      icon: Icons.wb_sunny_rounded,
    ),
    DuaSituationTopic(
      title: 'Beim Essen',
      situation: 'essen',
      icon: Icons.restaurant_rounded,
    ),
    DuaSituationTopic(
      title: 'Nach dem Gebet',
      situation: 'nach_dem_gebet',
      icon: Icons.mosque_rounded,
    ),
    DuaSituationTopic(
      title: 'Abend',
      situation: 'abend',
      icon: Icons.nights_stay_rounded,
    ),
    DuaSituationTopic(
      title: 'Auf Reisen',
      situation: 'reise',
      icon: Icons.flight_rounded,
    ),
    DuaSituationTopic(
      title: 'In schwierigen Zeiten',
      situation: 'schwierigkeiten',
      icon: Icons.favorite_rounded,
    ),
    DuaSituationTopic(
      title: 'Reue & Vergebung',
      situation: 'reue',
      icon: Icons.self_improvement_rounded,
    ),
    DuaSituationTopic(
      title: 'Alltag',
      situation: 'alltag',
      icon: Icons.today_rounded,
    ),
  ];

  @override
  State<DuaThemesScreen> createState() => _DuaThemesScreenState();
}

class _DuaThemesScreenState extends State<DuaThemesScreen> {
  static const double _outerPadding = 24;
  static const double _navClearance = 100;

  Map<String, int> _counts = {};
  int _favoriteCount = 0;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool forceReload = false}) async {
    try {
      final data = await DuaRepository.instance.load(forceReload: forceReload);
      final favoriteCount = await DuaBookmarkRepository.instance.getBookmarkCount();
      final counts = <String, int>{};
      for (final topic in DuaThemesScreen.topics) {
        counts[topic.situation] = DuaRepository.filterBySituation(
          data.entries,
          topic.situation,
        ).length;
      }
      if (!mounted) return;
      setState(() {
        _counts = counts;
        _favoriteCount = favoriteCount;
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

  void _openTopic(DuaSituationTopic topic) {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => DuaListScreen(
          title: topic.title,
          situation: topic.situation,
        ),
      ),
    ).then((_) => _load());
  }

  void _openFavorites() {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const DuaFavoritesScreen(),
      ),
    ).then((_) => _load());
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
                child: _buildScrollContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScrollContent() {
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

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              _outerPadding,
              20,
              _outerPadding,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dua',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    shadows: const [
                      Shadow(color: Colors.black45, blurRadius: 4),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Bittgebete für jeden Moment',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              _outerPadding,
              14,
              _outerPadding,
              0,
            ),
            child: _DuaFavoritesEntry(
              count: _favoriteCount,
              onTap: _openFavorites,
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(_outerPadding, 14, _outerPadding, 0),
            child: CollapsibleReflectionMomentSection(),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            _outerPadding,
            14,
            _outerPadding,
            _navClearance,
          ),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.08,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final topic = DuaThemesScreen.topics[index];
                final count = _counts[topic.situation] ?? 0;
                return _DuaTopicTile(
                  topic: topic,
                  count: count,
                  onTap: () => _openTopic(topic),
                );
              },
              childCount: DuaThemesScreen.topics.length,
            ),
          ),
        ),
      ],
    );
  }
}

class _DuaFavoritesEntry extends StatelessWidget {
  const _DuaFavoritesEntry({
    required this.count,
    required this.onTap,
  });

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: GlassCard(
          borderRadius: 18,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  Icons.bookmark_rounded,
                  size: 22,
                  color: _accentChampagneGold,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Meine Duas',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  count == 0 ? '—' : '$count',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white54,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DuaTopicTile extends StatelessWidget {
  const _DuaTopicTile({
    required this.topic,
    required this.count,
    required this.onTap,
  });

  final DuaSituationTopic topic;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: Colors.white.withOpacity(0.06),
        child: GlassCard(
          borderRadius: 18,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  topic.icon,
                  size: 28,
                  color: _accentChampagneGold,
                ),
                const SizedBox(height: 10),
                Text(
                  topic.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _duaCountLabel(count),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _duaCountLabel(int count) {
    if (count == 1) return '1 Dua';
    return '$count Duas';
  }
}
