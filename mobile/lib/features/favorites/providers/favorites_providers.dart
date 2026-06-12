import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/favorite_document.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/favorites_service.dart';

/// Provides the [FirestoreFavoritesService] singleton instance.
final favoritesServiceProvider = Provider<FavoritesService>((ref) {
  return FirestoreFavoritesService();
});

/// Real-time stream of favorites for the authenticated user.
///
/// Ordered by [savedAt] descending, limited to 100 favorites.
/// Emits an empty list when the user has no favorites or is not authenticated.
///
/// If Firestore does not respond within 10 seconds, the provider transitions
/// to an error state (Requirement 17.5).
///
/// Validates: Requirements 16.1, 16.3, 17.5
final favoritesProvider = StreamProvider<List<FavoriteDocument>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);

  final controller = StreamController<List<FavoriteDocument>>();

  // Set up a 10-second timeout. If no data arrives within this window,
  // emit a timeout error.
  Timer? timeoutTimer = Timer(const Duration(seconds: 10), () {
    if (!controller.isClosed) {
      controller.addError(
        TimeoutException(
          'Favorites did not load within 10 seconds. Please check your connection.',
          const Duration(seconds: 10),
        ),
      );
    }
  });

  final subscription =
      ref.read(favoritesServiceProvider).watchFavorites(user.uid).listen(
    (favorites) {
      timeoutTimer?.cancel();
      timeoutTimer = null;
      if (!controller.isClosed) {
        controller.add(favorites);
      }
    },
    onError: (Object error) {
      timeoutTimer?.cancel();
      timeoutTimer = null;
      if (!controller.isClosed) {
        controller.addError(error);
      }
    },
  );

  ref.onDispose(() {
    timeoutTimer?.cancel();
    subscription.cancel();
    controller.close();
  });

  return controller.stream;
});

/// Checks if a specific profile is favorited by the current user.
///
/// Returns a [Future<bool>] indicating whether the target user is in
/// the current user's favorites list.
///
/// Validates: Requirements 16.5
final isFavoritedProvider =
    FutureProvider.family<bool, String>((ref, targetUid) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return false;
  return ref
      .read(favoritesServiceProvider)
      .isFavorited(uid: user.uid, targetUid: targetUid);
});
