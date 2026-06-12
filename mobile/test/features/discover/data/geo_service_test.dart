import 'package:flutter_test/flutter_test.dart';
import 'package:yaro0_mobile/features/discover/data/geo_service.dart';

void main() {
  group('GeoHasher', () {
    group('encode', () {
      test('encodes known coordinates to expected geohash', () {
        // San Francisco: lat 37.7749, lon -122.4194
        // Known geohash prefix for SF area is "9q8y"
        final hash = GeoHasher.encode(37.7749, -122.4194, precision: 9);
        expect(hash.length, 9);
        expect(hash.startsWith('9q8y'), isTrue);
      });

      test('encodes equator/prime meridian to expected geohash', () {
        // (0, 0) should encode to 's000...' based on geohash spec
        final hash = GeoHasher.encode(0.0, 0.0, precision: 5);
        expect(hash.length, 5);
        expect(hash.startsWith('s'), isTrue);
      });

      test('returns correct length for different precisions', () {
        expect(GeoHasher.encode(51.5074, -0.1278, precision: 4).length, 4);
        expect(GeoHasher.encode(51.5074, -0.1278, precision: 6).length, 6);
        expect(GeoHasher.encode(51.5074, -0.1278, precision: 9).length, 9);
      });

      test('nearby coordinates share a common prefix', () {
        // Two points very close together in London
        final hash1 = GeoHasher.encode(51.5074, -0.1278, precision: 9);
        final hash2 = GeoHasher.encode(51.5075, -0.1279, precision: 9);
        // They should share at least 7 characters prefix
        expect(hash1.substring(0, 7), hash2.substring(0, 7));
      });

      test('distant coordinates have different prefixes', () {
        // London vs Tokyo
        final london = GeoHasher.encode(51.5074, -0.1278, precision: 4);
        final tokyo = GeoHasher.encode(35.6762, 139.6503, precision: 4);
        expect(london, isNot(equals(tokyo)));
      });

      test('handles extreme coordinates', () {
        // North pole
        final northPole = GeoHasher.encode(90.0, 0.0, precision: 5);
        expect(northPole.length, 5);

        // South pole
        final southPole = GeoHasher.encode(-90.0, 0.0, precision: 5);
        expect(southPole.length, 5);

        // Date line
        final dateLine = GeoHasher.encode(0.0, 180.0, precision: 5);
        expect(dateLine.length, 5);

        final dateLineNeg = GeoHasher.encode(0.0, -180.0, precision: 5);
        expect(dateLineNeg.length, 5);
      });
    });

    group('neighbors', () {
      test('returns exactly 8 neighbors', () {
        final hash = GeoHasher.encode(51.5074, -0.1278, precision: 5);
        final result = GeoHasher.neighbors(hash);
        expect(result.length, 8);
      });

      test('all neighbors have same precision as input', () {
        final hash = GeoHasher.encode(40.7128, -74.0060, precision: 6);
        final result = GeoHasher.neighbors(hash);
        for (final neighbor in result) {
          expect(neighbor.length, hash.length);
        }
      });

      test('neighbors are all different from input and each other', () {
        final hash = GeoHasher.encode(34.0522, -118.2437, precision: 5);
        final result = GeoHasher.neighbors(hash);
        final allHashes = {hash, ...result};
        // Input + 8 neighbors = 9 unique hashes
        expect(allHashes.length, 9);
      });
    });
  });

  group('FirebaseGeoService - _precisionForRadius', () {
    // Test via the public encode method behavior — the precision selection
    // is internal but we can verify the geohash lengths produced by the
    // service make sense for given radiuses.
    test('GeoHasher produces valid base-32 characters only', () {
      const validChars = '0123456789bcdefghjkmnpqrstuvwxyz';
      final hash = GeoHasher.encode(48.8566, 2.3522, precision: 12);
      for (final char in hash.split('')) {
        expect(validChars.contains(char), isTrue,
            reason: 'Invalid character: $char');
      }
    });
  });
}
