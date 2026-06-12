import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/models/discovery_filters.dart';
import '../../../core/models/like_document.dart';
import '../../../core/models/user_profile.dart';
import '../../discover/data/geo_service.dart';

/// Exception thrown when a swipe write operation fails.
///
/// When this is thrown, the UI should keep the current card in the stack
/// and display an error indication to the user.
class SwipeWriteException implements Exception {
  final String message;
  const SwipeWriteException(this.message);

  @override
  String toString() => 'SwipeWriteException: $message';
}

/// Service responsible for recording likes/dislikes and fetching eligible
/// profiles for the swipe card deck.
///
/// Like documents are stored at `likes/{uid}/liked/{targetUid}`.
/// Dislike documents are stored at `likes/{uid}/disliked/{targetUid}`.
abstract class SwipeService {
  /// Records a like at `likes/{uid}/liked/{targetUid}`.
  ///
  /// If [superLike] is true, the document will include a `superLike: true` field.
  /// Throws [SwipeWriteException] if the write fails, allowing the UI to keep
  /// the card in the stack.
  Future<void> like(String uid, String targetUid, {bool superLike = false});

  /// Records a dislike at `likes/{uid}/disliked/{targetUid}`.
  ///
  /// Throws [SwipeWriteException] if the write fails, allowing the UI to keep
  /// the card in the stack.
  Future<void> dislike(String uid, String targetUid);

  /// Fetches the next batch of eligible profiles using geo and filter criteria.
  ///
  /// This method:
  /// 1. Gets the current user's profile (for location and filters)
  /// 2. Fetches existing liked/disliked UIDs to build an exclusion set
  /// 3. Calls [GeoService.queryNearbyUsers] with the exclusion set and filters
  ///
  /// Returns up to [limit] profiles (default 10).
  Future<List<UserProfile>> fetchEligibleProfiles(String uid, {int limit = 10});
}

/// Firestore-backed implementation of [SwipeService].
///
/// Uses [GeoService] for proximity-based profile discovery and writes
/// like/dislike documents directly to Firestore.
class FirestoreSwipeService implements SwipeService {
  final FirebaseFirestore _firestore;
  final GeoService _geoService;

  FirestoreSwipeService({
    FirebaseFirestore? firestore,
    required GeoService geoService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _geoService = geoService;

  @override
  Future<void> like(String uid, String targetUid,
      {bool superLike = false}) async {
    try {
      final likeDoc = LikeDocument(
        targetUid: targetUid,
        superLike: superLike,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('likes')
          .doc(uid)
          .collection('liked')
          .doc(targetUid)
          .set(likeDoc.toFirestore());
    } catch (e) {
      throw SwipeWriteException(
        'Failed to record like. Please try again. Error: $e',
      );
    }
  }

  @override
  Future<void> dislike(String uid, String targetUid) async {
    try {
      final dislikeDoc = LikeDocument(
        targetUid: targetUid,
        superLike: false,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('likes')
          .doc(uid)
          .collection('disliked')
          .doc(targetUid)
          .set(dislikeDoc.toFirestore());
    } catch (e) {
      throw SwipeWriteException(
        'Failed to record dislike. Please try again. Error: $e',
      );
    }
  }

  @override
  Future<List<UserProfile>> fetchEligibleProfiles(String uid,
      {int limit = 10}) async {
    // 1. Get current user's profile for location and filter preferences
    final userDoc = await _firestore.collection('users').doc(uid).get();
    if (!userDoc.exists || userDoc.data() == null) {
      return [];
    }

    final currentUser = UserProfile.fromFirestore(userDoc);

    // 2. Build exclusion set from liked and disliked collections
    final excludedUids = await _fetchExcludedUids(uid);

    // 3. Build discovery filters from user preferences (use defaults if not set)
    final filters = DiscoveryFilters(
      ageMin: currentUser.ageMin ?? 18,
      ageMax: currentUser.ageMax ?? 99,
      maxDistance: currentUser.maxDistance ?? 50,
      interestedIn:
          currentUser.interestedInGenders ?? const ['Male', 'Female', 'Other'],
    );

    // 4. Query nearby users using GeoService with exclusion and filters
    final profiles = await _geoService.queryNearbyUsers(
      center: currentUser.location,
      radiusKm: filters.maxDistance.toDouble(),
      filters: filters,
      excludeUid: uid,
      excludedUids: excludedUids,
      limit: limit,
    );

    return profiles;
  }

  /// Fetches all UIDs that the user has already liked or disliked.
  ///
  /// These UIDs are used to exclude already-swiped profiles from discovery.
  Future<Set<String>> _fetchExcludedUids(String uid) async {
    final excludedUids = <String>{};

    // Fetch liked UIDs
    final likedSnapshot =
        await _firestore.collection('likes').doc(uid).collection('liked').get();

    for (final doc in likedSnapshot.docs) {
      excludedUids.add(doc.id);
    }

    // Fetch disliked UIDs
    final dislikedSnapshot = await _firestore
        .collection('likes')
        .doc(uid)
        .collection('disliked')
        .get();

    for (final doc in dislikedSnapshot.docs) {
      excludedUids.add(doc.id);
    }

    return excludedUids;
  }
}
