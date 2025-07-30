// File: butterfly_performance_optimizer.dart
// Performance optimization and caching for the butterfly garden system

import 'dart:collection';
import 'butterfly_production_config.dart';

/// Advanced caching system for butterfly performance optimization
class ButterflyPerformanceOptimizer {
  static final ButterflyPerformanceOptimizer _instance = ButterflyPerformanceOptimizer._internal();
  factory ButterflyPerformanceOptimizer() => _instance;
  ButterflyPerformanceOptimizer._internal();
  
  // Cache configuration
  static const int _maxButterflyDataCacheSize = 100;
  static const int _maxUserDataCacheSize = 50;
  static const int _maxSearchCacheSize = 30;
  static const int _maxAudioCacheSize = 20;
  static const Duration _cacheExpiration = Duration(minutes: 30);
  
  // Multi-level LRU caches
  final LinkedHashMap<String, CachedButterflyData> _butterflyDataCache = LinkedHashMap();
  final LinkedHashMap<String, CachedUserData> _userDataCache = LinkedHashMap();
  final LinkedHashMap<String, CachedSearchResult> _searchCache = LinkedHashMap();
  final LinkedHashMap<String, CachedAudio> _audioCache = LinkedHashMap();
  
  // Performance monitoring
  int _cacheHits = 0;
  int _cacheMisses = 0;
  int _totalRequests = 0;
  
  /// Butterfly data caching
  void cacheButterflyData(String butterflyId, Map<String, dynamic> data) {
    if (!ButterflyProductionConfig.enablePerformanceMonitoring) return;
    
    _manageButterflyDataCacheSize();
    
    _butterflyDataCache[butterflyId] = CachedButterflyData(
      data: Map<String, dynamic>.from(data),
      timestamp: DateTime.now(),
    );
    
    ButterflyDebugUtils.log('PerformanceOptimizer', 'Cached butterfly data: $butterflyId');
  }
  
  Map<String, dynamic>? getCachedButterflyData(String butterflyId) {
    _totalRequests++;
    
    final cached = _butterflyDataCache[butterflyId];
    if (cached != null && !_isExpired(cached.timestamp)) {
      _cacheHits++;
      _butterflyDataCache.remove(butterflyId);
      _butterflyDataCache[butterflyId] = cached; // Move to end (LRU)
      
      ButterflyDebugUtils.log('PerformanceOptimizer', 'Butterfly data cache hit: $butterflyId');
      return cached.data;
    }
    
    _cacheMisses++;
    if (cached != null) {
      _butterflyDataCache.remove(butterflyId);
      ButterflyDebugUtils.log('PerformanceOptimizer', 'Butterfly data cache expired: $butterflyId');
    }
    
    return null;
  }
  
  /// User data caching (unlocked butterflies, favorites, etc.)
  void cacheUserData(String userId, Map<String, dynamic> userData) {
    if (!ButterflyProductionConfig.enablePerformanceMonitoring) return;
    
    _manageUserDataCacheSize();
    
    _userDataCache[userId] = CachedUserData(
      data: Map<String, dynamic>.from(userData),
      timestamp: DateTime.now(),
    );
    
    ButterflyDebugUtils.log('PerformanceOptimizer', 'Cached user data: $userId');
  }
  
  Map<String, dynamic>? getCachedUserData(String userId) {
    _totalRequests++;
    
    final cached = _userDataCache[userId];
    if (cached != null && !_isExpired(cached.timestamp)) {
      _cacheHits++;
      _userDataCache.remove(userId);
      _userDataCache[userId] = cached; // Move to end (LRU)
      
      ButterflyDebugUtils.log('PerformanceOptimizer', 'User data cache hit: $userId');
      return cached.data;
    }
    
    _cacheMisses++;
    if (cached != null) {
      _userDataCache.remove(userId);
      ButterflyDebugUtils.log('PerformanceOptimizer', 'User data cache expired: $userId');
    }
    
    return null;
  }
  
