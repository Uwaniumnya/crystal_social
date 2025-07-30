import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../config/environment_config.dart';
import 'device_registration_service.dart';
import 'push_notification_service.dart';

/// Enhanced Push Notification Integration
/// Provides a unified interface for the complete push notification system
class EnhancedPushNotificationIntegration {
  static EnhancedPushNotificationIntegration? _instance;
  static EnhancedPushNotificationIntegration get instance {
    _instance ??= EnhancedPushNotificationIntegration._internal();
    return _instance!;
  }

  EnhancedPushNotificationIntegration._internal();

  final DeviceRegistrationService _deviceService = DeviceRegistrationService.instance;
  final PushNotificationService _notificationService = PushNotificationService.instance;
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Initialize the complete push notification system
  Future<void> initialize() async {
    try {
      // Initialize device registration service
      await _deviceService.initialize();
      
      // Initialize push notification service
      await _notificationService.initialize();
      
      // Initialize OneSignal with updated v5 API
      await _initializeOneSignal();
      
      debugPrint('✅ Enhanced Push Notification Integration initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize Enhanced Push Notification Integration: $e');
    }
  }
  
  /// Initialize OneSignal with the v5 API
  /// 
  /// This uses the updated OneSignal v5.3.4 initialization flow:
  /// 1. Call initialize with app ID (no await since it returns void)
  /// 2. Optionally set debug level 
  /// 3. Request permission for notifications
  Future<void> _initializeOneSignal() async {
    try {
      // Get app ID from environment config
      final appId = EnvironmentConfig.oneSignalAppId;
      
      // Initialize OneSignal - don't await since it returns void
      OneSignal.initialize(appId);
      
      // Enable debug logging in debug mode
      if (kDebugMode) {
        OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
      }
      
      // Request permission (will prompt the user)
      await OneSignal.Notifications.requestPermission(true);
      
      debugPrint('✅ OneSignal initialized with app ID: $appId');
    } catch (e) {
      debugPrint('❌ Failed to initialize OneSignal: $e');
    }
  }

  /// Handle user login - register device
  Future<void> onUserLogin(String userId) async {
    try {
      await _deviceService.registerDevice(userId);
      debugPrint('✅ User logged in, device registered: $userId');
    } catch (e) {
      debugPrint('❌ Failed to handle user login: $e');
    }
  }

  /// Handle user logout - deactivate device
  Future<void> onUserLogout(String userId) async {
    try {
      await _deviceService.deactivateDevice(userId);
      debugPrint('✅ User logged out, device deactivated: $userId');
    } catch (e) {
      debugPrint('❌ Failed to handle user logout: $e');
    }
  }

  /// Send message notification (primary use case)
  Future<bool> sendMessageNotification({
    required String receiverUserId,
    required String senderUsername,
    String? messagePreview,
  }) async {
    try {
      // Get receiver username for notification title
      final receiverData = await _supabase
          .from('users')
          .select('username')
          .eq('id', receiverUserId)
          .maybeSingle();

      if (receiverData == null) {
        debugPrint('❌ Receiver not found: $receiverUserId');
        return false;
      }

      final receiverUsername = receiverData['username'] as String;
      
      // Format: "Receiver": You have a message from "Sender"
      final customMessage = messagePreview != null 
          ? 'You have a message from $senderUsername: $messagePreview'
          : 'You have a message from $senderUsername';

      return await _notificationService.sendNotificationToUser(
        receiverUserId: receiverUserId,
        senderUsername: senderUsername,
        customMessage: customMessage,
        additionalData: {
          'notification_type': 'message',
          'action': 'open_chat',
          'sender_username': senderUsername,
          'receiver_username': receiverUsername,
        },
      );
    } catch (e) {
      debugPrint('❌ Failed to send message notification: $e');
      return false;
    }
  }

  /// Send group message notification
  Future<Map<String, bool>> sendGroupMessageNotification({
    required List<String> receiverUserIds,
    required String senderUsername,
    required String groupName,
    String? messagePreview,
  }) async {
    try {
      final customMessage = messagePreview != null
          ? 'New message in $groupName from $senderUsername: $messagePreview'
          : 'New message in $groupName from $senderUsername';

      return await _notificationService.sendBulkNotifications(
        receiverUserIds: receiverUserIds,
        senderUsername: senderUsername,
        customMessage: customMessage,
        additionalData: {
          'notification_type': 'group_message',
          'action': 'open_group_chat',
          'sender_username': senderUsername,
          'group_name': groupName,
        },
      );
    } catch (e) {
      debugPrint('❌ Failed to send group message notification: $e');
      return {};
    }
  }

