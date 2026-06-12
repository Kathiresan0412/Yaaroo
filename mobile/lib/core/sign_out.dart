import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/providers/auth_providers.dart';
import '../features/chat/providers/chat_providers.dart';
import '../features/discover/presentation/filter_screen.dart';
import '../features/favorites/providers/favorites_providers.dart';
import '../features/matches/providers/match_providers.dart';
import '../features/notifications/providers/notification_providers.dart';
import '../features/swipe/presentation/swipe_screen.dart';

/// Centralized sign-out function that:
/// 1. Calls [FirebaseAuth.instance.signOut()] to clear the Firebase session
/// 2. Invalidates/resets all Riverpod providers holding user-specific state
///
/// This ensures no cached user data remains in memory after sign-out
/// (Requirement 17.6).
///
/// Usage from a widget:
/// ```dart
/// final container = ProviderScope.containerOf(context);
/// await signOutAndResetProviders(container);
/// ```
///
/// Usage from a ref (e.g., inside a provider or notifier):
/// ```dart
/// await signOutAndResetProviders(ref);
/// ```
Future<void> signOutAndResetProviders(dynamic refOrContainer) async {
  // 1. Sign out from Firebase Auth
  await FirebaseAuth.instance.signOut();

  // 2. Invalidate all user-specific providers to reset them to initial state
  if (refOrContainer is WidgetRef) {
    _invalidateAll(refOrContainer);
  } else if (refOrContainer is Ref) {
    _invalidateAllFromRef(refOrContainer);
  } else if (refOrContainer is ProviderContainer) {
    _invalidateAllFromContainer(refOrContainer);
  }
}

/// Invalidates all user-specific providers using a [WidgetRef].
void _invalidateAll(WidgetRef ref) {
  // Auth state will automatically update via authStateChanges() stream
  ref.invalidate(authStateProvider);

  // Profile
  ref.invalidate(profileCompleteProvider);
  // Note: userProfileProvider is a .family provider; invalidating the
  // authStateProvider will cause dependent providers to rebuild with null user.

  // Matches
  ref.invalidate(matchesProvider);

  // Chat — family providers are invalidated when matches are cleared and
  // screens referencing them are disposed. Explicit invalidation for safety.
  ref.invalidate(chatMessagesProvider);

  // Swipe deck
  ref.invalidate(swipeDeckProvider);

  // Favorites
  ref.invalidate(favoritesProvider);

  // Discovery filters
  ref.invalidate(savedFiltersProvider);

  // Notifications
  ref.invalidate(notificationInitProvider);
}

/// Invalidates all user-specific providers using a [Ref].
void _invalidateAllFromRef(Ref ref) {
  ref.invalidate(authStateProvider);
  ref.invalidate(profileCompleteProvider);
  ref.invalidate(matchesProvider);
  ref.invalidate(chatMessagesProvider);
  ref.invalidate(swipeDeckProvider);
  ref.invalidate(favoritesProvider);
  ref.invalidate(savedFiltersProvider);
  ref.invalidate(notificationInitProvider);
}

/// Invalidates all user-specific providers using a [ProviderContainer].
void _invalidateAllFromContainer(ProviderContainer container) {
  container.invalidate(authStateProvider);
  container.invalidate(profileCompleteProvider);
  container.invalidate(matchesProvider);
  container.invalidate(chatMessagesProvider);
  container.invalidate(swipeDeckProvider);
  container.invalidate(favoritesProvider);
  container.invalidate(savedFiltersProvider);
  container.invalidate(notificationInitProvider);
}

/// Riverpod provider exposing the centralized sign-out + provider reset action.
///
/// Usage: `await ref.read(signOutAndResetProvider)(ref);`
///
/// This replaces the simpler [signOutProvider] from auth_providers.dart with
/// full provider invalidation (Requirement 17.6).
final signOutAndResetProvider = Provider<Future<void> Function(Ref ref)>((ref) {
  return (Ref callerRef) async {
    await signOutAndResetProviders(callerRef);
  };
});