  /// Search results caching
  void cacheSearchResult(String query, List<dynamic> results) {
    if (!ButterflyProductionConfig.enablePerformanceMonitoring) return;
    
    _manageSearchCacheSize();
    
    final cacheKey = _generateSearchCacheKey(query);
    _searchCache[cacheKey] = CachedSearchResult(
      results: List<dynamic>.from(results),
      timestamp: DateTime.now(),
    );
    
    ButterflyDebugUtils.log('PerformanceOptimizer', 'Cached search result: $query');
  }
  
  List<dynamic>? getCachedSearchResult(String query) {
    _totalRequests++;
    
    final cacheKey = _generateSearchCacheKey(query);
    final cached = _searchCache[cacheKey];
    if (cached != null && !_isExpired(cached.timestamp)) {
      _cacheHits++;
      _searchCache.remove(cacheKey);
      _searchCache[cacheKey] = cached; // Move to end (LRU)
      
      ButterflyDebugUtils.log('PerformanceOptimizer', 'Search cache hit: $query');
      return cached.results;
    }
    
    _cacheMisses++;
    if (cached != null) {
      _searchCache.remove(cacheKey);
      ButterflyDebugUtils.log('PerformanceOptimizer', 'Search cache expired: $query');
    }
    
    return null;
  }
  
  /// Audio caching
  void cacheAudio(String audioKey, dynamic audioPlayer) {
    if (!ButterflyProductionConfig.enablePerformanceMonitoring) return;
    
    _manageAudioCacheSize();
    
    _audioCache[audioKey] = CachedAudio(
      player: audioPlayer,
      timestamp: DateTime.now(),
    );
    
    ButterflyDebugUtils.logAudio('PerformanceOptimizer', audioKey, 'cached');
  }
  
  dynamic getCachedAudio(String audioKey) {
    _totalRequests++;
    
    final cached = _audioCache[audioKey];
    if (cached != null && !_isExpired(cached.timestamp)) {
      _cacheHits++;
      _audioCache.remove(audioKey);
      _audioCache[audioKey] = cached; // Move to end (LRU)
      
      ButterflyDebugUtils.logAudio('PerformanceOptimizer', audioKey, 'cache hit');
      return cached.player;
    }
    
    _cacheMisses++;
    if (cached != null) {
      _audioCache.remove(audioKey);
      ButterflyDebugUtils.logAudio('PerformanceOptimizer', audioKey, 'cache expired');
    }
    
    return null;
  }
  
  /// Cache management methods
  void _manageButterflyDataCacheSize() {
    while (_butterflyDataCache.length >= _maxButterflyDataCacheSize) {
      final oldestKey = _butterflyDataCache.keys.first;
      _butterflyDataCache.remove(oldestKey);
      ButterflyDebugUtils.log('PerformanceOptimizer', 'Evicted butterfly data cache: $oldestKey');
    }
  }
  
  void _manageUserDataCacheSize() {
    while (_userDataCache.length >= _maxUserDataCacheSize) {
      final oldestKey = _userDataCache.keys.first;
      _userDataCache.remove(oldestKey);
      ButterflyDebugUtils.log('PerformanceOptimizer', 'Evicted user data cache: $oldestKey');
    }
  }
  
  void _manageSearchCacheSize() {
    while (_searchCache.length >= _maxSearchCacheSize) {
      final oldestKey = _searchCache.keys.first;
      _searchCache.remove(oldestKey);
      ButterflyDebugUtils.log('PerformanceOptimizer', 'Evicted search cache: $oldestKey');
    }
  }
  
  void _manageAudioCacheSize() {
    while (_audioCache.length >= _maxAudioCacheSize) {
      final oldestKey = _audioCache.keys.first;
      _audioCache.remove(oldestKey);
      ButterflyDebugUtils.logAudio('PerformanceOptimizer', oldestKey, 'evicted from cache');
    }
  }
  
  String _generateSearchCacheKey(String query) {
    return query.toLowerCase().trim();
  }
  
  bool _isExpired(DateTime timestamp) {
    return DateTime.now().difference(timestamp) > _cacheExpiration;
  }
  
  /// Cache invalidation
  void invalidateButterflyData(String butterflyId) {
    _butterflyDataCache.remove(butterflyId);
    ButterflyDebugUtils.log('PerformanceOptimizer', 'Invalidated butterfly data cache: $butterflyId');
  }
  
