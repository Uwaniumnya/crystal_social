import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'profile_production_config.dart';
import 'profile_performance_optimizer.dart';

/// Centralized Profile Service that coordinates all profile-related functionality
/// This service acts as the single source of truth for all profile operations
class ProfileService extends ChangeNotifier {
  static ProfileService? _instance;
  static ProfileService get instance {
    _instance ??= ProfileService._internal();
    return _instance!;
  }

  ProfileService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // State management
  bool _isInitialized = false;
  String? _currentUserId;
  Map<String, dynamic> _userProfile = {};
  Map<String, dynamic> _userStats = {};
  List<Map<String, dynamic>> _avatarDecorations = [];
  Map<String, dynamic> _soundSettings = {};
  bool _isLoading = false;
  String? _error;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentUserId => _currentUserId;
  Map<String, dynamic> get userProfile => Map.from(_userProfile);
  Map<String, dynamic> get userStats => Map.from(_userStats);
  List<Map<String, dynamic>> get avatarDecorations => List.from(_avatarDecorations);
  Map<String, dynamic> get soundSettings => Map.from(_soundSettings);

  // Quick access getters
  String? get username => _userProfile['username'];
  String? get avatarUrl => _userProfile['avatarUrl'];
  String? get bio => _userProfile['bio'];
  String? get displayName => _userProfile['display_name'];
  String? get location => _userProfile['location'];
  String? get website => _userProfile['website'];
  String? get zodiacSign => _userProfile['zodiac_sign'];
  List<String>? get interests => _userProfile['interests']?.cast<String>();
  Map<String, dynamic>? get socialLinks => _userProfile['social_links'];
  String? get avatarDecoration => _userProfile['avatar_decoration'];
  bool get isPrivateProfile => _userProfile['is_private'] ?? false;
  
  /// Initialize the profile service with a user
  Future<void> initialize(String userId) async {
    if (_isInitialized && _currentUserId == userId) return;

    try {
      _setLoading(true);
      _clearError();

      _currentUserId = userId;

      // Load all user data in parallel
      await Future.wait([
        _loadUserProfile(),
        _loadUserStats(),
        _loadAvatarDecorations(),
        _loadSoundSettings(),
      ]);

      _isInitialized = true;
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to initialize profile service: $e');
      _setLoading(false);
      ProfileDebugUtils.logError('ProfileService initialization', e);
    }
  }

  /// Refresh all data
  Future<void> refresh() async {
    if (!_isInitialized || _currentUserId == null) return;
    await initialize(_currentUserId!);
  }

  /// Load user profile data
  Future<void> _loadUserProfile() async {
    try {
      final data = await _supabase
          .from('users')
          .select('*')
          .eq('id', _currentUserId!)
          .maybeSingle();

      if (data != null) {
        _userProfile = data;
      }
    } catch (e) {
      ProfileDebugUtils.logError('loadUserProfile', e);
    }
  }

  /// Load user statistics
  Future<void> _loadUserStats() async {
    try {
      final data = await _supabase
          .from('user_activity_stats')
          .select('*')
          .eq('user_id', _currentUserId!)
          .maybeSingle();

      _userStats = data ?? {};
    } catch (e) {
      ProfileDebugUtils.logError('loadUserStats', e);
    }
  }

  /// Load avatar decorations
  Future<void> _loadAvatarDecorations() async {
    try {
      final data = await _supabase
          .from('avatar_decorations')
          .select('*')
          .eq('user_id', _currentUserId!);

      _avatarDecorations = data;
    } catch (e) {
      ProfileDebugUtils.logError('loadAvatarDecorations', e);
    }
  }

  /// Load sound settings (ringtones, notification sounds)
  Future<void> _loadSoundSettings() async {
    try {
      final data = await _supabase
          .from('users')
          .select('default_ringtone, notification_sound_preferences')
          .eq('id', _currentUserId!)
          .maybeSingle();

      _soundSettings = data ?? {};
    } catch (e) {
      ProfileDebugUtils.logError('loadSoundSettings', e);
    }
  }

  /// Update user profile
  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    if (!_isInitialized || _currentUserId == null) return false;

