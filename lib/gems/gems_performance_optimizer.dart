// File: gems_performance_optimizer.dart
// Performance optimization and caching system for gems

import 'dart:async';
import 'dart:collection';
import 'gemstone_model.dart';
import 'gems_production_config.dart';

/// Advanced performance optimizer for the gems system
class GemsPerformanceOptimizer {
  static final GemsPerformanceOptimizer _instance = GemsPerformanceOptimizer._internal();
  factory GemsPerformanceOptimizer() => _instance;
  GemsPerformanceOptimizer._internal();

  // Caching systems
  final LRUCache<String, List<Gemstone>> _userGemsCache = LRUCache(100);
  final LRUCache<String, Gemstone> _gemDetailsCache = LRUCache(200);
  final LRUCache<String, Map<String, dynamic>> _userStatsCache = LRUCache(50);
  final LRUCache<String, bool> _unlockStatusCache = LRUCache(500);
  
  // Performance tracking
  final Map<String, List<Duration>> _operationTimes = {};
  final Map<String, int> _cacheHits = {};
  final Map<String, int> _cacheMisses = {};
  
  // Subscription management
  final Map<String, StreamSubscription> _activeSubscriptions = {};
  Timer? _cacheCleanupTimer;
  Timer? _performanceReportTimer;
  
  bool _isInitialized = false;

  /// Initialize the performance optimizer
  void initialize() {
    if (_isInitialized) return;
    
    _startCacheCleanup();
    _startPerformanceReporting();
    _isInitialized = true;
    
    GemsDebugUtils.log('PerformanceOptimizer', 'Initialized with caching and monitoring');
  }

  /// Cache user gems with expiration
  void cacheUserGems(String userId, List<Gemstone> gems) {
    _userGemsCache.put(userId, gems);
    _recordCacheOperation('userGems', 'write');
    GemsDebugUtils.log('PerformanceOptimizer', 'Cached ${gems.length} gems for user $userId');
  }

  /// Get cached user gems
  List<Gemstone>? getCachedUserGems(String userId) {
    final gems = _userGemsCache.get(userId);
    if (gems != null) {
      _recordCacheHit('userGems');
      return gems;
    }
    _recordCacheMiss('userGems');
    return null;
  }

  /// Cache gem details
  void cacheGemDetails(String gemId, Gemstone gem) {
    _gemDetailsCache.put(gemId, gem);
    _recordCacheOperation('gemDetails', 'write');
  }

  /// Get cached gem details
  Gemstone? getCachedGemDetails(String gemId) {
    final gem = _gemDetailsCache.get(gemId);
    if (gem != null) {
      _recordCacheHit('gemDetails');
      return gem;
    }
    _recordCacheMiss('gemDetails');
    return null;
  }

  /// Cache user statistics
  void cacheUserStats(String userId, Map<String, dynamic> stats) {
    _userStatsCache.put(userId, Map<String, dynamic>.from(stats));
    _recordCacheOperation('userStats', 'write');
    GemsDebugUtils.log('PerformanceOptimizer', 'Cached stats for user $userId');
  }

  /// Get cached user statistics
  Map<String, dynamic>? getCachedUserStats(String userId) {
    final stats = _userStatsCache.get(userId);
    if (stats != null) {
      _recordCacheHit('userStats');
      return Map<String, dynamic>.from(stats);
    }
    _recordCacheMiss('userStats');
    return null;
  }

  /// Cache unlock status
  void cacheUnlockStatus(String userId, String gemId, bool isUnlocked) {
    final key = '${userId}_$gemId';
    _unlockStatusCache.put(key, isUnlocked);
    _recordCacheOperation('unlockStatus', 'write');
  }

  /// Get cached unlock status
  bool? getCachedUnlockStatus(String userId, String gemId) {
    final key = '${userId}_$gemId';
    final status = _unlockStatusCache.get(key);
    if (status != null) {
      _recordCacheHit('unlockStatus');
      return status;
    }
    _recordCacheMiss('unlockStatus');
    return null;
  }

  /// Record operation performance
  void recordOperationTime(String operation, Duration duration) {
    _operationTimes.putIfAbsent(operation, () => []);
    _operationTimes[operation]!.add(duration);
    
    // Keep only recent measurements
    if (_operationTimes[operation]!.length > 100) {
      _operationTimes[operation]!.removeAt(0);
    }
    
    GemsDebugUtils.logPerformance('PerformanceOptimizer', operation, duration);
  }

