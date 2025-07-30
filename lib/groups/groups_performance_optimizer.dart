// File: groups_performance_optimizer.dart
// Performance optimization utilities for the groups system

import 'dart:async';
import 'dart:collection';
import 'groups_production_config.dart';

/// Performance optimizer for groups system
class GroupsPerformanceOptimizer {
  static final GroupsPerformanceOptimizer _instance = GroupsPerformanceOptimizer._internal();
  factory GroupsPerformanceOptimizer() => _instance;
  GroupsPerformanceOptimizer._internal();

  // Message caching
  final Map<String, List<Map<String, dynamic>>> _messageCache = {};
  final Map<String, DateTime> _messageCacheTimestamps = {};
  
  // Group data caching
  final Map<String, Map<String, dynamic>> _groupCache = {};
  final Map<String, DateTime> _groupCacheTimestamps = {};
  
  // Member data caching
  final Map<String, List<Map<String, dynamic>>> _memberCache = {};
  final Map<String, DateTime> _memberCacheTimestamps = {};
  
  // Analytics caching
  final Map<String, Map<String, dynamic>> _analyticsCache = {};
  final Map<String, DateTime> _analyticsCacheTimestamps = {};
  
  // Performance tracking
  final Map<String, List<Duration>> _operationTimes = {};
  final Queue<String> _recentOperations = Queue<String>();
  
  // Connection pooling
  final Map<String, StreamSubscription> _activeSubscriptions = {};
  Timer? _cleanupTimer;
  
  /// Initialize the performance optimizer
  void initialize() {
    _startCleanupTimer();
    GroupsDebugUtils.log('PerformanceOptimizer', 'Initialized with caching and monitoring');
  }
  
  /// Cache messages for a group
  void cacheMessages(String groupId, List<Map<String, dynamic>> messages) {
    if (messages.length > GroupsProductionConfig.maxMessagesInMemory) {
      // Keep only the most recent messages
      messages = messages.sublist(messages.length - GroupsProductionConfig.maxMessagesInMemory);
    }
    
    _messageCache[groupId] = List.from(messages);
    _messageCacheTimestamps[groupId] = DateTime.now();
    
    GroupsDebugUtils.log('PerformanceOptimizer', 'Cached ${messages.length} messages for group $groupId');
  }
  
  /// Get cached messages for a group
  List<Map<String, dynamic>>? getCachedMessages(String groupId) {
    final timestamp = _messageCacheTimestamps[groupId];
    if (timestamp == null) return null;
    
    final age = DateTime.now().difference(timestamp);
    if (age > GroupsProductionConfig.messageCacheTimeout) {
      _messageCache.remove(groupId);
      _messageCacheTimestamps.remove(groupId);
      return null;
    }
    
    return _messageCache[groupId];
  }
  
  /// Cache group data
  void cacheGroup(String groupId, Map<String, dynamic> groupData) {
    _groupCache[groupId] = Map.from(groupData);
    _groupCacheTimestamps[groupId] = DateTime.now();
    
    GroupsDebugUtils.log('PerformanceOptimizer', 'Cached group data for $groupId');
  }
  
  /// Get cached group data
  Map<String, dynamic>? getCachedGroup(String groupId) {
    final timestamp = _groupCacheTimestamps[groupId];
    if (timestamp == null) return null;
    
    final age = DateTime.now().difference(timestamp);
    if (age > const Duration(minutes: 30)) {
      _groupCache.remove(groupId);
      _groupCacheTimestamps.remove(groupId);
      return null;
    }
    
    return _groupCache[groupId];
  }
  
  /// Cache member data
  void cacheMembers(String groupId, List<Map<String, dynamic>> members) {
    _memberCache[groupId] = List.from(members);
    _memberCacheTimestamps[groupId] = DateTime.now();
    
    GroupsDebugUtils.log('PerformanceOptimizer', 'Cached ${members.length} members for group $groupId');
  }
  
  /// Get cached member data
  List<Map<String, dynamic>>? getCachedMembers(String groupId) {
    final timestamp = _memberCacheTimestamps[groupId];
    if (timestamp == null) return null;
    
    final age = DateTime.now().difference(timestamp);
    if (age > const Duration(minutes: 15)) {
      _memberCache.remove(groupId);
      _memberCacheTimestamps.remove(groupId);
      return null;
    }
    
    return _memberCache[groupId];
  }
  
  /// Cache analytics data
  void cacheAnalytics(String groupId, Map<String, dynamic> analytics) {
    _analyticsCache[groupId] = Map.from(analytics);
    _analyticsCacheTimestamps[groupId] = DateTime.now();
    
    GroupsDebugUtils.log('PerformanceOptimizer', 'Cached analytics for group $groupId');
  }
  
  /// Get cached analytics
  Map<String, dynamic>? getCachedAnalytics(String groupId) {
    final timestamp = _analyticsCacheTimestamps[groupId];
    if (timestamp == null) return null;
    
    final age = DateTime.now().difference(timestamp);
    if (age > GroupsProductionConfig.analyticsUpdateInterval) {
      _analyticsCache.remove(groupId);
      _analyticsCacheTimestamps.remove(groupId);
      return null;
    }
    
    return _analyticsCache[groupId];
  }
  
