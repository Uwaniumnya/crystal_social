import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'rewards_manager.dart';
import 'rewards_service.dart';
import 'aura_service.dart';
import 'shop_item_sync.dart';
import 'dart:async';

/// Unified Rewards Coordinator
/// Central hub that coordinates all rewards system components to work together smoothly
/// Provides a single entry point for all rewards operations across the application
class UnifiedRewardsCoordinator {
  static UnifiedRewardsCoordinator? _instance;
  static UnifiedRewardsCoordinator get instance {
    _instance ??= UnifiedRewardsCoordinator._internal();
    return _instance!;
  }

  UnifiedRewardsCoordinator._internal();

  // Core services
  late final RewardsService _rewardsService;
  late final RewardsManager _rewardsManager;
  late final AuraService _auraService;
  late final ShopItemSyncService _shopSyncService;
  
  final SupabaseClient _supabase = Supabase.instance.client;
  
  bool _isInitialized = false;
  String? _currentUserId;
  final Map<String, dynamic> _coordinatorCache = {};
  
  // Stream controllers for system-wide events
  final StreamController<Map<String, dynamic>> _rewardsEventController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _purchaseEventController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _achievementEventController = 
      StreamController<Map<String, dynamic>>.broadcast();

  // Getters
  bool get isInitialized => _isInitialized;
  String? get currentUserId => _currentUserId;
  RewardsService get rewardsService => _rewardsService;
  RewardsManager get rewardsManager => _rewardsManager;
  AuraService get auraService => _auraService;
  ShopItemSyncService get shopSyncService => _shopSyncService;

  // Event streams
  Stream<Map<String, dynamic>> get rewardsEventStream => _rewardsEventController.stream;
  Stream<Map<String, dynamic>> get purchaseEventStream => _purchaseEventController.stream;
  Stream<Map<String, dynamic>> get achievementEventStream => _achievementEventController.stream;

  /// Initialize the unified rewards coordinator
  Future<void> initialize(String userId) async {
    if (_isInitialized && _currentUserId == userId) return;

    try {
      debugPrint('🎁 Initializing Unified Rewards Coordinator for user: $userId');
      
      _currentUserId = userId;

      // Initialize all services
      await _initializeServices(userId);
      
      // Set up cross-service integrations
      await _setupIntegrations();
      
      // Sync initial data
      await _performInitialSync();
      
      _isInitialized = true;
      _emitRewardsEvent('coordinator_initialized', {'user_id': userId});
      
      debugPrint('✅ Unified Rewards Coordinator initialized successfully');
      
    } catch (e) {
      debugPrint('❌ Failed to initialize Unified Rewards Coordinator: $e');
      rethrow;
    }
  }

  /// Initialize all core services
  Future<void> _initializeServices(String userId) async {
    debugPrint('📦 Initializing rewards services...');
    
    // Initialize rewards service (this handles rewards manager and aura service internally)
    _rewardsService = RewardsService.instance;
    await _rewardsService.initialize(userId);
    
    // Get references to underlying services
    _rewardsManager = _rewardsService.rewardsManager;
    _auraService = _rewardsService.auraService;
    
    // Initialize shop sync service
    _shopSyncService = ShopItemSyncService(_supabase);
    // Shop sync service doesn't need initialization
    
    debugPrint('✅ All rewards services initialized');
  }

  /// Set up integrations between services
  Future<void> _setupIntegrations() async {
    debugPrint('🔗 Setting up service integrations...');
    
    // Listen to rewards service events and coordinate with other services
    _rewardsService.rewardsStream.listen(_handleRewardsUpdate);
    _rewardsService.inventoryStream.listen(_handleInventoryUpdate);
    _rewardsService.achievementsStream.listen(_handleAchievementUpdate);
    
    debugPrint('✅ Service integrations set up');
  }

  /// Perform initial data synchronization
  Future<void> _performInitialSync() async {
    debugPrint('🔄 Performing initial data sync...');
    
    try {
      // Sync shop items to ensure database is up to date
      await _shopSyncService.uploadAndSyncShopItems();
      
      // Refresh all user data
      await _rewardsService.refresh();
      
      debugPrint('✅ Initial data sync completed');
    } catch (e) {
      debugPrint('⚠️ Initial sync warning: $e');
      // Don't throw here as this is not critical for initialization
    }
  }

