import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/models/favorite_document.dart';

/// Exception thrown when a favorites operation fails.
class FavoritesException implements Exception {
  final String message;
  const FavoritesException(this.message);

  @override
  String toString() => 'FavoritesException: $message';
}

/// Abstract interface for managing user favorites.
///
/// Favorites are stored at `users/{uid}/favorites/{targetUid}` in Firestore.
abstract class FavoritesService {
  /// Saves a profile to the user's favorites list.
  ///
  /// Creates a document at `users/{uid}/favorites/{targetUid}` with the
  /// target user's basic info and a timestamp.
  ///
  /// Throws [FavoritesException] if the write fails.
  Future<void> addFavorite({
    required String uid,
    required String targetUid,
    required String name,
    required String primaryPhotoUrl,
    required int age,
  });

  /// Removes a profile from the user's favorites list.
  ///
  /// Deletes the document at `users/{uid}/favorites/{targetUid}`.
  ///
  /// Throws [FavoritesException] if the delete fails.
  Future<void> removeFavorite({
    required String uid,
    required String targetUid,
  });

  /// Returns a real-time stream of the user's favorites ordered by
  /// savedAt descending, limited to 100 documents.
  Stream<List<FavoriteDocument>> watchFavorites(String uid);

  /// Checks whether a specific profile is in the user's favorites.
  Future<bool> isFavorited({
    required String uid,
    required String targetUid,
  });
}

/// Firestore-backed implementation of [FavoritesService].
class FirestoreFavoritesService implements FavoritesService {
  final FirebaseFirestore _firestore;

  FirestoreFavoritesService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _favoritesCollection(String uid) {
    return _firestore.collection('users').doc(uid).collection('favorites');
  }

  @override
  Future<void> addFavorite({
    required String uid,
    required String targetUid,
    required String name,
    required String primaryPhotoUrl,
    required int age,
  }) async {
    final favorite = FavoriteDocument(
      targetUid: targetUid,
      name: name,
      primaryPhotoUrl: primaryPhotoUrl,
      age: age,
      savedAt: DateTime.now(),
    );

    try {
      await _favoritesCollection(uid)
          .doc(targetUid)
          .set(favorite.toFirestore());
    } catch (e) {
      throw FavoritesException('Failed to save favorite: ${e.toString()}');
    }
  }

  @override
  Future<void> removeFavorite({
    required String uid,
    required String targetUid,
  }) async {
    try {
      await _favoritesCollection(uid).doc(targetUid).delete();
    } catch (e) {
      throw FavoritesException('Failed to remove favorite: ${e.toString()}');
    }
  }

  @override
  Stream<List<FavoriteDocument>> watchFavorites(String uid) {
    return _favoritesCollection(uid)
        .orderBy('savedAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return FavoriteDocument.fromFirestore(doc);
      }).toList();
    });
  }

  @override
  Future<bool> isFavorited({
    required String uid,
    required String targetUid,
  }) async {
    final doc = await _favoritesCollection(uid).doc(targetUid).get();
    return doc.exists;
  }
}
