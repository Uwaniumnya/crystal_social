// Global Pet Accessory System
// This system provides universal accessories that work with all pets

import 'package:flutter/material.dart';

// Accessory categories for organization
enum AccessoryCategory {
  headwear,
  neckwear, 
  clothing,
  magical,
  seasonal,
  premium
}

enum AccessoryRarity {
  common,
  rare,
  epic,
  legendary,
  mythical
}

// Global accessory class
class GlobalAccessory {
  final String id;
  final String name;
  final String description;
  final AccessoryCategory category;
  final AccessoryRarity rarity;
  final double shopPrice;
  final String shopCategory;
  final String iconAsset; // Icon for shop/inventory display
  final Map<String, String> petAssetOverrides; // pet_id -> asset_path for this accessory
  final bool isAnimated;
  final List<String> tags;
  final String lore;

  const GlobalAccessory({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.rarity,
    required this.shopPrice,
    required this.shopCategory,
    required this.iconAsset,
    this.petAssetOverrides = const {},
    this.isAnimated = false,
    this.tags = const [],
    this.lore = '',
  });

  // Get the asset path for this accessory on a specific pet
  String getAssetPathForPet(String petId, String baseAssetPath) {
    // If there's a specific override for this pet, use it
    if (petAssetOverrides.containsKey(petId)) {
      return petAssetOverrides[petId]!;
    }
    
    // Otherwise, construct the path using the standard naming convention
    // e.g., assets/pets/cat.png -> assets/pets/cat_crown.png
    final pathParts = baseAssetPath.split('/');
    final fileName = pathParts.last.split('.');
    final baseName = fileName[0];
    final extension = fileName[1];
    
    pathParts[pathParts.length - 1] = '${baseName}_${id}.${extension}';
    return pathParts.join('/');
  }

  Color get rarityColor {
    switch (rarity) {
      case AccessoryRarity.common:
        return Colors.grey;
      case AccessoryRarity.rare:
        return Colors.blue;
      case AccessoryRarity.epic:
        return Colors.purple;
      case AccessoryRarity.legendary:
        return Colors.orange;
      case AccessoryRarity.mythical:
        return Colors.pink;
    }
  }

  IconData get categoryIcon {
    switch (category) {
      case AccessoryCategory.headwear:
        return Icons.emoji_objects;
      case AccessoryCategory.neckwear:
        return Icons.favorite;
      case AccessoryCategory.clothing:
        return Icons.checkroom;
      case AccessoryCategory.magical:
        return Icons.auto_awesome;
      case AccessoryCategory.seasonal:
        return Icons.celebration;
      case AccessoryCategory.premium:
        return Icons.diamond;
    }
  }
}

