import 'package:flutter/material.dart';
import 'shiny_gem_animation.dart';
import 'gem_unlock.dart';

class Gemstone {
  final String id;
  final String name;
  final String description;
  final String imagePath;
  final String rarity;
  final String element;
  final int power;
  final int value;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final String source;
  final String category;
  final List<String> tags;
  final bool isFavorite;
  final int timesViewed;
  final double sparkleIntensity;

  const Gemstone({
    required this.id,
    required this.name,
    required this.description,
    required this.imagePath,
    this.rarity = 'common',
    this.element = 'neutral',
    this.power = 0,
    this.value = 0,
    this.isUnlocked = false,
    this.unlockedAt,
    this.source = 'unknown',
    this.category = 'standard',
    this.tags = const [],
    this.isFavorite = false,
    this.timesViewed = 0,
    this.sparkleIntensity = 1.0,
  });

  // Factory constructor to create Gemstone from Map (database response)
  factory Gemstone.fromMap(Map<String, dynamic> map) {
    return Gemstone(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      imagePath: map['image_path']?.toString() ?? '',
      rarity: map['rarity']?.toString() ?? 'common',
      element: map['element']?.toString() ?? 'neutral',
      power: map['power'] as int? ?? 0,
      value: map['value'] as int? ?? 0,
      isUnlocked: map['is_unlocked'] as bool? ?? false,
      unlockedAt: map['unlocked_at'] != null ? DateTime.parse(map['unlocked_at']) : null,
      source: map['source']?.toString() ?? 'unknown',
      category: map['category']?.toString() ?? 'standard',
      tags: map['tags'] != null ? List<String>.from(map['tags']) : const [],
      isFavorite: map['is_favorite'] as bool? ?? false,
      timesViewed: map['times_viewed'] as int? ?? 0,
      sparkleIntensity: map['sparkle_intensity'] as double? ?? 1.0,
    );
  }

  // Convert string rarity to enum
  GemRarity get rarityEnum {
    switch (rarity.toLowerCase()) {
      case 'legendary':
      case 'mythic':
        return GemRarity.legendary;
      case 'epic':
        return GemRarity.epic;
      case 'rare':
        return GemRarity.rare;
      case 'uncommon':
        return GemRarity.uncommon;
      case 'common':
      default:
        return GemRarity.common;
    }
  }

  // Get rarity color
  Color get rarityColor {
    switch (rarityEnum) {
      case GemRarity.legendary:
        return const Color(0xFFFF6B35);
      case GemRarity.epic:
        return const Color(0xFF8E44AD);
      case GemRarity.rare:
        return const Color(0xFF3498DB);
      case GemRarity.uncommon:
        return const Color(0xFF27AE60);
      case GemRarity.common:
        return const Color(0xFF7F8C8D);
    }
  }

  // Get best animation type for this gem
  GemAnimationType get preferredAnimation {
    switch (rarityEnum) {
      case GemRarity.legendary:
        return GemAnimationType.rainbow;
      case GemRarity.epic:
        return GemAnimationType.sparkle;
      case GemRarity.rare:
        return GemAnimationType.shimmer;
      case GemRarity.uncommon:
        return GemAnimationType.glow;
      case GemRarity.common:
        return GemAnimationType.pulse;
    }
  }

  // Get element-based animation
  GemAnimationType get elementAnimation {
    switch (element.toLowerCase()) {
      case 'fire':
        return GemAnimationType.glow;
      case 'water':
        return GemAnimationType.float;
      case 'earth':
        return GemAnimationType.bounce;
      case 'air':
        return GemAnimationType.shimmer;
      case 'light':
        return GemAnimationType.sparkle;
      case 'dark':
        return GemAnimationType.pulse;
      case 'cosmic':
        return GemAnimationType.rainbow;
      default:
        return preferredAnimation;
    }
  }

  // Check if this is a rare unlock
  bool get isRareUnlock {
    return rarityEnum == GemRarity.epic || rarityEnum == GemRarity.legendary;
  }

  // Get unlock message based on rarity
  String get unlockMessage {
    switch (rarityEnum) {
      case GemRarity.legendary:
        return 'LEGENDARY GEM DISCOVERED';
      case GemRarity.epic:
        return 'EPIC GEM UNLOCKED';
      case GemRarity.rare:
        return 'RARE GEM FOUND';
      case GemRarity.uncommon:
        return 'You found a';
      case GemRarity.common:
        return 'You earned the';
    }
  }

  // Get rarity multiplier for effects
  double get rarityMultiplier {
    switch (rarityEnum) {
      case GemRarity.legendary:
        return 2.0;
      case GemRarity.epic:
        return 1.6;
      case GemRarity.rare:
        return 1.3;
      case GemRarity.uncommon:
        return 1.1;
      case GemRarity.common:
        return 1.0;
    }
  }

