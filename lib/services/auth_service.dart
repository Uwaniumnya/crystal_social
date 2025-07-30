import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/notification_preferences_service.dart';
import '../services/database_service.dart';

/// Enhanced Authentication Service for Crystal Social
/// Handles user authentication flows and new user setup
class AuthService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  
  /// Set up a new user profile with all necessary default data
  static Future<bool> setupNewUserProfile(User user) async {
    try {
      debugPrint('🔧 Setting up new user profile for: ${user.email}');
      
      // 1. Initialize database service for new user
      final success = await DatabaseService.initializeNewUser(user.id, user.email);
      if (!success) {
        debugPrint('❌ Failed to initialize basic user data');
        return false;
      }
      
      // 2. Create default notification preferences
      try {
        await NotificationPreferencesService.instance.createDefaultPreferences(user.id);
        debugPrint('✅ Notification preferences created');
      } catch (e) {
        debugPrint('⚠️ Failed to create notification preferences: $e');
        // Don't fail the entire setup for this
      }
      
      // 3. Set up additional user features
      await _setupUserFeatures(user.id);
      
      debugPrint('✅ New user profile setup completed for: ${user.email}');
      return true;
      
    } catch (e) {
      debugPrint('❌ Error setting up new user profile: $e');
      return false;
    }
  }
  
  /// Set up additional user features and preferences
  static Future<void> _setupUserFeatures(String userId) async {
    try {
      // Create user preferences record
      await _supabase.from('user_preferences').upsert({
        'user_id': userId,
        'theme': 'kawaii_pink',
        'language': 'en',
        'timezone': DateTime.now().timeZoneName,
        'onboarding_completed': false,
        'privacy_settings': {
          'show_online_status': true,
          'allow_friend_requests': true,
          'show_activity': true,
        },
        'created_at': DateTime.now().toIso8601String(),
      });
      
      // Initialize user stats
      await _supabase.from('user_stats').upsert({
        'user_id': userId,
        'login_count': 1,
        'last_login': DateTime.now().toIso8601String(),
        'total_sessions': 1,
        'created_at': DateTime.now().toIso8601String(),
      });
      
    } catch (e) {
      debugPrint('⚠️ Error setting up additional user features: $e');
      // Don't throw, as these are optional features
    }
  }
  
  /// Handle user sign in and update login stats
  static Future<void> handleUserSignIn(User user) async {
    try {
      // Update last login time
      await _supabase.from('user_stats').upsert({
        'user_id': user.id,
        'last_login': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      // Increment login count
      await _supabase.rpc('increment_login_count', params: {
        'user_id': user.id,
      });
      
      debugPrint('📊 Updated login stats for user: ${user.email}');
    } catch (e) {
      debugPrint('⚠️ Failed to update login stats: $e');
    }
  }
  
  /// Check if user profile is complete and up to date
  static Future<bool> isUserProfileComplete(String userId) async {
    try {
      // Check if user has all required profile fields
      final profile = await DatabaseService.getUserProfile(userId);
      if (profile == null) return false;
      
      // Check if user has notification preferences
      try {
        final prefs = await NotificationPreferencesService.instance.getPreferences(userId);
        final hasPrefs = prefs.messages != false; // Check if we got real preferences vs defaults
        
        // Check if user has settings
        final settings = await DatabaseService.getUserSettings(userId);
        
        return profile['display_name'] != null &&
               hasPrefs &&
               settings != null;
      } catch (e) {
        return false;
      }
             
    } catch (e) {
      debugPrint('❌ Error checking user profile completeness: $e');
      return false;
    }
  }
  
  /// Migrate existing user to new schema
  static Future<bool> migrateExistingUser(String userId) async {
    try {
      debugPrint('🔄 Migrating existing user: $userId');
      
      final user = _supabase.auth.currentUser;
      if (user == null) return false;
      
      // Check what's missing and create it
      final profile = await DatabaseService.getUserProfile(userId);
      if (profile == null) {
        await setupNewUserProfile(user);
        return true;
      }
      
      // Check and create missing notification preferences
      try {
        final prefs = await NotificationPreferencesService.instance.getPreferences(userId);
        // Check if these are default preferences (indicating no user preferences exist)
        final hasCustomPrefs = prefs.messages != true || prefs.achievements != true; // Assuming defaults are all true
        if (!hasCustomPrefs) {
          await NotificationPreferencesService.instance.createDefaultPreferences(userId);
          debugPrint('✅ Created missing notification preferences');
        }
      } catch (e) {
        debugPrint('⚠️ Failed to create notification preferences during migration: $e');
      }
      
      // Check and create missing settings
      final settings = await DatabaseService.getUserSettings(userId);
      if (settings == null) {
        await DatabaseService.updateUserSettings(userId, {
          'theme': 'kawaii_pink',
          'notifications_enabled': true,
          'language': 'en',
        });
        debugPrint('✅ Created missing user settings');
      }
      
      debugPrint('✅ User migration completed');
      return true;
      
    } catch (e) {
      debugPrint('❌ Error migrating existing user: $e');
      return false;
    }
  }
  
  /// Get user authentication status and profile completion
  static Future<UserAuthStatus> getUserAuthStatus() async {
    final user = _supabase.auth.currentUser;
    
    if (user == null) {
      return UserAuthStatus.notAuthenticated();
    }
    
    final isComplete = await isUserProfileComplete(user.id);
    
    return UserAuthStatus.authenticated(
      user: user,
      profileComplete: isComplete,
    );
  }
  
  /// Handle sign out and cleanup
  static Future<void> handleSignOut() async {
    try {
      await _supabase.auth.signOut();
      debugPrint('✅ User signed out successfully');
    } catch (e) {
      debugPrint('❌ Error during sign out: $e');
      throw Exception('Failed to sign out: $e');
    }
  }
  
  /// Check if user has admin privileges
  static Future<bool> isUserAdmin(String userId) async {
    try {
      final profile = await DatabaseService.getUserProfile(userId);
      return profile?['is_admin'] == true;
    } catch (e) {
      debugPrint('❌ Error checking admin status: $e');
      return false;
    }
  }
  
  /// Update user profile information
  static Future<bool> updateUserProfile(String userId, Map<String, dynamic> updates) async {
    try {
      await _supabase.from('profiles').update({
        ...updates,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
      
      return true;
    } catch (e) {
      debugPrint('❌ Error updating user profile: $e');
      return false;
    }
  }
}

/// User authentication status class
class UserAuthStatus {
  final bool isAuthenticated;
  final User? user;
  final bool profileComplete;
  final bool needsMigration;
  
  const UserAuthStatus._({
    required this.isAuthenticated,
    this.user,
    required this.profileComplete,
    required this.needsMigration,
  });
  
  factory UserAuthStatus.notAuthenticated() {
    return const UserAuthStatus._(
      isAuthenticated: false,
      profileComplete: false,
      needsMigration: false,
    );
  }
  
  factory UserAuthStatus.authenticated({
    required User user,
    required bool profileComplete,
    bool needsMigration = false,
  }) {
    return UserAuthStatus._(
      isAuthenticated: true,
      user: user,
      profileComplete: profileComplete,
      needsMigration: needsMigration,
    );
  }
  
  bool get needsSetup => isAuthenticated && !profileComplete;
  bool get isReady => isAuthenticated && profileComplete && !needsMigration;
}
