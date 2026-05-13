import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../data/glossary/glossary_entry.dart';
import '../data/glossary/glossary_repository.dart';
import '../theme/app_theme.dart';
import '../theme/hero_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/local_dictation_icon_button.dart';
import '../widgets/local_speech_privacy_caption.dart';

const Color _accentChampagneGold = Color(0xFFE5C07B);

/// Kurzes Leseglossar: Begriffe zu Koran und Praxis, offline aus JSON.
class GlossaryScreen extends StatefulWidget {
  const GlossaryScreen({super.key});

  @override
  State<GlossaryScreen> createState() => _GlossaryScreenState();
}

class _GlossaryScreenState extends State<GlossaryScreen> {
  final TextEditingController _search = TextEditingController();
  List<GlossaryEntry> _all = [];
  List<GlossaryEntry> _visible = [];
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _search.addListener(_applyFilter);
    _load();
  }

  @override
  void dispose() {
    _search.removeListener(_applyFilter);
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({bool forceReload = false}) async {
    try {
      final list = await GlossaryRepository.instance.loadEntries(forceReload: forceReload);
      if (!mounted) return;
      setState(() {
        _all = list;
        _visible = GlossaryRepository.filter(list, _search.text);
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _loading = false;
        });
      }
    }
  }

  Future<void> _retryLoad() async {
    GlossaryRepository.instance.clearCache();
    setState(() {
      _loading = true;
      _error = null;
    });
    await _load(forceReload: true);
  }

  void _applyFilter() {
    setState(() => _visible = GlossaryRepository.filter(_all, _search.text));
  }

  @override
  Widget build(BuildContext context) {
    final heroPhase = HeroPhase.day;

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
          'Koran-Begriffe',
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
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: Colors.white70))
                    : _error != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Konnte das Glossar nicht laden.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      color: Colors.white.withOpacity(0.88),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Nach neuen Dateien im Projekt: App vollständig neu starten (Hot Reload reicht für Assets oft nicht).',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      height: 1.4,
                                      color: Colors.white.withOpacity(0.52),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  TextButton(
                                    onPressed: _retryLoad,
                                    child: Text(
                                      'Erneut laden',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        color: _accentChampagneGold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    TextField(
                                      controller: _search,
                                      style: GoogleFonts.inter(fontSize: 15, color: Colors.white),
                                      cursorColor: _accentChampagneGold,
                                      decoration: InputDecoration(
                                        hintText: 'Begriff suchen …',
                                        hintStyle: GoogleFonts.inter(
                                          color: Colors.white.withOpacity(0.45),
                                        ),
                                        prefixIcon: Icon(
                                          Icons.search_rounded,
                                          color: Colors.white.withOpacity(0.55),
                                          size: 22,
                                        ),
                                        suffixIcon: LocalDictationIconButton(
                                          controller: _search,
                                          listenMode: ListenMode.search,
                                          iconColor: _accentChampagneGold,
                                          padding: const EdgeInsetsDirectional.only(end: 4),
                                        ),
                                        filled: true,
                                        fillColor: Colors.black.withOpacity(0.22),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          borderSide: BorderSide(color: Colors.white.withOpacity(0.14)),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          borderSide: BorderSide(color: Colors.white.withOpacity(0.14)),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          borderSide: BorderSide(color: _accentChampagneGold.withOpacity(0.45)),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                      ),
                                    ),
                                    const LocalSpeechPrivacyCaption(),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: _visible.isEmpty
                                    ? Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(24),
                                          child: Text(
                                            'Keine Treffer. Andere Stichworte probieren.',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.inter(
                                              color: Colors.white60,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      )
                                    : ListView.builder(
                                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                                        itemCount: _visible.length + 1,
                                        itemBuilder: (context, index) {
                                          if (index == _visible.length) {
                                            return Padding(
                                              padding: const EdgeInsets.only(top: 8),
                                              child: GlassCard(
                                                borderRadius: 18,
                                                child: Padding(
                                                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                                                  child: Text(
                                                    'Kurztexte zum Einordnen – kein Ersatz für Unterricht bei qualifizierten Lehrpersonen. Bei Glaubens- und Praxisfragen verlässliche Ansprechpartner vor Ort oder anerkannte Institutionen konsultieren.',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 12,
                                                      height: 1.45,
                                                      color: Colors.white.withOpacity(0.55),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          }
                                          final e = _visible[index];
                                          return Padding(
                                            padding: const EdgeInsets.only(bottom: 14),
                                            child: GlassCard(
                                              borderRadius: 20,
                                              child: Padding(
                                                padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                                  children: [
                                                    Text(
                                                      e.term,
                                                      style: GoogleFonts.playfairDisplay(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.w600,
                                                        color: Colors.white,
                                                        height: 1.25,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 10),
                                                    Text(
                                                      e.body,
                                                      style: GoogleFonts.inter(
                                                        fontSize: 14,
                                                        height: 1.5,
                                                        color: Colors.white.withOpacity(0.86),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
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
        ),
      ),
    );
  }
}
