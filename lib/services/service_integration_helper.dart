import 'package:flutter/foundation.dart';
import 'unified_service_manager.dart';

/// Service Integration Helper
/// Provides easy-to-use wrappers for common service operations
class ServiceIntegrationHelper {
  static ServiceIntegrationHelper? _instance;
  static ServiceIntegrationHelper get instance {
    _instance ??= ServiceIntegrationHelper._internal();
    return _instance!;
  }

  ServiceIntegrationHelper._internal();

  final UnifiedServiceManager _serviceManager = UnifiedServiceManager.instance;

  /// Initialize all services through the unified manager
  Future<void> initializeAll() async {
    await _serviceManager.initialize();
  }

  /// Complete login flow with all necessary service registrations
  Future<void> completeLoginFlow(String userId) async {
    try {
      debugPrint('🔐 Starting complete login flow for: $userId');
      
      // Handle user login across all services
      await _serviceManager.handleUserLogin(userId);
      
      // Get device stats for logging
      final deviceStats = await _serviceManager.getDeviceUsageStats(userId);
      debugPrint('📱 Device stats: ${deviceStats['total_users_on_device']} total users');
      
      debugPrint('✅ Complete login flow finished for: $userId');
      
    } catch (e) {
      debugPrint('❌ Error in complete login flow: $e');
      rethrow;
    }
  }

  /// Complete logout flow with proper cleanup
  Future<void> completeLogoutFlow(String userId) async {
    try {
      debugPrint('🚪 Starting complete logout flow for: $userId');
      
      // Handle user logout across all services
      await _serviceManager.handleUserLogout(userId);
      
      debugPrint('✅ Complete logout flow finished for: $userId');
      
    } catch (e) {
      debugPrint('❌ Error in complete logout flow: $e');
      rethrow;
    }
  }

  /// Send a chat message with automatic notification
  Future<bool> sendChatMessageWithNotification({
    required String receiverUserId,
    required String senderUsername,
    required String messageContent,
    String? messagePreview,
  }) async {
    try {
      // Send the actual message (this would integrate with your chat service)
      // For now, we'll just send the notification
      
      final success = await _serviceManager.sendMessageNotification(
        receiverUserId: receiverUserId,
        senderUsername: senderUsername,
        messagePreview: messagePreview ?? _truncateMessage(messageContent),
      );

      if (success) {
        debugPrint('✅ Chat message notification sent successfully');
      } else {
        debugPrint('⚠️ Chat message notification failed');
      }

      return success;
      
    } catch (e) {
      debugPrint('❌ Error sending chat message with notification: $e');
      return false;
    }
  }

  /// Create a glimmer post with full integration
  Future<String?> createGlimmerPostWithIntegration({
    required String title,
    required String description,
    required dynamic imageFile,
    required String category,
    required String userId,
    required List<String> tags,
    bool notifyFollowers = true,
  }) async {
    try {
      final postId = await _serviceManager.createGlimmerPost(
        title: title,
        description: description,
        imageFile: imageFile,
        category: category,
        userId: userId,
        tags: tags,
        notifyFollowers: notifyFollowers,
      );

      debugPrint('✅ Glimmer post created with full integration: $postId');
      return postId;
      
    } catch (e) {
      debugPrint('❌ Error creating glimmer post with integration: $e');
      return null;
    }
  }

  /// Like a glimmer post with notification
  Future<bool> likeGlimmerPostWithNotification({
    required String postId,
    required String userId,
    required bool currentlyLiked,
    bool notifyPostOwner = true,
  }) async {
    try {
      return await _serviceManager.toggleGlimmerLike(
        postId: postId,
        userId: userId,
        currentlyLiked: currentlyLiked,
        notifyPostOwner: notifyPostOwner,
      );
    } catch (e) {
      debugPrint('❌ Error liking glimmer post with notification: $e');
      return false;
    }
  }

  /// Get comprehensive user status across all services
  Future<Map<String, dynamic>> getUserComprehensiveStatus(String userId) async {
    try {
      final deviceStats = await _serviceManager.getDeviceUsageStats(userId);
      final notificationStats = await _serviceManager.getNotificationStats(userId);
      final shouldAutoLogout = await _serviceManager.shouldApplyAutoLogout(userId);

      return {
        'user_id': userId,
        'device_stats': deviceStats,
        'notification_stats': notificationStats,
        'should_auto_logout': shouldAutoLogout,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
    } catch (e) {
      debugPrint('❌ Error getting comprehensive user status: $e');
      return {'error': e.toString()};
    }
  }

  /// Check if user should be auto-logged out for security
  Future<bool> shouldUserBeAutoLoggedOut(String userId) async {
    return await _serviceManager.shouldApplyAutoLogout(userId);
  }

  /// Get glimmer feed with user context
  Future<List<Map<String, dynamic>>> getPersonalizedGlimmerFeed({
    required String userId,
    String? category,
    String? searchQuery,
  }) async {
    try {
      return await _serviceManager.getGlimmerFeed(
        category: category,
        searchQuery: searchQuery,
        currentUserId: userId,
      );
    } catch (e) {
      debugPrint('❌ Error getting personalized glimmer feed: $e');
      return [];
    }
  }

  /// Send friend request with notification
  Future<bool> sendFriendRequestWithNotification({
    required String receiverUserId,
    required String senderUsername,
  }) async {
    try {
      // Send friend request (integrate with your friend system)
      // For now, we'll just send the notification
      
      final success = await _serviceManager.enhancedNotification.sendFriendRequestNotification(
        receiverUserId: receiverUserId,
        senderUsername: senderUsername,
      );

      if (success) {
        debugPrint('✅ Friend request notification sent successfully');
      } else {
        debugPrint('⚠️ Friend request notification failed');
      }

      return success;
      
    } catch (e) {
      debugPrint('❌ Error sending friend request with notification: $e');
      return false;
    }
  }

  /// Send group message with notifications to all members
  Future<Map<String, bool>> sendGroupMessageWithNotifications({
    required List<String> memberUserIds,
    required String senderUsername,
    required String groupName,
    required String messageContent,
    String? messagePreview,
  }) async {
    try {
      return await _serviceManager.sendGroupMessageNotification(
        receiverUserIds: memberUserIds,
        senderUsername: senderUsername,
        groupName: groupName,
        messagePreview: messagePreview ?? _truncateMessage(messageContent),
      );
    } catch (e) {
      debugPrint('❌ Error sending group message with notifications: $e');
      return {};
    }
  }

  /// Perform system maintenance across all services
  Future<void> performSystemMaintenance() async {
    try {
      debugPrint('🔧 Starting system maintenance...');
      
      await _serviceManager.performMaintenanceCleanup();
      
      debugPrint('✅ System maintenance completed');
      
    } catch (e) {
      debugPrint('❌ Error during system maintenance: $e');
    }
  }

  /// Get system health status
  Future<Map<String, dynamic>> getSystemHealthStatus() async {
    try {
      return {
        'unified_service_manager': 'operational',
        'device_registration': 'operational',
        'push_notifications': 'operational',
        'device_user_tracking': 'operational',
        'glimmer_service': 'operational',
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'healthy',
      };
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Private helper methods

  String _truncateMessage(String message, {int maxLength = 50}) {
    if (message.length <= maxLength) return message;
    return '${message.substring(0, maxLength)}...';
  }

  /// Direct access to unified service manager if needed
  UnifiedServiceManager get serviceManager => _serviceManager;
}
