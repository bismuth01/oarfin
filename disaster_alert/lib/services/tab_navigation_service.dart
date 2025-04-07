import 'package:flutter/material.dart';
import '../models/friend_model.dart';
import '../models/alert_model.dart';

class TabNavigationService extends ChangeNotifier {
  int _currentTabIndex = 0;
  FriendModel? _focusFriend;
  AlertModel? _focusAlert;

  int get currentTabIndex => _currentTabIndex;
  FriendModel? get focusFriend => _focusFriend;
  AlertModel? get focusAlert => _focusAlert;

  // Navigate to a specific tab
  void navigateToTab(int index) {
    _currentTabIndex = index;
    notifyListeners();
  }

  // Request to focus on a friend's location on the map
  void focusOnFriend(FriendModel friend) {
    _focusFriend = friend;
    _focusAlert = null; // Clear any alert focus
    _currentTabIndex = 2; // Map tab index
    notifyListeners();
  }

  // Request to focus on an alert on the map
  void focusOnAlert(AlertModel alert) {
    _focusAlert = alert;
    _focusFriend = null; // Clear any friend focus
    _currentTabIndex = 2; // Map tab index
    notifyListeners();
  }

  // Clear focus after it's been handled
  void clearFriendFocus() {
    _focusFriend = null;
  }

  // Clear alert focus after it's been handled
  void clearAlertFocus() {
    _focusAlert = null;
  }
}
