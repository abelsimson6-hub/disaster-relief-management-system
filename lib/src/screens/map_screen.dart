// lib/src/screens/map_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  final VoidCallback onBack;
  const MapScreen({super.key, required this.onBack});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // controller to programmatically move the map
  final MapController _mapController = MapController();

  // Map center (default) and sample markers with lat/lng
  LatLng _center = LatLng(37.7749, -122.4194);

  // user's current location (updated from GPS)
  LatLng? _userLocation;

  // stream subscription for live location updates
  StreamSubscription<Position>? _positionSub;

  // whether the map should follow the user's location
  bool _followUser = true;

  // current zoom used when centering/following
  final double _zoom = 13.0;

  final List<Map<String, dynamic>> locations = [
    {
      'type': 'shelter',
      'name': 'City Hall Relief Center',
      'address': '123 Main St',
      'lat': 37.7793,
      'lng': -122.4192,
      'capacity': '200 people',
      'status': 'active',
    },
    {
      'type': 'shelter',
      'name': 'Community Shelter',
      'address': '456 Oak Ave',
      'lat': 37.7685,
      'lng': -122.4156,
      'capacity': '150 people',
      'status': 'active',
    },
    {
      'type': 'safe-zone',
      'name': 'North Safe Zone',
      'address': 'Park District',
      'lat': 37.7810,
      'lng': -122.4120,
      'capacity': '100 people',
      'status': 'safe',
    },
    {
      'type': 'danger',
      'name': 'Flood Warning Area',
      'address': 'Downtown Low District',
      'lat': 37.7720,
      'lng': -122.4230,
      'capacity': 'Evacuate',
      'status': 'danger',
    },
  ];

  @override
  void initState() {
    super.initState();

    // Request location permission and obtain current position
    _determinePosition().then((pos) {
      if (pos != null) {
        final ll = LatLng(pos.latitude, pos.longitude);
        setState(() {
          _userLocation = ll;
          _center = ll;
        });
        // Move map to user's location if controller is ready
        try {
          _mapController.move(ll, 14.0);
        } catch (_) {}
      }
    });

    // subscribe to position updates (distanceFilter to reduce updates)
    _positionSub =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best,
            distanceFilter: 10,
          ),
        ).listen((p) {
          final ll = LatLng(p.latitude, p.longitude);
          setState(() {
            _userLocation = ll;
          });
          if (_followUser) {
            try {
              _mapController.move(ll, _zoom);
            } catch (_) {}
          }
        });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  void _centerOnUser() {
    final ll = _userLocation ?? _center;
    try {
      _mapController.move(ll, _zoom);
    } catch (_) {}
    setState(() {
      _followUser = true;
    });
  }

  void _toggleFollow() {
    setState(() {
      _followUser = !_followUser;
    });
  }

  Future<Position?> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled.')),
        );
      }
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
        }
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location permissions are permanently denied. Please enable them from settings.',
            ),
          ),
        );
      }
      return null;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      return pos;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to get location: $e')));
      }
      return null;
    }
  }

  // map markers are built inline using flutter_map's Marker widget

  Widget _statusBadge(String status) {
    Color bg;
    Color txt;
    switch (status) {
      case 'danger':
        bg = Colors.red.shade100;
        txt = Colors.red.shade700;
        break;
      case 'safe':
        bg = Colors.green.shade100;
        txt = Colors.green.shade700;
        break;
      default:
        bg = Colors.blue.shade100;
        txt = Colors.blue.shade700;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(status, style: TextStyle(color: txt, fontSize: 12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFF007BFF);

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            color: primary,
            padding: const EdgeInsets.fromLTRB(12, 40, 12, 12),
            child: Row(
              children: [
                IconButton(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Nearby Locations',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.navigation, color: Colors.white),
                ),
              ],
            ),
          ),

          // Map view with markers (FlutterMap + OSM tiles) -- centered and constrained
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: SizedBox(
                height: 300,
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _center,
                    initialZoom: 13.0,
                    interactionOptions: InteractionOptions(
                      flags: InteractiveFlag.all,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                      userAgentPackageName: 'dev.reliefapp',
                    ),
                    MarkerLayer(
                      markers: locations.map((loc) {
                        final lat = loc['lat'] as double? ?? _center.latitude;
                        final lng = loc['lng'] as double? ?? _center.longitude;
                        final status = loc['status'] as String? ?? 'active';
                        final color = status == 'danger'
                            ? Colors.red.shade600
                            : (status == 'safe'
                                  ? Colors.green.shade600
                                  : primary);
                        final icon = status == 'danger'
                            ? Icons.warning_amber_rounded
                            : (status == 'safe' ? Icons.shield : Icons.home);
                        return Marker(
                          point: LatLng(lat, lng),
                          width: 40,
                          height: 40,
                          child: Container(
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 6,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(icon, color: Colors.white, size: 18),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    // center current location marker
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _userLocation ?? _center,
                          width: 44,
                          height: 44,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: const Icon(
                              Icons.my_location,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Legend
          Container(
            color: Colors.grey.shade50,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _LegendDot(color: Colors.green.shade600, label: 'Safe Zones'),
                const SizedBox(width: 12),
                _LegendDot(color: primary, label: 'Shelters'),
                const SizedBox(width: 12),
                _LegendDot(color: Colors.red.shade600, label: 'Danger Zones'),
                const SizedBox(width: 12),
                _LegendDot(color: Colors.blue.shade700, label: 'You'),
              ],
            ),
          ),

          // Locations list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: locations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final loc = locations[i];
                final status = loc['status'] ?? 'active';
                final isDanger = status == 'danger';
                final bgColor = isDanger
                    ? Colors.red.shade50
                    : (status == 'safe'
                          ? Colors.green.shade50
                          : Colors.blue.shade50);
                final borderColor = isDanger
                    ? Colors.red.shade400
                    : (status == 'safe'
                          ? Colors.green.shade400
                          : Colors.blue.shade400);

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border(
                                  left: BorderSide(
                                    color: borderColor,
                                    width: 4,
                                  ),
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  isDanger
                                      ? Icons.warning_amber_rounded
                                      : (status == 'safe'
                                            ? Icons.shield
                                            : Icons.home),
                                  color: isDanger
                                      ? Colors.red.shade700
                                      : (status == 'safe'
                                            ? Colors.green.shade700
                                            : Colors.blue.shade700),
                                  size: 28,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          loc['name'] ?? '',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      _statusBadge(status),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.place,
                                        size: 14,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          loc['address'] ?? '',
                                          style: const TextStyle(
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Capacity: ${loc['capacity']}',
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (!isDanger) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // In a real app: launch maps/navigation
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Navigate to ${loc['name']} (mock)',
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.navigation, size: 18),
                              label: const Text('Navigate Here'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'center',
            mini: false,
            onPressed: _centerOnUser,
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'follow',
            mini: true,
            backgroundColor: _followUser ? Colors.blue : Colors.grey,
            onPressed: _toggleFollow,
            child: Icon(
              _followUser ? Icons.location_searching : Icons.location_disabled,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }
}
