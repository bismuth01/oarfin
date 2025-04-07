class FriendModel {
  final String id;
  final String userId;
  final String? requestorID; // Add this field
  final bool isRequestor; // Add this field
  final String displayName;
  final String email;
  final double? latitude;
  final double? longitude;
  final DateTime? lastLocationUpdate;
  final bool hasActiveAlerts;
  final List<String> activeAlertIds;
  final FriendStatus status;
  final int? batteryLevel;
  final String? photoUrl;

  FriendModel({
    required this.id,
    required this.userId,
    this.requestorID, // Add this field
    this.isRequestor = false, // Add this field with default
    required this.displayName,
    required this.email, //ye break kar sakta keep an eye on it
    this.latitude,
    this.longitude,
    this.lastLocationUpdate,
    this.hasActiveAlerts = false,
    this.activeAlertIds = const [],
    required this.status,
    this.batteryLevel,
    this.photoUrl,
  });

  // Update fromJson method
  factory FriendModel.fromJson(Map<String, dynamic> json) {
    print('Parsing FriendModel: ${json.toString()}');

    // Handle special case for email which might be null
    final email = json['email'] as String? ?? 'unknown@example.com';

    return FriendModel(
      id: json['id'].toString(),
      userId: json['userId'].toString(),
      requestorID: json['requestorID']?.toString(),
      isRequestor: json['isRequestor'] == true,
      displayName: json['displayName'] ?? 'Unknown User',
      email: email, // Use the safely accessed email
      latitude: json['latitude'] != null
          ? double.parse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.parse(json['longitude'].toString())
          : null,
      lastLocationUpdate: json['lastLocationUpdate'] != null
          ? DateTime.parse(json['lastLocationUpdate'])
          : null,
      hasActiveAlerts: json['hasActiveAlerts'] == true ||
          (json['activeAlertsCount'] is num && json['activeAlertsCount'] > 0),
      activeAlertIds: json['activeAlertIds'] != null
          ? List<String>.from(json['activeAlertIds'])
          : [],
      status: _parseStatus(json['status']),
      batteryLevel: json['batteryLevel'],
      photoUrl: json['photoUrl'],
    );
  }

  // Convert to JSON (for Firestore)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'latitude': latitude,
      'longitude': longitude,
      'lastLocationUpdate': lastLocationUpdate?.toIso8601String(),
      'hasActiveAlerts': hasActiveAlerts,
      'activeAlertIds': activeAlertIds,
      'status': status.toString().split('.').last,
    };
  }

  static FriendStatus _parseStatus(String? statusStr) {
    if (statusStr == null) return FriendStatus.pending;

    switch (statusStr.toLowerCase()) {
      case 'pending':
        return FriendStatus.pending;
      case 'accepted':
        return FriendStatus.accepted;
      case 'rejected':
        return FriendStatus.rejected;
      default:
        return FriendStatus.pending; // Default status
    }
  }

  FriendModel copyWith({
    String? id,
    String? userId,
    String? requestorID,
    bool? isRequestor,
    String? displayName,
    String? email,
    double? latitude,
    double? longitude,
    DateTime? lastLocationUpdate,
    bool? hasActiveAlerts,
    List<String>? activeAlertIds,
    FriendStatus? status,
    int? batteryLevel,
    String? photoUrl,
  }) {
    return FriendModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      requestorID: requestorID ?? this.requestorID,
      isRequestor: isRequestor ?? this.isRequestor,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      lastLocationUpdate: lastLocationUpdate ?? this.lastLocationUpdate,
      hasActiveAlerts: hasActiveAlerts ?? this.hasActiveAlerts,
      activeAlertIds: activeAlertIds ?? this.activeAlertIds,
      status: status ?? this.status,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  // Check if location is recent (within last hour)
  bool get hasRecentLocation =>
      lastLocationUpdate != null &&
      DateTime.now().difference(lastLocationUpdate!).inHours < 1;

  // Get location age string
  String get locationAgeString {
    if (lastLocationUpdate == null) return 'No location data';

    final now = DateTime.now();
    final difference = now.difference(lastLocationUpdate!);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    }
  }
}

// Friend status enum
enum FriendStatus { pending, accepted, rejected, blocked }
