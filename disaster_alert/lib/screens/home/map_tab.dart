import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../services/location_service.dart';
import '../../services/alert_service.dart';
import '../../models/alert_model.dart';
import '../../utils/theme.dart';

class MapTab extends StatefulWidget {
  const MapTab({Key? key}) : super(key: key);

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  bool _isLoading = true;
  final MapController _mapController = MapController();

  // Default map center (will be updated with user's location)
  final LatLng _center = const LatLng(37.7749, -122.4194); // San Francisco

  // Filter settings
  bool _showCritical = true;
  bool _showWarning = true;
  bool _showWatch = true;
  bool _showInfo = true;
  bool _showFriends = true;
  bool _showSafeZones = false;

  @override
  void initState() {
    super.initState();
    _loadPlaceholderData();

    // Simulate loading delay
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  void _loadPlaceholderData() {
    // This method would be replaced with actual data loading in a real implementation
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Get placeholder alerts
    final List<AlertModel> alerts = _getPlaceholderAlerts();

    return Stack(
      children: [
        // Main map
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _center,
            initialZoom: 11.0,
            onTap: (tapPosition, point) {
              // Close any open info dialogs
            },
          ),
          children: [
            // Base map layer
            TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                  // TODO: Implement map type switching
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
                  // TODO: Refresh alerts on map
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Refreshing alerts...'),
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
                    'Alert Filters',
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
                    // TODO: Navigate to alert details
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

  List<AlertModel> _getPlaceholderAlerts() {
    final now = DateTime.now();

    return [
      AlertModel(
        id: '1',
        title: 'Flash Flood Warning',
        description:
            'Flash flooding is expected in your area. Move to higher ground immediately.',
        severity: 'Critical',
        timestamp: now.subtract(const Duration(minutes: 10)),
        expiryTime: now.add(const Duration(hours: 6)),
        latitude: 37.7749,
        longitude: -122.4194,
        radius: 5000, // 5 km
        source: 'NOAA',
      ),
      AlertModel(
        id: '2',
        title: 'Thunderstorm Watch',
        description:
            'Severe thunderstorms possible in your area in the next 6 hours.',
        severity: 'Warning',
        timestamp: now.subtract(const Duration(minutes: 30)),
        expiryTime: now.add(const Duration(hours: 12)),
        latitude: 37.8044,
        longitude: -122.2712,
        radius: 10000, // 10 km
        source: 'NOAA',
      ),
      AlertModel(
        id: '3',
        title: 'Earthquake Report',
        description:
            'Magnitude 4.2 earthquake detected 50 miles from your location.',
        severity: 'Info',
        timestamp: now.subtract(const Duration(hours: 2)),
        expiryTime: now.add(const Duration(hours: 24)),
        latitude: 37.4419,
        longitude: -122.1430,
        radius: 50000, // 50 km
        source: 'USGS',
      ),
    ];
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
