// File: gems_production_config.dart
// Production configuration and constants for the gems system

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

/// Production configuration for gems system
class GemsProductionConfig {
  // Environment settings
  static const bool isProduction = kReleaseMode;
  static const bool enableDebugLogging = !kReleaseMode;
  static const bool enablePerformanceMonitoring = true;
  
  // Gem collection limits and constraints
  static const int maxGemsPerUser = 500;
  static const int maxGemUnlocksPerDay = 20;
  static const int maxFavoriteGems = 50;
  static const int maxGemHistory = 1000;
  static const int maxGemsInMemory = 200;
  
  // Discovery and unlock configuration
  static const Duration gemDiscoveryTimeout = Duration(seconds: 30);
  static const Duration gemUnlockAnimation = Duration(milliseconds: 2000);
  static const Duration gemCacheTimeout = Duration(hours: 4);
  static const Duration statsUpdateInterval = Duration(minutes: 5);
  
  // Gem features settings
  static const bool enableGemUnlocking = true;
  static const bool enableGemFavorites = true;
  static const bool enableGemSharing = true;
  static const bool enableGemAnimations = true;
  static const bool enableGemNotifications = true;
  static const bool enableGemAnalytics = true;
  static const bool enableShinyVariants = true;
  
  // Unlock mechanics
  static const bool enableLocationBasedGems = true;
  static const bool enableTimeBasedGems = true;
  static const bool enableActivityBasedGems = true;
  static const bool enableSocialGems = true;
  
  // Performance optimization
  static const Duration connectionRetryDelay = Duration(seconds: 2);
  static const int maxConnectionRetries = 3;
  static const Duration operationTimeout = Duration(seconds: 15);
  static const Duration cacheRefreshInterval = Duration(minutes: 30);
  
  // Rarity and drop rates
  static const Map<String, double> rarityDropRates = {
    'common': 0.60,      // 60% chance
    'uncommon': 0.25,    // 25% chance
    'rare': 0.10,        // 10% chance
    'epic': 0.04,        // 4% chance
    'legendary': 0.01,   // 1% chance
  };
  
  // Gem value system
  static const Map<String, int> rarityValues = {
    'common': 10,
    'uncommon': 25,
    'rare': 50,
    'epic': 100,
    'legendary': 250,
  };
  
  // Animation and UI settings
  static const bool enableGemSparkles = true;
  static const bool enableGemGlow = true;
  static const bool enableGemRotation = true;
  static const bool enableGemPulse = true;
  static const Duration sparkleInterval = Duration(milliseconds: 500);
  static const Duration glowCycle = Duration(seconds: 3);
  
  // Auto-collection settings
  static const bool enableAutoCollection = false;  // Premium feature
  static const Duration autoCollectionInterval = Duration(hours: 1);
  static const int maxAutoCollectionGems = 5;
  
  // Security and anti-cheat
  static const bool enableUnlockValidation = true;
  static const bool enableRateLimiting = true;
  static const Duration unlockCooldown = Duration(seconds: 5);
  static const int maxUnlocksPerMinute = 10;
  
  // Backup and sync settings
  static const bool enableCloudSync = true;
  static const bool enableLocalBackup = true;
  static const Duration syncInterval = Duration(minutes: 10);
  static const int maxSyncRetries = 3;
}

/// Production-safe debug utilities for gems system
class GemsDebugUtils {
  static void log(String component, String message) {
    if (GemsProductionConfig.enableDebugLogging) {
      debugPrint('💎 Gems[$component]: $message');
    }
  }
  
  static void logError(String component, String error) {
    if (GemsProductionConfig.enableDebugLogging) {
      debugPrint('🔴 Gems[$component] ERROR: $error');
    }
    // In production, you might want to send to crash reporting service
    // CrashReporting.recordError('Gems[$component]', error);
  }
  
  static void logWarning(String component, String warning) {
    if (GemsProductionConfig.enableDebugLogging) {
      debugPrint('🟡 Gems[$component] WARNING: $warning');
    }
  }
  
  static void logSuccess(String component, String message) {
    if (GemsProductionConfig.enableDebugLogging) {
      debugPrint('🟢 Gems[$component] SUCCESS: $message');
    }
  }
  
  static void logPerformance(String component, String operation, Duration duration) {
    if (GemsProductionConfig.enablePerformanceMonitoring) {
      debugPrint('⚡ Gems[$component] PERF: $operation took ${duration.inMilliseconds}ms');
    }
  }
  
  static void logUnlock(String component, String gemName, String rarity) {
    if (GemsProductionConfig.enableDebugLogging) {
      debugPrint('✨ Gems[$component] UNLOCK: $gemName ($rarity) unlocked!');
    }
  }
}

/// Error handling utilities for gems system
class GemsErrorHandler {
  static void handleError(String context, dynamic error) {
    GemsDebugUtils.logError(context, error.toString());
    
    // Handle different types of errors
    if (error is PostgrestException) {
      _handleSupabaseError(context, error);
    } else if (error is TimeoutException) {
      _handleTimeoutError(context, error);
    } else {
      _handleGenericError(context, error);
    }
  }
  
  static void _handleSupabaseError(String context, PostgrestException error) {
    final code = error.code;
    switch (code) {
      case '401':
        GemsDebugUtils.logWarning(context, 'Authentication error');
        break;
      case '403':
        GemsDebugUtils.logWarning(context, 'Permission denied for $context');
        break;
      case '500':
        GemsDebugUtils.logWarning(context, 'Server error in $context');
        break;
      default:
        GemsDebugUtils.logWarning(context, 'Database error: ${error.message}');
    }
  }
  
  static void _handleTimeoutError(String context, TimeoutException error) {
    GemsDebugUtils.logWarning(context, 'Operation timed out');
  }
  
  static void _handleGenericError(String context, dynamic error) {
    GemsDebugUtils.logWarning(context, 'Unexpected error: $error');
  }
}

/// Production configuration validator
class GemsConfigValidator {
  static bool validateConfiguration() {
    try {
      // Validate rarity drop rates sum to approximately 1.0
      final totalDropRate = GemsProductionConfig.rarityDropRates.values
          .fold(0.0, (sum, rate) => sum + rate);
      
      if ((totalDropRate - 1.0).abs() > 0.01) {
        GemsDebugUtils.logWarning('ConfigValidator', 
            'Drop rates sum to $totalDropRate, expected ~1.0');
        return false;
      }
      
      // Validate reasonable limits
      if (GemsProductionConfig.maxGemsPerUser <= 0 ||
          GemsProductionConfig.maxGemUnlocksPerDay <= 0) {
        GemsDebugUtils.logWarning('ConfigValidator', 'Invalid gem limits');
        return false;
      }
      
      GemsDebugUtils.logSuccess('ConfigValidator', 'Configuration validation passed');
      return true;
    } catch (e) {
      GemsDebugUtils.logError('ConfigValidator', 'Validation failed: $e');
      return false;
    }
  }
}
