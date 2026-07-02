import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

// ==================== MAP SCREEN ====================
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  Position? _currentLocation;
  bool _isLoading = true;
  String _selectedType = 'mosque';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      _currentLocation = await Geolocator.getCurrentPosition();
      setState(() => _isLoading = false);
    } catch (e) {
      _currentLocation = Position(
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
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Islamic Places'),
        actions: [
          DropdownButton<String>(
            value: _selectedType,
            items: ['mosque', 'halal', 'islamic_shop']
                .map((type) => DropdownMenuItem(
                    value: type, child: Text(type.toUpperCase())))
                .toList(),
            onChanged: (value) {
              setState(() => _selectedType = value!);
            },
          ),
          IconButton(
              icon: const Icon(Icons.refresh), onPressed: _getCurrentLocation),
        ],
      ),
      body: _isLoading || _currentLocation == null
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.map, size: 100, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Map functionality requires additional packages',
                      style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(
                      'Current location: ${_currentLocation!.latitude}, ${_currentLocation!.longitude}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _getCurrentLocation,
                    child: const Text('Refresh Location'),
                  ),
                ],
              ),
            ),
    );
  }
}

