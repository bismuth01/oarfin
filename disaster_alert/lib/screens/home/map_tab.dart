import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../services/location_service.dart';
import '../../services/alert_service.dart';
import '../../services/friend_service.dart';
import '../../services/tab_navigation_service.dart'; // Add this import
import '../../models/alert_model.dart';
import '../../models/friend_model.dart';
import '../../utils/theme.dart';
import '../alerts/alert_details_screen.dart';
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
  final LatLng _center = const LatLng(37.7749, -122.4194); // San Francisco

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
        // Note: This requires an account with a map provider.
        // Using a placeholder satellite map URL here:
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
                  .map((alert) => Marker(
                        point: LatLng(alert.latitude, alert.longitude),
                        child: GestureDetector(
                          onTap: () => _showAlertInfo(alert),
                          child: Icon(
                            _getSeverityIcon(alert.severity),
                            color: Color(alert.getColorValue()),
                            size: 30,
                          ),
                        ),
                      ))
                  .toList(),
            ),

            // Safe location markers
            if (_showSafeZones)
              MarkerLayer(
                markers: safeLocations
                    .map((safeLocation) => Marker(
                          point: LatLng(
                              safeLocation.latitude, safeLocation.longitude),
                          child: GestureDetector(
                            onTap: () => _showSafeLocationInfo(safeLocation),
                            child: const Icon(
                              Icons.local_hospital,
                              color: AppColors.safeZone,
                              size: 30,
                            ),
                          ),
                        ))
                    .toList(),
              ),

            // Friend markers
            if (_showFriends)
              MarkerLayer(
                markers: friends
                    .map((friend) => Marker(
                          point: friend.latitude != null &&
                                  friend.longitude != null
                              ? LatLng(friend.latitude!, friend.longitude!)
                              : _center,
                          child: GestureDetector(
                            onTap: () => _showFriendInfo(friend),
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
                                        border: Border.all(
                                            color: Colors.white, width: 1),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ))
                    .toList(),
              ),

            // User location marker
            if (locationService.currentPosition != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(
                      locationService.currentPosition!.latitude,
                      locationService.currentPosition!.longitude,
                    ),
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
                  ),
                ],
              ),
          ],
        ),

        // Map controls
        Positioned(
          top: 16,
          right: 16,
          child: Column(
            children: [
              _buildMapButton(
                icon: Icons.layers,
                tooltip: 'Change Map Type',
                onPressed: () {
                  // Show a popup menu for map type selection
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
                },
              ),
              const SizedBox(height: 8),
              _buildMapButton(
                icon: Icons.my_location,
                tooltip: 'My Location',
                onPressed: () {
                  _goToCurrentLocation();
                },
              ),
              const SizedBox(height: 8),
              _buildMapButton(
                icon: Icons.refresh,
                tooltip: 'Refresh Alerts',
                onPressed: () {
                  // Refresh all map data
                  _loadMapData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Refreshing map data...'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        // Alert filter controls
        Positioned(
          bottom: 24,
          left: 16,
          right: 16,
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Map Filters',
                    style: AppTextStyles.headline3,
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                          label: 'Critical',
                          color: AppColors.criticalAlert,
                          isSelected: _showCritical,
                          onSelected: (selected) {
                            setState(() {
                              _showCritical = selected;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: 'Warning',
                          color: AppColors.warningAlert,
                          isSelected: _showWarning,
                          onSelected: (selected) {
                            setState(() {
                              _showWarning = selected;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: 'Watch',
                          color: AppColors.watchAlert,
                          isSelected: _showWatch,
                          onSelected: (selected) {
                            setState(() {
                              _showWatch = selected;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: 'Info',
                          color: AppColors.infoAlert,
                          isSelected: _showInfo,
                          onSelected: (selected) {
                            setState(() {
                              _showInfo = selected;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: 'Friends',
                          color: AppColors.primary,
                          isSelected: _showFriends,
                          onSelected: (selected) {
                            setState(() {
                              _showFriends = selected;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: 'Safe Zones',
                          color: AppColors.safeZone,
                          isSelected: _showSafeZones,
                          onSelected: (selected) {
                            setState(() {
                              _showSafeZones = selected;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required Color color,
    required bool isSelected,
    required Function(bool) onSelected,
  }) {
    return FilterChip(
      label: Text(label),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      selected: isSelected,
      selectedColor: color,
      backgroundColor: Colors.grey.shade200,
      checkmarkColor: Colors.white,
      onSelected: onSelected,
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
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Color(alert.getColorValue()),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    alert.severity.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    alert.title,
                    style: AppTextStyles.headline3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              alert.description,
              style: AppTextStyles.body1,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            if (alert.safeLocations != null && alert.safeLocations!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Safe Locations Available',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.safeZone,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${alert.safeLocations!.length} safe zones near this alert',
                    style: AppTextStyles.body2,
                  ),
                ],
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CLOSE'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Navigate to alert details screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AlertDetailsScreen(alert: alert),
                      ),
                    );
                  },
                  child: const Text('VIEW DETAILS'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSafeLocationInfo(dynamic safeLocation) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.safeZone,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'SAFE ZONE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    safeLocation.type ?? 'Safe Location',
                    style: AppTextStyles.headline3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              safeLocation.description ??
                  'This location has been designated as a safe zone for the current emergency.',
              style: AppTextStyles.body1,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CLOSE'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    // Open map with directions to the safe location
                    final latitude = safeLocation.latitude;
                    final longitude = safeLocation.longitude;
                    final url =
                        'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=driving';
                    final uri = Uri.parse(url);

                    try {
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Could not open maps application'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text('Error opening maps: ${e.toString()}'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('GET DIRECTIONS'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showFriendInfo(FriendModel friend) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  child: Text(
                    friend.displayName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        friend.displayName,
                        style: AppTextStyles.headline3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        friend.email,
                        style: AppTextStyles.body2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (friend.lastLocationUpdate != null)
              Text(
                'Last updated: ${_formatTimestamp(friend.lastLocationUpdate!)}',
                style: AppTextStyles.body2.copyWith(color: Colors.grey),
              ),
            if (friend.hasActiveAlerts)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.warning, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber,
                          color: AppColors.warning, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'This friend has active alerts in their area',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CLOSE'),
                ),
                const SizedBox(width: 8),
                if (friend.hasActiveAlerts)
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Show a dialog or bottom sheet with the friend's alerts
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        builder: (context) {
                          // Get alerts for this friend
                          final alertIds = friend.activeAlertIds ?? [];
                          final alertService =
                              Provider.of<AlertService>(context, listen: false);
                          final friendAlerts = alertService.alerts
                              .where((alert) => alertIds.contains(alert.id))
                              .toList();

                          return DraggableScrollableSheet(
                            initialChildSize: 0.5,
                            minChildSize: 0.3,
                            maxChildSize: 0.8,
                            expand: false,
                            builder: (context, scrollController) {
                              return Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: AppColors.primary
                                              .withOpacity(0.2),
                                          child: Text(
                                            friend.displayName
                                                .substring(0, 1)
                                                .toUpperCase(),
                                            style: const TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            '${friend.displayName}\'s Alerts',
                                            style: AppTextStyles.headline3,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.close),
                                          onPressed: () =>
                                              Navigator.pop(context),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Divider(),
                                  if (friendAlerts.isEmpty)
                                    const Expanded(
                                      child: Center(
                                        child: Text(
                                          'No details available for alerts in this area',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ),
                                    )
                                  else
                                    Expanded(
                                      child: ListView.builder(
                                        controller: scrollController,
                                        padding: const EdgeInsets.all(16),
                                        itemCount: friendAlerts.length,
                                        itemBuilder: (context, index) {
                                          final alert = friendAlerts[index];
                                          return Card(
                                            margin: const EdgeInsets.only(
                                                bottom: 12),
                                            child: ListTile(
                                              leading: CircleAvatar(
                                                backgroundColor: Color(
                                                    alert.getColorValue()),
                                                child: Icon(
                                                  _getSeverityIcon(
                                                      alert.severity),
                                                  color: Colors.white,
                                                  size: 18,
                                                ),
                                              ),
                                              title: Text(alert.title),
                                              subtitle: Text(
                                                alert.description,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              onTap: () {
                                                Navigator.pop(context);
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        AlertDetailsScreen(
                                                            alert: alert),
                                                  ),
                                                );
                                              },
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                ],
                              );
                            },
                          );
                        },
                      );
                    },
                    child: const Text('VIEW ALERTS'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else {
      return '${timestamp.month}/${timestamp.day}/${timestamp.year}';
    }
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

  IconData _getSeverityIcon(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Icons.warning_amber;
      case 'warning':
        return Icons.notifications_active;
      case 'watch':
        return Icons.visibility;
      case 'info':
        return Icons.info_outline;
      default:
        return Icons.notifications;
    }
  }
}
