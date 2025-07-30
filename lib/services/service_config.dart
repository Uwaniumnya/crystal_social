import 'services_production_config.dart';

/// Service Configuration
/// Centralized configuration for all integrated services
/// Now uses production configuration for optimal performance
class ServiceConfig {
  
  // Use production configuration as the source of truth
  static bool get enablePushNotifications => ServicesProductionConfig.enablePushNotifications;
  static bool get enableMessageNotifications => ServicesProductionConfig.enableMessageNotifications;
  static bool get enableGlimmerNotifications => ServicesProductionConfig.enableGlimmerNotifications;
  static bool get enableFriendRequestNotifications => ServicesProductionConfig.enableFriendRequestNotifications;
  static bool get enableSystemNotifications => ServicesProductionConfig.enableSystemNotifications;
  
  // Auto-logout Configuration
  static bool get enableAutoLogout => ServicesProductionConfig.enableAutoLogout;
  static bool get forceAutoLogoutForMultipleUsers => ServicesProductionConfig.forceAutoLogoutForMultipleUsers;
  
  // Device Registration Configuration
  static bool get enableDeviceRegistration => ServicesProductionConfig.enableDeviceRegistration;
  static bool get trackDeviceUsers => ServicesProductionConfig.enableUserTracking;
  static int get maxDevicesPerUser => ServicesProductionConfig.maxDevicesPerUser;
  
  // Glimmer Service Configuration
  static bool get enableGlimmerIntegration => ServicesProductionConfig.enableGlimmerIntegration;
  static bool get notifyFollowersOnNewPost => ServicesProductionConfig.notifyFollowersOnNewPost;
  static bool get notifyOwnerOnLike => ServicesProductionConfig.notifyOwnerOnLike;
  static bool get notifyOwnerOnComment => ServicesProductionConfig.notifyOwnerOnComment;
  
  // Maintenance Configuration
  static bool get enableAutomaticMaintenance => ServicesProductionConfig.enableAutomaticMaintenance;
  static Duration get maintenanceInterval => ServicesProductionConfig.maintenanceInterval;
  static int get maxNotificationLogDays => ServicesProductionConfig.maxNotificationLogDays;
  static int get maxInactiveDeviceDays => ServicesProductionConfig.maxInactiveDeviceDays;
  
  // Debug Configuration (production-aware)
  static bool get enableDebugLogging => ServicesProductionConfig.enableDebugLogging;
  static bool get enableServiceVerification => ServicesProductionConfig.enableServiceVerification;
  static bool get logServiceOperations => ServicesProductionConfig.logServiceOperations;
  
  // Performance Configuration
  static Duration get serviceInitializationTimeout => ServicesProductionConfig.serviceInitializationTimeout;
  static Duration get notificationTimeout => ServicesProductionConfig.notificationTimeout;
  static int get maxRetryAttempts => ServicesProductionConfig.maxRetryAttempts;
  
  /// Get notification settings based on type
  static bool isNotificationEnabled(String notificationType) {
    switch (notificationType) {
      case 'message':
        return enableMessageNotifications;
      case 'glimmer':
        return enableGlimmerNotifications;
      case 'friend_request':
        return enableFriendRequestNotifications;
      case 'system':
        return enableSystemNotifications;
      default:
        return enablePushNotifications;
    }
  }
  
  /// Get complete configuration as a map
  static Map<String, dynamic> toMap() {
    return {
      'notifications': {
        'enabled': enablePushNotifications,
        'message_notifications': enableMessageNotifications,
        'glimmer_notifications': enableGlimmerNotifications,
        'friend_request_notifications': enableFriendRequestNotifications,
        'system_notifications': enableSystemNotifications,
      },
      'auto_logout': {
        'enabled': enableAutoLogout,
        'force_for_multiple_users': forceAutoLogoutForMultipleUsers,
      },
      'device_registration': {
        'enabled': enableDeviceRegistration,
        'track_device_users': trackDeviceUsers,
        'max_devices_per_user': maxDevicesPerUser,
      },
      'glimmer': {
        'enabled': enableGlimmerIntegration,
        'notify_followers_on_new_post': notifyFollowersOnNewPost,
        'notify_owner_on_like': notifyOwnerOnLike,
        'notify_owner_on_comment': notifyOwnerOnComment,
      },
      'maintenance': {
        'enabled': enableAutomaticMaintenance,
        'interval_hours': maintenanceInterval.inHours,
        'max_notification_log_days': maxNotificationLogDays,
        'max_inactive_device_days': maxInactiveDeviceDays,
      },
      'debug': {
        'enable_logging': enableDebugLogging,
        'enable_verification': enableServiceVerification,
        'log_operations': logServiceOperations,
      },
      'performance': {
        'initialization_timeout_seconds': serviceInitializationTimeout.inSeconds,
        'notification_timeout_seconds': notificationTimeout.inSeconds,
        'max_retry_attempts': maxRetryAttempts,
      },
    };
  }
}
