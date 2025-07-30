import 'package:flutter/foundation.dart';

/// Services Production Configuration
/// Centralized production settings for all Crystal Social services
/// Optimized for release builds with performance and security focus
class ServicesProductionConfig {
  
  // ============================================================================
  // PRODUCTION ENVIRONMENT SETTINGS
  // ============================================================================
  
  /// Whether we're running in production mode
  static const bool isProduction = kReleaseMode;
  
  /// Enable debug logging only in debug builds
  static const bool enableDebugLogging = kDebugMode;
  
  /// Enable verbose service logging for troubleshooting
  static const bool enableVerboseLogging = false;
  
  /// Enable performance monitoring
  static const bool enablePerformanceMonitoring = true;
  
  // ============================================================================
  // NOTIFICATION SERVICE CONFIGURATION
  // ============================================================================
  
  /// Core notification settings
  static const bool enablePushNotifications = true;
  static const bool enableMessageNotifications = true;
  static const bool enableGlimmerNotifications = true;
  static const bool enableFriendRequestNotifications = true;
  static const bool enableSystemNotifications = true;
  
  /// Notification performance settings
  static const Duration notificationTimeout = Duration(seconds: 15);
  static const int maxNotificationRetryAttempts = 3;
  static const Duration notificationRetryDelay = Duration(seconds: 2);
  
  /// Notification batch processing
  static const int maxNotificationBatchSize = 100;
  static const Duration notificationBatchInterval = Duration(seconds: 5);
  
  // ============================================================================
  // DEVICE REGISTRATION CONFIGURATION
  // ============================================================================
  
  /// Device registration limits and settings
  static const bool enableDeviceRegistration = true;
  static const int maxDevicesPerUser = 10;
  static const Duration deviceRegistrationTimeout = Duration(seconds: 30);
  
  /// Device cleanup settings
  static const int maxInactiveDeviceDays = 90;
  static const bool enableAutomaticDeviceCleanup = true;
  static const Duration deviceCleanupInterval = Duration(hours: 24);
  
  // ============================================================================
  // USER TRACKING CONFIGURATION
  // ============================================================================
  
  /// User tracking and auto-logout settings
  static const bool enableUserTracking = true;
  static const bool enableAutoLogout = true;
  static const bool forceAutoLogoutForMultipleUsers = true;
  
  /// User session management
  static const Duration userSessionTimeout = Duration(hours: 24);
  static const int maxConcurrentUserSessions = 5;
  
  // ============================================================================
  // GLIMMER SERVICE CONFIGURATION
  // ============================================================================
  
  /// Glimmer post and interaction settings
  static const bool enableGlimmerIntegration = true;
  static const bool notifyFollowersOnNewPost = true;
  static const bool notifyOwnerOnLike = true;
  static const bool notifyOwnerOnComment = true;
  
  /// Glimmer performance settings
  static const int glimmerPostBatchSize = 50;
  static const Duration glimmerCacheTimeout = Duration(minutes: 30);
  static const int maxGlimmerRetryAttempts = 3;
  
  // ============================================================================
  // PERFORMANCE OPTIMIZATION
  // ============================================================================
  
  /// Service initialization timeouts
  static const Duration serviceInitializationTimeout = Duration(seconds: 45);
  static const Duration unifiedManagerInitTimeout = Duration(seconds: 30);
  
