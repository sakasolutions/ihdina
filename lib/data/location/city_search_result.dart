/// Result of a city search: either list of cities or an error message.
class CitySearchResponse {
  const CitySearchResponse({this.results, this.errorMessage})
      : assert(results == null || errorMessage == null);

  final List<CitySearchResult>? results;
  final String? errorMessage;

  static CitySearchResponse success(List<CitySearchResult> list) =>
      CitySearchResponse(results: list);
  static CitySearchResponse error(String message) =>
      CitySearchResponse(errorMessage: message);
}

/// One city from GeoNames search.
class CitySearchResult {
  const CitySearchResult({
    required this.name,
    required this.countryName,
    this.countryCode,
    this.adminName1,
    required this.lat,
    required this.lng,
  });

  final String name;
  final String countryName;
  final String? countryCode;
  final String? adminName1;
  final double lat;
  final double lng;

  /// Label: "Name, AdminName1, CountryCode" (skip missing parts).
  String get displayLabel {
    final parts = <String>[name];
    if (adminName1 != null && adminName1!.isNotEmpty) parts.add(adminName1!);
    parts.add(countryCode != null && countryCode!.isNotEmpty ? countryCode! : countryName);
    return parts.join(', ');
  }

  /// Same format for persistence.
  String get persistenceLabel => displayLabel;

  factory CitySearchResult.fromJson(Map<String, dynamic> json) {
    final lat = double.tryParse('${json['lat']}') ?? 0.0;
    final lng = double.tryParse('${json['lng']}') ?? 0.0;
    return CitySearchResult(
      name: json['name'] as String? ?? '',
      countryName: json['countryName'] as String? ?? '',
      countryCode: json['countryCode'] as String?,
      adminName1: json['adminName1'] as String?,
      lat: lat,
      lng: lng,
    );
  }
}
