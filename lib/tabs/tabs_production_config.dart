import 'package:flutter/foundation.dart';

/// Production configuration utility for Crystal Social tabs
/// Manages environment-specific settings and optimizations for all tab screens
class TabsProductionConfig {
  static const bool _isProduction = kReleaseMode;
  
  /// Whether debug features should be enabled
  static bool get enableDebugFeatures => !_isProduction;
  
  /// Whether mock data should be used
  static bool get useMockData => !_isProduction;
  
  /// Whether detailed analytics should be enabled
  static bool get enableAnalytics => _isProduction;
  
  /// Network timeout for tab-specific requests
  static Duration get networkTimeout => _isProduction 
    ? const Duration(seconds: 15) 
    : const Duration(seconds: 30);
  
  /// Maximum cache size for tab content
  static int get maxCacheSize => _isProduction ? 50 * 1024 * 1024 : 25 * 1024 * 1024; // 50MB prod, 25MB debug
  
  /// Auto-refresh interval for live content
  static Duration get autoRefreshInterval => _isProduction 
    ? const Duration(minutes: 5) 
    : const Duration(minutes: 1);
  
  /// Maximum file upload size for tab content
  static int get maxUploadSize => _isProduction ? 5 * 1024 * 1024 : 20 * 1024 * 1024; // 5MB prod, 20MB debug
  
  /// Whether to enable premium features
  static bool get enablePremiumFeatures => _isProduction;
  
  /// Whether to show performance monitoring
  static bool get showPerformanceMetrics => !_isProduction;
  
  /// Tab-specific configurations
  static Map<String, dynamic> getTabConfig(String tabName) {
    final baseConfig = {
      'enableAnimations': true,
      'enableHapticFeedback': _isProduction,
      'enableSoundEffects': _isProduction,
      'maxRetries': _isProduction ? 3 : 5,
      'cacheDuration': _isProduction 
        ? const Duration(hours: 2) 
        : const Duration(minutes: 15),
    };
    
    switch (tabName) {
      case 'home_screen':
        return {
          ...baseConfig,
          'maxAppsToShow': _isProduction ? 20 : 50,
          'enableShareFeature': _isProduction,
          'enableReferralSystem': _isProduction,
        };
        
      case 'glitter_board':
        return {
          ...baseConfig,
          'maxPostsPerLoad': _isProduction ? 10 : 20,
          'enableImageUploads': true,
          'enableVideoUploads': _isProduction,
          'maxImageSize': _isProduction ? 2 * 1024 * 1024 : 10 * 1024 * 1024,
        };
        
      case 'call_screen':
        return {
          ...baseConfig,
          'maxCallDuration': _isProduction ? const Duration(hours: 2) : const Duration(hours: 24),
          'enableRecording': _isProduction,
          'enableScreenSharing': _isProduction,
          'videoQuality': _isProduction ? 'medium' : 'high',
        };
        
      case 'enhanced_horoscope':
        return {
          ...baseConfig,
          'enablePaidReadings': _isProduction,
          'enableCosmicAnimations': true,
          'maxDailyCoinEarning': _isProduction ? 100 : 1000,
        };
        
      case 'music':
        return {
          ...baseConfig,
          'enableSpotifyIntegration': _isProduction,
          'maxRoomsToShow': _isProduction ? 50 : 100,
          'enableVoiceChat': _isProduction,
        };
        
      case 'information':
        return {
          ...baseConfig,
          'enableCollaborativeEditing': _isProduction,
          'maxDocumentSize': _isProduction ? 1 * 1024 * 1024 : 5 * 1024 * 1024,
          'autoSaveInterval': const Duration(seconds: 30),
        };
        
      default:
        return baseConfig;
    }
  }
  
  /// Check if a tab feature is enabled
  static bool isTabFeatureEnabled(String tabName, String featureName) {
    final config = getTabConfig(tabName);
    return config[featureName] ?? false;
  }
  
