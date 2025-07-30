// File: butterfly_production_config.dart
// Production configuration and constants for the butterfly garden system

import 'package:flutter/foundation.dart';

/// Production configuration for butterfly garden system
class ButterflyProductionConfig {
  // Environment settings
  static const bool isProduction = kReleaseMode;
  static const bool enableDebugLogging = !kReleaseMode;
  static const bool enablePerformanceMonitoring = true;
  
  // Butterfly collection limits and constraints
  static const int maxButterflyCollection = 90;
  static const int maxFavorites = 30;
  static const int maxDailyDiscoveries = 5;
  static const int maxSearchResults = 50;
  
  // Collection and discovery settings
  static const Duration discoveryAnimation = Duration(milliseconds: 800);
  static const Duration shakeAnimationDuration = Duration(milliseconds: 500);
  static const Duration sparkleAnimationDuration = Duration(seconds: 3);
  static const Duration interactionCooldown = Duration(seconds: 1);
  
  // Butterfly features settings
  static const bool enableAudioEffects = true;
  static const bool enableShakeAnimations = true;
  static const bool enableSparkleEffects = true;
  static const bool enableRarityFilters = true;
  static const bool enableFavoriteSystem = true;
  static const bool enableSearchSystem = true;
  static const bool enableDailyRewards = true;
  static const bool enableCollectionStats = true;
  
  // Rarity distribution for discovery (balanced for game economy)
  static const Map<String, double> butterflyRarityRates = {
    'common': 0.45,      // 45% chance
    'uncommon': 0.25,    // 25% chance
    'rare': 0.15,        // 15% chance
    'epic': 0.10,        // 10% chance
    'legendary': 0.04,   // 4% chance
    'mythical': 0.01,    // 1% chance
  };
  
  // Audio settings
  static const bool enableBackgroundMusic = true;
  static const bool enableEffectSounds = true;
  static const double defaultVolume = 0.7;
  static const int maxAudioRetries = 3;
  
  // Performance optimization settings
  static const int imageCacheSize = 100;
  static const Duration cacheExpiration = Duration(hours: 2);
  static const bool enableImagePrecaching = true;
  static const bool enableMemoryOptimization = true;
  
  // Animation settings
  static const int minShakeInterval = 2; // seconds
  static const int maxShakeInterval = 7; // seconds
  static const double shakeAmplitude = 2.0;
  
  // UI settings
  static const int gridCrossAxisCount = 3;
  static const double gridChildAspectRatio = 0.85;
  static const double cardBorderRadius = 20.0;
  static const double jarImageHeight = 100.0;
  static const double butterflyImageSize = 35.0;
  
  // Search and filter settings
  static const int maxSearchQueryLength = 50;
  static const Duration searchDebounceDelay = Duration(milliseconds: 300);
  static const bool enableCaseSensitiveSearch = false;
  
  // Daily reward settings
  static const int dailyDiscoveryLimit = 3;
  static const Duration dailyResetInterval = Duration(days: 1);
  
  // Security and validation
  static const bool enableInputValidation = true;
  static const bool enableRateLimiting = true;
  static const bool enableDataIntegrityChecks = true;
  static const Duration actionCooldown = Duration(milliseconds: 500);
  
  // Collection progression rewards
  static const Map<int, Map<String, dynamic>> progressionRewards = {
    10: {'type': 'coins', 'amount': 100, 'message': 'First 10 butterflies! 🎉'},
    25: {'type': 'gems', 'amount': 5, 'message': 'Quarter collection complete! ✨'},
    50: {'type': 'coins', 'amount': 500, 'message': 'Halfway there! 🦋'},
    75: {'type': 'gems', 'amount': 10, 'message': 'Master collector! 👑'},
    90: {'type': 'special', 'amount': 1, 'message': 'Complete collection! 🌟'},
  };
  
  // Butterfly categories for organization
  static const List<String> butterflyCategories = [
    'Garden Dwellers',
    'Forest Friends', 
    'Magical Creatures',
    'Celestial Beings',
    'Mythical Legends'
  ];
  
  // Audio file paths
  static const Map<String, String> audioFiles = {
    'background': 'assets/butterfly/chimes.mp3',
    'epic': 'assets/butterfly/magical_chime.mp3',
    'legendary': 'assets/butterfly/legendary_bell.mp3',
    'mythical': 'assets/butterfly/mythical_sparkle.mp3',
    'discovery': 'assets/butterfly/discovery_sound.mp3',
    'favorite': 'assets/butterfly/favorite_chime.mp3',
  };
  
