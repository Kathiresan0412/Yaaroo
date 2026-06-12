import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a like/dislike document stored at
/// `likes/{uid}/liked/{targetUid}` or `likes/{uid}/disliked/{targetUid}`.
class LikeDocument {
  final String targetUid;
  final bool superLike;
  final DateTime createdAt;

  const LikeDocument({
    required this.targetUid,
    required this.superLike,
    required this.createdAt,
  });

  /// Converts this [LikeDocument] to a Firestore-compatible map.
  Map<String, dynamic> toFirestore() {
    return {
      'targetUid': targetUid,
      'superLike': superLike,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Creates a [LikeDocument] from a Firestore document snapshot.
  factory LikeDocument.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return LikeDocument(
      targetUid: data['targetUid'] as String,
      superLike: data['superLike'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Creates a [LikeDocument] from a raw map.
  factory LikeDocument.fromMap(Map<String, dynamic> data) {
    return LikeDocument(
      targetUid: data['targetUid'] as String,
      superLike: data['superLike'] as bool? ?? false,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : data['createdAt'] as DateTime,
    );
  }

  LikeDocument copyWith({
    String? targetUid,
    bool? superLike,
    DateTime? createdAt,
  }) {
    return LikeDocument(
      targetUid: targetUid ?? this.targetUid,
      superLike: superLike ?? this.superLike,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
