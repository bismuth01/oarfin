import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../services/location_service.dart';
import '../../services/alert_service.dart';
import '../../services/friend_service.dart';
import '../../services/tab_navigation_service.dart';
import '../../models/alert_model.dart';
import '../../models/friend_model.dart';
import '../../utils/theme.dart';
import '../../utils/map_utils.dart';
import '../../utils/map_marker_utils.dart';
import '../../widgets/map/map_controls.dart';
import '../../widgets/map/map_filter_panel.dart';
import '../../widgets/bottom_sheets/alert_info_sheet.dart';
import '../../widgets/bottom_sheets/safe_location_info_sheet.dart';
import '../../widgets/bottom_sheets/friend_info_sheet.dart';
import 'package:url_launcher/url_launcher.dart';

class MapTab extends StatefulWidget {
  const MapTab({Key? key}) : super(key: key);

  @override
  _MapTabState createState() => _MapTabState();

  // Expose state type for external access
  static Type get stateType => _MapTabState;
}

enum MapType {
  standard,
  satellite,
  terrain,
}

class _MapTabState extends State<MapTab> {
  bool _isLoading = true;
  final MapController _mapController = MapController();

  // Default map center (will be updated with user's location)
  final LatLng _center = const LatLng(28.7041, 77.1025); // New Delhi

  // Map type settings
  MapType _currentMapType = MapType.standard;

  // Filter settings
  bool _showCritical = true;
  bool _showWarning = true;
  bool _showWatch = true;
  bool _showInfo = true;
  bool _showFriends = true;
  bool _showSafeZones = true;

