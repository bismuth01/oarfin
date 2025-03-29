import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/theme.dart';

class FriendsTab extends StatefulWidget {
  const FriendsTab({Key? key}) : super(key: key);

  @override
  State<FriendsTab> createState() => _FriendsTabState();
}

class _FriendsTabState extends State<FriendsTab> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // TODO: Fetch friends when we implement the friend service
    // For now, just simulate loading
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isAnonymous = authService.currentUser?.isAnonymous ?? false;

    if (isAnonymous) {
      return _buildSignInPrompt();
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // This is a placeholder. We'll replace this with actual friend data later
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Friends', style: AppTextStyles.headline1),
              IconButton(
                icon: const Icon(Icons.person_add),
                onPressed: () {
                  // TODO: Show add friend dialog
                  _showAddFriendDialog();
                },
                tooltip: 'Add Friend',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                _buildPlaceholderFriendCard(
                  name: 'John Doe',
                  location: 'San Francisco, CA',
                  avatarUrl: null,
                  hasActiveAlerts: true,
                ),
                const SizedBox(height: 12),
                _buildPlaceholderFriendCard(
                  name: 'Jane Smith',
                  location: 'New York, NY',
                  avatarUrl: null,
                  hasActiveAlerts: false,
                ),
                const SizedBox(height: 12),
                _buildPlaceholderFriendCard(
                  name: 'Mike Johnson',
                  location: 'Chicago, IL',
                  avatarUrl: null,
                  hasActiveAlerts: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignInPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people, size: 80, color: Colors.grey),
          const SizedBox(height: 24),
          const Text('Friends Feature', style: AppTextStyles.headline2),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Sign in with Google to connect with friends and see alerts in their area.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body1,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Sign out first (to clear anonymous state)
              // Then show login screen
              Provider.of<AuthService>(context, listen: false).signOut();
            },
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderFriendCard({
    required String name,
    required String location,
    String? avatarUrl,
    required bool hasActiveAlerts,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primary.withOpacity(0.2),
              child:
                  avatarUrl != null
                      ? ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Image.network(
                          avatarUrl,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Text(
                              name.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            );
                          },
                        ),
                      )
                      : Text(
                        name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.headline3),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(location, style: AppTextStyles.body2),
                    ],
                  ),
                  if (hasActiveAlerts)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.warning_amber,
                              size: 16,
                              color: AppColors.warning,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Active Alerts',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications),
                  onPressed: () {
                    // TODO: Show friend's alerts
                  },
                  tooltip: 'View Alerts',
                ),
                IconButton(
                  icon: const Icon(Icons.map),
                  onPressed: () {
                    // TODO: Show friend on map
                  },
                  tooltip: 'View on Map',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddFriendDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add Friend'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    hintText: 'Enter your friend\'s email',
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Your friend will receive an invitation to share location data with you.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('CANCEL'),
              ),
              ElevatedButton(
                onPressed: () {
                  // TODO: Send friend request
                  Navigator.pop(context);

                  // Show confirmation
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Friend invitation sent'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: const Text('SEND INVITATION'),
              ),
            ],
          ),
    );
  }
}
