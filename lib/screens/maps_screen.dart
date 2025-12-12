import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key});

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  final MapController _mapController = MapController();
  Position? _currentPosition;
  List<Marker> _markers = [];
  List<Map<String, dynamic>> _places = [];
  bool _isLoading = true;
  String _selectedCategory = 'mosque';
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _categories = [
    {
      'id': 'mosque',
      'name': 'Mosques',
      'icon': Icons.mosque,
      'color': Colors.teal
    },
    {
      'id': 'halal',
      'name': 'Halal Food',
      'icon': Icons.restaurant,
      'color': Colors.orange
    },
    {
      'id': 'islamic_school',
      'name': 'Islamic Schools',
      'icon': Icons.school,
      'color': Colors.blue
    },
    {
      'id': 'bookstore',
      'name': 'Islamic Bookstores',
      'icon': Icons.menu_book,
      'color': Colors.purple
    },
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isLoading = false;
        });
        _searchNearbyPlaces();
      }
    } catch (e) {
      // Default to Makkah
      if (mounted) {
        setState(() {
          _currentPosition = Position(
            latitude: 21.4225,
            longitude: 39.8262,
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            heading: 0,
            speed: 0,
            speedAccuracy: 0,
            altitudeAccuracy: 0,
            headingAccuracy: 0,
          );
          _isLoading = false;
        });
        _searchNearbyPlaces();
      }
    }
  }

  Future<void> _searchNearbyPlaces() async {
    if (_currentPosition == null) return;

    setState(() => _isLoading = true);

    try {
      // Use Overpass API for OpenStreetMap data
      final query = _buildOverpassQuery();
      final response = await http.post(
        Uri.parse('https://overpass-api.de/api/interpreter'),
        body: query,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final elements = data['elements'] as List;

        final places = elements
            .map<Map<String, dynamic>>((e) {
              return {
                'id': e['id'],
                'name': e['tags']?['name'] ?? 'Unknown',
                'lat': e['lat'] ?? e['center']?['lat'],
                'lon': e['lon'] ?? e['center']?['lon'],
                'type': _selectedCategory,
                'address': e['tags']?['addr:street'] ?? '',
              };
            })
            .where((p) => p['lat'] != null && p['lon'] != null)
            .toList();

        if (mounted) {
          setState(() {
            _places = places;
            _updateMarkers();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching places: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _buildOverpassQuery() {
    final lat = _currentPosition!.latitude;
    final lon = _currentPosition!.longitude;
    final radius = 5000; // 5km radius

    String amenityType;
    switch (_selectedCategory) {
      case 'mosque':
        amenityType = 'place_of_worship"]["religion"="muslim';
        break;
      case 'halal':
        amenityType = 'restaurant"]["cuisine"="halal';
        break;
      case 'islamic_school':
        amenityType = 'school"]["religion"="muslim';
        break;
      case 'bookstore':
        amenityType = 'shop"]["books"="religious';
        break;
      default:
        amenityType = 'place_of_worship"]["religion"="muslim';
    }

    return '''
      [out:json][timeout:25];
      (
        node["amenity"="$amenityType"](around:$radius,$lat,$lon);
        way["amenity"="$amenityType"](around:$radius,$lat,$lon);
      );
      out center;
    ''';
  }

  void _updateMarkers() {
    final category =
        _categories.firstWhere((c) => c['id'] == _selectedCategory);

    _markers = [
      // Current location marker
      if (_currentPosition != null)
        Marker(
          point:
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          width: 50,
          height: 50,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.my_location, color: Colors.blue, size: 30),
          ),
        ),
      // Place markers
      ..._places.map((place) => Marker(
            point: LatLng(place['lat'], place['lon']),
            width: 50,
            height: 50,
            child: GestureDetector(
              onTap: () => _showPlaceDetails(place),
              child: Container(
                decoration: BoxDecoration(
                  color: (category['color'] as Color).withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(category['icon'] as IconData,
                    color: Colors.white, size: 28),
              ),
            ),
          )),
    ];
  }

  void _showPlaceDetails(Map<String, dynamic> place) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.mosque, color: Colors.teal, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place['name'] ?? 'Unknown Place',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      if (place['address'] != null &&
                          place['address'].isNotEmpty)
                        Text(
                          place['address'],
                          style: const TextStyle(color: Colors.grey),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _mapController.move(
                        LatLng(place['lat'], place['lon']),
                        16,
                      );
                    },
                    icon: const Icon(Icons.directions),
                    label: const Text('Navigate'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Islamic Places'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Category Chips
          Container(
            color: Colors.teal,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((cat) {
                  final isSelected = cat['id'] == _selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: isSelected,
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            cat['icon'] as IconData,
                            size: 18,
                            color: isSelected
                                ? Colors.white
                                : cat['color'] as Color,
                          ),
                          const SizedBox(width: 6),
                          Text(cat['name'] as String),
                        ],
                      ),
                      selectedColor: cat['color'] as Color,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                      onSelected: (selected) {
                        setState(() => _selectedCategory = cat['id'] as String);
                        _searchNearbyPlaces();
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Map
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentPosition != null
                        ? LatLng(_currentPosition!.latitude,
                            _currentPosition!.longitude)
                        : const LatLng(21.4225, 39.8262),
                    initialZoom: 14,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.rafiq.app',
                    ),
                    MarkerLayer(markers: _markers),
                  ],
                ),

                // Loading overlay
                if (_isLoading)
                  Container(
                    color: Colors.black.withValues(alpha: 0.3),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),

                // Places count badge
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Text(
                      '${_places.length} places found',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_currentPosition != null) {
            _mapController.move(
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
              14,
            );
          }
        },
        backgroundColor: Colors.teal,
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }
}
