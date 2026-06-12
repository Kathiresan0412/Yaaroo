import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/chat/presentation/chat_screen.dart';
import '../../features/discover/presentation/map_screen.dart';
import '../../features/favorites/presentation/favorites_screen.dart';
import '../../features/notifications/providers/notification_providers.dart';
import '../../features/swipe/presentation/swipe_screen.dart';
import '../widgets/offline_indicator.dart';
import 'matches_tab.dart';
import 'profile_tab.dart';

/// Provider tracking the currently selected bottom navigation tab index.
final homeTabIndexProvider = StateProvider<int>((ref) => 0);

/// Home screen with bottom tab navigation integrating all major features:
/// - Swipe (Discover)
/// - Matches (with navigation to chat)
/// - Map (nearby users)
/// - Favorites
/// - Profile
///
/// Initializes notification service on first build when user is authenticated.
///
/// Requirements: 17.1, 18.1, 18.2
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize notifications after auth (fires once when HomeScreen loads).
    // This triggers the notificationInitProvider which handles FCM registration.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initNotifications();
    });
  }

  void _initNotifications() {
    // Reading the provider triggers its initialization logic.
    // It watches authStateProvider and initializes FCM when a user is present.
    ref.read(notificationInitProvider);

    // Wire notification tap callback for navigation routing.
    final notificationService = ref.read(notificationServiceProvider);
    notificationService.onNotificationTap = _handleNotificationTap;
  }

  /// Handles notification taps by routing to the correct screen.
  ///
  /// Routes:
  /// - '/match_detail' → Switches to matches tab
  /// - '/chat' → Opens ChatScreen with the matchId from payload
  /// - '/profile' → Switches to profile tab
  ///
  /// Requirements: 15.6
  void _handleNotificationTap(String route, Map<String, dynamic> payload) {
    switch (route) {
      case '/chat':
        final matchId = payload['matchId'] as String?;
        if (matchId != null && mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                matchId: matchId,
                matchName: payload['senderName'] as String? ?? 'Chat',
              ),
            ),
          );
        }
        break;
      case '/match_detail':
        // Navigate to the matches tab
        ref.read(homeTabIndexProvider.notifier).state = 1;
        break;
      case '/profile':
        // Navigate to the profile tab or open the specific user's profile
        final targetUid = payload['targetUid'] as String?;
        if (targetUid != null) {
          // For super_like notifications, switch to swipe tab where profiles are
          ref.read(homeTabIndexProvider.notifier).state = 0;
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTab = ref.watch(homeTabIndexProvider);

    return Scaffold(
      body: Column(
        children: [
          const OfflineIndicatorBanner(),
          Expanded(
            child: IndexedStack(
              index: currentTab,
              children: const [
                SwipeScreen(),
                MatchesTab(),
                MapScreen(),
                FavoritesScreen(),
                ProfileTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentTab,
        onDestinationSelected: (index) {
          ref.read(homeTabIndexProvider.notifier).state = index;
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.local_fire_department_outlined),
            selectedIcon: Icon(Icons.local_fire_department),
            label: 'Discover',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Matches',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
