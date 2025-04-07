import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/location_service.dart';
import '../../utils/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../dev/developer_menu_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Settings
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  bool _showCriticalAlerts = true;
  bool _showWarningAlerts = true;
  bool _showWatchAlerts = true;
  bool _showInfoAlerts = true;
  double _alertRadius = 100.0; // km
  int _tapCount = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Load settings from shared preferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _locationEnabled = prefs.getBool('location_enabled') ?? true;
      _showCriticalAlerts = prefs.getBool('show_critical_alerts') ?? true;
      _showWarningAlerts = prefs.getBool('show_warning_alerts') ?? true;
      _showWatchAlerts = prefs.getBool('show_watch_alerts') ?? true;
      _showInfoAlerts = prefs.getBool('show_info_alerts') ?? true;
      _alertRadius = prefs.getDouble('alert_radius') ?? 100.0;
    });
  }

  // Save settings to shared preferences
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setBool('location_enabled', _locationEnabled);
    await prefs.setBool('show_critical_alerts', _showCriticalAlerts);
    await prefs.setBool('show_warning_alerts', _showWarningAlerts);
    await prefs.setBool('show_watch_alerts', _showWatchAlerts);
    await prefs.setBool('show_info_alerts', _showInfoAlerts);
    await prefs.setDouble('alert_radius', _alertRadius);
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final locationService = Provider.of<LocationService>(context);
    final user = authService.userModel;
    final isAnonymous = authService.currentUser?.isAnonymous ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User profile section
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Profile picture and name
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            child: isAnonymous
                                ? const Icon(
                                    Icons.person,
                                    size: 50,
                                    color: AppColors.primary,
                                  )
                                : (user?.photoUrl != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          50,
                                        ),
                                        child: Image.network(
                                          user!.photoUrl!,
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                          errorBuilder: (
                                            context,
                                            error,
                                            stackTrace,
                                          ) {
                                            return const Icon(
                                              Icons.person,
                                              size: 50,
                                              color: AppColors.primary,
                                            );
                                          },
                                        ),
                                      )
                                    : Text(
                                        user?.displayName
                                                ?.substring(0, 1)
                                                .toUpperCase() ??
                                            'U',
                                        style: const TextStyle(
                                          fontSize: 40,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      )),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isAnonymous
                                ? 'Guest User'
                                : (user?.displayName ?? 'User'),
                            style: AppTextStyles.headline2,
                          ),
                          if (!isAnonymous && user?.email != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                user!.email,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Account actions
                    if (isAnonymous)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.login),
                        label: const Text('Sign In with Google'),
                        onPressed: () {
                          // Sign out from anonymous account
                          authService.signOut();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      )
                    else
                      ElevatedButton.icon(
                        icon: const Icon(Icons.logout),
                        label: const Text('Sign Out'),
                        onPressed: () {
                          authService.signOut();
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Settings sections
            const Text('App Settings', style: AppTextStyles.headline2),
            const SizedBox(height: 16),

            // Notifications settings
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Enable Notifications'),
                    subtitle: const Text('Receive alerts about disasters'),
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _notificationsEnabled = value;
                      });
                      _saveSettings();
                    },
                    secondary: const Icon(Icons.notifications),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Location Services'),
                    subtitle: const Text('Allow access to your location'),
                    value: _locationEnabled,
                    onChanged: (value) {
                      setState(() {
                        _locationEnabled = value;
                      });
                      if (value) {
                        locationService.requestPermission();
                      }
                      _saveSettings();
                    },
                    secondary: const Icon(Icons.location_on),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Alert filters
            const Text('Alert Filters', style: AppTextStyles.headline2),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  CheckboxListTile(
                    title: const Text('Critical Alerts'),
                    secondary: const Icon(
                      Icons.warning_amber,
                      color: AppColors.criticalAlert,
                    ),
                    value: _showCriticalAlerts,
                    onChanged: (value) {
                      setState(() {
                        _showCriticalAlerts = value ?? true;
                      });
                      _saveSettings();
                    },
                  ),
                  const Divider(height: 1),
                  CheckboxListTile(
                    title: const Text('Warning Alerts'),
                    secondary: const Icon(
                      Icons.notifications_active,
                      color: AppColors.warningAlert,
                    ),
                    value: _showWarningAlerts,
                    onChanged: (value) {
                      setState(() {
                        _showWarningAlerts = value ?? true;
                      });
                      _saveSettings();
                    },
                  ),
                  const Divider(height: 1),
                  CheckboxListTile(
                    title: const Text('Watch Alerts'),
                    secondary: const Icon(
                      Icons.visibility,
                      color: AppColors.watchAlert,
                    ),
                    value: _showWatchAlerts,
                    onChanged: (value) {
                      setState(() {
                        _showWatchAlerts = value ?? true;
                      });
                      _saveSettings();
                    },
                  ),
                  const Divider(height: 1),
                  CheckboxListTile(
                    title: const Text('Info Alerts'),
                    secondary: const Icon(
                      Icons.info_outline,
                      color: AppColors.infoAlert,
                    ),
                    value: _showInfoAlerts,
                    onChanged: (value) {
                      setState(() {
                        _showInfoAlerts = value ?? true;
                      });
                      _saveSettings();
                    },
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Alert Radius',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_alertRadius.toInt()} km',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        Slider(
                          value: _alertRadius,
                          min: 10,
                          max: 500,
                          divisions: 49,
                          label: '${_alertRadius.toInt()} km',
                          onChanged: (value) {
                            setState(() {
                              _alertRadius = value;
                            });
                          },
                          onChangeEnd: (value) {
                            _saveSettings();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // App info
            const Text('About', style: AppTextStyles.headline2),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Version'),
                    subtitle: const Text('1.0.0'),
                    leading: const Icon(Icons.info_outline),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('DEV MDE'),
                    leading: const Icon(Icons.description),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: Open terms of service
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DeveloperMenuScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Terms Of Service'),
                    leading: const Icon(Icons.description),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: Open privacy policy
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Privacy Policy'),
                    leading: const Icon(Icons.privacy_tip),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: Open privacy policy
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Contact Support'),
                    leading: const Icon(Icons.support_agent),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: Open support contact
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
