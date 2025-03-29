class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final List<String> friendIds;
  final bool isAnonymous;

  UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.friendIds = const [],
    this.isAnonymous = false,
  });

  // Create from JSON (for Firestore)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      photoUrl: json['photoUrl'] as String?,
      friendIds:
          (json['friendIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      isAnonymous: json['isAnonymous'] as bool? ?? false,
    );
  }

  // Convert to JSON (for Firestore)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'friendIds': friendIds,
      'isAnonymous': isAnonymous,
    };
  }

  // Create a copy with updated fields
  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    List<String>? friendIds,
    bool? isAnonymous,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      friendIds: friendIds ?? this.friendIds,
      isAnonymous: isAnonymous ?? this.isAnonymous,
    );
  }
}
