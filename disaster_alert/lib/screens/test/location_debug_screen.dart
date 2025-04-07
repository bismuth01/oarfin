// screens/test/location_debug_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/location_service.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class LocationDebugScreen extends StatefulWidget {
  const LocationDebugScreen({Key? key}) : super(key: key);

  @override
  _LocationDebugScreenState createState() => _LocationDebugScreenState();
}

class _LocationDebugScreenState extends State<LocationDebugScreen> {
  String _locationInfo = 'No location data';
  bool _isTracking = false;
  StreamSubscription<Position>? _positionStream;

  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  @override
  void dispose() {
    _stopTracking();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  void _stopTracking() {
    _positionStream?.cancel();
    _positionStream = null;
    setState(() {
      _isTracking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final locationService = Provider.of<LocationService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Debug'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Location Status',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Text('Has permission: ${locationService.hasPermission}'),
                    Text('Is loading: ${locationService.isLoading}'),
                    Text(
                        'Error message: ${locationService.errorMessage ?? 'None'}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        await locationService.requestPermission();
                        setState(() {}); // Refresh UI
                      },
                      child: const Text('Request Permission'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Location',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    if (locationService.currentPosition != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'Latitude: ${locationService.currentPosition!.latitude}'),
                          Text(
                              'Longitude: ${locationService.currentPosition!.longitude}'),
                          Text(
                              'Accuracy: ${locationService.currentPosition!.accuracy} meters'),
                          Text(
                              'Timestamp: ${locationService.currentPosition!.timestamp}'),
                        ],
                      )
                    else
                      const Text('No position available'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final position =
                                  await locationService.getCurrentPosition();
                              setState(() {
                                _locationInfo = position != null
                                    ? 'Updated location:\nLat: ${position.latitude}\nLng: ${position.longitude}'
                                    : 'Failed to get location';
                              });
                            },
                            child: const Text('Get Current Location'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: !_isTracking
                                ? () {
                                    setState(() {
                                      _isTracking = true;
                                    });

                                    // Start tracking
                                    _positionStream = locationService
                                        .getPositionStream()
                                        .listen((position) {
                                      setState(() {
                                        _locationInfo =
                                            'Live location:\nLat: ${position.latitude}\nLng: ${position.longitude}\nAccuracy: ${position.accuracy} m';
                                      });
                                    });
                                  }
                                : _stopTracking,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isTracking ? Colors.red : null,
                            ),
                            child: Text(_isTracking
                                ? 'Stop Tracking'
                                : 'Start Tracking'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(_locationInfo),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mock Location',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _latController,
                      decoration: const InputDecoration(
                        labelText: 'Latitude',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _lngController,
                      decoration: const InputDecoration(
                        labelText: 'Longitude',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              try {
                                final lat = double.parse(_latController.text);
                                final lng = double.parse(_lngController.text);

                                // Create mock position
                                final mockPosition = Position(
                                  latitude: lat,
                                  longitude: lng,
                                  timestamp: DateTime.now(),
                                  accuracy: 10.0,
                                  altitude: 0.0,
                                  altitudeAccuracy: 0.0,
                                  heading: 0.0,
                                  headingAccuracy: 0.0,
                                  speed: 0.0,
                                  speedAccuracy: 0.0,
                                );

                                // Set mock position
                                locationService.setMockPosition(mockPosition);

                                setState(() {
                                  _locationInfo =
                                      'Set mock location:\nLat: $lat\nLng: $lng';
                                });
                              } catch (e) {
                                setState(() {
                                  _locationInfo =
                                      'Error setting mock location: $e';
                                });
                              }
                            },
                            child: const Text('Set Mock Location'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            _latController.text = '37.7749';
                            _lngController.text = '-122.4194';
                          },
                          child: const Text('SF'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            _latController.text = '34.0522';
                            _lngController.text = '-118.2437';
                          },
                          child: const Text('LA'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
