import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/bookmarks/bookmark_repository.dart';
import '../data/bookmarks/bookmark_item.dart';
import '../data/settings/settings_repository.dart';
import '../theme/app_theme.dart';
import '../theme/hero_theme.dart';
import '../models/surah.dart';
import 'quran_reader_screen.dart';

/// Champagne Gold accent (matches home, prayer, sources).
const Color _accentChampagneGold = Color(0xFFE5C07B);

/// Lists all bookmarks (offline from SQLite). Tap opens reader and scrolls to ayah.
class MyVersesScreen extends StatefulWidget {
  const MyVersesScreen({super.key});

  @override
  State<MyVersesScreen> createState() => _MyVersesScreenState();
}

class _MyVersesScreenState extends State<MyVersesScreen> {
  List<BookmarkItem>? _items;
  Object? _error;
  double _arabicFontSize = 28;
  double _arabicLineHeight = 1.8;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final settingsRepo = SettingsRepository.instance;
      final results = await Future.wait([
        BookmarkRepository.instance.getBookmarksDetailed(),
        settingsRepo.getArabicFontSize(),
        settingsRepo.getArabicLineHeight(),
      ]);
      final list = results[0] as List<BookmarkItem>;
      final fontSize = results[1] as double;
      final lineHeight = results[2] as double;
      if (mounted) setState(() {
        _items = list;
        _arabicFontSize = fontSize;
        _arabicLineHeight = lineHeight;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() {
        _items = null;
        _error = e;
      });
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
              Icon(Icons.bookmark_outline, size: 48, color: Colors.white54),
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
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _openReader(item),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                        '${item.surahId}',
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
                            item.surahNameEn,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          if (item.surahNameAr.isNotEmpty)
                            Text(
                              item.surahNameAr,
                              textDirection: TextDirection.rtl,
                              style: GoogleFonts.amiri(
                                fontSize: 18,
                                color: Colors.white.withOpacity(0.85),
                              ),
                            ),
                          if (item.ayahTextAr != null && item.ayahTextAr!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Directionality(
                              textDirection: TextDirection.rtl,
                              child: Text(
                                item.ayahTextAr!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.amiri(
                                  fontSize: _arabicFontSize,
                                  height: _arabicLineHeight,
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
        );
      },
    );
  }
}
