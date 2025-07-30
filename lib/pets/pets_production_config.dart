import 'package:flutter/foundation.dart';

/// Production configuration for the Pets subsystem
class PetsProductionConfig {
  static const String version = '1.0.0';
  static const String lastUpdated = '2024-12-20';
  
  // Environment flags
  static const bool isProduction = kReleaseMode;
  static const bool enableDebugLogging = !kReleaseMode;
  static const bool enablePerformanceMonitoring = true;
  
  // Pet system settings
  static const int maxPets = 50;
  static const int maxAccessories = 100;
  static const Duration petSoundCooldown = Duration(seconds: 3);
  static const Duration autoSaveInterval = Duration(seconds: 30);
  static const int maxPetLevel = 100;
  static const int xpPerLevel = 100;
  
  // Animation settings
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration petMovementInterval = Duration(seconds: 5);
  static const int maxAnimationFrames = 60;
  static const bool enableParticleEffects = true;
  
  // Audio settings
  static const double defaultVolume = 0.7;
  static const int maxSoundsPerMinute = 20;
  static const int soundCacheSize = 30;
  static const List<String> supportedAudioFormats = ['mp3', 'wav', 'aac'];
  
  // Game settings
  static const int maxMiniGameDuration = 300; // 5 minutes
  static const int maxDailyXP = 1000;
  static const int maxStreak = 365;
  static const Duration gameSessionTimeout = Duration(minutes: 10);
  
  // Health and care settings
  static const double minHappiness = 0.0;
  static const double maxHappiness = 1.0;
  static const double defaultHappiness = 1.0;
  static const Duration hungerInterval = Duration(hours: 6);
  static const Duration playInterval = Duration(hours: 4);
  
  // Performance settings
  static const int maxConcurrentAnimations = 5;
  static const int petStateUpdateInterval = 1000; // milliseconds
  static const int maxCacheSize = 100;
  static const Duration networkTimeout = Duration(seconds: 30);
  
  // Database settings
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  static const bool enableDataCompression = true;
  static const bool enableOfflineMode = true;
  
  // Security settings
  static const bool validatePetData = true;
  static const bool enableDataEncryption = true;
  static const int maxNameLength = 30;
  static const int maxAchievements = 200;
  
  /// Get environment-specific database configuration
  static Map<String, dynamic> getDatabaseConfig() {
    return {
      'timeout': networkTimeout.inSeconds,
      'retries': maxRetryAttempts,
      'retry_delay': retryDelay.inSeconds,
      'compression_enabled': enableDataCompression,
      'offline_mode': enableOfflineMode,
      'encryption_enabled': enableDataEncryption,
    };
  }
  
  /// Get audio configuration
  static Map<String, dynamic> getAudioConfig() {
    return {
      'default_volume': defaultVolume,
      'max_sounds_per_minute': maxSoundsPerMinute,
      'cache_size': soundCacheSize,
      'supported_formats': supportedAudioFormats,
      'cooldown_seconds': petSoundCooldown.inSeconds,
    };
  }
  
  /// Get animation configuration
  static Map<String, dynamic> getAnimationConfig() {
    return {
      'default_duration_ms': defaultAnimationDuration.inMilliseconds,
      'movement_interval_ms': petMovementInterval.inMilliseconds,
      'max_frames': maxAnimationFrames,
      'particle_effects_enabled': enableParticleEffects,
      'max_concurrent_animations': maxConcurrentAnimations,
    };
  }
  
  /// Get game configuration
  static Map<String, dynamic> getGameConfig() {
    return {
      'max_mini_game_duration': maxMiniGameDuration,
      'max_daily_xp': maxDailyXP,
      'max_streak': maxStreak,
      'session_timeout_minutes': gameSessionTimeout.inMinutes,
      'max_pet_level': maxPetLevel,
      'xp_per_level': xpPerLevel,
    };
  }
  
  /// Get pet care configuration
  static Map<String, dynamic> getCareConfig() {
    return {
      'min_happiness': minHappiness,
      'max_happiness': maxHappiness,
      'default_happiness': defaultHappiness,
      'hunger_interval_hours': hungerInterval.inHours,
      'play_interval_hours': playInterval.inHours,
      'max_pets': maxPets,
      'max_accessories': maxAccessories,
    };
  }
  
  /// Get performance configuration
  static Map<String, dynamic> getPerformanceConfig() {
    return {
      'max_cache_size': maxCacheSize,
      'state_update_interval_ms': petStateUpdateInterval,
      'monitoring_enabled': enablePerformanceMonitoring,
      'network_timeout_seconds': networkTimeout.inSeconds,
    };
  }
  
  /// Validate production configuration
  static bool validateProductionConfig() {
    final checks = [
      isProduction == kReleaseMode,
      enableDebugLogging == !kReleaseMode,
      maxPets > 0,
      maxAccessories > 0,
      maxPetLevel > 0,
      xpPerLevel > 0,
      petSoundCooldown.inSeconds > 0,
      autoSaveInterval.inSeconds > 0,
      defaultVolume >= 0.0 && defaultVolume <= 1.0,
      minHappiness >= 0.0 && maxHappiness <= 1.0,
      maxCacheSize > 0,
      maxRetryAttempts > 0,
    ];
    
    return checks.every((check) => check);
  }
  
  /// Get configuration summary
  static Map<String, dynamic> getConfigSummary() {
    return {
      'version': version,
      'last_updated': lastUpdated,
      'is_production': isProduction,
      'debug_logging': enableDebugLogging,
      'performance_monitoring': enablePerformanceMonitoring,
      'max_pets': maxPets,
      'max_accessories': maxAccessories,
      'max_pet_level': maxPetLevel,
      'sound_cooldown_seconds': petSoundCooldown.inSeconds,
      'validation_passed': validateProductionConfig(),
    };
  }
}

/// Debug utility for pets system
class PetsDebugUtils {
  static void conditionalLog(String message, [Object? error]) {
    if (PetsProductionConfig.enableDebugLogging) {
      if (kDebugMode) {
        if (error != null) {
          debugPrint('Pets Debug: $message - Error: $error');
        } else {
          debugPrint('Pets Debug: $message');
        }
      }
    }
  }
  
  static void logError(String operation, Object error, [StackTrace? stackTrace]) {
    if (PetsProductionConfig.enableDebugLogging) {
      if (kDebugMode) {
        debugPrint('Pets Error in $operation: $error');
        if (stackTrace != null) {
          debugPrint('Stack trace: $stackTrace');
        }
      }
    }
  }
  
  static void logPerformance(String operation, Duration duration) {
    if (PetsProductionConfig.enablePerformanceMonitoring && kDebugMode) {
      debugPrint('Pets Performance: $operation took ${duration.inMilliseconds}ms');
    }
  }
  
  static void logAudio(String operation, String soundFile, bool success) {
    if (PetsProductionConfig.enableDebugLogging && kDebugMode) {
      debugPrint('Pets Audio: $operation for $soundFile - ${success ? 'SUCCESS' : 'FAILED'}');
    }
  }
  
  static void logAnimation(String operation, String petId, String animationType) {
    if (PetsProductionConfig.enableDebugLogging && kDebugMode) {
      debugPrint('Pets Animation: $operation for pet $petId ($animationType)');
    }
  }
  
  static void logGameEvent(String event, String petId, Map<String, dynamic> data) {
    if (PetsProductionConfig.enableDebugLogging && kDebugMode) {
      debugPrint('Pets Game: $event for pet $petId - Data: $data');
    }
  }
}
