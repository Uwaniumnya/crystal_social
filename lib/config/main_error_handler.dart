// Production Error Handler
// Centralized error handling and reporting for production builds

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../config/production_config.dart';
import '../config/environment_config.dart';

/// Centralized error handler for production builds
class MainErrorHandler {
  static bool _isInitialized = false;
  
  /// Initialize the error handler
  static void initialize() {
    if (_isInitialized) return;
    
    // Set up Flutter error handling
    FlutterError.onError = handleFlutterError;
    
    // Set up platform error handling
    PlatformDispatcher.instance.onError = handlePlatformError;
    
    _isInitialized = true;
    ProductionLogger.logInfo('Error handler initialized', tag: 'ERROR_HANDLER');
  }
  
  /// Handle Flutter framework errors
  static void handleFlutterError(FlutterErrorDetails details) {
    final errorContext = details.context?.toString() ?? 'Unknown context';
    final errorMessage = 'Flutter Error in $errorContext: ${details.exception}';
    
    ProductionLogger.logError(
      errorMessage,
      details.exception,
      stackTrace: details.stack,
      tag: 'FLUTTER_ERROR',
    );
    
    if (EnvironmentConfig.enableCrashReporting) {
      _reportToCrashService(
        details.exception,
        details.stack ?? StackTrace.current,
        context: errorContext,
        isFatal: false,
      );
    }
    
    // In development, also show the error on screen
    if (EnvironmentConfig.isDevelopment) {
      FlutterError.presentError(details);
    }
  }
  
  /// Handle platform-level errors
  static bool handlePlatformError(Object error, StackTrace stack) {
    final errorMessage = 'Platform Error: ${error.toString()}';
    
    ProductionLogger.logError(
      errorMessage,
      error,
      stackTrace: stack,
      tag: 'PLATFORM_ERROR',
    );
    
    if (EnvironmentConfig.enableCrashReporting) {
      _reportToCrashService(
        error,
        stack,
        context: 'Platform Error',
        isFatal: true,
      );
    }
    
    // Return true to prevent the error from being re-thrown
    return true;
  }
  
  /// Handle async errors
  static void handleAsyncError(Object error, StackTrace stack, {String? context}) {
    final errorMessage = context != null 
        ? 'Async Error in $context: ${error.toString()}'
        : 'Async Error: ${error.toString()}';
    
    ProductionLogger.logError(
      errorMessage,
      error,
      stackTrace: stack,
      tag: 'ASYNC_ERROR',
    );
    
    if (EnvironmentConfig.enableCrashReporting) {
      _reportToCrashService(
        error,
        stack,
        context: context ?? 'Async Operation',
        isFatal: false,
      );
    }
  }
  
  /// Handle network errors specifically
  static void handleNetworkError(Object error, StackTrace stack, {String? endpoint}) {
    final errorMessage = endpoint != null 
        ? 'Network Error for $endpoint: ${error.toString()}'
        : 'Network Error: ${error.toString()}';
    
    ProductionLogger.logError(
      errorMessage,
      error,
      stackTrace: stack,
      tag: 'NETWORK_ERROR',
    );
    
    if (EnvironmentConfig.enableCrashReporting) {
      _reportToCrashService(
        error,
        stack,
        context: endpoint ?? 'Network Request',
        isFatal: false,
      );
    }
  }
  
  /// Handle database errors specifically
  static void handleDatabaseError(Object error, StackTrace stack, {String? operation}) {
    final errorMessage = operation != null 
        ? 'Database Error in $operation: ${error.toString()}'
        : 'Database Error: ${error.toString()}';
    
    ProductionLogger.logError(
      errorMessage,
      error,
      stackTrace: stack,
      tag: 'DATABASE_ERROR',
    );
    
    if (EnvironmentConfig.enableCrashReporting) {
      _reportToCrashService(
        error,
        stack,
        context: operation ?? 'Database Operation',
        isFatal: false,
      );
    }
  }
  
  /// Handle authentication errors
  static void handleAuthError(Object error, StackTrace stack, {String? operation}) {
    final errorMessage = operation != null 
        ? 'Auth Error in $operation: ${error.toString()}'
        : 'Auth Error: ${error.toString()}';
    
    ProductionLogger.logError(
      errorMessage,
      error,
      stackTrace: stack,
      tag: 'AUTH_ERROR',
    );
    
    if (EnvironmentConfig.enableCrashReporting) {
      _reportToCrashService(
        error,
        stack,
        context: operation ?? 'Authentication',
        isFatal: false,
      );
    }
  }
  
  /// Report error to crash reporting service
  static void _reportToCrashService(
    Object error, 
    StackTrace stack, {
    String? context,
    bool isFatal = false,
  }) {
    try {
      // TODO: Implement actual crash reporting service
      // Example implementations:
      
      // Firebase Crashlytics:
      // FirebaseCrashlytics.instance.recordError(
      //   error,
      //   stack,
      //   reason: context,
      //   fatal: isFatal,
      // );
      
      // Sentry:
      // Sentry.captureException(
      //   error,
      //   stackTrace: stack,
      //   withScope: (scope) {
      //     scope.setTag('context', context ?? 'unknown');
      //     scope.setLevel(isFatal ? SentryLevel.fatal : SentryLevel.error);
      //   },
      // );
      
      // For now, just log that we would report it
      ProductionLogger.logInfo(
        'Would report to crash service: ${error.toString()}',
        tag: 'CRASH_REPORTING',
      );
    } catch (reportingError) {
      ProductionLogger.logError(
        'Failed to report error to crash service',
        reportingError,
        tag: 'CRASH_REPORTING',
      );
    }
  }
  
  /// Safely execute an operation with error handling
  static Future<T?> safeExecute<T>(
    Future<T> Function() operation, {
    String? context,
    T? fallback,
  }) async {
    try {
      return await operation();
    } catch (error, stack) {
      handleAsyncError(error, stack, context: context);
      return fallback;
    }
  }
  
  /// Safely execute a synchronous operation with error handling
  static T? safeExecuteSync<T>(
    T Function() operation, {
    String? context,
    T? fallback,
  }) {
    try {
      return operation();
    } catch (error, stack) {
      handleAsyncError(error, stack, context: context);
      return fallback;
    }
  }
  
  /// Show user-friendly error dialog (only in development)
  static void showErrorDialog(BuildContext context, String message) {
    if (EnvironmentConfig.isDevelopment) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Development Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
  
  /// Check if error handler is properly initialized
  static bool get isInitialized => _isInitialized;
}
