import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/models/discovery_filters.dart';
import '../../../core/models/user_profile.dart';
import '../data/geo_service.dart';
import 'filter_screen.dart';

/// Provider for the GeoService instance used across the discover feature.
final geoServiceProvider = Provider<GeoService>((ref) {
  return FirebaseGeoService();
});

/// Enum representing the various states the map screen can be in.
enum MapScreenState {
  loading,
  permissionDenied,
  loaded,
  error,
}

/// Map view screen displaying nearby users as markers on Google Maps.
///
/// Requirements: 11.1, 11.2, 11.3, 11.4, 11.5, 11.6, 11.7
///
/// - Centers on current user's location at zoom appropriate for maxDistance
/// - Renders markers for nearby users (max 50)
/// - Shows profile preview on marker tap
/// - Respects same filters as discover feed
/// - Handles location permission denied state
/// - Refreshes markers on open/return
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with WidgetsBindingObserver {
  GoogleMapController? _mapController;
  MapScreenState _screenState = MapScreenState.loading;
  String? _errorMessage;

  Position? _currentPosition;
  DiscoveryFilters _filters = const DiscoveryFilters();
  List<UserProfile> _nearbyUsers = [];
  Set<Marker> _markers = {};
  UserProfile? _selectedUser;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadMapData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _mapController?.dispose();
    super.dispose();
  }

  /// Refresh markers when the app returns to foreground (Requirement 11.7).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadMapData();
    }
  }

  /// Loads the user's current position, filters, and nearby users.
  Future<void> _loadMapData() async {
    setState(() {
      _screenState = MapScreenState.loading;
      _errorMessage = null;
      _selectedUser = null;
    });

    try {
      final geoService = ref.read(geoServiceProvider);

      // Get current position (throws LocationPermissionDeniedException if denied)
      final position = await geoService.getCurrentPosition();
      _currentPosition = position;

      // Load saved filters
      _filters = await ref.read(savedFiltersProvider.future);

      // Get current user UID for exclusion
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _screenState = MapScreenState.error;
          _errorMessage = 'Not authenticated. Please sign in again.';
        });
        return;
      }

      // Get liked/disliked UIDs for exclusion
      final excludedUids = await _getExcludedUids(user.uid);

      // Query nearby users (Requirement 11.2, 11.4)
      final center = GeoPoint(position.latitude, position.longitude);
      final nearbyUsers = await geoService.queryNearbyUsers(
        center: center,
        radiusKm: _filters.maxDistance.toDouble(),
        filters: _filters,
        excludeUid: user.uid,
        excludedUids: excludedUids,
        limit: 50,
      );

      _nearbyUsers = nearbyUsers;
      _buildMarkers();

      setState(() {
        _screenState = MapScreenState.loaded;
      });

      // Animate camera to current position with appropriate zoom
      _animateToCurrentPosition();
    } on LocationPermissionDeniedException catch (e) {
      setState(() {
        _screenState = MapScreenState.permissionDenied;
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _screenState = MapScreenState.error;
        _errorMessage = 'Failed to load map data. Please try again.';
      });
    }
  }

  /// Fetches UIDs from the current user's liked and disliked collections.
  Future<Set<String>> _getExcludedUids(String uid) async {
    final firestore = FirebaseFirestore.instance;
    final excludedUids = <String>{};

    try {
      final likedDocs = await firestore.collection('likes/$uid/liked').get();
      for (final doc in likedDocs.docs) {
        excludedUids.add(doc.id);
      }

      final dislikedDocs =
          await firestore.collection('likes/$uid/disliked').get();
      for (final doc in dislikedDocs.docs) {
        excludedUids.add(doc.id);
      }
    } catch (_) {
      // If fetching exclusions fails, continue with empty set
    }

    return excludedUids;
  }

  /// Builds Google Maps markers for nearby users (Requirement 11.2).
  void _buildMarkers() {
    final markers = <Marker>{};

    for (final user in _nearbyUsers) {
      final markerId = MarkerId(user.uid);
      markers.add(
        Marker(
          markerId: markerId,
          position: LatLng(user.location.latitude, user.location.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
          onTap: () => _onMarkerTapped(user),
        ),
      );
    }

    _markers = markers;
  }

  /// Called when a user marker is tapped (Requirement 11.3).
  void _onMarkerTapped(UserProfile user) {
    setState(() {
      _selectedUser = user;
    });
  }

  /// Calculates the appropriate zoom level based on max distance radius.
  ///
  /// Uses a logarithmic formula to convert km radius to Google Maps zoom level.
  /// Requirement 11.1: zoom level that fits the user's configured maximum distance.
  double _zoomForRadius(double radiusKm) {
    // Google Maps zoom formula:
    // At zoom 0, the whole world is visible (~40075 km wide at equator)
    // Each zoom level halves the visible area
    // zoom = log2(40075 / (radiusKm * 2)) approximately
    if (radiusKm <= 0) return 15.0;
    final zoom = log(40075.0 / (radiusKm * 2.5)) / log(2);
    return zoom.clamp(2.0, 18.0);
  }

  /// Animates the map camera to the current user's position.
  void _animateToCurrentPosition() {
    if (_currentPosition == null || _mapController == null) return;

    final zoom = _zoomForRadius(_filters.maxDistance.toDouble());
    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target:
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          zoom: zoom,
        ),
      ),
    );
  }

  /// Calculates the distance between the current user and a target user in km.
  double _distanceToUser(UserProfile user) {
    if (_currentPosition == null) return 0;
    final meters = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      user.location.latitude,
      user.location.longitude,
    );
    return meters / 1000.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadMapData,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_screenState) {
      case MapScreenState.loading:
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Finding nearby users...'),
            ],
          ),
        );

      case MapScreenState.permissionDenied:
        return _buildPermissionDeniedState();

      case MapScreenState.error:
        return _buildErrorState();

      case MapScreenState.loaded:
        return _buildMapContent();
    }
  }

  /// Builds the location permission denied UI (Requirement 11.5).
  Widget _buildPermissionDeniedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_off,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Location Access Required',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ??
                  'Location permission is needed to see nearby users on the map.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                await Geolocator.openAppSettings();
              },
              icon: const Icon(Icons.settings),
              label: const Text('Open Settings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4F6D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _loadMapData,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the generic error UI.
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Something went wrong.',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadMapData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4F6D),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the main map UI with markers and optional profile preview.
  Widget _buildMapContent() {
    return Stack(
      children: [
        // Google Map (Requirement 11.1, 11.2)
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _currentPosition != null
                ? LatLng(
                    _currentPosition!.latitude, _currentPosition!.longitude)
                : const LatLng(0, 0),
            zoom: _zoomForRadius(_filters.maxDistance.toDouble()),
          ),
          markers: _markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: true,
          mapToolbarEnabled: false,
          onMapCreated: (controller) {
            _mapController = controller;
          },
          onTap: (_) {
            // Dismiss profile preview when tapping on the map
            if (_selectedUser != null) {
              setState(() => _selectedUser = null);
            }
          },
        ),

        // Empty state message (Requirement 11.6)
        if (_nearbyUsers.isEmpty)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFFFF4F6D)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No users nearby. Try expanding your distance or adjusting filters.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Profile preview card (Requirement 11.3)
        if (_selectedUser != null)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: _buildProfilePreviewCard(_selectedUser!),
          ),
      ],
    );
  }

  /// Builds the profile preview card shown on marker tap (Requirement 11.3).
  Widget _buildProfilePreviewCard(UserProfile user) {
    final distance = _distanceToUser(user);
    final distanceText = distance < 1
        ? '${(distance * 1000).round()} m away'
        : '${distance.toStringAsFixed(1)} km away';

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // User photo
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 72,
                height: 72,
                child: user.photos.isNotEmpty
                    ? Image.network(
                        user.photos.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.person, size: 36),
                        ),
                      )
                    : Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.person, size: 36),
                      ),
              ),
            ),
            const SizedBox(width: 12),

            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${user.name}, ${user.age}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 14,
                        color: Color(0xFFFF4F6D),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        distanceText,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Close button
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () {
                setState(() => _selectedUser = null);
              },
            ),
          ],
        ),
      ),
    );
  }
}
