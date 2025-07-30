import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'rewards_service.dart';

/// Comprehensive Inventory Access Helper
/// Provides easy methods for other systems to check and manage user inventory
class InventoryAccessHelper {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Check if user owns a specific item by ID
  static Future<bool> userOwnsItem(String userId, int itemId) async {
    try {
      final result = await _supabase
          .from('user_inventory')
          .select('item_id')
          .eq('user_id', userId)
          .eq('item_id', itemId)
          .maybeSingle();
      
      return result != null;
    } catch (e) {
      debugPrint('Error checking item ownership: $e');
      return false;
    }
  }

  /// Check if user owns a specific item by name
  static Future<bool> userOwnsItemByName(String userId, String itemName) async {
    try {
      // First get item ID from shop_items
      final shopItem = await _supabase
          .from('shop_items')
          .select('id')
          .eq('name', itemName)
          .maybeSingle();
      
      if (shopItem == null) return false;
      
      return await userOwnsItem(userId, shopItem['id']);
    } catch (e) {
      debugPrint('Error checking item ownership by name: $e');
      return false;
    }
  }

  /// Get all items user owns in a specific category
  static Future<List<Map<String, dynamic>>> getUserItemsByCategory(
    String userId, 
    int categoryId
  ) async {
    try {
      final result = await _supabase
          .from('user_inventory')
          .select('''
            *,
            shop_items!inner (
              id,
              name,
              description,
              category_id,
              rarity,
              image_url,
              asset_path
            )
          ''')
          .eq('user_id', userId)
          .eq('shop_items.category_id', categoryId);
      
      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      debugPrint('Error getting user items by category: $e');
      return [];
    }
  }

  /// Get user's auras (category_id = 2)
  static Future<List<Map<String, dynamic>>> getUserAuras(String userId) async {
    return await getUserItemsByCategory(userId, 2);
  }

  /// Get user's pets (category_id = 3) 
  static Future<List<Map<String, dynamic>>> getUserPets(String userId) async {
    return await getUserItemsByCategory(userId, 3);
  }

  /// Get user's pet accessories (category_id = 4)
  static Future<List<Map<String, dynamic>>> getUserPetAccessories(String userId) async {
    return await getUserItemsByCategory(userId, 4);
  }

  /// Get user's avatar decorations (category_id = 1)
  static Future<List<Map<String, dynamic>>> getUserAvatarDecorations(String userId) async {
    return await getUserItemsByCategory(userId, 1);
  }

  /// Add item to user inventory (for admins/achievements/gifts)
  static Future<bool> addItemToUserInventory({
    required String userId,
    required int itemId,
    required String source, // 'achievement', 'gift', 'admin', etc.
    int quantity = 1,
    int purchasePrice = 0,
  }) async {
    try {
      // Verify item exists in shop_items
      final shopItem = await _supabase
          .from('shop_items')
          .select('id, name, category_id')
          .eq('id', itemId)
          .maybeSingle();
      
      if (shopItem == null) {
        debugPrint('Error: Item $itemId does not exist in shop_items');
        return false;
      }
      
      // Check if user already owns this item (for non-stackable items)
      final existingItem = await _supabase
          .from('user_inventory')
          .select('item_id')
          .eq('user_id', userId)
          .eq('item_id', itemId)
          .maybeSingle();
      
      if (existingItem != null) {
        debugPrint('User $userId already owns item $itemId');
        return false; // Don't add duplicates
      }
      
      // Add to inventory
      await _supabase.from('user_inventory').insert({
        'user_id': userId,
        'item_id': itemId,
        'quantity': quantity,
        'purchased_at': DateTime.now().toIso8601String(),
        'purchase_price': purchasePrice,
        'source': source,
        'category_reference_id': shopItem['category_id'],
      });
      
      debugPrint('✁EAdded item ${shopItem['name']} to user $userId inventory');
      
      // Refresh rewards service cache if initialized
      try {
        final rewardsService = RewardsService.instance;
        if (rewardsService.isInitialized) {
          await rewardsService.refresh();
        }
      } catch (e) {
        // RewardsService might not be initialized, that's ok
      }
      
      return true;
    } catch (e) {
      debugPrint('Error adding item to inventory: $e');
      return false;
    }
  }

  /// Get user's inventory count by category
  static Future<Map<String, int>> getUserInventoryStats(String userId) async {
    try {
      final result = await _supabase
          .from('user_inventory')
          .select('''
            shop_items!inner (category_id)
          ''')
          .eq('user_id', userId);
      
      final stats = <String, int>{};
      for (final item in result) {
        final categoryId = item['shop_items']['category_id'];
        final categoryName = _getCategoryName(categoryId);
        stats[categoryName] = (stats[categoryName] ?? 0) + 1;
      }
      
      return stats;
    } catch (e) {
      debugPrint('Error getting inventory stats: $e');
      return {};
    }
  }

