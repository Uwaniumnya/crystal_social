import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'rewards_service.dart';
import 'rewards_manager.dart';
import 'aura_service.dart';
import 'shop_item_sync.dart';
import 'dart:async';

/// Rewards Integration Helper
/// Provides easy-to-use methods for common rewards operations
/// Works seamlessly with existing rewards architecture
class RewardsIntegrationHelper {
  static RewardsIntegrationHelper? _instance;
  static RewardsIntegrationHelper get instance {
    _instance ??= RewardsIntegrationHelper._internal();
    return _instance!;
  }

  RewardsIntegrationHelper._internal();

  /// Complete purchase flow with context handling
  static Future<Map<String, dynamic>> completePurchaseFlow({
    required Map<String, dynamic> item,
    required String userId,
    required BuildContext context,
  }) async {
    try {
      debugPrint('🛒 Starting purchase flow for: ${item['name']}');
      
      // Get rewards manager instance with supabase
      final supabase = Supabase.instance.client;
      final rewardsManager = RewardsManager(supabase);
      
      // Execute purchase
      final result = await rewardsManager.purchaseItem(
        userId,
        item['id'] ?? 0,
        context,
      );

      if (result['success'] == true) {
        debugPrint('✅ Purchase successful: ${item['name']}');
        
        // Refresh rewards service data
        await RewardsService.instance.refresh();
        
        return {
          'success': true,
          'item': item,
          'message': 'Purchase completed successfully',
        };
      } else {
        return {
          'success': false,
          'error': result['error'] ?? 'Purchase failed',
          'code': 'PURCHASE_FAILED',
        };
      }
      
    } catch (e) {
      debugPrint('❌ Purchase error: $e');
      return {
        'success': false,
        'error': e.toString(),
        'code': 'PURCHASE_ERROR',
      };
    }
  }

  /// Enhanced aura management flow
  static Future<Map<String, dynamic>> manageAuraFlow({
    required String userId,
    required String auraColor,
    String action = 'equip', // 'equip' or 'unequip'
  }) async {
    try {
      debugPrint('✨ Managing aura: $auraColor for user: $userId');
      
      final supabase = Supabase.instance.client;
      final auraService = AuraService(supabase);
      
      if (action == 'equip') {
        await auraService.updateEquippedAura(userId, auraColor);
        
        return {
          'success': true,
          'aura_color': auraColor,
          'message': 'Aura equipped successfully',
        };
      } else {
        await auraService.updateEquippedAura(userId, '');
        
        return {
          'success': true,
          'message': 'Aura unequipped successfully',
        };
      }
      
    } catch (e) {
      debugPrint('❌ Aura management error: $e');
      return {
        'success': false,
        'error': e.toString(),
        'code': 'AURA_ERROR',
      };
    }
  }

  /// Get current equipped aura
  static Future<String?> getCurrentEquippedAura(String userId) async {
    try {
      final supabase = Supabase.instance.client;
      final auraService = AuraService(supabase);
      return await auraService.fetchEquippedAura(userId);
    } catch (e) {
      debugPrint('❌ Error fetching equipped aura: $e');
      return null;
    }
  }

  /// Comprehensive user status with all rewards data
  static Future<Map<String, dynamic>> getComprehensiveUserStatus(String userId) async {
    try {
      // Ensure rewards service is initialized
      final rewardsService = RewardsService.instance;
      if (!rewardsService.isInitialized) {
        await rewardsService.initialize(userId);
      }

      final userRewards = rewardsService.userRewards;
      final userStats = rewardsService.userStats;
      final inventory = rewardsService.userInventory;
      final achievements = rewardsService.achievements;

      // Get equipped aura
      final equippedAura = await getCurrentEquippedAura(userId);
      
      // Calculate statistics
      final totalItemsOwned = inventory.length;
      final achievementsUnlocked = achievements.where((a) => a['unlocked'] == true).length;
      final totalAchievements = achievements.length;
      
      return {
        'user_id': userId,
        'coins': userRewards['coins'] ?? 0,
        'points': userRewards['points'] ?? 0,
        'level': userRewards['level'] ?? 1,
        'experience': userRewards['experience'] ?? 0,
        'total_items_owned': totalItemsOwned,
        'achievements_unlocked': achievementsUnlocked,
        'total_achievements': totalAchievements,
        'achievement_percentage': totalAchievements > 0 ? (achievementsUnlocked / totalAchievements * 100).round() : 0,
        'equipped_aura': equippedAura,
        'user_stats': userStats,
        'last_updated': DateTime.now().toIso8601String(),
      };
      
    } catch (e) {
      debugPrint('❌ Error getting comprehensive user status: $e');
      return {'error': e.toString()};
    }
  }

  /// Initialize user rewards completely
  static Future<bool> initializeUserRewards(String userId) async {
    try {
      debugPrint('🎁 Initializing rewards for user: $userId');
      
      // Initialize rewards service
      final rewardsService = RewardsService.instance;
      await rewardsService.initialize(userId);
      
      // Verify initialization was successful
      if (rewardsService.isInitialized && !rewardsService.isLoading && rewardsService.error == null) {
        debugPrint('✅ User rewards initialized successfully');
        return true;
      } else {
        debugPrint('❌ Rewards initialization failed');
        return false;
      }
      
    } catch (e) {
      debugPrint('❌ Error initializing user rewards: $e');
      return false;
    }
  }

