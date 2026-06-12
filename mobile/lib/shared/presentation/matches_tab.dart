import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/models/match_document.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/chat/presentation/chat_screen.dart';
import '../../features/matches/providers/match_providers.dart';
import '../../main.dart' show YaaroColors;

/// Matches tab that displays a list of matches and opens ChatScreen on tap.
///
/// Each match list item shows the other user's name, last message, and time.
/// Tapping a match opens the ChatScreen with correct matchId.
///
/// Requirements: 9.3, 17.4, 18.2
class MatchesTab extends ConsumerWidget {
  const MatchesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(matchesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Matches'),
        centerTitle: true,
      ),
      body: matchesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildError(context, ref, error),
        data: (matches) {
          if (matches.isEmpty) {
            return _buildEmpty(context);
          }
          return _buildMatchList(context, ref, matches);
        },
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, Object error) {
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
              'Failed to load matches',
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
              onPressed: () => ref.invalidate(matchesProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: YaaroColors.mutedFor(context),
            ),
            const SizedBox(height: 16),
            Text(
              'No matches yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: YaaroColors.textFor(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start swiping to find your match!',
              style: TextStyle(
                fontSize: 14,
                color: YaaroColors.mutedFor(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchList(
      BuildContext context, WidgetRef ref, List<MatchDocument> matches) {
    final currentUser = ref.watch(authStateProvider).value;
    final currentUid = currentUser?.uid ?? '';

    return ListView.builder(
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final match = matches[index];
        return _MatchListItem(
          match: match,
          currentUid: currentUid,
        );
      },
    );
  }
}

/// A single match list item that loads the other user's profile and
/// navigates to ChatScreen on tap.
class _MatchListItem extends ConsumerWidget {
  const _MatchListItem({
    required this.match,
    required this.currentUid,
  });

  final MatchDocument match;
  final String currentUid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Determine the other user's UID
    final otherUid = match.users.firstWhere(
      (uid) => uid != currentUid,
      orElse: () => '',
    );

    // Watch the other user's profile for name/photo
    final otherProfileAsync = ref.watch(userProfileProvider(otherUid));

    final otherName = otherProfileAsync.whenOrNull(
          data: (profile) => profile?.name,
        ) ??
        'Match';

    final otherPhoto = otherProfileAsync.whenOrNull(
      data: (profile) =>
          (profile?.photos.isNotEmpty ?? false) ? profile!.photos.first : null,
    );

    return ListTile(
      leading: CircleAvatar(
        radius: 28,
        backgroundImage: otherPhoto != null ? NetworkImage(otherPhoto) : null,
        child: otherPhoto == null ? const Icon(Icons.person, size: 28) : null,
      ),
      title: Text(
        otherName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        match.lastMessage ?? 'Tap to start chatting',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: YaaroColors.mutedFor(context),
          fontSize: 13,
        ),
      ),
      trailing: match.lastMessageAt != null
          ? Text(
              _formatTime(match.lastMessageAt!),
              style: TextStyle(
                fontSize: 12,
                color: YaaroColors.mutedFor(context),
              ),
            )
          : null,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              matchId: match.matchId,
              matchName: otherName,
              matchPhotoUrl: otherPhoto,
              targetUid: otherUid,
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(time.year, time.month, time.day);

    if (messageDay == today) {
      return DateFormat.jm().format(time);
    } else if (today.difference(messageDay).inDays == 1) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM d').format(time);
    }
  }
}
