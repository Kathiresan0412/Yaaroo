import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/chat_message.dart';
import '../data/chat_service.dart';

/// Provides the [FirestoreChatService] singleton instance.
final chatServiceProvider = Provider<ChatService>((ref) {
  return FirestoreChatService();
});

/// Real-time stream of chat messages for a given match.
///
/// Accepts a [matchId] parameter and returns messages ordered by timestamp
/// ascending. Riverpod's [AsyncValue] natively exposes loading, data, and
/// error states. Consumers can call `ref.invalidate(chatMessagesProvider(matchId))`
/// to retry on error.
///
/// If Firestore does not respond within 10 seconds, the provider transitions
/// to an error state (Requirement 17.5).
///
/// Validates: Requirements 17.5
final chatMessagesProvider =
    StreamProvider.family<List<ChatMessage>, String>((ref, matchId) {
  final controller = StreamController<List<ChatMessage>>();

  // Set up a 10-second timeout. If no data arrives within this window,
  // emit a timeout error.
  Timer? timeoutTimer = Timer(const Duration(seconds: 10), () {
    if (!controller.isClosed) {
      controller.addError(
        TimeoutException(
          'Chat messages did not load within 10 seconds. Please check your connection.',
          const Duration(seconds: 10),
        ),
      );
    }
  });

  final subscription =
      ref.read(chatServiceProvider).watchMessages(matchId).listen(
    (messages) {
      timeoutTimer?.cancel();
      timeoutTimer = null;
      if (!controller.isClosed) {
        controller.add(messages);
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
