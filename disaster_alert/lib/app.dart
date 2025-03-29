import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'services/auth_service.dart';
import 'utils/theme.dart';

class DisasterAlertApp extends StatelessWidget {
  const DisasterAlertApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Disaster Alert',
      theme: appTheme,
      home: Consumer<AuthService>(
        builder: (context, authService, _) {
          // If auth state is loading, show loading indicator
          if (authService.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // If user is logged in, show home screen, otherwise show login screen
          return authService.currentUser != null
              ? const HomeScreen()
              : const LoginScreen();
        },
      ),
    );
  }
}
