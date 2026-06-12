import 'package:appinio_swiper/appinio_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/user_profile.dart';
import '../../auth/providers/auth_providers.dart';
import '../../discover/data/geo_service.dart';
import '../data/swipe_service.dart';

// --- Providers ---

/// Provides the [GeoService] singleton.
final geoServiceProvider = Provider<GeoService>((ref) {
  return FirebaseGeoService();
});

/// Provides the [SwipeService] backed by Firestore and GeoService.
final swipeServiceProvider = Provider<SwipeService>((ref) {
  final geoService = ref.watch(geoServiceProvider);
  return FirestoreSwipeService(geoService: geoService);
});

/// State notifier that manages the swipe card deck profiles.
final swipeDeckProvider =
    StateNotifierProvider<SwipeDeckNotifier, SwipeDeckState>((ref) {
  return SwipeDeckNotifier(ref);
});

// --- State ---

enum SwipeDeckStatus { loading, loaded, empty, error }

class SwipeDeckState {
  final List<UserProfile> profiles;
  final SwipeDeckStatus status;
  final String? errorMessage;

  const SwipeDeckState({
    this.profiles = const [],
    this.status = SwipeDeckStatus.loading,
    this.errorMessage,
  });

  SwipeDeckState copyWith({
    List<UserProfile>? profiles,
    SwipeDeckStatus? status,
    String? errorMessage,
  }) {
    return SwipeDeckState(
      profiles: profiles ?? this.profiles,
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }
}

// --- Notifier ---

class SwipeDeckNotifier extends StateNotifier<SwipeDeckState> {
  final Ref _ref;

  SwipeDeckNotifier(this._ref) : super(const SwipeDeckState()) {
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    final user = _ref.read(authStateProvider).value;
    if (user == null) {
      state = state.copyWith(
        status: SwipeDeckStatus.error,
        errorMessage: 'Not authenticated',
      );
      return;
    }

    state = state.copyWith(status: SwipeDeckStatus.loading);

    try {
      final swipeService = _ref.read(swipeServiceProvider);
      final profiles =
          await swipeService.fetchEligibleProfiles(user.uid, limit: 10);

      if (profiles.isEmpty) {
        state = state.copyWith(
          profiles: [],
          status: SwipeDeckStatus.empty,
        );
      } else {
        state = state.copyWith(
          profiles: profiles,
          status: SwipeDeckStatus.loaded,
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: SwipeDeckStatus.error,
        errorMessage: 'Failed to load profiles. Please try again.',
      );
    }
  }

  /// Called when the user swipes right (like).
  Future<void> onLike(int index) async {
    final user = _ref.read(authStateProvider).value;
    if (user == null) return;

    final profile = state.profiles[index];

    try {
      final swipeService = _ref.read(swipeServiceProvider);
      await swipeService.like(user.uid, profile.uid);
      _removeCard(index);
    } on SwipeWriteException catch (e) {
      // Keep card in stack and show error
      state = state.copyWith(errorMessage: e.message);
    }
  }

  /// Called when the user swipes left (dislike).
  Future<void> onDislike(int index) async {
    final user = _ref.read(authStateProvider).value;
    if (user == null) return;

    final profile = state.profiles[index];

    try {
      final swipeService = _ref.read(swipeServiceProvider);
      await swipeService.dislike(user.uid, profile.uid);
      _removeCard(index);
    } on SwipeWriteException catch (e) {
      // Keep card in stack and show error
      state = state.copyWith(errorMessage: e.message);
    }
  }

  /// Called when the user taps the super-like button.
  Future<void> onSuperLike() async {
    if (state.profiles.isEmpty) return;

    final user = _ref.read(authStateProvider).value;
    if (user == null) return;

    final profile = state.profiles.first;

    try {
      final swipeService = _ref.read(swipeServiceProvider);
      await swipeService.like(user.uid, profile.uid, superLike: true);
      _removeCard(0);
    } on SwipeWriteException catch (e) {
      // Keep card in stack and show error
      state = state.copyWith(errorMessage: e.message);
    }
  }

  /// Removes a card from the deck. Fetches next batch if empty.
  void _removeCard(int index) {
    final updatedProfiles = List<UserProfile>.from(state.profiles)
      ..removeAt(index);

    if (updatedProfiles.isEmpty) {
      state = state.copyWith(
        profiles: [],
        status: SwipeDeckStatus.loading,
      );
      _loadProfiles();
    } else {
      state = state.copyWith(profiles: updatedProfiles);
    }
  }

  /// Retry loading profiles (e.g. after an error).
  Future<void> retry() async {
    await _loadProfiles();
  }

  /// Clears the current error message.
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

// --- UI ---

/// The main swipe screen showing a card deck of eligible profiles.
///
/// Implements:
/// - Card stack with up to 10 cards at a time
/// - Swipe right = like, swipe left = dislike
/// - Super-like button
/// - Error handling: keeps card on write failure
/// - Fetches next batch when stack empties
/// - Empty state when no eligible profiles
/// - Loading state while fetching
class SwipeScreen extends ConsumerStatefulWidget {
  const SwipeScreen({super.key});

  @override
  ConsumerState<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends ConsumerState<SwipeScreen> {
  late AppinioSwiperController _swiperController;

  @override
  void initState() {
    super.initState();
    _swiperController = AppinioSwiperController();
  }

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deckState = ref.watch(swipeDeckProvider);

    // Listen for error messages and show snackbar
    ref.listen<SwipeDeckState>(swipeDeckProvider, (prev, next) {
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Dismiss',
              onPressed: () {
                ref.read(swipeDeckProvider.notifier).clearError();
              },
            ),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        centerTitle: true,
      ),
      body: _buildBody(deckState),
    );
  }

  Widget _buildBody(SwipeDeckState deckState) {
    switch (deckState.status) {
      case SwipeDeckStatus.loading:
        return const _LoadingView();
      case SwipeDeckStatus.error:
        return _ErrorView(
          message: deckState.errorMessage ?? 'Something went wrong',
          onRetry: () => ref.read(swipeDeckProvider.notifier).retry(),
        );
      case SwipeDeckStatus.empty:
        return const _EmptyView();
      case SwipeDeckStatus.loaded:
        return _SwipeCardDeck(
          profiles: deckState.profiles,
          swiperController: _swiperController,
          onSwipeRight: (index) {
            ref.read(swipeDeckProvider.notifier).onLike(index);
          },
          onSwipeLeft: (index) {
            ref.read(swipeDeckProvider.notifier).onDislike(index);
          },
          onSuperLike: () {
            ref.read(swipeDeckProvider.notifier).onSuperLike();
          },
        );
    }
  }
}

// --- Loading View ---

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Finding people nearby...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// --- Error View ---

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Empty State View ---

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No more profiles available',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Check back later or adjust your discovery filters to see more people.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Swipe Card Deck ---

class _SwipeCardDeck extends StatelessWidget {
  final List<UserProfile> profiles;
  final AppinioSwiperController swiperController;
  final void Function(int index) onSwipeRight;
  final void Function(int index) onSwipeLeft;
  final VoidCallback onSuperLike;

