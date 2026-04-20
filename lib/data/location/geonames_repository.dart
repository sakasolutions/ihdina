import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../config/geonames_config.dart';
import 'city_search_result.dart';

/// Fetches city search results from GeoNames (HTTPS only).
class GeonamesRepository {
  GeonamesRepository._();

  static final GeonamesRepository instance = GeonamesRepository._();

  Future<CitySearchResponse> searchCities(String query) async {
    final q = query.trim();
    if (q.isEmpty) return CitySearchResponse.success([]);

    if (!isGeonamesConfigured) {
      return CitySearchResponse.error(
        'Stadtsuche nicht konfiguriert. Bitte GeoNames Username in lib/config/geonames_config.dart eintragen.',
      );
    }

    final uri = Uri.parse(geonamesSearchUrl(q, maxRows: 10));
    if (kDebugMode) {
      // ignore: avoid_print
      print('[CITY] url=${geonamesSearchUrlForLog(q, maxRows: 10)}');
    }

    try {
      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
      );

      if (kDebugMode) {
        // ignore: avoid_print
        print('[CITY] status=${response.statusCode}');
        final bodyPreview = response.body.length > 200
            ? '${response.body.substring(0, 200)}...'
            : response.body;
        // ignore: avoid_print
        print('[CITY] body=$bodyPreview');
      }

      if (response.statusCode != 200) {
        return CitySearchResponse.error(
          'HTTP ${response.statusCode}: Anfrage fehlgeschlagen.',
        );
      }

      final map = jsonDecode(response.body) as Map<String, dynamic>?;
      if (map == null) {
        return CitySearchResponse.error('Antwort konnte nicht gelesen werden.');
      }

      // GeoNames API error (e.g. invalid username)
      final status = map['status'] as Map<String, dynamic>?;
      if (status != null) {
        final message = status['message'] as String? ?? 'Unbekannter Fehler';
        return CitySearchResponse.error('GeoNames Fehler: $message');
      }

      final list = map['geonames'];
      if (list is! List) {
        return CitySearchResponse.error('Ungültiges Antwortformat.');
      }

      final results = <CitySearchResult>[];
      for (final e in list) {
        if (e is! Map<String, dynamic>) continue;
        try {
          final city = CitySearchResult.fromJson(e);
          if (city.name.isNotEmpty) results.add(city);
        } catch (_) {
          // skip malformed item
        }
      }
      return CitySearchResponse.success(results);
    } catch (e, st) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('[CITY] exception: $e');
        // ignore: avoid_print
        print(st);
      }
      return CitySearchResponse.error(
        'Netzwerkfehler oder Zeitüberschreitung. Bitte prüfen Sie Ihre Verbindung.',
      );
    }
  }
}
