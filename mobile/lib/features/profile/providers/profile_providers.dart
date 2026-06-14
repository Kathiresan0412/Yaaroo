import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/user_profile.dart';

/// Internal provider for auth state - avoids circular import with auth_providers.
/// Uses Firebase Auth directly since we only need the user stream.
final _authStateForProfileProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// Watches the Firestore `users/{uid}` document for the given [uid].
///
/// Returns `null` when the document does not exist (new user, incomplete
/// profile). The stream emits updates in real-time so routing can react
/// immediately when the profile is completed.
///
/// If Firestore does not respond within 10 seconds, the provider transitions
/// to an error state (Requirement 17.5).
final userProfileProvider =
    StreamProvider.family<UserProfile?, String>((ref, uid) {
  final firestore = FirebaseFirestore.instance;

  final controller = StreamController<UserProfile?>();

  // Set up a 10-second timeout timer. If no data arrives within this window,
  // emit a timeout error.
  Timer? timeoutTimer = Timer(const Duration(seconds: 10), () {
    if (!controller.isClosed) {
      controller.addError(
        TimeoutException(
          'Profile data did not load within 10 seconds. Please check your connection.',
          const Duration(seconds: 10),
        ),
      );
    }
  });

  final subscription =
      firestore.collection('users').doc(uid).snapshots().listen(
    (snapshot) {
      // Cancel timeout on first successful data emission.
      timeoutTimer?.cancel();
      timeoutTimer = null;

      if (!snapshot.exists || snapshot.data() == null) {
        controller.add(null);
      } else {
        try {
          controller.add(UserProfile.fromFirestore(snapshot));
        } catch (_) {
          // Document exists but is missing required fields — treat as incomplete.
          controller.add(null);
        }
      }
    },
    onError: (Object error) {
      timeoutTimer?.cancel();
      timeoutTimer = null;
      controller.addError(error);
    },
  );

  ref.onDispose(() {
    timeoutTimer?.cancel();
    subscription.cancel();
    controller.close();
  });

  return controller.stream;
});

/// Checks whether all required profile fields are present and valid.
///
/// Required fields: name (non-empty), age (>0), gender (non-empty),
/// photos (non-empty list), interests (non-empty list).
bool isProfileComplete(UserProfile profile) {
  if (profile.name.trim().isEmpty) return false;
  if (profile.age <= 0) return false;
  if (profile.gender.trim().isEmpty) return false;
  // Photos are optional — no longer required for profile completion
  if (profile.interests.isEmpty) return false;
  return true;
}

/// Determines if the current user's profile has all required fields filled.
///
/// Required fields: name (non-empty), age (>0), gender (non-empty),
/// photos (non-empty list), interests (non-empty list).
///
/// Returns `true` if the profile is complete, `false` otherwise.
/// If the user is not authenticated or the profile is still loading,
/// returns `false`.
final profileCompleteProvider = Provider<bool>((ref) {
  final authState = ref.watch(_authStateForProfileProvider);
  final user = authState.valueOrNull;
  if (user == null) return false;

  final profileAsync = ref.watch(userProfileProvider(user.uid));
  final profile = profileAsync.valueOrNull;
  if (profile == null) return false;

  return isProfileComplete(profile);
});
