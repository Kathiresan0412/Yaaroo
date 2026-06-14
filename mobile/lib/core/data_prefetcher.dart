import 'dart:async';
import 'api_client.dart';
import '../main.dart'
    show DiscoveryProfile, ExploreCategory, VibeQuestion, MatchItem;

/// Prefetches data for all main tabs in parallel right after login.
///
/// This avoids N sequential API calls as users navigate tabs, reducing
/// server load spikes and improving perceived performance for 500k+
/// concurrent users.
///
/// Screens should call [consume*] methods to get prefetched data (returns
/// null if not ready or already consumed). If null, they fall back to their
/// normal fetch.
class DataPrefetcher {
  DataPrefetcher._();
  static final DataPrefetcher instance = DataPrefetcher._();

  // --- Prefetch state ---
  bool _prefetching = false;

  // Discover
  List<DiscoveryProfile>? _discoverProfiles;
  bool _discoverReady = false;

  // Explore
  List<ExploreCategory>? _exploreCategories;
  List<DiscoveryProfile>? _exploreNearby;
  VibeQuestion? _exploreVibe;
  bool _exploreReady = false;

  // Matches
  List<MatchItem>? _matches;
  Map<String, dynamic>? _likesPayload;
  bool _matchesReady = false;

  // Chat (conversations)
  List<MatchItem>? _conversations;
  bool _chatReady = false;

  // Profile photos
  List<dynamic>? _profilePhotos;
  bool _profileReady = false;

  /// Whether a prefetch is currently in progress.
  bool get isPrefetching => _prefetching;

  /// Fire all prefetch calls in parallel. Call this immediately after
  /// successful login / token restore.
  Future<void> prefetchAll(ApiClient api) async {
    if (_prefetching) return;
    _prefetching = true;

    try {
      // Fire all requests in parallel — no await between launches.
      final results = await Future.wait<dynamic>([
        _safeFetch(() => api.discover()), // 0
        _safeFetch(() => api.categories()), // 1
        _safeFetch(() => api.exploreNearby()), // 2
        _safeFetch(() => api.vibeToday()), // 3
        _safeFetch(() => api.matches()), // 4
        _safeFetch(() => api.likesReceivedFull()), // 5
        _safeFetch(() => api.conversations()), // 6
        _safeFetch(() => api.getProfilePhotos()), // 7
      ]);

      _discoverProfiles = results[0] as List<DiscoveryProfile>?;
      _discoverReady = _discoverProfiles != null;

      _exploreCategories = results[1] as List<ExploreCategory>?;
      _exploreNearby = results[2] as List<DiscoveryProfile>?;
      _exploreVibe = results[3] as VibeQuestion?;
      _exploreReady = _exploreCategories != null || _exploreNearby != null;

      _matches = results[4] as List<MatchItem>?;
      _likesPayload = results[5] as Map<String, dynamic>?;
      _matchesReady = _matches != null;

      _conversations = results[6] as List<MatchItem>?;
      _chatReady = _conversations != null;

      _profilePhotos = results[7] as List<dynamic>?;
      _profileReady = _profilePhotos != null;
    } finally {
      _prefetching = false;
    }
  }

  // --- Consume methods (one-shot: returns data then clears it) ---

  /// Returns prefetched discover profiles, or null if not available.
  /// After consuming, returns null on subsequent calls (screen owns the data).
  List<DiscoveryProfile>? consumeDiscover() {
    if (!_discoverReady) return null;
    final data = _discoverProfiles;
    _discoverProfiles = null;
    _discoverReady = false;
    return data;
  }

  /// Returns prefetched explore data, or null if not available.
  ({
    List<ExploreCategory>? categories,
    List<DiscoveryProfile>? nearby,
    VibeQuestion? vibe,
  })? consumeExplore() {
    if (!_exploreReady) return null;
    final data = (
      categories: _exploreCategories,
      nearby: _exploreNearby,
      vibe: _exploreVibe,
    );
    _exploreCategories = null;
    _exploreNearby = null;
    _exploreVibe = null;
    _exploreReady = false;
    return data;
  }

  /// Returns prefetched matches + likes data, or null if not available.
  ({List<MatchItem>? matches, Map<String, dynamic>? likesPayload})?
      consumeMatches() {
    if (!_matchesReady) return null;
    final data = (matches: _matches, likesPayload: _likesPayload);
    _matches = null;
    _likesPayload = null;
    _matchesReady = false;
    return data;
  }

  /// Returns prefetched conversations, or null if not available.
  List<MatchItem>? consumeConversations() {
    if (!_chatReady) return null;
    final data = _conversations;
    _conversations = null;
    _chatReady = false;
    return data;
  }

  /// Returns prefetched profile photos, or null if not available.
  List<dynamic>? consumeProfilePhotos() {
    if (!_profileReady) return null;
    final data = _profilePhotos;
    _profilePhotos = null;
    _profileReady = false;
    return data;
  }

  /// Clear all cached data (call on logout).
  void clear() {
    _prefetching = false;
    _discoverProfiles = null;
    _discoverReady = false;
    _exploreCategories = null;
    _exploreNearby = null;
    _exploreVibe = null;
    _exploreReady = false;
    _matches = null;
    _likesPayload = null;
    _matchesReady = false;
    _conversations = null;
    _chatReady = false;
    _profilePhotos = null;
    _profileReady = false;
  }

  /// Wraps an API call so failures return null instead of throwing.
  Future<T?> _safeFetch<T>(Future<T> Function() fetcher) async {
    try {
      return await fetcher();
    } catch (_) {
      return null;
    }
  }
}
