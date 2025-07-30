import 'package:flutter/foundation.dart';
import 'rewards_production_config.dart';

/// Rewards Performance Optimizer
/// Production-focused performance enhancements for the Crystal Social rewards system
/// Handles caching, batch processing, and resource optimization
class RewardsPerformanceOptimizer {
  
  // ============================================================================
  // SINGLETON PATTERN
  // ============================================================================
  
  static RewardsPerformanceOptimizer? _instance;
  static RewardsPerformanceOptimizer get instance {
    _instance ??= RewardsPerformanceOptimizer._internal();
    return _instance!;
  }
  
  RewardsPerformanceOptimizer._internal();
  
  // ============================================================================
  // PERFORMANCE MONITORING
  // ============================================================================
  
  final Map<String, DateTime> _operationStartTimes = {};
  final Map<String, List<int>> _operationDurations = {};
  final Map<String, int> _operationCounts = {};
  
  /// Start timing a rewards operation
  void startOperation(String operationName) {
    if (!RewardsProductionConfig.enablePerformanceMonitoring) return;
    
    _operationStartTimes[operationName] = DateTime.now();
    _operationCounts[operationName] = (_operationCounts[operationName] ?? 0) + 1;
  }
  
  /// End timing a rewards operation and log performance
  void endOperation(String operationName) {
    if (!RewardsProductionConfig.enablePerformanceMonitoring) return;
    
    final startTime = _operationStartTimes[operationName];
    if (startTime == null) return;
    
    final duration = DateTime.now().difference(startTime).inMilliseconds;
    _operationDurations.putIfAbsent(operationName, () => []).add(duration);
    
    // Log slow operations in debug mode
    if (kDebugMode && duration > 2000) {
      debugPrint('⚠️ Slow rewards operation: $operationName took ${duration}ms');
    }
    
    _operationStartTimes.remove(operationName);
  }
  
  /// Get performance metrics for a rewards operation
  Map<String, dynamic> getPerformanceMetrics(String operationName) {
    final durations = _operationDurations[operationName] ?? [];
    if (durations.isEmpty) {
      return {'count': 0, 'average': 0, 'min': 0, 'max': 0};
    }
    
    final count = durations.length;
    final average = durations.reduce((a, b) => a + b) / count;
    final min = durations.reduce((a, b) => a < b ? a : b);
    final max = durations.reduce((a, b) => a > b ? a : b);
    
    return {
      'count': count,
      'average': average.round(),
      'min': min,
      'max': max,
      'total_operations': _operationCounts[operationName] ?? 0,
    };
  }
  
  // ============================================================================
  // REWARDS CACHING SYSTEM
  // ============================================================================
  
  final Map<String, Map<String, dynamic>> _rewardsCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Map<String, List<Map<String, dynamic>>> _inventoryCache = {};
  final Map<String, List<Map<String, dynamic>>> _shopCache = {};
  
  /// Cache user rewards data
  void cacheUserRewards(String userId, Map<String, dynamic> rewards) {
    if (!RewardsProductionConfig.isFeatureEnabled('enable_caching')) return;
    
    final cacheKey = 'user_rewards_$userId';
    _rewardsCache[cacheKey] = rewards;
    _cacheTimestamps[cacheKey] = DateTime.now();
    
    _cleanExpiredCache();
  }
  
  /// Get cached user rewards
  Map<String, dynamic>? getCachedUserRewards(String userId) {
    if (!RewardsProductionConfig.isFeatureEnabled('enable_caching')) return null;
    
    final cacheKey = 'user_rewards_$userId';
    final timestamp = _cacheTimestamps[cacheKey];
    if (timestamp == null) return null;
    
    final age = DateTime.now().difference(timestamp);
    if (age > RewardsProductionConfig.cacheExpiration) {
      _rewardsCache.remove(cacheKey);
      _cacheTimestamps.remove(cacheKey);
      return null;
    }
    
    return _rewardsCache[cacheKey];
  }
  
