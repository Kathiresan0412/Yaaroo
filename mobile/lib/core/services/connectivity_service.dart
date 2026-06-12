import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Represents the current connectivity state of the device.
enum ConnectivityStatus {
  /// The device has an active internet connection.
  online,

  /// The device has no internet connection.
  offline,
}

/// Service responsible for monitoring device connectivity.
///
/// Uses periodic DNS lookups to determine actual internet reachability
/// rather than just network interface availability.
class ConnectivityService {
  ConnectivityService() {
    _startMonitoring();
  }

  final _statusController = StreamController<ConnectivityStatus>.broadcast();
  ConnectivityStatus _currentStatus = ConnectivityStatus.online;
  Timer? _pollTimer;

  /// Stream of connectivity status changes.
  Stream<ConnectivityStatus> get statusStream => _statusController.stream;

  /// The current connectivity status (synchronous access).
  ConnectivityStatus get currentStatus => _currentStatus;

  /// Whether the device is currently online.
  bool get isOnline => _currentStatus == ConnectivityStatus.online;

  /// Whether the device is currently offline.
  bool get isOffline => _currentStatus == ConnectivityStatus.offline;

  /// Starts periodic connectivity monitoring.
  void _startMonitoring() {
    // Check immediately
    _checkConnectivity();
    // Then poll every 5 seconds
    _pollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkConnectivity(),
    );
  }

  /// Performs a DNS lookup to verify internet connectivity.
  Future<void> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      final hasConnection =
          result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      _updateStatus(
        hasConnection ? ConnectivityStatus.online : ConnectivityStatus.offline,
      );
    } catch (_) {
      _updateStatus(ConnectivityStatus.offline);
    }
  }

  /// Forces a connectivity check and returns the result.
  Future<ConnectivityStatus> checkNow() async {
    await _checkConnectivity();
    return _currentStatus;
  }

  void _updateStatus(ConnectivityStatus newStatus) {
    if (newStatus != _currentStatus) {
      _currentStatus = newStatus;
      _statusController.add(newStatus);
      debugPrint('Connectivity changed: $newStatus');
    }
  }

  /// Dispose resources when the service is no longer needed.
  void dispose() {
    _pollTimer?.cancel();
    _statusController.close();
  }
}

/// Singleton provider for the connectivity service.
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// StreamProvider that emits connectivity status changes.
final connectivityStatusProvider =
    StreamProvider<ConnectivityStatus>((ref) async* {
  final service = ref.watch(connectivityServiceProvider);
  // Emit current status first
  yield service.currentStatus;
  // Then emit changes
  yield* service.statusStream;
});

/// Simple boolean provider for quick "is online?" checks.
final isOnlineProvider = Provider<bool>((ref) {
  final status = ref.watch(connectivityStatusProvider);
  return status.whenOrNull(data: (s) => s == ConnectivityStatus.online) ?? true;
});
