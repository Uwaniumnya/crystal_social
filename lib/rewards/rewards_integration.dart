import 'package:flutter/material.dart';

/// Rewards System Integration
/// 
/// This file exports all the necessary components for the rewards system
/// and provides a unified interface for the rest of the application.

// Core services
export 'rewards_service.dart';
export 'rewards_manager.dart';
export 'aura_service.dart';

// UI Components  
export 'rewards_provider.dart';
export 'unified_rewards_screen.dart';

// Individual screens
export 'shop_screen.dart';
export 'inventory_screen.dart';
export 'reward_archivement.dart';

// Special features
export 'bestie_bond.dart';
export 'booster.dart';

// Sync utilities
export 'shop_item_sync.dart';

/// How to use the integrated rewards system:
/// 
/// 1. Wrap your app or specific sections with RewardsProvider:
/// ```dart
/// RewardsProvider(
///   userId: currentUserId,
///   child: YourWidget(),
/// )
/// ```
/// 
/// 2. Use the UnifiedRewardsScreen as the main rewards interface:
/// ```dart
/// UnifiedRewardsScreen(userId: currentUserId)
/// ```
/// 
/// 3. Access rewards data from any widget using context extensions:
/// ```dart
/// final rewards = context.rewards;
/// final userCoins = rewards.userRewards['coins'];
/// ```
/// 
/// 4. Use pre-built widgets for common functionality:
/// ```dart
/// CoinBalanceWidget()
/// LevelProgressWidget()
/// ```
/// 
/// 5. Implement the RewardsMixin in your stateful widgets for easy integration:
/// ```dart
/// class MyWidget extends StatefulWidget {}
/// 
/// class _MyWidgetState extends State<MyWidget> with RewardsMixin {
///   void purchaseItem(Map<String, dynamic> item) async {
///     final success = await rewardsService.purchaseItem(item, context);
///     if (success) {
///       showPurchaseSuccess(item['name']);
///     }
///   }
/// }
/// ```

/// Constants for the rewards system
class RewardsConstants {
  // Categories
  static const int CATEGORY_AURA = 1;
  static const int CATEGORY_BACKGROUND = 2;
  static const int CATEGORY_PET = 3;
  static const int CATEGORY_PET_ACCESSORY = 4;
  static const int CATEGORY_FURNITURE = 5;
  static const int CATEGORY_TAROT = 6;
  static const int CATEGORY_BOOSTER = 7;
  static const int CATEGORY_DECORATION = 8;
  
  // Rarity levels
  static const String RARITY_COMMON = 'common';
  static const String RARITY_UNCOMMON = 'uncommon';
  static const String RARITY_RARE = 'rare';
  static const String RARITY_EPIC = 'epic';
  static const String RARITY_LEGENDARY = 'legendary';
  
  // Achievement types
  static const String ACHIEVEMENT_SOCIAL = 'Social';
  static const String ACHIEVEMENT_GAMING = 'Gaming';
  static const String ACHIEVEMENT_COLLECTING = 'Collecting';
  static const String ACHIEVEMENT_PROGRESS = 'Progress';
  static const String ACHIEVEMENT_SPECIAL = 'Special';
  
  // Transaction sources
  static const String SOURCE_SHOP = 'shop';
  static const String SOURCE_ACHIEVEMENT = 'achievement';
  static const String SOURCE_DAILY_LOGIN = 'daily_login';
  static const String SOURCE_BOOSTER_PACK = 'booster_pack';
  static const String SOURCE_PURCHASE_BONUS = 'purchase_bonus';
}

/// Helper functions for the rewards system
class RewardsHelper {
  /// Get color for rarity level
  static Color getRarityColor(String rarity) {
    switch (rarity.toLowerCase()) {
      case RewardsConstants.RARITY_COMMON:
        return const Color(0xFF9E9E9E); // Grey
      case RewardsConstants.RARITY_UNCOMMON:
        return const Color(0xFF4CAF50); // Green
      case RewardsConstants.RARITY_RARE:
        return const Color(0xFF2196F3); // Blue
      case RewardsConstants.RARITY_EPIC:
        return const Color(0xFF9C27B0); // Purple
      case RewardsConstants.RARITY_LEGENDARY:
        return const Color(0xFFFF9800); // Orange
      default:
        return const Color(0xFF9E9E9E);
    }
  }
  
  /// Get icon for category
  static IconData getCategoryIcon(int categoryId) {
    switch (categoryId) {
      case RewardsConstants.CATEGORY_AURA:
        return Icons.auto_awesome;
      case RewardsConstants.CATEGORY_BACKGROUND:
        return Icons.wallpaper;
      case RewardsConstants.CATEGORY_PET:
        return Icons.pets;
      case RewardsConstants.CATEGORY_PET_ACCESSORY:
        return Icons.inventory;
      case RewardsConstants.CATEGORY_FURNITURE:
        return Icons.chair;
      case RewardsConstants.CATEGORY_TAROT:
        return Icons.style;
      case RewardsConstants.CATEGORY_BOOSTER:
        return Icons.card_giftcard;
      case RewardsConstants.CATEGORY_DECORATION:
        return Icons.star;
      default:
        return Icons.inventory;
    }
  }
  
  /// Get name for category
  static String getCategoryName(int categoryId) {
    switch (categoryId) {
      case RewardsConstants.CATEGORY_AURA:
        return 'Auras';
      case RewardsConstants.CATEGORY_BACKGROUND:
        return 'Backgrounds';
      case RewardsConstants.CATEGORY_PET:
        return 'Pets';
      case RewardsConstants.CATEGORY_PET_ACCESSORY:
        return 'Pet Accessories';
      case RewardsConstants.CATEGORY_FURNITURE:
        return 'Furniture';
      case RewardsConstants.CATEGORY_TAROT:
        return 'Tarot Decks';
      case RewardsConstants.CATEGORY_BOOSTER:
        return 'Booster Packs';
      case RewardsConstants.CATEGORY_DECORATION:
        return 'Decorations';
      default:
        return 'Unknown';
    }
  }
  
  /// Format currency display
  static String formatCurrency(int amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return amount.toString();
    }
  }
  
  /// Calculate level from points
  static int calculateLevel(int points) {
    return (points / 1000).floor() + 1;
  }
  
  /// Calculate points needed for next level
  static int pointsForNextLevel(int currentLevel) {
    return currentLevel * 1000;
  }
  
  /// Calculate progress towards next level
  static double calculateLevelProgress(int points, int currentLevel) {
    final pointsInCurrentLevel = points % 1000;
    return pointsInCurrentLevel / 1000.0;
  }
}
