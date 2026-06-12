import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/sign_out.dart';
import '../data/firebase_auth_service.dart';

// Re-export profile providers so existing imports from this file continue to work.
export '../../profile/providers/profile_providers.dart';

/// Provides the [FirebaseAuthServiceImpl] singleton instance.
final authServiceProvider = Provider<FirebaseAuthServiceImpl>((ref) {
  return FirebaseAuthServiceImpl();
});

/// Streams the current Firebase Auth user (null when signed out).
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// Exposes a sign-out action that clears the Firebase session and resets
/// all Riverpod providers to their initial unauthenticated state.
///
/// This ensures no cached user data remains in memory after sign-out
/// (Requirement 17.6).
///
/// Usage: `await ref.read(signOutProvider)();`
final signOutProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    await signOutAndResetProviders(ref);
  };
});
