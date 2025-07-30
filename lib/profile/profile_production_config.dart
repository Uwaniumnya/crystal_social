import 'package:flutter/foundation.dart';

/// Production configuration for the Profile subsystem
class ProfileProductionConfig {
  static const String version = '1.0.0';
  static const String lastUpdated = '2024-12-20';
  
  // Environment flags
  static const bool isProduction = kReleaseMode;
  static const bool enableDebugLogging = !kReleaseMode;
  static const bool enablePerformanceMonitoring = true;
  
  // Profile service settings
  static const int cacheTimeout = 300; // 5 minutes
  static const int maxRetryAttempts = 3;
  static const Duration requestTimeout = Duration(seconds: 30);
  static const int maxCacheSize = 100; // Maximum cached profiles
  
  // Avatar settings
  static const int maxAvatarSize = 2 * 1024 * 1024; // 2MB
  static const List<String> supportedImageFormats = ['jpg', 'jpeg', 'png', 'gif'];
  static const int maxDecorationCacheSize = 50;
  
  // Sound settings
  static const int maxCustomSounds = 20;
  static const int maxSoundFileSize = 1 * 1024 * 1024; // 1MB
  static const List<String> supportedAudioFormats = ['mp3', 'wav', 'aac'];
  static const double defaultVolume = 0.7;
  
  // Stats and analytics
  static const int maxStatHistoryDays = 30;
  static const int statsUpdateInterval = 60; // seconds
  static const bool enableAnalytics = isProduction;
  
  // Privacy and security
  static const bool enforcePrivacySettings = true;
  static const int sessionTimeoutMinutes = 30;
  static const bool enableDataEncryption = true;
  
  // UI settings
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration hapticFeedbackDelay = Duration(milliseconds: 50);
  static const int maxBioLength = 500;
  static const int maxUsernameLength = 30;
  
  // Performance thresholds
  static const int profileLoadTimeoutMs = 5000;
  static const int imageLoadTimeoutMs = 10000;
  static const int maxConcurrentUploads = 3;
  
  /// Get environment-specific database settings
  static Map<String, dynamic> getDatabaseConfig() {
    return {
      'timeout': requestTimeout.inSeconds,
      'retries': maxRetryAttempts,
      'cache_enabled': true,
      'cache_size': maxCacheSize,
      'encryption_enabled': enableDataEncryption,
    };
  }
  
  /// Get media handling configuration
  static Map<String, dynamic> getMediaConfig() {
    return {
      'max_avatar_size': maxAvatarSize,
      'supported_image_formats': supportedImageFormats,
      'max_sound_size': maxSoundFileSize,
      'supported_audio_formats': supportedAudioFormats,
      'default_volume': defaultVolume,
      'max_concurrent_uploads': maxConcurrentUploads,
    };
  }
  
  /// Get performance monitoring configuration
  static Map<String, dynamic> getPerformanceConfig() {
    return {
      'monitoring_enabled': enablePerformanceMonitoring,
      'analytics_enabled': enableAnalytics,
      'profile_load_timeout': profileLoadTimeoutMs,
      'image_load_timeout': imageLoadTimeoutMs,
      'stats_update_interval': statsUpdateInterval,
    };
  }
  
  /// Get UI configuration
  static Map<String, dynamic> getUIConfig() {
    return {
      'animation_duration': animationDuration.inMilliseconds,
      'haptic_feedback_delay': hapticFeedbackDelay.inMilliseconds,
      'max_bio_length': maxBioLength,
      'max_username_length': maxUsernameLength,
    };
  }
  
  /// Validate production readiness
  static bool validateProductionConfig() {
    final checks = [
      isProduction == kReleaseMode,
      enableDebugLogging == !kReleaseMode,
      maxAvatarSize > 0,
      maxSoundFileSize > 0,
      supportedImageFormats.isNotEmpty,
      supportedAudioFormats.isNotEmpty,
      maxRetryAttempts > 0,
      requestTimeout.inSeconds > 0,
    ];
    
    return checks.every((check) => check);
  }
  
  /// Get configuration summary for debugging
  static Map<String, dynamic> getConfigSummary() {
    return {
      'version': version,
      'last_updated': lastUpdated,
      'is_production': isProduction,
      'debug_logging': enableDebugLogging,
      'performance_monitoring': enablePerformanceMonitoring,
      'cache_timeout': cacheTimeout,
      'max_avatar_size_mb': maxAvatarSize / (1024 * 1024),
      'max_sound_size_mb': maxSoundFileSize / (1024 * 1024),
      'validation_passed': validateProductionConfig(),
    };
  }
}

/// Debug utility for profile system
class ProfileDebugUtils {
  static void conditionalLog(String message, [Object? error]) {
    if (ProfileProductionConfig.enableDebugLogging) {
      if (kDebugMode) {
        if (error != null) {
          debugPrint('Profile Debug: $message - Error: $error');
        } else {
          debugPrint('Profile Debug: $message');
        }
      }
    }
  }
  
  static void logError(String operation, Object error, [StackTrace? stackTrace]) {
    if (ProfileProductionConfig.enableDebugLogging) {
      if (kDebugMode) {
        debugPrint('Profile Error in $operation: $error');
        if (stackTrace != null) {
          debugPrint('Stack trace: $stackTrace');
        }
      }
    }
  }
  
  static void logPerformance(String operation, Duration duration) {
    if (ProfileProductionConfig.enablePerformanceMonitoring && kDebugMode) {
      debugPrint('Profile Performance: $operation took ${duration.inMilliseconds}ms');
    }
  }
  
  static void logCacheOperation(String operation, String key, bool hit) {
    if (ProfileProductionConfig.enableDebugLogging && kDebugMode) {
      debugPrint('Profile Cache: $operation for $key - ${hit ? 'HIT' : 'MISS'}');
    }
  }
}
