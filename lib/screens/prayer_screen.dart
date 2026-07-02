import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:adhan/adhan.dart' as adhan;

// ==================== PRAYER SCREEN ====================
class PrayerScreen extends StatefulWidget {
  const PrayerScreen({super.key});

  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen> {
  Future<Map<String, DateTime>> _prayerTimesFuture = Future.value(
    <String, DateTime>{},
  );
  Position? _currentLocation;
  adhan.CalculationMethod _selectedMethod =
      adhan.CalculationMethod.muslim_world_league;
  adhan.Madhab _selectedMadhab = adhan.Madhab.shafi;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Request permission first
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled.';
      }

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

      final location = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );

      if (mounted) {
        setState(() {
          _currentLocation = location;
          _prayerTimesFuture = _getPrayerTimes(location);
        });
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
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
          _prayerTimesFuture = _getPrayerTimes(_currentLocation!);
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Using default location (Makkah). Please enable location services for accurate prayer times.'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<Map<String, DateTime>> _getPrayerTimes(Position position) async {
    try {
      // Get today's date
      final now = DateTime.now();

      // Create DateComponents for the adhan library (v2.0.0+)
      final dateComponents = adhan.DateComponents(now.year, now.month, now.day);

      // Create coordinates
      final coordinates = adhan.Coordinates(
        position.latitude,
        position.longitude,
      );

      // Get calculation parameters based on selected method
      final params = _selectedMethod.getParameters();
      params.madhab = _selectedMadhab;

      // Set high latitude rule for extreme latitudes
      params.highLatitudeRule = adhan.HighLatitudeRule.middle_of_the_night;

      // Calculate prayer times (precision parameter removed in v2.0.0+)
      final prayerTimes = adhan.PrayerTimes(
        coordinates,
        dateComponents,
        params,
      );

      // Convert to local time and return
      return {
        'Fajr': prayerTimes.fajr.toLocal(),
        'Sunrise': prayerTimes.sunrise.toLocal(),
        'Dhuhr': prayerTimes.dhuhr.toLocal(),
        'Asr': prayerTimes.asr.toLocal(),
        'Maghrib': prayerTimes.maghrib.toLocal(),
        'Isha': prayerTimes.isha.toLocal(),
      };
    } catch (e) {
      debugPrint('Error calculating prayer times: $e');
      throw Exception('Failed to calculate prayer times: $e');
    }
  }