  /// Track operation performance
  void trackOperation(String operation, Duration duration) {
    _operationTimes.putIfAbsent(operation, () => <Duration>[]);
    _operationTimes[operation]!.add(duration);
    
    // Keep only recent measurements
    if (_operationTimes[operation]!.length > 50) {
      _operationTimes[operation]!.removeAt(0);
    }
    
    _recentOperations.add('$operation: ${duration.inMilliseconds}ms');
    if (_recentOperations.length > 100) {
      _recentOperations.removeFirst();
    }
    
    GroupsDebugUtils.logPerformance('PerformanceOptimizer', operation, duration);
  }
  
  /// Get average performance for an operation
  Duration? getAveragePerformance(String operation) {
    final times = _operationTimes[operation];
    if (times == null || times.isEmpty) return null;
    
    final totalMs = times.fold<int>(0, (sum, duration) => sum + duration.inMilliseconds);
    return Duration(milliseconds: totalMs ~/ times.length);
  }
  
  /// Manage real-time subscriptions
  void manageSubscription(String key, StreamSubscription subscription) {
    // Cancel existing subscription if any
    _activeSubscriptions[key]?.cancel();
    
    _activeSubscriptions[key] = subscription;
    GroupsDebugUtils.log('PerformanceOptimizer', 'Managing subscription: $key');
  }
  
  /// Cancel subscription
  void cancelSubscription(String key) {
    _activeSubscriptions[key]?.cancel();
    _activeSubscriptions.remove(key);
    GroupsDebugUtils.log('PerformanceOptimizer', 'Cancelled subscription: $key');
  }
  
  /// Optimize message loading
  List<Map<String, dynamic>> optimizeMessageBatch(List<Map<String, dynamic>> messages) {
    // Sort by timestamp
    messages.sort((a, b) {
      final aTime = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime.now();
      final bTime = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime.now();
      return bTime.compareTo(aTime);
    });
    
    // Remove duplicates
    final seen = <String>{};
    messages = messages.where((message) {
      final id = message['id'] ?? '';
      if (seen.contains(id)) return false;
      seen.add(id);
      return true;
    }).toList();
    
    return messages;
  }
  
  /// Get performance metrics
  Map<String, dynamic> getPerformanceMetrics() {
    final metrics = <String, dynamic>{};
    
    // Cache statistics
    metrics['cache_stats'] = {
      'message_cache_size': _messageCache.length,
      'group_cache_size': _groupCache.length,
      'member_cache_size': _memberCache.length,
      'analytics_cache_size': _analyticsCache.length,
    };
    
    // Performance statistics
    metrics['performance_stats'] = <String, dynamic>{};
    _operationTimes.forEach((operation, times) {
      if (times.isNotEmpty) {
        final totalMs = times.fold<int>(0, (sum, duration) => sum + duration.inMilliseconds);
        metrics['performance_stats'][operation] = {
          'count': times.length,
          'average_ms': totalMs ~/ times.length,
          'total_ms': totalMs,
        };
      }
    });
    
    // Active subscriptions
    metrics['active_subscriptions'] = _activeSubscriptions.length;
    
    return metrics;
  }
  
  /// Clear all caches
  void clearCaches() {
    _messageCache.clear();
    _messageCacheTimestamps.clear();
    _groupCache.clear();
    _groupCacheTimestamps.clear();
    _memberCache.clear();
    _memberCacheTimestamps.clear();
    _analyticsCache.clear();
    _analyticsCacheTimestamps.clear();
    
    GroupsDebugUtils.log('PerformanceOptimizer', 'All caches cleared');
  }
  
  /// Start cleanup timer
  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _cleanupExpiredCaches();
    });
  }
  
  /// Cleanup expired caches
  void _cleanupExpiredCaches() {
    final now = DateTime.now();
    
    // Clean message caches
    _messageCacheTimestamps.removeWhere((groupId, timestamp) {
      final expired = now.difference(timestamp) > GroupsProductionConfig.messageCacheTimeout;
      if (expired) {
        _messageCache.remove(groupId);
      }
      return expired;
    });
    
    // Clean group caches
    _groupCacheTimestamps.removeWhere((groupId, timestamp) {
      final expired = now.difference(timestamp) > const Duration(minutes: 30);
      if (expired) {
        _groupCache.remove(groupId);
      }
      return expired;
    });
    
    // Clean member caches
    _memberCacheTimestamps.removeWhere((groupId, timestamp) {
      final expired = now.difference(timestamp) > const Duration(minutes: 15);
      if (expired) {
        _memberCache.remove(groupId);
      }
      return expired;
    });
    
    // Clean analytics caches
    _analyticsCacheTimestamps.removeWhere((groupId, timestamp) {
      final expired = now.difference(timestamp) > GroupsProductionConfig.analyticsUpdateInterval;
      if (expired) {
        _analyticsCache.remove(groupId);
      }
      return expired;
    });
    
    GroupsDebugUtils.log('PerformanceOptimizer', 'Cleanup completed');
  }
  
  /// Dispose resources
  void dispose() {
    _cleanupTimer?.cancel();
    _activeSubscriptions.values.forEach((subscription) => subscription.cancel());
    _activeSubscriptions.clear();
    clearCaches();
    
    GroupsDebugUtils.log('PerformanceOptimizer', 'Disposed');
  }
}
