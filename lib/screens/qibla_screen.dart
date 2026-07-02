import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import '../widgets/feature_header.dart';

// ==================== QIBLA SCREEN ====================
class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  Position? _currentLocation;
  double _qiblaDirection = 0;
  double _deviceHeading = 0;
  StreamSubscription<CompassEvent>? _compassSubscription;
  bool _hasCompassSupport = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _initCompass();
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initCompass() async {
    // Check if compass is available
    final compassStream = FlutterCompass.events;

    if (compassStream == null) {
      setState(() {
        _hasCompassSupport = false;
        _errorMessage = 'Compass not supported on this device';
      });
      return;
    }

    setState(() {
      _hasCompassSupport = true;
    });

    // Listen to compass events
    _compassSubscription = compassStream.listen(
      (CompassEvent event) {
        if (event.heading != null) {
          setState(() {
            _deviceHeading = event.heading!;
          });
        }
      },
      onError: (error) {
        setState(() {
          _errorMessage = 'Compass error: $error';
        });
      },
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled.';
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied.';
      }

      // Get current location
      final location = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );

      if (mounted) {
        setState(() {
          _currentLocation = location;
          _qiblaDirection = _calculateQiblaDirection(location);
          _errorMessage = '';
        });
      }
    } catch (e) {
      // Default to Makkah coordinates
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

      if (mounted) {
        setState(() {
          _qiblaDirection = _calculateQiblaDirection(_currentLocation!);
          _errorMessage = 'Using default location (Makkah): $e';
        });
      }
    }
  }

  double _calculateQiblaDirection(Position position) {
    const meccaLat = 21.4225;
    const meccaLon = 39.8262;

    final lat = position.latitude * pi / 180;
    final lon = position.longitude * pi / 180;
    final meccaLatRad = meccaLat * pi / 180;
    final meccaLonRad = meccaLon * pi / 180;

    final deltaLon = meccaLonRad - lon;

    final y = sin(deltaLon) * cos(meccaLatRad);
    final x = cos(lat) * sin(meccaLatRad) -
        sin(lat) * cos(meccaLatRad) * cos(deltaLon);

    final bearing = atan2(y, x);
    final qibla = (bearing * 180 / pi + 360) % 360;

    return qibla;
  }

  // Calculate the rotation angle for the compass needle
  double get _needleRotation {
    // The needle should point to Qibla
    // Subtract device heading from Qibla direction to get relative angle
    double rotation = _qiblaDirection - _deviceHeading;

    // Normalize to -180 to 180 range for smoother rotation
    while (rotation > 180) {
      rotation -= 360;
    }
    while (rotation < -180) {
      rotation += 360;
    }

    return rotation * pi / 180; // Convert to radians
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Qibla Direction'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _getCurrentLocation,
            tooltip: 'Refresh Location',
          ),
        ],
      ),
      body: _currentLocation == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                children: [
                  FeatureHeader(
                    icon: Icons.explore_rounded,
                    title: 'Qibla Direction',
                    subtitle: 'Rotate until the needle points up',
                  ),
                  if (_errorMessage.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        _errorMessage,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Location info
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text('Current location', style: theme.textTheme.labelLarge),
                        const SizedBox(height: 6),
                        Text(
                          'Lat: ${_currentLocation!.latitude.toStringAsFixed(4)}',
                          style: theme.textTheme.bodyMedium,
                        ),
                        Text(
                          'Lng: ${_currentLocation!.longitude.toStringAsFixed(4)}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Compass display
                  Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.surface,
                      border: Border.all(color: colorScheme.primary, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.12),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Compass rose background
                        CustomPaint(
                          size: const Size(260, 260),
                          painter: CompassRosePainter(
                            color: colorScheme.onSurface.withValues(alpha: 0.24),
                          ),
                        ),

                        // Rotating needle pointing to Qibla
                        if (_hasCompassSupport)
                          Transform.rotate(
                            angle: _needleRotation,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.navigation_rounded,
                                  size: 74,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Qibla',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        if (!_hasCompassSupport)
                          Icon(
                            Icons.error_outline_rounded,
                            size: 72,
                            color: colorScheme.error,
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Direction info
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text('Qibla Direction', style: theme.textTheme.labelLarge),
                                const SizedBox(height: 4),
                                Text(
                                  '${_qiblaDirection.toStringAsFixed(1)}°',
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            if (_hasCompassSupport)
                              Column(
                                children: [
                                  Text('Device Heading', style: theme.textTheme.labelLarge),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_deviceHeading.toStringAsFixed(1)}°',
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        if (!_hasCompassSupport) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Compass not available on this device.\nPlease use the angle shown above to face Qibla.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.error,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Instructions
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: Text(
                      'Hold your device flat and rotate until the arrow points upward.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// Custom painter for compass rose
class CompassRosePainter extends CustomPainter {
  const CompassRosePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw cardinal direction markers
    for (int i = 0; i < 4; i++) {
      final angle = i * pi / 2;
      final x1 = center.dx + (radius - 30) * cos(angle);
      final y1 = center.dy + (radius - 30) * sin(angle);
      final x2 = center.dx + (radius - 10) * cos(angle);
      final y2 = center.dy + (radius - 10) * sin(angle);

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }

    // Draw minor direction markers
    paint.strokeWidth = 1;
    for (int i = 0; i < 12; i++) {
      if (i % 3 != 0) {
        final angle = i * pi / 6;
        final x1 = center.dx + (radius - 20) * cos(angle);
        final y1 = center.dy + (radius - 20) * sin(angle);
        final x2 = center.dx + (radius - 10) * cos(angle);
        final y2 = center.dy + (radius - 10) * sin(angle);

        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CompassRosePainter oldDelegate) =>
      oldDelegate.color != color;
}
