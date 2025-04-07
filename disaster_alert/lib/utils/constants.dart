class AppConstants {
  // App Info
  static const String appName = 'Disaster Alert';
  static const String appVersion = '1.0.0';

  // API Endpoints
  static const String baseApiUrl = 'https://example.com/api';
  static const String alertsEndpoint = '$baseApiUrl/alerts';
  static const String weatherEndpoint = '$baseApiUrl/weather';

  // Default Map Settings
  static const double defaultMapZoom = 10.0;
  static const double defaultMapLatitude = 37.7749; // San Francisco
  static const double defaultMapLongitude = -122.4194;

  // Location Settings
  static const int locationUpdateInterval = 1000 * 60 * 5; // 5 minutes
  static const int locationUpdateDistance = 100; // 100 meters

  // Alert Settings
  static const int alertRefreshInterval = 1000 * 60 * 15; // 15 minutes
  static const double alertDefaultRadius = 50.0; // 50 km

  // Alert Severities
  static const String alertCritical = 'Critical';
  static const String alertWarning = 'Warning';
  static const String alertWatch = 'Watch';
  static const String alertInfo = 'Info';

  // Alert Types
  static const List<String> alertTypes = [
    'Earthquake',
    'Tsunami',
    'Hurricane',
    'Tornado',
    'Flood',
    'Wildfire',
    'Winter Storm',
    'Extreme Heat',
    'Severe Weather',
    'Other',
  ];

  // Notification Channels
  static const String alertChannelId = 'alert_channel';
  static const String alertChannelName = 'Alert Notifications';
  static const String alertChannelDescription =
      'Notifications for disaster alerts';

  static const String friendChannelId = 'friend_channel';
  static const String friendChannelName = 'Friend Notifications';
  static const String friendChannelDescription =
      'Notifications for friend requests and alerts';

  // Cache Keys
  static const String cacheKeyAlerts = 'cached_alerts';
  static const String cacheKeyFriends = 'cached_friends';
  static const String cacheKeySettings = 'app_settings';

  // Timeouts
  static const int apiTimeoutSeconds = 10;
  static const int locationTimeoutSeconds = 5;
}

// Shared Preferences Keys
class PrefsKeys {
  static const String isFirstRun = 'is_first_run';
  static const String userLocation = 'user_location';
  static const String notificationsEnabled = 'notifications_enabled';
  static const String alertFilters = 'alert_filters';
  static const String mapType = 'map_type';
  static const String userIdKey = 'user_id';
  static const String isLoggedIn = 'is_logged_in';
}
