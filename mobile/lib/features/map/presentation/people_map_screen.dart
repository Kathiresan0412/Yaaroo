import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../../main.dart';

// ---------------------------------------------------------------------------
// Data model
// ---------------------------------------------------------------------------

class MapPerson {
  const MapPerson({
    required this.id,
    required this.displayName,
    required this.latitude,
    required this.longitude,
    this.photoUrl,
    this.age,
    this.isVerified = false,
    this.bio,
    this.distanceKm,
    this.interests = const [],
  });

  final String id;
  final String displayName;
  final double latitude;
  final double longitude;
  final String? photoUrl;
  final int? age;
  final bool isVerified;
  final String? bio;
  final double? distanceKm;
  final List<String> interests;

  factory MapPerson.fromJson(Map<String, dynamic> json) {
    final rawInterests = json['interests'];
    final interests = rawInterests is List
        ? rawInterests.map((e) => e.toString()).toList()
        : <String>[];

    return MapPerson(
      id: json['id']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? 'Someone',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      photoUrl: json['photoUrl']?.toString(),
      age: int.tryParse(json['age']?.toString() ?? ''),
      isVerified: json['isVerified'] == true,
      bio: json['bio']?.toString(),
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      interests: interests,
    );
  }

  String get distanceLabel {
    if (distanceKm == null) return 'Nearby';
    if (distanceKm! < 1) return '${(distanceKm! * 1000).round()}m away';
    return '${distanceKm!.round()} km away';
  }
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class PeopleMapScreen extends StatefulWidget {
  const PeopleMapScreen({super.key});

  @override
  State<PeopleMapScreen> createState() => _PeopleMapScreenState();
}

class _PeopleMapScreenState extends State<PeopleMapScreen> {
  final MapController _mapController = MapController();
  LatLng _center = const LatLng(0, 0);
  bool _loading = true;
  String? _error;
  List<MapPerson> _people = [];
  MapPerson? _selectedPerson;
  String _searchQuery = '';

  // Place search
  final TextEditingController _searchController = TextEditingController();
  List<_PlaceResult> _placeResults = [];
  bool _showPlaceResults = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  // ---------- Location ----------

  Future<void> _initLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Fall back to profile location instead of showing error
        await _fallbackToProfileLocation();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          await _fallbackToProfileLocation();
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        await _fallbackToProfileLocation();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );

      setState(() {
        _center = LatLng(position.latitude, position.longitude);
        _loading = false;
      });
      await _loadNearbyPeople();

