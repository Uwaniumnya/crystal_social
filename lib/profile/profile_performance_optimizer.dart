import 'dart:async';
import 'dart:collection';
import 'profile_production_config.dart';

/// Performance optimizer for profile-related operations
class ProfilePerformanceOptimizer {
  static final ProfilePerformanceOptimizer _instance = ProfilePerformanceOptimizer._internal();
  factory ProfilePerformanceOptimizer() => _instance;
  ProfilePerformanceOptimizer._internal();

  // Cache management
  final Map<String, dynamic> _profileCache = HashMap();
  final Map<String, DateTime> _cacheTimestamps = HashMap();
  final Map<String, Timer> _cacheTimers = HashMap();
  
  // Performance monitoring
  final Map<String, List<Duration>> _operationTimes = HashMap();
  final Map<String, int> _operationCounts = HashMap();
  
  // Image and media cache
  final Map<String, dynamic> _imageCache = HashMap();
  final Map<String, dynamic> _soundCache = HashMap();
  
  /// Cache profile data with automatic expiration
  void cacheProfile(String userId, Map<String, dynamic> profile) {
    if (!ProfileProductionConfig.isProduction || 
        _profileCache.length >= ProfileProductionConfig.maxCacheSize) {
      return;
    }
    
    _profileCache[userId] = Map.from(profile);
    _cacheTimestamps[userId] = DateTime.now();
    
    // Set up automatic cache expiration
    _cacheTimers[userId]?.cancel();
    _cacheTimers[userId] = Timer(
      Duration(seconds: ProfileProductionConfig.cacheTimeout),
      () => _evictProfile(userId),
    );
    
    ProfileDebugUtils.logCacheOperation('STORE', userId, false);
  }
  
  /// Retrieve cached profile data
  Map<String, dynamic>? getCachedProfile(String userId) {
    final cached = _profileCache[userId];
    final timestamp = _cacheTimestamps[userId];
    
    if (cached != null && timestamp != null) {
      final age = DateTime.now().difference(timestamp);
      if (age.inSeconds < ProfileProductionConfig.cacheTimeout) {
        ProfileDebugUtils.logCacheOperation('RETRIEVE', userId, true);
        return Map.from(cached);
      } else {
        _evictProfile(userId);
      }
    }
    
    ProfileDebugUtils.logCacheOperation('RETRIEVE', userId, false);
    return null;
  }
  
  /// Evict profile from cache
  void _evictProfile(String userId) {
    _profileCache.remove(userId);
    _cacheTimestamps.remove(userId);
    _cacheTimers[userId]?.cancel();
    _cacheTimers.remove(userId);
    
    ProfileDebugUtils.logCacheOperation('EVICT', userId, false);
  }
  
  /// Cache image data
  void cacheImage(String url, dynamic imageData) {
    if (_imageCache.length >= ProfileProductionConfig.maxDecorationCacheSize) {
      // Remove oldest entry
      final oldestKey = _imageCache.keys.first;
      _imageCache.remove(oldestKey);
    }
    
    _imageCache[url] = imageData;
    ProfileDebugUtils.logCacheOperation('IMAGE_STORE', url, false);
  }
  
  /// Get cached image data
  dynamic getCachedImage(String url) {
    final cached = _imageCache[url];
    ProfileDebugUtils.logCacheOperation('IMAGE_RETRIEVE', url, cached != null);
    return cached;
  }
  
  /// Cache sound data
  void cacheSound(String soundId, dynamic soundData) {
    if (_soundCache.length >= ProfileProductionConfig.maxCustomSounds) {
      // Remove oldest entry
      final oldestKey = _soundCache.keys.first;
      _soundCache.remove(oldestKey);
    }
    
    _soundCache[soundId] = soundData;
    ProfileDebugUtils.logCacheOperation('SOUND_STORE', soundId, false);
  }
  
  /// Get cached sound data
  dynamic getCachedSound(String soundId) {
    final cached = _soundCache[soundId];
    ProfileDebugUtils.logCacheOperation('SOUND_RETRIEVE', soundId, cached != null);
    return cached;
  }
  
