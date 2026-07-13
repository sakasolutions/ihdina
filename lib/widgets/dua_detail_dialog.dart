import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/dua/dua_bookmark_repository.dart';
import '../data/dua/dua_entry.dart';
import '../theme/app_theme.dart';
import 'dua_reader_tile.dart';

/// Dunkle, fast schwarze Dialogfläche — dezenter Emerald-Unterton, kein Teal-Grün.
Color _duaDialogCardColor() {
  return Color.lerp(
    AppColors.emeraldDark,
    const Color(0xFF050505),
    0.82,
  )!;
}

/// Vollständige Dua-Card als zentrierter Dialog (statt Bottom-Sheet).
Future<void> showDuaDetailDialog(
  BuildContext context, {
  required DuaEntry entry,
  required int listIndex,
  VoidCallback? onBookmarkChanged,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.transparent,
    useSafeArea: false,
    builder: (dialogContext) => _DuaDetailDialog(
      entry: entry,
      listIndex: listIndex,
      onBookmarkChanged: onBookmarkChanged,
    ),
  );
}

class _DuaDetailDialog extends StatefulWidget {
  const _DuaDetailDialog({
    required this.entry,
    required this.listIndex,
    this.onBookmarkChanged,
  });

  final DuaEntry entry;
  final int listIndex;
  final VoidCallback? onBookmarkChanged;

  @override
  State<_DuaDetailDialog> createState() => _DuaDetailDialogState();
}

class _DuaDetailDialogState extends State<_DuaDetailDialog> {
  bool _isBookmarked = false;
  bool _loadingBookmark = true;

  @override
  void initState() {
    super.initState();
    _loadBookmark();
  }

  Future<void> _loadBookmark() async {
    try {
      final bookmarked = await DuaBookmarkRepository.instance.isBookmarked(
        widget.entry.id,
      );
      if (!mounted) return;
      setState(() {
        _isBookmarked = bookmarked;
        _loadingBookmark = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingBookmark = false);
    }
  }

  Future<void> _toggleBookmark() async {
    if (_loadingBookmark) return;
    HapticFeedback.lightImpact();
    try {
      final repo = DuaBookmarkRepository.instance;
      if (_isBookmarked) {
        await repo.removeBookmark(widget.entry.id);
      } else {
        await repo.addBookmark(widget.entry.id);
      }
      if (!mounted) return;
      setState(() => _isBookmarked = !_isBookmarked);
      widget.onBookmarkChanged?.call();
    } catch (_) {
      // DB nicht verfügbar — UI bleibt unverändert.
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final maxHeight = size.height * 0.84;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      clipBehavior: Clip.none,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.pop(context),
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: ColoredBox(
                      color: Colors.black.withOpacity(0.42),
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxHeight),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: _duaDialogCardColor(),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.55),
                          blurRadius: 32,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Stack(
                        children: [
                          SingleChildScrollView(
                            child: DuaReaderTile(
                              entry: widget.entry,
                              listIndex: widget.listIndex,
                              embedded: true,
                              isBookmarked: _isBookmarked,
                              onBookmarkTap: _toggleBookmark,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Material(
                              color: Colors.transparent,
                              child: IconButton(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.all(8),
                                constraints: const BoxConstraints(
                                  minWidth: 36,
                                  minHeight: 36,
                                ),
                                tooltip: 'Schließen',
                                onPressed: () => Navigator.pop(context),
                                icon: Icon(
                                  Icons.close_rounded,
                                  size: 22,
                                  color: Colors.white.withOpacity(0.62),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