  const _SwipeCardDeck({
    required this.profiles,
    required this.swiperController,
    required this.onSwipeRight,
    required this.onSwipeLeft,
    required this.onSuperLike,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: AppinioSwiper(
              controller: swiperController,
              cardCount: profiles.length,
              cardBuilder: (context, index) {
                return _ProfileCard(profile: profiles[index]);
              },
              onSwipeEnd: (previousIndex, targetIndex, activity) {
                if (activity is Swipe) {
                  if (activity.direction == AxisDirection.right) {
                    onSwipeRight(previousIndex);
                  } else if (activity.direction == AxisDirection.left) {
                    onSwipeLeft(previousIndex);
                  }
                }
              },
            ),
          ),
        ),
        _ActionButtons(
          swiperController: swiperController,
          onSuperLike: onSuperLike,
        ),
      ],
    );
  }
}

// --- Action Buttons ---

class _ActionButtons extends StatelessWidget {
  final AppinioSwiperController swiperController;
  final VoidCallback onSuperLike;

  const _ActionButtons({
    required this.swiperController,
    required this.onSuperLike,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Dislike button
          FloatingActionButton(
            heroTag: 'dislike',
            onPressed: () => swiperController.swipeLeft(),
            backgroundColor: Colors.white,
            child: const Icon(Icons.close, color: Colors.red, size: 32),
          ),
          // Super Like button
          FloatingActionButton(
            heroTag: 'superlike',
            onPressed: onSuperLike,
            backgroundColor: Colors.blue,
            child: const Icon(Icons.star, color: Colors.white, size: 28),
          ),
          // Like button
          FloatingActionButton(
            heroTag: 'like',
            onPressed: () => swiperController.swipeRight(),
            backgroundColor: Colors.white,
            child: const Icon(Icons.favorite, color: Colors.green, size: 32),
          ),
        ],
      ),
    );
  }
}

// --- Profile Card ---

class _ProfileCard extends StatelessWidget {
  final UserProfile profile;

  const _ProfileCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final primaryPhoto = profile.photos.isNotEmpty ? profile.photos[0] : null;

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Primary photo
          if (primaryPhoto != null)
            Image.network(
              primaryPhoto,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child:
                      const Icon(Icons.person, size: 100, color: Colors.grey),
                );
              },
            )
          else
            Container(
              color: Colors.grey[300],
              child: const Icon(Icons.person, size: 100, color: Colors.grey),
            ),

          // Gradient overlay for text readability
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // Profile info at the bottom
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name and age
                Text(
                  '${profile.name}, ${profile.age}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                // Bio
                if (profile.bio.isNotEmpty)
                  Text(
                    profile.bio,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
