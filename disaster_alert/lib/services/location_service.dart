import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'api_service.dart';
import 'package:battery_plus/battery_plus.dart';

class LocationService extends ChangeNotifier {
  bool _isLoading = true;
  bool _hasPermission = false;
  Position? _currentPosition;
  String? _errorMessage;

  // Getters
  bool get isLoading => _isLoading;
  bool get hasPermission => _hasPermission;
  Position? get currentPosition => _currentPosition;
  String? get errorMessage => _errorMessage;

  // Constructor
  LocationService() {
    _checkPermission();
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
}
