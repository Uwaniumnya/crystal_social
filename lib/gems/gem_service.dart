import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'dart:math';
import 'gemstone_model.dart';
import 'shiny_gem_animation.dart';
import 'gems_production_config.dart';

/// Centralized Gem Service - Singleton for managing all gem-related operations
/// This service provides a unified interface for gem collection, unlocking, and management
class GemService {
  static final GemService _instance = GemService._internal();
  factory GemService() => _instance;
  GemService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final StreamController<List<Gemstone>> _gemsController = StreamController<List<Gemstone>>.broadcast();
  final StreamController<Map<String, dynamic>> _statsController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Gemstone> _unlockController = StreamController<Gemstone>.broadcast();
  
  List<Gemstone> _allGems = [];
  List<Gemstone> _userGems = [];
  Map<String, dynamic> _userStats = {};
  Map<String, bool> _userGemCache = {};
  bool _isInitialized = false;
  String? _currentUserId;

  // Getters for reactive access
  Stream<List<Gemstone>> get gemsStream => _gemsController.stream;
  Stream<Map<String, dynamic>> get statsStream => _statsController.stream;
  Stream<Gemstone> get unlockStream => _unlockController.stream;
  
  List<Gemstone> get allGems => List.unmodifiable(_allGems);
  List<Gemstone> get userGems => List.unmodifiable(_userGems);
  Map<String, dynamic> get userStats => Map.unmodifiable(_userStats);
  bool get isInitialized => _isInitialized;

  /// Initialize the gem service for a specific user
  Future<void> initialize(String userId) async {
    if (_isInitialized && _currentUserId == userId) return;
    
    _currentUserId = userId;
    try {
      await Future.wait([
        _loadAllGems(),
        _loadUserGems(userId),
        _loadUserStats(userId),
      ]);
      
      _isInitialized = true;
      _broadcastUpdates();
      GemsDebugUtils.log('GemService', 'GemService initialized for user: $userId');
    } catch (e) {
      GemsDebugUtils.logError('GemService', 'Error initializing GemService: $e');
      rethrow;
    }
  }

  /// Load all available gems from the database
  Future<void> _loadAllGems() async {
    try {
      final response = await _supabase
          .from('enhanced_gemstones')
          .select('*')
          .order('rarity, name');
      
      _allGems = (response as List)
          .map((data) => Gemstone.fromMap(data))
          .toList();
    } catch (e) {
      GemsDebugUtils.logError('GemService', 'Error loading all gems: $e');
      // Fallback to sample gems if database fails
      _loadSampleGems();
    }
  }

  /// Load user's collected gems
  Future<void> _loadUserGems(String userId) async {
    try {
      final response = await _supabase
          .from('user_gemstones')
          .select('''
            *,
            enhanced_gemstones!inner(*)
          ''')
          .eq('user_id', userId);
      
      _userGems = (response as List).map((data) {
        final gemData = data['enhanced_gemstones'];
        return Gemstone.fromMap({
          ...gemData,
          'is_unlocked': true,
          'unlocked_at': data['unlocked_at'],
          'is_favorite': data['is_favorite'] ?? false,
          'times_viewed': data['times_viewed'] ?? 0,
        });
      }).toList();

      // Update cache
      _userGemCache.clear();
      for (final gem in _userGems) {
        _userGemCache['${userId}_${gem.id}'] = true;
      }
    } catch (e) {
      GemsDebugUtils.logError('GemService', 'Error loading user gems: $e');
      _userGems = [];
    }
  }

