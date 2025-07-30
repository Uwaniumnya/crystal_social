import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'rewards_manager.dart';
import 'aura_service.dart';
import 'dart:async';

/// Centralized rewards service that coordinates all reward-related functionality
/// This service acts as the single source of truth for all rewards operations
class RewardsService extends ChangeNotifier {
  static RewardsService? _instance;
  static RewardsService get instance {
    _instance ??= RewardsService._internal();
    return _instance!;
  }

  RewardsService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  late final RewardsManager _rewardsManager;
  late final AuraService _auraService;

  // State management
  bool _isInitialized = false;
  String? _currentUserId;
  Map<String, dynamic> _userRewards = {};
  List<Map<String, dynamic>> _userInventory = [];
  List<Map<String, dynamic>> _shopItems = [];
  List<Map<String, dynamic>> _achievements = [];
  UserStats? _userStats;
  bool _isLoading = false;
  String? _error;

  // Stream controllers for real-time updates
  final StreamController<Map<String, dynamic>> _rewardsController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<List<Map<String, dynamic>>> _inventoryController = 
      StreamController<List<Map<String, dynamic>>>.broadcast();
  final StreamController<List<Map<String, dynamic>>> _achievementsController = 
      StreamController<List<Map<String, dynamic>>>.broadcast();

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentUserId => _currentUserId;
  Map<String, dynamic> get userRewards => Map.from(_userRewards);
  List<Map<String, dynamic>> get userInventory => List.from(_userInventory);
  List<Map<String, dynamic>> get shopItems => List.from(_shopItems);
  List<Map<String, dynamic>> get achievements => List.from(_achievements);
  Map<String, dynamic> get userStats {
    if (_userStats == null) return {};
    return {
      'totalPurchases': _userStats!.totalPurchases,
      'totalSpent': _userStats!.totalSpent,
      'achievementsUnlocked': _userStats!.achievementsUnlocked,
      'levelUps': _userStats!.levelUps,
      'lastLogin': _userStats!.lastLogin?.toIso8601String(),
      'loginStreak': _userStats!.loginStreak,
      'favoriteCategory': _userStats!.favoriteCategory,
      'averageSessionTime': _userStats!.averageSessionTime,
    };
  }

  // Stream getters
  Stream<Map<String, dynamic>> get rewardsStream => _rewardsController.stream;
  Stream<List<Map<String, dynamic>>> get inventoryStream => _inventoryController.stream;
  Stream<List<Map<String, dynamic>>> get achievementsStream => _achievementsController.stream;

  // Access to underlying services
  RewardsManager get rewardsManager => _rewardsManager;
  AuraService get auraService => _auraService;

  /// Initialize the rewards service with a user
  Future<void> initialize(String userId) async {
    if (_isInitialized && _currentUserId == userId) return;

    try {
      _setLoading(true);
      _clearError();

      _currentUserId = userId;
      _rewardsManager = RewardsManager(_supabase);
      _auraService = AuraService(_supabase);

      // Load all user data in parallel
      await Future.wait([
        _loadUserRewards(),
        _loadUserInventory(),
        _loadShopItems(),
        _loadAchievements(),
        _loadUserStats(),
      ]);

      _isInitialized = true;
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to initialize rewards service: $e');
      _setLoading(false);
      debugPrint('RewardsService initialization error: $e');
    }
  }

  /// Refresh all data
  Future<void> refresh() async {
    if (!_isInitialized || _currentUserId == null) return;
    await initialize(_currentUserId!);
  }

  /// Load user rewards (coins, points, etc.)
  Future<void> _loadUserRewards() async {
    try {
      final rewards = await _rewardsManager.getUserRewards(_currentUserId!);
      _userRewards = rewards;
      _rewardsController.add(rewards);
    } catch (e) {
      debugPrint('Error loading user rewards: $e');
    }
  }

  /// Load user inventory
  Future<void> _loadUserInventory() async {
    try {
      final inventory = await _rewardsManager.getUserInventory(_currentUserId!);
      _userInventory = inventory;
      _inventoryController.add(inventory);
    } catch (e) {
      debugPrint('Error loading user inventory: $e');
    }
  }

  /// Load shop items
  Future<void> _loadShopItems() async {
    try {
      // Load items from multiple categories
      final categories = [1, 2, 3, 7, 8]; // aura, background, pet, booster, decorations
      List<Map<String, dynamic>> allItems = [];
      
      for (int categoryId in categories) {
        final items = await _rewardsManager.getShopItems(categoryId);
        allItems.addAll(items);
      }
      
      _shopItems = allItems;
    } catch (e) {
      debugPrint('Error loading shop items: $e');
    }
  }

  /// Load achievements - placeholder since method doesn't exist
  Future<void> _loadAchievements() async {
    try {
      // For now, use empty list until achievements API is available
      _achievements = [];
      _achievementsController.add(_achievements);
    } catch (e) {
      debugPrint('Error loading achievements: $e');
    }
  }

  /// Load user statistics
  Future<void> _loadUserStats() async {
    try {
      _userStats = await _rewardsManager.getUserStats(_currentUserId!);
    } catch (e) {
      debugPrint('Error loading user stats: $e');
    }
  }