  Gemstone copyWith({
    String? id,
    String? name,
    String? description,
    String? imagePath,
    String? rarity,
    String? element,
    int? power,
    int? value,
    bool? isUnlocked,
    DateTime? unlockedAt,
    String? source,
    String? category,
    List<String>? tags,
    bool? isFavorite,
    int? timesViewed,
    double? sparkleIntensity,
  }) {
    return Gemstone(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      rarity: rarity ?? this.rarity,
      element: element ?? this.element,
      power: power ?? this.power,
      value: value ?? this.value,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      source: source ?? this.source,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
      timesViewed: timesViewed ?? this.timesViewed,
      sparkleIntensity: sparkleIntensity ?? this.sparkleIntensity,
    );
  }

  // Create an enhanced gem animation widget
  Widget createAnimation({
    double size = 100,
    GemAnimationType? animationType,
    bool? showParticles,
    bool? showGlow,
    Duration? duration,
  }) {
    return EnhancedShinyGemAnimation(
      imagePath: imagePath,
      size: size,
      animationType: animationType ?? preferredAnimation,
      rarity: rarityEnum,
      showParticles: showParticles ?? isRareUnlock,
      showGlow: showGlow ?? true,
      animationDuration: duration ?? Duration(milliseconds: (2000 / rarityMultiplier).round()),
      customColor: null,
    );
  }

  // Create unlock popup
  Widget createUnlockPopup({
    VoidCallback? onClose,
    bool? showStats,
    bool? playSound,
  }) {
    return EnhancedGemUnlockPopup(
      gem: this,
      customUnlockMessage: unlockMessage,
      customIsRareUnlock: isRareUnlock,
      onClose: onClose,
      showStats: showStats ?? true,
      playSound: playSound ?? true,
    );
  }

  // Get element icon
  IconData get elementIcon {
    switch (element.toLowerCase()) {
      case 'fire':
        return Icons.local_fire_department;
      case 'water':
        return Icons.water_drop;
      case 'earth':
        return Icons.terrain;
      case 'air':
        return Icons.air;
      case 'light':
        return Icons.wb_sunny;
      case 'dark':
        return Icons.nightlight;
      case 'cosmic':
        return Icons.stars;
      case 'ice':
        return Icons.ac_unit;
      case 'lightning':
        return Icons.flash_on;
      default:
        return Icons.diamond;
    }
  }

  // Get element color
  Color get elementColor {
    switch (element.toLowerCase()) {
      case 'fire':
        return Colors.red;
      case 'water':
        return Colors.blue;
      case 'earth':
        return Colors.brown;
      case 'air':
        return Colors.cyan;
      case 'light':
        return Colors.yellow;
      case 'dark':
        return Colors.deepPurple;
      case 'cosmic':
        return Colors.purple;
      case 'ice':
        return Colors.lightBlue;
      case 'lightning':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  @override
  String toString() {
    return 'Gemstone(id: $id, name: $name, rarity: $rarity, element: $element)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Gemstone && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Utility class for gem management
class GemManager {
  static List<Gemstone> filterByRarity(List<Gemstone> gems, GemRarity rarity) {
    return gems.where((gem) => gem.rarityEnum == rarity).toList();
  }

  static List<Gemstone> filterByElement(List<Gemstone> gems, String element) {
    return gems.where((gem) => gem.element.toLowerCase() == element.toLowerCase()).toList();
  }

  static List<Gemstone> getFavorites(List<Gemstone> gems) {
    return gems.where((gem) => gem.isFavorite).toList();
  }

  static List<Gemstone> getUnlocked(List<Gemstone> gems) {
    return gems.where((gem) => gem.isUnlocked).toList();
  }

  static List<Gemstone> sortByRarity(List<Gemstone> gems, {bool ascending = false}) {
    final rarityOrder = {
      GemRarity.legendary: 5,
      GemRarity.epic: 4,
      GemRarity.rare: 3,
      GemRarity.uncommon: 2,
      GemRarity.common: 1,
    };

    gems.sort((a, b) {
      final aValue = rarityOrder[a.rarityEnum] ?? 0;
      final bValue = rarityOrder[b.rarityEnum] ?? 0;
      return ascending ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
    });

    return gems;
  }

  static Map<GemRarity, int> getRarityStats(List<Gemstone> gems) {
    final stats = <GemRarity, int>{};
    for (final rarity in GemRarity.values) {
      stats[rarity] = gems.where((gem) => gem.rarityEnum == rarity).length;
    }
    return stats;
  }

  static double getCollectionValue(List<Gemstone> gems) {
    return gems.fold(0.0, (sum, gem) => sum + (gem.isUnlocked ? gem.value : 0));
  }

  static int getTotalPower(List<Gemstone> gems) {
    return gems.fold(0, (sum, gem) => sum + (gem.isUnlocked ? gem.power : 0));
  }
}
