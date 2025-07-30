import 'package:flutter/foundation.dart';

/// Rewards Production Configuration
/// Production-optimized settings for the Crystal Social rewards system
/// Handles performance, security, and environment-specific configurations
class RewardsProductionConfig {
  
  // ============================================================================
  // PRODUCTION ENVIRONMENT SETTINGS
  // ============================================================================
  
  /// Whether we're running in production mode
  static const bool isProduction = kReleaseMode;
  
  /// Enable debug logging only in debug builds
  static const bool enableDebugLogging = kDebugMode;
  
  /// Enable verbose logging for troubleshooting
  static const bool enableVerboseLogging = false;
  
  /// Enable performance monitoring
  static const bool enablePerformanceMonitoring = true;
  
  // ============================================================================
  // REWARD SYSTEM CONFIGURATION
  // ============================================================================
  
  /// Achievement thresholds (production-balanced)
  static const int messageAchievementThreshold = 100;
  static const int loginStreakThreshold = 7;
  static const int spendingThreshold = 1000;
  static const int socialAchievementThreshold = 50;
  
  /// Currency settings (production-balanced)
  static const int dailyLoginBonus = 50;
  static const int messageReward = 5;
  static const int levelUpBonus = 100;
  static const int postCreationReward = 10;
  static const int commentReward = 5;
  static const int likeReward = 1;
  static const int achievementBonus = 50;
  
  // ============================================================================
  // PERFORMANCE OPTIMIZATION
  // ============================================================================
  
  /// Cache settings for optimal performance
  static const Duration cacheExpiration = Duration(minutes: 30); // Extended for production
  static const int maxCacheSize = 2000; // Increased for production
  static const Duration inventoryCacheTimeout = Duration(minutes: 15);
  static const Duration shopCacheTimeout = Duration(hours: 1);
  
  /// Database operation settings
  static const int maxBatchSize = 100;
  static const Duration transactionTimeout = Duration(seconds: 30);
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  
  // ============================================================================
  // SHOP AND INVENTORY SETTINGS
  // ============================================================================
  
  /// Shop configuration
  static const int maxItemsPerPage = 50;
  static const bool validateAssetsByDefault = true; // Enabled in production
  static const bool preloadShopItems = true;
  static const Duration shopSyncInterval = Duration(hours: 6);
  
  /// Inventory management
  static const int maxInventorySize = 1000;
  static const bool enableInventoryOptimization = true;
  static const Duration inventoryCleanupInterval = Duration(days: 1);
  
  // ============================================================================
  // SYSTEM SETTINGS
  // ============================================================================
  
  /// Initialization settings
  static const Duration initializationTimeout = Duration(seconds: 45);
  static const bool autoSyncOnInitialization = true; // Enabled in production
  static const bool enableHealthChecks = true;
  static const Duration healthCheckInterval = Duration(minutes: 10);
  
  /// Security settings
  static const bool validatePurchases = true;
  static const bool enableTransactionLogging = true;
  static const bool enableAuditTrail = true;
  static const int maxPurchaseRetries = 2;
  
  // ============================================================================
  // ACTIVITY REWARDS (PRODUCTION-BALANCED)
  // ============================================================================
  
  /// Activity reward amounts
  static const Map<String, int> activityRewards = {
    'message_sent': 2,
    'post_created': 10,
    'comment_added': 5,
    'like_given': 1,
    'achievement_unlocked': 50,
    'daily_login': 20,
    'friend_added': 15,
    'profile_complete': 25,
    'first_purchase': 100,
    'level_milestone': 200,
  };
  
  /// Daily limits to prevent abuse
  static const Map<String, int> dailyActivityLimits = {
    'message_sent': 100, // Max 200 coins from messages per day
    'post_created': 5,   // Max 50 coins from posts per day
    'comment_added': 20, // Max 100 coins from comments per day
    'like_given': 50,    // Max 50 coins from likes per day
  };
  
  // ============================================================================
  // LEVEL SYSTEM (PRODUCTION-BALANCED)
  // ============================================================================
  
  /// Level requirements (experience needed for each level)
  static const Map<int, int> levelRequirements = {
    1: 0,
    2: 100,
    3: 250,
    4: 500,
    5: 1000,
    6: 2000,
    7: 4000,
    8: 8000,
    9: 16000,
    10: 32000,
    11: 50000,
    12: 75000,
    13: 100000,
    14: 150000,
    15: 200000,
  };
  
  /// Level up bonuses
  static const Map<int, int> levelUpBonuses = {
    2: 50,   // Level 2
    3: 75,   // Level 3
    4: 100,  // Level 4
    5: 150,  // Level 5
    10: 500, // Level 10 milestone
    15: 1000, // Level 15 milestone
  };
  
  // ============================================================================
  // SHOP CATEGORIES
  // ============================================================================
  
  /// Shop categories with proper ordering
  static const Map<int, String> shopCategories = {
    1: 'Avatar Decorations',
    2: 'Auras',
    3: 'Pets',
    4: 'Pet Accessories',
    5: 'Furniture',
    6: 'Tarot Decks',
    7: 'Booster Packs',
    8: 'Special Items',
    9: 'Limited Edition',
  };
  
  /// Category priority for loading
  static const List<int> categoryLoadPriority = [2, 1, 3, 4, 5, 6, 7, 8, 9];
  
