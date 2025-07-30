import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for managing user notification preferences
class NotificationPreferencesService {
  static NotificationPreferencesService? _instance;
  static NotificationPreferencesService get instance {
    _instance ??= NotificationPreferencesService._internal();
    return _instance!;
  }

  NotificationPreferencesService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  static const _table = 'user_notification_preferences';

  /// Get user's notification preferences
  Future<NotificationPreferences> getPreferences(String userId) async {
    try {
      final response = await _supabase
          .from(_table)
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        return NotificationPreferences.fromMap(response);
      } else {
        // Return default preferences if none exist
        return NotificationPreferences.defaultPreferences();
      }
    } catch (e) {
      debugPrint('❌ Error fetching notification preferences: $e');
      return NotificationPreferences.defaultPreferences();
    }
  }

  /// Update user's notification preferences
  Future<bool> updatePreferences(String userId, NotificationPreferences preferences) async {
    try {
      await _supabase
          .from(_table)
          .upsert({
            'user_id': userId,
            ...preferences.toMap(),
            'updated_at': DateTime.now().toIso8601String(),
          });

      debugPrint('✅ Notification preferences updated successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating notification preferences: $e');
      return false;
    }
  }

  /// Create default notification preferences for a new user
  Future<bool> createDefaultPreferences(String userId) async {
    try {
      final defaultPrefs = NotificationPreferences.defaultPreferences();
      
      await _supabase
          .from(_table)
          .insert({
            'user_id': userId,
            ...defaultPrefs.toMap(),
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });

      debugPrint('✅ Default notification preferences created for user: $userId');
      return true;
    } catch (e) {
      debugPrint('❌ Error creating default notification preferences: $e');
      return false;
    }
  }

  /// Update a specific preference
  Future<bool> updateSpecificPreference(String userId, String key, dynamic value) async {
    try {
      await _supabase
          .from(_table)
          .upsert({
            'user_id': userId,
            key: value,
            'updated_at': DateTime.now().toIso8601String(),
          });

      debugPrint('✅ Notification preference "$key" updated to: $value');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating notification preference: $e');
      return false;
    }
  }

  /// Check if a specific notification type is enabled for user
  Future<bool> isNotificationTypeEnabled(String userId, String notificationType) async {
    try {
      final preferences = await getPreferences(userId);
      
      switch (notificationType) {
        case 'message':
          return preferences.messages;
        case 'achievement':
          return preferences.achievements;
        case 'support':
          return preferences.support;
        case 'system':
          return preferences.system;
        case 'friend_request':
          return preferences.friendRequests;
        case 'pet_interaction':
          return preferences.petInteractions;
        default:
          return true; // Default to enabled for unknown types
      }
    } catch (e) {
      debugPrint('❌ Error checking notification type: $e');
      return true; // Default to enabled on error
    }
  }

  /// Check if user is in quiet hours
  Future<bool> isInQuietHours(String userId) async {
    try {
      final preferences = await getPreferences(userId);
      
      if (!preferences.quietHoursEnabled) {
        return false;
      }

      final now = DateTime.now();
      final currentTime = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
      
      // Check if current time is within quiet hours
      final startTime = preferences.quietHoursStart;
      final endTime = preferences.quietHoursEnd;
      
      // Handle overnight quiet hours (e.g., 22:00 to 08:00)
      if (startTime.compareTo(endTime) > 0) {
        return currentTime.compareTo(startTime) >= 0 || currentTime.compareTo(endTime) <= 0;
      } else {
        // Same day quiet hours (e.g., 12:00 to 14:00)
        return currentTime.compareTo(startTime) >= 0 && currentTime.compareTo(endTime) <= 0;
      }
    } catch (e) {
      debugPrint('❌ Error checking quiet hours: $e');
      return false;
    }
  }
}

/// Notification preferences data model
class NotificationPreferences {
  final bool messages;
  final bool achievements;
  final bool support;
  final bool system;
  final bool friendRequests;
  final bool petInteractions;
  final String sound;
  final bool vibrate;
  final bool quietHoursEnabled;
  final String quietHoursStart;
  final String quietHoursEnd;
  final bool showPreview;
  final bool groupNotifications;
  final int maxNotificationsPerHour;

  const NotificationPreferences({
    required this.messages,
    required this.achievements,
    required this.support,
    required this.system,
    required this.friendRequests,
    required this.petInteractions,
    required this.sound,
    required this.vibrate,
    required this.quietHoursEnabled,
    required this.quietHoursStart,
    required this.quietHoursEnd,
    required this.showPreview,
    required this.groupNotifications,
    required this.maxNotificationsPerHour,
  });

  /// Create default preferences
  factory NotificationPreferences.defaultPreferences() {
    return const NotificationPreferences(
      messages: true,
      achievements: true,
      support: true,
      system: true,
      friendRequests: true,
      petInteractions: true,
      sound: 'default',
      vibrate: true,
      quietHoursEnabled: false,
      quietHoursStart: '22:00',
      quietHoursEnd: '08:00',
      showPreview: true,
      groupNotifications: false,
      maxNotificationsPerHour: 10,
    );
  }

  /// Create from database map
  factory NotificationPreferences.fromMap(Map<String, dynamic> map) {
    return NotificationPreferences(
      messages: map['messages'] ?? true,
      achievements: map['achievements'] ?? true,
      support: map['support'] ?? true,
      system: map['system'] ?? true,
      friendRequests: map['friend_requests'] ?? true,
      petInteractions: map['pet_interactions'] ?? true,
      sound: map['sound'] ?? 'default',
      vibrate: map['vibrate'] ?? true,
      quietHoursEnabled: map['quiet_hours_enabled'] ?? false,
      quietHoursStart: map['quiet_hours_start'] ?? '22:00',
      quietHoursEnd: map['quiet_hours_end'] ?? '08:00',
      showPreview: map['show_preview'] ?? true,
      groupNotifications: map['group_notifications'] ?? false,
      maxNotificationsPerHour: map['max_notifications_per_hour'] ?? 10,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'messages': messages,
      'achievements': achievements,
      'support': support,
      'system': system,
      'friend_requests': friendRequests,
      'pet_interactions': petInteractions,
      'sound': sound,
      'vibrate': vibrate,
      'quiet_hours_enabled': quietHoursEnabled,
      'quiet_hours_start': quietHoursStart,
      'quiet_hours_end': quietHoursEnd,
      'show_preview': showPreview,
      'group_notifications': groupNotifications,
      'max_notifications_per_hour': maxNotificationsPerHour,
    };
  }

  /// Create a copy with updated values
  NotificationPreferences copyWith({
    bool? messages,
    bool? achievements,
    bool? support,
    bool? system,
    bool? friendRequests,
    bool? petInteractions,
    String? sound,
    bool? vibrate,
    bool? quietHoursEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
    bool? showPreview,
    bool? groupNotifications,
    int? maxNotificationsPerHour,
  }) {
    return NotificationPreferences(
      messages: messages ?? this.messages,
      achievements: achievements ?? this.achievements,
      support: support ?? this.support,
      system: system ?? this.system,
      friendRequests: friendRequests ?? this.friendRequests,
      petInteractions: petInteractions ?? this.petInteractions,
      sound: sound ?? this.sound,
      vibrate: vibrate ?? this.vibrate,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      showPreview: showPreview ?? this.showPreview,
      groupNotifications: groupNotifications ?? this.groupNotifications,
      maxNotificationsPerHour: maxNotificationsPerHour ?? this.maxNotificationsPerHour,
    );
  }
}
