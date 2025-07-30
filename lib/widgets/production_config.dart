import 'package:flutter/foundation.dart';

/// Production configuration utility for Crystal Social widgets
/// Manages environment-specific settings and feature flags
class WidgetProductionConfig {
  static const bool _isProduction = kReleaseMode;
  
  /// Whether debug features should be enabled
  static bool get enableDebugFeatures => !_isProduction;
  
  /// Whether test widgets should be shown
  static bool get showTestWidgets => !_isProduction;
  
  /// Whether detailed logging should be enabled
  static bool get enableDetailedLogging => !_isProduction;
  
  /// Whether performance monitoring should be enabled
  static bool get enablePerformanceMonitoring => _isProduction;
  
  /// Whether analytics should be enabled
  static bool get enableAnalytics => _isProduction;
  
  /// Whether crash reporting should be enabled
  static bool get enableCrashReporting => _isProduction;
  
  /// Maximum cache size for images and media
  static int get maxCacheSize => _isProduction ? 100 * 1024 * 1024 : 50 * 1024 * 1024; // 100MB prod, 50MB debug
  
  /// Network timeout duration
  static Duration get networkTimeout => _isProduction 
    ? const Duration(seconds: 30) 
    : const Duration(seconds: 60);
  
  /// Maximum file upload size
  static int get maxUploadSize => _isProduction ? 10 * 1024 * 1024 : 50 * 1024 * 1024; // 10MB prod, 50MB debug
  
  /// Whether to use production API endpoints
  static bool get useProductionEndpoints => _isProduction;
  
  /// Whether to show performance overlays
  static bool get showPerformanceOverlay => !_isProduction;
  
  /// Logging configuration
  static void configureLogging() {
    if (!_isProduction) {
      // Debug logging configuration
      debugPrint('Debug mode: Detailed logging enabled');
    }
  }
  
  /// Get environment name
  static String get environmentName => _isProduction ? 'production' : 'development';
  
  /// Check if a feature flag is enabled
  static bool isFeatureEnabled(String featureName) {
    // In production, all features should be stable
    if (_isProduction) {
      return _productionFeatures.contains(featureName);
    }
    
    // In development, allow experimental features
    return _developmentFeatures.contains(featureName) || 
           _productionFeatures.contains(featureName);
  }
  
  /// Production-ready features
  static const Set<String> _productionFeatures = {
    'message_bubble',
    'emoticon_picker',
    'background_picker',
    'sticker_picker',
    'glimmer_upload',
    'coin_earning',
    'local_storage',
    'message_analysis',
    'push_notifications',
    'avatar_decorations',
    'chat_backgrounds',
    'media_viewer',
    'gemdex',
    'rewards_system',
  };
  
  /// Development/experimental features
  static const Set<String> _developmentFeatures = {
    'debug_widgets',
    'test_notifications',
    'device_tracking_debug',
    'performance_monitor',
    'network_logger',
    'state_inspector',
  };
  
  /// Get widget configuration for environment
  static Map<String, dynamic> getWidgetConfig(String widgetName) {
    final baseConfig = {
      'enableAnimations': true,
      'enableHapticFeedback': true,
      'enableSoundEffects': _isProduction,
      'maxRetries': _isProduction ? 3 : 5,
      'cacheDuration': _isProduction 
        ? const Duration(hours: 1) 
        : const Duration(minutes: 30),
    };
    
    // Widget-specific configurations
    switch (widgetName) {
      case 'sticker_picker':
        return {
          ...baseConfig,
          'maxStickersPerCategory': _isProduction ? 50 : 100,
          'enableGifSupport': true,
          'enableCustomUploads': true,
        };
        
      case 'emoticon_picker':
        return {
          ...baseConfig,
          'maxFavorites': _isProduction ? 20 : 50,
          'enableCloudSync': _isProduction,
          'enableCreation': true,
        };
        
      case 'message_bubble':
        return {
          ...baseConfig,
          'enableReactions': true,
          'enableEffects': _isProduction,
          'maxReactionCount': 6,
        };
        
      case 'background_picker':
        return {
          ...baseConfig,
          'maxCustomBackgrounds': _isProduction ? 10 : 20,
          'enableEffects': true,
          'enableBlur': true,
        };
        
      default:
        return baseConfig;
    }
  }
}
