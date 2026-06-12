import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../data/notification_service.dart';

/// Provides the [FirebaseNotificationService] singleton instance.
final notificationServiceProvider =
    Provider<FirebaseNotificationService>((ref) {
  return FirebaseNotificationService();
});

/// Provider that tracks whether notifications have been initialized for the
/// current user session.
///
/// Returns `true` once initialization is complete, `false` while pending,
/// and an error state if initialization fails.
///
/// Automatically re-initializes when the auth state changes to a new user.
final notificationInitProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return false;

  final service = ref.read(notificationServiceProvider);
  await service.initialize(user.uid);
  return true;
});
