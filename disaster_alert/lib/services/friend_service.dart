import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/friend_model.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

class FriendService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService;

  List<FriendModel> _friends = [];
  List<FriendModel> _pendingRequests = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<FriendModel> get friends => _friends;
  List<FriendModel> get pendingRequests => _pendingRequests;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Constructor with dependency injection
  FriendService(this._authService) {
    // Listen to auth changes
    _authService.addListener(_onAuthChanged);

    // Initial load
    if (_authService.currentUser != null &&
        !_authService.currentUser!.isAnonymous) {
      _loadFriends();
    }
  }

  // Clean up listeners when disposed
  @override
  void dispose() {
    _authService.removeListener(_onAuthChanged);
    super.dispose();
  }

  // Handle auth changes
  void _onAuthChanged() {
    if (_authService.currentUser != null &&
        !_authService.currentUser!.isAnonymous) {
      _loadFriends();
    } else {
      // Clear friends if logged out or anonymous
      _friends = [];
      _pendingRequests = [];
      notifyListeners();
    }
  }

  // Load friends from Firestore
  Future<void> _loadFriends() async {
    if (_authService.currentUser == null ||
        _authService.currentUser!.isAnonymous)
      return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userId = _authService.currentUser!.uid;

      // Get friends
      final friendsSnapshot =
          await _firestore
              .collection('friends')
              .where('userId', isEqualTo: userId)
              .where('status', isEqualTo: 'accepted')
              .get();

      _friends =
          friendsSnapshot.docs
              .map((doc) => FriendModel.fromJson({'id': doc.id, ...doc.data()}))
              .toList();

      // Get pending requests
      final pendingSnapshot =
          await _firestore
              .collection('friends')
              .where('userId', isEqualTo: userId)
              .where('status', isEqualTo: 'pending')
              .get();

      _pendingRequests =
          pendingSnapshot.docs
              .map((doc) => FriendModel.fromJson({'id': doc.id, ...doc.data()}))
              .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load friends: ${e.toString()}';
      _isLoading = false;

      // For demo purposes, generate some fake friends
      _generateFakeFriends();

      notifyListeners();
    }
  }

  // Generate fake friends for demo
  void _generateFakeFriends() {
    _friends = [
      FriendModel(
        id: '1',
        userId: 'user1',
        displayName: 'John Doe',
        email: 'john@example.com',
        latitude: 37.7749,
        longitude: -122.4194,
        lastLocationUpdate: DateTime.now().subtract(
          const Duration(minutes: 15),
        ),
        hasActiveAlerts: true,
        activeAlertIds: ['alert1', 'alert2'],
        status: FriendStatus.accepted,
      ),
      FriendModel(
        id: '2',
        userId: 'user2',
        displayName: 'Jane Smith',
        email: 'jane@example.com',
        latitude: 37.3382,
        longitude: -121.8863,
        lastLocationUpdate: DateTime.now().subtract(const Duration(hours: 2)),
        hasActiveAlerts: false,
        status: FriendStatus.accepted,
      ),
      FriendModel(
        id: '3',
        userId: 'user3',
        displayName: 'Mike Johnson',
        email: 'mike@example.com',
        latitude: 37.4419,
        longitude: -122.1430,
        lastLocationUpdate: DateTime.now().subtract(
          const Duration(minutes: 45),
        ),
        hasActiveAlerts: true,
        activeAlertIds: ['alert3'],
        status: FriendStatus.accepted,
      ),
    ];

    _pendingRequests = [
      FriendModel(
        id: '4',
        userId: 'user4',
        displayName: 'Sarah Parker',
        email: 'sarah@example.com',
        status: FriendStatus.pending,
      ),
    ];
  }

  // Send friend request
  Future<bool> sendFriendRequest(String email) async {
    if (_authService.currentUser == null ||
        _authService.currentUser!.isAnonymous) {
      _errorMessage = 'You need to be logged in to add friends';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Check if user exists
      final userSnapshot =
          await _firestore
              .collection('users')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

      if (userSnapshot.docs.isEmpty) {
        _errorMessage = 'User with this email not found';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final friendData = userSnapshot.docs.first.data();
      final friendId = userSnapshot.docs.first.id;

      // Check if this is the current user
      if (friendId == _authService.currentUser!.uid) {
        _errorMessage = 'You cannot add yourself as a friend';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Check if already friends or pending
      final existingSnapshot =
          await _firestore
              .collection('friends')
              .where('userId', isEqualTo: _authService.currentUser!.uid)
              .where('friendId', isEqualTo: friendId)
              .limit(1)
              .get();

      if (existingSnapshot.docs.isNotEmpty) {
        final status = existingSnapshot.docs.first.data()['status'];
        if (status == 'accepted') {
          _errorMessage = 'You are already friends with this user';
        } else if (status == 'pending') {
          _errorMessage = 'Friend request already sent';
        } else if (status == 'blocked') {
          _errorMessage = 'This user is blocked';
        }
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Create friend request
      await _firestore.collection('friends').add({
        'userId': _authService.currentUser!.uid,
        'friendId': friendId,
        'displayName': friendData['displayName'] ?? 'User',
        'email': email,
        'photoUrl': friendData['photoUrl'],
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Create reverse entry for the other user
      await _firestore.collection('friendRequests').add({
        'userId': friendId,
        'friendId': _authService.currentUser!.uid,
        'displayName': _authService.userModel?.displayName ?? 'User',
        'email': _authService.userModel?.email ?? '',
        'photoUrl': _authService.userModel?.photoUrl,
        'status': 'received',
        'createdAt': FieldValue.serverTimestamp(),
      });

      _isLoading = false;

      // Reload friends
      _loadFriends();

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to send friend request: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Accept friend request
  Future<bool> acceptFriendRequest(String requestId) async {
    if (_authService.currentUser == null ||
        _authService.currentUser!.isAnonymous)
      return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Update friend request status
      await _firestore.collection('friendRequests').doc(requestId).update({
        'status': 'accepted',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Get the request data
      final requestSnapshot =
          await _firestore.collection('friendRequests').doc(requestId).get();
      final requestData = requestSnapshot.data();

      if (requestData == null) {
        _errorMessage = 'Friend request not found';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Find the original request from the other user
      final originalRequestSnapshot =
          await _firestore
              .collection('friends')
              .where('userId', isEqualTo: requestData['friendId'])
              .where('friendId', isEqualTo: _authService.currentUser!.uid)
              .limit(1)
              .get();

      if (originalRequestSnapshot.docs.isNotEmpty) {
        // Update original request
        await _firestore
            .collection('friends')
            .doc(originalRequestSnapshot.docs.first.id)
            .update({
              'status': 'accepted',
              'updatedAt': FieldValue.serverTimestamp(),
            });
      }

      // Create a new friend entry for the current user
      await _firestore.collection('friends').add({
        'userId': _authService.currentUser!.uid,
        'friendId': requestData['friendId'],
        'displayName': requestData['displayName'],
        'email': requestData['email'],
        'photoUrl': requestData['photoUrl'],
        'status': 'accepted',
        'createdAt': FieldValue.serverTimestamp(),
      });

      _isLoading = false;

      // Reload friends
      _loadFriends();

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to accept friend request: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Reject friend request
  Future<bool> rejectFriendRequest(String requestId) async {
    if (_authService.currentUser == null ||
        _authService.currentUser!.isAnonymous)
      return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Update friend request status
      await _firestore.collection('friendRequests').doc(requestId).update({
        'status': 'rejected',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Get the request data
      final requestSnapshot =
          await _firestore.collection('friendRequests').doc(requestId).get();
      final requestData = requestSnapshot.data();

      if (requestData == null) {
        _errorMessage = 'Friend request not found';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Find the original request from the other user
      final originalRequestSnapshot =
          await _firestore
              .collection('friends')
              .where('userId', isEqualTo: requestData['friendId'])
              .where('friendId', isEqualTo: _authService.currentUser!.uid)
              .limit(1)
              .get();

      if (originalRequestSnapshot.docs.isNotEmpty) {
        // Update original request
        await _firestore
            .collection('friends')
            .doc(originalRequestSnapshot.docs.first.id)
            .update({
              'status': 'rejected',
              'updatedAt': FieldValue.serverTimestamp(),
            });
      }

      _isLoading = false;

      // Reload friends
      _loadFriends();

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to reject friend request: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Remove friend
  Future<bool> removeFriend(String friendId) async {
    if (_authService.currentUser == null ||
        _authService.currentUser!.isAnonymous)
      return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Find the friend entry
      final friendSnapshot =
          await _firestore
              .collection('friends')
              .where('userId', isEqualTo: _authService.currentUser!.uid)
              .where('friendId', isEqualTo: friendId)
              .limit(1)
              .get();

      if (friendSnapshot.docs.isEmpty) {
        _errorMessage = 'Friend not found';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Delete the friend entry
      await _firestore
          .collection('friends')
          .doc(friendSnapshot.docs.first.id)
          .delete();

      // Find the reverse entry
      final reverseSnapshot =
          await _firestore
              .collection('friends')
              .where('userId', isEqualTo: friendId)
              .where('friendId', isEqualTo: _authService.currentUser!.uid)
              .limit(1)
              .get();

      if (reverseSnapshot.docs.isNotEmpty) {
        // Delete the reverse entry
        await _firestore
            .collection('friends')
            .doc(reverseSnapshot.docs.first.id)
            .delete();
      }

      _isLoading = false;

      // Update local list
      _friends.removeWhere((friend) => friend.userId == friendId);
      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = 'Failed to remove friend: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update friend location
  Future<bool> updateFriendLocation(
    String friendId,
    double latitude,
    double longitude,
  ) async {
    if (_authService.currentUser == null ||
        _authService.currentUser!.isAnonymous)
      return false;

    try {
      // Find the friend entry
      final friendSnapshot =
          await _firestore
              .collection('friends')
              .where('userId', isEqualTo: _authService.currentUser!.uid)
              .where('friendId', isEqualTo: friendId)
              .limit(1)
              .get();

      if (friendSnapshot.docs.isEmpty) return false;

      // Update the location
      await _firestore
          .collection('friends')
          .doc(friendSnapshot.docs.first.id)
          .update({
            'latitude': latitude,
            'longitude': longitude,
            'lastLocationUpdate': FieldValue.serverTimestamp(),
          });

      // Update local data
      final index = _friends.indexWhere((friend) => friend.userId == friendId);
      if (index >= 0) {
        _friends[index] = _friends[index].copyWith(
          latitude: latitude,
          longitude: longitude,
          lastLocationUpdate: DateTime.now(),
        );
        notifyListeners();
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // Get friends with active alerts
  List<FriendModel> getFriendsWithAlerts() {
    return _friends.where((friend) => friend.hasActiveAlerts).toList();
  }

  // Get friend by ID
  FriendModel? getFriendById(String friendId) {
    try {
      return _friends.firstWhere((friend) => friend.userId == friendId);
    } catch (e) {
      return null;
    }
  }
}
