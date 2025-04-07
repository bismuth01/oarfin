// screens/test/basic_mock_test_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/mock_api_service.dart';

class BasicMockTestScreen extends StatefulWidget {
  const BasicMockTestScreen({Key? key}) : super(key: key);

  @override
  State<BasicMockTestScreen> createState() => _BasicMockTestScreenState();
}

class _BasicMockTestScreenState extends State<BasicMockTestScreen> {
  String _testResult = 'No test run yet';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Basic Mock API Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: _testMockApi,
              child: const Text('Test Mock API Connection'),
            ),
            const SizedBox(height: 20),
            const Text('Result:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              Text(_testResult),
          ],
        ),
      ),
    );
  }

  Future<void> _testMockApi() async {
    setState(() {
      _isLoading = true;
      _testResult = 'Testing...';
    });

    try {
      // Get the API service
      final apiService = Provider.of<ApiService>(context, listen: false);

      // Check if it's a mock service
      final isMock = apiService is MockApiService;

      if (!isMock) {
        setState(() {
          _isLoading = false;
          _testResult = 'NOT using mock API service. Check your configuration.';
        });
        return;
      }

      // Cast to mock service to access mock-specific methods
      final mockService = apiService as MockApiService;

      // Try a simple API call
      final response = await apiService.get('/api/test/ping');

      setState(() {
        _isLoading = false;
        _testResult = 'Mock API Service Test:\n'
            'Is Mock Service: $isMock\n'
            'Response Status: ${response.statusCode}\n'
            'Response Body: ${response.body}';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _testResult = 'Error: $e';
      });
    }
  }
}