  /// Purchase an item from the shop
  Future<bool> purchaseItem(Map<String, dynamic> item, BuildContext context) async {
    if (!_isInitialized || _currentUserId == null) return false;

    try {
      _setLoading(true);
      _clearError();

      final result = await _rewardsManager.purchaseItem(_currentUserId!, item['id'], context);
      
      if (result['success'] == true) {
        // Refresh relevant data
        await Future.wait([
          _loadUserRewards(),
          _loadUserInventory(),
        ]);
        notifyListeners();
        _setLoading(false);
        return true;
      } else {
        _setError(result['error'] ?? 'Purchase failed');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Failed to purchase item: $e');
      _setLoading(false);
      return false;
    }
  }

  /// Open a booster pack - placeholder for now
  Future<List<Map<String, dynamic>>?> openBoosterPack(Map<String, dynamic> boosterPack) async {
    if (!_isInitialized || _currentUserId == null) return null;

    try {
      _setLoading(true);
      _clearError();

      // For now, return empty list until booster pack opening is properly implemented
      // This functionality would need to be added to RewardsManager
      
      // Refresh inventory
      await _loadUserInventory();
      notifyListeners();

      _setLoading(false);
      return [];
    } catch (e) {
      _setError('Failed to open booster pack: $e');
      _setLoading(false);
      return null;
    }
  }

  /// Equip an aura
  Future<bool> equipAura(String auraColor) async {
    if (!_isInitialized || _currentUserId == null) return false;

    try {
      await _auraService.updateEquippedAura(_currentUserId!, auraColor);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to equip aura: $e');
      return false;
    }
  }

  /// Claim daily reward
  Future<Map<String, dynamic>?> claimDailyReward() async {
    if (!_isInitialized || _currentUserId == null) return null;

    try {
      _setLoading(true);
      _clearError();

      final result = await _rewardsManager.handleDailyLogin(_currentUserId!);
      
      if (!result['already_claimed']) {
        await _loadUserRewards();
        notifyListeners();
      }

      _setLoading(false);
      return result;
    } catch (e) {
      _setError('Failed to claim daily reward: $e');
      _setLoading(false);
      return null;
    }
  }

  /// Award achievement - placeholder for now
  Future<bool> awardAchievement(String achievementId) async {
    if (!_isInitialized || _currentUserId == null) return false;

    try {
      // For now, return true until achievement system is properly implemented
      // This functionality would need to be added to RewardsManager
      
      await Future.wait([
        _loadAchievements(),
        _loadUserRewards(),
      ]);
      notifyListeners();

      return true;
    } catch (e) {
      _setError('Failed to award achievement: $e');
      return false;
    }
  }

  /// Get filtered shop items
  List<Map<String, dynamic>> getFilteredShopItems({
    int? categoryId,
    String? searchQuery,
    int? minPrice,
    int? maxPrice,
    String? rarity,
  }) {
    var filtered = _shopItems;

    if (categoryId != null) {
      filtered = filtered.where((item) => item['category_id'] == categoryId).toList();
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      filtered = filtered.where((item) =>
          item['name'].toLowerCase().contains(searchQuery.toLowerCase()) ||
          item['description'].toLowerCase().contains(searchQuery.toLowerCase())
      ).toList();
    }

    if (minPrice != null) {
      filtered = filtered.where((item) => item['price'] >= minPrice).toList();
    }

    if (maxPrice != null) {
      filtered = filtered.where((item) => item['price'] <= maxPrice).toList();
    }

    if (rarity != null) {
      filtered = filtered.where((item) => item['rarity'] == rarity).toList();
    }

    return filtered;
  }

  /// Get filtered inventory items
  List<Map<String, dynamic>> getFilteredInventoryItems({
    String? type,
    String? searchQuery,
    String? rarity,
  }) {
    var filtered = _userInventory;

    if (type != null && type != 'all') {
      filtered = filtered.where((item) => item['type'] == type).toList();
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      filtered = filtered.where((item) =>
          item['name'].toLowerCase().contains(searchQuery.toLowerCase()) ||
          (item['description'] ?? '').toLowerCase().contains(searchQuery.toLowerCase())
      ).toList();
    }

    if (rarity != null) {
      filtered = filtered.where((item) => item['rarity'] == rarity).toList();
    }

    return filtered;
  }

  /// Check if user can afford an item
  bool canAffordItem(Map<String, dynamic> item) {
    final price = item['price'] as int? ?? 0;
    final userCoins = _userRewards['coins'] as int? ?? 0;
    return userCoins >= price;
  }

  /// Check if user owns an item
  bool ownsItem(int itemId) {
    return _userInventory.any((item) => item['id'] == itemId);
  }

  /// Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _rewardsController.close();
    _inventoryController.close();
    _achievementsController.close();
    _auraService.dispose();
    super.dispose();
  }

  /// Cleanup when user logs out
  void cleanup() {
    _isInitialized = false;
    _currentUserId = null;
    _userRewards.clear();
    _userInventory.clear();
    _shopItems.clear();
    _achievements.clear();
    _userStats = null;
    _clearError();
    _setLoading(false);
    notifyListeners();
  }
}
