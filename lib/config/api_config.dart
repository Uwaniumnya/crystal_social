import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/environment_config.dart';

/// API Configuration for Crystal Social
/// Manages all API endpoints and configurations
class ApiConfig {
  static const String baseUrl = 'https://zdsjtjbzhiejvpuahnlk.supabase.co';
  
  // Edge Function URLs
  static const String sendNotificationUrl = '$baseUrl/functions/v1/send-push-notification';
  static const String moderateContentUrl = '$baseUrl/functions/v1/moderate-content';
  static const String processAnalyticsUrl = '$baseUrl/functions/v1/process-analytics';
  static const String backgroundTasksUrl = '$baseUrl/functions/v1/background-tasks';
  static const String processGameEventsUrl = '$baseUrl/functions/v1/process-game-events';
  
  // Storage URLs
  static const String storageUrl = '$baseUrl/storage/v1';
  static const String avatarsUrl = '$storageUrl/object/public/avatars';
  static const String backgroundsUrl = '$storageUrl/object/public/backgrounds';
  static const String userContentUrl = '$storageUrl/object/public/user-content';
  
  // API Headers for authenticated requests
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${EnvironmentConfig.supabaseAnonKey}',
    'apikey': EnvironmentConfig.supabaseAnonKey,
  };
  
  // Service role headers for administrative operations
  static Map<String, String> get serviceHeaders => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${EnvironmentConfig.supabaseServiceRoleKey}',
    'apikey': EnvironmentConfig.supabaseServiceRoleKey,
  };
  
  // Realtime configuration
  static Map<String, dynamic> get realtimeConfig => {
    'url': baseUrl.replaceFirst('https', 'wss'),
    'apikey': EnvironmentConfig.supabaseAnonKey,
    'timeout': 20000,
    'heartbeatIntervalMs': 30000,
    'reconnectAfterMs': (int tries) {
      final delays = [1000, 2000, 5000, 10000];
      return tries <= delays.length ? delays[tries - 1] : 10000;
    },
  };
  
  // Rate limiting configuration
  static const int maxRequestsPerMinute = 60;
  static const int maxUploadSizeMB = 50;
  
  // Timeouts
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration uploadTimeout = Duration(minutes: 5);
  static const Duration downloadTimeout = Duration(minutes: 2);
  
  // Debug configuration
  static bool get isDebugMode => kDebugMode;
  static bool get enableLogging => kDebugMode;
  
  /// Get user-specific storage path
  static String getUserStoragePath(String userId, String bucket) {
    return '$bucket/$userId';
  }
  
  /// Get public URL for storage object
  static String getPublicUrl(String bucket, String path) {
    return '$storageUrl/object/public/$bucket/$path';
  }
  
  /// Validate API response
  static bool isValidResponse(Map<String, dynamic>? response) {
    return response != null && !response.containsKey('error');
  }
  
  /// Get error message from API response
  static String getErrorMessage(dynamic error) {
    if (error is PostgrestException) {
      return 'Database Error: ${error.message}';
    } else if (error is AuthException) {
      return 'Authentication Error: ${error.message}';
    } else if (error is StorageException) {
      return 'Storage Error: ${error.message}';
    } else if (error is Map && error.containsKey('error')) {
      return 'API Error: ${error['error']['message'] ?? error['error']}';
    }
    return 'Unexpected error occurred';
  }
}
