import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/models/discovery_filters.dart';
import '../../../core/models/user_profile.dart';

/// Exception thrown when location permission is denied or disabled.
class LocationPermissionDeniedException implements Exception {
  final String message;
  const LocationPermissionDeniedException(this.message);

  @override
  String toString() => 'LocationPermissionDeniedException: $message';
}

/// Abstract interface for geolocation services.
abstract class GeoService {
  /// Updates user's location and geohash in Firestore.
  Future<void> updateLocation(String uid, GeoPoint location);

  /// Queries nearby users within radius, applying filters.
  Future<List<UserProfile>> queryNearbyUsers({
    required GeoPoint center,
    required double radiusKm,
    required DiscoveryFilters filters,
    required String excludeUid,
    required Set<String> excludedUids,
    int limit = 50,
  });

  /// Requests current device location, handling permissions.
  /// Throws [LocationPermissionDeniedException] if denied.
  Future<Position> getCurrentPosition();

  /// Updates location on app open if permission is granted.
  /// Returns true if location was updated, false if permission denied.
  Future<bool> updateLocationOnAppOpen(String uid);
}

/// Firebase implementation of [GeoService] using geohash-based Firestore queries.
///
/// Uses geohash encoding to enable efficient proximity queries on Firestore
/// without external geo-query libraries. This is the same technique used by
/// Geoflutterfire2 internally.
class FirebaseGeoService implements GeoService {
  final FirebaseFirestore _firestore;

  FirebaseGeoService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> updateLocation(String uid, GeoPoint location) async {
    final geohash = GeoHasher.encode(
      location.latitude,
      location.longitude,
    );

    await _firestore.collection('users').doc(uid).update({
      'location': location,
      'geohash': geohash,
    });
  }

  @override
  Future<List<UserProfile>> queryNearbyUsers({
    required GeoPoint center,
    required double radiusKm,
    required DiscoveryFilters filters,
    required String excludeUid,
    required Set<String> excludedUids,
    int limit = 50,
  }) async {
    // Calculate the geohash precision needed for the given radius
    final precision = _precisionForRadius(radiusKm);
    final centerHash = GeoHasher.encode(
      center.latitude,
      center.longitude,
      precision: precision,
    );

    // Get neighboring geohash cells to cover the radius area
    final neighbors = GeoHasher.neighbors(centerHash);
    final searchHashes = [centerHash, ...neighbors];

    final results = <UserProfile>[];
    final seen = <String>{};

    // Query each geohash range
    for (final hash in searchHashes) {
      if (results.length >= limit) break;

      final querySnapshot = await _firestore
          .collection('users')
          .where('geohash', isGreaterThanOrEqualTo: hash)
          .where('geohash', isLessThan: '$hash~')
          .get();

      for (final doc in querySnapshot.docs) {
        if (results.length >= limit) break;

        final data = doc.data();
        final uid = data['uid'] as String?;
        if (uid == null) continue;

        // Skip duplicates from overlapping ranges
        if (seen.contains(uid)) continue;
        seen.add(uid);

        // Exclude self
        if (uid == excludeUid) continue;

        // Exclude already liked/disliked users
        if (excludedUids.contains(uid)) continue;

        // Apply age filter
        final age = data['age'] as int?;
        if (age == null) continue;
        if (age < filters.ageMin || age > filters.ageMax) continue;

        // Apply gender filter
        final gender = data['gender'] as String?;
        if (gender == null) continue;
        if (!filters.interestedIn.contains(gender)) continue;

        // Verify actual distance (geohash is an approximation)
        final userLocation = data['location'] as GeoPoint?;
        if (userLocation == null) continue;

        final distanceMeters = Geolocator.distanceBetween(
          center.latitude,
          center.longitude,
          userLocation.latitude,
          userLocation.longitude,
        );
        final distanceKm = distanceMeters / 1000.0;
        if (distanceKm > radiusKm) continue;

        try {
          final profile = UserProfile.fromFirestore(doc);
          results.add(profile);
        } catch (_) {
          // Skip malformed documents
          continue;
        }
      }
    }

    return results;
  }