  /// Comprehensive purchase flow with full integration
  Future<Map<String, dynamic>> purchaseItem({
    required Map<String, dynamic> item,
    required String userId,
    required BuildContext context,
    int quantity = 1,
  }) async {
    try {
      debugPrint('🛒 Starting comprehensive purchase flow for: ${item['name']}');
      
      // Pre-purchase validation
      final validation = await _validatePurchase(item, userId, quantity);
      if (!validation['valid']) {
        return {
          'success': false,
          'error': validation['error'],
          'code': 'VALIDATION_FAILED',
        };
      }

      // Execute purchase through rewards manager (using correct signature)
      final purchaseResult = await _rewardsManager.purchaseItem(
        _currentUserId!,
        item['id'] ?? 0,
        context,
      );
      
      if (purchaseResult['success'] == true) {
        // Post-purchase integration tasks
        await _handleSuccessfulPurchase(item, userId, quantity);
        
        _emitPurchaseEvent('purchase_success', {
          'item': item,
          'user_id': userId,
          'quantity': quantity,
          'timestamp': DateTime.now().toIso8601String(),
        });

        return {
          'success': true,
          'item': item,
          'message': 'Purchase completed successfully',
        };
      } else {
        return {
          'success': false,
          'error': 'Purchase failed - insufficient funds or other error',
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

  /// Enhanced aura management with full integration
  Future<Map<String, dynamic>> equipAura({
    required String auraId,
    required String userId,
  }) async {
    try {
      debugPrint('✨ Equipping aura: $auraId for user: $userId');
      
      // Check if user owns the aura
      final inventory = await _rewardsService.userInventory;
      final ownsAura = inventory.any((item) => 
        item['item_id'] == auraId && item['item_type'] == 'aura'
      );
      
      if (!ownsAura) {
        return {
          'success': false,
          'error': 'Aura not owned by user',
          'code': 'AURA_NOT_OWNED',
        };
      }

      // Equip aura through aura service
      await _auraService.updateEquippedAura(userId, auraId);
      
      // Update cache and notify other services
      _coordinatorCache['equipped_aura_$userId'] = auraId;
      
      _emitRewardsEvent('aura_equipped', {
        'aura_id': auraId,
        'user_id': userId,
        'timestamp': DateTime.now().toIso8601String(),
      });

      return {
        'success': true,
        'aura_id': auraId,
        'message': 'Aura equipped successfully',
      };
      
    } catch (e) {
      debugPrint('❌ Aura equip error: $e');
      return {
        'success': false,
        'error': e.toString(),
        'code': 'AURA_EQUIP_ERROR',
      };
    }
  }

  /// Comprehensive achievement system integration
  Future<Map<String, dynamic>> unlockAchievement({
    required String achievementId,
    required String userId,
    Map<String, dynamic>? progress,
  }) async {
    try {
      debugPrint('🏆 Unlocking achievement: $achievementId for user: $userId');
      
      // Check if achievement is already unlocked
      final userAchievements = await _rewardsService.achievements;
      final alreadyUnlocked = userAchievements.any((ach) => 
        ach['id'] == achievementId && ach['unlocked'] == true
      );
      
      if (alreadyUnlocked) {
        return {
          'success': false,
          'error': 'Achievement already unlocked',
          'code': 'ALREADY_UNLOCKED',
        };
      }

      // Check achievements through rewards manager
      await _rewardsManager.checkAchievements(userId);
      
      // Check if achievement was unlocked by verifying current achievements
      final updatedAchievements = await _rewardsService.achievements;
      final wasUnlocked = updatedAchievements.any((ach) => 
        ach['id'] == achievementId && ach['unlocked'] == true
      );
      
      if (wasUnlocked && !alreadyUnlocked) {
        // Achievement was successfully unlocked
        _emitAchievementEvent('achievement_unlocked', {
          'achievement_id': achievementId,
          'user_id': userId,
          'timestamp': DateTime.now().toIso8601String(),
        });

        return {
          'success': true,
          'achievement_id': achievementId,
          'message': 'Achievement unlocked successfully',
        };
      } else {
        return {
          'success': false,
          'error': 'Achievement was not unlocked or conditions not met',
          'code': 'UNLOCK_FAILED',
        };
      }
      
    } catch (e) {
      debugPrint('❌ Achievement unlock error: $e');
      return {
        'success': false,
        'error': e.toString(),
        'code': 'ACHIEVEMENT_ERROR',
      };
    }
  }

  /// Enhanced booster pack opening with full rewards integration
  Future<Map<String, dynamic>> openBoosterPack({
    required String boosterPackId,
    required String userId,
  }) async {
    try {
      debugPrint('📦 Opening booster pack: $boosterPackId for user: $userId');
      
      // Check if user owns the booster pack
      final inventory = await _rewardsService.userInventory;
      final ownsBooster = inventory.any((item) => 
        item['item_id'] == boosterPackId && item['item_type'] == 'booster'
      );
      
      if (!ownsBooster) {
        return {
          'success': false,
          'error': 'Booster pack not owned by user',
          'code': 'BOOSTER_NOT_OWNED',
        };
      }

      // Generate random rewards based on booster pack type
      final rewards = await _generateBoosterRewards(boosterPackId);
      
      // TODO: Add rewards to user inventory using available methods
      // Currently commented out until proper inventory methods are available
      /*
      final addResults = <Map<String, dynamic>>[];
      for (final reward in rewards) {
        final addResult = await _rewardsManager.addItemToInventory(
          userId: userId,
          itemId: reward['item_id'],
          itemType: reward['item_type'],
          quantity: reward['quantity'] ?? 1,
          source: 'booster_pack',
        );
        addResults.add(addResult);
      }

      // Remove booster pack from inventory
      await _rewardsManager.removeItemFromInventory(
        userId: userId,
        itemId: boosterPackId,
        itemType: 'booster',
        quantity: 1,
      );
      */

      _emitRewardsEvent('booster_opened', {
        'booster_id': boosterPackId,
        'user_id': userId,
        'rewards': rewards,
        'timestamp': DateTime.now().toIso8601String(),
      });

      return {
        'success': true,
        'booster_id': boosterPackId,
        'rewards': rewards,
        'message': 'Booster pack opened successfully',
      };
      
    } catch (e) {
      debugPrint('❌ Booster pack error: $e');
      return {
        'success': false,
        'error': e.toString(),
        'code': 'BOOSTER_ERROR',
      };
    }
  }

  /// Get comprehensive user rewards status
  Future<Map<String, dynamic>> getUserRewardsStatus(String userId) async {
    try {
      // Ensure services are initialized
      if (!_isInitialized || _currentUserId != userId) {
        await initialize(userId);
      }

      final userRewards = _rewardsService.userRewards;
      final userStats = _rewardsService.userStats;
      final inventory = _rewardsService.userInventory;
      final achievements = _rewardsService.achievements;

      // Get equipped items
      final equippedAura = await _auraService.fetchEquippedAura(userId);
      
      // Calculate additional statistics
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
      debugPrint('❌ Error getting user rewards status: $e');
      return {'error': e.toString()};
    }
  }

  /// Refresh all rewards data across all services
  Future<void> refreshAllData() async {
    try {
      debugPrint('🔄 Refreshing all rewards data...');
      
      if (_currentUserId != null) {
        // Refresh rewards service data
        await _rewardsService.refresh();
        
        // Clear local cache
        _coordinatorCache.clear();
        
        // Emit refresh event
        _emitRewardsEvent('data_refreshed', {
          'user_id': _currentUserId,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
      
      debugPrint('✅ All rewards data refreshed');
      
    } catch (e) {
      debugPrint('❌ Error refreshing rewards data: $e');
      rethrow;
    }
  }

  /// Get system health status
  Future<Map<String, dynamic>> getSystemHealth() async {
    try {
      final health = {
        'coordinator_initialized': _isInitialized,
        'current_user': _currentUserId,
        'rewards_service_initialized': _rewardsService.isInitialized,
        'rewards_service_loading': _rewardsService.isLoading,
        'rewards_service_error': _rewardsService.error,
        'cache_entries': _coordinatorCache.length,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final allHealthy = _isInitialized && 
                        _rewardsService.isInitialized && 
                        !_rewardsService.isLoading && 
                        _rewardsService.error == null;

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

  /// Private helper methods

  Future<Map<String, dynamic>> _validatePurchase(
    Map<String, dynamic> item, 
    String userId, 
    int quantity
  ) async {
    try {
      // Check user level requirement
      final userRewards = _rewardsService.userRewards;
      final userLevel = userRewards['level'] ?? 1;
      final requiredLevel = item['requires_level'] ?? 1;
      
      if (userLevel < requiredLevel) {
        return {
          'valid': false,
          'error': 'Insufficient level. Required: $requiredLevel, Current: $userLevel',
        };
      }

      // Check if user has enough coins
      final userCoins = userRewards['coins'] ?? 0;
      final totalCost = (item['price'] ?? 0) * quantity;
      
      if (userCoins < totalCost) {
        return {
          'valid': false,
          'error': 'Insufficient coins. Required: $totalCost, Available: $userCoins',
        };
      }

      // Check max per user limit
      final maxPerUser = item['max_per_user'];
      if (maxPerUser != null) {
        final inventory = _rewardsService.userInventory;
        final ownedCount = inventory.where((inv) => inv['item_id'] == item['id']).length;
        
        if (ownedCount + quantity > maxPerUser) {
          return {
            'valid': false,
            'error': 'Maximum ownership limit reached. Max: $maxPerUser, Current: $ownedCount',
          };
        }
      }

      return {'valid': true};
      
    } catch (e) {
      return {
        'valid': false,
        'error': 'Validation error: $e',
      };
    }
  }

  Future<void> _handleSuccessfulPurchase(
    Map<String, dynamic> item,
    String userId,
    int quantity,
  ) async {
    try {
      // Check for achievement unlocks based on purchase
      await _checkPurchaseAchievements(item, userId, quantity);
      
      // Update user statistics
      await _updatePurchaseStats(item, userId, quantity);
      
    } catch (e) {
      debugPrint('⚠️ Post-purchase processing error: $e');
    }
  }

  Future<void> _checkPurchaseAchievements(
    Map<String, dynamic> item,
    String userId,
    int quantity,
  ) async {
    // This would check for various purchase-related achievements
    // e.g., "First Purchase", "Big Spender", "Collector", etc.
    // Implementation depends on your specific achievement definitions
  }

  Future<void> _updatePurchaseStats(
    Map<String, dynamic> item,
    String userId,
    int quantity,
  ) async {
    // This would update user statistics related to purchases
    // e.g., total spent, favorite category, etc.
  }

  Future<List<Map<String, dynamic>>> _generateBoosterRewards(String boosterPackId) async {
    // This would generate random rewards based on the booster pack type
    // Implementation depends on your specific booster pack logic
    return [];
  }

  void _handleRewardsUpdate(Map<String, dynamic> rewards) {
    _emitRewardsEvent('rewards_updated', rewards);
  }

  void _handleInventoryUpdate(List<Map<String, dynamic>> inventory) {
    _emitRewardsEvent('inventory_updated', {'inventory': inventory});
  }

  void _handleAchievementUpdate(List<Map<String, dynamic>> achievements) {
    _emitAchievementEvent('achievements_updated', {'achievements': achievements});
  }

  void _emitRewardsEvent(String type, Map<String, dynamic> data) {
    _rewardsEventController.add({
      'type': type,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void _emitPurchaseEvent(String type, Map<String, dynamic> data) {
    _purchaseEventController.add({
      'type': type,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void _emitAchievementEvent(String type, Map<String, dynamic> data) {
    _achievementEventController.add({
      'type': type,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Dispose of resources
  void dispose() {
    _rewardsEventController.close();
    _purchaseEventController.close();
    _achievementEventController.close();
    _coordinatorCache.clear();
    _auraService.dispose();
  }
}
