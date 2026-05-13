import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/bookmarks/bookmark_item.dart';
import '../data/bookmarks/bookmark_note_repository.dart';
import '../theme/app_theme.dart';

const Color _accentChampagneGold = Color(0xFFE5C07B);

/// Bottom Sheet: persönliche Notiz zu einem Sammlungsvers speichern oder löschen.
/// Gibt `true` zurück, wenn sich etwas in der DB geändert hat.
Future<bool> showBookmarkNoteSheet(
  BuildContext context, {
  required BookmarkItem item,
}) async {
  final changed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _BookmarkNoteSheetBody(item: item),
  );
  return changed ?? false;
}

class _BookmarkNoteSheetBody extends StatefulWidget {
  const _BookmarkNoteSheetBody({required this.item});

  final BookmarkItem item;

  @override
  State<_BookmarkNoteSheetBody> createState() => _BookmarkNoteSheetBodyState();
}

class _BookmarkNoteSheetBodyState extends State<_BookmarkNoteSheetBody> {
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: (widget.item.noteBody ?? '').trim());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await BookmarkNoteRepository.instance.upsert(
        widget.item.surahId,
        widget.item.ayahNumber,
        _controller.text,
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _delete() async {
    setState(() => _saving = true);
    try {
      await BookmarkNoteRepository.instance.delete(
        widget.item.surahId,
        widget.item.ayahNumber,
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final hadNote = (widget.item.noteBody ?? '').trim().isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: AppColors.emeraldDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
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
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Notiz',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.item.surahNameEn} · Vers ${widget.item.ayahNumber}',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.white.withOpacity(0.55),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLines: 8,
              minLines: 4,
              style: GoogleFonts.inter(
                fontSize: 15,
                height: 1.45,
                color: Colors.white.withOpacity(0.9),
              ),
              cursorColor: _accentChampagneGold,
              decoration: InputDecoration(
                hintText: 'Deine Gedanken, Stichworte …',
                hintStyle: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.35),
                ),
                filled: true,
                fillColor: Colors.black.withOpacity(0.22),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: _accentChampagneGold.withOpacity(0.45)),
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                if (hadNote)
                  TextButton(
                    onPressed: _saving ? null : _delete,
                    child: Text(
                      'Löschen',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w500,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: _saving ? null : () => Navigator.of(context).pop(false),
                  child: Text(
                    'Abbrechen',
                    style: GoogleFonts.inter(color: Colors.white60),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: _accentChampagneGold.withOpacity(0.92),
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black54,
                          ),
                        )
                      : Text(
                          'Speichern',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