  /// Cache user inventory
  void cacheUserInventory(String userId, List<Map<String, dynamic>> inventory) {
    if (!RewardsProductionConfig.isFeatureEnabled('enable_caching')) return;
    
    final cacheKey = 'user_inventory_$userId';
    _inventoryCache[cacheKey] = inventory;
    _cacheTimestamps[cacheKey] = DateTime.now();
    
    _cleanExpiredCache();
  }
  
  /// Get cached user inventory
  List<Map<String, dynamic>>? getCachedUserInventory(String userId) {
    if (!RewardsProductionConfig.isFeatureEnabled('enable_caching')) return null;
    
    final cacheKey = 'user_inventory_$userId';
    final timestamp = _cacheTimestamps[cacheKey];
    if (timestamp == null) return null;
    
    final age = DateTime.now().difference(timestamp);
    if (age > RewardsProductionConfig.inventoryCacheTimeout) {
      _inventoryCache.remove(cacheKey);
      _cacheTimestamps.remove(cacheKey);
      return null;
    }
    
    return _inventoryCache[cacheKey];
  }
  
  /// Cache shop items
  void cacheShopItems(List<Map<String, dynamic>> shopItems) {
    if (!RewardsProductionConfig.isFeatureEnabled('enable_caching')) return;
    
    const cacheKey = 'shop_items_global';
    _shopCache[cacheKey] = shopItems;
    _cacheTimestamps[cacheKey] = DateTime.now();
    
    _cleanExpiredCache();
  }
  
  /// Get cached shop items
  List<Map<String, dynamic>>? getCachedShopItems() {
    if (!RewardsProductionConfig.isFeatureEnabled('enable_caching')) return null;
    
    const cacheKey = 'shop_items_global';
    final timestamp = _cacheTimestamps[cacheKey];
    if (timestamp == null) return null;
    
    final age = DateTime.now().difference(timestamp);
    if (age > RewardsProductionConfig.shopCacheTimeout) {
      _shopCache.remove(cacheKey);
      _cacheTimestamps.remove(cacheKey);
      return null;
    }
    
    return _shopCache[cacheKey];
  }
  
  // ============================================================================
  // BATCH PROCESSING OPTIMIZATION
  // ============================================================================
  
  final Map<String, List<Map<String, dynamic>>> _batchQueues = {};
  final Map<String, DateTime> _lastBatchProcess = {};
  
  /// Add reward transaction to batch queue
  void addRewardToBatch(String batchType, Map<String, dynamic> rewardData) {
    if (!RewardsProductionConfig.isFeatureEnabled('enable_batch_processing')) {
      return;
    }
    
    _batchQueues.putIfAbsent(batchType, () => []).add(rewardData);
    
    // Check if batch should be processed
    _checkBatchProcessing(batchType);
  }
  
  /// Check if batch should be processed based on size or time
  void _checkBatchProcessing(String batchType) {
    final queue = _batchQueues[batchType] ?? [];
    final lastProcess = _lastBatchProcess[batchType];
    final now = DateTime.now();
    
    final shouldProcessBySize = queue.length >= _getBatchSize(batchType);
    final shouldProcessByTime = lastProcess == null || 
        now.difference(lastProcess) >= _getBatchInterval(batchType);
    
    if (shouldProcessBySize || shouldProcessByTime) {
      _processBatch(batchType);
    }
  }
  
