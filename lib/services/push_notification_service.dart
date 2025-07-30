import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'device_registration_service.dart';

/// Push Notification Service
/// Sends notifications to all devices where a user has ever logged in
/// Format: "Receiver": You have a message from "Sender"
class PushNotificationService {
  static PushNotificationService? _instance;
  static PushNotificationService get instance {
    _instance ??= PushNotificationService._internal();
    return _instance!;
  }

  PushNotificationService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // DEPRECATED: FCM Server Keys are deprecated, use Web API Key instead
  // Firebase Web API Key for Crystal Social
  static const String _fcmServerKey = 'AIzaSyDd89JRRHAoKSChIoMfM3zZzkrVOyI4tjA';

  /// Send notification to all devices for a specific user
  Future<bool> sendNotificationToUser({
    required String receiverUserId,
    required String senderUsername,
    String? customMessage,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Get receiver's username for the notification
      final receiverData = await _supabase
          .from('users')
          .select('username')
          .eq('id', receiverUserId)
          .maybeSingle();

      if (receiverData == null) {
        debugPrint('❌ Receiver user not found: $receiverUserId');
        return false;
      }

      final receiverUsername = receiverData['username'] as String;
      
      // Get all active devices for the receiver
      final devices = await DeviceRegistrationService.instance.getUserDevices(receiverUserId);
      
      if (devices.isEmpty) {
        debugPrint('❌ No active devices found for user: $receiverUserId');
        return false;
      }

      // Prepare notification content
      final title = receiverUsername;
      final body = customMessage ?? 'You have a message from $senderUsername';
      
      // Send to each device
      int successCount = 0;
      for (final device in devices) {
        final fcmToken = device['fcm_token'] as String?;
        if (fcmToken != null) {
          final success = await _sendFCMNotification(
            fcmToken: fcmToken,
            title: title,
            body: body,
            data: {
              'type': 'message',
              'sender': senderUsername,
              'receiver': receiverUsername,
              'receiver_id': receiverUserId,
              'timestamp': DateTime.now().toIso8601String(),
              ...?additionalData,
            },
          );
          
          if (success) {
            successCount++;
          }
        }
      }

      // Log the notification in database
      await _logNotification(
        receiverUserId: receiverUserId,
        senderUsername: senderUsername,
        title: title,
        body: body,
        deviceCount: devices.length,
        successCount: successCount,
      );

      debugPrint('✅ Sent notification to $successCount/${devices.length} devices for user $receiverUserId');
      return successCount > 0;
      
    } catch (e) {
      debugPrint('❌ Failed to send notification to user: $e');
      return false;
    }
  }