  /// Send friend request notification
  Future<bool> sendFriendRequestNotification({
    required String receiverUserId,
    required String senderUsername,
  }) async {
    try {
      return await _notificationService.sendNotificationToUser(
        receiverUserId: receiverUserId,
        senderUsername: senderUsername,
        customMessage: '$senderUsername sent you a friend request',
        additionalData: {
          'notification_type': 'friend_request',
          'action': 'open_friend_requests',
          'sender_username': senderUsername,
        },
      );
    } catch (e) {
      debugPrint('❌ Failed to send friend request notification: $e');
      return false;
    }
  }

  /// Send system notification
  Future<bool> sendSystemNotification({
    required String receiverUserId,
    required String title,
    required String message,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      return await _notificationService.sendNotificationToUser(
        receiverUserId: receiverUserId,
        senderUsername: 'Crystal Social',
        customMessage: message,
        additionalData: {
          'notification_type': 'system',
          'action': 'open_app',
          'system_title': title,
          ...?additionalData,
        },
      );
    } catch (e) {
      debugPrint('❌ Failed to send system notification: $e');
      return false;
    }
  }

  /// Get user's notification statistics
  Future<Map<String, dynamic>> getUserNotificationStats(String userId) async {
    try {
      // Get device count
      final deviceCount = await _deviceService.getDeviceCount(userId);
      
      // Get notification history
      final notificationHistory = await _notificationService.getNotificationHistory(userId, limit: 10);
      
      // Get total notifications from database
      final statsResponse = await _supabase
          .rpc('get_notification_stats', params: {'target_user_id': userId});
      
      return {
        'active_devices': deviceCount,
        'recent_notifications': notificationHistory,
        'total_notifications': statsResponse?['total_notifications'] ?? 0,
        'total_devices_reached': statsResponse?['total_devices_reached'] ?? 0,
        'total_successful_sends': statsResponse?['total_successful_sends'] ?? 0,
        'last_notification': statsResponse?['last_notification'],
      };
    } catch (e) {
      debugPrint('❌ Failed to get notification stats: $e');
      return {
        'active_devices': 0,
        'recent_notifications': [],
        'total_notifications': 0,
        'total_devices_reached': 0,
        'total_successful_sends': 0,
        'last_notification': null,
      };
    }
  }

  /// Get all devices for current user
  Future<List<Map<String, dynamic>>> getCurrentUserDevices() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return [];
      }
      
      return await _deviceService.getUserDevices(user.id);
    } catch (e) {
      debugPrint('❌ Failed to get current user devices: $e');
      return [];
    }
  }

  /// Test notification system
  Future<bool> sendTestNotification(String userId) async {
    try {
      return await sendSystemNotification(
        receiverUserId: userId,
        title: 'Test Notification',
        message: 'This is a test notification from Crystal Social! 🧪✨',
        additionalData: {
          'test': true,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('❌ Failed to send test notification: $e');
      return false;
    }
  }
  
  /// Send notification with OneSignal
  /// 
  /// Note: For security reasons, sending notifications should be done via your server,
  /// not directly from the app. This method delegates to your backend API.
  Future<bool> sendOneSignalNotification({
    required List<String> playerIds,
    required String title,
    required String content,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Get the Supabase instance
      final supabase = Supabase.instance.client;
      
      // Call your Supabase Edge Function that will handle the actual notification sending
      final response = await supabase.functions.invoke(
        'send-onesignal-notification',
        body: {
          'player_ids': playerIds,
          'title': title,
          'content': content,
          'additional_data': additionalData,
        },
      );
      
      if (response.status >= 200 && response.status < 300) {
        debugPrint('✅ OneSignal notification sent to ${playerIds.length} devices');
        return true;
      } else {
        debugPrint('❌ Failed to send OneSignal notification: ${response.status} ${response.data}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Failed to send OneSignal notification: $e');
      return false;
    }
  }

  /// Clean up old devices
  Future<void> performMaintenance() async {
    try {
      await _deviceService.cleanupOldDevices();
      debugPrint('✅ Notification system maintenance completed');
    } catch (e) {
      debugPrint('❌ Failed to perform maintenance: $e');
    }
  }

  /// Check if notifications are enabled for current user
  Future<bool> areNotificationsEnabled() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;
      
      return await _deviceService.hasRegisteredDevices(user.id);
    } catch (e) {
      debugPrint('❌ Failed to check notification status: $e');
      return false;
    }
  }

  /// Update FCM token (called when token refreshes)
  Future<void> updateFCMToken(String newToken) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        await _deviceService.updateFcmToken(user.id, newToken);
      }
    } catch (e) {
      debugPrint('❌ Failed to update FCM token: $e');
    }
  }
}