  /// Track operation performance
  void trackOperation(String operation, Duration duration) {
    if (!ProfileProductionConfig.enablePerformanceMonitoring) return;
    
    _operationTimes.putIfAbsent(operation, () => []).add(duration);
    _operationCounts[operation] = (_operationCounts[operation] ?? 0) + 1;
    
    ProfileDebugUtils.logPerformance(operation, duration);
    
    // Keep only recent measurements
    final times = _operationTimes[operation]!;
    if (times.length > 100) {
      times.removeRange(0, times.length - 100);
    }
  }
  
  /// Get average operation time
  Duration? getAverageOperationTime(String operation) {
    final times = _operationTimes[operation];
    if (times == null || times.isEmpty) return null;
    
    final totalMs = times.fold<int>(0, (sum, duration) => sum + duration.inMilliseconds);
    return Duration(milliseconds: totalMs ~/ times.length);
  }
  
  /// Get operation statistics
  Map<String, dynamic> getOperationStats(String operation) {
    final times = _operationTimes[operation] ?? [];
    final count = _operationCounts[operation] ?? 0;
    
    if (times.isEmpty) {
      return {'count': count, 'average_ms': 0, 'min_ms': 0, 'max_ms': 0};
    }
    
    final durations = times.map((d) => d.inMilliseconds).toList()..sort();
    
    return {
      'count': count,
      'average_ms': durations.fold<int>(0, (sum, ms) => sum + ms) ~/ durations.length,
      'min_ms': durations.first,
      'max_ms': durations.last,
      'median_ms': durations[durations.length ~/ 2],
    };
  }
  
  /// Batch operations for better performance
  Future<List<T>> batchOperation<T>(
    List<Future<T> Function()> operations, {
    int batchSize = 5,
    Duration delay = const Duration(milliseconds: 10),
  }) async {
    final results = <T>[];
    
    for (int i = 0; i < operations.length; i += batchSize) {
      final batch = operations.skip(i).take(batchSize);
      final batchResults = await Future.wait(batch.map((op) => op()));
      results.addAll(batchResults);
      
      // Small delay between batches to prevent overwhelming the system
      if (i + batchSize < operations.length) {
        await Future.delayed(delay);
      }
    }
    
    return results;
  }
  
  /// Preload critical profile data
  Future<void> preloadCriticalData(String userId) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // This would be implemented to preload essential profile data
      ProfileDebugUtils.conditionalLog('Preloading critical data for user: $userId');
      
      // Simulate preloading operations
      await Future.delayed(const Duration(milliseconds: 100));
      
    } catch (e) {
      ProfileDebugUtils.logError('preloadCriticalData', e);
    } finally {
      stopwatch.stop();
      trackOperation('preload_critical_data', stopwatch.elapsed);
    }
  }
  
  /// Clear all caches
  void clearAllCaches() {
    _profileCache.clear();
    _cacheTimestamps.clear();
    _cacheTimers.values.forEach((timer) => timer.cancel());
    _cacheTimers.clear();
    _imageCache.clear();
    _soundCache.clear();
    
    ProfileDebugUtils.conditionalLog('All profile caches cleared');
  }
  
  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'profile_cache_size': _profileCache.length,
      'image_cache_size': _imageCache.length,
      'sound_cache_size': _soundCache.length,
      'active_timers': _cacheTimers.length,
      'total_operations': _operationCounts.values.fold<int>(0, (sum, count) => sum + count),
      'tracked_operations': _operationTimes.keys.toList(),
    };
  }
  
  /// Optimize memory usage
  void optimizeMemory() {
    // Remove expired cache entries
    final now = DateTime.now();
    final expiredKeys = _cacheTimestamps.entries
        .where((entry) => now.difference(entry.value).inSeconds > ProfileProductionConfig.cacheTimeout)
        .map((entry) => entry.key)
        .toList();
    
    for (final key in expiredKeys) {
      _evictProfile(key);
    }
    
    // Trim operation history
    _operationTimes.forEach((operation, times) {
      if (times.length > 50) {
        _operationTimes[operation] = times.sublist(times.length - 50);
      }
    });
    
    ProfileDebugUtils.conditionalLog('Memory optimization completed, removed ${expiredKeys.length} expired entries');
  }
  
  /// Dispose resources
  void dispose() {
    _cacheTimers.values.forEach((timer) => timer.cancel());
    clearAllCaches();
    _operationTimes.clear();
    _operationCounts.clear();
  }
}
