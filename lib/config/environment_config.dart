// Production Environment Configuration
// Manages environment-specific settings and secrets

import 'package:flutter/foundation.dart';

/// Environment-specific configuration
class EnvironmentConfig {
  // Environment detection
  static bool get isProduction => kReleaseMode;
  static bool get isDevelopment => kDebugMode;
  static bool get isStaging => const bool.fromEnvironment('STAGING', defaultValue: false);
  
  // Supabase Configuration
  static String get supabaseUrl {
    if (isProduction) {
      return const String.fromEnvironment(
        'SUPABASE_URL_PROD',
        defaultValue: 'https://zdsjtjbzhiejvpuahnlk.supabase.co',
      );
    } else if (isStaging) {
      return const String.fromEnvironment(
        'SUPABASE_URL_STAGING', 
        defaultValue: 'https://zdsjtjbzhiejvpuahnlk.supabase.co',
      );
    } else {
      return const String.fromEnvironment(
        'SUPABASE_URL_DEV',
        defaultValue: 'https://zdsjtjbzhiejvpuahnlk.supabase.co',
      );
    }
  }
  
  static String get supabaseAnonKey {
    if (isProduction) {
      return const String.fromEnvironment(
        'SUPABASE_ANON_KEY_PROD',
        defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inpkc2p0amJ6aGllanZwdWFobmxrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM4MjAyMzYsImV4cCI6MjA2OTM5NjIzNn0.CSPzbngxKJHrHD8oNMFaYzvKXzNzMENFtaWu9Vy2rV0',
      );
    } else if (isStaging) {
      return const String.fromEnvironment(
        'SUPABASE_ANON_KEY_STAGING',
        defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inpkc2p0amJ6aGllanZwdWFobmxrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM4MjAyMzYsImV4cCI6MjA2OTM5NjIzNn0.CSPzbngxKJHrHD8oNMFaYzvKXzNzMENFtaWu9Vy2rV0',
      );
    } else {
      return const String.fromEnvironment(
        'SUPABASE_ANON_KEY_DEV',
        defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inpkc2p0amJ6aGllanZwdWFobmxrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM4MjAyMzYsImV4cCI6MjA2OTM5NjIzNn0.CSPzbngxKJHrHD8oNMFaYzvKXzNzMENFtaWu9Vy2rV0',
      );
    }
  }
  
  static String get supabaseServiceRoleKey {
    if (isProduction) {
      return const String.fromEnvironment(
        'SUPABASE_SERVICE_ROLE_KEY_PROD',
        defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inpkc2p0amJ6aGllanZwdWFobmxrIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MzgyMDIzNiwiZXhwIjoyMDY5Mzk2MjM2fQ.sOTNug5cmkkC3stzFqgw7v8lEVK_c06BgP-hHbsfj8A',
      );
    } else if (isStaging) {
      return const String.fromEnvironment(
        'SUPABASE_SERVICE_ROLE_KEY_STAGING',
        defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inpkc2p0amJ6aGllanZwdWFobmxrIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MzgyMDIzNiwiZXhwIjoyMDY5Mzk2MjM2fQ.sOTNug5cmkkC3stzFqgw7v8lEVK_c06BgP-hHbsfj8A',
      );
    } else {
      return const String.fromEnvironment(
        'SUPABASE_SERVICE_ROLE_KEY_DEV',
        defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inpkc2p0amJ6aGllanZwdWFobmxrIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MzgyMDIzNiwiZXhwIjoyMDY5Mzk2MjM2fQ.sOTNug5cmkkC3stzFqgw7v8lEVK_c06BgP-hHbsfj8A',
      );
    }
  }