    try {
      _setLoading(true);
      _clearError();

      await _supabase
          .from('users')
          .update(updates)
          .eq('id', _currentUserId!);

      // Update local cache
      _userProfile.addAll(updates);
      
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update profile: $e');
      _setLoading(false);
      return false;
    }
  }

  /// Upload avatar image
  Future<String?> uploadAvatar(File imageFile) async {
    if (!_isInitialized || _currentUserId == null) return null;

    try {
      _setLoading(true);
      _clearError();

      final fileExt = imageFile.path.split('.').last;
      final fileName = '${_currentUserId}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'avatars/$fileName';

      await _supabase.storage
          .from('user_content')
          .upload(filePath, imageFile);

      final publicUrl = _supabase.storage
          .from('user_content')
          .getPublicUrl(filePath);

      // Update avatar URL in profile
      await updateProfile({'avatarUrl': publicUrl});

      _setLoading(false);
      return publicUrl;
    } catch (e) {
      _setError('Failed to upload avatar: $e');
      _setLoading(false);
      return null;
    }
  }

  /// Set avatar decoration
  Future<bool> setAvatarDecoration(String? decorationPath) async {
    if (!_isInitialized || _currentUserId == null) return false;

    try {
      await updateProfile({'avatar_decoration': decorationPath});
      return true;
    } catch (e) {
      ProfileDebugUtils.logError('setAvatarDecoration', e);
      return false;
    }
  }

  /// Update sound settings
  Future<bool> updateSoundSettings({
    String? defaultRingtone,
    Map<String, dynamic>? notificationPreferences,
  }) async {
    if (!_isInitialized || _currentUserId == null) return false;

    try {
      final updates = <String, dynamic>{};
      
      if (defaultRingtone != null) {
        updates['default_ringtone'] = defaultRingtone;
      }
      
      if (notificationPreferences != null) {
        updates['notification_sound_preferences'] = notificationPreferences;
      }

      await _supabase
          .from('users')
          .update(updates)
          .eq('id', _currentUserId!);

      // Update local cache
      _soundSettings.addAll(updates);
      
      notifyListeners();
      return true;
    } catch (e) {
      ProfileDebugUtils.logError('updateSoundSettings', e);
      return false;
    }
  }

  /// Set per-user ringtone
  Future<bool> setPerUserRingtone(String senderId, String ringtone) async {
    if (!_isInitialized || _currentUserId == null) return false;

    try {
      await _supabase.from('per_user_ringtones').upsert({
        'owner_id': _currentUserId!,
        'sender_id': senderId,
        'ringtone': ringtone,
      });

      return true;
    } catch (e) {
      ProfileDebugUtils.logError('setPerUserRingtone', e);
      return false;
    }
  }

  /// Get per-user ringtone
  Future<String?> getPerUserRingtone(String senderId) async {
    if (!_isInitialized || _currentUserId == null) return null;

    try {
      final data = await _supabase
          .from('per_user_ringtones')
          .select('ringtone')
          .eq('owner_id', _currentUserId!)
          .eq('sender_id', senderId)
          .maybeSingle();

      return data?['ringtone'];
    } catch (e) {
      ProfileDebugUtils.logError('getPerUserRingtone', e);
      return null;
    }
  }

  /// Update user statistics
  Future<bool> updateStats(Map<String, dynamic> stats) async {
    if (!_isInitialized || _currentUserId == null) return false;

    try {
      await _supabase.from('user_activity_stats').upsert({
        'user_id': _currentUserId!,
        ...stats,
      });

      // Update local cache
      _userStats.addAll(stats);
      
      notifyListeners();
      return true;
    } catch (e) {
      ProfileDebugUtils.logError('updateUserStats', e);
      return false;
    }
  }

  /// Increment a specific stat
  Future<bool> incrementStat(String statName, [int amount = 1]) async {
    final currentValue = _userStats[statName] ?? 0;
    return await updateStats({statName: currentValue + amount});
  }

  /// Get profile completion percentage
  double getProfileCompletionPercentage() {
    if (_userProfile.isEmpty) return 0.0;

    final requiredFields = [
      'username', 'avatarUrl', 'bio', 'display_name', 
      'zodiac_sign', 'interests'
    ];
    
    int completedFields = 0;
    for (final field in requiredFields) {
      final value = _userProfile[field];
      if (value != null && value.toString().isNotEmpty) {
        if (field == 'interests' && value is List && value.isNotEmpty) {
          completedFields++;
        } else if (field != 'interests') {
          completedFields++;
        }
      }
    }

    return completedFields / requiredFields.length;
  }

  /// Check if user owns a specific avatar decoration
  bool ownsDecoration(String decorationId) {
    return _avatarDecorations.any((decoration) => 
        decoration['decoration_id'] == decorationId);
  }

  /// Purchase avatar decoration
  Future<bool> purchaseDecoration(String decorationId, int cost) async {
    if (!_isInitialized || _currentUserId == null) return false;

    try {
      // This would integrate with the rewards system
      // For now, just add the decoration to user's collection
      await _supabase.from('avatar_decorations').insert({
        'user_id': _currentUserId!,
        'decoration_id': decorationId,
        'purchased_at': DateTime.now().toIso8601String(),
      });

      // Reload decorations
      await _loadAvatarDecorations();
      notifyListeners();
      
      return true;
    } catch (e) {
      ProfileDebugUtils.logError('purchaseDecoration', e);
      return false;
    }
  }

  // Helper methods
  void _setLoading(bool isLoading) {
    _isLoading = isLoading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  /// Clear all data (for logout)
  void clear() {
    _isInitialized = false;
    _currentUserId = null;
    _userProfile.clear();
    _userStats.clear();
    _avatarDecorations.clear();
    _soundSettings.clear();
    _clearError();
    notifyListeners();
  }

  /// Get formatted display name
  String getDisplayName() {
    return displayName?.isNotEmpty == true 
        ? displayName! 
        : username ?? 'User';
  }

  /// Get user level based on stats
  int getUserLevel() {
    final totalActivity = (_userStats['total_messages'] ?? 0) + 
                         (_userStats['total_logins'] ?? 0) + 
                         (_userStats['groups_joined'] ?? 0);
    return (totalActivity / 100).floor() + 1;
  }

  /// Get user activity score
  int getActivityScore() {
    return (_userStats['total_messages'] ?? 0) + 
           (_userStats['total_logins'] ?? 0) * 2 + 
           (_userStats['groups_joined'] ?? 0) * 5;
  }
}