  // ============================================================================
  // ERROR HANDLING
  // ============================================================================
  
  /// Production-safe error messages
  static const Map<String, String> errorMessages = {
    'insufficient_funds': 'Not enough coins to complete this purchase',
    'item_not_found': 'The requested item could not be found',
    'already_owned': 'You already own this item',
    'level_requirement': 'You do not meet the level requirement for this item',
    'initialization_failed': 'Failed to initialize rewards system',
    'user_not_found': 'User profile could not be found',
    'network_error': 'Network connection error. Please try again.',
    'server_error': 'Server temporarily unavailable. Please try again later.',
    'purchase_failed': 'Purchase could not be completed. Please try again.',
    'daily_limit_reached': 'Daily activity limit reached for this action.',
  };
  
  /// Success messages
  static const Map<String, String> successMessages = {
    'purchase_complete': 'Purchase completed successfully!',
    'achievement_unlocked': 'Achievement unlocked!',
    'level_up': 'Congratulations! You leveled up!',
    'aura_equipped': 'Aura equipped successfully!',
    'daily_bonus': 'Daily login bonus received!',
    'rewards_synced': 'Rewards synchronized successfully!',
    'inventory_updated': 'Inventory updated!',
  };
  
  // ============================================================================
  // FEATURE FLAGS
  // ============================================================================
  
  /// Production feature toggles
  static const Map<String, bool> featureFlags = {
    'enable_achievements': true,
    'enable_daily_rewards': true,
    'enable_level_system': true,
    'enable_shop': true,
    'enable_aura_system': true,
    'enable_inventory': true,
    'enable_activity_tracking': true,
    'enable_purchase_validation': true,
    'enable_transaction_history': true,
    'enable_performance_monitoring': true,
    'enable_caching': true,
    'enable_batch_processing': true,
    'enable_auto_sync': true,
    'enable_error_reporting': true,
  };
  
  // ============================================================================
  // RATE LIMITING
  // ============================================================================
  
  /// Rate limiting to prevent abuse
  static const Map<String, int> rateLimits = {
    'purchases_per_minute': 5,
    'rewards_claims_per_minute': 10,
    'shop_refreshes_per_hour': 20,
    'inventory_updates_per_minute': 15,
  };
  
  // ============================================================================
  // PRODUCTION VALIDATION
  // ============================================================================
  
  /// Validate production configuration
  static bool validateProductionConfig() {
    // Ensure critical features are enabled
    if (!featureFlags['enable_shop']! || !featureFlags['enable_inventory']!) {
      if (kDebugMode) {
        debugPrint('⚠️ Critical rewards features disabled in production config');
      }
      return false;
    }
    
    // Validate timeout settings are reasonable
    if (initializationTimeout.inSeconds < 10 || transactionTimeout.inSeconds < 5) {
      if (kDebugMode) {
        debugPrint('⚠️ Timeout settings too aggressive for production');
      }
      return false;
    }
    
    // Validate cache settings
    if (maxCacheSize < 100 || cacheExpiration.inMinutes < 5) {
      if (kDebugMode) {
        debugPrint('⚠️ Cache settings too restrictive for production');
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
        'initialization': initializationTimeout.inMilliseconds,
        'transaction': transactionTimeout.inMilliseconds,
        'cache_expiration': cacheExpiration.inMilliseconds,
      },
      'limits': {
        'max_cache_size': maxCacheSize,
        'max_batch_size': maxBatchSize,
        'max_retry_attempts': maxRetryAttempts,
      },
      'shop_config': {
        'max_items_per_page': maxItemsPerPage,
        'validate_assets': validateAssetsByDefault,
        'preload_items': preloadShopItems,
      },
    };
  }
  
  /// Check if feature is enabled
  static bool isFeatureEnabled(String feature) {
    return featureFlags[feature] ?? false;
  }
  
  /// Get activity reward amount with daily limit check
  static int getActivityReward(String activity, int dailyCount) {
    final baseReward = activityRewards[activity] ?? 0;
    final dailyLimit = dailyActivityLimits[activity];
    
    if (dailyLimit != null && dailyCount >= dailyLimit) {
      return 0; // Daily limit reached
    }
    
    return baseReward;
  }
  
  /// Get level up bonus for specific level
  static int getLevelUpBonus(int level) {
    return levelUpBonuses[level] ?? levelUpBonus;
  }
  
  /// Get production-optimized rewards configuration
  static Map<String, dynamic> getRewardsConfig() {
    return {
      'currency_settings': {
        'daily_login_bonus': dailyLoginBonus,
        'message_reward': messageReward,
        'level_up_bonus': levelUpBonus,
      },
      'achievement_thresholds': {
        'message_threshold': messageAchievementThreshold,
        'login_streak': loginStreakThreshold,
        'spending_threshold': spendingThreshold,
      },
      'performance_settings': {
        'cache_expiration': cacheExpiration.inMilliseconds,
        'max_cache_size': maxCacheSize,
        'batch_size': maxBatchSize,
      },
      'shop_settings': {
        'max_items_per_page': maxItemsPerPage,
        'validate_assets': validateAssetsByDefault,
        'sync_interval': shopSyncInterval.inMilliseconds,
      },
      'security_settings': {
        'validate_purchases': validatePurchases,
        'enable_audit_trail': enableAuditTrail,
        'max_purchase_retries': maxPurchaseRetries,
      },
    };
  }
}
