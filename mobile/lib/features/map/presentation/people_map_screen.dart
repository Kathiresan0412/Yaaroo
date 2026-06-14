import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../main.dart';

/// Data model for a person visible on the map.
class MapPerson {
  const MapPerson({
    required this.id,
    required this.displayName,
    required this.latitude,
    required this.longitude,
    this.photoUrl,
    this.age,
    this.isVerified = false,
  });

  final String id;
  final String displayName;
  final double latitude;
  final double longitude;
  final String? photoUrl;
  final int? age;
  final bool isVerified;

  factory MapPerson.fromJson(Map<String, dynamic> json) {
    return MapPerson(
      id: json['id']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? 'Someone',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      photoUrl: json['photoUrl']?.toString(),
      age: int.tryParse(json['age']?.toString() ?? ''),
      isVerified: json['isVerified'] == true,
    );
  }
}

/// Full-screen map showing nearby people as markers.
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

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      // Check location services
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _error = 'Location services are disabled. Enable them in settings.';
          _loading = false;
        });
        return;
      }

      // Check permissions
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

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        _center = LatLng(position.latitude, position.longitude);
      });

      await _loadNearbyPeople();
    } catch (e) {
      setState(() {
        _error = 'Could not get your location.';
        _loading = false;
      });
    }
  }

  Future<void> _loadNearbyPeople() async {
    try {
      final api = YaaroScope.of(context);
      // Call backend endpoint for nearby users
      final results = await api.nearbyForMap(
        lat: _center.latitude,
        lng: _center.longitude,
      );

      _people = results.map((json) => MapPerson.fromJson(json)).toList();
      _buildMarkers();
    } catch (e) {
      // If the endpoint doesn't exist yet, show empty map gracefully
      debugPrint('[Map] Failed to load nearby people: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _buildMarkers() {
    final markers = <Marker>{};

    // Add current user marker
    markers.add(
      Marker(
        markerId: const MarkerId('current_user'),
        position: _center,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'You'),
      ),
    );

    // Add people markers
    for (final person in _people) {
      markers.add(
        Marker(
          markerId: MarkerId(person.id),
          position: LatLng(person.latitude, person.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            person.isVerified
                ? BitmapDescriptor.hueGreen
                : BitmapDescriptor.hueRose,
          ),
          infoWindow: InfoWindow(
            title: person.displayName,
            snippet: person.age != null ? '${person.age} years old' : null,
          ),
          onTap: () {
            setState(() => _selectedPerson = person);
          },
        ),
      );
    }

    setState(() => _markers = markers);
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('People Nearby'),
        backgroundColor: isDark ? YaaroColors.surface : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF111216),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _loading = true);
              _loadNearbyPeople();
            },
          ),
        ],
      ),
      body: _buildBody(isDark),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_error != null) {
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

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _center,
            zoom: 13,
          ),
          markers: _markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          onMapCreated: (controller) {
            _mapController = controller;
            if (isDark) {
              _setDarkMapStyle(controller);
            }
          },
        ),
        // Bottom card for selected person
        if (_selectedPerson != null)
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: _PersonCard(
              person: _selectedPerson!,
              onClose: () => setState(() => _selectedPerson = null),
            ),
          ),
        // People count pill
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? YaaroColors.surface.withOpacity(0.92)
                  : Colors.white.withOpacity(0.92),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.people, size: 18, color: YaaroColors.rose),
                const SizedBox(width: 6),
                Text(
                  '${_people.length} nearby',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF111216),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

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
    await controller.setMapStyle(darkStyle);
  }
}

class _PersonCard extends StatelessWidget {
  const _PersonCard({
    required this.person,
    required this.onClose,
  });

  final MapPerson person;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? YaaroColors.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 28,
            backgroundColor: YaaroColors.rose.withOpacity(0.2),
            backgroundImage:
                person.photoUrl != null ? NetworkImage(person.photoUrl!) : null,
            child: person.photoUrl == null
                ? Text(
                    person.displayName.isNotEmpty
                        ? person.displayName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: YaaroColors.rose,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        person.displayName,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color:
                              isDark ? Colors.white : const Color(0xFF111216),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (person.age != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        '${person.age}',
                        style: TextStyle(
                          fontSize: 15,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                    if (person.isVerified) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.verified,
                          size: 18, color: YaaroColors.teal),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Nearby',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
              ],
            ),
          ),
          // Close button
          IconButton(
            icon: Icon(
              Icons.close,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}
