// services/mock_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import '../models/alert_model.dart';
import '../models/friend_model.dart';
import 'auth_service.dart';
import 'dart:math';

class MockApiService extends ApiService {
  // Control variables for testing
  bool simulateNetworkError = false;
  bool simulateServerError = false;
  bool simulateAuthError = false;

  // Constructor - make sure it matches the parent class structure
  MockApiService({AuthService? authService})
      : super(baseUrl: 'mock://api', authService: authService);

  // Add a simple method to verify the mock service is working
  bool get isMockService => true;

  // Mock database of alerts
  final List<Map<String, dynamic>> _mockAlerts = [
    {
      'id': 'mock-alert-1',
      'title': 'Flash Flood Warning',
      'description':
          'Flash flooding is expected in your area. Move to higher ground immediately.',
      'severity': 'Critical',
      'timestamp': DateTime.now()
          .subtract(const Duration(minutes: 10))
          .toIso8601String(),
      'expiryTime':
          DateTime.now().add(const Duration(hours: 6)).toIso8601String(),
      'latitude': 37.7749,
      'longitude': -122.4194,
      'radius': 5000,
      'source': 'MOCK NOAA',
      'isActive': true,
    },
    // Additional mock alerts
  ];

  // Mock database of users
  final List<Map<String, dynamic>> _mockUsers = [
    {
      'userID': 'user-1',
      'email': 'john@example.com',
      'displayName': 'John Doe',
      'latitude': 37.7749,
      'longitude': -122.4194,
      'radius': 10000,
    },
    // Additional mock users
  ];

  // Mock database of friends
  final List<Map<String, dynamic>> _mockFriends = [
    {
      'id': '1',
      'requestorID': 'current-user',
      'userId': 'user-1',
      'status': 'accepted',
      'lastLocationUpdate': DateTime.now()
          .subtract(const Duration(minutes: 15))
          .toIso8601String(),
      'displayName': 'John Doe',
      'email': 'john@example.com',
      'latitude': 37.7749,
      'longitude': -122.4194,
      'hasActiveAlerts': true,
      'activeAlertIds': ['mock-alert-1', 'mock-alert-2'],
    },
    // Additional mock friends
  ];

  // Helper method to simulate network delay
  Future<void> _simulateNetworkDelay() async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<http.Response> get(String endpoint,
      {Map<String, dynamic>? queryParams}) async {
    await _simulateNetworkDelay();

    // Check for simulated errors
    if (simulateNetworkError) {
      throw Exception('Simulated network error');
    }

    if (simulateServerError) {
      return http.Response('{"error": "Internal Server Error"}', 500);
    }

    if (simulateAuthError) {
      return http.Response('{"error": "Unauthorized"}', 401);
    }

    // Handle endpoints
    if (endpoint == '/api/test/ping') {
      return http.Response(
          '{"status": "success", "message": "Mock API is working!"}', 200);
    } else if (endpoint == '/get-alerts') {
      return _handleGetAlerts(queryParams);
    } else if (endpoint.startsWith('/api/friends')) {
      final status = queryParams?['status'] ?? 'accepted';
      return _handleGetFriends(status);
    }

    // Default response for unhandled endpoints
    print('Unhandled mock GET endpoint: $endpoint');
    return http.Response('{"error": "Endpoint not implemented in mock"}', 404);
  }

  @override
  Future<http.Response> post(String endpoint,
      {required Map<String, dynamic> data}) async {
    await _simulateNetworkDelay();

    // Check for simulated errors
    if (simulateNetworkError) {
      throw Exception('Simulated network error');
    }

    if (simulateServerError) {
      return http.Response('{"error": "Internal Server Error"}', 500);
    }

    if (simulateAuthError) {
      return http.Response('{"error": "Unauthorized"}', 401);
    }

    // Handle endpoints
    if (endpoint == '/api/location/update') {
      return _handleLocationUpdate(data);
    } else if (endpoint == '/api/location/update-and-get-alerts') {
      return _handleUpdateLocationAndGetAlerts(data);
    } else if (endpoint == '/api/friends/request') {
      return _handleFriendRequest(data);
    } else if (endpoint == '/api/test/echo') {
      return http.Response('{"echo": ${json.encode(data)}}', 200);
    }

    // Default response for unhandled endpoints
    print('Unhandled mock POST endpoint: $endpoint');
    return http.Response('{"error": "Endpoint not implemented in mock"}', 404);
  }

