import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/alert_model.dart';
import '../models/friend_model.dart';
import '../utils/theme.dart';
import 'map_utils.dart';

class MapMarkerUtils {
  /// Creates a marker for an alert
  static Marker createAlertMarker({
    required AlertModel alert,
    required Function(AlertModel) onTap,
  }) {
    return Marker(
      point: LatLng(alert.latitude, alert.longitude),
      width: 30,
      height: 30,
      child: GestureDetector(
        onTap: () => onTap(alert),
        child: Icon(
          MapUtils.getSeverityIcon(alert.severity),
          color: Color(alert.getColorValue()),
          size: 30,
        ),
      ),
    );
  }

  /// Creates a marker for a safe location
  static Marker createSafeLocationMarker({
    required SafeLocationModel safeLocation,
    required Function(SafeLocationModel) onTap,
  }) {
    return Marker(
      point: LatLng(safeLocation.latitude, safeLocation.longitude),
      width: 30,
      height: 30,
      child: GestureDetector(
        onTap: () => onTap(safeLocation),
        child: const Icon(
          Icons.local_hospital,
          color: AppColors.safeZone,
          size: 30,
        ),
      ),
    );
  }

  /// Creates a marker for a friend
  static Marker createFriendMarker({
    required FriendModel friend,
    required LatLng defaultLocation,
    required Function(FriendModel) onTap,
  }) {
    return Marker(
      point: friend.latitude != null && friend.longitude != null
          ? LatLng(friend.latitude!, friend.longitude!)
          : defaultLocation,
      width: 30,
      height: 30,
      child: GestureDetector(
        onTap: () => onTap(friend),
        child: Stack(
          children: [
            const Icon(
              Icons.person_pin,
              color: AppColors.primary,
              size: 30,
            ),
            if (friend.hasActiveAlerts)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.warning,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Creates a marker for the user's current location
  static Marker createUserLocationMarker({
    required double latitude,
    required double longitude,
  }) {
    return Marker(
      point: LatLng(latitude, longitude),
      width: 20,
      height: 20,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        width: 20,
        height: 20,
        child: Center(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            width: 10,
            height: 10,
          ),
        ),
      ),
    );
  }
}
