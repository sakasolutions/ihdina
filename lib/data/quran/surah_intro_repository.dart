import 'dart:convert';

import 'package:flutter/services.dart';

/// Lokale Kurz-Einführungen pro Sure (DE). Später durch API-Response ersetzbar, gleiche Schnittstelle.
class SurahIntroRepository {
  SurahIntroRepository._();

  static final SurahIntroRepository instance = SurahIntroRepository._();

  static const String _assetPath = 'assets/data/surah_intros.json';

  Map<String, dynamic>? _json;

  Future<void> _ensureLoaded() async {
    if (_json != null) return;
    final raw = await rootBundle.loadString(_assetPath);
    _json = json.decode(raw) as Map<String, dynamic>;
  }

  /// Fließtext mit Absätzen getrennt durch `\n\n`, oder null wenn keine Einführung hinterlegt.
  Future<String?> getIntroDe(int surahId) async {
    await _ensureLoaded();
    final v = _json![surahId.toString()];
    if (v is String && v.trim().isNotEmpty) return v.trim();
    return null;
  }
}
