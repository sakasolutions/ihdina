import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/quran/models/ayah_model.dart';
import '../data/quran/models/surah_model.dart';
import '../data/quran/quran_repository.dart';
import '../data/quran/translation_service.dart';
import '../theme/app_theme.dart';

const Color _accentChampagneGold = Color(0xFFE5C07B);

/// Kurzvorschau für einen Koranvers (Tap auf Versreferenz in KI-Erklärungen).
Future<void> showAyahPreviewBottomSheet({
  required BuildContext context,
  required int surahId,
  required int ayahNumber,
  required VoidCallback onOpenVerse,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _AyahPreviewSheet(
      surahId: surahId,
      ayahNumber: ayahNumber,
      onOpenVerse: onOpenVerse,
    ),
  );
}

class _AyahPreviewSheet extends StatefulWidget {
  const _AyahPreviewSheet({
    required this.surahId,
    required this.ayahNumber,
    required this.onOpenVerse,
  });

  final int surahId;
  final int ayahNumber;
  final VoidCallback onOpenVerse;

  @override
  State<_AyahPreviewSheet> createState() => _AyahPreviewSheetState();
}

class _AyahPreviewSheetState extends State<_AyahPreviewSheet> {
  bool _loading = true;
  String? _error;
  String? _surahTitle;
  String? _textAr;
  String? _textDe;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        QuranRepository.instance.getAllSurahs(),
        QuranRepository.instance.getAyahsBySurahId(widget.surahId),
        TranslationService.instance.ensureLoaded(),
      ]);
      if (!mounted) return;

      final surahs = results[0] as List<SurahModel>;
      final ayahs = results[1] as List<AyahModel>;
      final surah = surahs.where((s) => s.id == widget.surahId).firstOrNull;
      if (surah == null) {
        setState(() {
          _loading = false;
          _error = 'Sure nicht gefunden.';
        });
        return;
      }

      final ayah = ayahs.where((a) => a.ayahNumber == widget.ayahNumber).firstOrNull;
      if (ayah == null) {
        setState(() {
          _loading = false;
          _error = 'Vers ${widget.ayahNumber} wurde in dieser Sure nicht gefunden.';
        });
        return;
      }

      final translation = TranslationService.instance.getTranslation(
        widget.surahId,
        widget.ayahNumber,
      );

      setState(() {
        _loading = false;
        _surahTitle = '${surah.nameEn}, Vers ${widget.ayahNumber}';
        _textAr = ayah.textAr;
        _textDe = translation.trim().isNotEmpty ? translation.trim() : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Vers konnte nicht geladen werden.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        bottom: 16 + bottomInset,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Colors.white.withOpacity(0.14),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.menu_book_outlined,
                    size: 22,
                    color: _accentChampagneGold,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _loading
                          ? 'Vers wird geladen…'
                          : (_surahTitle ?? 'Versvorschau'),
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        color: _accentChampagneGold,
                        strokeWidth: 2.5,
                      ),
                    ),
                  ),
                )
              else if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    _error!,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      height: 1.45,
                      color: Colors.white.withOpacity(0.75),
                    ),
                  ),
                )
              else ...[
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.38,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _textAr ?? '',
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          style: GoogleFonts.amiri(
                            fontSize: 22,
                            height: 1.65,
                            color: Colors.white,
                          ),
                        ),
                        if (_textDe != null) ...[
                          const SizedBox(height: 14),
                          Text(
                            _textDe!,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              height: 1.5,
                              color: Colors.white.withOpacity(0.88),
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 10),
                          Text(
                            'Deutsche Übersetzung für diesen Vers ist nicht verfügbar.',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              height: 1.4,
                              color: Colors.white.withOpacity(0.55),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onOpenVerse();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: _accentChampagneGold,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Zum Vers öffnen',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }
}
