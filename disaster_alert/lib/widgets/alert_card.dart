import 'package:flutter/material.dart';
import '../models/alert_model.dart';
import '../utils/theme.dart';
import '../screens/alerts/alert_details_screen.dart';
import 'package:provider/provider.dart';
import '../services/tab_navigation_service.dart';

class AlertCard extends StatelessWidget {
  final AlertModel alert;
  final VoidCallback? onMapPressed;
  final VoidCallback? onTap;

  const AlertCard({
    Key? key,
    required this.alert,
    this.onMapPressed,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Color(alert.getColorValue()).withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Alert header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Color(alert.getColorValue()),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getSeverityIcon(alert.severity),
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  alert.severity.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  alert.timeAgo,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Alert content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: AppTextStyles.headline3,
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.map),
                      label: const Text('View on Map'),
                      onPressed: onMapPressed ??
                          () {
                            try {
                              final navigationService =
                                  Provider.of<TabNavigationService>(context,
                                      listen: false);

                              // Navigate to map tab and focus on this alert
                              navigationService
                                  .navigateToTab(2); // 2 is the map tab index

                              // Show a short confirmation message
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Showing alert on map'),
                                  duration: Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            } catch (e) {
                              print('Error navigating to map: $e');
                            }
                          },
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.info_outline),
                      label: const Text('Details'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AlertDetailsScreen(alert: alert),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
