import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alert_model.dart';
import 'location_service.dart';
import 'api_service.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class AlertService extends ChangeNotifier {
  final LocationService _locationService;
  final ApiService _apiService;
  final AuthService _authService;

  List<AlertModel> _alerts = [];
  List<SafeLocationModel> _safeLocations = [];
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _alertRefreshTimer;

  // Filter settings
  bool _showCritical = true;
  bool _showWarning = true;
  bool _showWatch = true;
  bool _showInfo = true;
  bool _showFriendsAlerts = true;
  double _maxDistance = 100.0; // km

  // Getters
  List<AlertModel> get alerts => _alerts;
  List<SafeLocationModel> get safeLocations => _safeLocations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Constructor with dependency injection
  AlertService(this._locationService, this._apiService, this._authService) {
    _loadFilterPreferences();
  }

  // Start periodic alert refreshing
  void startAlertRefresh() {
    // Refresh every 15 minutes
    _alertRefreshTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      fetchAlerts();
    });

    // Also fetch immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchAlerts();
    });
  }

  // Stop alert refreshing
  void stopAlertRefresh() {
    _alertRefreshTimer?.cancel();
    _alertRefreshTimer = null;
  }

  // Combined method to update location and get alerts
  Future<void> updateLocationAndGetAlerts() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final position = await _locationService.getCurrentPosition();

      if (position == null) {
        _errorMessage = 'Unable to get current location';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final batteryLevel = await _getBatteryLevel();
      final userID = _authService.currentUser?.uid;

      if (userID == null) {
        _errorMessage = 'Not authenticated';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final response = await _apiService.post(
        '/api/location/update-and-get-alerts',
        data: {
          'userID': userID,
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': DateTime.now().toIso8601String(),
          'accuracy': position.accuracy,
          'batteryLevel': batteryLevel,
          'radius': _maxDistance * 1000, // Convert km to meters
          'filters': {
            'showCritical': _showCritical,
            'showWarning': _showWarning,
            'showWatch': _showWatch,
            'showInfo': _showInfo,
            'showFriendsAlerts': _showFriendsAlerts,
          },
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        // Process alerts
        if (responseData.containsKey('alerts')) {
          final List<dynamic> alertsData = responseData['alerts'];
          _alerts =
              alertsData.map((json) => AlertModel.fromJson(json)).toList();

          // Process safe locations and associate with alerts
          if (responseData.containsKey('safeLocations')) {
            final List<dynamic> safeLocationsData =
                responseData['safeLocations'];
            _safeLocations = safeLocationsData
                .map((json) => SafeLocationModel.fromJson(json))
                .toList();

            // Group safe locations by eventID and associate with matching alerts
            Map<String, List<SafeLocationModel>> safeLocationsByEvent = {};
            for (var safeLocation in _safeLocations) {
              if (safeLocation.eventID != null) {
                if (!safeLocationsByEvent.containsKey(safeLocation.eventID)) {
                  safeLocationsByEvent[safeLocation.eventID!] = [];
                }
                safeLocationsByEvent[safeLocation.eventID!]!.add(safeLocation);
              }
            }

            // Associate safe locations with their respective alerts
            for (int i = 0; i < _alerts.length; i++) {
              final alert = _alerts[i];
              if (alert.eventID != null &&
                  safeLocationsByEvent.containsKey(alert.eventID)) {
                // Create a new alert with the safe locations
                _alerts[i] = AlertModel(
                  id: alert.id,
                  title: alert.title,
                  description: alert.description,
                  severity: alert.severity,
                  timestamp: alert.timestamp,
                  expiryTime: alert.expiryTime,
                  latitude: alert.latitude,
                  longitude: alert.longitude,
                  radius: alert.radius,
                  source: alert.source,
                  metadata: alert.metadata,
                  eventID: alert.eventID,
                  safeLocations: safeLocationsByEvent[alert.eventID!],
                );
              }
            }
          }
        }

        // Cache the alerts for offline access
        _cacheAlerts(_alerts);
        _cacheSafeLocations(_safeLocations);

        _isLoading = false;
        notifyListeners();
      } else {
        _errorMessage = 'Failed to load alerts: ${response.statusCode}';
        _loadCachedAlerts(); // Load cached alerts as fallback
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Error fetching alerts: ${e.toString()}';
      _loadCachedAlerts(); // Load cached alerts as fallback
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAlerts() async {
    if (_isLoading) {
      print('[DEBUG] fetchAlerts aborted: already loading');
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    if (hasListeners) notifyListeners();

    try {
      final position = _locationService.currentPosition;
      final userID = _authService.currentUser?.uid;

      print('[DEBUG] Fetching alerts...');
      print('[DEBUG] Current Position: $position');
      print('[DEBUG] Current UserID: $userID');

      if (position == null) {
        _errorMessage = 'No location available';
        _isLoading = false;
        notifyListeners();
        print('[ERROR] No location available');
        return;
      }

      if (userID == null) {
        _errorMessage = 'Not authenticated';
        _isLoading = false;
        notifyListeners();
        print('[ERROR] User not authenticated');
        return;
      }

      final response = await _apiService.get(
        '/get-alerts',
        queryParams: {
          'userID': userID,
          'latitude': position.latitude.toString(),
          'longitude': position.longitude.toString(),
          'radius': (_maxDistance * 1000).toString(), // Convert km to meters
        },
      ).timeout(const Duration(seconds: 10));

      print(
          '[DEBUG] API response received with status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        print('[DEBUG] Raw response body: ${response.body}');

        // Process alerts
        if (responseData.containsKey('alerts')) {
          final List<dynamic> alertsData = responseData['alerts'];
          print('[DEBUG] Fetched ${alertsData.length} alerts');

          _alerts = alertsData.map((json) {
            final alert = AlertModel.fromJson(json);
            print('[DEBUG] Parsed alert: ${alert.toString()}');
            return alert;
          }).toList();
        } else {
          print('[WARN] Response does not contain "alerts" key');
        }

        // Process safe locations
        if (responseData.containsKey('safeLocations')) {
          final List<dynamic> safeLocationsData = responseData['safeLocations'];
          print('[DEBUG] Fetched ${safeLocationsData.length} safe locations');

          _safeLocations = safeLocationsData.map((json) {
            final loc = SafeLocationModel.fromJson(json);
            print('[DEBUG] Parsed safe location: ${loc.toString()}');
            return loc;
          }).toList();

          // Group safe locations by eventID
          Map<String, List<SafeLocationModel>> safeLocationsByEvent = {};
          for (var safeLocation in _safeLocations) {
            final eventID = safeLocation.eventID;
            if (eventID != null) {
              safeLocationsByEvent
                  .putIfAbsent(eventID, () => [])
                  .add(safeLocation);
            }
          }

          // Associate safe locations with their respective alerts
          for (int i = 0; i < _alerts.length; i++) {
            final alert = _alerts[i];
            if (alert.eventID != null &&
                safeLocationsByEvent.containsKey(alert.eventID)) {
              _alerts[i] = AlertModel(
                id: alert.id,
                title: alert.title,
                description: alert.description,
                severity: alert.severity,
                timestamp: alert.timestamp,
                expiryTime: alert.expiryTime,
                latitude: alert.latitude,
                longitude: alert.longitude,
                radius: alert.radius,
                source: alert.source,
                metadata: alert.metadata,
                eventID: alert.eventID,
                safeLocations: safeLocationsByEvent[alert.eventID!],
              );
              print('[DEBUG] Linked safe locations to alert ${alert.id}');
            }
          }
        } else {
          print('[WARN] Response does not contain "safeLocations" key');
        }

        _cacheAlerts(_alerts);
        _cacheSafeLocations(_safeLocations);
        print('[DEBUG] Cached alerts and safe locations');

        _isLoading = false;
        notifyListeners();
        print(
            '[DEBUG] fetchAlerts finished successfully. Alerts count: ${_alerts.length}');
      } else {
        _apiService.handleError(response);
        _errorMessage = 'Failed to load alerts: ${response.statusCode}';
        print('[ERROR] Server returned ${response.statusCode}');
        _loadCachedAlerts();
        _isLoading = false;
        notifyListeners();
      }
    } catch (e, stackTrace) {
      print('[ERROR] Exception during fetchAlerts: $e');
      print('[STACKTRACE] $stackTrace');

      _errorMessage = 'Error fetching alerts: ${e.toString()}';
      _loadCachedAlerts();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper method to get battery level
  Future<int> _getBatteryLevel() async {
    try {
      final Battery battery = Battery();
      return await battery.batteryLevel;
    } catch (e) {
      return 100; // Default value if unable to get battery level
    }
  }

  // Cache alerts for offline access
  Future<void> _cacheAlerts(List<AlertModel> alerts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alertsJson = alerts.map((alert) => alert.toJson()).toList();
      await prefs.setString('cached_alerts', json.encode(alertsJson));
    } catch (e) {
      print('Error caching alerts: $e');
    }
  }

  // Cache safe locations for offline access
  Future<void> _cacheSafeLocations(
      List<SafeLocationModel> safeLocations) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final locationsJson = safeLocations.map((loc) => loc.toJson()).toList();
      await prefs.setString(
          'cached_safe_locations', json.encode(locationsJson));
    } catch (e) {
      print('Error caching safe locations: $e');
    }
  }

  // Load cached alerts
  Future<void> _loadCachedAlerts() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load cached alerts
      final cachedAlerts = prefs.getString('cached_alerts');
      if (cachedAlerts != null) {
        final List<dynamic> alertsJson = json.decode(cachedAlerts);
        _alerts = alertsJson.map((json) => AlertModel.fromJson(json)).toList();
      }

      // Load cached safe locations
      final cachedLocations = prefs.getString('cached_safe_locations');
      if (cachedLocations != null) {
        final List<dynamic> locationsJson = json.decode(cachedLocations);
        _safeLocations = locationsJson
            .map((json) => SafeLocationModel.fromJson(json))
            .toList();
      }

      notifyListeners();
    } catch (e) {
      print('Error loading cached data: $e');
    }
  }

  // Load filter preferences from shared preferences
  Future<void> _loadFilterPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    _showCritical = prefs.getBool('filter_critical') ?? true;
    _showWarning = prefs.getBool('filter_warning') ?? true;
    _showWatch = prefs.getBool('filter_watch') ?? true;
    _showInfo = prefs.getBool('filter_info') ?? true;
    _showFriendsAlerts = prefs.getBool('filter_friends') ?? true;
    _maxDistance = prefs.getDouble('filter_distance') ?? 100.0;

    notifyListeners();
  }

  // Save filter preferences
  Future<void> _saveFilterPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('filter_critical', _showCritical);
    await prefs.setBool('filter_warning', _showWarning);
    await prefs.setBool('filter_watch', _showWatch);
    await prefs.setBool('filter_info', _showInfo);
    await prefs.setBool('filter_friends', _showFriendsAlerts);
    await prefs.setDouble('filter_distance', _maxDistance);
  }

  // Update filter settings
  void updateFilters({
    bool? showCritical,
    bool? showWarning,
    bool? showWatch,
    bool? showInfo,
    bool? showFriendsAlerts,
    double? maxDistance,
  }) {
    if (showCritical != null) _showCritical = showCritical;
    if (showWarning != null) _showWarning = showWarning;
    if (showWatch != null) _showWatch = showWatch;
    if (showInfo != null) _showInfo = showInfo;
    if (showFriendsAlerts != null) _showFriendsAlerts = showFriendsAlerts;
    if (maxDistance != null) _maxDistance = maxDistance;

    _saveFilterPreferences();
    notifyListeners();

    // Refresh alerts with new filters
    fetchAlerts();
  }

  // Filter alerts based on user preferences
  List<AlertModel> getFilteredAlerts() {
    return _alerts.where((alert) {
      // Filter by severity
      if (!_showCritical && alert.severity.toLowerCase() == 'critical')
        return false;
      if (!_showWarning && alert.severity.toLowerCase() == 'warning')
        return false;
      if (!_showWatch && alert.severity.toLowerCase() == 'watch') return false;
      if (!_showInfo && alert.severity.toLowerCase() == 'info') return false;

      // Filter expired alerts
      if (!alert.isActive) return false;

      return true;
    }).toList();
  }

  // Get alerts near specified coordinates
  List<AlertModel> getAlertsNearLocation(
    double latitude,
    double longitude,
    double radius,
  ) {
    return _alerts.where((alert) {
      final distance = _locationService.getDistance(
        startLatitude: latitude,
        startLongitude: longitude,
        endLatitude: alert.latitude,
        endLongitude: alert.longitude,
      );

      return distance <= radius;
    }).toList();
  }

  // Get alerts by severity
  List<AlertModel> getAlertsBySeverity(String severity) {
    return _alerts
        .where(
          (alert) => alert.severity.toLowerCase() == severity.toLowerCase(),
        )
        .toList();
  }

  // Get safe locations near specified coordinates
  List<SafeLocationModel> getSafeLocationsNearby(
    double latitude,
    double longitude,
    double radius,
  ) {
    return _safeLocations.where((location) {
      final distance = _locationService.getDistance(
        startLatitude: latitude,
        startLongitude: longitude,
        endLatitude: location.latitude,
        endLongitude: location.longitude,
      );

      return distance <= radius;
    }).toList();
  }

  // Get safe locations for a specific alert
  List<SafeLocationModel> getSafeLocationsForAlert(String eventID) {
    return _safeLocations
        .where((location) => location.eventID == eventID)
        .toList();
  }
}
