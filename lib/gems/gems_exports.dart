// Crystal Social Gems System - Production Export Management
// Centralized exports for all gems-related functionality

// Core gems system
export 'gem_service.dart';
export 'gem_provider.dart';
export 'gemstone_model.dart';

// Gems screens and UI
export 'enhanced_gem_collection_screen.dart';
export 'enhanced_gem_discovery_screen.dart';
export 'gem_unlock.dart';
export 'shiny_gem_animation.dart';

// Integration and examples
export 'gems_integration.dart';


// Production infrastructure
export 'gems_production_config.dart';
export 'gems_performance_optimizer.dart';
export 'gems_validator.dart';

// Import required classes for the utility class
import 'gems_production_config.dart';
import 'gems_validator.dart';
import 'gems_performance_optimizer.dart';
import 'gem_service.dart';

// Gems utilities and models
class GemsSystemExports {
  // Production configuration
  static const String version = '1.0.0';
  static const String buildDate = '2025-07-27';
  
  // Feature flags for production
  static const bool enableGemUnlocking = true;
  static const bool enableGemFavorites = true;
  static const bool enableGemSharing = true;
  static const bool enableGemAnimations = true;
  static const bool enableGemNotifications = true;
  static const bool enableGemAnalytics = true;
  static const bool enableShinyVariants = true;
  static const bool enableLocationBasedGems = true;
  static const bool enableTimeBasedGems = true;
  static const bool enableActivityBasedGems = true;
  static const bool enableSocialGems = true;
  
  // Collection settings
  static const int maxGemsPerUser = 500;
  static const int maxFavoriteGems = 50;
  static const int maxGemUnlocksPerDay = 20;
  static const int maxGemsInMemory = 200;
  static const int gemHistoryRetentionDays = 365;
  
  // Performance settings
  static const Duration gemUnlockAnimation = Duration(milliseconds: 2000);
  static const Duration gemCacheTimeout = Duration(hours: 4);
  static const Duration gemDiscoveryTimeout = Duration(seconds: 30);
  static const Duration statsUpdateInterval = Duration(minutes: 5);
  
  // Rarity system
  static const Map<String, double> rarityDropRates = {
    'common': 0.60,      // 60% chance
    'uncommon': 0.25,    // 25% chance
    'rare': 0.10,        // 10% chance
    'epic': 0.04,        // 4% chance
    'legendary': 0.01,   // 1% chance
  };
  
  // Value system
  static const Map<String, int> rarityValues = {
    'common': 10,
    'uncommon': 25,
    'rare': 50,
    'epic': 100,
    'legendary': 250,
  };
  
  // Security settings
  static const bool enableUnlockValidation = true;
  static const bool enableRateLimiting = true;
  static const Duration unlockCooldown = Duration(seconds: 5);
  static const int maxUnlocksPerMinute = 10;
  
  // System health indicators
  static bool get isSystemHealthy {
    try {
      // Validate core gems components
      return GemsProductionConfig.isProduction &&
             GemsProductionConfig.enableGemUnlocking &&
             GemsProductionConfig.enableGemFavorites;
    } catch (e) {
      GemsDebugUtils.logError('GemsSystemExports', 'Health check failed: $e');
      return false;
    }
  }
  
  // Production readiness check
  static Future<bool> validateProductionReadiness() async {
    try {
      final result = await GemsValidator.validateProductionReadiness();
      return result['isValid'] ?? false;
    } catch (e) {
      GemsDebugUtils.logError('GemsSystemExports', 'Production validation failed: $e');
      return false;
    }
  }
  
  // Initialize gems system for production
  static Future<void> initializeForProduction() async {
    try {
      GemsDebugUtils.log('GemsSystemExports', 'Initializing gems system for production...');
      
      // Validate configuration
      final configValid = GemsConfigValidator.validateConfiguration();
      if (!configValid) {
        throw Exception('Gems configuration validation failed');
      }
      
      // Initialize performance optimizer
      final optimizer = GemsPerformanceOptimizer();
      optimizer.initialize();
      
      // Validate system readiness
      final isReady = await validateProductionReadiness();
      if (!isReady) {
        throw Exception('Gems system not ready for production');
      }
      
      GemsDebugUtils.logSuccess('GemsSystemExports', 'Gems system initialized successfully');
    } catch (e) {
      GemsDebugUtils.logError('GemsSystemExports', 'Failed to initialize gems system: $e');
      rethrow;
    }
  }
  
  // Quick health check
  static Future<bool> quickHealthCheck() async {
    try {
      return await GemsValidator.quickHealthCheck();
    } catch (e) {
      GemsDebugUtils.logError('GemsSystemExports', 'Health check failed: $e');
      return false;
    }
  }
  
  // Get gem statistics
  static Future<Map<String, dynamic>> getGemStatistics(String userId) async {
    try {
      final gemService = GemService();
      await gemService.initialize(userId);
      
      final allGems = gemService.allGems;
      final userGems = gemService.userGems;
      
      final rarityCount = <String, int>{};
      final userRarityCount = <String, int>{};
      
      // Count total gems by rarity
      for (final gem in allGems) {
        rarityCount[gem.rarity.toString()] = (rarityCount[gem.rarity.toString()] ?? 0) + 1;
      }
      
      // Count user gems by rarity
      for (final gem in userGems) {
        userRarityCount[gem.rarity.toString()] = (userRarityCount[gem.rarity.toString()] ?? 0) + 1;
      }
      
      return {
        'totalGems': allGems.length,
        'userGems': userGems.length,
        'collectionProgress': userGems.length / allGems.length,
        'rarityDistribution': rarityCount,
        'userRarityDistribution': userRarityCount,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      GemsDebugUtils.logError('GemsSystemExports', 'Failed to get gem statistics: $e');
      return {};
    }
  }
  
  // System diagnostics
  static Map<String, dynamic> getDiagnostics() {
    return {
      'version': version,
      'buildDate': buildDate,
      'isProduction': GemsProductionConfig.isProduction,
      'featuresEnabled': {
        'gemUnlocking': enableGemUnlocking,
        'gemFavorites': enableGemFavorites,
        'gemSharing': enableGemSharing,
        'gemAnimations': enableGemAnimations,
        'gemNotifications': enableGemNotifications,
        'gemAnalytics': enableGemAnalytics,
        'shinyVariants': enableShinyVariants,
        'locationBasedGems': enableLocationBasedGems,
        'timeBasedGems': enableTimeBasedGems,
        'activityBasedGems': enableActivityBasedGems,
        'socialGems': enableSocialGems,
      },
      'limits': {
        'maxGemsPerUser': maxGemsPerUser,
        'maxFavoriteGems': maxFavoriteGems,
        'maxGemUnlocksPerDay': maxGemUnlocksPerDay,
        'maxGemsInMemory': maxGemsInMemory,
        'gemHistoryRetentionDays': gemHistoryRetentionDays,
      },
      'raritySystem': {
        'dropRates': rarityDropRates,
        'values': rarityValues,
      },
      'security': {
        'unlockValidation': enableUnlockValidation,
        'rateLimiting': enableRateLimiting,
        'unlockCooldownSeconds': unlockCooldown.inSeconds,
        'maxUnlocksPerMinute': maxUnlocksPerMinute,
      },
      'performance': {
        'unlockAnimationMs': gemUnlockAnimation.inMilliseconds,
        'cacheTimeoutHours': gemCacheTimeout.inHours,
        'discoveryTimeoutSeconds': gemDiscoveryTimeout.inSeconds,
        'statsUpdateMinutes': statsUpdateInterval.inMinutes,
      },
      'health': isSystemHealthy,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