  // Image optimization settings
  static const Map<String, int> imageCacheSettings = {
    'cacheWidth': 70,
    'cacheHeight': 70,
    'jarCacheWidth': 200,
    'jarCacheHeight': 100,
  };
  
  // Validation helpers
  static bool isValidButterflyId(String id) {
    return id.isNotEmpty && id.length <= 10 && id.startsWith('b');
  }
  
  static bool isValidSearchQuery(String query) {
    return query.length <= maxSearchQueryLength;
  }
  
  static bool isValidFavoriteCount(int count) {
    return count <= maxFavorites;
  }
  
  static bool isValidDailyDiscoveries(int count) {
    return count <= maxDailyDiscoveries;
  }
}

/// Production-safe debug utilities for butterfly system
class ButterflyDebugUtils {
  static void log(String component, String message) {
    if (ButterflyProductionConfig.enableDebugLogging) {
      debugPrint('🦋 Butterfly[$component]: $message');
    }
  }
  
  static void logError(String component, String error) {
    if (ButterflyProductionConfig.enableDebugLogging) {
      debugPrint('🔴 Butterfly[$component] ERROR: $error');
    }
    // In production, you might want to send to crash reporting service
    // CrashReporting.recordError('Butterfly[$component]', error);
  }
  
  static void logWarning(String component, String warning) {
    if (ButterflyProductionConfig.enableDebugLogging) {
      debugPrint('🟡 Butterfly[$component] WARNING: $warning');
    }
  }
  
  static void logSuccess(String component, String message) {
    if (ButterflyProductionConfig.enableDebugLogging) {
      debugPrint('🟢 Butterfly[$component] SUCCESS: $message');
    }
  }
  
  static void logPerformance(String component, String operation, Duration duration) {
    if (ButterflyProductionConfig.enablePerformanceMonitoring) {
      debugPrint('⚡ Butterfly[$component] PERF: $operation took ${duration.inMilliseconds}ms');
    }
  }
  
  static void logDiscovery(String component, String butterflyName, String rarity) {
    if (ButterflyProductionConfig.enableDebugLogging) {
      debugPrint('✨ Butterfly[$component] DISCOVERY: $butterflyName ($rarity)');
    }
  }
  
  static void logAudio(String component, String audioType, String status) {
    if (ButterflyProductionConfig.enableDebugLogging) {
      debugPrint('🎵 Butterfly[$component] AUDIO: $audioType - $status');
    }
  }
  
  static void logUserAction(String component, String action, String targetId) {
    if (ButterflyProductionConfig.enableDebugLogging) {
      debugPrint('👆 Butterfly[$component] ACTION: $action on $targetId');
    }
  }
}

/// Error handling utilities for butterfly system
class ButterflyErrorHandler {
  static void handleDatabaseError(String context, dynamic error) {
    ButterflyDebugUtils.logError(context, 'Database error: $error');
    
    // Handle different types of database errors
    if (error.toString().contains('duplicate key')) {
      ButterflyDebugUtils.logWarning(context, 'Duplicate entry - already exists');
    } else if (error.toString().contains('foreign key')) {
      ButterflyDebugUtils.logWarning(context, 'Reference error - missing dependency');
    } else if (error.toString().contains('timeout')) {
      ButterflyDebugUtils.logWarning(context, 'Database timeout - network issue');
    } else {
      ButterflyDebugUtils.logWarning(context, 'Generic database error');
    }
  }
  
  static void handleAudioError(String context, dynamic error) {
    ButterflyDebugUtils.logError(context, 'Audio error: $error');
    
    // Handle different types of audio errors
    if (error.toString().contains('404') || error.toString().contains('not found')) {
      ButterflyDebugUtils.logWarning(context, 'Audio file not found - using fallback');
    } else if (error.toString().contains('permission')) {
      ButterflyDebugUtils.logWarning(context, 'Audio permission denied');
    } else if (error.toString().contains('codec')) {
      ButterflyDebugUtils.logWarning(context, 'Audio codec not supported');
    } else {
      ButterflyDebugUtils.logWarning(context, 'Generic audio error');
    }
  }
  
  static void handleImageError(String context, dynamic error) {
    ButterflyDebugUtils.logError(context, 'Image error: $error');
    
    // Handle different types of image errors
    if (error.toString().contains('404') || error.toString().contains('not found')) {
      ButterflyDebugUtils.logWarning(context, 'Image file not found - using fallback');
    } else if (error.toString().contains('format')) {
      ButterflyDebugUtils.logWarning(context, 'Image format not supported');
    } else {
      ButterflyDebugUtils.logWarning(context, 'Generic image error');
    }
  }
  
