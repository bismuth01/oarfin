import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/alert_model.dart';
import '../../services/alert_service.dart';
import '../../utils/theme.dart';
import '../../widgets/alert_card.dart';
import '../alerts/alert_details_screen.dart';
import '../../services/tab_navigation_service.dart';

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
    // Fetch alerts when the tab is initialized
    _fetchAlerts();
  }

  Future<void> _fetchAlerts() async {
    print('[DEBUG] _fetchAlerts() called');

    final alertService = Provider.of<AlertService>(context, listen: false);

    setState(() {
      _isLoading = true;
    });
    print('[DEBUG] Set _isLoading = true');

    try {
      print('[DEBUG] Calling alertService.fetchAlerts()...');
      await alertService.fetchAlerts();
      print('[DEBUG] alertService.fetchAlerts() completed successfully');
    } catch (e, stacktrace) {
      print('[ERROR] alertService.fetchAlerts() threw an error: $e');
      print('[STACKTRACE] $stacktrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading alerts: ${e.toString()}'),
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
        print('[DEBUG] Set _isLoading = false');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final alertService = Provider.of<AlertService>(context);
    final alerts = alertService.alerts;

    if (alerts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No alerts in your area',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'You\'ll be notified when alerts are issued',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchAlerts,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchAlerts,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recent Alerts', style: AppTextStyles.headline1),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: alerts.length,
                itemBuilder: (context, index) {
                  final alert = alerts[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: AlertCard(
                      alert: alert,
                      onMapPressed: () {
                        // Use the navigation service
                        final navigationService =
                            Provider.of<TabNavigationService>(context,
                                listen: false);
                        navigationService.focusOnAlert(alert);
                      },
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AlertDetailsScreen(alert: alert),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
