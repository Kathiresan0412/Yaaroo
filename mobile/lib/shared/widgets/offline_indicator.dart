import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/connectivity_service.dart';

/// A banner widget that displays an offline indicator at the top of the screen.
///
/// This widget should be included in all screens to satisfy requirement 20.1:
/// "SHALL display an offline indicator visible on all screens."
///
/// Uses [connectivityStatusProvider] to reactively show/hide the banner.
class OfflineIndicatorBanner extends ConsumerWidget {
  const OfflineIndicatorBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityAsync = ref.watch(connectivityStatusProvider);

    return connectivityAsync.when(
      data: (status) {
        if (status == ConnectivityStatus.online) {
          return const SizedBox.shrink();
        }
        return _OfflineBanner();
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFFFF6B35),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            const Text(
              'You are offline',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFFFD700),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A scaffold wrapper that automatically includes the offline indicator.
///
/// Use this instead of [Scaffold] to automatically include the offline
/// indicator on all screens. The banner appears above the body content.
class OfflineAwareScaffold extends ConsumerWidget {
  const OfflineAwareScaffold({
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.backgroundColor,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    super.key,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;
  final bool extendBody;
  final bool extendBodyBehindAppBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      backgroundColor: backgroundColor,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      body: Column(
        children: [
          const OfflineIndicatorBanner(),
          Expanded(child: body),
        ],
      ),
    );
  }
}

/// A utility mixin for gating server-required actions when offline.
///
/// Usage:
/// ```dart
/// class MyScreen extends ConsumerWidget with OfflineActionGate {
///   void _onCallPressed(BuildContext context, WidgetRef ref) {
///     if (isOffline(ref)) {
///       showOfflineMessage(context, 'Making calls');
///       return;
///     }
///     // ... proceed with call
///   }
/// }
/// ```
mixin OfflineActionGate {
  /// Returns true if the device is currently offline.
  bool isOffline(WidgetRef ref) {
    return !ref.read(isOnlineProvider);
  }

  /// Shows a snackbar indicating that the action requires a network connection.
  ///
  /// Satisfies requirement 20.2: "SHALL display a message indicating that
  /// the action requires a network connection."
  void showOfflineMessage(BuildContext context, String actionName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.cloud_off, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$actionName requires a network connection. '
                'Please check your internet and try again.',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFFF6B35),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

/// Static utility for checking offline status and showing messages.
///
/// Use this for places where a mixin isn't practical.
class OfflineGuard {
  const OfflineGuard._();

  /// Returns true if the device is currently offline.
  static bool isOffline(WidgetRef ref) {
    return !ref.read(isOnlineProvider);
  }

  /// Shows an offline action message. Returns true if offline (action blocked).
  static bool guardAction(
      BuildContext context, WidgetRef ref, String actionName) {
    if (!ref.read(isOnlineProvider)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.cloud_off, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$actionName requires a network connection. '
                  'Please check your internet and try again.',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFFF6B35),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      return true;
    }
    return false;
  }
}