  /// Get environment-appropriate API endpoints
  static Map<String, String> getApiEndpoints() {
    if (_isProduction) {
      return {
        'glitter_posts': '/api/v1/glitter/posts',
        'horoscope_data': '/api/v1/horoscope',
        'music_rooms': '/api/v1/music/rooms',
        'call_tokens': '/api/v1/calls/token',
        'user_profiles': '/api/v1/users/profiles',
      };
    } else {
      return {
        'glitter_posts': '/api/dev/glitter/posts',
        'horoscope_data': '/api/dev/horoscope',
        'music_rooms': '/api/dev/music/rooms',
        'call_tokens': '/api/dev/calls/token',
        'user_profiles': '/api/dev/users/profiles',
      };
    }
  }
  
  /// Get mock data configuration
  static Map<String, dynamic> getMockDataConfig() {
    return {
      'useMockData': useMockData,
      'mockPostCount': _isProduction ? 0 : 10,
      'mockUserCount': _isProduction ? 0 : 50,
      'enableMockNotifications': !_isProduction,
      'mockDataRefreshInterval': const Duration(minutes: 5),
    };
  }
  
  /// Performance optimization settings
  static Map<String, dynamic> getPerformanceConfig() {
    return {
      'enableLazyLoading': true,
      'preloadNextPage': _isProduction,
      'imageCompressionQuality': _isProduction ? 0.8 : 0.9,
      'enableImageCaching': true,
      'maxConcurrentRequests': _isProduction ? 3 : 10,
      'enableGZipCompression': _isProduction,
    };
  }
  
  /// Security and privacy settings
  static Map<String, dynamic> getSecurityConfig() {
    return {
      'enableDataEncryption': _isProduction,
      'requireAuthentication': _isProduction,
      'enableBiometricAuth': _isProduction,
      'sessionTimeout': _isProduction 
        ? const Duration(hours: 24) 
        : const Duration(hours: 72),
      'enableAuditLogging': _isProduction,
    };
  }
}

/// Production-safe logging utility for tabs
class TabsLogger {
  static void log(String message, {String? tabName}) {
    if (kDebugMode) {
      final prefix = tabName != null ? '[$tabName] ' : '[TABS] ';
      debugPrint('$prefix$message');
    }
  }
  
  static void logError(String error, {String? tabName, dynamic exception}) {
    if (kDebugMode) {
      final prefix = tabName != null ? '[$tabName] ERROR: ' : '[TABS] ERROR: ';
      debugPrint('$prefix$error');
      if (exception != null) {
        debugPrint('Exception: $exception');
      }
    }
  }
  
  static void logPerformance(String operation, Duration duration, {String? tabName}) {
    if (kDebugMode && TabsProductionConfig.showPerformanceMetrics) {
      final prefix = tabName != null ? '[$tabName] PERF: ' : '[TABS] PERF: ';
      debugPrint('$prefix$operation took ${duration.inMilliseconds}ms');
    }
  }
}

/// Tab performance monitoring utility
class TabsPerformanceMonitor {
  static final Map<String, Stopwatch> _stopwatches = {};
  
  static void startTimer(String operation) {
    if (kDebugMode && TabsProductionConfig.showPerformanceMetrics) {
      _stopwatches[operation] = Stopwatch()..start();
    }
  }
  
  static void endTimer(String operation, {String? tabName}) {
    if (kDebugMode && TabsProductionConfig.showPerformanceMetrics) {
      final stopwatch = _stopwatches[operation];
      if (stopwatch != null) {
        stopwatch.stop();
        TabsLogger.logPerformance(operation, stopwatch.elapsed, tabName: tabName);
        _stopwatches.remove(operation);
      }
    }
  }
  
  static T measureOperation<T>(String operation, T Function() function, {String? tabName}) {
    startTimer(operation);
    try {
      return function();
    } finally {
      endTimer(operation, tabName: tabName);
    }
  }
  
  static Future<T> measureAsyncOperation<T>(String operation, Future<T> Function() function, {String? tabName}) async {
    startTimer(operation);
    try {
      return await function();
    } finally {
      endTimer(operation, tabName: tabName);
    }
  }
}
