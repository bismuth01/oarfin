import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/tab_navigation_service.dart';
import '../../utils/theme.dart';
import '../auth/profile_screen.dart';
import 'alerts_tab.dart';
import 'friends_tab.dart';
import 'map_tab.dart';
import '../../services/location_service.dart';
import '../../services/alert_service.dart';
import '../../models/friend_model.dart';
import 'package:package_info_plus/package_info_plus.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // Define tabs without using keys for private state classes
  late final List<Widget> _tabs = [
    const AlertsTab(),
    const FriendsTab(),
    const MapTab(), // No key needed
  ];

  @override
  void initState() {
    super.initState();

    // Start location updates and alert refreshing when app opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final locationService =
          Provider.of<LocationService>(context, listen: false);
      final alertService = Provider.of<AlertService>(context, listen: false);

      locationService.startLocationUpdates();
      alertService.startAlertRefresh();
    });
  }

  @override
  void dispose() {
    // Stop services when app is closed
    final locationService =
        Provider.of<LocationService>(context, listen: false);
    final alertService = Provider.of<AlertService>(context, listen: false);

    locationService.stopLocationUpdates();
    alertService.stopAlertRefresh();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final tabNavigationService = Provider.of<TabNavigationService>(context);
    final user = authService.userModel;
    final isAnonymous = authService.currentUser?.isAnonymous ?? false;

    // Sync local state with service
    if (_currentIndex != tabNavigationService.currentTabIndex) {
      setState(() {
        _currentIndex = tabNavigationService.currentTabIndex;
      });
    }

    return WillPopScope(
      onWillPop: () async {
        if (_currentIndex != 0) {
          tabNavigationService.navigateToTab(0);
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Disaster Alert'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                accountName: Text(
                  isAnonymous ? 'Guest User' : (user?.displayName ?? 'User'),
                  style: const TextStyle(color: Colors.white),
                ),
                accountEmail: Text(
                  isAnonymous ? '' : (user?.email ?? ''),
                  style: const TextStyle(color: Colors.white70),
                ),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: isAnonymous
                      ? const Icon(Icons.person, color: AppColors.primary)
                      : (user?.photoUrl != null
                          ? Image.network(
                              user!.photoUrl!,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.person,
                                  color: AppColors.primary,
                                );
                              },
                            )
                          : const Icon(
                              Icons.person,
                              color: AppColors.primary,
                            )),
                ),
                decoration: const BoxDecoration(color: AppColors.primary),
              ),
              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text('Alerts'),
                onTap: () {
                  tabNavigationService.navigateToTab(0);
                  Navigator.pop(context);
                },
              ),
              if (!isAnonymous) // Only show friends option for signed-in users
                ListTile(
                  leading: const Icon(Icons.people),
                  title: const Text('Friends'),
                  onTap: () {
                    tabNavigationService.navigateToTab(1);
                    Navigator.pop(context);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.map),
                title: const Text('Map'),
                onTap: () {
                  tabNavigationService.navigateToTab(2);
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('About'),
                onTap: () {
                  Navigator.pop(context); // Close drawer first
                  _showAboutDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Sign Out'),
                onTap: () async {
                  Navigator.pop(context); // Close drawer first
                  await authService.signOut();
                },
              ),
            ],
          ),
        ),
        body: _tabs[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            // If user is anonymous and trying to access Friends tab
            if (index == 1 && isAnonymous) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please sign in to access friends feature'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return;
            }

            tabNavigationService.navigateToTab(index);
          },
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.notifications),
              label: 'Alerts',
            ),
            BottomNavigationBarItem(
              icon: Stack(
                children: [
                  const Icon(Icons.people),
                  if (isAnonymous)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 12,
                          minHeight: 12,
                        ),
                        child: const Icon(
                          Icons.lock,
                          size: 8,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              label: 'Friends',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.map),
              label: 'Map',
            ),
          ],
        ),
      ),
    );
  }

  void focusOnFriend(FriendModel friend) {
    // Instead of trying to access the map state directly,
    // just use the NavigationService to handle it
    if (friend.latitude != null && friend.longitude != null) {
      final navigationService =
          Provider.of<TabNavigationService>(context, listen: false);
      navigationService.focusOnFriend(friend);
    }
  }

  Future<void> _showAboutDialog() async {
    // Get package info
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final String version = packageInfo.version;
    final String buildNumber = packageInfo.buildNumber;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AboutDialog(
        applicationName: 'Disaster Alert',
        applicationVersion: 'v$version+$buildNumber',
        applicationIcon: Image.asset(
          'assets/logo.png',
          width: 48,
          height: 48,
          // If asset isn't available, handle gracefully
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 48,
              height: 48,
              color: AppColors.primary,
              child: const Icon(Icons.warning, color: Colors.white),
            );
          },
        ),
        children: const [
          SizedBox(height: 16),
          Text(
            'Disaster Alert provides real-time information about natural disasters and emergencies in your area.',
          ),
          SizedBox(height: 16),
          Text(
            'Features:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            '• Real-time alerts for disasters in your vicinity\n'
            '• Location sharing with trusted friends\n'
            '• Interactive map showing alert zones\n'
            '• Safe locations during emergencies',
          ),
          SizedBox(height: 16),
          Text(
            '© 2025 Disaster Alert Team',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
