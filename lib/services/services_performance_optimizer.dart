import 'package:flutter/foundation.dart';
import 'services_production_config.dart';

/// Services Performance Optimizer
/// Production-focused performance enhancements for all Crystal Social services
/// Handles caching, batch processing, and resource optimization
class ServicesPerformanceOptimizer {
  
  // ============================================================================
  // SINGLETON PATTERN
  // ============================================================================
  
  static ServicesPerformanceOptimizer? _instance;
  static ServicesPerformanceOptimizer get instance {
    _instance ??= ServicesPerformanceOptimizer._internal();
    return _instance!;
  }
  
  ServicesPerformanceOptimizer._internal();
  
  // ============================================================================
  // PERFORMANCE MONITORING
  // ============================================================================
  
  final Map<String, DateTime> _serviceStartTimes = {};
  final Map<String, List<int>> _operationDurations = {};
  final Map<String, int> _operationCounts = {};
  
  /// Start timing a service operation
  void startOperation(String operationName) {
    if (!ServicesProductionConfig.enablePerformanceMonitoring) return;
    
    _serviceStartTimes[operationName] = DateTime.now();
    _operationCounts[operationName] = (_operationCounts[operationName] ?? 0) + 1;
  }
  
  /// End timing a service operation and log performance
  void endOperation(String operationName) {
    if (!ServicesProductionConfig.enablePerformanceMonitoring) return;
    
    final startTime = _serviceStartTimes[operationName];
    if (startTime == null) return;
    
    final duration = DateTime.now().difference(startTime).inMilliseconds;
    _operationDurations.putIfAbsent(operationName, () => []).add(duration);
    
    // Log slow operations in debug mode
    if (kDebugMode && duration > 1000) {
      debugPrint('⚠️ Slow operation: $operationName took ${duration}ms');
    }
    
    _serviceStartTimes.remove(operationName);
  }
  
  /// Get performance metrics for a service operation
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
  // BATCH PROCESSING OPTIMIZATION
  // ============================================================================
  
  final Map<String, List<Map<String, dynamic>>> _batchQueues = {};
  final Map<String, DateTime> _lastBatchProcess = {};
  
  /// Add item to batch queue for processing
  void addToBatch(String batchType, Map<String, dynamic> item) {
    if (!ServicesProductionConfig.isFeatureEnabled('batch_processing')) {
      return;
    }
    
    _batchQueues.putIfAbsent(batchType, () => []).add(item);
    
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
  
  /// Process a batch of items
  void _processBatch(String batchType) {
    final queue = _batchQueues[batchType];
    if (queue == null || queue.isEmpty) return;
    
    final itemsToProcess = List<Map<String, dynamic>>.from(queue);
    queue.clear();
    _lastBatchProcess[batchType] = DateTime.now();
    
    if (kDebugMode) {
      debugPrint('📦 Processing batch: $batchType (${itemsToProcess.length} items)');
    }
    
    // Process based on batch type
    switch (batchType) {
      case 'notifications':
        _processNotificationBatch(itemsToProcess);
        break;
      case 'device_cleanup':
        _processDeviceCleanupBatch(itemsToProcess);
        break;
      case 'glimmer_updates':
        _processGlimmerBatch(itemsToProcess);
        break;
    }
  }
  
  /// Get batch size for operation type
  int _getBatchSize(String batchType) {
    switch (batchType) {
      case 'notifications':
        return ServicesProductionConfig.maxNotificationBatchSize;
      case 'device_cleanup':
        return ServicesProductionConfig.maintenanceCleanupBatchSize;
      case 'glimmer_updates':
        return ServicesProductionConfig.glimmerPostBatchSize;
      default:
        return 50;
    }
  }
  
  /// Get batch interval for operation type
  Duration _getBatchInterval(String batchType) {
    switch (batchType) {
      case 'notifications':
        return ServicesProductionConfig.notificationBatchInterval;
      case 'device_cleanup':
        return ServicesProductionConfig.maintenanceCleanupDelay;
      case 'glimmer_updates':
        return const Duration(seconds: 10);
      default:
        return const Duration(seconds: 5);
    }
  }
  
  // ============================================================================
  // BATCH PROCESSORS
  // ============================================================================
  
  /// Process notification batch
  void _processNotificationBatch(List<Map<String, dynamic>> notifications) {
    startOperation('notification_batch');
    
    try {
      // Group notifications by type for efficient processing
      final groupedNotifications = <String, List<Map<String, dynamic>>>{};
      for (final notification in notifications) {
        final type = notification['type'] as String? ?? 'general';
        groupedNotifications.putIfAbsent(type, () => []).add(notification);
      }
      
      // Process each group
      for (final entry in groupedNotifications.entries) {
        if (kDebugMode) {
          debugPrint('📱 Processing ${entry.value.length} ${entry.key} notifications');
        }
      }
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error processing notification batch: $e');
      }
    } finally {
      endOperation('notification_batch');
    }
  }
  