// Global accessories available for all pets
final List<GlobalAccessory> globalAccessories = [
  // Common Accessories (Free/Low Cost)
  const GlobalAccessory(
    id: 'bow',
    name: 'Cute Bow',
    description: 'A simple and adorable bow that suits any pet',
    category: AccessoryCategory.headwear,
    rarity: AccessoryRarity.common,
    shopPrice: 0, // Free starter accessory
    shopCategory: 'pet_accessory',
    iconAsset: 'assets/accessories/bow_icon.png',
    tags: ['cute', 'basic', 'pink'],
    lore: 'Every pet deserves to feel pretty!',
  ),

  const GlobalAccessory(
    id: 'collar',
    name: 'Classic Collar',
    description: 'A timeless collar that shows your pet belongs to a loving family',
    category: AccessoryCategory.neckwear,
    rarity: AccessoryRarity.common,
    shopPrice: 50,
    shopCategory: 'pet_accessory',
    iconAsset: 'assets/accessories/collar_icon.png',
    tags: ['classic', 'red', 'identification'],
    lore: 'A symbol of love and belonging.',
  ),

  const GlobalAccessory(
    id: 'hat',
    name: 'Little Hat',
    description: 'A tiny hat that makes any pet look distinguished',
    category: AccessoryCategory.headwear,
    rarity: AccessoryRarity.common,
    shopPrice: 100,
    shopCategory: 'pet_accessory',
    iconAsset: 'assets/accessories/hat_icon.png',
    tags: ['formal', 'cute', 'black'],
    lore: 'Perfect for formal occasions and photo shoots.',
  ),

  const GlobalAccessory(
    id: 'scarf',
    name: 'Cozy Scarf',
    description: 'A warm scarf to keep your pet comfortable in any weather',
    category: AccessoryCategory.clothing,
    rarity: AccessoryRarity.common,
    shopPrice: 75,
    shopCategory: 'pet_accessory',
    iconAsset: 'assets/accessories/scarf_icon.png',
    tags: ['warm', 'winter', 'blue'],
    lore: 'Handknitted with love and care.',
  ),

  // Rare Accessories
  const GlobalAccessory(
    id: 'crown',
    name: 'Royal Crown',
    description: 'A magnificent crown for pets of royal blood',
    category: AccessoryCategory.headwear,
    rarity: AccessoryRarity.rare,
    shopPrice: 500,
    shopCategory: 'pet_accessory',
    iconAsset: 'assets/accessories/crown_icon.png',
    tags: ['royal', 'gold', 'prestigious'],
    lore: 'Worn by the most noble of companions.',
  ),

  const GlobalAccessory(
    id: 'gem_necklace',
    name: 'Gem Necklace',
    description: 'A sparkling necklace with precious gems',
    category: AccessoryCategory.neckwear,
    rarity: AccessoryRarity.rare,
    shopPrice: 800,
    shopCategory: 'pet_accessory',
    iconAsset: 'assets/accessories/gem_necklace_icon.png',
    tags: ['gems', 'sparkly', 'expensive'],
    lore: 'Each gem holds the power of friendship.',
  ),

  const GlobalAccessory(
    id: 'wizard_hat',
    name: 'Wizard Hat',
    description: 'A mystical hat that enhances your pet\'s magical abilities',
    category: AccessoryCategory.magical,
    rarity: AccessoryRarity.rare,
    shopPrice: 1000,
    shopCategory: 'pet_accessory',
    iconAsset: 'assets/accessories/wizard_hat_icon.png',
    tags: ['magical', 'purple', 'stars'],
    lore: 'Crafted by ancient pet wizards.',
  ),

  // Epic Accessories
  const GlobalAccessory(
    id: 'angel_wings',
    name: 'Angel Wings',
    description: 'Heavenly wings that make your pet look divine',
    category: AccessoryCategory.magical,
    rarity: AccessoryRarity.epic,
    shopPrice: 2000,
    shopCategory: 'premium_pet_accessory',
    iconAsset: 'assets/accessories/angel_wings_icon.png',
    isAnimated: true,
    tags: ['wings', 'holy', 'white', 'flying'],
    lore: 'Blessed by celestial beings.',
  ),

  const GlobalAccessory(
    id: 'flame_crown',
    name: 'Crown of Flames',
    description: 'A crown wreathed in eternal flames',
    category: AccessoryCategory.magical,
    rarity: AccessoryRarity.epic,
    shopPrice: 2500,
    shopCategory: 'premium_pet_accessory',
    iconAsset: 'assets/accessories/flame_crown_icon.png',
    isAnimated: true,
    tags: ['fire', 'magical', 'crown', 'power'],
    lore: 'Forged in the fires of dragon breath.',
  ),

  const GlobalAccessory(
    id: 'ice_armor',
    name: 'Ice Armor',
    description: 'Crystalline armor that protects and dazzles',
    category: AccessoryCategory.clothing,
    rarity: AccessoryRarity.epic,
    shopPrice: 3000,
    shopCategory: 'premium_pet_accessory',
    iconAsset: 'assets/accessories/ice_armor_icon.png',
    isAnimated: true,
    tags: ['ice', 'armor', 'protection', 'blue'],
    lore: 'Formed from eternal ice that never melts.',
  ),

  // Legendary Accessories
  const GlobalAccessory(
    id: 'phoenix_feather',
    name: 'Phoenix Feather Crown',
    description: 'A crown adorned with genuine phoenix feathers',
    category: AccessoryCategory.magical,
    rarity: AccessoryRarity.legendary,
    shopPrice: 10000,
    shopCategory: 'legendary_pet_accessory',
    iconAsset: 'assets/accessories/phoenix_feather_icon.png',
    isAnimated: true,
    tags: ['phoenix', 'fire', 'rebirth', 'legendary'],
    lore: 'Each feather contains the essence of eternal life.',
  ),

  const GlobalAccessory(
    id: 'time_pendant',
    name: 'Pendant of Time',
    description: 'A mystical pendant that manipulates time itself',
    category: AccessoryCategory.neckwear,
    rarity: AccessoryRarity.legendary,
    shopPrice: 15000,
    shopCategory: 'legendary_pet_accessory',
    iconAsset: 'assets/accessories/time_pendant_icon.png',
    isAnimated: true,
    tags: ['time', 'magic', 'powerful', 'ancient'],
    lore: 'Created by the first time mages.',
  ),

  // Mythical Accessories
  const GlobalAccessory(
    id: 'cosmic_halo',
    name: 'Cosmic Halo',
    description: 'A halo made from stardust and cosmic energy',
    category: AccessoryCategory.magical,
    rarity: AccessoryRarity.mythical,
    shopPrice: 50000,
    shopCategory: 'mythical_pet_accessory',
    iconAsset: 'assets/accessories/cosmic_halo_icon.png',
    isAnimated: true,
    tags: ['cosmic', 'stars', 'divine', 'ultimate'],
    lore: 'The ultimate symbol of cosmic harmony.',
  ),

  const GlobalAccessory(
    id: 'void_cloak',
    name: 'Cloak of the Void',
    description: 'A cloak woven from the fabric of space itself',
    category: AccessoryCategory.clothing,
    rarity: AccessoryRarity.mythical,
    shopPrice: 75000,
    shopCategory: 'mythical_pet_accessory',
    iconAsset: 'assets/accessories/void_cloak_icon.png',
    isAnimated: true,
    tags: ['void', 'space', 'mysterious', 'powerful'],
    lore: 'Said to grant the wearer control over reality itself.',
  ),

  // Seasonal Accessories
  const GlobalAccessory(
    id: 'santa_hat',
    name: 'Santa Hat',
    description: 'A festive hat perfect for the holiday season',
    category: AccessoryCategory.seasonal,
    rarity: AccessoryRarity.common,
    shopPrice: 200,
    shopCategory: 'seasonal_pet_accessory',
    iconAsset: 'assets/accessories/santa_hat_icon.png',
    tags: ['christmas', 'red', 'festive', 'holiday'],
    lore: 'Spread holiday cheer with your pet!',
  ),

  const GlobalAccessory(
    id: 'flower_crown',
    name: 'Spring Flower Crown',
    description: 'A beautiful crown of fresh spring flowers',
    category: AccessoryCategory.seasonal,
    rarity: AccessoryRarity.common,
    shopPrice: 150,
    shopCategory: 'seasonal_pet_accessory',
    iconAsset: 'assets/accessories/flower_crown_icon.png',
    tags: ['spring', 'flowers', 'nature', 'beautiful'],
    lore: 'Celebrate the beauty of spring with nature\'s crown.',
  ),

  const GlobalAccessory(
    id: 'pumpkin_hat',
    name: 'Pumpkin Hat',
    description: 'A spooky pumpkin hat perfect for Halloween',
    category: AccessoryCategory.seasonal,
    rarity: AccessoryRarity.common,
    shopPrice: 180,
    shopCategory: 'seasonal_pet_accessory',
    iconAsset: 'assets/accessories/pumpkin_hat_icon.png',
    tags: ['halloween', 'pumpkin', 'spooky', 'orange'],
    lore: 'Get into the Halloween spirit!',
  ),
];