  @override
  Future<Position> getCurrentPosition() async {
    // Check if location services are enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationPermissionDeniedException(
        'Location services are disabled. Please enable location services.',
      );
    }

    // Check and request permission
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const LocationPermissionDeniedException(
          'Location permission denied. Location is required to discover nearby users.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationPermissionDeniedException(
        'Location permission permanently denied. Please enable it in device settings to discover nearby users.',
      );
    }

    // Get current position
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
  }

  @override
  Future<bool> updateLocationOnAppOpen(String uid) async {
    try {
      final position = await getCurrentPosition();
      final geoPoint = GeoPoint(position.latitude, position.longitude);
      await updateLocation(uid, geoPoint);
      return true;
    } on LocationPermissionDeniedException {
      return false;
    }
  }

  /// Determines the geohash precision level appropriate for a given radius.
  ///
  /// Precision determines how many characters the geohash uses.
  /// Higher precision = smaller cells = more queries needed for large areas.
  int _precisionForRadius(double radiusKm) {
    // Approximate cell sizes for each precision level:
    // 1: ~5000km, 2: ~1250km, 3: ~156km, 4: ~39km
    // 5: ~4.9km, 6: ~1.2km, 7: ~0.15km, 8: ~0.019km
    if (radiusKm > 625) return 1;
    if (radiusKm > 156) return 2;
    if (radiusKm > 39) return 3;
    if (radiusKm > 5) return 4;
    if (radiusKm > 1.2) return 5;
    if (radiusKm > 0.15) return 6;
    if (radiusKm > 0.02) return 7;
    return 8;
  }
}

/// Geohash encoding and neighbor computation utility.
///
/// Implements the standard geohash algorithm using base-32 encoding
/// for geographic coordinates.
class GeoHasher {
  static const String _base32Chars = '0123456789bcdefghjkmnpqrstuvwxyz';

  /// Encodes latitude and longitude into a geohash string.
  ///
  /// [precision] determines the length of the resulting geohash (default: 9).
  /// Higher precision = more accurate but smaller coverage area.
  static String encode(
    double latitude,
    double longitude, {
    int precision = 9,
  }) {
    double minLat = -90.0, maxLat = 90.0;
    double minLon = -180.0, maxLon = 180.0;
    bool isEven = true;
    int bit = 0;
    int charIndex = 0;
    final buffer = StringBuffer();

    while (buffer.length < precision) {
      if (isEven) {
        final mid = (minLon + maxLon) / 2;
        if (longitude >= mid) {
          charIndex = charIndex * 2 + 1;
          minLon = mid;
        } else {
          charIndex = charIndex * 2;
          maxLon = mid;
        }
      } else {
        final mid = (minLat + maxLat) / 2;
        if (latitude >= mid) {
          charIndex = charIndex * 2 + 1;
          minLat = mid;
        } else {
          charIndex = charIndex * 2;
          maxLat = mid;
        }
      }

      isEven = !isEven;
      bit++;

      if (bit == 5) {
        buffer.write(_base32Chars[charIndex]);
        bit = 0;
        charIndex = 0;
      }
    }

    return buffer.toString();
  }

  /// Returns the 8 neighboring geohash cells for a given geohash.
  static List<String> neighbors(String geohash) {
    final decoded = _decodeBounds(geohash);
    final lat = (decoded.minLat + decoded.maxLat) / 2;
    final lon = (decoded.minLon + decoded.maxLon) / 2;
    final latErr = (decoded.maxLat - decoded.minLat) / 2;
    final lonErr = (decoded.maxLon - decoded.minLon) / 2;

    final precision = geohash.length;

    return [
      // N
      encode(lat + 2 * latErr, lon, precision: precision),
      // NE
      encode(lat + 2 * latErr, lon + 2 * lonErr, precision: precision),
      // E
      encode(lat, lon + 2 * lonErr, precision: precision),
      // SE
      encode(lat - 2 * latErr, lon + 2 * lonErr, precision: precision),
      // S
      encode(lat - 2 * latErr, lon, precision: precision),
      // SW
      encode(lat - 2 * latErr, lon - 2 * lonErr, precision: precision),
      // W
      encode(lat, lon - 2 * lonErr, precision: precision),
      // NW
      encode(lat + 2 * latErr, lon - 2 * lonErr, precision: precision),
    ];
  }

  /// Decodes a geohash into its bounding box coordinates.
  static _GeoBounds _decodeBounds(String geohash) {
    double minLat = -90.0, maxLat = 90.0;
    double minLon = -180.0, maxLon = 180.0;
    bool isEven = true;

    for (int i = 0; i < geohash.length; i++) {
      final charIndex = _base32Chars.indexOf(geohash[i]);
      for (int bit = 4; bit >= 0; bit--) {
        final bitValue = (charIndex >> bit) & 1;
        if (isEven) {
          final mid = (minLon + maxLon) / 2;
          if (bitValue == 1) {
            minLon = mid;
          } else {
            maxLon = mid;
          }
        } else {
          final mid = (minLat + maxLat) / 2;
          if (bitValue == 1) {
            minLat = mid;
          } else {
            maxLat = mid;
          }
        }
        isEven = !isEven;
      }
    }

    return _GeoBounds(
      minLat: minLat,
      maxLat: maxLat,
      minLon: minLon,
      maxLon: maxLon,
    );
  }
}

/// Internal bounding box representation for geohash decoding.
class _GeoBounds {
  final double minLat;
  final double maxLat;
  final double minLon;
  final double maxLon;

  const _GeoBounds({
    required this.minLat,
    required this.maxLat,
    required this.minLon,
    required this.maxLon,
  });
}
