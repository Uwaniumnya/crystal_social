// File: garden_performance_optimizer.dart
// Performance optimization and caching for the crystal garden system

import 'dart:collection';
import 'garden_production_config.dart';

/// Advanced caching system for garden performance optimization
class GardenPerformanceOptimizer {
  static final GardenPerformanceOptimizer _instance = GardenPerformanceOptimizer._internal();
  factory GardenPerformanceOptimizer() => _instance;
  GardenPerformanceOptimizer._internal();
  
  // Cache configuration
  static const int _maxGardenCacheSize = 50;
  static const int _maxFlowerCacheSize = 200;
  static const int _maxUserCacheSize = 100;
  static const int _maxAudioCacheSize = 30;
  static const Duration _cacheExpiration = Duration(minutes: 30);
  
  // Multi-level LRU caches
  final LinkedHashMap<String, CachedGarden> _gardenCache = LinkedHashMap();
  final LinkedHashMap<String, CachedFlower> _flowerCache = LinkedHashMap();
  final LinkedHashMap<String, CachedUserData> _userDataCache = LinkedHashMap();
  final LinkedHashMap<String, CachedAudio> _audioCache = LinkedHashMap();
  
  // Performance monitoring
  int _cacheHits = 0;
  int _cacheMisses = 0;
  int _totalRequests = 0;
  
  /// Garden data caching
  void cacheGarden(String gardenId, Map<String, dynamic> gardenData) {
    if (!GardenProductionConfig.enablePerformanceMonitoring) return;
    
    _manageGardenCacheSize();
    
    _gardenCache[gardenId] = CachedGarden(
      data: Map<String, dynamic>.from(gardenData),
      timestamp: DateTime.now(),
    );
    
    GardenDebugUtils.log('PerformanceOptimizer', 'Cached garden data: $gardenId');
  }
  
  Map<String, dynamic>? getCachedGarden(String gardenId) {
    _totalRequests++;
    
    final cached = _gardenCache[gardenId];
    if (cached != null && !_isExpired(cached.timestamp)) {
      _cacheHits++;
      _gardenCache.remove(gardenId);
      _gardenCache[gardenId] = cached; // Move to end (LRU)
      
      GardenDebugUtils.log('PerformanceOptimizer', 'Garden cache hit: $gardenId');
      return cached.data;
    }
    
    _cacheMisses++;
    if (cached != null) {
      _gardenCache.remove(gardenId);
      GardenDebugUtils.log('PerformanceOptimizer', 'Garden cache expired: $gardenId');
    }
    
    return null;
  }
  
  /// Flower data caching
  void cacheFlower(String flowerId, Map<String, dynamic> flowerData) {
    if (!GardenProductionConfig.enablePerformanceMonitoring) return;
    
    _manageFlowerCacheSize();
    
    _flowerCache[flowerId] = CachedFlower(
      data: Map<String, dynamic>.from(flowerData),
      timestamp: DateTime.now(),
    );
    
    GardenDebugUtils.log('PerformanceOptimizer', 'Cached flower data: $flowerId');
  }
  
  Map<String, dynamic>? getCachedFlower(String flowerId) {
    _totalRequests++;
    
    final cached = _flowerCache[flowerId];
    if (cached != null && !_isExpired(cached.timestamp)) {
      _cacheHits++;
      _flowerCache.remove(flowerId);
      _flowerCache[flowerId] = cached; // Move to end (LRU)
      
      GardenDebugUtils.log('PerformanceOptimizer', 'Flower cache hit: $flowerId');
      return cached.data;
    }
    
    _cacheMisses++;
    if (cached != null) {
      _flowerCache.remove(flowerId);
      GardenDebugUtils.log('PerformanceOptimizer', 'Flower cache expired: $flowerId');
    }
    
    return null;
  }
  
  /// User data caching
  void cacheUserData(String userId, Map<String, dynamic> userData) {
    if (!GardenProductionConfig.enablePerformanceMonitoring) return;
    
    _manageUserCacheSize();
    
    _userDataCache[userId] = CachedUserData(
      data: Map<String, dynamic>.from(userData),
      timestamp: DateTime.now(),
    );
    
    GardenDebugUtils.log('PerformanceOptimizer', 'Cached user data: $userId');
  }
  
