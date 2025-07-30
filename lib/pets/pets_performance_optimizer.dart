import 'dart:async';
import 'dart:collection';
import 'pets_production_config.dart';

/// Performance optimizer for pets-related operations
class PetsPerformanceOptimizer {
  static final PetsPerformanceOptimizer _instance = PetsPerformanceOptimizer._internal();
  factory PetsPerformanceOptimizer() => _instance;
  PetsPerformanceOptimizer._internal();

  // Cache management
  final Map<String, dynamic> _petStateCache = HashMap();
  final Map<String, DateTime> _cacheTimestamps = HashMap();
  final Map<String, Timer> _cacheTimers = HashMap();
  
  // Animation optimization
  final Map<String, dynamic> _animationCache = HashMap();
  final Set<String> _activeAnimations = <String>{};
  
  // Audio optimization
  final Map<String, dynamic> _audioCache = HashMap();
  final Map<String, DateTime> _soundCooldowns = HashMap();
  
  // Performance monitoring
  final Map<String, List<Duration>> _operationTimes = HashMap();
  final Map<String, int> _operationCounts = HashMap();
  
  // Resource management
  final Set<String> _loadedResources = <String>{};
  Timer? _cleanupTimer;
  
  /// Initialize performance optimizer
  void initialize() {
    // Set up periodic cleanup
    _cleanupTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _performCleanup(),
    );
    
