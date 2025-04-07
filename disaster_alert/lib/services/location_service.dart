import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:battery_plus/battery_plus.dart'; // Add this dependency
import 'api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class LocationService extends ChangeNotifier {
  final ApiService _apiService;
  final AuthService _authService;
  final Battery _battery = Battery();

  bool _isLoading = true;
  bool _hasPermission = false;
  Position? _currentPosition;
  String? _errorMessage;
  Timer? _locationUpdateTimer;

  // Constants for update frequency
  static const int FOREGROUND_UPDATE_INTERVAL = 1 * 60 * 1000; // 1 minute
  static const int BACKGROUND_UPDATE_INTERVAL = 5 * 60 * 1000; // 5 minutes

  // Getters
  bool get isLoading => _isLoading;
  bool get hasPermission => _hasPermission;
  Position? get currentPosition => _currentPosition;
  String? get errorMessage => _errorMessage;

  LocationService(this._apiService, this._authService) {
    _checkPermission();
  }
  // Start regular location updates
  void startLocationUpdates({bool isBackground = false}) {
    final updateInterval =
        isBackground ? BACKGROUND_UPDATE_INTERVAL : FOREGROUND_UPDATE_INTERVAL;

    // Cancel existing timer if running
    _locationUpdateTimer?.cancel();

    // Create a new timer for regular updates
    _locationUpdateTimer =
        Timer.periodic(Duration(milliseconds: updateInterval), (_) {
      _updateLocationAndSendToServer();
    });

    // Also update immediately
    _updateLocationAndSendToServer();
  }

  // Stop location updates
  void stopLocationUpdates() {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;
  }

  // Update location and send to server
  Future<void> _updateLocationAndSendToServer() async {
    try {
      final position = await getCurrentPosition();
      final batteryLevel = await _getBatteryLevel();
      final prefs = await SharedPreferences.getInstance();
      final alertRadius = prefs.getDouble('alert_radius') ?? 100.0;
      final userID = _authService.currentUser?.uid;

      if (position != null && userID != null) {
        // Send to server with the proper format the server expects
        final response = await _apiService.post(
          '/api/location/update',
          data: {
            'userID': userID,
            'latitude': position.latitude,
            'longitude': position.longitude,
            'radius': (alertRadius * 1000)
                .toString(), // Convert km to meters as a string
            'accuracy': position.accuracy,
            'timestamp': DateTime.now().toIso8601String(),
            'batteryLevel': batteryLevel,
          },
        );
        print('Tried Updating Location: Response ${response.statusCode}');
        if (response.statusCode != 200) {
          _errorMessage = 'Failed to update location: ${response.statusCode}';
          notifyListeners();
        }
      }
    } catch (e, stackTrace) {
      print('Error updating location: $e');
      print(stackTrace);
      _errorMessage = 'Error updating location: ${e.toString()}';
      notifyListeners();
    }
  }

  // Get battery level (0-100)
  Future<int> _getBatteryLevel() async {
    try {
      return await _battery.batteryLevel;
    } catch (e) {
      return 100; // Default to 100 if unable to get battery level
    }
  }

  // Check and request location permission
  Future<void> _checkPermission() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _errorMessage =
            'Location services are disabled. Please enable location in your device settings.';
        _isLoading = false;
        _hasPermission = false;
        notifyListeners();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _errorMessage =
              'Location permission denied. Some features will be limited.';
          _isLoading = false;
          _hasPermission = false;
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _errorMessage =
            'Location permission permanently denied. Please enable location in app settings.';
        _isLoading = false;
        _hasPermission = false;
        notifyListeners();
        return;
      }

      // Permission granted, get current position
      _hasPermission = true;
      await getCurrentPosition();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error getting location: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> testLocationUpdate() async {
    return _updateLocationAndSendToServer();
  }

  // Get current position
  Future<Position?> getCurrentPosition() async {
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      notifyListeners();
      return _currentPosition;
    } catch (e) {
      _errorMessage = 'Error getting current location: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }

  void setMockPosition(Position position) {
    _currentPosition = position;
    notifyListeners();
  }

  // Request permission again
  Future<void> requestPermission() async {
    await _checkPermission();
  }

  // Get last known position (faster than getCurrentPosition)
  Future<Position?> getLastKnownPosition() async {
    try {
      final lastPosition = await Geolocator.getLastKnownPosition();
      if (lastPosition != null) {
        _currentPosition = lastPosition;
        notifyListeners();
      }
      return lastPosition;
    } catch (e) {
      _errorMessage = 'Error getting last known location: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }

  // Start position stream for continuous updates
  Stream<Position> getPositionStream({
    LocationAccuracy accuracy = LocationAccuracy.medium,
    int interval = 10000, // 10 seconds
    int distanceFilter = 10, // 10 meters
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
        timeLimit: Duration(milliseconds: interval),
      ),
    ).map((position) {
      _currentPosition = position;
      notifyListeners();
      return position;
    });
  }

  // Get distance between two positions in meters
  double getDistance({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  // Check if a position is within a certain radius
  bool isWithinRadius({
    required double latitude,
    required double longitude,
    required double centerLatitude,
    required double centerLongitude,
    required double radius, // in meters
  }) {
    double distance = getDistance(
      startLatitude: latitude,
      startLongitude: longitude,
      endLatitude: centerLatitude,
      endLongitude: centerLongitude,
    );

    return distance <= radius;
  }

  @override
  void dispose() {
    stopLocationUpdates();
    super.dispose();
  }
}
