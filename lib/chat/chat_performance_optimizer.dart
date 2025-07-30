// File: chat_performance_optimizer.dart
// Performance optimization utilities for the chat system

import 'dart:async';
import 'dart:collection';
import 'chat_production_config.dart';

/// Performance optimizer for chat system
class ChatPerformanceOptimizer {
  static final ChatPerformanceOptimizer _instance = ChatPerformanceOptimizer._internal();
  factory ChatPerformanceOptimizer() => _instance;
  ChatPerformanceOptimizer._internal();

  // Message caching
  final Map<String, List<Map<String, dynamic>>> _messageCache = {};
  final Map<String, DateTime> _messageCacheTimestamps = {};
  
  // Chat data caching
  final Map<String, List<Map<String, dynamic>>> _chatListCache = {};
  final Map<String, DateTime> _chatListCacheTimestamps = {};
  
  // User data caching
  final Map<String, Map<String, dynamic>> _userCache = {};
  final Map<String, DateTime> _userCacheTimestamps = {};
  
  // Media caching
  final Map<String, String> _mediaCache = {};
  final Map<String, DateTime> _mediaCacheTimestamps = {};
  
  // Performance tracking
  final Map<String, List<Duration>> _operationTimes = {};
  final Queue<String> _recentOperations = Queue<String>();
  
  // Connection pooling
  final Map<String, StreamSubscription> _activeSubscriptions = {};
  Timer? _cleanupTimer;
  
  /// Initialize the performance optimizer
  void initialize() {
    _startCleanupTimer();
    ChatDebugUtils.log('PerformanceOptimizer', 'Initialized with caching and monitoring');
  }
  
  /// Cache messages for a chat
  void cacheMessages(String chatId, List<Map<String, dynamic>> messages) {
    if (messages.length > ChatProductionConfig.maxMessagesInMemory) {
      // Keep only the most recent messages
      messages = messages.sublist(messages.length - ChatProductionConfig.maxMessagesInMemory);
    }
    
    _messageCache[chatId] = List.from(messages);
    _messageCacheTimestamps[chatId] = DateTime.now();
    
    ChatDebugUtils.log('PerformanceOptimizer', 'Cached ${messages.length} messages for chat $chatId');
  }
  
  /// Get cached messages for a chat
  List<Map<String, dynamic>>? getCachedMessages(String chatId) {
    final timestamp = _messageCacheTimestamps[chatId];
    if (timestamp == null) return null;
    
    final age = DateTime.now().difference(timestamp);
    if (age > ChatProductionConfig.messageCacheTimeout) {
      _messageCache.remove(chatId);
      _messageCacheTimestamps.remove(chatId);
      return null;
    }
    
    return _messageCache[chatId];
  }
  
  /// Cache chat list
  void cacheChatList(List<Map<String, dynamic>> chats) {
    if (chats.length > ChatProductionConfig.maxRecentChats) {
      chats = chats.sublist(0, ChatProductionConfig.maxRecentChats);
    }
    
    _chatListCache['recent_chats'] = List.from(chats);
    _chatListCacheTimestamps['recent_chats'] = DateTime.now();
    
    ChatDebugUtils.log('PerformanceOptimizer', 'Cached ${chats.length} recent chats');
  }
  
  /// Get cached chat list
  List<Map<String, dynamic>>? getCachedChatList() {
    final timestamp = _chatListCacheTimestamps['recent_chats'];
    if (timestamp == null) return null;
    
    final age = DateTime.now().difference(timestamp);
    if (age > const Duration(minutes: 10)) {
      _chatListCache.remove('recent_chats');
      _chatListCacheTimestamps.remove('recent_chats');
      return null;
    }
    
    return _chatListCache['recent_chats'];
  }
  
  /// Cache user data
  void cacheUser(String userId, Map<String, dynamic> userData) {
    _userCache[userId] = Map.from(userData);
    _userCacheTimestamps[userId] = DateTime.now();
    
    ChatDebugUtils.log('PerformanceOptimizer', 'Cached user data for $userId');
  }
  
  /// Get cached user data
  Map<String, dynamic>? getCachedUser(String userId) {
    final timestamp = _userCacheTimestamps[userId];
    if (timestamp == null) return null;
    
    final age = DateTime.now().difference(timestamp);
    if (age > const Duration(minutes: 30)) {
      _userCache.remove(userId);
      _userCacheTimestamps.remove(userId);
      return null;
    }
    
    return _userCache[userId];
  }
  
  /// Cache media URL
  void cacheMedia(String mediaId, String mediaUrl) {
    _mediaCache[mediaId] = mediaUrl;
    _mediaCacheTimestamps[mediaId] = DateTime.now();
    
    ChatDebugUtils.log('PerformanceOptimizer', 'Cached media URL for $mediaId');
  }
  