  /// Measure and record operation performance
  Future<T> measureOperation<T>(String operation, Future<T> Function() function) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await function();
      return result;
    } finally {
      stopwatch.stop();
      recordOperationTime(operation, stopwatch.elapsed);
    }
  }

  /// Manage stream subscriptions efficiently
  void manageSubscription(String key, StreamSubscription subscription) {
    // Cancel existing subscription if any
    _activeSubscriptions[key]?.cancel();
    _activeSubscriptions[key] = subscription;
    GemsDebugUtils.log('PerformanceOptimizer', 'Managing subscription: $key');
  }

  /// Cancel a specific subscription
  void cancelSubscription(String key) {
    _activeSubscriptions[key]?.cancel();
    _activeSubscriptions.remove(key);
    GemsDebugUtils.log('PerformanceOptimizer', 'Cancelled subscription: $key');
  }

  /// Preload frequently accessed gems
  Future<void> preloadPopularGems(List<String> gemIds, Future<Gemstone?> Function(String) loader) async {
    final futures = gemIds.map((gemId) async {
      if (_gemDetailsCache.get(gemId) == null) {
        try {
          final gem = await loader(gemId);
          if (gem != null) {
            cacheGemDetails(gemId, gem);
          }
        } catch (e) {
          GemsDebugUtils.logError('PerformanceOptimizer', 'Failed to preload gem $gemId: $e');
        }
      } else {
        GemsDebugUtils.log('PerformanceOptimizer', 'Gem $gemId already cached');
      }
    });
    
    await Future.wait(futures);
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'userGemsCache': {
        'size': _userGemsCache.length,
        'maxSize': _userGemsCache.maxSize,
        'hits': _cacheHits['userGems'] ?? 0,
        'misses': _cacheMisses['userGems'] ?? 0,
      },
      'gemDetailsCache': {
        'size': _gemDetailsCache.length,
        'maxSize': _gemDetailsCache.maxSize,
        'hits': _cacheHits['gemDetails'] ?? 0,
        'misses': _cacheMisses['gemDetails'] ?? 0,
      },
      'userStatsCache': {
        'size': _userStatsCache.length,
        'maxSize': _userStatsCache.maxSize,
        'hits': _cacheHits['userStats'] ?? 0,
        'misses': _cacheMisses['userStats'] ?? 0,
      },
      'unlockStatusCache': {
        'size': _unlockStatusCache.length,
        'maxSize': _unlockStatusCache.maxSize,
        'hits': _cacheHits['unlockStatus'] ?? 0,
        'misses': _cacheMisses['unlockStatus'] ?? 0,
      },
    };
  }

  /// Get performance statistics
  Map<String, dynamic> getPerformanceStats() {
    final stats = <String, dynamic>{};
    
    _operationTimes.forEach((operation, times) {
      if (times.isNotEmpty) {
        final totalMs = times.fold(0, (sum, duration) => sum + duration.inMilliseconds);
        final avgMs = totalMs / times.length;
        final maxMs = times.map((d) => d.inMilliseconds).reduce((a, b) => a > b ? a : b);
        final minMs = times.map((d) => d.inMilliseconds).reduce((a, b) => a < b ? a : b);
        
        stats[operation] = {
          'count': times.length,
          'averageMs': avgMs.round(),
          'maxMs': maxMs,
          'minMs': minMs,
          'totalMs': totalMs,
        };
      }
    });
    
    return stats;
  }

  /// Clear all caches
  void clearAllCaches() {
    _userGemsCache.clear();
    _gemDetailsCache.clear();
    _userStatsCache.clear();
    _unlockStatusCache.clear();
    _cacheHits.clear();
    _cacheMisses.clear();
    GemsDebugUtils.log('PerformanceOptimizer', 'All caches cleared');
  }

  /// Start periodic cache cleanup
  void _startCacheCleanup() {
    _cacheCleanupTimer = Timer.periodic(GemsProductionConfig.cacheRefreshInterval, (timer) {
      _performCacheCleanup();
    });
  }

  /// Start periodic performance reporting
  void _startPerformanceReporting() {
    if (GemsProductionConfig.enablePerformanceMonitoring) {
      _performanceReportTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
        _reportPerformanceMetrics();
      });
    }
  }

  /// Perform cache cleanup
  void _performCacheCleanup() {
    // The LRU caches automatically handle eviction, but we can clean old performance data
    
    // Clean up old performance measurements (keeping only recent ones)
    _operationTimes.forEach((operation, times) {
      if (times.length > 50) {
        times.removeRange(0, times.length - 50);
      }
    });
    
    GemsDebugUtils.log('PerformanceOptimizer', 'Cache cleanup completed');
  }

  /// Report performance metrics
  void _reportPerformanceMetrics() {
    final cacheStats = getCacheStats();
    final perfStats = getPerformanceStats();
    
    GemsDebugUtils.log('PerformanceOptimizer', 'Cache stats: $cacheStats');
    GemsDebugUtils.log('PerformanceOptimizer', 'Performance stats: $perfStats');
  }

  /// Record cache operations for metrics
  void _recordCacheOperation(String cacheType, String operation) {
    // This can be extended for detailed cache analytics
  }

  /// Record cache hit
  void _recordCacheHit(String cacheType) {
    _cacheHits[cacheType] = (_cacheHits[cacheType] ?? 0) + 1;
  }

  /// Record cache miss
  void _recordCacheMiss(String cacheType) {
    _cacheMisses[cacheType] = (_cacheMisses[cacheType] ?? 0) + 1;
  }

  /// Dispose and cleanup
  void dispose() {
    _cacheCleanupTimer?.cancel();
    _performanceReportTimer?.cancel();
    
    // Cancel all subscriptions
    for (final subscription in _activeSubscriptions.values) {
      subscription.cancel();
    }
    _activeSubscriptions.clear();
    
    clearAllCaches();
    GemsDebugUtils.log('PerformanceOptimizer', 'Disposed');
  }
}

/// Simple LRU Cache implementation
class LRUCache<K, V> {
  final int maxSize;
  final LinkedHashMap<K, V> _cache = LinkedHashMap<K, V>();

  LRUCache(this.maxSize);

  V? get(K key) {
    if (!_cache.containsKey(key)) return null;
    
    // Move to end (most recently used)
    final value = _cache.remove(key)!;
    _cache[key] = value;
    return value;
  }

  void put(K key, V value) {
    if (_cache.containsKey(key)) {
      _cache.remove(key);
    } else if (_cache.length >= maxSize) {
      // Remove least recently used (first item)
      _cache.remove(_cache.keys.first);
    }
    
    _cache[key] = value;
  }

  void clear() {
    _cache.clear();
  }

  int get length => _cache.length;
}
