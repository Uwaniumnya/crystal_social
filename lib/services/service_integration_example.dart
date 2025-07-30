import 'package:flutter/material.dart';
import 'service_initializer.dart';

/// Example of how to integrate and use all services together
/// This file demonstrates the smooth integration between services
class ServiceIntegrationExample {
  
  /// Example: Complete app initialization
  static Future<void> initializeApp() async {
    try {
      // Initialize all services at app startup
      final success = await Services.initialize();
      
      if (success) {
        debugPrint('✅ App services initialized successfully');
      } else {
        debugPrint('❌ App services initialization failed');
      }
      
    } catch (e) {
      debugPrint('❌ App initialization error: $e');
    }
  }

  /// Example: User login flow
  static Future<void> handleUserLogin(String userId) async {
    try {
      // Ensure services are ready
      await Services.isReady();
      
      // Complete login flow with all service integrations
      await Services.login(userId);
      
      // Get user status across all services
      final userStatus = await Services.helper.getUserComprehensiveStatus(userId);
      debugPrint('👤 User status: $userStatus');
      
      // Check if auto-logout should be applied
      final shouldAutoLogout = await Services.helper.shouldUserBeAutoLoggedOut(userId);
      if (shouldAutoLogout) {
        debugPrint('🔒 Auto-logout will be applied for security');
      }
      
    } catch (e) {
      debugPrint('❌ Login flow error: $e');
    }
  }

  /// Example: User logout flow
  static Future<void> handleUserLogout(String userId) async {
    try {
      // Complete logout flow with all service cleanup
      await Services.logout(userId);
      
    } catch (e) {
      debugPrint('❌ Logout flow error: $e');
    }
  }

  /// Example: Send chat message with notification
  static Future<void> sendChatMessage({
    required String receiverUserId,
    required String senderUsername,
    required String messageContent,
  }) async {
    try {
      // Send message with automatic notification
      final success = await Services.helper.sendChatMessageWithNotification(
        receiverUserId: receiverUserId,
        senderUsername: senderUsername,
        messageContent: messageContent,
      );
      
      if (success) {
        debugPrint('✅ Chat message sent with notification');
      } else {
        debugPrint('⚠️ Chat message notification failed');
      }
      
    } catch (e) {
      debugPrint('❌ Chat message error: $e');
    }
  }

  /// Example: Create glimmer post with notifications
  static Future<void> createGlimmerPost({
    required String title,
    required String description,
    required dynamic imageFile,
    required String category,
    required String userId,
    required List<String> tags,
  }) async {
    try {
      // Create post with follower notifications
      final postId = await Services.helper.createGlimmerPostWithIntegration(
        title: title,
        description: description,
        imageFile: imageFile,
        category: category,
        userId: userId,
        tags: tags,
        notifyFollowers: true,
      );
      
      if (postId != null) {
        debugPrint('✅ Glimmer post created: $postId');
      } else {
        debugPrint('❌ Failed to create glimmer post');
      }
      
    } catch (e) {
      debugPrint('❌ Glimmer post creation error: $e');
    }
  }

  /// Example: Like glimmer post with notification
  static Future<void> likeGlimmerPost({
    required String postId,
    required String userId,
    required bool currentlyLiked,
  }) async {
    try {
      // Toggle like with post owner notification
      final success = await Services.helper.likeGlimmerPostWithNotification(
        postId: postId,
        userId: userId,
        currentlyLiked: currentlyLiked,
        notifyPostOwner: true,
      );
      
      if (success) {
        debugPrint('✅ Post liked with notification');
      } else {
        debugPrint('⚠️ Post like notification failed');
      }
      
    } catch (e) {
      debugPrint('❌ Post like error: $e');
    }
  }

  /// Example: Send friend request with notification
  static Future<void> sendFriendRequest({
    required String receiverUserId,
    required String senderUsername,
  }) async {
    try {
      // Send friend request with notification
      final success = await Services.helper.sendFriendRequestWithNotification(
        receiverUserId: receiverUserId,
        senderUsername: senderUsername,
      );
      
      if (success) {
        debugPrint('✅ Friend request sent with notification');
      } else {
        debugPrint('⚠️ Friend request notification failed');
      }
      
    } catch (e) {
      debugPrint('❌ Friend request error: $e');
    }
  }