  @override
  Future<http.Response> put(String endpoint,
      {required Map<String, dynamic> data}) async {
    await _simulateNetworkDelay();

    // Check for simulated errors
    if (simulateNetworkError) {
      throw Exception('Simulated network error');
    }

    if (simulateServerError) {
      return http.Response('{"error": "Internal Server Error"}', 500);
    }

    if (simulateAuthError) {
      return http.Response('{"error": "Unauthorized"}', 401);
    }

    // Handle endpoints
    if (endpoint == '/api/friends/respond') {
      return _handleFriendResponse(data);
    } else if (endpoint.contains('/api/friends/') &&
        endpoint.contains('/location')) {
      // Extract friend ID from the URL
      final friendId = endpoint.split('/')[3];
      return _handleUpdateFriendLocation(friendId, data);
    }

    // Default response for unhandled endpoints
    print('Unhandled mock PUT endpoint: $endpoint');
    return http.Response('{"error": "Endpoint not implemented in mock"}', 404);
  }

  @override
  Future<http.Response> delete(String endpoint) async {
    await _simulateNetworkDelay();

    // Check for simulated errors
    if (simulateNetworkError) {
      throw Exception('Simulated network error');
    }

    if (simulateServerError) {
      return http.Response('{"error": "Internal Server Error"}', 500);
    }

    if (simulateAuthError) {
      return http.Response('{"error": "Unauthorized"}', 401);
    }

    // Handle endpoints
    if (endpoint.startsWith('/api/friends/')) {
      final friendId = endpoint.split('/').last;
      return _handleRemoveFriend(friendId);
    }

    // Default response for unhandled endpoints
    print('Unhandled mock DELETE endpoint: $endpoint');
    return http.Response('{"error": "Endpoint not implemented in mock"}', 404);
  }

  // Handler methods
  Future<http.Response> _handleGetAlerts(
      Map<String, dynamic>? queryParams) async {
    // Process query parameters
    final latitude = double.tryParse(queryParams?['latitude'] ?? '0') ?? 0;
    final longitude = double.tryParse(queryParams?['longitude'] ?? '0') ?? 0;
    final radius = double.tryParse(queryParams?['radius'] ?? '0') ?? 0;

    print(
        'Mock getting alerts for location: $latitude, $longitude with radius: $radius');

    // Filter alerts based on location and radius
    final filteredAlerts = _mockAlerts.where((alert) {
      // Simple distance calculation for testing
      final dx = (alert['latitude'] as double) - latitude;
      final dy = (alert['longitude'] as double) - longitude;
      final distance =
          sqrt(dx * dx + dy * dy) * 111000; // Rough conversion to meters

      return distance <= radius;
    }).toList();

    return http.Response(json.encode(filteredAlerts), 200);
  }

  Future<http.Response> _handleLocationUpdate(Map<String, dynamic> data) async {
    // Validate required fields
    if (!data.containsKey('userID') ||
        !data.containsKey('latitude') ||
        !data.containsKey('longitude') ||
        !data.containsKey('radius')) {
      return http.Response('{"error": "Missing required fields"}', 400);
    }

    print('Mock updating location for user: ${data['userID']}');

    // Update mock user data (in a real implementation, this would modify the in-memory database)
    final userIndex =
        _mockUsers.indexWhere((user) => user['userID'] == data['userID']);

    if (userIndex >= 0) {
      _mockUsers[userIndex]['latitude'] = data['latitude'];
      _mockUsers[userIndex]['longitude'] = data['longitude'];
      _mockUsers[userIndex]['radius'] = data['radius'];
    } else {
      // Add new user
      _mockUsers.add({
        'userID': data['userID'],
        'latitude': data['latitude'],
        'longitude': data['longitude'],
        'radius': data['radius'],
        'email': 'mock@example.com',
        'displayName': 'Mock User',
      });
    }

    return http.Response(
        '{"message": "User location updated successfully"}', 200);
  }

