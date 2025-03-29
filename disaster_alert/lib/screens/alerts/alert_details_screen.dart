import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/alert_model.dart';
import '../../utils/theme.dart';

class AlertDetailsScreen extends StatefulWidget {
  final AlertModel alert;

  const AlertDetailsScreen({
    Key? key,
    required this.alert,
  }) : super(key: key);

  @override
  State<AlertDetailsScreen> createState() => _AlertDetailsScreenState();
}

class _AlertDetailsScreenState extends State<AlertDetailsScreen> {
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    // No need to set up map overlays anymore as they're part of the build method
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alert Details'),
        backgroundColor: Color(widget.alert.getColorValue()),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Alert header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Color(widget.alert.getColorValue()).withOpacity(0.1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Color(widget.alert.getColorValue()),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          widget.alert.severity.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        widget.alert.timeAgo,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        _getSeverityIcon(widget.alert.severity),
                        color: Color(widget.alert.getColorValue()),
                        size: 28,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.alert.title,
                    style: AppTextStyles.headline1,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Source: ${widget.alert.source}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Alert map
            // Alert map
// Alert map
            SizedBox(
              height: 200,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter:
                      LatLng(widget.alert.latitude, widget.alert.longitude),
                  initialZoom: 10,
                ),
                children: [
                  // Base map layer
                  TileLayer(
                    urlTemplate:
                        'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c'],
                  ),

                  // Alert circle
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: LatLng(
                            widget.alert.latitude, widget.alert.longitude),
                        color: Color(widget.alert.getColorValue())
                            .withOpacity(0.2),
                        borderColor: Color(widget.alert.getColorValue()),
                        borderStrokeWidth: 2,
                        radius: widget.alert.radius, // meters
                      ),
                    ],
                  ),

                  // Alert marker
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(
                            widget.alert.latitude, widget.alert.longitude),
                        child: Icon(
                          _getSeverityIcon(widget.alert.severity),
                          color: Color(widget.alert.getColorValue()),
                          size: 30,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Add a location display
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Location: ${widget.alert.latitude}, ${widget.alert.longitude}',
                style: AppTextStyles.body2,
              ),
            ),

            // Alert details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Description',
                    style: AppTextStyles.headline2,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.alert.description,
                    style: AppTextStyles.body1,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Details',
                    style: AppTextStyles.headline2,
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow('Issued', widget.alert.timestamp.toString()),
                  _buildDetailRow(
                      'Expires', widget.alert.expiryTime.toString()),
                  _buildDetailRow('Affected Area',
                      '${(widget.alert.radius / 1000).toStringAsFixed(1)} km radius'),
                  if (widget.alert.metadata != null) ...{
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),
                    ...widget.alert.metadata!.entries.map(
                      (entry) => _buildDetailRow(
                        entry.key.replaceFirst(
                            entry.key[0], entry.key[0].toUpperCase()),
                        entry.value.toString(),
                      ),
                    ),
                  },
                ],
              ),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: Icons.directions,
                    label: 'Directions',
                    onPressed: () {
                      // TODO: Open navigation to safe zone
                    },
                  ),
                  _buildActionButton(
                    icon: Icons.share,
                    label: 'Share',
                    onPressed: () {
                      // TODO: Share alert
                    },
                  ),
                  _buildActionButton(
                    icon: Icons.notifications,
                    label: 'Subscribe',
                    onPressed: () {
                      // TODO: Subscribe to updates
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon),
      label: Text(label),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
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