  /// Check if user owns any items in a category
  static Future<bool> userOwnsAnyInCategory(String userId, int categoryId) async {
    try {
      final result = await _supabase
          .from('user_inventory')
          .select('''
            shop_items!inner (category_id)
          ''')
          .eq('user_id', userId)
          .eq('shop_items.category_id', categoryId)
          .limit(1);
      
      return result.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking category ownership: $e');
      return false;
    }
  }

  /// Get user's most recent purchases
  static Future<List<Map<String, dynamic>>> getUserRecentPurchases(
    String userId, {
    int limit = 10,
  }) async {
    try {
      final result = await _supabase
          .from('user_inventory')
          .select('''
            *,
            shop_items (
              id,
              name,
              description,
              image_url,
              category_id,
              rarity
            )
          ''')
          .eq('user_id', userId)
          .order('purchased_at', ascending: false)
          .limit(limit);
      
      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      debugPrint('Error getting recent purchases: $e');
      return [];
    }
  }

  /// Search user's inventory
  static Future<List<Map<String, dynamic>>> searchUserInventory(
    String userId, 
    String searchTerm
  ) async {
    try {
      final result = await _supabase
          .from('user_inventory')
          .select('''
            *,
            shop_items (
              id,
              name,
              description,
              image_url,
              category_id,
              rarity
            )
          ''')
          .eq('user_id', userId)
          .ilike('shop_items.name', '%$searchTerm%');
      
      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      debugPrint('Error searching inventory: $e');
      return [];
    }
  }

  /// Bulk check ownership of multiple items
  static Future<Map<int, bool>> checkMultipleItemOwnership(
    String userId, 
    List<int> itemIds
  ) async {
    try {
      final result = await _supabase
          .from('user_inventory')
          .select('item_id')
          .eq('user_id', userId)
          .filter('item_id', 'in', '(${itemIds.join(',')})');
      
      final ownedIds = result.map((item) => item['item_id'] as int).toSet();
      
      final ownership = <int, bool>{};
      for (final itemId in itemIds) {
        ownership[itemId] = ownedIds.contains(itemId);
      }
      
      return ownership;
    } catch (e) {
      debugPrint('Error checking multiple item ownership: $e');
      return {};
    }
  }

  /// Get total value of user's inventory
  static Future<int> getUserInventoryValue(String userId) async {
    try {
      final result = await _supabase
          .from('user_inventory')
          .select('''
            purchase_price,
            shop_items (price)
          ''')
          .eq('user_id', userId);
      
      int totalValue = 0;
      for (final item in result) {
        // Use purchase price if available, otherwise use current shop price
        final value = item['purchase_price'] ?? item['shop_items']['price'] ?? 0;
        totalValue += value as int;
      }
      
      return totalValue;
    } catch (e) {
      debugPrint('Error calculating inventory value: $e');
      return 0;
    }
  }

  /// Helper method to get category name
  static String _getCategoryName(int categoryId) {
    switch (categoryId) {
      case 1: return 'Avatar Decorations';
      case 2: return 'Auras';
      case 3: return 'Pets';
      case 4: return 'Pet Accessories';
      case 5: return 'Furniture';
      case 6: return 'Tarot Decks';
      case 7: return 'Booster Packs';
      default: return 'Unknown';
    }
  }
}

/// Extension on RewardsService for enhanced inventory access
extension InventoryExtensions on RewardsService {
  /// Check if user owns specific item by name
  Future<bool> ownsItemByName(String itemName) async {
    return userInventory.any((item) => item['name'] == itemName);
  }
  
  /// Get items by category from current inventory
  List<Map<String, dynamic>> getItemsByCategory(int categoryId) {
    return userInventory.where((item) => item['category_id'] == categoryId).toList();
  }
  
  /// Get auras from current inventory
  List<Map<String, dynamic>> getOwnedAuras() => getItemsByCategory(2);
  
  /// Get pets from current inventory  
  List<Map<String, dynamic>> getOwnedPets() => getItemsByCategory(3);
  
  /// Get pet accessories from current inventory
  List<Map<String, dynamic>> getOwnedPetAccessories() => getItemsByCategory(4);
  
  /// Get avatar decorations from current inventory
  List<Map<String, dynamic>> getOwnedAvatarDecorations() => getItemsByCategory(1);
}
