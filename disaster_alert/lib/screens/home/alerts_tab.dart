// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/alert_model.dart';
import '../../services/alert_service.dart';
import '../../utils/theme.dart';
import '../../widgets/alert_card.dart';
import '../alerts/alert_details_screen.dart';

class AlertsTab extends StatefulWidget {
  const AlertsTab({Key? key}) : super(key: key);

  @override
  State<AlertsTab> createState() => _AlertsTabState();
}

class _AlertsTabState extends State<AlertsTab> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // TODO: Fetch alerts when we implement the API service
    // For now, just simulate loading
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // This is a placeholder. We'll replace this with actual alert data later
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recent Alerts', style: AppTextStyles.headline1),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                AlertCard(
                  alert: AlertModel(
                    id: '1',
                    title: 'Flash Flood Warning',
                    description:
                        'Flash flooding is expected in your area. Move to higher ground immediately.',
                    severity: 'Critical',
                    timestamp: DateTime.now().subtract(
                      const Duration(minutes: 10),
                    ),
                    expiryTime: DateTime.now().add(const Duration(hours: 6)),
                    latitude: 37.7749,
                    longitude: -122.4194,
                    radius: 5000,
                    source: 'NOAA',
                    metadata: {
                      'impactedAreas': 'Downtown, Richmond District',
                      'safeZones': 'Higher ground, Multi-story buildings',
                      'expectedDuration': '6 hours',
                    },
                  ),
                  onMapPressed: () {
                    // Switch to map tab and highlight this alert
                    // For now, just navigate to the third tab (map)
                    DefaultTabController.of(context)?.animateTo(2);
                  },
                ),
                const SizedBox(height: 12),
                AlertCard(
                  alert: AlertModel(
                    id: '2',
                    title: 'Thunderstorm Watch',
                    description:
                        'Severe thunderstorms possible in your area in the next 6 hours.',
                    severity: 'Warning',
                    timestamp: DateTime.now().subtract(
                      const Duration(minutes: 30),
                    ),
                    expiryTime: DateTime.now().add(const Duration(hours: 12)),
                    latitude: 37.8044,
                    longitude: -122.2712,
                    radius: 10000,
                    source: 'NOAA',
                  ),
                ),
                const SizedBox(height: 12),
                AlertCard(
                  alert: AlertModel(
                    id: '3',
                    title: 'Earthquake Report',
                    description:
                        'Magnitude 4.2 earthquake detected 50 miles from your location.',
                    severity: 'Info',
                    timestamp: DateTime.now().subtract(
                      const Duration(hours: 2),
                    ),
                    expiryTime: DateTime.now().add(const Duration(hours: 24)),
                    latitude: 37.3382,
                    longitude: -121.8863,
                    radius: 50000,
                    source: 'USGS',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
