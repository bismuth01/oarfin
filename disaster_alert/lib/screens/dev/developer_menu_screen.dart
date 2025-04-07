// screens/dev/developer_menu_screen.dart
import 'package:flutter/material.dart';
import '../test/basic_mock_test_screen.dart';
import '../test/location_debug_screen.dart';
import '../test/alert_simulation_screen.dart';

class DeveloperMenuScreen extends StatelessWidget {
  const DeveloperMenuScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer Menu'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Basic Mock API Test'),
            subtitle: const Text('Verify mock API is working'),
            leading: const Icon(Icons.verified),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BasicMockTestScreen(),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Advanced Mock API Testing'),
            subtitle: const Text('Test complex API responses with mock data'),
            leading: const Icon(Icons.api),
            onTap: () {},
          ),
          ListTile(
            title: const Text('Location Debug'),
            subtitle: const Text('Test location services'),
            leading: const Icon(Icons.location_on),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LocationDebugScreen(),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Alert Simulation'),
            subtitle: const Text('Create test alerts'),
            leading: const Icon(Icons.warning_amber),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AlertSimulationScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
