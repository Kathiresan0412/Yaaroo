import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/match_document.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/match_service.dart';

/// Provides the [FirestoreMatchService] singleton instance.
final matchServiceProvider = Provider<MatchService>((ref) {
  return FirestoreMatchService();
});

/// Real-time stream of matches for the authenticated user.
///
/// Ordered by [lastMessageAt] descending so the most recent conversations
/// appear first. Emits an empty list when the user has no matches or when
/// the user is not authenticated.
///
/// If Firestore does not respond within 10 seconds, the provider transitions
/// to an error state (Requirement 17.5).
///
/// Validates: Requirements 9.3, 17.4, 17.5
final matchesProvider = StreamProvider<List<MatchDocument>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);

  final controller = StreamController<List<MatchDocument>>();

  // Set up a 10-second timeout. If no data arrives within this window,
  // emit a timeout error.
  Timer? timeoutTimer = Timer(const Duration(seconds: 10), () {
    if (!controller.isClosed) {
      controller.addError(
        TimeoutException(
          'Matches did not load within 10 seconds. Please check your connection.',
          const Duration(seconds: 10),
        ),
      );
    }
  });

  final subscription =
      ref.read(matchServiceProvider).watchMatches(user.uid).listen(
    (matches) {
      timeoutTimer?.cancel();
      timeoutTimer = null;
      if (!controller.isClosed) {
        controller.add(matches);
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
