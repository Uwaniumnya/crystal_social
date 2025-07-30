import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

/// Enhanced local storage for user data with comprehensive features
class EnhancedLocalUserStore {
  static const String _knownUsersKey = 'known_users';
  static const String _userProfilesKey = 'user_profiles';
  static const String _userPreferencesKey = 'user_preferences';
  static const String _userSessionsKey = 'user_sessions';
  static const String _userStatsKey = 'user_stats';
  static const String _appSettingsKey = 'app_settings';
  static const String _cacheExpiryKey = 'cache_expiry';
  static const String _favoritesKey = 'favorites';
  static const String _recentInteractionsKey = 'recent_interactions';
  static const String _offlineDataKey = 'offline_data';

  static SharedPreferences? _prefs;
  static final Map<String, dynamic> _memoryCache = {};
  static const Duration _cacheExpiry = Duration(hours: 24);

  /// Initialize the store and preload data
  static Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _cleanExpiredCache();
    await _loadCriticalDataToMemory();
  }

  /// Ensure preferences are initialized
  static Future<SharedPreferences> get _preferences async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  // ============================================================================
  // USER MANAGEMENT
  // ============================================================================

  /// Enhanced user model for local storage
  static Future<void> rememberUser(String userId, {
    String? username,
    String? email,
    String? avatarUrl,
    Map<String, dynamic>? metadata,
  }) async {
    final prefs = await _preferences;
    
    // Add to known users list
    final users = prefs.getStringList(_knownUsersKey) ?? [];
    if (!users.contains(userId)) {
      users.add(userId);
      await prefs.setStringList(_knownUsersKey, users);
    }

    // Store user profile if additional data provided
    if (username != null || email != null || avatarUrl != null || metadata != null) {
      await _storeUserProfile(userId, {
        'user_id': userId,
        'username': username,
        'email': email,
        'avatar_url': avatarUrl,
        'metadata': metadata ?? {},
        'last_seen': DateTime.now().toIso8601String(),
        'first_remembered': DateTime.now().toIso8601String(),
      });
    }

    // Update user statistics
    await _updateUserStats(userId, 'remembered');
    
    // Cache in memory
    _memoryCache['known_users'] = users;
  }

  /// Get all known user IDs with optional profile data
  static Future<List<String>> getKnownUsers() async {
    // Check memory cache first
    if (_memoryCache.containsKey('known_users')) {
      return List<String>.from(_memoryCache['known_users']);
    }

    final prefs = await _preferences;
    final users = prefs.getStringList(_knownUsersKey) ?? [];
    
    // Cache in memory
    _memoryCache['known_users'] = users;
    
    return users;
  }

  /// Get detailed user profiles for known users
  static Future<List<Map<String, dynamic>>> getKnownUsersWithProfiles() async {
    final userIds = await getKnownUsers();
    final profiles = <Map<String, dynamic>>[];

    for (final userId in userIds) {
      final profile = await getUserProfile(userId);
      if (profile != null) {
        profiles.add(profile);
      } else {
        // Create basic profile for users without detailed data
        profiles.add({
          'user_id': userId,
          'username': null,
          'email': null,
          'avatar_url': null,
          'metadata': {},
          'last_seen': null,
        });
      }
    }

    return profiles;
  }

  /// Remove a user and all associated data
  static Future<void> forgetUser(String userId, {bool keepProfile = false}) async {
    final prefs = await _preferences;
    
    // Remove from known users
    final users = prefs.getStringList(_knownUsersKey) ?? [];
    users.remove(userId);
    await prefs.setStringList(_knownUsersKey, users);

    // Remove associated data unless specified to keep
    if (!keepProfile) {
      await _removeUserProfile(userId);
      await _removeUserPreferences(userId);
      await _removeUserSessions(userId);
      await _removeUserStats(userId);
      await _removeFavorites(userId);
      await _removeRecentInteractions(userId);
    }

    // Update memory cache
    _memoryCache.remove('known_users');
    _memoryCache.remove('user_profile_$userId');
  }

  /// Clear all user data
  static Future<void> clearAllUsers({bool keepAppSettings = true}) async {
    final prefs = await _preferences;
    
    final keysToRemove = [
      _knownUsersKey,
      _userProfilesKey,
      _userPreferencesKey,
      _userSessionsKey,
      _userStatsKey,
      _favoritesKey,
      _recentInteractionsKey,
      _offlineDataKey,
    ];

    if (!keepAppSettings) {
      keysToRemove.add(_appSettingsKey);
    }

    for (final key in keysToRemove) {
      await prefs.remove(key);
    }

    // Clear memory cache
    _memoryCache.clear();
  }

  // ============================================================================
  // USER PROFILES
  // ============================================================================

  /// Store detailed user profile
  static Future<void> _storeUserProfile(String userId, Map<String, dynamic> profile) async {
    final prefs = await _preferences;
    final profiles = _getUserProfiles(prefs);
    
    profiles[userId] = {
      ...profile,
      'updated_at': DateTime.now().toIso8601String(),
    };

    await prefs.setString(_userProfilesKey, jsonEncode(profiles));
    
    // Cache in memory
    _memoryCache['user_profile_$userId'] = profiles[userId];
  }

  /// Get user profile
  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    // Check memory cache first
    final cacheKey = 'user_profile_$userId';
    if (_memoryCache.containsKey(cacheKey)) {
      return Map<String, dynamic>.from(_memoryCache[cacheKey]);
    }

    final prefs = await _preferences;
    final profiles = _getUserProfiles(prefs);
    final profile = profiles[userId];
    
    if (profile != null) {
      // Cache in memory
      _memoryCache[cacheKey] = profile;
    }
    
    return profile;
  }

  /// Update user profile
  static Future<void> updateUserProfile(String userId, Map<String, dynamic> updates) async {
    final existingProfile = await getUserProfile(userId) ?? {};
    final updatedProfile = {
      ...existingProfile,
      ...updates,
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    await _storeUserProfile(userId, updatedProfile);
  }

  /// Remove user profile
  static Future<void> _removeUserProfile(String userId) async {
    final prefs = await _preferences;
    final profiles = _getUserProfiles(prefs);
    
    profiles.remove(userId);
    await prefs.setString(_userProfilesKey, jsonEncode(profiles));
    
    // Remove from memory cache
    _memoryCache.remove('user_profile_$userId');
  }

  // ============================================================================
  // USER PREFERENCES
  // ============================================================================

  /// Store user preferences
  static Future<void> setUserPreferences(String userId, Map<String, dynamic> preferences) async {
    final prefs = await _preferences;
    final allPrefs = _getUserPreferences(prefs);
    
    allPrefs[userId] = {
      ...preferences,
      'updated_at': DateTime.now().toIso8601String(),
    };

    await prefs.setString(_userPreferencesKey, jsonEncode(allPrefs));
    
    // Cache in memory
    _memoryCache['user_prefs_$userId'] = allPrefs[userId];
  }

  /// Get user preferences
  static Future<Map<String, dynamic>> getUserPreferences(String userId) async {
    // Check memory cache first
    final cacheKey = 'user_prefs_$userId';
    if (_memoryCache.containsKey(cacheKey)) {
      return Map<String, dynamic>.from(_memoryCache[cacheKey]);
    }

    final prefs = await _preferences;
    final allPrefs = _getUserPreferences(prefs);
    final userPrefs = allPrefs[userId] ?? _getDefaultPreferences();
    
    // Cache in memory
    _memoryCache[cacheKey] = userPrefs;
    
    return userPrefs;
  }

  /// Update specific user preference
  static Future<void> updateUserPreference(String userId, String key, dynamic value) async {
    final preferences = await getUserPreferences(userId);
    preferences[key] = value;
    await setUserPreferences(userId, preferences);
  }

  /// Remove user preferences
  static Future<void> _removeUserPreferences(String userId) async {
    final prefs = await _preferences;
    final allPrefs = _getUserPreferences(prefs);
    
    allPrefs.remove(userId);
    await prefs.setString(_userPreferencesKey, jsonEncode(allPrefs));
    
    // Remove from memory cache
    _memoryCache.remove('user_prefs_$userId');
  }

  // ============================================================================
  // USER SESSIONS
  // ============================================================================

  /// Record user session
  static Future<void> recordUserSession(String userId, {
    DateTime? startTime,
    String? deviceInfo,
    Map<String, dynamic>? sessionData,
  }) async {
    final prefs = await _preferences;
    final sessions = _getUserSessions(prefs);
    
    if (!sessions.containsKey(userId)) {
      sessions[userId] = [];
    }

    final sessionRecord = {
      'session_id': _generateSessionId(),
      'user_id': userId,
      'start_time': (startTime ?? DateTime.now()).toIso8601String(),
      'device_info': deviceInfo,
      'session_data': sessionData ?? {},
      'created_at': DateTime.now().toIso8601String(),
    };

    sessions[userId].add(sessionRecord);
    
    // Keep only last 10 sessions per user
    if (sessions[userId].length > 10) {
      sessions[userId] = sessions[userId].sublist(sessions[userId].length - 10);
    }

    await prefs.setString(_userSessionsKey, jsonEncode(sessions));
  }

  /// Get user sessions
  static Future<List<Map<String, dynamic>>> getUserSessions(String userId) async {
    final prefs = await _preferences;
    final sessions = _getUserSessions(prefs);
    
    return List<Map<String, dynamic>>.from(sessions[userId] ?? []);
  }

  /// Get last session for user
  static Future<Map<String, dynamic>?> getLastUserSession(String userId) async {
    final sessions = await getUserSessions(userId);
    return sessions.isNotEmpty ? sessions.last : null;
  }

  /// Remove user sessions
  static Future<void> _removeUserSessions(String userId) async {
    final prefs = await _preferences;
    final sessions = _getUserSessions(prefs);
    
    sessions.remove(userId);
    await prefs.setString(_userSessionsKey, jsonEncode(sessions));
  }

  // ============================================================================
  // USER STATISTICS
  // ============================================================================

  /// Update user statistics
  static Future<void> _updateUserStats(String userId, String action) async {
    final prefs = await _preferences;
    final stats = _getUserStats(prefs);
    
    if (!stats.containsKey(userId)) {
      stats[userId] = _getDefaultUserStats();
    }

    final userStats = stats[userId];
    userStats['total_actions'] = (userStats['total_actions'] ?? 0) + 1;
    userStats['last_action'] = action;
    userStats['last_activity'] = DateTime.now().toIso8601String();
    
    // Track action counts
    final actions = userStats['actions'] as Map<String, dynamic>;
    actions[action] = (actions[action] ?? 0) + 1;

    await prefs.setString(_userStatsKey, jsonEncode(stats));
  }

  /// Get user statistics
  static Future<Map<String, dynamic>> getUserStats(String userId) async {
    final prefs = await _preferences;
    final stats = _getUserStats(prefs);
    
    return Map<String, dynamic>.from(stats[userId] ?? _getDefaultUserStats());
  }

  /// Remove user statistics
  static Future<void> _removeUserStats(String userId) async {
    final prefs = await _preferences;
    final stats = _getUserStats(prefs);
    
    stats.remove(userId);
    await prefs.setString(_userStatsKey, jsonEncode(stats));
  }

  // ============================================================================
  // FAVORITES SYSTEM
  // ============================================================================

  /// Add item to user favorites
  static Future<void> addToFavorites(String userId, String itemType, String itemId, {
    Map<String, dynamic>? metadata,
  }) async {
    final prefs = await _preferences;
    final favorites = _getFavorites(prefs);
    
    if (!favorites.containsKey(userId)) {
      favorites[userId] = {};
    }
    
    if (!favorites[userId].containsKey(itemType)) {
      favorites[userId][itemType] = [];
    }

    final favoriteItem = {
      'item_id': itemId,
      'item_type': itemType,
      'added_at': DateTime.now().toIso8601String(),
      'metadata': metadata ?? {},
    };

    // Remove if already exists to avoid duplicates
    favorites[userId][itemType].removeWhere((item) => item['item_id'] == itemId);
    favorites[userId][itemType].add(favoriteItem);

    await prefs.setString(_favoritesKey, jsonEncode(favorites));
  }

  /// Remove item from user favorites
  static Future<void> removeFromFavorites(String userId, String itemType, String itemId) async {
    final prefs = await _preferences;
    final favorites = _getFavorites(prefs);
    
    if (favorites.containsKey(userId) && favorites[userId].containsKey(itemType)) {
      favorites[userId][itemType].removeWhere((item) => item['item_id'] == itemId);
      await prefs.setString(_favoritesKey, jsonEncode(favorites));
    }
  }

  /// Get user favorites by type
  static Future<List<Map<String, dynamic>>> getUserFavorites(String userId, String itemType) async {
    final prefs = await _preferences;
    final favorites = _getFavorites(prefs);
    
    if (favorites.containsKey(userId) && favorites[userId].containsKey(itemType)) {
      return List<Map<String, dynamic>>.from(favorites[userId][itemType]);
    }
    
    return [];
  }

  /// Check if item is favorited
  static Future<bool> isFavorited(String userId, String itemType, String itemId) async {
    final favorites = await getUserFavorites(userId, itemType);
    return favorites.any((item) => item['item_id'] == itemId);
  }

  /// Remove all user favorites
  static Future<void> _removeFavorites(String userId) async {
    final prefs = await _preferences;
    final favorites = _getFavorites(prefs);
    
    favorites.remove(userId);
    await prefs.setString(_favoritesKey, jsonEncode(favorites));
  }

  // ============================================================================
  // RECENT INTERACTIONS
  // ============================================================================

  /// Record recent interaction
  static Future<void> recordRecentInteraction(String userId, String interactionType, String targetId, {
    Map<String, dynamic>? metadata,
  }) async {
    final prefs = await _preferences;
    final interactions = _getRecentInteractions(prefs);
    
    if (!interactions.containsKey(userId)) {
      interactions[userId] = [];
    }

    final interaction = {
      'interaction_type': interactionType,
      'target_id': targetId,
      'timestamp': DateTime.now().toIso8601String(),
      'metadata': metadata ?? {},
    };

    interactions[userId].insert(0, interaction); // Add to beginning
    
    // Keep only last 50 interactions
    if (interactions[userId].length > 50) {
      interactions[userId] = interactions[userId].sublist(0, 50);
    }

    await prefs.setString(_recentInteractionsKey, jsonEncode(interactions));
  }

  /// Get recent interactions for user
  static Future<List<Map<String, dynamic>>> getRecentInteractions(String userId, {
    String? interactionType,
    int limit = 20,
  }) async {
    final prefs = await _preferences;
    final interactions = _getRecentInteractions(prefs);
    
    var userInteractions = List<Map<String, dynamic>>.from(interactions[userId] ?? []);
    
    if (interactionType != null) {
      userInteractions = userInteractions
          .where((interaction) => interaction['interaction_type'] == interactionType)
          .toList();
    }
    
    return userInteractions.take(limit).toList();
  }

  /// Remove recent interactions
  static Future<void> _removeRecentInteractions(String userId) async {
    final prefs = await _preferences;
    final interactions = _getRecentInteractions(prefs);
    
    interactions.remove(userId);
    await prefs.setString(_recentInteractionsKey, jsonEncode(interactions));
  }

  // ============================================================================
  // OFFLINE DATA MANAGEMENT
  // ============================================================================

  /// Store data for offline use
  static Future<void> storeOfflineData(String userId, String dataType, Map<String, dynamic> data) async {
    final prefs = await _preferences;
    final offlineData = _getOfflineData(prefs);
    
    if (!offlineData.containsKey(userId)) {
      offlineData[userId] = {};
    }

    offlineData[userId][dataType] = {
      'data': data,
      'stored_at': DateTime.now().toIso8601String(),
      'expires_at': DateTime.now().add(_cacheExpiry).toIso8601String(),
    };

    await prefs.setString(_offlineDataKey, jsonEncode(offlineData));
  }

  /// Get offline data
  static Future<Map<String, dynamic>?> getOfflineData(String userId, String dataType) async {
    final prefs = await _preferences;
    final offlineData = _getOfflineData(prefs);
    
    if (offlineData.containsKey(userId) && offlineData[userId].containsKey(dataType)) {
      final data = offlineData[userId][dataType];
      final expiresAt = DateTime.parse(data['expires_at']);
      
      if (DateTime.now().isBefore(expiresAt)) {
        return Map<String, dynamic>.from(data['data']);
      } else {
        // Data expired, remove it
        offlineData[userId].remove(dataType);
        await prefs.setString(_offlineDataKey, jsonEncode(offlineData));
      }
    }
    
    return null;
  }

  // ============================================================================
  // APP SETTINGS
  // ============================================================================

  /// Store app-wide settings
  static Future<void> setAppSetting(String key, dynamic value) async {
    final prefs = await _preferences;
    final settings = _getAppSettings(prefs);
    
    settings[key] = value;
    settings['updated_at'] = DateTime.now().toIso8601String();

    await prefs.setString(_appSettingsKey, jsonEncode(settings));
    
    // Cache in memory
    _memoryCache['app_setting_$key'] = value;
  }

  /// Get app setting
  static Future<T?> getAppSetting<T>(String key, {T? defaultValue}) async {
    // Check memory cache first
    final cacheKey = 'app_setting_$key';
    if (_memoryCache.containsKey(cacheKey)) {
      return _memoryCache[cacheKey] as T?;
    }

    final prefs = await _preferences;
    final settings = _getAppSettings(prefs);
    final value = settings[key] as T?;
    
    if (value != null) {
      // Cache in memory
      _memoryCache[cacheKey] = value;
    }
    
    return value ?? defaultValue;
  }

  /// Remove app setting
  static Future<void> removeAppSetting(String key) async {
    final prefs = await _preferences;
    final settings = _getAppSettings(prefs);
    
    settings.remove(key);
    await prefs.setString(_appSettingsKey, jsonEncode(settings));
    
    // Remove from memory cache
    _memoryCache.remove('app_setting_$key');
  }

  // ============================================================================
  // CACHE MANAGEMENT
  // ============================================================================

  /// Clean expired cache entries
  static Future<void> _cleanExpiredCache() async {
    final prefs = await _preferences;
    final expiryData = _getCacheExpiry(prefs);
    final now = DateTime.now();
    
    final expiredKeys = <String>[];
    
    for (final entry in expiryData.entries) {
      final expiryTime = DateTime.parse(entry.value);
      if (now.isAfter(expiryTime)) {
        expiredKeys.add(entry.key);
        await prefs.remove(entry.key);
      }
    }
    
    // Remove expired entries from expiry tracking
    for (final key in expiredKeys) {
      expiryData.remove(key);
    }
    
    if (expiredKeys.isNotEmpty) {
      await prefs.setString(_cacheExpiryKey, jsonEncode(expiryData));
    }
  }

  /// Load critical data to memory for performance
  static Future<void> _loadCriticalDataToMemory() async {
    // Load known users
    await getKnownUsers();
    
    // Load common app settings
    final commonSettings = ['theme', 'language', 'notification_settings'];
    for (final setting in commonSettings) {
      await getAppSetting(setting);
    }
  }

  /// Clear memory cache
  static void clearMemoryCache() {
    _memoryCache.clear();
  }

  /// Get cache size information
  static Future<Map<String, dynamic>> getCacheInfo() async {
    final prefs = await _preferences;
    final keys = prefs.getKeys();
    
    int totalSize = 0;
    final categorySizes = <String, int>{};
    
    for (final key in keys) {
      final value = prefs.get(key);
      final size = value.toString().length;
      totalSize += size;
      
      // Categorize by key prefix
      final category = key.split('_').first;
      categorySizes[category] = (categorySizes[category] ?? 0) + size;
    }
    
    return {
      'total_keys': keys.length,
      'total_size_chars': totalSize,
      'memory_cache_size': _memoryCache.length,
      'category_sizes': categorySizes,
    };
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  static Map<String, dynamic> _getUserProfiles(SharedPreferences prefs) {
    final profilesJson = prefs.getString(_userProfilesKey) ?? '{}';
    return Map<String, dynamic>.from(jsonDecode(profilesJson));
  }

  static Map<String, dynamic> _getUserPreferences(SharedPreferences prefs) {
    final prefsJson = prefs.getString(_userPreferencesKey) ?? '{}';
    return Map<String, dynamic>.from(jsonDecode(prefsJson));
  }

  static Map<String, dynamic> _getUserSessions(SharedPreferences prefs) {
    final sessionsJson = prefs.getString(_userSessionsKey) ?? '{}';
    return Map<String, dynamic>.from(jsonDecode(sessionsJson));
  }

  static Map<String, dynamic> _getUserStats(SharedPreferences prefs) {
    final statsJson = prefs.getString(_userStatsKey) ?? '{}';
    return Map<String, dynamic>.from(jsonDecode(statsJson));
  }

  static Map<String, dynamic> _getFavorites(SharedPreferences prefs) {
    final favoritesJson = prefs.getString(_favoritesKey) ?? '{}';
    return Map<String, dynamic>.from(jsonDecode(favoritesJson));
  }

  static Map<String, dynamic> _getRecentInteractions(SharedPreferences prefs) {
    final interactionsJson = prefs.getString(_recentInteractionsKey) ?? '{}';
    return Map<String, dynamic>.from(jsonDecode(interactionsJson));
  }

  static Map<String, dynamic> _getOfflineData(SharedPreferences prefs) {
    final offlineJson = prefs.getString(_offlineDataKey) ?? '{}';
    return Map<String, dynamic>.from(jsonDecode(offlineJson));
  }

  static Map<String, dynamic> _getAppSettings(SharedPreferences prefs) {
    final settingsJson = prefs.getString(_appSettingsKey) ?? '{}';
    return Map<String, dynamic>.from(jsonDecode(settingsJson));
  }

  static Map<String, dynamic> _getCacheExpiry(SharedPreferences prefs) {
    final expiryJson = prefs.getString(_cacheExpiryKey) ?? '{}';
    return Map<String, dynamic>.from(jsonDecode(expiryJson));
  }

  static Map<String, dynamic> _getDefaultPreferences() {
    return {
      'theme': 'light',
      'notifications_enabled': true,
      'sound_enabled': true,
      'auto_save': true,
      'language': 'en',
      'privacy_mode': false,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  static Map<String, dynamic> _getDefaultUserStats() {
    return {
      'total_actions': 0,
      'actions': <String, dynamic>{},
      'first_seen': DateTime.now().toIso8601String(),
      'last_activity': DateTime.now().toIso8601String(),
      'last_action': null,
    };
  }

  static String _generateSessionId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  // ============================================================================
  // EXPORT/IMPORT FUNCTIONALITY
  // ============================================================================

  /// Export all user data
  static Future<Map<String, dynamic>> exportUserData(String userId) async {
    return {
      'profile': await getUserProfile(userId),
      'preferences': await getUserPreferences(userId),
      'sessions': await getUserSessions(userId),
      'stats': await getUserStats(userId),
      'favorites': {
        'messages': await getUserFavorites(userId, 'messages'),
        'users': await getUserFavorites(userId, 'users'),
        'groups': await getUserFavorites(userId, 'groups'),
      },
      'recent_interactions': await getRecentInteractions(userId),
      'exported_at': DateTime.now().toIso8601String(),
    };
  }

  /// Import user data
  static Future<void> importUserData(String userId, Map<String, dynamic> data) async {
    if (data['profile'] != null) {
      await _storeUserProfile(userId, data['profile']);
    }
    
    if (data['preferences'] != null) {
      await setUserPreferences(userId, data['preferences']);
    }
    
    // Note: Sessions and stats are typically not imported to avoid conflicts
    // Favorites and interactions could be selectively imported based on use case
  }
}
