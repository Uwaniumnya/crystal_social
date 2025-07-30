// File: groups_exports.dart
// Centralized exports for groups system components

// Production infrastructure (import for internal use)
import 'groups_production_config.dart';
import 'groups_performance_optimizer.dart';
import 'groups_validator.dart';

// Core groups functionality
export 'groups_integration.dart';
export 'group_utils.dart';
export 'group_navigation_helper.dart';

// UI screens
export 'group_list_screen.dart';
export 'group_chat_screen.dart';
export 'group_settings_screen.dart';
export 'create_group_chat.dart';

// Messaging system
export 'group_message_service.dart';
export 'group_message_analyzer.dart';

// Production infrastructure
export 'groups_production_config.dart';
export 'groups_performance_optimizer.dart';
export 'groups_validator.dart';

/// Groups system information and utilities
class GroupsSystemInfo {
  static const String version = '2.1.0';
  static const String buildDate = '2025-01-27';
  static const String description = 'Production-ready groups system with advanced messaging and analytics';
  
  static const Map<String, dynamic> features = {
    'real_time_messaging': true,
    'group_analytics': true,
    'message_analysis': true,
    'smart_reactions': true,
    'group_gems': true,
    'media_sharing': true,
    'push_notifications': true,
    'typing_indicators': true,
    'message_editing': true,
    'message_reactions': true,
    'auto_moderation': true,
    'performance_optimization': true,
  };
  
  static const Map<String, int> systemLimits = {
    'max_groups_per_user': 20,
    'max_members_per_group': 100,
    'max_message_length': 1000,
    'max_media_size_mb': 10,
  };
  
  /// Get system status
  static Map<String, dynamic> getSystemStatus() {
    return {
      'version': version,
      'build_date': buildDate,
      'description': description,
      'features': features,
      'limits': systemLimits,
      'production_ready': true,
      'debug_enabled': !GroupsProductionConfig.isProduction,
      'performance_monitoring': true,
    };
  }
  
  /// Get component list
  static List<String> getComponents() {
    return [
      'GroupsIntegration - Core integration hub',
      'GroupListScreen - Groups listing interface',
      'GroupChatScreen - Chat interface with enhanced features',
      'GroupSettingsScreen - Group management interface',
      'CreateGroupChat - Group creation workflow',
      'GroupMessageService - Real-time messaging service',
      'GroupMessageAnalyzer - Advanced message analysis',
      'GroupUtils - Utility functions',
      'GroupNavigationHelper - Navigation utilities',
      'GroupsProductionConfig - Production configuration',
      'GroupsPerformanceOptimizer - Performance optimization',
      'GroupsValidator - Production readiness validation',
    ];
  }
}

/// Event tracking for groups system
class GroupsEventTracker {
  static final List<Map<String, dynamic>> _events = [];
  
  static void trackEvent(String event, Map<String, dynamic> data) {
    if (!GroupsProductionConfig.enableDebugLogging) return;
    
    _events.add({
      'event': event,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    // Keep only recent events
    if (_events.length > 100) {
      _events.removeAt(0);
    }
    
    GroupsDebugUtils.log('EventTracker', 'Event: $event');
  }
  
  static List<Map<String, dynamic>> getEvents() {
    return List.from(_events);
  }
  
  static void clearEvents() {
    _events.clear();
  }
}

/// Common groups system utilities
class GroupsSystemUtils {
  /// Initialize the groups system
  static Future<void> initialize() async {
    try {
      // Initialize performance optimizer
      final optimizer = GroupsPerformanceOptimizer();
      optimizer.initialize();
      
      // Track initialization
      GroupsEventTracker.trackEvent('system_initialize', {
        'version': GroupsSystemInfo.version,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      GroupsDebugUtils.logSuccess('SystemUtils', 'Groups system initialized successfully');
    } catch (e) {
      GroupsDebugUtils.logError('SystemUtils', 'Failed to initialize groups system: $e');
      rethrow;
    }
  }
  
  /// Validate system health
  static Future<Map<String, dynamic>> checkHealth() async {
    try {
      final validation = await GroupsValidator.validateProductionReadiness();
      
      GroupsEventTracker.trackEvent('health_check', {
        'status': validation['overall_status'],
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      return validation;
    } catch (e) {
      GroupsDebugUtils.logError('SystemUtils', 'Health check failed: $e');
      return {
        'overall_status': 'error',
        'error': e.toString(),
      };
    }
  }
  
  /// Get performance metrics
  static Map<String, dynamic> getPerformanceMetrics() {
    final optimizer = GroupsPerformanceOptimizer();
    return optimizer.getPerformanceMetrics();
  }
  
  /// Cleanup system resources
  static void cleanup() {
    try {
      final optimizer = GroupsPerformanceOptimizer();
      optimizer.dispose();
      GroupsEventTracker.clearEvents();
      
      GroupsDebugUtils.log('SystemUtils', 'Groups system cleanup completed');
    } catch (e) {
      GroupsDebugUtils.logError('SystemUtils', 'Cleanup failed: $e');
    }
  }
}