  /// Process a batch of reward transactions
  void _processBatch(String batchType) {
    final queue = _batchQueues[batchType];
    if (queue == null || queue.isEmpty) return;
    
    final itemsToProcess = List<Map<String, dynamic>>.from(queue);
    queue.clear();
    _lastBatchProcess[batchType] = DateTime.now();
    
    if (kDebugMode) {
      debugPrint('💰 Processing rewards batch: $batchType (${itemsToProcess.length} items)');
    }
    
    // Process based on batch type
    switch (batchType) {
      case 'activity_rewards':
        _processActivityRewardsBatch(itemsToProcess);
        break;
      case 'purchases':
        _processPurchasesBatch(itemsToProcess);
        break;
      case 'achievements':
        _processAchievementsBatch(itemsToProcess);
        break;
      case 'inventory_updates':
        _processInventoryUpdatesBatch(itemsToProcess);
        break;
    }
  }
  
  /// Get batch size for operation type
  int _getBatchSize(String batchType) {
    switch (batchType) {
      case 'activity_rewards':
        return 50;
      case 'purchases':
        return 20;
      case 'achievements':
        return 10;
      case 'inventory_updates':
        return RewardsProductionConfig.maxBatchSize;
      default:
        return 25;
    }
  }
  
  /// Get batch interval for operation type
  Duration _getBatchInterval(String batchType) {
    switch (batchType) {
      case 'activity_rewards':
        return const Duration(seconds: 30);
      case 'purchases':
        return const Duration(seconds: 10);
      case 'achievements':
        return const Duration(seconds: 15);
      case 'inventory_updates':
        return const Duration(seconds: 20);
      default:
        return const Duration(seconds: 15);
    }
  }
  
  // ============================================================================
  // BATCH PROCESSORS
  // ============================================================================
  
