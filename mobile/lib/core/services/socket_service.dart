import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// Singleton that holds the one and only Socket.IO connection for the app.
///
/// Previously each screen (MatchesScreen, ChatScreen) created its own socket,
/// resulting in 2–3 concurrent connections per session. Now:
///   - AppShell calls [attach] after login to create the connection.
///   - Screens call [on] / [off] to subscribe/unsubscribe to specific events.
///   - AppShell calls [detach] on logout / dispose.
///
/// ChatScreen still creates its own socket for the chat room because it needs
/// to join a specific match room and handle typed/read-receipt events that are
/// scoped to that room. Future work: pass this singleton into ChatScreen and
/// emit join_match on it.
class SocketService {
  SocketService._();
  static final SocketService instance = SocketService._();

  io.Socket? _socket;

  /// Whether the socket is currently connected.
  bool get isConnected => _socket?.connected ?? false;

  /// Attach an already-created socket. Called by AppShell after login.
  void attach(io.Socket socket) {
    _socket = socket;
  }

  /// Disconnect and clear the socket. Called by AppShell on logout / dispose.
  void detach() {
    try {
      _socket?.clearListeners();
      _socket?.disconnect();
    } catch (_) {}
    _socket = null;
  }

  /// Subscribe to a socket event.
  ///
  /// Returns a [StreamController] whose stream emits event payloads.
  /// Call [cancel] on the returned [StreamSubscription] when done.
  StreamSubscription<dynamic> on(
    String event,
    void Function(dynamic data) handler,
  ) {
    final controller = StreamController<dynamic>.broadcast();
    void socketHandler(dynamic data) => controller.add(data);
    _socket?.on(event, socketHandler);

    final sub = controller.stream.listen(handler);

    // When the caller cancels the subscription, also remove the socket listener
    // to prevent memory leaks and ghost callbacks.
    return _SocketSubscription(
      inner: sub,
      onCancel: () {
        _socket?.off(event, socketHandler);
        controller.close();
      },
    );
  }

  /// Emit an event. No-op if not connected.
  void emit(String event, [dynamic data]) {
    _socket?.emit(event, data);
  }
}

/// Wraps an inner [StreamSubscription] and calls [onCancel] when cancelled,
/// so we can clean up the socket listener at the same time.
class _SocketSubscription implements StreamSubscription<dynamic> {
  _SocketSubscription({required this.inner, required this.onCancel});

  final StreamSubscription<dynamic> inner;
  final void Function() onCancel;

  @override
  Future<void> cancel() {
    onCancel();
    return inner.cancel();
  }

  @override
  void onData(void Function(dynamic data)? handleData) =>
      inner.onData(handleData);

  @override
  void onError(Function? handleError) => inner.onError(handleError);

  @override
  void onDone(void Function()? handleDone) => inner.onDone(handleDone);

  @override
  void pause([Future<void>? resumeSignal]) => inner.pause(resumeSignal);

  @override
  void resume() => inner.resume();

  @override
  bool get isPaused => inner.isPaused;

  @override
  Future<E> asFuture<E>([E? futureValue]) => inner.asFuture(futureValue);
}
