import 'package:flutter/material.dart';
import '../utils/theme.dart';

class SafeLocationModel {
  final String? id;
  final String? eventID;
  final double latitude;
  final double longitude;
  final String? type;
  final String? description;

  SafeLocationModel({
    this.id,
    this.eventID,
    required this.latitude,
    required this.longitude,
    this.type,
    this.description,
  });

  factory SafeLocationModel.fromJson(Map<String, dynamic> json) {
    return SafeLocationModel(
      id: json['id']?.toString(),
      eventID: json['eventID']?.toString(),
      latitude: double.tryParse(json['latitude']?.toString() ??
              json['safelat']?.toString() ??
              '0') ??
          0.0,
      longitude: double.tryParse(json['longitude']?.toString() ??
              json['safelong']?.toString() ??
              '0') ??
          0.0,
      type: json['type'] as String?,
      description: json['description'] as String? ?? json['desc'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventID': eventID,
      'latitude': latitude,
      'longitude': longitude,
      'type': type,
      'description': description,
    };
  }

  @override
  String toString() {
    return 'SafeLocationModel(id: $id, eventID: $eventID, '
        'latitude: $latitude, longitude: $longitude, '
        'type: $type, description: $description)';
  }
}

class AlertModel {
  final String id;
  final String title;
  final String description;
  final String severity;
  final DateTime timestamp;
  final DateTime expiryTime;
  final double latitude;
  final double longitude;
  final double radius;
  final String? source;
  final Map<String, dynamic>? metadata;
  final List<SafeLocationModel>? safeLocations;
  final String? eventID;

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
    this.source,
    this.metadata,
    this.safeLocations,
    this.eventID,
  });

  // Returns true if the alert is still active (not expired)
  bool get isActive => DateTime.now().isBefore(expiryTime);

  // Returns color value based on severity
  int getColorValue() {
    switch (severity.toLowerCase()) {
      case 'critical':
        return AppColors.criticalAlert.value;
      case 'warning':
        return AppColors.warningAlert.value;
      case 'watch':
        return AppColors.watchAlert.value;
      case 'info':
        return AppColors.infoAlert.value;
      default:
        return Colors.grey.value;
    }
  }

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    List<SafeLocationModel>? safeLocations;

    // Check if safeLocations is included in the JSON
    if (json['safeLocations'] != null) {
      safeLocations = (json['safeLocations'] as List)
          .map((item) =>
              SafeLocationModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return AlertModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      severity: json['severity'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      expiryTime: DateTime.parse(json['expiryTime'] as String),
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      radius: double.parse(json['radius'].toString()),
      source: json['source'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      safeLocations: safeLocations,
      eventID: json['eventID']?.toString(),
    );
  }

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
      'eventID': eventID,
      'safeLocations': safeLocations?.map((loc) => loc.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'AlertModel(id: $id, title: $title, description: $description, '
        'severity: $severity, timestamp: $timestamp, expiryTime: $expiryTime, '
        'latitude: $latitude, longitude: $longitude, radius: $radius, '
        'source: $source, metadata: $metadata, eventID: $eventID, '
        'safeLocations: ${safeLocations?.map((e) => e.toString()).toList()})';
  }

  // Add this getter to the AlertModel class in your models/alert_model.dart file

  // Returns a human-readable relative time string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} ${(difference.inDays / 7).floor() == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()} ${(difference.inDays / 30).floor() == 1 ? 'month' : 'months'} ago';
    } else {
      return '${(difference.inDays / 365).floor()} ${(difference.inDays / 365).floor() == 1 ? 'year' : 'years'} ago';
    }
  }

  // You might also want to add this getter for expiry time
  String get expiresIn {
    final now = DateTime.now();
    final difference = expiryTime.difference(now);

    if (difference.inSeconds < 0) {
      return 'Expired';
    } else if (difference.inMinutes < 60) {
      return 'Expires in ${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'}';
    } else if (difference.inHours < 24) {
      return 'Expires in ${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'}';
    } else {
      return 'Expires in ${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'}';
    }
  }
}
