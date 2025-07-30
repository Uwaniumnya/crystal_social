import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

class AuraService {
  final SupabaseClient supabase;
  
  // Cache for user auras to reduce database calls
  final Map<String, List<Map<String, dynamic>>> _auraCache = {};
  final Map<String, String?> _equippedAuraCache = {};
  Timer? _cacheTimer;

  AuraService(this.supabase) {
    _initializeCacheCleanup();
  }

  // Initialize cache cleanup timer
  void _initializeCacheCleanup() {
    _cacheTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _clearExpiredCache();
    });
  }

  // Clear expired cache entries
  void _clearExpiredCache() {
    _auraCache.clear();
    _equippedAuraCache.clear();
  }

  // Dispose of resources
  void dispose() {
    _cacheTimer?.cancel();
    _auraCache.clear();
    _equippedAuraCache.clear();
  }

  // Fetch the user's purchased aura effects (Inventory) with caching
  Future<List<Map<String, dynamic>>> fetchUserAuras(String userId) async {
    // Check cache first
    if (_auraCache.containsKey(userId)) {
      return _auraCache[userId]!;
    }

    try {
      final response = await supabase
          .from('user_aura_purchases')
          .select('aura_item_id, aura_items(id, name, description, rarity, color_code, effect_type, price, unlocked_at)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final auras = List<Map<String, dynamic>>.from(response);
      
      // Cache the result
      _auraCache[userId] = auras;
      
      return auras;
    } catch (e) {
      throw Exception('Error fetching user auras: $e');
    }
  }

  // Fetch the currently equipped aura color for a user with caching
  Future<String?> fetchEquippedAura(String userId) async {
    // Check cache first
    if (_equippedAuraCache.containsKey(userId)) {
      return _equippedAuraCache[userId];
    }

    try {
      final response = await supabase
          .from('user_profiles')
          .select('aura_color')
          .eq('id', userId)
          .single();

      final auraColor = response['aura_color'] as String?;
      
      // Cache the result
      _equippedAuraCache[userId] = auraColor;
      
      return auraColor;
    } catch (e) {
      throw Exception('Error fetching equipped aura: $e');
    }
  }

  // Update the equipped aura color for a user
  Future<void> updateEquippedAura(String userId, String auraColor) async {
    try {
      await supabase
          .from('user_profiles')
          .update({'aura_color': auraColor})
          .eq('id', userId);

      // Update cache
      _equippedAuraCache[userId] = auraColor;
      
      // Log aura change for statistics
      await _logAuraChange(userId, auraColor);
    } catch (e) {
      throw Exception('Error updating equipped aura: $e');
    }
  }

  // Purchase an aura for a user
  Future<bool> purchaseAura(String userId, String auraId, int cost) async {
    try {
      // Check if user has enough coins
      final userCoins = await _getUserCoins(userId);
      if (userCoins < cost) {
        return false;
      }

      // Check if user already owns this aura
      final ownedAuras = await fetchUserAuras(userId);
      final alreadyOwned = ownedAuras.any((aura) => 
          aura['aura_item_id'] == auraId);
      
      if (alreadyOwned) {
        throw Exception('User already owns this aura');
      }

      // Start a transaction
      await supabase.rpc('purchase_aura', params: {
        'user_id': userId,
        'aura_id': auraId,
        'cost': cost,
      });

      // Clear cache to force refresh
      _auraCache.remove(userId);
      
      return true;
    } catch (e) {
      throw Exception('Error purchasing aura: $e');
    }
  }

  // Get available auras in the shop
  Future<List<Map<String, dynamic>>> getShopAuras(String userId) async {
    try {
      final response = await supabase
          .from('aura_items')
          .select('*')
          .order('rarity', ascending: false)
          .order('price', ascending: true);

      final allAuras = List<Map<String, dynamic>>.from(response);
      
      // Get user's owned auras to filter them out
      final ownedAuras = await fetchUserAuras(userId);
      final ownedAuraIds = ownedAuras
          .map((aura) => aura['aura_item_id'])
          .toSet();

      // Filter out owned auras
      final shopAuras = allAuras.where((aura) => 
          !ownedAuraIds.contains(aura['id'])).toList();

      return shopAuras;
    } catch (e) {
      throw Exception('Error fetching shop auras: $e');
    }
  }

  // Get aura statistics for a user
  Future<Map<String, dynamic>> getAuraStatistics(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statsJson = prefs.getString('aura_stats_$userId');
      
      if (statsJson != null) {
        final stats = json.decode(statsJson) as Map<String, dynamic>;
        return {
          'total_owned': await _getTotalOwnedAuras(userId),
          'total_changes': stats['total_changes'] ?? 0,
          'favorite_aura': stats['favorite_aura'] ?? 'None',
          'last_change': stats['last_change'] ?? 'Never',
          'rarity_distribution': await _getRarityDistribution(userId),
          'total_spent': stats['total_spent'] ?? 0,
        };
      }

      return {
        'total_owned': await _getTotalOwnedAuras(userId),
        'total_changes': 0,
        'favorite_aura': 'None',
        'last_change': 'Never',
        'rarity_distribution': await _getRarityDistribution(userId),
        'total_spent': 0,
      };
    } catch (e) {
      throw Exception('Error fetching aura statistics: $e');
    }
  }

  // Get aura combinations (special effects)
  Future<List<Map<String, dynamic>>> getAuraCombinations(String userId) async {
    try {
      final ownedAuras = await fetchUserAuras(userId);
      final combinations = <Map<String, dynamic>>[];

      // Define some example combinations
      final combos = [
        {
          'name': 'Rainbow Master',
          'description': 'Own 7 different colored auras',
          'required_auras': ['red', 'blue', 'green', 'yellow', 'purple', 'orange', 'pink'],
          'reward': 'Special rainbow effect',
          'coins_bonus': 100,
        },
        {
          'name': 'Legendary Collector',
          'description': 'Own 3 legendary auras',
          'required_rarity': 'legendary',
          'required_count': 3,
          'reward': 'Legendary aura glow',
          'coins_bonus': 500,
        },
        {
          'name': 'Epic Enthusiast',
          'description': 'Own 5 epic auras',
          'required_rarity': 'epic',
          'required_count': 5,
          'reward': 'Epic sparkle effect',
          'coins_bonus': 250,
        },
      ];

      for (final combo in combos) {
        final isUnlocked = await _checkComboUnlocked(combo, ownedAuras);
        combinations.add({
          ...combo,
          'unlocked': isUnlocked,
        });
      }

      return combinations;
    } catch (e) {
      throw Exception('Error fetching aura combinations: $e');
    }
  }

  // Get recommended auras for a user
  Future<List<Map<String, dynamic>>> getRecommendedAuras(String userId) async {
    try {
      final shopAuras = await getShopAuras(userId);
      
      // Get user's most used rarity
      final rarityDistribution = await _getRarityDistribution(userId);
      
      String favoriteRarity = 'common';
      if (rarityDistribution.isNotEmpty) {
        favoriteRarity = rarityDistribution.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;
      }

      // Filter recommendations based on favorite rarity
      final recommendations = shopAuras.where((aura) => 
          aura['rarity'] == favoriteRarity ||
          aura['rarity'] == 'epic' ||
          aura['rarity'] == 'legendary'
      ).take(5).toList();

      return recommendations;
    } catch (e) {
      throw Exception('Error fetching recommended auras: $e');
    }
  }

  // Private helper methods
  Future<void> _logAuraChange(String userId, String auraColor) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statsJson = prefs.getString('aura_stats_$userId');
      final stats = statsJson != null 
          ? Map<String, dynamic>.from(json.decode(statsJson))
          : <String, dynamic>{};

      stats['total_changes'] = (stats['total_changes'] ?? 0) + 1;
      stats['last_change'] = DateTime.now().toIso8601String();
      
      // Update favorite aura (most used)
      final auraUsage = Map<String, int>.from(stats['aura_usage'] ?? {});
      auraUsage[auraColor] = (auraUsage[auraColor] ?? 0) + 1;
      stats['aura_usage'] = auraUsage;
      
      final mostUsed = auraUsage.entries
          .reduce((a, b) => a.value > b.value ? a : b);
      stats['favorite_aura'] = mostUsed.key;

      await prefs.setString('aura_stats_$userId', json.encode(stats));
    } catch (e) {
      // Silent fail for statistics
    }
  }

  Future<int> _getUserCoins(String userId) async {
    final response = await supabase
        .from('user_profiles')
        .select('coins')
        .eq('id', userId)
        .single();
    
    return response['coins'] ?? 0;
  }

  Future<int> _getTotalOwnedAuras(String userId) async {
    final auras = await fetchUserAuras(userId);
    return auras.length;
  }

  Future<Map<String, int>> _getRarityDistribution(String userId) async {
    final auras = await fetchUserAuras(userId);
    final distribution = <String, int>{};

    for (final aura in auras) {
      final rarity = aura['aura_items']['rarity'] as String? ?? 'common';
      distribution[rarity] = (distribution[rarity] ?? 0) + 1;
    }

    return distribution;
  }

  Future<bool> _checkComboUnlocked(
      Map<String, dynamic> combo, 
      List<Map<String, dynamic>> ownedAuras) async {
    
    if (combo.containsKey('required_auras')) {
      final requiredAuras = List<String>.from(combo['required_auras']);
      final ownedColors = ownedAuras
          .map((aura) => aura['aura_items']['color_code'] as String?)
          .where((color) => color != null)
          .toSet();
      
      return requiredAuras.every((color) => ownedColors.contains(color));
    }
    
    if (combo.containsKey('required_rarity')) {
      final requiredRarity = combo['required_rarity'] as String;
      final requiredCount = combo['required_count'] as int;
      final matchingAuras = ownedAuras.where((aura) => 
          aura['aura_items']['rarity'] == requiredRarity).length;
      
      return matchingAuras >= requiredCount;
    }
    
    return false;
  }
}