// Replace the _showCalculationMethodDialog and _showMadhabDialog methods
// in your _PrayerScreenState class with these fixed versions:

  void _showCalculationMethodDialog() {
    final methods = [
      {
        'name': 'Muslim World League',
        'method': adhan.CalculationMethod.muslim_world_league
      },
      {'name': 'Egyptian', 'method': adhan.CalculationMethod.egyptian},
      {'name': 'Karachi', 'method': adhan.CalculationMethod.karachi},
      {
        'name': 'Umm Al-Qura (Makkah)',
        'method': adhan.CalculationMethod.umm_al_qura
      },
      {'name': 'Dubai', 'method': adhan.CalculationMethod.dubai},
      {
        'name': 'Moonsighting Committee',
        'method': adhan.CalculationMethod.moon_sighting_committee
      },
      {
        'name': 'North America (ISNA)',
        'method': adhan.CalculationMethod.north_america
      },
      {'name': 'Kuwait', 'method': adhan.CalculationMethod.kuwait},
      {'name': 'Qatar', 'method': adhan.CalculationMethod.qatar},
      {'name': 'Singapore', 'method': adhan.CalculationMethod.singapore},
      {'name': 'Turkey', 'method': adhan.CalculationMethod.turkey},
    ];

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        adhan.CalculationMethod tempMethod = _selectedMethod;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text('Select Calculation Method'),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: RadioGroup<adhan.CalculationMethod>(
                  groupValue: tempMethod,
                  onChanged: (adhan.CalculationMethod? value) {
                    if (value != null) {
                      setDialogState(() {
                        tempMethod = value;
                      });
                    }
                  },
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: methods.length,
                    itemBuilder: (BuildContext context, int index) {
                      final method = methods[index];
                      final methodValue =
                          method['method'] as adhan.CalculationMethod;

                      return RadioListTile<adhan.CalculationMethod>(
                        title: Text(method['name'] as String),
                        value: methodValue,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      );
                    },
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedMethod = tempMethod;
                    });
                    Navigator.pop(dialogContext);
                    if (_currentLocation != null) {
                      setState(() {
                        _prayerTimesFuture = _getPrayerTimes(_currentLocation!);
                      });
                    }
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showMadhabDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        adhan.Madhab tempMadhab = _selectedMadhab;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text('Select Madhab (School of Thought)'),
              content: RadioGroup<adhan.Madhab>(
                groupValue: tempMadhab,
                onChanged: (adhan.Madhab? value) {
                  if (value != null) {
                    setDialogState(() {
                      tempMadhab = value;
                    });
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RadioListTile<adhan.Madhab>(
                      title: const Text('Shafi\'i, Maliki, Hanbali'),
                      value: adhan.Madhab.shafi,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    RadioListTile<adhan.Madhab>(
                      title: const Text('Hanafi'),
                      value: adhan.Madhab.hanafi,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedMadhab = tempMadhab;
                    });
                    Navigator.pop(dialogContext);
                    if (_currentLocation != null) {
                      setState(() {
                        _prayerTimesFuture = _getPrayerTimes(_currentLocation!);
                      });
                    }
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prayer Times'),
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _getCurrentLocation,
            tooltip: 'Refresh Location',
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: _showCalculationMethodDialog,
            tooltip: 'Calculation Method',
          ),
        ],
      ),
      body: FutureBuilder<Map<String, DateTime>>(
        future: _prayerTimesFuture,
        builder: (BuildContext context,
            AsyncSnapshot<Map<String, DateTime>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Calculating prayer times...'),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 64),
                  const SizedBox(height: 20),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _getCurrentLocation,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                  'No prayer times available. Please check your location.'),
            );
          }

          final colorScheme = Theme.of(context).colorScheme;
          final prayerTimes = snapshot.data!;
          final currentTime = DateTime.now();

          // Find next prayer
          String? nextPrayer;
          DateTime? nextPrayerTime;

          for (final entry in prayerTimes.entries) {
            if (entry.value.isAfter(currentTime)) {
              if (nextPrayerTime == null ||
                  entry.value.isBefore(nextPrayerTime)) {
                nextPrayer = entry.key;
                nextPrayerTime = entry.value;
              }
            }
          }

          // If no prayer found for today, get first prayer of tomorrow
          if (nextPrayer == null) {
            nextPrayer = 'Fajr';
            final tomorrow = DateTime.now().add(const Duration(days: 1));
            final tomorrowDateComponents = adhan.DateComponents(
                tomorrow.year, tomorrow.month, tomorrow.day);
            final coordinates = adhan.Coordinates(
              _currentLocation?.latitude ?? 21.4225,
              _currentLocation?.longitude ?? 39.8262,
            );
            final params = _selectedMethod.getParameters();
            params.madhab = _selectedMadhab;
            params.highLatitudeRule =
                adhan.HighLatitudeRule.middle_of_the_night;

            final tomorrowPrayerTimes = adhan.PrayerTimes(
              coordinates,
              tomorrowDateComponents,
              params,
            );
            nextPrayerTime = tomorrowPrayerTimes.fajr.toLocal();
          }

          final timeUntilNextPrayer = nextPrayerTime!.difference(currentTime);
          final hours = timeUntilNextPrayer.inHours;
          final minutes = timeUntilNextPrayer.inMinutes % 60;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.location_on_rounded,
                          color: colorScheme.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current location',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _currentLocation != null
                                  ? '${_currentLocation!.latitude.toStringAsFixed(3)}°, ${_currentLocation!.longitude.toStringAsFixed(3)}°'
                                  : 'Location unavailable',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _showMadhabDialog,
                        icon: const Icon(Icons.school_rounded, size: 18),
                        label: Text(
                          _selectedMadhab == adhan.Madhab.hanafi
                              ? 'Hanafi'
                              : 'Shafi\'i',
                        ),
                      ),
                    ],
                  ),
                ),
                if (_currentLocation == null ||
                    (_currentLocation!.latitude == 21.4225 &&
                        _currentLocation!.longitude == 39.8262))
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      'Using default Makkah location. Enable GPS for precise prayer timings.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.primary,
                        colorScheme.secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.22),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: colorScheme.onPrimary.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          _getPrayerIcon(nextPrayer),
                          color: colorScheme.onPrimary,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Next Prayer',
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: colorScheme.onPrimary.withValues(alpha: 0.72),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              nextPrayer,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: colorScheme.onPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('h:mm a').format(nextPrayerTime),
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: colorScheme.onPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Remaining',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: colorScheme.onPrimary.withValues(alpha: 0.72),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${hours}h ${minutes}m',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('EEE, MMM d').format(DateTime.now()),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onPrimary.withValues(alpha: 0.72),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Prayer schedule',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: prayerTimes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final entry = prayerTimes.entries.toList()[index];
                    final prayerName = entry.key;
                    final prayerTime = entry.value;
                    final isPast = prayerTime.isBefore(currentTime);
                    final isNext = prayerName == nextPrayer;

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isNext
                            ? colorScheme.primaryContainer.withValues(alpha: 0.35)
                            : colorScheme.surface.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isNext
                              ? colorScheme.primary.withValues(alpha: 0.45)
                              : colorScheme.outlineVariant.withValues(alpha: 0.16),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isNext
                                  ? colorScheme.primary
                                  : colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              _getPrayerIcon(prayerName),
                              color: isNext
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurface.withValues(alpha: 0.7),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  prayerName,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: isNext ? FontWeight.w700 : FontWeight.w600,
                                    color: isNext ? colorScheme.primary : null,
                                  ),
                                ),
                                if (isPast)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Prayed',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                DateFormat('h:mm').format(prayerTime),
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: isNext ? colorScheme.primary : null,
                                ),
                              ),
                              Text(
                                DateFormat('a').format(prayerTime).toLowerCase(),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: isNext
                                      ? colorScheme.primary
                                      : colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  IconData _getPrayerIcon(String prayerName) {
    switch (prayerName) {
      case 'Fajr':
        return Icons.nightlight;
      case 'Sunrise':
        return Icons.wb_sunny;
      case 'Dhuhr':
        return Icons.brightness_5;
      case 'Asr':
        return Icons.brightness_6;
      case 'Maghrib':
        return Icons.nightlight_round;
      case 'Isha':
        return Icons.nightlight;
      default:
        return Icons.access_time;
    }
  }
}