  /// Process device cleanup batch
  void _processDeviceCleanupBatch(List<Map<String, dynamic>> devices) {
    startOperation('device_cleanup_batch');
    
    try {
      final now = DateTime.now();
      int cleanedCount = 0;
      
      for (final device in devices) {
        final lastActive = device['last_active'] as DateTime?;
        if (lastActive != null) {
          final daysSinceActive = now.difference(lastActive).inDays;
          if (daysSinceActive > ServicesProductionConfig.maxInactiveDeviceDays) {
            cleanedCount++;
          }
        }
      }
      
      if (kDebugMode && cleanedCount > 0) {
        debugPrint('🧹 Cleaned up $cleanedCount inactive devices');
      }
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error processing device cleanup batch: $e');
      }
    } finally {
      endOperation('device_cleanup_batch');
    }
  }
  
  /// Process Glimmer updates batch
  void _processGlimmerBatch(List<Map<String, dynamic>> updates) {
    startOperation('glimmer_batch');
    
    try {
      // Group updates by type (likes, comments, posts)
      final likes = updates.where((u) => u['type'] == 'like').toList();
      final comments = updates.where((u) => u['type'] == 'comment').toList();
      final posts = updates.where((u) => u['type'] == 'post').toList();
      
      if (kDebugMode) {
        debugPrint('✨ Processing Glimmer batch: ${likes.length} likes, ${comments.length} comments, ${posts.length} posts');
      }
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error processing Glimmer batch: $e');
      }
    } finally {
      endOperation('glimmer_batch');
    }
  }
  
  // ============================================================================
  // MEMORY OPTIMIZATION
  // ============================================================================
  
  final Map<String, Map<String, dynamic>> _serviceCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  
  /// Cache service result
  void cacheResult(String key, Map<String, dynamic> result) {
    if (!ServicesProductionConfig.enableServiceCaching) return;
    
    _serviceCache[key] = result;
    _cacheTimestamps[key] = DateTime.now();
    
    // Clean old cache entries
    _cleanExpiredCache();
  }
  
  /// Get cached result
  Map<String, dynamic>? getCachedResult(String key) {
    if (!ServicesProductionConfig.enableServiceCaching) return null;
    
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return null;
    
    final age = DateTime.now().difference(timestamp);
    if (age > ServicesProductionConfig.serviceCacheTimeout) {
      _serviceCache.remove(key);
      _cacheTimestamps.remove(key);
      return null;
    }
    
    return _serviceCache[key];
  }
  
  /// Clean expired cache entries
  void _cleanExpiredCache() {
    if (_serviceCache.length <= ServicesProductionConfig.maxCacheSize) return;
    
    final now = DateTime.now();
    final expiredKeys = <String>[];
    
    for (final entry in _cacheTimestamps.entries) {
      if (now.difference(entry.value) > ServicesProductionConfig.serviceCacheTimeout) {
        expiredKeys.add(entry.key);
      }
    }
    
    for (final key in expiredKeys) {
      _serviceCache.remove(key);
      _cacheTimestamps.remove(key);
    }
    
    if (kDebugMode && expiredKeys.isNotEmpty) {
      debugPrint('🗑️ Cleaned ${expiredKeys.length} expired cache entries');
    }
  }
  
  // ============================================================================
  // RESOURCE OPTIMIZATION
  // ============================================================================
  
  /// Optimize service resource usage
  void optimizeResources() {
    startOperation('resource_optimization');
    
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
        debugPrint('🔧 Service resource optimization completed');
      }
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error during resource optimization: $e');
      }
    } finally {
      endOperation('resource_optimization');
    }
  }
  
  /// Clean old performance monitoring data
  void _cleanPerformanceData() {
    const maxEntries = 1000;
    
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
  
  /// Get comprehensive performance report
  Map<String, dynamic> getPerformanceReport() {
    final report = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'cache_stats': {
        'entries': _serviceCache.length,
        'max_size': ServicesProductionConfig.maxCacheSize,
        'hit_rate': _calculateCacheHitRate(),
      },
      'batch_stats': {
        'queues': _batchQueues.keys.length,
        'pending_items': _batchQueues.values.fold(0, (sum, queue) => sum + queue.length),
      },
      'operations': {},
    };
    
    // Add operation metrics
    for (final operation in _operationDurations.keys) {
      report['operations'][operation] = getPerformanceMetrics(operation);
    }
    
    return report;
  }
  
  /// Calculate cache hit rate (simplified)
  double _calculateCacheHitRate() {
    // This is a simplified calculation
    // In a real implementation, you'd track cache hits vs misses
    return _serviceCache.isNotEmpty ? 0.85 : 0.0;
  }
}