  static void handleAnimationError(String context, dynamic error) {
    ButterflyDebugUtils.logError(context, 'Animation error: $error');
    
    // Handle animation errors gracefully
    if (error is StateError) {
      ButterflyDebugUtils.logWarning(context, 'Animation state error - widget disposed?');
    } else {
      ButterflyDebugUtils.logWarning(context, 'Generic animation error');
    }
  }
  
  static void handleUIError(String context, dynamic error) {
    ButterflyDebugUtils.logError(context, 'UI error: $error');
    
    // Handle UI errors
    if (error is FlutterError) {
      ButterflyDebugUtils.logWarning(context, 'Flutter framework error');
    } else if (error is StateError) {
      ButterflyDebugUtils.logWarning(context, 'State error - widget disposed?');
    } else {
      ButterflyDebugUtils.logWarning(context, 'Generic UI error');
    }
  }
}

/// Production configuration validator for butterfly system
class ButterflyConfigValidator {
  static bool validateConfiguration() {
    try {
      // Validate butterfly rarity rates sum to approximately 1.0
      final totalRarityRate = ButterflyProductionConfig.butterflyRarityRates.values
          .fold(0.0, (sum, rate) => sum + rate);
      
      if ((totalRarityRate - 1.0).abs() > 0.01) {
        ButterflyDebugUtils.logWarning('ConfigValidator', 
            'Butterfly rarity rates sum to $totalRarityRate, expected ~1.0');
        return false;
      }
      
      // Validate reasonable limits
      final checks = {
        'maxButterflyCollection': ButterflyProductionConfig.maxButterflyCollection > 0,
        'maxFavorites': ButterflyProductionConfig.maxFavorites > 0,
        'maxDailyDiscoveries': ButterflyProductionConfig.maxDailyDiscoveries > 0,
        'maxSearchResults': ButterflyProductionConfig.maxSearchResults > 0,
      };
      
      for (final entry in checks.entries) {
        if (!entry.value) {
          ButterflyDebugUtils.logError('ConfigValidator', 
              'Invalid configuration: ${entry.key} must be > 0');
          return false;
        }
      }
      
      // Validate animation durations are reasonable
      final durations = [
        ButterflyProductionConfig.discoveryAnimation.inMilliseconds,
        ButterflyProductionConfig.shakeAnimationDuration.inMilliseconds,
        ButterflyProductionConfig.sparkleAnimationDuration.inMilliseconds,
      ];
      
      for (final duration in durations) {
        if (duration <= 0 || duration > 10000) { // Max 10 seconds
          ButterflyDebugUtils.logError('ConfigValidator', 
              'Invalid animation duration: ${duration}ms');
          return false;
        }
      }
      
      // Validate progression rewards
      if (ButterflyProductionConfig.progressionRewards.isEmpty) {
        ButterflyDebugUtils.logError('ConfigValidator', 'Progression rewards configuration is empty');
        return false;
      }
      
      // Validate audio files configuration
      if (ButterflyProductionConfig.audioFiles.isEmpty) {
        ButterflyDebugUtils.logError('ConfigValidator', 'Audio files configuration is empty');
        return false;
      }
      
      ButterflyDebugUtils.logSuccess('ConfigValidator', 'Configuration validation passed');
      return true;
    } catch (e) {
      ButterflyDebugUtils.logError('ConfigValidator', 'Validation failed: $e');
      return false;
    }
  }
  
  /// Validate butterfly data integrity
  static bool validateButterflyData(List<dynamic> butterflies) {
    try {
      if (butterflies.isEmpty) {
        ButterflyDebugUtils.logError('DataValidator', 'Butterfly list is empty');
        return false;
      }
      
      // Check for duplicate IDs
      final ids = <String>{};
      for (final butterfly in butterflies) {
        final id = butterfly.id as String;
        if (ids.contains(id)) {
          ButterflyDebugUtils.logError('DataValidator', 'Duplicate butterfly ID: $id');
          return false;
        }
        ids.add(id);
        
        // Validate ID format
        if (!ButterflyProductionConfig.isValidButterflyId(id)) {
          ButterflyDebugUtils.logError('DataValidator', 'Invalid butterfly ID format: $id');
          return false;
        }
      }
      
      ButterflyDebugUtils.logSuccess('DataValidator', 'Butterfly data validation passed');
      return true;
    } catch (e) {
      ButterflyDebugUtils.logError('DataValidator', 'Data validation failed: $e');
      return false;
    }
  }
}