  Map<String, dynamic>? getCachedUserData(String userId) {
    _totalRequests++;
    
    final cached = _userDataCache[userId];
    if (cached != null && !_isExpired(cached.timestamp)) {
      _cacheHits++;
      _userDataCache.remove(userId);
      _userDataCache[userId] = cached; // Move to end (LRU)
      
      GardenDebugUtils.log('PerformanceOptimizer', 'User data cache hit: $userId');
      return cached.data;
    }
    
    _cacheMisses++;
    if (cached != null) {
      _userDataCache.remove(userId);
      GardenDebugUtils.log('PerformanceOptimizer', 'User data cache expired: $userId');
    }
    
    return null;
  }
  
  /// Audio caching
  void cacheAudio(String audioKey, dynamic audioPlayer) {
    if (!GardenProductionConfig.enablePerformanceMonitoring) return;
    
    _manageAudioCacheSize();
    
    _audioCache[audioKey] = CachedAudio(
      player: audioPlayer,
      timestamp: DateTime.now(),
    );
    
    GardenDebugUtils.logAudio('PerformanceOptimizer', audioKey, 'cached');
  }
  
  dynamic getCachedAudio(String audioKey) {
    _totalRequests++;
    
    final cached = _audioCache[audioKey];
    if (cached != null && !_isExpired(cached.timestamp)) {
      _cacheHits++;
      _audioCache.remove(audioKey);
      _audioCache[audioKey] = cached; // Move to end (LRU)
      
      GardenDebugUtils.logAudio('PerformanceOptimizer', audioKey, 'cache hit');
      return cached.player;
    }
    
    _cacheMisses++;
    if (cached != null) {
      _audioCache.remove(audioKey);
      GardenDebugUtils.logAudio('PerformanceOptimizer', audioKey, 'cache expired');
    }
    
    return null;
  }
  
  /// Cache management methods
  void _manageGardenCacheSize() {
    while (_gardenCache.length >= _maxGardenCacheSize) {
      final oldestKey = _gardenCache.keys.first;
      _gardenCache.remove(oldestKey);
      GardenDebugUtils.log('PerformanceOptimizer', 'Evicted garden cache: $oldestKey');
    }
  }
  
  void _manageFlowerCacheSize() {
    while (_flowerCache.length >= _maxFlowerCacheSize) {
      final oldestKey = _flowerCache.keys.first;
      _flowerCache.remove(oldestKey);
      GardenDebugUtils.log('PerformanceOptimizer', 'Evicted flower cache: $oldestKey');
    }
  }
  
  void _manageUserCacheSize() {
    while (_userDataCache.length >= _maxUserCacheSize) {
      final oldestKey = _userDataCache.keys.first;
      _userDataCache.remove(oldestKey);
      GardenDebugUtils.log('PerformanceOptimizer', 'Evicted user cache: $oldestKey');
    }
  }
  
  void _manageAudioCacheSize() {
    while (_audioCache.length >= _maxAudioCacheSize) {
      final oldestKey = _audioCache.keys.first;
      _audioCache.remove(oldestKey);
      GardenDebugUtils.logAudio('PerformanceOptimizer', oldestKey, 'evicted from cache');
    }
  }
  
  bool _isExpired(DateTime timestamp) {
    return DateTime.now().difference(timestamp) > _cacheExpiration;
  }
  
  /// Cache invalidation
  void invalidateGarden(String gardenId) {
    _gardenCache.remove(gardenId);
    GardenDebugUtils.log('PerformanceOptimizer', 'Invalidated garden cache: $gardenId');
  }
  
  void invalidateFlower(String flowerId) {
    _flowerCache.remove(flowerId);
    GardenDebugUtils.log('PerformanceOptimizer', 'Invalidated flower cache: $flowerId');
  }
  
  void invalidateUser(String userId) {
    _userDataCache.remove(userId);
    GardenDebugUtils.log('PerformanceOptimizer', 'Invalidated user cache: $userId');
  }
  
  void invalidateAllAudio() {
    _audioCache.clear();
    GardenDebugUtils.logAudio('PerformanceOptimizer', 'all', 'cleared cache');
  }
  
  void clearAllCaches() {
    _gardenCache.clear();
    _flowerCache.clear();
    _userDataCache.clear();
    _audioCache.clear();
    
    _cacheHits = 0;
    _cacheMisses = 0;
    _totalRequests = 0;
    
    GardenDebugUtils.log('PerformanceOptimizer', 'Cleared all caches');
  }
  