  void invalidateUserData(String userId) {
    _userDataCache.remove(userId);
    ButterflyDebugUtils.log('PerformanceOptimizer', 'Invalidated user data cache: $userId');
  }
  
  void invalidateSearchCache() {
    _searchCache.clear();
    ButterflyDebugUtils.log('PerformanceOptimizer', 'Cleared search cache');
  }
  
  void invalidateAllAudio() {
    _audioCache.clear();
    ButterflyDebugUtils.logAudio('PerformanceOptimizer', 'all', 'cleared cache');
  }
  
  void clearAllCaches() {
    _butterflyDataCache.clear();
    _userDataCache.clear();
    _searchCache.clear();
    _audioCache.clear();
    
    _cacheHits = 0;
    _cacheMisses = 0;
    _totalRequests = 0;
    
    ButterflyDebugUtils.log('PerformanceOptimizer', 'Cleared all caches');
  }
  
  /// Performance statistics
  Map<String, dynamic> getPerformanceStats() {
    final hitRate = _totalRequests > 0 ? (_cacheHits / _totalRequests) * 100 : 0.0;
    
    return {
      'cache_hits': _cacheHits,
      'cache_misses': _cacheMisses,
      'total_requests': _totalRequests,
      'hit_rate_percentage': hitRate.toStringAsFixed(2),
      'butterfly_data_cache_size': _butterflyDataCache.length,
      'user_data_cache_size': _userDataCache.length,
      'search_cache_size': _searchCache.length,
      'audio_cache_size': _audioCache.length,
    };
  }
  
  void logPerformanceStats() {
    final stats = getPerformanceStats();
    ButterflyDebugUtils.logPerformance('PerformanceOptimizer', 'Cache Stats', 
        Duration(milliseconds: 0));
    ButterflyDebugUtils.log('PerformanceOptimizer', 
        'Hit Rate: ${stats['hit_rate_percentage']}% '
        '(${stats['cache_hits']}/${stats['total_requests']})');
    ButterflyDebugUtils.log('PerformanceOptimizer', 
        'Cache Sizes - Butterfly: ${stats['butterfly_data_cache_size']}, '
        'User: ${stats['user_data_cache_size']}, '
        'Search: ${stats['search_cache_size']}, '
        'Audio: ${stats['audio_cache_size']}');
  }
  
  /// Memory optimization
  void optimizeMemoryUsage() {
    // Remove expired entries
    final now = DateTime.now();
    
    _butterflyDataCache.removeWhere((key, cached) {
      final expired = now.difference(cached.timestamp) > _cacheExpiration;
      if (expired) {
        ButterflyDebugUtils.log('PerformanceOptimizer', 'Removed expired butterfly data: $key');
      }
      return expired;
    });
    
    _userDataCache.removeWhere((key, cached) {
      final expired = now.difference(cached.timestamp) > _cacheExpiration;
      if (expired) {
        ButterflyDebugUtils.log('PerformanceOptimizer', 'Removed expired user data: $key');
      }
      return expired;
    });
    
    _searchCache.removeWhere((key, cached) {
      final expired = now.difference(cached.timestamp) > _cacheExpiration;
      if (expired) {
        ButterflyDebugUtils.log('PerformanceOptimizer', 'Removed expired search: $key');
      }
      return expired;
    });
    
    _audioCache.removeWhere((key, cached) {
      final expired = now.difference(cached.timestamp) > _cacheExpiration;
      if (expired) {
        ButterflyDebugUtils.logAudio('PerformanceOptimizer', key, 'expired and removed');
      }
      return expired;
    });
    
    ButterflyDebugUtils.log('PerformanceOptimizer', 'Memory optimization completed');
  }
  
  /// Image precaching optimization
  void trackImagePrecaching(String imagePath, bool success) {
    if (ButterflyProductionConfig.enablePerformanceMonitoring) {
      if (success) {
        ButterflyDebugUtils.log('PerformanceOptimizer', 'Image precached: $imagePath');
      } else {
        ButterflyDebugUtils.logWarning('PerformanceOptimizer', 'Image precaching failed: $imagePath');
      }
    }
  }
}