      // If no people found near GPS location, try profile location
      if (_people.isEmpty) {
        await _fallbackToProfileLocation(keepCenter: false);
      }
    } catch (e) {
      await _fallbackToProfileLocation();
    }
  }

  /// Use the user's stored profile location when GPS doesn't find nearby people.
  Future<void> _fallbackToProfileLocation({bool keepCenter = false}) async {
    try {
      final api = YaaroScope.of(context);
      final profile = await api.getProfileMe();
      final location = profile['location'] as Map<String, dynamic>?;
      if (location != null) {
        final lat = double.tryParse(location['latitude']?.toString() ?? '');
        final lng = double.tryParse(location['longitude']?.toString() ?? '');
        if (lat != null && lng != null) {
          if (!keepCenter || _center.latitude == 0) {
            setState(() {
              _center = LatLng(lat, lng);
              _loading = false;
            });
          }
          // Load people near the profile location
          final results = await api.nearbyForMap(lat: lat, lng: lng);
          if (mounted && results.isNotEmpty) {
            setState(() {
              _people =
                  results.map((json) => MapPerson.fromJson(json)).toList();
              // Center on the profile location if we found people there
              _center = LatLng(lat, lng);
              _loading = false;
            });
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('[Map] Profile location fallback failed: $e');
    }

    if (mounted && _loading) {
      setState(() {
        _error = 'Could not determine your location.';
        _loading = false;
      });
    }
  }

  // ---------- Data ----------

  Future<void> _loadNearbyPeople() async {
    try {
      final api = YaaroScope.of(context);
      final results = await api.nearbyForMap(
        lat: _center.latitude,
        lng: _center.longitude,
      );

      if (mounted) {
        setState(() {
          _people = results.map((json) => MapPerson.fromJson(json)).toList();
        });
      }
    } catch (e) {
      debugPrint('[Map] Failed to load nearby people: $e');
    }
  }

  // ---------- Filtered list ----------

  List<MapPerson> get _filteredPeople {
    if (_searchQuery.isEmpty) return _people;
    final q = _searchQuery.toLowerCase();
    return _people
        .where((p) =>
            p.displayName.toLowerCase().contains(q) ||
            p.interests.any((i) => i.toLowerCase().contains(q)))
        .toList();
  }

  // ---------- Place search (Nominatim - free) ----------

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);

    _debounce?.cancel();
    if (query.trim().length < 2) {
      setState(() {
        _placeResults = [];
        _showPlaceResults = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchPlaces(query.trim());
    });
  }

  Future<void> _searchPlaces(String query) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=5',
      );
      final response = await http.get(uri, headers: {
        'User-Agent': 'YaaRo0-Mobile/1.0',
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _placeResults = data
                .map((item) => _PlaceResult(
                      displayName: item['display_name']?.toString() ?? '',
                      lat: double.tryParse(item['lat']?.toString() ?? '') ?? 0,
                      lon: double.tryParse(item['lon']?.toString() ?? '') ?? 0,
                    ))
                .toList();
            _showPlaceResults = _placeResults.isNotEmpty;
          });
        }
      }
    } catch (e) {
      debugPrint('[Map] Place search failed: $e');
    }
  }

  void _selectPlace(_PlaceResult place) {
    final target = LatLng(place.lat, place.lon);
    _mapController.move(target, 14);
    setState(() {
      _showPlaceResults = false;
      _placeResults = [];
      _searchController.text = place.shortName;
    });
    // Dismiss keyboard
    FocusScope.of(context).unfocus();
  }

  // ---------- Zoom ----------

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom + 1);
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom - 1);
  }

  // ---------- UI ----------

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? YaaroColors.black : const Color(0xFFF2F3F7),
      body: _error != null
          ? _buildError(isDark)
          : _loading
              ? const Center(child: CircularProgressIndicator())
              : _buildMap(isDark),
    );
  }

  Widget _buildError(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _error = null;
                  _loading = true;
                });
                _initLocation();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: YaaroColors.rose,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap(bool isDark) {
    return Stack(
      children: [
        // Flutter Map with OpenStreetMap tiles
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _center,
            initialZoom: 14,
            onTap: (_, __) => setState(() {
              _selectedPerson = null;
              _showPlaceResults = false;
            }),
          ),
          children: [
            TileLayer(
              urlTemplate: isDark
                  ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                  : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: isDark ? const ['a', 'b', 'c', 'd'] : const [],
              userAgentPackageName: 'com.yaaro0.mobile',
            ),
            // Markers layer
            MarkerLayer(
              markers: [
                // Current user marker (blue dot)
                Marker(
                  point: _center,
                  width: 24,
                  height: 24,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withValues(alpha: 0.4),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
                // People markers
                ..._filteredPeople.map((person) => Marker(
                      point: LatLng(person.latitude, person.longitude),
                      width: 52,
                      height: 52,
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedPerson = person),
                        child: _PersonMarker(person: person),
                      ),
                    )),
              ],
            ),
          ],
        ),

        // Top overlay: search bar + filter chips
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 12,
          right: 12,
          child: Column(
            children: [
              // Search bar
              Row(
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: YaaroColors.rose,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.favorite,
                          color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Search field
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E2130)
                            : const Color(0xFF1B2140),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search places or people...',
                          hintStyle: const TextStyle(color: Colors.white54),
                          prefixIcon: const Icon(Icons.search,
                              color: Colors.white54, size: 20),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                      _placeResults = [];
                                      _showPlaceResults = false;
                                    });
                                  },
                                  child: const Icon(Icons.close,
                                      color: Colors.white54, size: 18),
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Place search results dropdown
              if (_showPlaceResults) ...[
                const SizedBox(height: 4),
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2130) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _placeResults.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: isDark ? Colors.white12 : Colors.black12,
                    ),
                    itemBuilder: (_, index) {
                      final place = _placeResults[index];
                      return ListTile(
                        dense: true,
                        leading: Icon(Icons.place,
                            size: 18,
                            color: isDark ? Colors.white54 : YaaroColors.rose),
                        title: Text(
                          place.shortName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color:
                                isDark ? Colors.white : const Color(0xFF111216),
                          ),
                        ),
                        subtitle: Text(
                          place.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white38 : Colors.black45,
                          ),
                        ),
                        onTap: () => _selectPlace(place),
                      );
                    },
                  ),
                ),
              ],
              if (!_showPlaceResults) ...[
                const SizedBox(height: 10),
                // Filter chips
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      const _FilterChip(
                        icon: Icons.location_on,
                        label: 'All People',
                        isActive: true,
                      ),
                      const SizedBox(width: 8),
                      const _FilterChip(
                        icon: Icons.verified,
                        label: 'Verified',
                        isActive: false,
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        icon: Icons.people,
                        label: '${_people.length} Nearby',
                        isActive: false,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // Bottom: person detail card or people count
        if (_selectedPerson != null)
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: _PersonDetailCard(
              person: _selectedPerson!,
              isDark: isDark,
              onClose: () => setState(() => _selectedPerson = null),
              onViewProfile: () {
                // TODO: Navigate to full profile
              },
            ),
          )
        else
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: _PeopleListPreview(
              people: _filteredPeople,
              isDark: isDark,
              onPersonTap: (person) {
                setState(() => _selectedPerson = person);
                _mapController.move(
                  LatLng(person.latitude, person.longitude),
                  _mapController.camera.zoom,
                );
              },
            ),
          ),

        // Right side: Zoom controls + My location
        Positioned(
          bottom: _selectedPerson != null ? 200 : 160,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Zoom In
              _MapButton(
                icon: Icons.add,
                isDark: isDark,
                onTap: _zoomIn,
                heroTag: 'zoom_in',
              ),
              const SizedBox(height: 8),
              // Zoom Out
              _MapButton(
                icon: Icons.remove,
                isDark: isDark,
                onTap: _zoomOut,
                heroTag: 'zoom_out',
              ),
              const SizedBox(height: 8),
              // My location
              _MapButton(
                icon: Icons.my_location,
                isDark: isDark,
                onTap: () {
                  _mapController.move(_center, 14);
                },
                heroTag: 'my_location',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Person Marker Widget
// ---------------------------------------------------------------------------

class _PersonMarker extends StatelessWidget {
  const _PersonMarker({required this.person});

  final MapPerson person;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: person.isVerified ? YaaroColors.teal : Colors.white,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 6,
          ),
        ],
      ),
      child: ClipOval(
        child: person.photoUrl != null && person.photoUrl!.isNotEmpty
            ? Image.network(
                person.photoUrl!,
                fit: BoxFit.cover,
                width: 46,
                height: 46,
                errorBuilder: (_, __, ___) => _buildInitial(),
              )
            : _buildInitial(),
      ),
    );
  }

  Widget _buildInitial() {
    return Container(
      color: YaaroColors.rose.withValues(alpha: 0.2),
      child: Center(
        child: Text(
          person.displayName.isNotEmpty
              ? person.displayName[0].toUpperCase()
              : '?',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: YaaroColors.rose,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter Chip
// ---------------------------------------------------------------------------

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.icon,
    required this.label,
    required this.isActive,
  });

  final IconData icon;
  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFF1B2140)
            : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isActive ? Colors.transparent : Colors.black12,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 14, color: isActive ? Colors.white : YaaroColors.rose),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.white : const Color(0xFF1B2140),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Person Detail Card (shown when tapping a marker)
