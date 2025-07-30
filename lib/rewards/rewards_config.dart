import 'rewards_production_config.dart';

/// Rewards System Configuration
/// Centralized configuration for the unified rewards system
/// Now uses production configuration for optimal performance and security
class RewardsConfig {
  
  // Use production configuration as the source of truth
  static int get messageAchievementThreshold => RewardsProductionConfig.messageAchievementThreshold;
  static int get loginStreakThreshold => RewardsProductionConfig.loginStreakThreshold;
  static int get spendingThreshold => RewardsProductionConfig.spendingThreshold;
  
  // Currency settings from production config
  static int get dailyLoginBonus => RewardsProductionConfig.dailyLoginBonus;
  static int get messageReward => RewardsProductionConfig.messageReward;
  static int get levelUpBonus => RewardsProductionConfig.levelUpBonus;
  
  // Cache settings from production config
  static Duration get cacheExpiration => RewardsProductionConfig.cacheExpiration;
  static int get maxCacheSize => RewardsProductionConfig.maxCacheSize;
  
  // Shop settings from production config
  static int get maxItemsPerPage => RewardsProductionConfig.maxItemsPerPage;
  static bool get validateAssetsByDefault => RewardsProductionConfig.validateAssetsByDefault;
  
  // System settings from production config
  static Duration get initializationTimeout => RewardsProductionConfig.initializationTimeout;
  static bool get enableDebugLogging => RewardsProductionConfig.enableDebugLogging;
  static bool get autoSyncOnInitialization => RewardsProductionConfig.autoSyncOnInitialization;
  
  // Activity rewards from production config
  static Map<String, int> get activityRewards => RewardsProductionConfig.activityRewards;
  
  // Level requirements from production config
  static Map<int, int> get levelRequirements => RewardsProductionConfig.levelRequirements;
  
  // Shop categories from production config
  static Map<int, String> get shopCategories => RewardsProductionConfig.shopCategories;
  
  // Error messages from production config
  static Map<String, String> get errorMessages => RewardsProductionConfig.errorMessages;
  
  // Success messages from production config
  static Map<String, String> get successMessages => RewardsProductionConfig.successMessages;
}

/// Event types for the rewards system
enum RewardsEventType {
  coinEarned,
  pointEarned,
  itemPurchased,
  achievementUnlocked,
  levelUp,
  auraEquipped,
  dailyLogin,
  messageReward,
  activityReward,
}

/// Achievement categories
enum AchievementCategory {
  social,
  financial,
  collection,
  activity,
  milestone,
  special,
}

/// Item rarities with associated benefits
enum ItemRarity {
  common('Common', 1.0),
  uncommon('Uncommon', 1.2),
  rare('Rare', 1.5),
  epic('Epic', 2.0),
  legendary('Legendary', 3.0),
  mythic('Mythic', 5.0);

  const ItemRarity(this.displayName, this.multiplier);
  final String displayName;
  final double multiplier;
}

/// Currency types in the rewards system
enum CurrencyType {
  coins('Coins', '💰'),
  points('Points', '⭐'),
  gems('Gems', '💎'),
  experience('Experience', '🎯');

  const CurrencyType(this.displayName, this.icon);
  final String displayName;
  final String icon;
}
