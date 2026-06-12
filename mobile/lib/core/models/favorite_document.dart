import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a favorite document stored at
/// `users/{uid}/favorites/{targetUid}` in Firestore.
class FavoriteDocument {
  final String targetUid;
  final String name;
  final String primaryPhotoUrl;
  final int age;
  final DateTime savedAt;

  const FavoriteDocument({
    required this.targetUid,
    required this.name,
    required this.primaryPhotoUrl,
    required this.age,
    required this.savedAt,
  });

  /// Converts this [FavoriteDocument] to a Firestore-compatible map.
  Map<String, dynamic> toFirestore() {
    return {
      'targetUid': targetUid,
      'name': name,
      'primaryPhotoUrl': primaryPhotoUrl,
      'age': age,
      'savedAt': Timestamp.fromDate(savedAt),
    };
  }

  /// Creates a [FavoriteDocument] from a Firestore document snapshot.
  factory FavoriteDocument.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return FavoriteDocument(
      targetUid: data['targetUid'] as String,
      name: data['name'] as String,
      primaryPhotoUrl: data['primaryPhotoUrl'] as String,
      age: data['age'] as int,
      savedAt: (data['savedAt'] as Timestamp).toDate(),
    );
  }

  /// Creates a [FavoriteDocument] from a raw map.
  factory FavoriteDocument.fromMap(Map<String, dynamic> data) {
    return FavoriteDocument(
      targetUid: data['targetUid'] as String,
      name: data['name'] as String,
      primaryPhotoUrl: data['primaryPhotoUrl'] as String,
      age: data['age'] as int,
      savedAt: data['savedAt'] is Timestamp
          ? (data['savedAt'] as Timestamp).toDate()
          : data['savedAt'] as DateTime,
    );
  }

  FavoriteDocument copyWith({
    String? targetUid,
    String? name,
    String? primaryPhotoUrl,
    int? age,
    DateTime? savedAt,
  }) {
    return FavoriteDocument(
      targetUid: targetUid ?? this.targetUid,
      name: name ?? this.name,
      primaryPhotoUrl: primaryPhotoUrl ?? this.primaryPhotoUrl,
      age: age ?? this.age,
      savedAt: savedAt ?? this.savedAt,
    );
  }
}
