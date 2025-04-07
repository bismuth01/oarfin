// screens/test/alert_simulation_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/alert_service.dart';
import '../../services/location_service.dart';
import '../../models/alert_model.dart';

class AlertSimulationScreen extends StatefulWidget {
  const AlertSimulationScreen({Key? key}) : super(key: key);

  @override
  _AlertSimulationScreenState createState() => _AlertSimulationScreenState();
}

class _AlertSimulationScreenState extends State<AlertSimulationScreen> {
  // Form controllers
  final _titleController = TextEditingController(text: 'Test Alert');
  final _descriptionController = TextEditingController(
      text: 'This is a test alert generated from the development tools.');
  String _selectedSeverity = 'Critical';
  double _radius = 5000; // meters
  int _durationHours = 6;

  String _simulationResult = '';

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locationService = Provider.of<LocationService>(context);
    final alertService = Provider.of<AlertService>(context);

    final hasLocation = locationService.currentPosition != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alert Simulation'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!hasLocation)
              Card(
                color: Colors.amber[100],
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'No location available. Please use the Location Debug tool to set a location first.',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Text(
              'Create Simulated Alert',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Alert Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Alert Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Severity',
                border: OutlineInputBorder(),
              ),
              value: _selectedSeverity,
              items: ['Critical', 'Warning', 'Watch', 'Info']
                  .map((severity) => DropdownMenuItem(
                        value: severity,
                        child: Text(severity),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedSeverity = value;
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            Text('Alert Radius: ${(_radius / 1000).toStringAsFixed(1)} km'),
            Slider(
              min: 1000,
              max: 50000,
              divisions: 49,
              value: _radius,
              label: '${(_radius / 1000).toStringAsFixed(1)} km',
              onChanged: (value) {
                setState(() {
                  _radius = value;
                });
              },
            ),
            const SizedBox(height: 12),
            Text('Duration: $_durationHours hours'),
            Slider(
              min: 1,
              max: 72,
              divisions: 71,
              value: _durationHours.toDouble(),
              label: '$_durationHours hours',
              onChanged: (value) {
                setState(() {
                  _durationHours = value.toInt();
                });
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: hasLocation
                  ? () {
                      final now = DateTime.now();
                      final position = locationService.currentPosition!;

                      // Create a simulated alert
                      final alert = AlertModel(
                        id: 'sim-${now.millisecondsSinceEpoch}',
                        title: _titleController.text,
                        description: _descriptionController.text,
                        severity: _selectedSeverity,
                        timestamp: now,
                        expiryTime: now.add(Duration(hours: _durationHours)),
                        latitude: position.latitude,
                        longitude: position.longitude,
                        radius: _radius,
                        source: 'SIMULATION',
                      );

                      // Add to the alert service
                      // Note: In a real implementation, you would need to add a method to AlertService
                      // to support adding simulated alerts

                      // For now, let's just show what would be created
                      setState(() {
                        _simulationResult = 'Simulated Alert Created:\n\n'
                            'Title: ${alert.title}\n'
                            'Severity: ${alert.severity}\n'
                            'Location: ${alert.latitude}, ${alert.longitude}\n'
                            'Radius: ${(alert.radius / 1000).toStringAsFixed(1)} km\n'
                            'Active until: ${alert.expiryTime}\n\n'
                            'Note: This alert is for testing only and is not saved to the backend.';
                      });
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                'Create Simulated Alert',
                style: TextStyle(fontSize: 16),
              ),
            ),
            if (_simulationResult.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[400]!),
                ),
                child: Text(_simulationResult),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
