// Production Configuration for Crystal Social
// This file contains all production-ready settings and utilities

import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;

/// Production configuration for the Crystal Social app
class ProductionConfig {
  // Environment detection
  static const bool isProduction = bool.fromEnvironment('dart.vm.product');
  static const bool isDebug = kDebugMode;
  static const bool isRelease = kReleaseMode;
  
  // Logging configuration
  static const bool enableDetailedLogging = !isProduction;
  static const bool enableCrashReporting = isProduction;
  static const bool enableAnalytics = isProduction;
  
  // Performance settings
  static const int maxCacheSize = isProduction ? 50 : 100; // MB
  static const Duration cacheTimeout = Duration(hours: isProduction ? 24 : 1);
  static const int maxRetryAttempts = isProduction ? 5 : 3;
  static const Duration retryDelay = Duration(seconds: isProduction ? 10 : 5);
  
  // Security settings
  static const bool enableBiometricAuth = isProduction;
  static const bool enforceSSL = isProduction;
  static const Duration sessionTimeout = Duration(hours: isProduction ? 12 : 24);
  
  // Feature flags
  static const bool enableExperimentalFeatures = !isProduction;
  static const bool enableBetaFeatures = !isProduction;
  static const bool enableDeveloperTools = !isProduction;
  
  // API configuration
  static const Duration apiTimeout = Duration(seconds: isProduction ? 30 : 60);
  static const int maxConcurrentRequests = isProduction ? 10 : 20;
  
  // Memory management
  static const int maxImageCacheSize = isProduction ? 100 : 200; // Number of images
  static const Duration imageCacheTimeout = Duration(hours: isProduction ? 24 : 12);
  
  // Database settings
  static const int maxDatabaseConnections = isProduction ? 5 : 10;
  static const Duration databaseTimeout = Duration(seconds: isProduction ? 15 : 30);
}

/// Production-safe logging utility
class ProductionLogger {
  static void log(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    if (ProductionConfig.isProduction) {
      // In production, only log errors to crash reporting
      if (error != null) {
        _logToAnalytics(message, error: error, stackTrace: stackTrace);
      }
    } else {
      // In development, log everything
      final logMessage = tag != null ? '[$tag] $message' : message;
      if (error != null) {
        developer.log(logMessage, error: error, stackTrace: stackTrace);
      } else {
        developer.log(logMessage);
      }
    }
  }
  
  static void logError(String message, Object error, {StackTrace? stackTrace, String? tag}) {
    if (ProductionConfig.isProduction) {
      _logToAnalytics(message, error: error, stackTrace: stackTrace);
    } else {
      final logMessage = tag != null ? '[$tag] ERROR: $message' : 'ERROR: $message';
      developer.log(logMessage, error: error, stackTrace: stackTrace);
    }
  }
  
  static void logInfo(String message, {String? tag}) {
    if (ProductionConfig.enableDetailedLogging) {
      log(message, tag: tag);
    }
  }
  
  static void logWarning(String message, {String? tag}) {
    if (ProductionConfig.enableDetailedLogging) {
      log('WARNING: $message', tag: tag);
    }
  }
  
  static void _logToAnalytics(String message, {Object? error, StackTrace? stackTrace}) {
    // TODO: Implement actual crash reporting service integration
    // Example: FirebaseCrashlytics.instance.recordError(error, stackTrace, reason: message);
    // For now, just log to console in non-production builds
    if (!ProductionConfig.isProduction) {
      developer.log('ANALYTICS: $message', error: error, stackTrace: stackTrace);
    }
  }
}

/// Production error handler
class ProductionErrorHandler {
  static void handleError(Object error, StackTrace stackTrace, {String? context}) {
    final message = context != null ? 'Error in $context' : 'Unhandled error';
    ProductionLogger.logError(message, error, stackTrace: stackTrace);
    
    if (ProductionConfig.enableCrashReporting) {
      _reportToCrashService(error, stackTrace, context);
    }
  }
  
  static void _reportToCrashService(Object error, StackTrace stackTrace, String? context) {
    // TODO: Implement actual crash reporting
    // Example: FirebaseCrashlytics.instance.recordError(error, stackTrace, reason: context);
    ProductionLogger.logInfo('Crash reported: ${error.toString()}');
  }
  
  static void setup() {
    if (ProductionConfig.isProduction) {
      // Set up global error handling for production
      FlutterError.onError = (FlutterErrorDetails details) {
        handleError(details.exception, details.stack ?? StackTrace.current, 
                   context: details.context?.toString());
      };
    }
  }
}

/// Production analytics helper
class ProductionAnalytics {
  static void trackEvent(String eventName, {Map<String, dynamic>? parameters}) {
    if (ProductionConfig.enableAnalytics) {
      ProductionLogger.logInfo('Analytics Event: $eventName', tag: 'ANALYTICS');
      // TODO: Implement actual analytics tracking
      // Example: FirebaseAnalytics.instance.logEvent(name: eventName, parameters: parameters);
    }
  }
  
  static void trackScreen(String screenName) {
    if (ProductionConfig.enableAnalytics) {
      ProductionLogger.logInfo('Screen View: $screenName', tag: 'ANALYTICS');
      // TODO: Implement actual screen tracking
      // Example: FirebaseAnalytics.instance.logScreenView(screenName: screenName);
    }
  }
  
  static void setUserProperty(String name, String value) {
    if (ProductionConfig.enableAnalytics) {
      ProductionLogger.logInfo('User Property: $name = $value', tag: 'ANALYTICS');
      // TODO: Implement actual user property setting
      // Example: FirebaseAnalytics.instance.setUserProperty(name: name, value: value);
    }
  }
}

/// Production performance monitor
class ProductionPerformanceMonitor {
  static final Map<String, DateTime> _operationStartTimes = {};
  
  static void startOperation(String operationName) {
    if (ProductionConfig.enableDetailedLogging) {
      _operationStartTimes[operationName] = DateTime.now();
      ProductionLogger.logInfo('Started: $operationName', tag: 'PERF');
    }
  }
  
  static void endOperation(String operationName) {
    if (ProductionConfig.enableDetailedLogging && _operationStartTimes.containsKey(operationName)) {
      final startTime = _operationStartTimes.remove(operationName)!;
      final duration = DateTime.now().difference(startTime);
      ProductionLogger.logInfo('Completed: $operationName in ${duration.inMilliseconds}ms', tag: 'PERF');
      
      // Track slow operations
      if (duration.inMilliseconds > 1000) {
        ProductionLogger.logWarning('Slow operation detected: $operationName took ${duration.inMilliseconds}ms', tag: 'PERF');
      }
    }
  }
}
