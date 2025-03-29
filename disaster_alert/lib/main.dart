import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/location_service.dart';
import 'services/alert_service.dart';
import 'services/friend_service.dart';
import 'app.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
        // Auth service
        ChangeNotifierProvider(create: (_) => AuthService()),

        // Location service
        ChangeNotifierProvider(create: (_) => LocationService()),

        // Alert service - depends on location service
        ChangeNotifierProxyProvider<LocationService, AlertService>(
          create: (context) => AlertService(
            Provider.of<LocationService>(context, listen: false),
          ),
          update: (context, locationService, previous) =>
              previous ?? AlertService(locationService),
        ),

        // Friend service - depends on auth service
        ChangeNotifierProxyProvider<AuthService, FriendService>(
          create: (context) => FriendService(
            Provider.of<AuthService>(context, listen: false),
          ),
          update: (context, authService, previous) =>
              previous ?? FriendService(authService),
        ),
      ],
      child: const DisasterAlertApp(),
    ),
  );
}
