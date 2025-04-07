import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/theme.dart';
import '../../services/friend_service.dart';
import '../../services/alert_service.dart';
import '../../services/tab_navigation_service.dart';
import '../../models/friend_model.dart';
import '../../models/alert_model.dart';

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
    // Fetch friends when the tab is initialized
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    if (!mounted) return;

    final authService = Provider.of<AuthService>(context, listen: false);

    // Don't try to load friends if user is anonymous
    if (authService.currentUser?.isAnonymous ?? true) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final friendService = Provider.of<FriendService>(context, listen: false);
      await friendService.refreshFriends();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading friends: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isAnonymous = authService.currentUser?.isAnonymous ?? true;

    if (isAnonymous) {
      return _buildSignInPrompt();
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final friendService = Provider.of<FriendService>(context);
    final friends = friendService.friends;
    final pendingRequests = friendService.pendingRequests;

    print(
        "FriendsTab build - Friends: ${friends.length}, Pending: ${pendingRequests.length}");

    // Debug each pending request
    pendingRequests.forEach((req) {
      print(
          "Pending request: ID=${req.id}, Name=${req.displayName}, IsRequestor=${req.isRequestor}");
    });

    if (friends.isEmpty && pendingRequests.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadFriends,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Friends', style: AppTextStyles.headline1),
                  Row(
                    children: [
                      // Manual reload button
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Manually refreshing friends list...'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                          _loadFriends();
                        },
                        tooltip: 'Manual Refresh',
                      ),
                      IconButton(
                        icon: const Icon(Icons.person_add),
                        onPressed: () => _showAddFriendDialog(),
                        tooltip: 'Add Friend',
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Pending requests section
              if (pendingRequests.isNotEmpty) ...[
                const Text('Pending Requests',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: pendingRequests.length,
                  itemBuilder: (context, index) {
                    final request = pendingRequests[index];
                    print(
                        "Building UI for pending request: ${request.id}, ${request.displayName}");
                    return _buildPendingRequestCard(request);
                  },
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
              ],

              // Friends list section
              Expanded(
                child: friends.isEmpty
                    ? Center(
                        child: Text(
                          'No friends yet. Add friends to see their location.',
                          style: TextStyle(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        itemCount: friends.length,
                        itemBuilder: (context, index) {
                          final friend = friends[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildFriendCard(friend),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            const Text(
              'No Friends Yet',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Add friends to see their location and alerts in their area',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _showAddFriendDialog(),
              icon: const Icon(Icons.person_add),
              label: const Text('Add Friend'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingRequestCard(FriendModel request) {
    print(
        "Building pending request card for: ${request.id}, ${request.displayName}, isRequestor: ${request.isRequestor}");
    final friendService = Provider.of<FriendService>(context, listen: false);
    final isIncoming = !request.isRequestor;

    print(
        "  - isIncoming: $isIncoming (showing accept/reject buttons: $isIncoming)");

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey[200],
              child: Text(
                request.displayName.isNotEmpty
                    ? request.displayName.substring(0, 1).toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(request.displayName, style: AppTextStyles.headline3),
                  Text(request.email, style: AppTextStyles.body2),
                  const SizedBox(height: 4),
                  Text(
                    isIncoming ? 'Incoming request' : 'Outgoing request',
                    style: TextStyle(
                      color: isIncoming ? Colors.orange : Colors.blue,
                      fontStyle: FontStyle.italic,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isIncoming) // Only show accept/reject buttons for incoming requests
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () async {
                      await _handleFriendResponse(request.id, true);
                    },
                    tooltip: 'Accept',
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () async {
                      await _handleFriendResponse(request.id, false);
                    },
                    tooltip: 'Reject',
                  ),
                ],
              ),
            if (!isIncoming) // Show cancel button for outgoing requests
              IconButton(
                icon: const Icon(Icons.cancel, color: Colors.grey),
                onPressed: () async {
                  // Cancel outgoing request
                  try {
                    await friendService.removeFriend(request.id);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Friend request canceled'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                tooltip: 'Cancel Request',
              ),
          ],
        ),
      ),
    );
  }

  // Handle accept/reject response
  Future<void> _handleFriendResponse(String requestId, bool accept) async {
    final friendService = Provider.of<FriendService>(context, listen: false);

    try {
      bool success;
      if (accept) {
        success = await friendService.acceptFriendRequest(requestId);
      } else {
        success = await friendService.rejectFriendRequest(requestId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Friend request ${accept ? 'accepted' : 'rejected'}'
                : 'Failed to ${accept ? 'accept' : 'reject'} request'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: success ? null : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildFriendCard(FriendModel friend) {
    String locationText = 'Location unavailable';
    if (friend.latitude != null && friend.longitude != null) {
      locationText =
          'Lat: ${friend.latitude!.toStringAsFixed(4)}, Long: ${friend.longitude!.toStringAsFixed(4)}';
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primary.withOpacity(0.2),
              child: friend.photoUrl != null && friend.photoUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.network(
                        friend.photoUrl!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Text(
                            friend.displayName.isNotEmpty
                                ? friend.displayName
                                    .substring(0, 1)
                                    .toUpperCase()
                                : '?',
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
                      friend.displayName.isNotEmpty
                          ? friend.displayName.substring(0, 1).toUpperCase()
                          : '?',
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
                  Text(
                    friend.displayName,
                    style: AppTextStyles.headline3,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          locationText,
                          style: AppTextStyles.body2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (friend.lastLocationUpdate != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Last seen: ${_formatTimestamp(friend.lastLocationUpdate!)}',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  if (friend.hasActiveAlerts)
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
                    // Show friend's alerts
                    _showFriendAlerts(friend);
                  },
                  tooltip: 'View Alerts',
                ),
                IconButton(
                  icon: const Icon(Icons.map),
                  onPressed: () {
                    // Show friend on map
                    _showFriendOnMap(friend);
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

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else {
      return '${timestamp.month}/${timestamp.day}/${timestamp.year}';
    }
  }

  void _showFriendAlerts(FriendModel friend) {
    if (!friend.hasActiveAlerts) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active alerts for this friend'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final alertService = Provider.of<AlertService>(context, listen: false);

    // Get the friend's alerts
    List<AlertModel> friendAlerts = [];
    if (friend.activeAlertIds.isNotEmpty) {
      for (AlertModel alert in alertService.alerts) {
        if (friend.activeAlertIds.contains(alert.id)) {
          friendAlerts.add(alert);
        }
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primary.withOpacity(0.2),
                      child: Text(
                        friend.displayName.isNotEmpty
                            ? friend.displayName.substring(0, 1).toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${friend.displayName}\'s Alerts',
                        style: AppTextStyles.headline2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: friendAlerts.isEmpty
                      ? Center(
                          child: Text(
                            'No details available for alerts in ${friend.displayName}\'s area',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: friendAlerts.length,
                          itemBuilder: (context, index) {
                            final alert = friendAlerts[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Color(alert.getColorValue()),
                                  child: Icon(
                                    _getSeverityIcon(alert.severity),
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                title: Text(alert.title),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      alert.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Issued: ${alert.timeAgo}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                                isThreeLine: true,
                                onTap: () {
                                  Navigator.pop(context);
                                  // Additional alert detail handling can go here
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showFriendOnMap(FriendModel friend) {
    if (friend.latitude == null || friend.longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Friend location is not available'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      // Use TabNavigationService to handle the navigation
      final navigationService =
          Provider.of<TabNavigationService>(context, listen: false);
      navigationService.focusOnFriend(friend);

      // Show feedback to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Showing ${friend.displayName} on map'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error navigating to friend on map: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please go to the Map tab to see friends'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  IconData _getSeverityIcon(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Icons.warning_amber;
      case 'warning':
        return Icons.notifications_active;
      case 'watch':
        return Icons.visibility;
      case 'info':
        return Icons.info_outline;
      default:
        return Icons.notifications;
    }
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

  void _showAddFriendDialog() {
    final TextEditingController emailController = TextEditingController();
    final friendService = Provider.of<FriendService>(context, listen: false);
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Friend'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'Enter your friend\'s email',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                autofocus: true,
              ),
              const SizedBox(height: 16),
              const Text(
                'Your friend will receive an invitation to share location data with you.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 16.0),
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading
                  ? null
                  : () {
                      Navigator.pop(context);
                    },
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      // Validate email
                      final email = emailController.text.trim();
                      if (email.isEmpty || !email.contains('@')) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a valid email address'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }

                      // Show loading indicator
                      setState(() {
                        isLoading = true;
                      });

                      try {
                        // Send friend request
                        final success =
                            await friendService.sendFriendRequest(email);

                        if (mounted) {
                          // Close dialog regardless of result
                          Navigator.pop(context);

                          // Show appropriate message
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Friend invitation sent'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } else {
                            final errorMsg = friendService.errorMessage ??
                                'Failed to send invitation';
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(errorMsg),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        if (mounted) {
                          // Close dialog
                          Navigator.pop(context);

                          // Show error
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${e.toString()}'),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              child: const Text('SEND INVITATION'),
            ),
          ],
        ),
      ),
    );
  }
}