  /// Network and API settings
  static const Duration networkTimeout = Duration(seconds: 30);
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 1);
  
  /// Memory and cache optimization
  static const bool enableServiceCaching = true;
  static const Duration serviceCacheTimeout = Duration(minutes: 15);
  static const int maxCacheSize = 1000;
  
  // ============================================================================
  // MAINTENANCE AND CLEANUP
  // ============================================================================
  
  /// Automatic maintenance settings
  static const bool enableAutomaticMaintenance = true;
  static const Duration maintenanceInterval = Duration(hours: 24);
  static const Duration maintenanceWindow = Duration(hours: 2);
  
  /// Data retention policies
  static const int maxNotificationLogDays = 30;
  static const int maxServiceLogDays = 7;
  static const int maxErrorLogDays = 14;
  
  /// Cleanup batch sizes
  static const int maintenanceCleanupBatchSize = 1000;
  static const Duration maintenanceCleanupDelay = Duration(milliseconds: 100);
  
  // ============================================================================
  // SECURITY CONFIGURATION
  // ============================================================================
  
  /// API key and security settings
  static const bool validateApiKeys = true;
  static const bool enableServiceVerification = true;
  static const bool logServiceOperations = false; // Disabled in production for security
  
  /// Rate limiting
  static const int maxRequestsPerMinute = 100;
  static const int maxRequestsPerHour = 1000;
  static const Duration rateLimitWindow = Duration(minutes: 1);
  
  // ============================================================================
  // ERROR HANDLING AND MONITORING
  // ============================================================================
  
  /// Error reporting settings
  static const bool enableErrorReporting = true;
  static const bool enableCrashlytics = true;
  static const bool logDetailedErrors = kDebugMode;
  
  /// Service health monitoring
  static const bool enableHealthChecks = true;
  static const Duration healthCheckInterval = Duration(minutes: 5);
  static const int maxConsecutiveFailures = 3;
  
  // ============================================================================
  // FEATURE FLAGS
  // ============================================================================
  
  /// Service feature toggles
  static const Map<String, bool> featureFlags = {
    'enhanced_notifications': true,
    'batch_processing': true,
    'automatic_cleanup': true,
    'performance_monitoring': true,
    'advanced_caching': true,
    'rate_limiting': true,
    'service_verification': true,
    'health_monitoring': true,
  };
  
  // ============================================================================
  // PRODUCTION VALIDATION
  // ============================================================================
  
  /// Validate production configuration
  static bool validateProductionConfig() {
    // Ensure critical services are enabled
    if (!enableDeviceRegistration || !enablePushNotifications) {
      if (kDebugMode) {
        debugPrint('⚠️ Critical services disabled in production config');
      }
      return false;
    }
    
    // Validate timeout settings are reasonable
    if (serviceInitializationTimeout.inSeconds < 10 || 
        notificationTimeout.inSeconds < 5) {
      if (kDebugMode) {
        debugPrint('⚠️ Timeout settings too aggressive for production');
      }
      return false;
    }
    
    // Validate security settings
    if (logServiceOperations && isProduction) {
      if (kDebugMode) {
        debugPrint('⚠️ Service operation logging enabled in production');
      }
      return false;
    }
    
    return true;
  }
  
  /// Get environment-specific configuration
  static Map<String, dynamic> getEnvironmentConfig() {
    return {
      'environment': isProduction ? 'production' : 'development',
      'debug_enabled': enableDebugLogging,
      'verbose_logging': enableVerboseLogging,
      'performance_monitoring': enablePerformanceMonitoring,
      'feature_flags': featureFlags,
      'timeouts': {
        'service_init': serviceInitializationTimeout.inMilliseconds,
        'notification': notificationTimeout.inMilliseconds,
        'network': networkTimeout.inMilliseconds,
      },
      'limits': {
        'max_devices_per_user': maxDevicesPerUser,
        'max_notification_batch': maxNotificationBatchSize,
        'max_retry_attempts': maxRetryAttempts,
      },
      'security': {
        'validate_api_keys': validateApiKeys,
        'enable_verification': enableServiceVerification,
        'log_operations': logServiceOperations,
      },
    };
  }
  
  /// Check if feature is enabled
  static bool isFeatureEnabled(String feature) {
    return featureFlags[feature] ?? false;
  }
  
  /// Get production-optimized service configuration
  static Map<String, dynamic> getServiceConfig(String serviceName) {
    final baseConfig = {
      'timeout': serviceInitializationTimeout.inMilliseconds,
      'retry_attempts': maxRetryAttempts,
      'enable_caching': enableServiceCaching,
      'enable_monitoring': enablePerformanceMonitoring,
    };
    
    switch (serviceName) {
      case 'notification':
        return {
          ...baseConfig,
          'batch_size': maxNotificationBatchSize,
          'batch_interval': notificationBatchInterval.inMilliseconds,
          'timeout': notificationTimeout.inMilliseconds,
        };
      case 'device_registration':
        return {
          ...baseConfig,
          'max_devices': maxDevicesPerUser,
          'cleanup_enabled': enableAutomaticDeviceCleanup,
          'inactive_days': maxInactiveDeviceDays,
        };
      case 'glimmer':
        return {
          ...baseConfig,
          'batch_size': glimmerPostBatchSize,
          'cache_timeout': glimmerCacheTimeout.inMilliseconds,
          'notify_followers': notifyFollowersOnNewPost,
        };
      default:
        return baseConfig;
    }
  }
}
