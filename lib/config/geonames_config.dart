/// GeoNames API config for city search.
/// Get a free username at https://www.geonames.org/login
const String geonamesUsername = 'ihdinas';

const String _baseUrl = 'https://secure.geonames.org/searchJSON';

/// Returns true if username is set and not placeholder.
bool get isGeonamesConfigured =>
    geonamesUsername.trim().isNotEmpty;

/// Full URL for search (HTTPS only). Use for requests.
String geonamesSearchUrl(String query, {int maxRows = 10}) {
  final uri = Uri.parse(_baseUrl).replace(
    queryParameters: {
      'q': query,
      'maxRows': maxRows.toString(),
      'featureClass': 'P',
      'lang': 'de',
      'username': geonamesUsername,
    },
  );
  return uri.toString();
}

/// URL with username masked for logging (no username in logs).
String geonamesSearchUrlForLog(String query, {int maxRows = 10}) {
  final uri = Uri.parse(_baseUrl).replace(
    queryParameters: {
      'q': query,
      'maxRows': maxRows.toString(),
      'featureClass': 'P',
      'lang': 'de',
      'username': '***',
    },
  );
  return uri.toString();
}
