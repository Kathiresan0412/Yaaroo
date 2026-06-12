import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/favorite_document.dart';
import '../../../main.dart' show YaaroColors;
import '../../auth/providers/auth_providers.dart';
import '../data/favorites_service.dart';
import '../providers/favorites_providers.dart';

/// Screen displaying the user's favorited profiles.
///
/// Shows profiles ordered by savedAt descending (max 100).
/// Allows removing favorites with error handling via SnackBar.
///
/// Requirements: 16.1, 16.2, 16.3, 16.4, 16.5
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
      ),
      body: favoritesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, _) => _buildErrorState(context, ref, error),
        data: (favorites) => _buildFavoritesList(context, ref, favorites),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: YaaroColors.rose,
            ),
            const SizedBox(height: 12),
            Text(
              'Failed to load favorites',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: YaaroColors.textFor(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: YaaroColors.mutedFor(context),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => ref.invalidate(favoritesProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesList(
    BuildContext context,
    WidgetRef ref,
    List<FavoriteDocument> favorites,
  ) {
    if (favorites.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_border,
              size: 64,
              color: YaaroColors.mutedFor(context),
            ),
            const SizedBox(height: 16),
            Text(
              'No favorites yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: YaaroColors.textFor(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Profiles you save will appear here.',
              style: TextStyle(
                fontSize: 14,
                color: YaaroColors.mutedFor(context),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final favorite = favorites[index];
        return _FavoriteListTile(
          favorite: favorite,
          onRemove: () => _removeFavorite(context, ref, favorite),
        );
      },
    );
  }

  Future<void> _removeFavorite(
    BuildContext context,
    WidgetRef ref,
    FavoriteDocument favorite,
  ) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    try {
      await ref.read(favoritesServiceProvider).removeFavorite(
            uid: user.uid,
            targetUid: favorite.targetUid,
          );
    } on FavoritesException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove favorite: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// A single tile representing a favorited profile.
class _FavoriteListTile extends StatelessWidget {
  const _FavoriteListTile({
    required this.favorite,
    required this.onRemove,
  });

  final FavoriteDocument favorite;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 28,
        backgroundImage: NetworkImage(favorite.primaryPhotoUrl),
        backgroundColor: YaaroColors.surfaceAltFor(context),
      ),
      title: Text(
        favorite.name,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: YaaroColors.textFor(context),
        ),
      ),
      subtitle: Text(
        '${favorite.age} years old',
        style: TextStyle(
          color: YaaroColors.mutedFor(context),
        ),
      ),
      trailing: IconButton(
        onPressed: onRemove,
        icon: const Icon(
          Icons.favorite,
          color: YaaroColors.rose,
        ),
        tooltip: 'Remove from favorites',
      ),
    );
  }
}

/// A toggle button widget that can be used on profile views to show
/// whether a profile is already favorited and to add/remove favorites.
///
/// Requirements: 16.4, 16.5
class FavoriteToggleButton extends ConsumerStatefulWidget {
  const FavoriteToggleButton({
    required this.targetUid,
    required this.targetName,
    required this.targetPhotoUrl,
    required this.targetAge,
    super.key,
  });

  final String targetUid;
  final String targetName;
  final String targetPhotoUrl;
  final int targetAge;

  @override
  ConsumerState<FavoriteToggleButton> createState() =>
      _FavoriteToggleButtonState();
}

class _FavoriteToggleButtonState extends ConsumerState<FavoriteToggleButton> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final isFavoritedAsync = ref.watch(isFavoritedProvider(widget.targetUid));

    return isFavoritedAsync.when(
      loading: () => const IconButton(
        onPressed: null,
        icon: Icon(Icons.favorite_border),
      ),
      error: (_, __) => IconButton(
        onPressed: () => _toggleFavorite(false),
        icon: const Icon(Icons.favorite_border),
      ),
      data: (isFavorited) => IconButton(
        onPressed: _isProcessing ? null : () => _toggleFavorite(isFavorited),
        icon: Icon(
          isFavorited ? Icons.favorite : Icons.favorite_border,
          color: isFavorited ? YaaroColors.rose : null,
        ),
        tooltip: isFavorited ? 'Remove from favorites' : 'Add to favorites',
      ),
    );
  }

  Future<void> _toggleFavorite(bool currentlyFavorited) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    setState(() => _isProcessing = true);

    try {
      final service = ref.read(favoritesServiceProvider);
      if (currentlyFavorited) {
        await service.removeFavorite(
          uid: user.uid,
          targetUid: widget.targetUid,
        );
      } else {
        await service.addFavorite(
          uid: user.uid,
          targetUid: widget.targetUid,
          name: widget.targetName,
          primaryPhotoUrl: widget.targetPhotoUrl,
          age: widget.targetAge,
        );
      }
      // Invalidate the provider to refresh the state
      ref.invalidate(isFavoritedProvider(widget.targetUid));
      ref.invalidate(favoritesProvider);
    } on FavoritesException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Operation failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}