  /// Sync shop items to database
  static Future<Map<String, dynamic>> syncShopItemsToDatabase() async {
    try {
      debugPrint('🔄 Syncing shop items to database...');
      
      final supabase = Supabase.instance.client;
      final shopSync = ShopItemSyncService(supabase);
      final result = await shopSync.uploadAndSyncShopItems(
        forceUpdate: false,
        validateAssets: false,
      );
      
      debugPrint('✅ Shop sync completed');
      return {
        'success': true,
        'created': result.created.length,
        'updated': result.updated.length,
        'skipped': result.skipped.length,
        'errors': result.errors.length,
        'warnings': result.warnings.length,
      };
      
    } catch (e) {
      debugPrint('❌ Shop sync error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Refresh all user data
  static Future<void> refreshAllUserData() async {
    try {
      debugPrint('🔄 Refreshing all user data...');
      
      // Refresh rewards service
      await RewardsService.instance.refresh();
      
      debugPrint('✅ All user data refreshed');
      
    } catch (e) {
      debugPrint('❌ Error refreshing user data: $e');
      rethrow;
    }
  }

  /// Get system health status
  static Future<Map<String, dynamic>> getSystemHealth() async {
    try {
      final rewardsService = RewardsService.instance;
      
      final health = {
        'rewards_service_initialized': rewardsService.isInitialized,
        'rewards_service_loading': rewardsService.isLoading,
        'rewards_service_error': rewardsService.error,
        'current_user_rewards': rewardsService.userRewards.isNotEmpty,
        'current_user_inventory': rewardsService.userInventory.isNotEmpty,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final allHealthy = rewardsService.isInitialized && 
                        !rewardsService.isLoading && 
                        rewardsService.error == null;

      return {
        'status': allHealthy ? 'healthy' : 'degraded',
        'details': health,
      };
      
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Handle achievement progress checking
  static Future<void> checkAchievementProgress(String userId) async {
    try {
      debugPrint('🏆 Checking achievement progress for user: $userId');
      
      final supabase = Supabase.instance.client;
      final rewardsManager = RewardsManager(supabase);
      await rewardsManager.checkAchievements(userId);
      
      // Refresh rewards service to reflect any new achievements
      await RewardsService.instance.refresh();
      
      debugPrint('✅ Achievement progress checked');
      
    } catch (e) {
      debugPrint('❌ Error checking achievement progress: $e');
    }
  }

  /// Award activity coins (using actual rewards manager method)
  static Future<bool> awardActivityCoins({
    required String userId,
    required String activityType,
    required BuildContext context,
    int? customAmount,
  }) async {
    try {
      debugPrint('💰 Awarding activity coins to user: $userId for: $activityType');
      
      final supabase = Supabase.instance.client;
      final rewardsManager = RewardsManager(supabase);
      await rewardsManager.awardActivityCoins(
        userId,
        activityType,
        context,
        customAmount: customAmount,
      );
      
      // Check for achievements that might be unlocked
      await checkAchievementProgress(userId);
      
      debugPrint('✅ Activity coins awarded successfully');
      return true;
      
    } catch (e) {
      debugPrint('❌ Error awarding activity coins: $e');
      return false;
    }
  }

  /// Track activity with points (using actual rewards manager method)
  static Future<bool> trackActivity({
    required String userId,
    required String activityType,
    required BuildContext context,
    int customPoints = 0,
  }) async {
    try {
      debugPrint('⭐ Tracking activity for user: $userId, type: $activityType');
      
      final supabase = Supabase.instance.client;
      final rewardsManager = RewardsManager(supabase);
      await rewardsManager.trackActivity(
        userId,
        activityType,
        context,
        customPoints: customPoints,
      );
      
      // Check for achievements that might be unlocked
      await checkAchievementProgress(userId);
      
      debugPrint('✅ Activity tracked successfully');
      return true;
      
    } catch (e) {
      debugPrint('❌ Error tracking activity: $e');
      return false;
    }
  }

  /// Record message activity for achievements
  static Future<void> recordMessageActivity(String userId, BuildContext context) async {
    try {
      final supabase = Supabase.instance.client;
      final rewardsManager = RewardsManager(supabase);
      await rewardsManager.trackMessageSent(userId, context);
      
      debugPrint('📝 Message activity recorded for user: $userId');
      
    } catch (e) {
      debugPrint('❌ Error recording message activity: $e');
    }
  }

  /// Record login activity
  static Future<Map<String, dynamic>> recordLoginActivity(String userId) async {
    try {
      final supabase = Supabase.instance.client;
      final rewardsManager = RewardsManager(supabase);
      final result = await rewardsManager.handleDailyLogin(userId);
      
      debugPrint('👋 Login activity recorded for user: $userId');
      return result;
      
    } catch (e) {
      debugPrint('❌ Error recording login activity: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
}
