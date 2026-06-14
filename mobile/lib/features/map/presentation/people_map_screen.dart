import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
  GoogleMapController? _mapController;
  LatLng _center = const LatLng(0, 0);
  bool _loading = true;
  String? _error;
  Set<Marker> _markers = {};
  List<MapPerson> _people = [];
  MapPerson? _selectedPerson;
  String _searchQuery = '';

  // Marker bitmap cache
  final Map<String, BitmapDescriptor> _markerBitmaps = {};

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
        setState(() {
          _error = 'Location services are disabled. Enable them in settings.';
          _loading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _error = 'Location permission denied.';
            _loading = false;
          });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _error =
              'Location permission permanently denied. Enable it in settings.';
          _loading = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );

      setState(() => _center = LatLng(position.latitude, position.longitude));
      await _loadNearbyPeople();
    } catch (e) {
      setState(() {
        _error = 'Could not get your location.';
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

      _people = results.map((json) => MapPerson.fromJson(json)).toList();
      await _buildMarkers();
    } catch (e) {
      debugPrint('[Map] Failed to load nearby people: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ---------- Custom photo markers ----------

  Future<void> _buildMarkers() async {
    final markers = <Marker>{};

    // Current user marker (blue dot)
    markers.add(
      Marker(
        markerId: const MarkerId('current_user'),
        position: _center,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        zIndex: 999,
      ),
    );

    // Build photo markers for each person
    for (final person in _people) {
      BitmapDescriptor icon;
      if (_markerBitmaps.containsKey(person.id)) {
        icon = _markerBitmaps[person.id]!;
      } else {
        icon = await _createPhotoMarker(person);
        _markerBitmaps[person.id] = icon;
      }

      markers.add(
        Marker(
          markerId: MarkerId(person.id),
          position: LatLng(person.latitude, person.longitude),
          icon: icon,
          zIndex: 1,
          onTap: () => setState(() => _selectedPerson = person),
        ),
      );
    }

    if (mounted) setState(() => _markers = markers);
  }

  /// Creates a circular photo marker bitmap from the user's photo URL.
  Future<BitmapDescriptor> _createPhotoMarker(MapPerson person) async {
    const double size = 96;
    const double borderWidth = 4;

    try {
      if (person.photoUrl != null && person.photoUrl!.isNotEmpty) {
        // Download image
        final file = await DefaultCacheManager()
            .getSingleFile(person.photoUrl!)
            .timeout(const Duration(seconds: 5));
        final bytes = await file.readAsBytes();
        final codec = await ui.instantiateImageCodec(
          bytes,
          targetWidth: size.toInt(),
          targetHeight: size.toInt(),
        );
        final frame = await codec.getNextFrame();
        final image = frame.image;

        // Draw circular avatar with border
        final pictureRecorder = ui.PictureRecorder();
        final canvas = Canvas(pictureRecorder);
        final totalSize = size + borderWidth * 2;

        // White circle border
        final borderPaint = Paint()..color = Colors.white;
        canvas.drawCircle(
          Offset(totalSize / 2, totalSize / 2),
          totalSize / 2,
          borderPaint,
        );

        // Clip to circle and draw image
        final clipPath = Path()
          ..addOval(Rect.fromCircle(
            center: Offset(totalSize / 2, totalSize / 2),
            radius: size / 2,
          ));
        canvas.clipPath(clipPath);
        canvas.drawImageRect(
          image,
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
          Rect.fromLTWH(borderWidth, borderWidth, size, size),
          Paint(),
        );

        // Verified badge (small teal dot at bottom right)
        if (person.isVerified) {
          canvas.restore();
          final badgePaint = Paint()..color = const Color(0xFF00BFA5);
          canvas.drawCircle(
            Offset(totalSize - 12, totalSize - 12),
            8,
            badgePaint,
          );
          final checkPaint = Paint()
            ..color = Colors.white
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke;
          canvas.drawLine(
            Offset(totalSize - 15, totalSize - 12),
            Offset(totalSize - 12, totalSize - 9),
            checkPaint,
          );
          canvas.drawLine(
            Offset(totalSize - 12, totalSize - 9),
            Offset(totalSize - 8, totalSize - 15),
            checkPaint,
          );
        }

        final picture = pictureRecorder.endRecording();
        final markerImage = await picture.toImage(
          totalSize.toInt(),
          totalSize.toInt(),
        );
        final byteData =
            await markerImage.toByteData(format: ui.ImageByteFormat.png);

        if (byteData != null) {
          return BitmapDescriptor.bytes(byteData.buffer.asUint8List());
        }
      }
    } catch (e) {
      debugPrint('[Map] Failed to create photo marker for ${person.id}: $e');
    }

    // Fallback: colored initial marker
    return await _createInitialMarker(person);
  }

  /// Creates a circular marker with the user's initial letter as fallback.
  Future<BitmapDescriptor> _createInitialMarker(MapPerson person) async {
    const double size = 96;
    const double borderWidth = 4;
    final totalSize = size + borderWidth * 2;

    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);

    // White border
    canvas.drawCircle(
      Offset(totalSize / 2, totalSize / 2),
      totalSize / 2,
      Paint()..color = Colors.white,
    );

    // Rose background
    canvas.drawCircle(
      Offset(totalSize / 2, totalSize / 2),
      size / 2,
      Paint()..color = const Color(0xFFFF4F6D),
    );

    // Letter
    final textPainter = TextPainter(
      text: TextSpan(
        text: person.displayName.isNotEmpty
            ? person.displayName[0].toUpperCase()
            : '?',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 38,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (totalSize - textPainter.width) / 2,
        (totalSize - textPainter.height) / 2,
      ),
    );

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(totalSize.toInt(), totalSize.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData != null) {
      return BitmapDescriptor.bytes(byteData.buffer.asUint8List());
    }

    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose);
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

  // ---------- UI ----------

  @override
  void dispose() {
    _mapController?.dispose();
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
        // Google Map
        GoogleMap(
          initialCameraPosition: CameraPosition(target: _center, zoom: 14),
          markers: _markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: false,
          onMapCreated: (controller) {
            _mapController = controller;
            if (isDark) _setDarkMapStyle(controller);
          },
          onTap: (_) => setState(() => _selectedPerson = null),
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
                            color: Colors.black.withOpacity(0.15),
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
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: TextField(
                        onChanged: (v) => setState(() => _searchQuery = v),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Search people...',
                          hintStyle: TextStyle(color: Colors.white54),
                          prefixIcon: Icon(Icons.search,
                              color: Colors.white54, size: 20),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Filter chips
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _FilterChip(
                      icon: Icons.location_on,
                      label: 'All People',
                      isActive: true,
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
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
                _mapController?.animateCamera(
                  CameraUpdate.newLatLng(
                      LatLng(person.latitude, person.longitude)),
                );
              },
            ),
          ),

        // My location button
        Positioned(
          bottom: _selectedPerson != null ? 200 : 160,
          right: 16,
          child: FloatingActionButton.small(
            heroTag: 'my_location',
            backgroundColor: isDark ? YaaroColors.surface : Colors.white,
            onPressed: () {
              _mapController?.animateCamera(
                CameraUpdate.newLatLng(_center),
              );
            },
            child: Icon(Icons.my_location,
                color: isDark ? Colors.white : const Color(0xFF1B2140)),
          ),
        ),
      ],
    );
  }

  Future<void> _setDarkMapStyle(GoogleMapController controller) async {
    const darkStyle = '''
    [
      {"elementType":"geometry","stylers":[{"color":"#212121"}]},
      {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
      {"elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
      {"elementType":"labels.text.stroke","stylers":[{"color":"#212121"}]},
      {"featureType":"administrative","elementType":"geometry","stylers":[{"color":"#757575"}]},
      {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#181818"}]},
      {"featureType":"road","elementType":"geometry.fill","stylers":[{"color":"#2c2c2c"}]},
      {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#8a8a8a"}]},
      {"featureType":"water","elementType":"geometry","stylers":[{"color":"#000000"}]}
    ]
    ''';
    // ignore deprecation — mapStyle param on GoogleMap not yet stable
    // ignore: deprecated_member_use
    await controller.setMapStyle(darkStyle);
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
        color:
            isActive ? const Color(0xFF1B2140) : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isActive ? Colors.transparent : Colors.black12,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4),
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
            color: Colors.black.withOpacity(0.12),
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
                    color: YaaroColors.rose.withOpacity(0.1),
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
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.05),
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
      color: YaaroColors.rose.withOpacity(0.2),
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
              ? YaaroColors.surface.withOpacity(0.92)
              : Colors.white.withOpacity(0.92),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8),
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
                    ? YaaroColors.surface.withOpacity(0.92)
                    : Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.08), blurRadius: 6),
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
                                color: YaaroColors.rose.withOpacity(0.2),
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
                              color: YaaroColors.rose.withOpacity(0.2),
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
