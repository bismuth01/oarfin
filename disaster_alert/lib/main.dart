import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/location_service.dart';
import 'services/alert_service.dart';
import 'services/api_service.dart';
import 'services/friend_service.dart';
import 'app.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'services/mock_api_service.dart';
import 'services/tab_navigation_service.dart';

bool get useMockApi => false;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  // Initialize Firebase with configuration from .env
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: dotenv.env['FIREBASE_API_KEY']!,
      appId: dotenv.env['FIREBASE_APP_ID']!,
      messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID']!,
      projectId: dotenv.env['FIREBASE_PROJECT_ID']!,
      storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET']!,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        // Auth service (no dependencies)
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(
          create: (_) => TabNavigationService(),
        ),
        // API service (no dependencies)
        Provider(
          create: (context) {
            final authService =
                Provider.of<AuthService>(context, listen: false);
            print("Creating API service. Using mock: $useMockApi");

            if (useMockApi) {
              final mockService = MockApiService(authService: authService);
              print("Created MockApiService: $mockService");
              return mockService;
            } else {
              return ApiService(authService: authService);
            }
          },
        ),
        // LocationService depends on ApiService
        ChangeNotifierProxyProvider2<ApiService, AuthService, LocationService>(
          create: (context) => LocationService(
            Provider.of<ApiService>(context, listen: false),
            Provider.of<AuthService>(context, listen: false),
          ),
          update: (context, apiService, authService, previous) =>
              previous ?? LocationService(apiService, authService),
        ),
        ChangeNotifierProxyProvider3<LocationService, ApiService, AuthService,
            AlertService>(
          create: (context) => AlertService(
            Provider.of<LocationService>(context, listen: false),
            Provider.of<ApiService>(context, listen: false),
            Provider.of<AuthService>(context, listen: false),
          ),
          update:
              (context, locationService, apiService, authService, previous) =>
                  previous ??
                  AlertService(locationService, apiService, authService),
        ),

        // FriendService depends on AuthService and ApiService
        ChangeNotifierProxyProvider2<AuthService, ApiService, FriendService>(
          create: (context) => FriendService(
            Provider.of<AuthService>(context, listen: false),
            Provider.of<ApiService>(context, listen: false),
          ),
          update: (context, authService, apiService, previous) =>
              previous ?? FriendService(authService, apiService),
        ),
      ],
      child: const DisasterAlertApp(),
    ),
  );
}