  // OneSignal Configuration
  static String get oneSignalAppId {
    if (isProduction) {
      return const String.fromEnvironment(
        'ONESIGNAL_APP_ID_PROD',
        defaultValue: 'production-onesignal-app-id',
      );
    } else if (isStaging) {
      return const String.fromEnvironment(
        'ONESIGNAL_APP_ID_STAGING',
        defaultValue: 'staging-onesignal-app-id',
      );
    } else {
      return const String.fromEnvironment(
        'ONESIGNAL_APP_ID_DEV',
        defaultValue: 'development-onesignal-app-id',
      );
    }
  }
  
  // API Configuration
  static Duration get apiTimeout {
    return isProduction 
        ? const Duration(seconds: 30)
        : const Duration(seconds: 60);
  }
  
  static int get maxRetryAttempts {
    return isProduction ? 3 : 5;
  }
  
  // Cache Configuration
  static int get maxCacheSize {
    return isProduction ? 50 : 100; // MB
  }
  
  static Duration get cacheTimeout {
    return isProduction 
        ? const Duration(hours: 24)
        : const Duration(hours: 1);
  }
  
  // Security Configuration
  static bool get enableSSL => isProduction;
  static bool get enableCertificatePinning => isProduction;
  
  static Duration get sessionTimeout {
    return isProduction 
        ? const Duration(hours: 12)
        : const Duration(hours: 24);
  }
  
  // Feature Flags
  static bool get enableAnalytics => isProduction;
  static bool get enableCrashReporting => isProduction;
  static bool get enablePerformanceMonitoring => isProduction;
  static bool get enableDetailedLogging => !isProduction;
  static bool get enableDebugFeatures => isDevelopment;
  
  // App Configuration
  static String get appName {
    if (isProduction) return 'Crystal Social';
    if (isStaging) return 'Crystal Social (Staging)';
    return 'Crystal Social (Dev)';
  }
  
  static String get appVersion => const String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0');
  static String get buildNumber => const String.fromEnvironment('BUILD_NUMBER', defaultValue: '1');
  
  // Database Configuration
  static int get maxDatabaseConnections => isProduction ? 5 : 10;
  static Duration get databaseTimeout => isProduction 
      ? const Duration(seconds: 15) 
      : const Duration(seconds: 30);
  
  // Memory Management
  static int get maxImageCacheSize => isProduction ? 100 : 200;
  static Duration get imageCacheTimeout => isProduction 
      ? const Duration(hours: 24) 
      : const Duration(hours: 12);
  
  // Network Configuration
  static int get maxConcurrentRequests => isProduction ? 10 : 20;
  static Duration get connectTimeout => const Duration(seconds: 10);
  static Duration get receiveTimeout => const Duration(seconds: 30);
  
  // User Experience
  static Duration get splashDuration => const Duration(seconds: 3);
  static Duration get animationDuration => const Duration(milliseconds: 300);
  static Duration get debounceDelay => const Duration(milliseconds: 500);
  
  // Security Keys (these should be injected via CI/CD in production)
  static String get encryptionKey {
    return const String.fromEnvironment(
      'ENCRYPTION_KEY',
      defaultValue: 'development-encryption-key-change-in-production',
    );
  }
  
  static String get hmacSecret {
    return const String.fromEnvironment(
      'HMAC_SECRET', 
      defaultValue: 'development-hmac-secret-change-in-production',
    );
  }
  
  // External Service URLs
  static String get crashlyticsKey {
    return const String.fromEnvironment(
      'CRASHLYTICS_KEY',
      defaultValue: '',
    );
  }
  
  static String get analyticsKey {
    return const String.fromEnvironment(
      'ANALYTICS_KEY',
      defaultValue: '',
    );
  }
  
  /// Get current environment name
  static String get environmentName {
    if (isProduction) return 'production';
    if (isStaging) return 'staging';
    return 'development';
  }
  
  /// Check if we're running in a secure environment
  static bool get isSecureEnvironment => isProduction || isStaging;
  
  /// Get environment-specific color for debugging
  static int get environmentColor {
    if (isProduction) return 0xFF4CAF50; // Green
    if (isStaging) return 0xFFFF9800; // Orange
    return 0xFF2196F3; // Blue
  }
}