// ---------------------------------------------------------------------------

class _PersonDetailCard extends StatelessWidget {
  const _PersonDetailCard({
    required this.person,
    required this.isDark,
    required this.onClose,
    required this.onViewProfile,
  });

  final MapPerson person;
  final bool isDark;
  final VoidCallback onClose;
  final VoidCallback onViewProfile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? YaaroColors.surface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Photo
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: YaaroColors.rose, width: 2),
                ),
                child: ClipOval(
                  child: person.photoUrl != null
                      ? Image.network(
                          person.photoUrl!,
                          fit: BoxFit.cover,
                          width: 60,
                          height: 60,
                          errorBuilder: (_, __, ___) => _buildInitialAvatar(),
                        )
                      : _buildInitialAvatar(),
                ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            person.age != null
                                ? '${person.displayName}, ${person.age}'
                                : person.displayName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF111216),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (person.isVerified) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.verified,
                              size: 18, color: YaaroColors.teal),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 14,
                            color: isDark ? Colors.white38 : Colors.black38),
                        const SizedBox(width: 4),
                        Text(
                          person.distanceLabel,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    if (person.bio != null && person.bio!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        person.bio!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Close
              IconButton(
                icon: Icon(Icons.close,
                    color: isDark ? Colors.white38 : Colors.black38, size: 20),
                onPressed: onClose,
              ),
            ],
          ),
          // Interests
          if (person.interests.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 28,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: person.interests.length.clamp(0, 5),
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: YaaroColors.rose.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    person.interests[i],
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: YaaroColors.rose,
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onViewProfile,
                  icon: const Icon(Icons.person, size: 18),
                  label: const Text('View Profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: YaaroColors.rose,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.favorite_border,
                      color: YaaroColors.rose),
                  onPressed: () {
                    // TODO: Like action
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInitialAvatar() {
    return Container(
      width: 60,
      height: 60,
      color: YaaroColors.rose.withValues(alpha: 0.2),
      child: Center(
        child: Text(
          person.displayName.isNotEmpty
              ? person.displayName[0].toUpperCase()
              : '?',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: YaaroColors.rose,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// People List Preview (horizontal scroll at bottom when no person selected)
// ---------------------------------------------------------------------------

class _PeopleListPreview extends StatelessWidget {
  const _PeopleListPreview({
    required this.people,
    required this.isDark,
    required this.onPersonTap,
  });

  final List<MapPerson> people;
  final bool isDark;
  final void Function(MapPerson) onPersonTap;

  @override
  Widget build(BuildContext context) {
    if (people.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? YaaroColors.surface.withValues(alpha: 0.92)
              : Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.08), blurRadius: 8),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.explore,
                color: isDark ? Colors.white54 : Colors.black38),
            const SizedBox(width: 8),
            Text(
              'No people found nearby',
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: people.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, index) {
          final person = people[index];
          return GestureDetector(
            onTap: () => onPersonTap(person),
            child: Container(
              width: 72,
              decoration: BoxDecoration(
                color: isDark
                    ? YaaroColors.surface.withValues(alpha: 0.92)
                    : Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 6),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: person.isVerified
                            ? YaaroColors.teal
                            : YaaroColors.rose,
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: person.photoUrl != null
                          ? Image.network(
                              person.photoUrl!,
                              fit: BoxFit.cover,
                              width: 40,
                              height: 40,
                              errorBuilder: (_, __, ___) => Container(
                                color: YaaroColors.rose.withValues(alpha: 0.2),
                                child: Center(
                                  child: Text(
                                    person.displayName.isNotEmpty
                                        ? person.displayName[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: YaaroColors.rose,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              color: YaaroColors.rose.withValues(alpha: 0.2),
                              child: Center(
                                child: Text(
                                  person.displayName.isNotEmpty
                                      ? person.displayName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: YaaroColors.rose,
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    person.displayName.split(' ').first,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF111216),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Map Button (zoom in/out, my location)
// ---------------------------------------------------------------------------

class _MapButton extends StatelessWidget {
  const _MapButton({
    required this.icon,
    required this.isDark,
    required this.onTap,
    required this.heroTag,
  });

  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark ? YaaroColors.surface : Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 6,
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 20,
          color: isDark ? Colors.white : const Color(0xFF1B2140),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Place Result model (from Nominatim geocoding)
// ---------------------------------------------------------------------------

class _PlaceResult {
  const _PlaceResult({
    required this.displayName,
    required this.lat,
    required this.lon,
  });

  final String displayName;
  final double lat;
  final double lon;

  /// Returns just the first part of the display name (city/town name)
  String get shortName {
    final parts = displayName.split(',');
    if (parts.length >= 2) {
      return '${parts[0].trim()}, ${parts[1].trim()}';
    }
    return parts.first.trim();
  }
}
