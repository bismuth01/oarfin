class AlertModel {
  final String id;
  final String title;
  final String description;
  final String severity; // Critical, Warning, Watch, Info
  final DateTime timestamp;
  final DateTime expiryTime;
  final double latitude;
  final double longitude;
  final double radius; // in meters
  final String source; // e.g., "NOAA", "USGS", etc.
  final Map<String, dynamic>?
  metadata; // Additional data specific to alert type

  AlertModel({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.timestamp,
    required this.expiryTime,
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.source,
    this.metadata,
  });

  // Create from JSON (for API responses)
  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      severity: json['severity'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      expiryTime: DateTime.parse(json['expiryTime'] as String),
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      radius: json['radius'] as double,
      source: json['source'] as String,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  // Convert to JSON (for storage)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'severity': severity,
      'timestamp': timestamp.toIso8601String(),
      'expiryTime': expiryTime.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'source': source,
      'metadata': metadata,
    };
  }

  // Check if alert is active (not expired)
  bool get isActive => DateTime.now().isBefore(expiryTime);

  // Get time ago string (e.g., "5 minutes ago")
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else {
      return timestamp.toString().substring(0, 10); // Just date
    }
  }

  // Get color based on severity
  int getColorValue() {
    switch (severity.toLowerCase()) {
      case 'critical':
        return 0xFFD32F2F; // Red
      case 'warning':
        return 0xFFF57C00; // Orange
      case 'watch':
        return 0xFFFFB300; // Amber
      case 'info':
        return 0xFF0288D1; // Light Blue
      default:
        return 0xFF0288D1; // Default to info color
    }
  }
}
