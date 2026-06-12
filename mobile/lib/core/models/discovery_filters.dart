/// Represents the discovery filter preferences for a user.
///
/// Used to filter eligible profiles in the discovery/swipe feed
/// and map view.
class DiscoveryFilters {
  final int ageMin;
  final int ageMax;
  final int maxDistance;
  final List<String> interestedIn;

  const DiscoveryFilters({
    this.ageMin = 18,
    this.ageMax = 99,
    this.maxDistance = 50,
    this.interestedIn = const ['Male', 'Female', 'Other'],
  });

  /// Converts this [DiscoveryFilters] to a Firestore-compatible map.
  Map<String, dynamic> toFirestore() {
    return {
      'ageMin': ageMin,
      'ageMax': ageMax,
      'maxDistance': maxDistance,
      'interestedIn': interestedIn,
    };
  }

  /// Creates a [DiscoveryFilters] from a Firestore map.
  factory DiscoveryFilters.fromFirestore(Map<String, dynamic> data) {
    return DiscoveryFilters(
      ageMin: data['ageMin'] as int? ?? 18,
      ageMax: data['ageMax'] as int? ?? 99,
      maxDistance: data['maxDistance'] as int? ?? 50,
      interestedIn: data['interestedIn'] != null
          ? List<String>.from(data['interestedIn'] as List)
          : const ['Male', 'Female', 'Other'],
    );
  }

  DiscoveryFilters copyWith({
    int? ageMin,
    int? ageMax,
    int? maxDistance,
    List<String>? interestedIn,
  }) {
    return DiscoveryFilters(
      ageMin: ageMin ?? this.ageMin,
      ageMax: ageMax ?? this.ageMax,
      maxDistance: maxDistance ?? this.maxDistance,
      interestedIn: interestedIn ?? this.interestedIn,
    );
  }
}
