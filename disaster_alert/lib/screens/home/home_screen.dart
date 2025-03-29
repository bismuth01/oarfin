import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/theme.dart';
import '../auth/profile_screen.dart';
import 'alerts_tab.dart';
import 'friends_tab.dart';
import 'map_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const AlertsTab(),
    const FriendsTab(),
    const MapTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.userModel;
    final isAnonymous = authService.currentUser?.isAnonymous ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Disaster Alert'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
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
                child:
                    isAnonymous
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
                setState(() => _currentIndex = 0);
                Navigator.pop(context);
              },
            ),
            if (!isAnonymous) // Only show friends option for signed-in users
              ListTile(
                leading: const Icon(Icons.people),
                title: const Text('Friends'),
                onTap: () {
                  setState(() => _currentIndex = 1);
                  Navigator.pop(context);
                },
              ),
            ListTile(
              leading: const Icon(Icons.map),
              title: const Text('Map'),
              onTap: () {
                setState(() => _currentIndex = 2);
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('About'),
              onTap: () {
                // TODO: Show about dialog
                Navigator.pop(context);
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

          setState(() {
            _currentIndex = index;
          });
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
          const BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
        ],
      ),
    );
  }
}
