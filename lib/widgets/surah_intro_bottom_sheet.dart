import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

const Color _accentChampagneGold = Color(0xFFE5C07B);

/// Bottom-Sheet: Kurz-Einführung (Lesen-Modus). Überschrift = Surename; Stil wie Karahat-/Settings-Hilfe.
Future<void> showSurahIntroBottomSheet(
  BuildContext context, {
  required String surahNameDe,
  required String bodyDe,
  /// Wenn true: Option „nicht mehr automatisch“ + Callback nach Schließen.
  bool showAutoOptOut = false,
  void Function({required bool disableAutoShow})? onClose,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final bottomInset = MediaQuery.paddingOf(ctx).bottom;
      final disableAutoVN = ValueNotifier<bool>(false);
      return Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          bottom: 16 + bottomInset,
        ),
        child: ValueListenableBuilder<bool>(
          valueListenable: disableAutoVN,
          builder: (ctx, disableAuto, _) {
            return DecoratedBox(
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
                        Icon(
                          Icons.menu_book_outlined,
                          size: 22,
                          color: _accentChampagneGold,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            surahNameDe,
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
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.sizeOf(ctx).height * 0.5,
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          bodyDe,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            height: 1.45,
                            color: Colors.white.withOpacity(0.88),
                          ),
                        ),
                      ),
                    ),
                    if (showAutoOptOut) ...[
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () => disableAutoVN.value = !disableAutoVN.value,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: disableAuto,
                                  onChanged: (v) => disableAutoVN.value = v ?? false,
                                  activeColor: _accentChampagneGold,
                                  checkColor: AppColors.emeraldDark,
                                  side: BorderSide(color: Colors.white.withOpacity(0.45)),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Beim Öffnen von Suren nicht mehr automatisch anzeigen',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    height: 1.35,
                                    color: Colors.white.withOpacity(0.82),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          onClose?.call(disableAutoShow: disableAutoVN.value);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: _accentChampagneGold,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'Weiter zum Lesen',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
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