  /// Performance statistics
  Map<String, dynamic> getPerformanceStats() {
    final hitRate = _totalRequests > 0 ? (_cacheHits / _totalRequests) * 100 : 0.0;
    
    return {
      'cache_hits': _cacheHits,
      'cache_misses': _cacheMisses,
      'total_requests': _totalRequests,
      'hit_rate_percentage': hitRate.toStringAsFixed(2),
      'garden_cache_size': _gardenCache.length,
      'flower_cache_size': _flowerCache.length,
      'user_cache_size': _userDataCache.length,
      'audio_cache_size': _audioCache.length,
    };
  }
  
  void logPerformanceStats() {
    final stats = getPerformanceStats();
    GardenDebugUtils.logPerformance('PerformanceOptimizer', 'Cache Stats', 
        Duration(milliseconds: 0));
    GardenDebugUtils.log('PerformanceOptimizer', 
        'Hit Rate: ${stats['hit_rate_percentage']}% '
        '(${stats['cache_hits']}/${stats['total_requests']})');
    GardenDebugUtils.log('PerformanceOptimizer', 
        'Cache Sizes - Gardens: ${stats['garden_cache_size']}, '
        'Flowers: ${stats['flower_cache_size']}, '
        'Users: ${stats['user_cache_size']}, '
        'Audio: ${stats['audio_cache_size']}');
  }
  
  /// Memory optimization
  void optimizeMemoryUsage() {
    // Remove expired entries
    final now = DateTime.now();
    
    _gardenCache.removeWhere((key, cached) {
      final expired = now.difference(cached.timestamp) > _cacheExpiration;
      if (expired) {
        GardenDebugUtils.log('PerformanceOptimizer', 'Removed expired garden: $key');
      }
      return expired;
    });
    
    _flowerCache.removeWhere((key, cached) {
      final expired = now.difference(cached.timestamp) > _cacheExpiration;
      if (expired) {
        GardenDebugUtils.log('PerformanceOptimizer', 'Removed expired flower: $key');
      }
      return expired;
    });
    
    _userDataCache.removeWhere((key, cached) {
      final expired = now.difference(cached.timestamp) > _cacheExpiration;
      if (expired) {
        GardenDebugUtils.log('PerformanceOptimizer', 'Removed expired user: $key');
      }
      return expired;
    });
    
    _audioCache.removeWhere((key, cached) {
      final expired = now.difference(cached.timestamp) > _cacheExpiration;
      if (expired) {
        GardenDebugUtils.logAudio('PerformanceOptimizer', key, 'expired and removed');
      }
      return expired;
    });
    
    GardenDebugUtils.log('PerformanceOptimizer', 'Memory optimization completed');
  }
}

/// Cached data structures
class CachedGarden {
  final Map<String, dynamic> data;
  final DateTime timestamp;
  
  CachedGarden({required this.data, required this.timestamp});
}

class CachedFlower {
  final Map<String, dynamic> data;
  final DateTime timestamp;
  
  CachedFlower({required this.data, required this.timestamp});
}

class CachedUserData {
  final Map<String, dynamic> data;
  final DateTime timestamp;
  
  CachedUserData({required this.data, required this.timestamp});
}

class CachedAudio {
  final dynamic player;
  final DateTime timestamp;
  
  CachedAudio({required this.player, required this.timestamp});
}

/// Performance monitoring utilities
class GardenPerformanceMonitor {
  static final Map<String, DateTime> _operationStartTimes = {};
  static final Map<String, List<Duration>> _operationDurations = {};
  
  static void startOperation(String operationId) {
    _operationStartTimes[operationId] = DateTime.now();
    GardenDebugUtils.log('PerformanceMonitor', 'Started operation: $operationId');
  }
  
  static void endOperation(String operationId) {
    final startTime = _operationStartTimes[operationId];
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      
      _operationDurations.putIfAbsent(operationId, () => []);
      _operationDurations[operationId]!.add(duration);
      
      GardenDebugUtils.logPerformance('PerformanceMonitor', operationId, duration);
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
    GardenDebugUtils.log('PerformanceMonitor', '=== Performance Statistics ===');
    for (final operationId in _operationDurations.keys) {
      final stats = getOperationStats(operationId);
      GardenDebugUtils.log('PerformanceMonitor', 
          '${stats['operation']}: ${stats['count']} ops, '
          'avg: ${stats['average_ms']}ms, '
          'min: ${stats['min_ms']}ms, '
          'max: ${stats['max_ms']}ms');
    }
    GardenDebugUtils.log('PerformanceMonitor', '=============================');
  }
  
  static void clearStats() {
    _operationStartTimes.clear();
    _operationDurations.clear();
    GardenDebugUtils.log('PerformanceMonitor', 'Cleared all performance stats');
  }
}