  /// Send FCM notification to a specific token
  Future<bool> _sendFCMNotification({
    required String fcmToken,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final url = Uri.parse('https://fcm.googleapis.com/fcm/send');
      
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'key=$_fcmServerKey',
      };

      final payload = {
        'to': fcmToken,
        'notification': {
          'title': title,
          'body': body,
          'sound': 'default',
          'badge': 1,
        },
        'data': data ?? {},
        'priority': 'high',
        'content_available': true,
      };

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == 1) {
          return true;
        } else {
          debugPrint('❌ FCM error: ${responseData['results']?[0]?['error']}');
          return false;
        }
      } else {
        debugPrint('❌ FCM HTTP error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Failed to send FCM notification: $e');
      return false;
    }
  }

  /// Send notification using Supabase Edge Function (RECOMMENDED METHOD)
  Future<bool> sendNotificationViaEdgeFunction({
    required String receiverUserId,
    required String senderUsername,
    String? customMessage,
    Map<String, dynamic>? additionalData,
    String notificationType = 'message',
    String priority = 'high',
  }) async {
    try {
      // Get receiver's username
      final receiverData = await _supabase
          .from('users')
          .select('username')
          .eq('id', receiverUserId)
          .maybeSingle();

      if (receiverData == null) {
        debugPrint('❌ Receiver user not found: $receiverUserId');
        return false;
      }

      final receiverUsername = receiverData['username'] as String;
      final title = receiverUsername;
      final body = customMessage ?? 'You have a message from $senderUsername';

      // Call Supabase Edge Function
      final response = await _supabase.functions.invoke(
        'send-push-notification',
        body: {
          'receiver_user_id': receiverUserId,
          'title': title,
          'body': body,
          'notification_type': notificationType,
          'priority': priority,
          'data': {
            'type': notificationType,
            'sender': senderUsername,
            'receiver': receiverUsername,
            'receiver_id': receiverUserId,
            'timestamp': DateTime.now().toIso8601String(),
            ...?additionalData,
          },
        },
      );

      if (response.status == 200) {
        final responseData = response.data as Map<String, dynamic>;
        debugPrint('✅ Notification sent via edge function: ${responseData['message']}');
        return responseData['success'] == true;
      } else {
        debugPrint('❌ Edge function error: ${response.status} - ${response.data}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Failed to send notification via edge function: $e');
      return false;
    }
  }

  /// Send notification with automatic fallback (Edge Function first, then direct FCM)
  Future<bool> sendNotificationWithFallback({
    required String receiverUserId,
    required String senderUsername,
    String? customMessage,
    Map<String, dynamic>? additionalData,
    String notificationType = 'message',
  }) async {
    // Try Edge Function first (recommended)
    bool success = await sendNotificationViaEdgeFunction(
      receiverUserId: receiverUserId,
      senderUsername: senderUsername,
      customMessage: customMessage,
      additionalData: additionalData,
      notificationType: notificationType,
    );

    // Fallback to direct FCM if Edge Function fails
    if (!success) {
      debugPrint('🔄 Edge function failed, trying direct FCM...');
      success = await sendNotificationToUser(
        receiverUserId: receiverUserId,
        senderUsername: senderUsername,
        customMessage: customMessage,
        additionalData: additionalData,
      );
    }

    return success;
  }

  /// Send bulk notifications to multiple users (uses Edge Function)
  Future<Map<String, bool>> sendBulkNotifications({
    required List<String> receiverUserIds,
    required String senderUsername,
    String? customMessage,
    Map<String, dynamic>? additionalData,
    String notificationType = 'message',
  }) async {
    final results = <String, bool>{};
    
    for (final userId in receiverUserIds) {
      final success = await sendNotificationWithFallback(
        receiverUserId: userId,
        senderUsername: senderUsername,
        customMessage: customMessage,
        additionalData: additionalData,
        notificationType: notificationType,
      );
      results[userId] = success;
    }
    
    return results;
  }

  /// Quick send methods for common notification types
  
  /// Send chat message notification
  Future<bool> sendChatNotification({
    required String receiverUserId,
    required String senderUsername,
    String? messagePreview,
  }) async {
    return sendNotificationWithFallback(
      receiverUserId: receiverUserId,
      senderUsername: senderUsername,
      customMessage: messagePreview ?? 'You have a new message from $senderUsername',
      notificationType: 'message',
      additionalData: {'chat_type': 'direct_message'},
    );
  }

  /// Send friend request notification
  Future<bool> sendFriendRequestNotification({
    required String receiverUserId,
    required String senderUsername,
  }) async {
    return sendNotificationWithFallback(
      receiverUserId: receiverUserId,
      senderUsername: senderUsername,
      customMessage: '$senderUsername sent you a friend request!',
      notificationType: 'friend_request',
    );
  }

  /// Send achievement notification
  Future<bool> sendAchievementNotification({
    required String receiverUserId,
    required String achievementName,
  }) async {
    return sendNotificationWithFallback(
      receiverUserId: receiverUserId,
      senderUsername: 'Crystal Social',
      customMessage: '🏆 Achievement unlocked: $achievementName',
      notificationType: 'achievement',
      additionalData: {'achievement': achievementName},
    );
  }

  /// Send pet interaction notification
  Future<bool> sendPetNotification({
    required String receiverUserId,
    required String petName,
    required String action,
  }) async {
    return sendNotificationWithFallback(
      receiverUserId: receiverUserId,
      senderUsername: 'Pet Care',
      customMessage: '🐾 $petName $action',
      notificationType: 'pet_interaction',
      additionalData: {'pet_name': petName, 'action': action},
    );
  }

  /// Send support ticket notification
  Future<bool> sendSupportNotification({
    required String receiverUserId,
    required String message,
  }) async {
    return sendNotificationWithFallback(
      receiverUserId: receiverUserId,
      senderUsername: 'Support Team',
      customMessage: message,
      notificationType: 'support',
    );
  }

  /// Log notification in database for analytics
  Future<void> _logNotification({
    required String receiverUserId,
    required String senderUsername,
    required String title,
    required String body,
    required int deviceCount,
    required int successCount,
  }) async {
    try {
      await _supabase.from('notification_logs').insert({
        'receiver_user_id': receiverUserId,
        'sender_username': senderUsername,
        'title': title,
        'body': body,
        'device_count': deviceCount,
        'success_count': successCount,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('❌ Failed to log notification: $e');
    }
  }

  /// Get notification history for a user
  Future<List<Map<String, dynamic>>> getNotificationHistory(String userId, {int limit = 50}) async {
    try {
      final response = await _supabase
          .from('notification_logs')
          .select('*')
          .eq('receiver_user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Failed to get notification history: $e');
      return [];
    }
  }

  /// Initialize push notification service
  Future<void> initialize() async {
    try {
      // Request notification permissions
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ Notification permissions granted');
      } else {
        debugPrint('❌ Notification permissions denied');
      }

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

      // Handle notification taps
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Check for initial message (app opened from notification)
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      debugPrint('✅ Push Notification Service initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize Push Notification Service: $e');
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📱 Received foreground message: ${message.notification?.title}');
    
    // You can show an in-app notification here
    // For example, using a snackbar or custom overlay
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('👆 Notification tapped: ${message.data}');
    
    // Navigate to appropriate screen based on notification data
    final data = message.data;
    if (data['type'] == 'message') {
      // Navigate to chat screen
      // NavigationService.navigateToChat(data['sender']);
    }
  }

  /// Test notification (for debugging)
  Future<void> sendTestNotification(String receiverUserId) async {
    await sendNotificationWithFallback(
      receiverUserId: receiverUserId,
      senderUsername: 'Crystal Bot',
      customMessage: 'This is a test notification! 🧪',
      notificationType: 'system',
      additionalData: {
        'test': true,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// RECOMMENDED: Use sendNotificationWithFallback() for all notifications
  /// This method tries Edge Function first (secure, reliable) and falls back to direct FCM
  /// 
  /// For specific notification types, use the convenience methods:
  /// - sendChatNotification()
  /// - sendFriendRequestNotification() 
  /// - sendAchievementNotification()
  /// - sendPetNotification()
  /// - sendSupportNotification()
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  debugPrint('🔕 Received background message: ${message.notification?.title}');
  
  // Handle background message processing here
  // This could include updating local storage, badges, etc.
}
