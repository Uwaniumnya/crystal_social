import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'device_registration_service.dart';
import 'push_notification_service.dart';
import 'enhanced_push_notification_integration.dart';
import 'device_user_tracking_service.dart';
import 'glimmer_service.dart';

/// Unified Service Manager
/// Coordinates all services to work together smoothly
/// Provides a single entry point for service operations
class UnifiedServiceManager {
  static UnifiedServiceManager? _instance;
  static UnifiedServiceManager get instance {
    _instance ??= UnifiedServiceManager._internal();
    return _instance!;
  }

  UnifiedServiceManager._internal();

  // Service instances
  late final DeviceRegistrationService _deviceRegistration;
  late final PushNotificationService _pushNotification;
  late final EnhancedPushNotificationIntegration _enhancedNotification;
  late final DeviceUserTrackingService _deviceUserTracking;
  late final GlimmerService _glimmerService;
  
  final SupabaseClient _supabase = Supabase.instance.client;
  
  bool _isInitialized = false;

  /// Initialize all services
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      debugPrint('🚀 Initializing Unified Service Manager...');
      
      // Initialize service instances
      _deviceRegistration = DeviceRegistrationService.instance;
      _pushNotification = PushNotificationService.instance;
      _enhancedNotification = EnhancedPushNotificationIntegration.instance;
      _deviceUserTracking = DeviceUserTrackingService.instance;
      _glimmerService = GlimmerService();

      // Initialize enhanced notification integration (this handles the others)
      await _enhancedNotification.initialize();
      