  Future<http.Response> _handleUpdateLocationAndGetAlerts(
      Map<String, dynamic> data) async {
    // First update location
    final locationResponse = await _handleLocationUpdate(data);

    if (locationResponse.statusCode != 200) {
      return locationResponse;
    }

    // Then get alerts
    final queryParams = {
      'latitude': data['latitude'].toString(),
      'longitude': data['longitude'].toString(),
      'radius': data['radius'].toString(),
    };

    return _handleGetAlerts(queryParams);
  }

  Future<http.Response> _handleGetFriends(String status) async {
    print('Mock getting friends with status: $status');

    final filteredFriends =
        _mockFriends.where((friend) => friend['status'] == status).toList();

    return http.Response(json.encode(filteredFriends), 200);
  }

  Future<http.Response> _handleFriendRequest(Map<String, dynamic> data) async {
    // Validate required fields
    if (!data.containsKey('email')) {
      return http.Response('{"error": "Missing required fields"}', 400);
    }

    final email = data['email'];
    print('Mock sending friend request to: $email');

    // Check if friend already exists
    final existingFriend =
        _mockFriends.any((friend) => friend['email'] == email);

    if (existingFriend) {
      return http.Response('{"error": "Friend request already exists"}', 409);
    }

    // Create fake pending request
    _mockFriends.add({
      'id': 'mock-pending-${DateTime.now().millisecondsSinceEpoch}',
      'requestorID': 'current-user',
      'userId': 'mock-user-${DateTime.now().millisecondsSinceEpoch}',
      'status': 'pending',
      'displayName': 'Pending User',
      'email': email,
      'lastLocationUpdate': DateTime.now().toIso8601String(),
    });

    return http.Response(
        '{"message": "Friend request sent", "id": "mock-pending-id"}', 201);
  }

  Future<http.Response> _handleFriendResponse(Map<String, dynamic> data) async {
    // Validate required fields
    if (!data.containsKey('requestId') || !data.containsKey('status')) {
      return http.Response('{"error": "Missing required fields"}', 400);
    }

    final requestId = data['requestId'];
    final status = data['status'];

    print('Mock responding to friend request $requestId with status: $status');

    if (status == 'accept') {
      // Find the request
      final index =
          _mockFriends.indexWhere((friend) => friend['id'] == requestId);

      if (index < 0) {
        return http.Response('{"error": "Friend request not found"}', 404);
      }

      // Update status
      _mockFriends[index]['status'] = 'accepted';

      return http.Response('{"message": "Friend request accepted"}', 200);
    } else if (status == 'reject') {
      // Remove the request
      _mockFriends.removeWhere((friend) => friend['id'] == requestId);

      return http.Response('{"message": "Friend request rejected"}', 200);
    } else {
      return http.Response('{"error": "Invalid status"}', 400);
    }
  }

  Future<http.Response> _handleRemoveFriend(String friendId) async {
    print('Mock removing friend: $friendId');

    // Remove the friend
    final initialCount = _mockFriends.length;
    _mockFriends.removeWhere((friend) => friend['userId'] == friendId);

    if (_mockFriends.length == initialCount) {
      return http.Response('{"error": "Friend relationship not found"}', 404);
    }

    return http.Response('{"message": "Friend removed successfully"}', 200);
  }

  Future<http.Response> _handleUpdateFriendLocation(
      String friendId, Map<String, dynamic> data) async {
    // Validate required fields
    if (!data.containsKey('latitude') || !data.containsKey('longitude')) {
      return http.Response('{"error": "Missing required fields"}', 400);
    }

    print(
        'Mock updating friend $friendId location to: ${data['latitude']}, ${data['longitude']}');

    // Find the friend
    final index =
        _mockFriends.indexWhere((friend) => friend['userId'] == friendId);

    if (index < 0) {
      return http.Response('{"error": "Friend relationship not found"}', 404);
    }

    // Update location
    _mockFriends[index]['latitude'] = data['latitude'];
    _mockFriends[index]['longitude'] = data['longitude'];
    _mockFriends[index]['lastLocationUpdate'] =
        DateTime.now().toIso8601String();

    return http.Response('{"message": "Friend location updated"}', 200);
  }
}
