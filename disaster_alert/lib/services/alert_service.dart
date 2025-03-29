import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alert_model.dart';
import 'location_service.dart';

class AlertService extends ChangeNotifier {
  final LocationService _locationService;

  List<AlertModel> _alerts = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Filter settings
  bool _showCritical = true;
  bool _showWarning = true;
  bool _showWatch = true;
  bool _showInfo = true;
  bool _showFriendsAlerts = true;
  double _maxDistance = 100.0; // km

  // Getters
  List<AlertModel> get alerts => _alerts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get showCritical => _showCritical;
  bool get showWarning => _showWarning;
  bool get showWatch => _showWatch;
  bool get showInfo => _showInfo;
  bool get showFriendsAlerts => _showFriendsAlerts;
  double get maxDistance => _maxDistance;

  // Constructor with dependency injection
  AlertService(this._locationService) {
    _loadFilterPreferences();
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

  // Fetch alerts from API
  Future<void> fetchAlerts() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Get current position
      final position = await _locationService.getCurrentPosition();

      if (position == null) {
        _errorMessage = 'Unable to get current location';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // TODO: Replace with your actual API endpoint
      final apiUrl = 'https://example.com/api/alerts';

      final response = await http.get(
        Uri.parse(
          '$apiUrl?lat=${position.latitude}&lon=${position.longitude}&radius=${_maxDistance * 1000}',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        _alerts =
            data
                .map((json) => AlertModel.fromJson(json))
                .where(_filterAlert)
                .toList();

        // Sort by timestamp, most recent first
        _alerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        _isLoading = false;
        notifyListeners();
      } else {
        _errorMessage = 'Failed to load alerts: ${response.statusCode}';
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      // For demo purposes, generate some fake alerts
      _generateFakeAlerts();

      _isLoading = false;
      notifyListeners();
    }
  }

  // Filter alerts based on user preferences
  bool _filterAlert(AlertModel alert) {
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
  }

  // Generate fake alerts for demo purposes
  void _generateFakeAlerts() {
    final position = _locationService.currentPosition;
    if (position == null) return;

    final now = DateTime.now();

    _alerts = [
      AlertModel(
        id: '1',
        title: 'Flash Flood Warning',
        description:
            'Flash flooding is expected in your area. Move to higher ground immediately.',
        severity: 'Critical',
        timestamp: now.subtract(const Duration(minutes: 10)),
        expiryTime: now.add(const Duration(hours: 6)),
        latitude: position.latitude + 0.01,
        longitude: position.longitude - 0.01,
        radius: 5000, // 5 km
        source: 'NOAA',
      ),
      AlertModel(
        id: '2',
        title: 'Thunderstorm Watch',
        description:
            'Severe thunderstorms possible in your area in the next 6 hours.',
        severity: 'Warning',
        timestamp: now.subtract(const Duration(minutes: 30)),
        expiryTime: now.add(const Duration(hours: 12)),
        latitude: position.latitude - 0.02,
        longitude: position.longitude + 0.02,
        radius: 10000, // 10 km
        source: 'NOAA',
      ),
      AlertModel(
        id: '3',
        title: 'Earthquake Report',
        description:
            'Magnitude 4.2 earthquake detected 50 miles from your location.',
        severity: 'Info',
        timestamp: now.subtract(const Duration(hours: 2)),
        expiryTime: now.add(const Duration(hours: 24)),
        latitude: position.latitude + 0.03,
        longitude: position.longitude + 0.03,
        radius: 50000, // 50 km
        source: 'USGS',
      ),
    ];
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
}