  /// Get cached media URL
  String? getCachedMedia(String mediaId) {
    final timestamp = _mediaCacheTimestamps[mediaId];
    if (timestamp == null) return null;
    
    final age = DateTime.now().difference(timestamp);
    if (age > const Duration(hours: 1)) {
      _mediaCache.remove(mediaId);
      _mediaCacheTimestamps.remove(mediaId);
      return null;
    }
    
    return _mediaCache[mediaId];
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
    
    ChatDebugUtils.logPerformance('PerformanceOptimizer', operation, duration);
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
    ChatDebugUtils.log('PerformanceOptimizer', 'Managing subscription: $key');
  }
  
  /// Cancel subscription
  void cancelSubscription(String key) {
    _activeSubscriptions[key]?.cancel();
    _activeSubscriptions.remove(key);
    ChatDebugUtils.log('PerformanceOptimizer', 'Cancelled subscription: $key');
  }
  
  /// Optimize message batch
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
    
    // Limit batch size
    if (messages.length > ChatProductionConfig.maxMessagesInMemory) {
      messages = messages.sublist(0, ChatProductionConfig.maxMessagesInMemory);
    }
    
    return messages;
  }
  
  /// Preload chat data
  Future<void> preloadChatData(String chatId) async {
    try {
      final stopwatch = Stopwatch()..start();
      
      // Check if already cached
      if (getCachedMessages(chatId) != null) {
        ChatDebugUtils.log('PerformanceOptimizer', 'Chat $chatId already cached');
        return;
      }
      
      // Preload would happen here in a real implementation
      // This is a placeholder for the actual preloading logic
      
      stopwatch.stop();
      trackOperation('preload_chat', stopwatch.elapsed);
      
    } catch (e) {
      ChatDebugUtils.logError('PerformanceOptimizer', 'Failed to preload chat $chatId: $e');
    }
  }
  
  /// Get performance metrics
  Map<String, dynamic> getPerformanceMetrics() {
    final metrics = <String, dynamic>{};
    
    // Cache statistics
    metrics['cache_stats'] = {
      'message_cache_size': _messageCache.length,
      'chat_list_cache_size': _chatListCache.length,
      'user_cache_size': _userCache.length,
      'media_cache_size': _mediaCache.length,
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
    
    // Memory usage estimation
    metrics['memory_stats'] = {
      'estimated_message_cache_kb': _messageCache.length * 2, // Rough estimate
      'estimated_user_cache_kb': _userCache.length * 1, // Rough estimate
      'estimated_media_cache_kb': _mediaCache.length * 0.5, // Rough estimate
    };
    
    return metrics;
  }
  
  /// Clear all caches
  void clearCaches() {
    _messageCache.clear();
    _messageCacheTimestamps.clear();
    _chatListCache.clear();
    _chatListCacheTimestamps.clear();
    _userCache.clear();
    _userCacheTimestamps.clear();
    _mediaCache.clear();
    _mediaCacheTimestamps.clear();
    
    ChatDebugUtils.log('PerformanceOptimizer', 'All caches cleared');
  }
  
  /// Start cleanup timer
  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
      _cleanupExpiredCaches();
    });
  }
  
  /// Cleanup expired caches
  void _cleanupExpiredCaches() {
    final now = DateTime.now();
    
    // Clean message caches
    _messageCacheTimestamps.removeWhere((chatId, timestamp) {
      final expired = now.difference(timestamp) > ChatProductionConfig.messageCacheTimeout;
      if (expired) {
        _messageCache.remove(chatId);
      }
      return expired;
    });
    
    // Clean chat list caches
    _chatListCacheTimestamps.removeWhere((key, timestamp) {
      final expired = now.difference(timestamp) > const Duration(minutes: 10);
      if (expired) {
        _chatListCache.remove(key);
      }
      return expired;
    });
    
    // Clean user caches
    _userCacheTimestamps.removeWhere((userId, timestamp) {
      final expired = now.difference(timestamp) > const Duration(minutes: 30);
      if (expired) {
        _userCache.remove(userId);
      }
      return expired;
    });
    
    // Clean media caches
    _mediaCacheTimestamps.removeWhere((mediaId, timestamp) {
      final expired = now.difference(timestamp) > const Duration(hours: 1);
      if (expired) {
        _mediaCache.remove(mediaId);
      }
      return expired;
    });
    
    ChatDebugUtils.log('PerformanceOptimizer', 'Cache cleanup completed');
  }
  
  /// Dispose resources
  void dispose() {
    _cleanupTimer?.cancel();
    _activeSubscriptions.values.forEach((subscription) => subscription.cancel());
    _activeSubscriptions.clear();
    clearCaches();
    
    ChatDebugUtils.log('PerformanceOptimizer', 'Disposed');
  }
}