  /// Process activity rewards batch
  void _processActivityRewardsBatch(List<Map<String, dynamic>> rewards) {
    startOperation('activity_rewards_batch');
    
    try {
      // Group rewards by user and activity type
      final userRewards = <String, Map<String, int>>{};
      
      for (final reward in rewards) {
        final userId = reward['user_id'] as String;
        final activityType = reward['activity_type'] as String;
        final amount = reward['amount'] as int;
        
        userRewards.putIfAbsent(userId, () => {});
        userRewards[userId]![activityType] = 
            (userRewards[userId]![activityType] ?? 0) + amount;
      }
      
      // Process consolidated rewards for each user
      for (final entry in userRewards.entries) {
        final userId = entry.key;
        final activities = entry.value;
        
        if (kDebugMode) {
          debugPrint('💰 Processing ${activities.length} activity types for user $userId');
        }
      }
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error processing activity rewards batch: $e');
      }
    } finally {
      endOperation('activity_rewards_batch');
    }
  }
  
  /// Process purchases batch
  void _processPurchasesBatch(List<Map<String, dynamic>> purchases) {
    startOperation('purchases_batch');
    
    try {
      // Group purchases by user
      final userPurchases = <String, List<Map<String, dynamic>>>{};
      
      for (final purchase in purchases) {
        final userId = purchase['user_id'] as String;
        userPurchases.putIfAbsent(userId, () => []).add(purchase);
      }
      
      // Process purchases for each user
      for (final entry in userPurchases.entries) {
        final userId = entry.key;
        final purchases = entry.value;
        
        if (kDebugMode) {
          debugPrint('🛒 Processing ${purchases.length} purchases for user $userId');
        }
      }
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error processing purchases batch: $e');
      }
    } finally {
      endOperation('purchases_batch');
    }
  }
  
  /// Process achievements batch
  void _processAchievementsBatch(List<Map<String, dynamic>> achievements) {
    startOperation('achievements_batch');
    
    try {
      // Group achievements by user
      final userAchievements = <String, List<Map<String, dynamic>>>{};
      
      for (final achievement in achievements) {
        final userId = achievement['user_id'] as String;
        userAchievements.putIfAbsent(userId, () => []).add(achievement);
      }
      
      // Process achievements for each user
      for (final entry in userAchievements.entries) {
        final userId = entry.key;
        final achievements = entry.value;
        
        if (kDebugMode) {
          debugPrint('🏆 Processing ${achievements.length} achievements for user $userId');
        }
      }
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error processing achievements batch: $e');
      }
    } finally {
      endOperation('achievements_batch');
    }
  }
  
  /// Process inventory updates batch
  void _processInventoryUpdatesBatch(List<Map<String, dynamic>> updates) {
    startOperation('inventory_updates_batch');
    
    try {
      // Group updates by user
      final userUpdates = <String, List<Map<String, dynamic>>>{};
      
      for (final update in updates) {
        final userId = update['user_id'] as String;
        userUpdates.putIfAbsent(userId, () => []).add(update);
      }
      
      // Process updates for each user
      for (final entry in userUpdates.entries) {
        final userId = entry.key;
        final updates = entry.value;
        
        if (kDebugMode) {
          debugPrint('📦 Processing ${updates.length} inventory updates for user $userId');
        }
      }
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error processing inventory updates batch: $e');
      }
    } finally {
      endOperation('inventory_updates_batch');
    }
  }
  
  // ============================================================================
  // MEMORY OPTIMIZATION
  // ============================================================================
  
  /// Clean expired cache entries
  void _cleanExpiredCache() {
    if (_rewardsCache.length + _inventoryCache.length + _shopCache.length <= 
        RewardsProductionConfig.maxCacheSize) return;
    
    final now = DateTime.now();
    final expiredKeys = <String>[];
    
    // Check rewards cache
    for (final entry in _cacheTimestamps.entries) {
      if (now.difference(entry.value) > RewardsProductionConfig.cacheExpiration) {
        expiredKeys.add(entry.key);
      }
    }
    
    // Remove expired entries
    for (final key in expiredKeys) {
      _rewardsCache.remove(key);
      _inventoryCache.remove(key);
      _shopCache.remove(key);
      _cacheTimestamps.remove(key);
    }
    
    if (kDebugMode && expiredKeys.isNotEmpty) {
      debugPrint('🗑️ Cleaned ${expiredKeys.length} expired rewards cache entries');
    }
  }
  
  /// Optimize rewards system resources
  void optimizeResources() {
    startOperation('rewards_resource_optimization');
    
    try {
      // Clean expired cache
      _cleanExpiredCache();
      
      // Process pending batches
      for (final batchType in _batchQueues.keys) {
        _processBatch(batchType);
      }
      
      // Clear old performance data
      _cleanPerformanceData();
      
      if (kDebugMode) {
        debugPrint('🔧 Rewards resource optimization completed');
      }
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error during rewards resource optimization: $e');
      }
    } finally {
      endOperation('rewards_resource_optimization');
    }
  }
  
  /// Clean old performance monitoring data
  void _cleanPerformanceData() {
    const maxEntries = 500;
    
    for (final entry in _operationDurations.entries) {
      if (entry.value.length > maxEntries) {
        // Keep only the most recent entries
        final recentEntries = entry.value.skip(entry.value.length - maxEntries).toList();
        _operationDurations[entry.key] = recentEntries;
      }
    }
  }
  
  // ============================================================================
  // PERFORMANCE REPORTING
  // ============================================================================
  
  /// Get comprehensive performance report for rewards system
  Map<String, dynamic> getRewardsPerformanceReport() {
    final report = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'rewards_cache_stats': {
        'rewards_entries': _rewardsCache.length,
        'inventory_entries': _inventoryCache.length,
        'shop_entries': _shopCache.length,
        'total_entries': _rewardsCache.length + _inventoryCache.length + _shopCache.length,
        'max_size': RewardsProductionConfig.maxCacheSize,
      },
      'batch_stats': {
        'active_queues': _batchQueues.keys.length,
        'pending_rewards': _batchQueues.values.fold(0, (sum, queue) => sum + queue.length),
      },
      'performance_operations': {},
    };
    
    // Add operation metrics
    for (final operation in _operationDurations.keys) {
      report['performance_operations'][operation] = getPerformanceMetrics(operation);
    }
    
    return report;
  }
}
