import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/models/match_document.dart';

/// Service for retrieving match data from Firestore.
///
/// Matches are stored at `matches/{matchId}` and queried using the `users`
/// array field to find matches for a specific user.
abstract class MatchService {
  /// Real-time stream of matches for the current user.
  ///
  /// Results are ordered by [lastMessageAt] descending so that the most
  /// recent conversations appear first. Returns an empty list when no
  /// matches exist.
  Stream<List<MatchDocument>> watchMatches(String uid);

  /// Gets a single match document by its [matchId].
  ///
  /// Returns `null` if the document does not exist.
  Future<MatchDocument?> getMatch(String matchId);
}

/// Firestore-backed implementation of [MatchService].
class FirestoreMatchService implements MatchService {
  final FirebaseFirestore _firestore;

  FirestoreMatchService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<MatchDocument>> watchMatches(String uid) {
    return _firestore
        .collection('matches')
        .where('users', arrayContains: uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return MatchDocument.fromFirestore(doc);
      }).toList();
    });
  }

  @override
  Future<MatchDocument?> getMatch(String matchId) async {
    final doc = await _firestore.collection('matches').doc(matchId).get();
    if (!doc.exists || doc.data() == null) {
      return null;
    }
    return MatchDocument.fromFirestore(doc);
  }
}