// Utility functions for global accessories
class GlobalAccessoryUtils {
  static List<GlobalAccessory> getAccessoriesByCategory(AccessoryCategory category) {
    return globalAccessories.where((accessory) => accessory.category == category).toList();
  }

  static List<GlobalAccessory> getAccessoriesByRarity(AccessoryRarity rarity) {
    return globalAccessories.where((accessory) => accessory.rarity == rarity).toList();
  }

  static GlobalAccessory? getAccessoryById(String id) {
    try {
      return globalAccessories.firstWhere((accessory) => accessory.id == id);
    } catch (e) {
      return null;
    }
  }

  static List<GlobalAccessory> getOwnedAccessories(List<String> ownedAccessoryIds) {
    return globalAccessories.where((accessory) => ownedAccessoryIds.contains(accessory.id)).toList();
  }

  static List<GlobalAccessory> getAvailableForPurchase(List<String> ownedAccessoryIds) {
    return globalAccessories.where((accessory) => !ownedAccessoryIds.contains(accessory.id)).toList();
  }

  static List<GlobalAccessory> getAccessoriesByShopCategory(String category) {
    return globalAccessories.where((accessory) => accessory.shopCategory == category).toList();
  }

  static List<GlobalAccessory> searchAccessories(String query) {
    final lowercaseQuery = query.toLowerCase();
    return globalAccessories.where((accessory) {
      return accessory.name.toLowerCase().contains(lowercaseQuery) ||
             accessory.description.toLowerCase().contains(lowercaseQuery) ||
             accessory.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }

  static List<GlobalAccessory> getAccessoriesUnderPrice(double maxPrice) {
    return globalAccessories.where((accessory) => accessory.shopPrice <= maxPrice).toList();
  }

  static List<GlobalAccessory> getAnimatedAccessories() {
    return globalAccessories.where((accessory) => accessory.isAnimated).toList();
  }

  static Color getRarityColor(AccessoryRarity rarity) {
    switch (rarity) {
      case AccessoryRarity.common:
        return Colors.grey;
      case AccessoryRarity.rare:
        return Colors.blue;
      case AccessoryRarity.epic:
        return Colors.purple;
      case AccessoryRarity.legendary:
        return Colors.orange;
      case AccessoryRarity.mythical:
        return Colors.pink;
    }
  }

  // Get all accessories that should appear in shop
  static List<GlobalAccessory> getShopAccessories() {
    return globalAccessories.toList()..sort((a, b) => a.shopPrice.compareTo(b.shopPrice));
  }

  // Get free starter accessories
  static List<GlobalAccessory> getStarterAccessories() {
    return globalAccessories.where((accessory) => accessory.shopPrice == 0).toList();
  }
}
