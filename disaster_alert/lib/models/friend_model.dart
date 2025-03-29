class FriendModel {
  final String id;
  final String userId;
  final String displayName;
  final String email;
  final String? photoUrl;
  final double? latitude;
  final double? longitude;
  final DateTime? lastLocationUpdate;
  final bool hasActiveAlerts;
  final List<String>? activeAlertIds;
  final FriendStatus status;

  FriendModel({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.email,
    this.photoUrl,
    this.latitude,
    this.longitude,
    this.lastLocationUpdate,
    this.hasActiveAlerts = false,
    this.activeAlertIds,
    this.status = FriendStatus.accepted,
  });

  // Create from JSON (for Firestore)
  factory FriendModel.fromJson(Map<String, dynamic> json) {
    return FriendModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      email: json['email'] as String,
      photoUrl: json['photoUrl'] as String?,
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      lastLocationUpdate:
          json['lastLocationUpdate'] != null
              ? DateTime.parse(json['lastLocationUpdate'] as String)
              : null,
      hasActiveAlerts: json['hasActiveAlerts'] as bool? ?? false,
      activeAlertIds:
          (json['activeAlertIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList(),
      status: FriendStatus.values.firstWhere(
        (e) => e.toString() == 'FriendStatus.${json['status']}',
        orElse: () => FriendStatus.pending,
      ),
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

  // Create a copy with updated fields
  FriendModel copyWith({
    String? id,
    String? userId,
    String? displayName,
    String? email,
    String? photoUrl,
    double? latitude,
    double? longitude,
    DateTime? lastLocationUpdate,
    bool? hasActiveAlerts,
    List<String>? activeAlertIds,
    FriendStatus? status,
  }) {
    return FriendModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      lastLocationUpdate: lastLocationUpdate ?? this.lastLocationUpdate,
      hasActiveAlerts: hasActiveAlerts ?? this.hasActiveAlerts,
      activeAlertIds: activeAlertIds ?? this.activeAlertIds,
      status: status ?? this.status,
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