  /// Load user statistics
  Future<void> _loadUserStats(String userId) async {
    try {
      final response = await _supabase
          .from('user_gem_stats')
          .select('*')
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        _userStats = Map<String, dynamic>.from(response);
      } else {
        await _generateUserStats(userId);
      }
    } catch (e) {
      GemsDebugUtils.logError('GemService', 'Error loading user stats: $e');
      _generateDefaultStats();
    }
  }

  /// Generate comprehensive user statistics
  Future<void> _generateUserStats(String userId) async {
    final rarityStats = GemManager.getRarityStats(_userGems);
    final totalValue = GemManager.getCollectionValue(_userGems);
    final totalPower = GemManager.getTotalPower(_userGems);
    
    _userStats = {
      'user_id': userId,
      'total_gems': _userGems.length,
      'total_possible': _allGems.length,
      'completion_percentage': _allGems.isEmpty ? 0.0 : (_userGems.length / _allGems.length * 100),
      'total_value': totalValue,
      'total_power': totalPower,
      'favorites_count': _userGems.where((g) => g.isFavorite).length,
      'common_count': rarityStats[GemRarity.common] ?? 0,
      'uncommon_count': rarityStats[GemRarity.uncommon] ?? 0,
      'rare_count': rarityStats[GemRarity.rare] ?? 0,
      'epic_count': rarityStats[GemRarity.epic] ?? 0,
      'legendary_count': rarityStats[GemRarity.legendary] ?? 0,
      'last_updated': DateTime.now().toIso8601String(),
    };

    // Save to database
    try {
      await _supabase
          .from('user_gem_stats')
          .upsert(_userStats);
    } catch (e) {
      GemsDebugUtils.logError('GemService', 'Error saving user stats: $e');
    }
  }

  /// Generate default statistics when database fails
  void _generateDefaultStats() {
    _userStats = {
      'total_gems': 0,
      'total_possible': _allGems.length,
      'completion_percentage': 0.0,
      'total_value': 0,
      'total_power': 0,
      'favorites_count': 0,
      'common_count': 0,
      'uncommon_count': 0,
      'rare_count': 0,
      'epic_count': 0,
      'legendary_count': 0,
    };
  }

  /// Unlock a new gem for the user
  Future<bool> unlockGem(String gemId, {Map<String, dynamic>? context}) async {
    if (_currentUserId == null) return false;

    try {
      // Check if gem already unlocked
      final cacheKey = '${_currentUserId}_$gemId';
      if (_userGemCache[cacheKey] == true) {
        GemsDebugUtils.log('GemService', 'Gem $gemId already unlocked for user $_currentUserId');
        return false;
      }

      // Find the gem
      final gem = _allGems.firstWhere((g) => g.id == gemId);
      
      // Unlock in database
      await _supabase.from('user_gemstones').insert({
        'user_id': _currentUserId,
        'gem_id': gemId,
        'unlocked_at': DateTime.now().toIso8601String(),
        'unlock_context': context ?? {},
      });

      // Update local state
      final unlockedGem = gem.copyWith(
        isUnlocked: true,
        unlockedAt: DateTime.now(),
      );
      
      _userGems.add(unlockedGem);
      _userGemCache[cacheKey] = true;

      // Update statistics
      await _generateUserStats(_currentUserId!);

      // Broadcast updates
      _broadcastUpdates();
      _unlockController.add(unlockedGem);

      // Log analytics
      await _logGemUnlock(_currentUserId!, unlockedGem, context ?? {});

      GemsDebugUtils.logUnlock('GemService', gem.name, gem.rarity.toString());
      return true;
    } catch (e) {
      GemsDebugUtils.logError('GemService', 'Error unlocking gem $gemId: $e');
      return false;
    }
  }

  /// Toggle favorite status for a gem
  Future<bool> toggleFavorite(String gemId) async {
    if (_currentUserId == null) return false;

    try {
      final gemIndex = _userGems.indexWhere((g) => g.id == gemId);
      if (gemIndex == -1) return false;

      final gem = _userGems[gemIndex];
      final newFavoriteStatus = !gem.isFavorite;

      // Update database
      await _supabase
          .from('user_gemstones')
          .update({'is_favorite': newFavoriteStatus})
          .eq('user_id', _currentUserId!)
          .eq('gem_id', gemId);

      // Update local state
      _userGems[gemIndex] = gem.copyWith(isFavorite: newFavoriteStatus);

      // Update statistics
      await _generateUserStats(_currentUserId!);

      _broadcastUpdates();
      return true;
    } catch (e) {
      GemsDebugUtils.logError('GemService', 'Error toggling favorite for gem $gemId: $e');
      return false;
    }
  }

  /// Get gems by rarity
  List<Gemstone> getGemsByRarity(GemRarity rarity, {bool userOnly = false}) {
    final gems = userOnly ? _userGems : _allGems;
    return gems.where((gem) => gem.rarityEnum == rarity).toList();
  }

  /// Get gems by element
  List<Gemstone> getGemsByElement(String element, {bool userOnly = false}) {
    final gems = userOnly ? _userGems : _allGems;
    return gems.where((gem) => gem.element.toLowerCase() == element.toLowerCase()).toList();
  }

  /// Search gems by text
  List<Gemstone> searchGems(String query, {bool userOnly = false}) {
    if (query.isEmpty) return userOnly ? _userGems : _allGems;
    
    final gems = userOnly ? _userGems : _allGems;
    final lowercaseQuery = query.toLowerCase();
    
    return gems.where((gem) {
      return gem.name.toLowerCase().contains(lowercaseQuery) ||
             gem.description.toLowerCase().contains(lowercaseQuery) ||
             gem.element.toLowerCase().contains(lowercaseQuery) ||
             gem.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }

  /// Get filtered and sorted gems
  List<Gemstone> getFilteredGems({
    String? searchQuery,
    GemRarity? rarity,
    String? element,
    String sortBy = 'name',
    bool ascending = true,
    bool userOnly = false,
  }) {
    List<Gemstone> gems = userOnly ? _userGems : _allGems;

    // Apply search filter
    if (searchQuery != null && searchQuery.isNotEmpty) {
      gems = searchGems(searchQuery, userOnly: userOnly);
    }

    // Apply rarity filter
    if (rarity != null) {
      gems = gems.where((gem) => gem.rarityEnum == rarity).toList();
    }

    // Apply element filter
    if (element != null && element != 'all') {
      gems = gems.where((gem) => gem.element.toLowerCase() == element.toLowerCase()).toList();
    }

    // Sort gems
    gems.sort((a, b) {
      int comparison;
      switch (sortBy) {
        case 'rarity':
          comparison = a.rarityEnum.index.compareTo(b.rarityEnum.index);
          break;
        case 'power':
          comparison = a.power.compareTo(b.power);
          break;
        case 'value':
          comparison = a.value.compareTo(b.value);
          break;
        case 'date':
          final aDate = a.unlockedAt ?? DateTime(2000);
          final bDate = b.unlockedAt ?? DateTime(2000);
          comparison = aDate.compareTo(bDate);
          break;
        default: // name
          comparison = a.name.compareTo(b.name);
      }
      return ascending ? comparison : -comparison;
    });

    return gems;
  }

  /// Check if user has specific gem
  bool hasGem(String gemId) {
    if (_currentUserId == null) return false;
    return _userGemCache['${_currentUserId}_$gemId'] == true;
  }

  /// Get random gem for discovery/reward systems
  Gemstone? getRandomGem({GemRarity? rarity, bool excludeOwned = true}) {
    List<Gemstone> availableGems = _allGems;
    
    if (excludeOwned && _currentUserId != null) {
      availableGems = availableGems.where((gem) => !hasGem(gem.id)).toList();
    }
    
    if (rarity != null) {
      availableGems = availableGems.where((gem) => gem.rarityEnum == rarity).toList();
    }
    
    if (availableGems.isEmpty) return null;
    
    final random = Random();
    return availableGems[random.nextInt(availableGems.length)];
  }

  /// Generate a random gem reward based on weighted probabilities
  Gemstone? generateRandomReward() {
    final random = Random();
    final roll = random.nextDouble();
    
    // Weighted probabilities for rarity
    GemRarity targetRarity;
    if (roll < 0.5) {
      targetRarity = GemRarity.common;
    } else if (roll < 0.75) {
      targetRarity = GemRarity.uncommon;
    } else if (roll < 0.9) {
      targetRarity = GemRarity.rare;
    } else if (roll < 0.98) {
      targetRarity = GemRarity.epic;
    } else {
      targetRarity = GemRarity.legendary;
    }
    
    return getRandomGem(rarity: targetRarity, excludeOwned: true);
  }

  /// Log gem unlock for analytics
  Future<void> _logGemUnlock(String userId, Gemstone gem, Map<String, dynamic> context) async {
    try {
      await _supabase.from('gem_unlock_analytics').insert({
        'user_id': userId,
        'gem_id': gem.id,
        'gem_name': gem.name,
        'gem_rarity': gem.rarity,
        'gem_element': gem.element,
        'trigger_type': context['trigger_type'] ?? 'unknown',
        'trigger_data': context,
        'unlocked_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      GemsDebugUtils.logError('GemService', 'Error logging gem unlock analytics: $e');
    }
  }

  /// Load sample gems for testing/fallback
  void _loadSampleGems() {
    _allGems = [
      const Gemstone(
        id: '1',
        name: 'Fire Ruby',
        description: 'A blazing gem that burns with eternal flame',
        imagePath: 'assets/gems/fire_ruby.png',
        rarity: 'legendary',
        element: 'fire',
        power: 95,
        value: 2000,
        category: 'elemental',
        tags: ['flame', 'power', 'rare'],
        sparkleIntensity: 2.0,
      ),
      const Gemstone(
        id: '2',
        name: 'Ocean Sapphire',
        description: 'Deep blue gem from the ocean depths',
        imagePath: 'assets/gems/ocean_sapphire.png',
        rarity: 'epic',
        element: 'water',
        power: 75,
        value: 1200,
        category: 'elemental',
        tags: ['ocean', 'wisdom', 'flow'],
        sparkleIntensity: 1.5,
      ),
      const Gemstone(
        id: '3',
        name: 'Wind Emerald',
        description: 'A light gem that dances with the breeze',
        imagePath: 'assets/gems/wind_emerald.png',
        rarity: 'rare',
        element: 'air',
        power: 60,
        value: 800,
        category: 'elemental',
        tags: ['wind', 'freedom', 'swift'],
        sparkleIntensity: 1.2,
      ),
      const Gemstone(
        id: '4',
        name: 'Earth Crystal',
        description: 'Solid and enduring, strength of the mountains',
        imagePath: 'assets/gems/earth_crystal.png',
        rarity: 'uncommon',
        element: 'earth',
        power: 45,
        value: 400,
        category: 'elemental',
        tags: ['earth', 'stability', 'endurance'],
        sparkleIntensity: 1.0,
      ),
      const Gemstone(
        id: '5',
        name: 'Simple Quartz',
        description: 'A common but beautiful clear crystal',
        imagePath: 'assets/gems/quartz.png',
        rarity: 'common',
        element: 'neutral',
        power: 25,
        value: 100,
        category: 'standard',
        tags: ['clear', 'pure', 'basic'],
        sparkleIntensity: 0.8,
      ),
    ];
  }

  /// Broadcast all updates to listeners
  void _broadcastUpdates() {
    _gemsController.add(_userGems);
    _statsController.add(_userStats);
  }

  /// Refresh all data
  Future<void> refresh() async {
    if (_currentUserId == null) return;
    await initialize(_currentUserId!);
  }

  /// Dispose resources
  void dispose() {
    _gemsController.close();
    _statsController.close();
    _unlockController.close();
  }
}
