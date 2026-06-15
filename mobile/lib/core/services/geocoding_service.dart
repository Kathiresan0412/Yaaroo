import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service to geocode a city/country string into latitude/longitude coordinates.
///
/// Uses OpenStreetMap Nominatim (free, no API key required) to resolve
/// manually-entered city names to coordinates so users always show up on the
/// map and in distance-based discovery — even if their city isn't well-known.
class GeocodingService {
  GeocodingService._();
  static final GeocodingService instance = GeocodingService._();

  /// Resolve a city + country pair to lat/lng.
  ///
  /// Returns `null` if the place cannot be found.
  Future<GeocodingResult?> geocode({
    required String city,
    required String country,
  }) async {
    final query = '$city, $country';
    final uri = Uri.https(
      'nominatim.openstreetmap.org',
      '/search',
      {
        'q': query,
        'format': 'json',
        'limit': '1',
        'addressdetails': '1',
      },
    );

    try {
      final response = await http.get(uri, headers: {
        'User-Agent': 'YaaroApp/1.0',
        'Accept': 'application/json',
      });

      if (response.statusCode != 200) {
        debugPrint('[Geocoding] HTTP ${response.statusCode} for "$query"');
        return null;
      }

      final List<dynamic> results = jsonDecode(response.body);
      if (results.isEmpty) {
        debugPrint('[Geocoding] No results for "$query"');
        return null;
      }

      final first = results[0] as Map<String, dynamic>;
      final lat = double.tryParse(first['lat']?.toString() ?? '');
      final lng = double.tryParse(first['lon']?.toString() ?? '');

      if (lat == null || lng == null) return null;

      // Use the display name from Nominatim as a cleaner city name if available
      final address = first['address'] as Map<String, dynamic>?;
      final resolvedCity = address?['city']?.toString() ??
          address?['town']?.toString() ??
          address?['village']?.toString() ??
          address?['hamlet']?.toString() ??
          city;

      final resolvedCountry = address?['country']?.toString() ?? country;

      return GeocodingResult(
        latitude: lat,
        longitude: lng,
        city: resolvedCity,
        country: resolvedCountry,
        displayName: first['display_name']?.toString() ?? query,
      );
    } catch (e) {
      debugPrint('[Geocoding] Error geocoding "$query": $e');
      return null;
    }
  }

  /// Reverse geocode coordinates to city/country.
  Future<GeocodingResult?> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.https(
      'nominatim.openstreetmap.org',
      '/reverse',
      {
        'lat': latitude.toString(),
        'lon': longitude.toString(),
        'format': 'json',
        'addressdetails': '1',
      },
    );

    try {
      final response = await http.get(uri, headers: {
        'User-Agent': 'YaaroApp/1.0',
        'Accept': 'application/json',
      });

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final address = data['address'] as Map<String, dynamic>?;
      if (address == null) return null;

      final city = address['city']?.toString() ??
          address['town']?.toString() ??
          address['village']?.toString() ??
          address['hamlet']?.toString() ??
          '';
      final country = address['country']?.toString() ?? '';

      if (city.isEmpty) return null;

      return GeocodingResult(
        latitude: latitude,
        longitude: longitude,
        city: city,
        country: country,
        displayName: data['display_name']?.toString() ?? '',
      );
    } catch (e) {
      debugPrint('[Geocoding] Reverse geocode error: $e');
      return null;
    }
  }

  /// Search for places matching a query string (for autocomplete).
  Future<List<GeocodingResult>> searchPlaces(String query) async {
    if (query.trim().length < 2) return [];

    final uri = Uri.https(
      'nominatim.openstreetmap.org',
      '/search',
      {
        'q': query,
        'format': 'json',
        'limit': '5',
        'addressdetails': '1',
      },
    );

    try {
      final response = await http.get(uri, headers: {
        'User-Agent': 'YaaroApp/1.0',
        'Accept': 'application/json',
      });

      if (response.statusCode != 200) return [];

      final List<dynamic> results = jsonDecode(response.body);
      return results.map((item) {
        final map = item as Map<String, dynamic>;
        final address = map['address'] as Map<String, dynamic>?;
        return GeocodingResult(
          latitude: double.tryParse(map['lat']?.toString() ?? '') ?? 0,
          longitude: double.tryParse(map['lon']?.toString() ?? '') ?? 0,
          city: address?['city']?.toString() ??
              address?['town']?.toString() ??
              address?['village']?.toString() ??
              address?['hamlet']?.toString() ??
              map['display_name']?.toString().split(',').first ??
              '',
          country: address?['country']?.toString() ?? '',
          displayName: map['display_name']?.toString() ?? '',
        );
      }).toList();
    } catch (e) {
      debugPrint('[Geocoding] Search error: $e');
      return [];
    }
  }
}

class GeocodingResult {
  const GeocodingResult({
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.country,
    required this.displayName,
  });

  final double latitude;
  final double longitude;
  final String city;
  final String country;
  final String displayName;
}
