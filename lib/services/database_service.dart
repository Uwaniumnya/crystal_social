import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Database Service for Crystal Social
/// Provides centralized error handling and database operations
class DatabaseService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  
  /// Safe query execution with comprehensive error handling
  static Future<T?> safeQuery<T>(
    Future<T> Function() query,
    String operation, {
    T? fallback,
    bool logErrors = true,
  }) async {
    try {
      return await query();
    } on PostgrestException catch (e) {
      if (logErrors) {
        debugPrint('🔴 PostgrestException in $operation: ${e.code} - ${e.message}');
      }
      
      // Handle specific database errors
      switch (e.code) {
        case 'PGRST116':
          // Table/relation doesn't exist
          if (logErrors) {
            debugPrint('⚠️ Table not found for $operation: ${e.message}');
          }
          return fallback;
          
        case '42501':
          // Permission denied
          if (logErrors) {
            debugPrint('🔒 Permission denied for $operation: ${e.message}');
          }
          throw DatabaseException(
            'Access denied. Please check your permissions.',
            code: 'PERMISSION_DENIED',
          );
          
        case '23505':
          // Unique constraint violation
          throw DatabaseException(
            'This record already exists.',
            code: 'DUPLICATE_RECORD',
          );
          
        case '23503':
          // Foreign key violation
          throw DatabaseException(
            'Related record not found.',
            code: 'FOREIGN_KEY_ERROR',
          );
          
        case '42703':
          // Undefined column
          if (logErrors) {
            debugPrint('⚠️ Column not found in $operation: ${e.message}');
          }
          return fallback;
          
        default:
          throw DatabaseException(
            'Database error in $operation: ${e.message}',
            code: e.code ?? 'UNKNOWN_DATABASE_ERROR',
          );
      }
    } on AuthException catch (e) {
      if (logErrors) {
        debugPrint('🔴 AuthException in $operation: ${e.message}');
      }
      throw DatabaseException(
        'Authentication error: ${e.message}',
        code: 'AUTH_ERROR',
      );
    } on StorageException catch (e) {
      if (logErrors) {
        debugPrint('🔴 StorageException in $operation: ${e.message}');
      }
      throw DatabaseException(
        'Storage error: ${e.message}',
        code: 'STORAGE_ERROR',
      );
    } catch (e) {
      if (logErrors) {
        debugPrint('🔴 Unexpected error in $operation: $e');
      }
      throw DatabaseException(
        'Unexpected error in $operation: ${e.toString()}',
        code: 'UNEXPECTED_ERROR',
      );
    }
  }
  
  /// Check if a table exists in the database
  static Future<bool> tableExists(String tableName) async {
    try {
      await _supabase
          .from(tableName)
          .select('count(*)')
          .limit(1);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Check if user has access to a specific table
  static Future<bool> hasTableAccess(String tableName, String userId) async {
    return await safeQuery(
      () async {
        await _supabase
            .from(tableName)
            .select('count(*)')
            .eq('user_id', userId)
            .limit(1);
        return true;
      },
      'hasTableAccess',
      fallback: false,
    ) ?? false;
  }
  
  /// Get user profile safely
  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    return await safeQuery<Map<String, dynamic>?>(
      () async {
        final result = await _supabase
            .from('profiles')
            .select()
            .eq('id', userId)
            .single();
        return result;
      },
      'getUserProfile',
    );
  }
  
  /// Get user notifications with pagination
  static Future<List<Map<String, dynamic>>> getUserNotifications(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) async {
    return await safeQuery<List<Map<String, dynamic>>>(
      () async {
        final result = await _supabase
            .from('user_notifications')
            .select()
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .range(offset, offset + limit - 1);
        return (result as List).cast<Map<String, dynamic>>();
      },
      'getUserNotifications',
      fallback: <Map<String, dynamic>>[],
    ) ?? [];
  }
  
  /// Get user settings safely
  static Future<Map<String, dynamic>?> getUserSettings(String userId) async {
    return await safeQuery<Map<String, dynamic>?>(
      () async {
        final result = await _supabase
            .from('user_settings')
            .select()
            .eq('user_id', userId)
            .maybeSingle();
        return result;
      },
      'getUserSettings',
    );
  }
  
  /// Update user settings with error handling
  static Future<bool> updateUserSettings(
    String userId,
    Map<String, dynamic> settings,
  ) async {
    final result = await safeQuery(
      () => _supabase
          .from('user_settings')
          .upsert({
            'user_id': userId,
            ...settings,
            'updated_at': DateTime.now().toIso8601String(),
          }),
      'updateUserSettings',
    );
    return result != null;
  }
  
  /// Create default user data for new users
  static Future<bool> initializeNewUser(String userId, String? email) async {
    try {
      // Create profile
      await _supabase.from('profiles').upsert({
        'id': userId,
        'email': email,
        'display_name': email?.split('@')[0] ?? 'User',
        'created_at': DateTime.now().toIso8601String(),
      });
      
      // Create default settings
      await _supabase.from('user_settings').upsert({
        'user_id': userId,
        'theme': 'kawaii_pink',
        'notifications_enabled': true,
        'language': 'en',
        'created_at': DateTime.now().toIso8601String(),
      });
      
      return true;
    } catch (e) {
      debugPrint('❌ Failed to initialize new user $userId: $e');
      return false;
    }
  }
  
  /// Health check for database connection
  static Future<bool> healthCheck() async {
    return await safeQuery(
      () async {
        await _supabase.from('profiles').select('count(*)').limit(1);
        return true;
      },
      'healthCheck',
      fallback: false,
      logErrors: false,
    ) ?? false;
  }
  
  /// Get database statistics
  static Future<Map<String, int>> getDatabaseStats() async {
    final stats = <String, int>{};
    
    final tables = [
      'profiles',
      'user_settings',
      'user_notifications',
      'support_requests',
      'chat_messages',
    ];
    
    for (final table in tables) {
      final count = await safeQuery(
        () async {
          final response = await _supabase
              .from(table)
              .select('count(*)')
              .single();
          return response['count'] as int? ?? 0;
        },
        'getDatabaseStats:$table',
        fallback: 0,
        logErrors: false,
      );
      stats[table] = count ?? 0;
    }
    
    return stats;
  }
}

/// Custom database exception class
class DatabaseException implements Exception {
  final String message;
  final String code;
  final dynamic originalError;
  
  const DatabaseException(
    this.message, {
    required this.code,
    this.originalError,
  });
  
  @override
  String toString() => 'DatabaseException($code): $message';
  
  /// Check if this is a specific type of error
  bool isPermissionError() => code == 'PERMISSION_DENIED';
  bool isDuplicateError() => code == 'DUPLICATE_RECORD';
  bool isNotFoundError() => code == 'NOT_FOUND';
  bool isConnectionError() => code == 'CONNECTION_ERROR';
}
