import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Enhanced Device User Tracking Service
/// Tracks all users who have ever logged in on this device
/// Used to determine if auto-logout should be applied
class DeviceUserTrackingService {
  static DeviceUserTrackingService? _instance;
  static DeviceUserTrackingService get instance {
    _instance ??= DeviceUserTrackingService._internal();
    return _instance!;
  }

  DeviceUserTrackingService._internal();

  static const String _deviceUsersKey = 'device_users_history';
  static const String _currentUserKey = 'current_device_user';
  static const String _firstUserKey = 'first_device_user';

  /// Track when a user logs in on this device
  Future<void> trackUserLogin(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing users list
      final existingUsers = prefs.getStringList(_deviceUsersKey) ?? [];
      
      // Add current user if not already in list
      if (!existingUsers.contains(userId)) {
        existingUsers.add(userId);
        await prefs.setStringList(_deviceUsersKey, existingUsers);
        debugPrint('📱 User $userId added to device history. Total users: ${existingUsers.length}');
      }

      // Set as current user
      await prefs.setString(_currentUserKey, userId);

      // Set as first user if this is the first login ever
      if (!prefs.containsKey(_firstUserKey)) {
        await prefs.setString(_firstUserKey, userId);
        debugPrint('🏠 User $userId is the first user on this device');
      }

    } catch (e) {
      debugPrint('❌ Error tracking user login: $e');
    }
  }

  /// Track when a user logs out
  Future<void> trackUserLogout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_currentUserKey);
      debugPrint('👋 Current user logged out');
    } catch (e) {
      debugPrint('❌ Error tracking user logout: $e');
    }
  }

  /// Check if multiple users have ever logged in on this device
  Future<bool> hasMultipleUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final users = prefs.getStringList(_deviceUsersKey) ?? [];
      final hasMultiple = users.length > 1;
      
      debugPrint('👥 Device has ${users.length} user(s). Multiple users: $hasMultiple');
      return hasMultiple;
    } catch (e) {
      debugPrint('❌ Error checking multiple users: $e');
      return true; // Default to true for security
    }
  }

  /// Check if current user is the only user who has ever used this device
  Future<bool> isOnlyUser(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final users = prefs.getStringList(_deviceUsersKey) ?? [];
      final firstUser = prefs.getString(_firstUserKey);
      
      final isOnly = users.length == 1 && 
                     users.contains(userId) && 
                     firstUser == userId;
      
      debugPrint('👤 User $userId is only user: $isOnly');
      return isOnly;
    } catch (e) {
      debugPrint('❌ Error checking if only user: $e');
      return false; // Default to false for security
    }
  }

  /// Get all users who have ever logged in on this device
  Future<List<String>> getAllDeviceUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_deviceUsersKey) ?? [];
    } catch (e) {
      debugPrint('❌ Error getting device users: $e');
      return [];
    }
  }

  /// Get the first user who ever logged in on this device
  Future<String?> getFirstUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_firstUserKey);
    } catch (e) {
      debugPrint('❌ Error getting first user: $e');
      return null;
    }
  }

  /// Get current logged in user
  Future<String?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_currentUserKey);
    } catch (e) {
      debugPrint('❌ Error getting current user: $e');
      return null;
    }
  }

  /// Clear all device user data (for testing or device reset)
  Future<void> clearDeviceUserHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_deviceUsersKey);
      await prefs.remove(_currentUserKey);
      await prefs.remove(_firstUserKey);
      debugPrint('🧹 Device user history cleared');
    } catch (e) {
      debugPrint('❌ Error clearing device user history: $e');
    }
  }

  /// Get device user statistics
  Future<Map<String, dynamic>> getDeviceStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final users = prefs.getStringList(_deviceUsersKey) ?? [];
      final currentUser = prefs.getString(_currentUserKey);
      final firstUser = prefs.getString(_firstUserKey);

      return {
        'total_users': users.length,
        'all_users': users,
        'current_user': currentUser,
        'first_user': firstUser,
        'has_multiple_users': users.length > 1,
        'is_current_only_user': users.length == 1 && 
                                currentUser != null && 
                                users.contains(currentUser),
      };
    } catch (e) {
      debugPrint('❌ Error getting device stats: $e');
      return {
        'total_users': 0,
        'all_users': [],
        'current_user': null,
        'first_user': null,
        'has_multiple_users': false,
        'is_current_only_user': false,
      };
    }
  }

  /// Check if auto-logout should be applied for current user
  Future<bool> shouldApplyAutoLogout() async {
    try {
      final hasMultiple = await hasMultipleUsers();
      
      if (hasMultiple) {
        debugPrint('🔐 Auto-logout enabled: Multiple users detected');
        return true;
      } else {
        debugPrint('🏠 Auto-logout disabled: Single user device');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error checking auto-logout policy: $e');
      return true; // Default to true for security
    }
  }
}