  /// Example: Send group message with notifications
  static Future<void> sendGroupMessage({
    required List<String> memberUserIds,
    required String senderUsername,
    required String groupName,
    required String messageContent,
  }) async {
    try {
      // Send group message with notifications to all members
      final results = await Services.helper.sendGroupMessageWithNotifications(
        memberUserIds: memberUserIds,
        senderUsername: senderUsername,
        groupName: groupName,
        messageContent: messageContent,
      );
      
      final successCount = results.values.where((success) => success).length;
      debugPrint('✅ Group message sent to $successCount/${results.length} members');
      
    } catch (e) {
      debugPrint('❌ Group message error: $e');
    }
  }

  /// Example: Get personalized content feed
  static Future<List<Map<String, dynamic>>> getPersonalizedFeed({
    required String userId,
    String? category,
    String? searchQuery,
  }) async {
    try {
      // Get personalized glimmer feed
      final feed = await Services.helper.getPersonalizedGlimmerFeed(
        userId: userId,
        category: category,
        searchQuery: searchQuery,
      );
      
      debugPrint('📱 Loaded ${feed.length} posts for user $userId');
      return feed;
      
    } catch (e) {
      debugPrint('❌ Feed loading error: $e');
      return [];
    }
  }

  /// Example: Check system health
  static Future<void> checkSystemHealth() async {
    try {
      // Get comprehensive service status
      final status = await Services.getStatus();
      
      debugPrint('🏥 System health: ${status['health_status']['status']}');
      
      if (status['health_status']['status'] != 'healthy') {
        debugPrint('⚠️ System health issue detected');
      }
      
    } catch (e) {
      debugPrint('❌ Health check error: $e');
    }
  }

  /// Example: Perform system maintenance
  static Future<void> performMaintenance() async {
    try {
      // Perform system-wide maintenance
      await Services.helper.performSystemMaintenance();
      
      debugPrint('✅ System maintenance completed');
      
    } catch (e) {
      debugPrint('❌ Maintenance error: $e');
    }
  }

  /// Example: Get notification statistics
  static Future<Map<String, dynamic>> getNotificationStats(String userId) async {
    try {
      // Get comprehensive notification statistics
      final stats = await Services.unified.getNotificationStats(userId);
      
      debugPrint('📊 Notification stats: ${stats['active_devices']} active devices');
      return stats;
      
    } catch (e) {
      debugPrint('❌ Notification stats error: $e');
      return {};
    }
  }

  /// Example: Quick notification (convenience method)
  static Future<void> quickNotify({
    required String receiverUserId,
    required String senderUsername,
    String? message,
  }) async {
    try {
      // Quick notification using the convenience method
      final success = await Services.notifyMessage(
        receiverUserId: receiverUserId,
        senderUsername: senderUsername,
        messagePreview: message,
      );
      
      if (success) {
        debugPrint('✅ Quick notification sent');
      } else {
        debugPrint('⚠️ Quick notification failed');
      }
      
    } catch (e) {
      debugPrint('❌ Quick notification error: $e');
    }
  }
}

/// Widget example showing how to use services in Flutter widgets
class ServiceIntegratedWidget extends StatefulWidget {
  final String userId;
  
  const ServiceIntegratedWidget({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<ServiceIntegratedWidget> createState() => _ServiceIntegratedWidgetState();
}

class _ServiceIntegratedWidgetState extends State<ServiceIntegratedWidget> {
  bool _servicesReady = false;
  Map<String, dynamic> _userStatus = {};

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      // Ensure services are ready
      final ready = await Services.isReady();
      
      if (ready) {
        // Get user status
        final status = await Services.helper.getUserComprehensiveStatus(widget.userId);
        
        setState(() {
          _servicesReady = true;
          _userStatus = status;
        });
      }
      
    } catch (e) {
      debugPrint('Widget service initialization error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_servicesReady) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Column(
      children: [
        Text('Services Ready: $_servicesReady'),
        Text('User ID: ${widget.userId}'),
        Text('Device Users: ${_userStatus['device_stats']?['total_users_on_device'] ?? 0}'),
        Text('Active Devices: ${_userStatus['notification_stats']?['active_devices'] ?? 0}'),
        Text('Auto Logout: ${_userStatus['should_auto_logout']}'),
        
        ElevatedButton(
          onPressed: () async {
            // Example: Send test notification
            await ServiceIntegrationExample.quickNotify(
              receiverUserId: widget.userId,
              senderUsername: 'Test User',
              message: 'Test notification from integrated services',
            );
          },
          child: const Text('Send Test Notification'),
        ),
        
        ElevatedButton(
          onPressed: () async {
            // Example: Check system health
            await ServiceIntegrationExample.checkSystemHealth();
          },
          child: const Text('Check System Health'),
        ),
      ],
    );
  }
}