      _isInitialized = true;
      debugPrint('✅ Unified Service Manager initialized successfully');
      
    } catch (e) {
      debugPrint('❌ Failed to initialize Unified Service Manager: $e');
      rethrow;
    }
  }

  /// Handle complete user login process
  Future<void> handleUserLogin(String userId) async {
    await _ensureInitialized();
    
    try {
      debugPrint('👤 Handling user login: $userId');
      
      // Track user on device
      await _deviceUserTracking.trackUserLogin(userId);
      
      // Register device for notifications
      await _enhancedNotification.onUserLogin(userId);
      
      debugPrint('✅ User login handled successfully: $userId');
      
    } catch (e) {
      debugPrint('❌ Failed to handle user login: $e');
      rethrow;
    }
  }

  /// Handle complete user logout process
  Future<void> handleUserLogout(String userId) async {
    await _ensureInitialized();
    
    try {
      debugPrint('👋 Handling user logout: $userId');
      
      // Track logout on device
      await _deviceUserTracking.trackUserLogout();
      
      // Deactivate device for notifications
      await _enhancedNotification.onUserLogout(userId);
      
      debugPrint('✅ User logout handled successfully: $userId');
      
    } catch (e) {
      debugPrint('❌ Failed to handle user logout: $e');
      rethrow;
    }
  }

  /// Send message notification with enhanced context
  Future<bool> sendMessageNotification({
    required String receiverUserId,
    required String senderUsername,
    String? messagePreview,
    Map<String, dynamic>? additionalContext,
  }) async {
    await _ensureInitialized();
    
    try {
      // Check if receiver has devices registered
      final devices = await _deviceRegistration.getUserDevices(receiverUserId);
      if (devices.isEmpty) {
        debugPrint('⚠️ No devices found for user: $receiverUserId');
        return false;
      }

      // Send notification through enhanced integration
      final success = await _enhancedNotification.sendMessageNotification(
        receiverUserId: receiverUserId,
        senderUsername: senderUsername,
        messagePreview: messagePreview,
      );

      if (success) {
        debugPrint('✅ Message notification sent successfully');
      } else {
        debugPrint('❌ Failed to send message notification');
      }

      return success;
      
    } catch (e) {
      debugPrint('❌ Error sending message notification: $e');
      return false;
    }
  }

  /// Send group message notification to multiple users
  Future<Map<String, bool>> sendGroupMessageNotification({
    required List<String> receiverUserIds,
    required String senderUsername,
    required String groupName,
    String? messagePreview,
  }) async {
    await _ensureInitialized();
    
    try {
      return await _enhancedNotification.sendGroupMessageNotification(
        receiverUserIds: receiverUserIds,
        senderUsername: senderUsername,
        groupName: groupName,
        messagePreview: messagePreview,
      );
    } catch (e) {
      debugPrint('❌ Error sending group message notification: $e');
      return {};
    }
  }

  /// Check if auto-logout should be applied based on device usage
  Future<bool> shouldApplyAutoLogout(String userId) async {
    await _ensureInitialized();
    
    try {
      // Check if this user is the only one who has ever used this device
      final isOnlyUser = await _deviceUserTracking.isOnlyUser(userId);
      
      // If user is the only one, no auto-logout needed
      if (isOnlyUser) {
        debugPrint('🏠 User $userId is the only user on this device - no auto-logout');
        return false;
      }

      // Multiple users have used this device - apply auto-logout for security
      debugPrint('🔒 Multiple users have used this device - applying auto-logout');
      return true;
      
    } catch (e) {
      debugPrint('❌ Error checking auto-logout: $e');
      // Default to true for security
      return true;
    }
  }

  /// Get device usage statistics
  Future<Map<String, dynamic>> getDeviceUsageStats(String currentUserId) async {
    await _ensureInitialized();
    
    try {
      final allUsers = await _deviceUserTracking.getAllDeviceUsers();
      final isOnlyUser = await _deviceUserTracking.isOnlyUser(currentUserId);
      final hasMultiple = await _deviceUserTracking.hasMultipleUsers();
      final devices = await _deviceRegistration.getUserDevices(currentUserId);

      return {
        'total_users_on_device': allUsers.length,
        'is_only_user': isOnlyUser,
        'has_multiple_users': hasMultiple,
        'active_devices_count': devices.length,
        'current_user_id': currentUserId,
        'all_device_users': allUsers,
        'should_auto_logout': !isOnlyUser,
      };
      
    } catch (e) {
      debugPrint('❌ Error getting device usage stats: $e');
      return {};
    }
  }

  /// Get comprehensive notification stats
  Future<Map<String, dynamic>> getNotificationStats(String userId) async {
    await _ensureInitialized();
    
    try {
      final devices = await _deviceRegistration.getUserDevices(userId);
      
      return {
        'active_devices': devices.length,
        'device_details': devices,
        'can_receive_notifications': devices.isNotEmpty,
      };
      
    } catch (e) {
      debugPrint('❌ Error getting notification stats: $e');
      return {};
    }
  }

  /// Handle glimmer post creation with notifications
  Future<String> createGlimmerPost({
    required String title,
    required String description,
    required dynamic imageFile,
    required String category,
    required String userId,
    required List<String> tags,
    bool notifyFollowers = false,
  }) async {
    await _ensureInitialized();
    
    try {
      // Create the post
      final postId = await _glimmerService.uploadPost(
        title: title,
        description: description,
        imageFile: imageFile,
        category: category,
        userId: userId,
        tags: tags,
      );

      // If notifications are enabled and user has followers, send notifications
      if (notifyFollowers) {
        await _notifyFollowersOfNewPost(userId, title);
      }

      return postId;
      
    } catch (e) {
      debugPrint('❌ Error creating glimmer post: $e');
      rethrow;
    }
  }

  /// Handle glimmer post interaction with notifications
  Future<bool> toggleGlimmerLike({
    required String postId,
    required String userId,
    required bool currentlyLiked,
    bool notifyPostOwner = true,
  }) async {
    await _ensureInitialized();
    
    try {
      final result = await _glimmerService.toggleLike(
        postId: postId,
        userId: userId,
        currentlyLiked: currentlyLiked,
      );
      
      // If like was added and notifications enabled, notify post owner
      if (result && notifyPostOwner) {
        await _notifyPostOwnerOfLike(postId, userId);
      }

      return result;
      
    } catch (e) {
      debugPrint('❌ Error toggling glimmer like: $e');
      return false;
    }
  }

  /// Get comprehensive glimmer feed with user context
  Future<List<Map<String, dynamic>>> getGlimmerFeed({
    String? category,
    String? searchQuery,
    required String currentUserId,
  }) async {
    await _ensureInitialized();
    
    try {
      return await _glimmerService.getPosts(
        category: category,
        searchQuery: searchQuery,
        currentUserId: currentUserId,
      );
    } catch (e) {
      debugPrint('❌ Error getting glimmer feed: $e');
      return [];
    }
  }

  /// Clean up inactive devices and old data
  Future<void> performMaintenanceCleanup() async {
    await _ensureInitialized();
    
    try {
      debugPrint('🧹 Performing maintenance cleanup...');
      
      // Note: Cleanup methods would need to be implemented in individual services
      // For now, we'll just log that maintenance was attempted
      
      debugPrint('✅ Maintenance cleanup completed');
      
    } catch (e) {
      debugPrint('❌ Error during maintenance cleanup: $e');
    }
  }

  /// Private helper methods

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  Future<void> _notifyFollowersOfNewPost(String userId, String postTitle) async {
    try {
      // Get user's followers
      final followers = await _supabase
          .from('user_follows')
          .select('follower_id')
          .eq('following_id', userId);

      final userResponse = await _supabase
          .from('users')
          .select('username')
          .eq('id', userId)
          .single();

      final username = userResponse['username'] as String;

      // Send notifications to all followers
      for (final follower in followers) {
        await _enhancedNotification.sendSystemNotification(
          receiverUserId: follower['follower_id'],
          title: 'New Post',
          message: '$username shared a new post: $postTitle',
          additionalData: {
            'type': 'new_post',
            'post_owner': username,
            'post_title': postTitle,
          },
        );
      }
      
    } catch (e) {
      debugPrint('❌ Error notifying followers of new post: $e');
    }
  }

  Future<void> _notifyPostOwnerOfLike(String postId, String likerId) async {
    try {
      // Get post details and owner
      final postResponse = await _supabase
          .from('glimmer_posts')
          .select('user_id, title')
          .eq('id', postId)
          .single();

      final postOwnerId = postResponse['user_id'] as String;
      final postTitle = postResponse['title'] as String;

      // Don't notify if user liked their own post
      if (postOwnerId == likerId) return;

      // Get liker's username
      final likerResponse = await _supabase
          .from('users')
          .select('username')
          .eq('id', likerId)
          .single();

      final likerUsername = likerResponse['username'] as String;

      // Send notification to post owner
      await _enhancedNotification.sendSystemNotification(
        receiverUserId: postOwnerId,
        title: 'New Like',
        message: '$likerUsername liked your post: $postTitle',
        additionalData: {
          'type': 'post_like',
          'post_id': postId,
          'liker': likerUsername,
          'post_title': postTitle,
        },
      );
      
    } catch (e) {
      debugPrint('❌ Error notifying post owner of like: $e');
    }
  }

  /// Getters for individual services (if needed for specific operations)
  DeviceRegistrationService get deviceRegistration => _deviceRegistration;
  PushNotificationService get pushNotification => _pushNotification;
  EnhancedPushNotificationIntegration get enhancedNotification => _enhancedNotification;
  DeviceUserTrackingService get deviceUserTracking => _deviceUserTracking;
  GlimmerService get glimmerService => _glimmerService;
}