  @override
  void initState() {
    super.initState();
    _loadMapData();

    // Check if we need to focus on a friend
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForFriendFocus();
    });
  }

  @override
  void didUpdateWidget(MapTab oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check again when the widget updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForFriendFocus();
    });
  }

  void _checkForFriendFocus() {
    try {
      final navigationService =
          Provider.of<TabNavigationService>(context, listen: false);
      final friend = navigationService.focusFriend;

      if (friend != null &&
          friend.latitude != null &&
          friend.longitude != null) {
        // Focus on the friend's location
        _mapController.move(
          LatLng(friend.latitude!, friend.longitude!),
          15.0,
        );

        // Show a snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Showing location of ${friend.displayName}'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
        navigationService.clearFriendFocus();
        return;
      }
      final alert = navigationService.focusAlert;
      if (alert != null) {
        _mapController.move(
          LatLng(alert.latitude, alert.longitude),
          15.0,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Showing alert: ${alert.title}'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );

        navigationService.clearAlertFocus();
      }
    } catch (e) {
      print('Error checking for friend focus: $e');
      // Ignore errors from the navigation service - it might not be registered yet
    }
  }

  // Focus on a specific location
  void focusOnLocation(double latitude, double longitude, [String? name]) {
    _mapController.move(LatLng(latitude, longitude), 15.0);

    // Optionally show a popup for the focused location
    if (name != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Showing location of $name'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _loadMapData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final alertService = Provider.of<AlertService>(context, listen: false);
      final locationService =
          Provider.of<LocationService>(context, listen: false);
      final friendService = Provider.of<FriendService>(context, listen: false);

      // Fetch position first
      final position = await locationService.getCurrentPosition();

      // Then fetch alerts and friends data
      await Future.wait(
          [alertService.fetchAlerts(), friendService.refreshFriends()]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading map data: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getMapTileUrl() {
    switch (_currentMapType) {
      case MapType.standard:
        return 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
      case MapType.satellite:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case MapType.terrain:
        return 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png';
      default:
        return 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Get actual data from providers
    final alertService = Provider.of<AlertService>(context);
    final friendService = Provider.of<FriendService>(context);
    final locationService = Provider.of<LocationService>(context);

    final List<AlertModel> alerts = alertService.alerts;
    final List<FriendModel> friends = friendService.friends;

    // Get safe locations from the alert service
    final safeLocations = alertService.alerts.expand((alert) {
      return alert.safeLocations ?? [];
    }).toList();

    return Stack(
      children: [
        // Main map
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: locationService.currentPosition != null
                ? LatLng(locationService.currentPosition!.latitude,
                    locationService.currentPosition!.longitude)
                : _center,
            initialZoom: 11.0,
            onTap: (tapPosition, point) {
              // Close any open info dialogs
            },
          ),
          children: [
            // Base map layer
            TileLayer(
              urlTemplate: _getMapTileUrl(),
              subdomains: const ['a', 'b', 'c'],
            ),

            // Alert radius circles
            CircleLayer(
              circles: alerts
                  .where((alert) => _filterAlert(alert))
                  .map((alert) => CircleMarker(
                        point: LatLng(alert.latitude, alert.longitude),
                        color: Color(alert.getColorValue()).withOpacity(0.2),
                        borderColor: Color(alert.getColorValue()),
                        borderStrokeWidth: 2,
                        radius: alert.radius, // meters
                      ))
                  .toList(),
            ),

            // Alert markers
            MarkerLayer(
              markers: alerts
                  .where((alert) => _filterAlert(alert))
                  .map((alert) => MapMarkerUtils.createAlertMarker(
                        alert: alert,
                        onTap: _showAlertInfo,
                      ))
                  .toList(),
            ),

            // Safe location markers
            if (_showSafeZones)
              MarkerLayer(
                markers: safeLocations
                    .map((safeLocation) =>
                        MapMarkerUtils.createSafeLocationMarker(
                          safeLocation: safeLocation,
                          onTap: _showSafeLocationInfo,
                        ))
                    .toList(),
              ),

            // Friend markers
            if (_showFriends)
              MarkerLayer(
                markers: friends
                    .map((friend) => MapMarkerUtils.createFriendMarker(
                          friend: friend,
                          defaultLocation: _center,
                          onTap: _showFriendInfo,
                        ))
                    .toList(),
              ),

            // User location marker
            if (locationService.currentPosition != null)
              MarkerLayer(
                markers: [
                  MapMarkerUtils.createUserLocationMarker(
                    latitude: locationService.currentPosition!.latitude,
                    longitude: locationService.currentPosition!.longitude,
                  ),
                ],
              ),
          ],
        ),

        // Map controls
        MapControls(
          onMapTypePressed: _showMapTypeDialog,
          onMyLocationPressed: _goToCurrentLocation,
          onRefreshPressed: _loadMapData,
        ),

        // Alert filter controls
        MapFilterPanel(
          showCritical: _showCritical,
          showWarning: _showWarning,
          showWatch: _showWatch,
          showInfo: _showInfo,
          showFriends: _showFriends,
          showSafeZones: _showSafeZones,
          onCriticalChanged: (value) => setState(() => _showCritical = value),
          onWarningChanged: (value) => setState(() => _showWarning = value),
          onWatchChanged: (value) => setState(() => _showWatch = value),
          onInfoChanged: (value) => setState(() => _showInfo = value),
          onFriendsChanged: (value) => setState(() => _showFriends = value),
          onSafeZonesChanged: (value) => setState(() => _showSafeZones = value),
        ),
      ],
    );
  }

  void _showMapTypeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Map Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.map),
              title: const Text('Standard'),
              selected: _currentMapType == MapType.standard,
              onTap: () {
                setState(() {
                  _currentMapType = MapType.standard;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.satellite),
              title: const Text('Satellite'),
              selected: _currentMapType == MapType.satellite,
              onTap: () {
                setState(() {
                  _currentMapType = MapType.satellite;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.terrain),
              title: const Text('Terrain'),
              selected: _currentMapType == MapType.terrain,
              onTap: () {
                setState(() {
                  _currentMapType = MapType.terrain;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _goToCurrentLocation() async {
    final locationService =
        Provider.of<LocationService>(context, listen: false);
    final position = await locationService.getCurrentPosition();

    if (position != null) {
      _mapController.move(
        LatLng(position.latitude, position.longitude),
        15.0,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to get current location'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showAlertInfo(AlertModel alert) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => AlertInfoSheet(alert: alert),
    );
  }

  void _showSafeLocationInfo(dynamic safeLocation) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeLocationInfoSheet(safeLocation: safeLocation),
    );
  }

  void _showFriendInfo(FriendModel friend) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => FriendInfoSheet(friend: friend),
    );
  }

  bool _filterAlert(AlertModel alert) {
    switch (alert.severity.toLowerCase()) {
      case 'critical':
        return _showCritical;
      case 'warning':
        return _showWarning;
      case 'watch':
        return _showWatch;
      case 'info':
        return _showInfo;
      default:
        return true;
    }
  }
}