/// Cached data structures
class CachedButterflyData {
  final Map<String, dynamic> data;
  final DateTime timestamp;
  
  CachedButterflyData({required this.data, required this.timestamp});
}

class CachedUserData {
  final Map<String, dynamic> data;
  final DateTime timestamp;
  
  CachedUserData({required this.data, required this.timestamp});
}

class CachedSearchResult {
  final List<dynamic> results;
  final DateTime timestamp;
  
  CachedSearchResult({required this.results, required this.timestamp});
}

class CachedAudio {
  final dynamic player;
  final DateTime timestamp;
  
  CachedAudio({required this.player, required this.timestamp});
}

/// Performance monitoring utilities for butterfly system
class ButterflyPerformanceMonitor {
  static final Map<String, DateTime> _operationStartTimes = {};
  static final Map<String, List<Duration>> _operationDurations = {};
  
  static void startOperation(String operationId) {
    _operationStartTimes[operationId] = DateTime.now();
    ButterflyDebugUtils.log('PerformanceMonitor', 'Started operation: $operationId');
  }
  
  static void endOperation(String operationId) {
    final startTime = _operationStartTimes[operationId];
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      
      _operationDurations.putIfAbsent(operationId, () => []);
      _operationDurations[operationId]!.add(duration);
      
      ButterflyDebugUtils.logPerformance('PerformanceMonitor', operationId, duration);
      _operationStartTimes.remove(operationId);
    }
  }
  
  static Map<String, dynamic> getOperationStats(String operationId) {
    final durations = _operationDurations[operationId] ?? [];
    if (durations.isEmpty) {
      return {'operation': operationId, 'count': 0};
    }
    
    final totalMs = durations.fold(0, (sum, d) => sum + d.inMilliseconds);
    final avgMs = totalMs / durations.length;
    final minMs = durations.map((d) => d.inMilliseconds).reduce((a, b) => a < b ? a : b);
    final maxMs = durations.map((d) => d.inMilliseconds).reduce((a, b) => a > b ? a : b);
    
    return {
      'operation': operationId,
      'count': durations.length,
      'total_ms': totalMs,
      'average_ms': avgMs.toStringAsFixed(2),
      'min_ms': minMs,
      'max_ms': maxMs,
    };
  }
  
  static void logAllStats() {
    ButterflyDebugUtils.log('PerformanceMonitor', '=== Butterfly Performance Statistics ===');
    for (final operationId in _operationDurations.keys) {
      final stats = getOperationStats(operationId);
      ButterflyDebugUtils.log('PerformanceMonitor', 
          '${stats['operation']}: ${stats['count']} ops, '
          'avg: ${stats['average_ms']}ms, '
          'min: ${stats['min_ms']}ms, '
          'max: ${stats['max_ms']}ms');
    }
    ButterflyDebugUtils.log('PerformanceMonitor', '========================================');
  }
  
  static void clearStats() {
    _operationStartTimes.clear();
    _operationDurations.clear();
    ButterflyDebugUtils.log('PerformanceMonitor', 'Cleared all performance stats');
  }
}

/// Animation performance optimizer
class ButterflyAnimationOptimizer {
  static final Map<String, bool> _animationStates = {};
  
  static bool canStartAnimation(String animationId) {
    return !(_animationStates[animationId] ?? false);
  }
  
  static void markAnimationStarted(String animationId) {
    _animationStates[animationId] = true;
    ButterflyDebugUtils.log('AnimationOptimizer', 'Animation started: $animationId');
  }
  
  static void markAnimationFinished(String animationId) {
    _animationStates[animationId] = false;
    ButterflyDebugUtils.log('AnimationOptimizer', 'Animation finished: $animationId');
  }
  
  static void clearAnimationStates() {
    _animationStates.clear();
    ButterflyDebugUtils.log('AnimationOptimizer', 'Cleared animation states');
  }
  
  static Map<String, bool> getAnimationStates() {
    return Map<String, bool>.from(_animationStates);
  }
}
