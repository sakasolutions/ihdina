import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// Stabile Geräte-ID für Backend-Entitlement und Nutzungs-Tracking (ohne Login).
class InstallIdService {
  InstallIdService._();

  static final InstallIdService instance = InstallIdService._();

  static const String _prefsKey = 'ihdina_install_id_v1';

  Future<String> getOrCreate() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_prefsKey);
    if (existing != null && existing.trim().isNotEmpty) {
      return existing.trim();
    }
    final id = _randomHex(24);
    await prefs.setString(_prefsKey, id);
    return id;
  }

  static String _randomHex(int byteLength) {
    final rnd = Random.secure();
    final sb = StringBuffer();
    for (var i = 0; i < byteLength; i++) {
      sb.write(rnd.nextInt(256).toRadixString(16).padLeft(2, '0'));
    }
    return sb.toString();
  }
}