    PetsDebugUtils.conditionalLog('PetsPerformanceOptimizer initialized');
  }
  
  /// Cache pet state data
  void cachePetState(String petId, Map<String, dynamic> state) {
    if (!PetsProductionConfig.isProduction || 
        _petStateCache.length >= PetsProductionConfig.maxCacheSize) {
      return;
    }
    
    _petStateCache[petId] = Map.from(state);
    _cacheTimestamps[petId] = DateTime.now();
    
    // Set up automatic cache expiration
    _cacheTimers[petId]?.cancel();
    _cacheTimers[petId] = Timer(
      PetsProductionConfig.autoSaveInterval * 2,
      () => _evictPetState(petId),
    );
    
    PetsDebugUtils.conditionalLog('Cached pet state for: $petId');
  }
  
  /// Retrieve cached pet state
  Map<String, dynamic>? getCachedPetState(String petId) {
    final cached = _petStateCache[petId];
    final timestamp = _cacheTimestamps[petId];
    
    if (cached != null && timestamp != null) {
      final age = DateTime.now().difference(timestamp);
      if (age < PetsProductionConfig.autoSaveInterval * 2) {
        return Map.from(cached);
      } else {
        _evictPetState(petId);
      }
    }
    
    return null;
  }
  
  /// Evict pet state from cache
  void _evictPetState(String petId) {
    _petStateCache.remove(petId);
    _cacheTimestamps.remove(petId);
    _cacheTimers[petId]?.cancel();
    _cacheTimers.remove(petId);
    
    PetsDebugUtils.conditionalLog('Evicted pet state cache for: $petId');
  }
  
  /// Cache animation data
  void cacheAnimation(String animationKey, dynamic animationData) {
    if (_animationCache.length >= PetsProductionConfig.maxAnimationFrames) {
      // Remove oldest animation
      final oldestKey = _animationCache.keys.first;
      _animationCache.remove(oldestKey);
    }
    
    _animationCache[animationKey] = animationData;
    PetsDebugUtils.conditionalLog('Cached animation: $animationKey');
  }
  
  /// Get cached animation data
  dynamic getCachedAnimation(String animationKey) {
    return _animationCache[animationKey];
  }
  
  /// Track active animations
  bool canStartAnimation(String animationId) {
    if (_activeAnimations.length >= PetsProductionConfig.maxConcurrentAnimations) {
      return false;
    }
    
    _activeAnimations.add(animationId);
    PetsDebugUtils.logAnimation('Started', animationId, 'concurrent_check');
    return true;
  }
  
  /// Remove animation from active tracking
  void endAnimation(String animationId) {
    _activeAnimations.remove(animationId);
    PetsDebugUtils.logAnimation('Ended', animationId, 'concurrent_check');
  }
  
  /// Cache audio data
  void cacheAudio(String soundId, dynamic audioData) {
    if (_audioCache.length >= PetsProductionConfig.soundCacheSize) {
      // Remove oldest audio
      final oldestKey = _audioCache.keys.first;
      _audioCache.remove(oldestKey);
    }
    
    _audioCache[soundId] = audioData;
    PetsDebugUtils.logAudio('Cached', soundId, true);
  }
  
  /// Get cached audio data
  dynamic getCachedAudio(String soundId) {
    return _audioCache[soundId];
  }
  
  /// Check sound cooldown
  bool canPlaySound(String petId) {
    final now = DateTime.now();
    final lastSound = _soundCooldowns[petId];
    
    if (lastSound == null) {
      _soundCooldowns[petId] = now;
      return true;
    }
    
    final timeSinceLastSound = now.difference(lastSound);
    if (timeSinceLastSound >= PetsProductionConfig.petSoundCooldown) {
      _soundCooldowns[petId] = now;
      return true;
    }
    
    return false;
  }
  
  /// Track operation performance
  void trackOperation(String operation, Duration duration) {
    if (!PetsProductionConfig.enablePerformanceMonitoring) return;
    
    _operationTimes.putIfAbsent(operation, () => []).add(duration);
    _operationCounts[operation] = (_operationCounts[operation] ?? 0) + 1;
    
    PetsDebugUtils.logPerformance(operation, duration);
    
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
  
  /// Optimize pet state updates
  Future<void> batchPetStateUpdates(List<Map<String, dynamic>> updates) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // Group updates by pet ID
      final Map<String, List<Map<String, dynamic>>> groupedUpdates = {};
      
      for (final update in updates) {
        final petId = update['pet_id'] as String?;
        if (petId != null) {
          groupedUpdates.putIfAbsent(petId, () => []).add(update);
        }
      }
      
      // Process updates in batches
      const batchSize = 10;
      final batches = groupedUpdates.entries.toList();
      
      for (int i = 0; i < batches.length; i += batchSize) {
        final batch = batches.skip(i).take(batchSize);
        
        // Process batch
        for (final entry in batch) {
          final petId = entry.key;
          final petUpdates = entry.value;
          
          // Merge multiple updates for the same pet
          final mergedUpdate = <String, dynamic>{};
          for (final update in petUpdates) {
            mergedUpdate.addAll(update);
          }
          
          // Cache the merged update
          cachePetState(petId, mergedUpdate);
        }
        
        // Small delay between batches
        if (i + batchSize < batches.length) {
          await Future.delayed(const Duration(milliseconds: 10));
        }
      }
      
    } catch (e) {
      PetsDebugUtils.logError('batchPetStateUpdates', e);
    } finally {
      stopwatch.stop();
      trackOperation('batch_pet_state_updates', stopwatch.elapsed);
    }
  }
  
  /// Preload critical pet resources
  Future<void> preloadCriticalResources(List<String> petIds) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      for (final petId in petIds) {
        if (!_loadedResources.contains(petId)) {
          // Simulate preloading pet assets
          await Future.delayed(const Duration(milliseconds: 50));
          _loadedResources.add(petId);
          
          PetsDebugUtils.conditionalLog('Preloaded resources for pet: $petId');
        }
      }
    } catch (e) {
      PetsDebugUtils.logError('preloadCriticalResources', e);
    } finally {
      stopwatch.stop();
      trackOperation('preload_critical_resources', stopwatch.elapsed);
    }
  }
  
  /// Perform periodic cleanup
  void _performCleanup() {
    final now = DateTime.now();
    
    // Clean up expired sound cooldowns
    _soundCooldowns.removeWhere((petId, lastSound) {
      final age = now.difference(lastSound);
      return age > PetsProductionConfig.petSoundCooldown * 2;
    });
    
    // Clean up old operation times
    _operationTimes.forEach((operation, times) {
      if (times.length > 50) {
        _operationTimes[operation] = times.sublist(times.length - 50);
      }
    });
    
    // Clean up unused resources
    if (_loadedResources.length > PetsProductionConfig.maxCacheSize) {
      final excess = _loadedResources.length - PetsProductionConfig.maxCacheSize;
      final toRemove = _loadedResources.take(excess).toList();
      _loadedResources.removeAll(toRemove);
    }
    
    PetsDebugUtils.conditionalLog('Performed cleanup - removed expired data');
  }
  
  /// Get performance statistics
  Map<String, dynamic> getPerformanceStats() {
    return {
      'pet_state_cache_size': _petStateCache.length,
      'animation_cache_size': _animationCache.length,
      'audio_cache_size': _audioCache.length,
      'active_animations': _activeAnimations.length,
      'loaded_resources': _loadedResources.length,
      'sound_cooldowns': _soundCooldowns.length,
      'total_operations': _operationCounts.values.fold<int>(0, (sum, count) => sum + count),
      'tracked_operations': _operationTimes.keys.toList(),
    };
  }
  
  /// Clear all caches
  void clearAllCaches() {
    _petStateCache.clear();
    _cacheTimestamps.clear();
    _cacheTimers.values.forEach((timer) => timer.cancel());
    _cacheTimers.clear();
    _animationCache.clear();
    _activeAnimations.clear();
    _audioCache.clear();
    _soundCooldowns.clear();
    _loadedResources.clear();
    
    PetsDebugUtils.conditionalLog('All pets caches cleared');
  }
  
  /// Dispose resources
  void dispose() {
    _cleanupTimer?.cancel();
    _cacheTimers.values.forEach((timer) => timer.cancel());
    clearAllCaches();
    _operationTimes.clear();
    _operationCounts.clear();
    
    PetsDebugUtils.conditionalLog('PetsPerformanceOptimizer disposed');
  }
}
