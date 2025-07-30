// File: garden_production_config.dart
// Production configuration and constants for the crystal garden system

import 'package:flutter/foundation.dart';

/// Production configuration for crystal garden system
class GardenProductionConfig {
  // Environment settings
  static const bool isProduction = kReleaseMode;
  static const bool enableDebugLogging = !kReleaseMode;
  static const bool enablePerformanceMonitoring = true;
  
  // Garden limits and constraints
  static const int maxGardensPerUser = 50;
  static const int maxFlowersPerGarden = 9;
  static const int maxInventorySize = 100;
  static const int maxVisitorsPerGarden = 5;
  static const int maxGardenLevel = 100;
  
  // Growth and timing configuration
  static const Duration flowerGrowthInterval = Duration(hours: 1);
  static const Duration wateringCooldown = Duration(minutes: 30);
  static const Duration fertilizingCooldown = Duration(hours: 1);
  static const Duration pestCheckInterval = Duration(minutes: 10);
  static const Duration visitorInterval = Duration(minutes: 3);
  static const Duration weatherChangeInterval = Duration(minutes: 5);
  
  // Garden features settings
  static const bool enableWeatherSystem = true;
  static const bool enableSeasonalChanges = true;
  static const bool enableGardenVisitors = true;
  static const bool enableFlowerSongs = true;
  static const bool enablePestSystem = true;
  static const bool enableGardenThemes = true;
  static const bool enableSpecialEffects = true;
  static const bool enableSoundEffects = true;
  
  // Economic settings
  static const Map<String, int> flowerRewards = {
    'common': 15,
    'rare': 50,
    'epic': 100,
  };
  
  static const Map<String, int> flowerGemRewards = {
    'common': 0,
    'rare': 1,
    'epic': 2,
  };
  
  static const Map<String, int> flowerExperienceRewards = {
    'common': 10,
    'rare': 40,
    'epic': 80,
  };
  
  // Shop prices
  static const Map<String, Map<String, dynamic>> shopItems = {
    'water_5x': {'price': 25, 'currency': 'coins', 'quantity': 5},
    'fertilizer_3x': {'price': 50, 'currency': 'coins', 'quantity': 3},
    'pesticide_2x': {'price': 75, 'currency': 'coins', 'quantity': 2},
    'rare_seeds_1x': {'price': 2, 'currency': 'gems', 'quantity': 1},
    'epic_seeds_1x': {'price': 5, 'currency': 'gems', 'quantity': 1},
  };
  
  // Rarity drop rates for flowers
  static const Map<String, double> flowerRarityRates = {
    'common': 0.60,    // 60% chance
    'rare': 0.30,      // 30% chance
    'epic': 0.10,      // 10% chance
  };
  
  // Growth rates by rarity
  static const Map<String, double> flowerGrowthRates = {
    'common': 0.8,     // 80% growth chance
    'rare': 0.4,       // 40% growth chance
    'epic': 0.3,       // 30% growth chance
  };
  
  // Weather effects on garden
  static const Map<String, Map<String, dynamic>> weatherEffects = {
    'sunny': {'wateringBonus': 5, 'growthBonus': 1.2},
    'rainy': {'wateringBonus': 0, 'growthBonus': 1.5, 'autoWater': true},
    'snowy': {'wateringBonus': 0, 'growthBonus': 0.5, 'healthPenalty': 5},
    'windy': {'wateringBonus': 0, 'growthBonus': 0.8, 'pestReduction': true},
    'misty': {'wateringBonus': 2, 'growthBonus': 1.1, 'healthBonus': 5},
  };
  
  // Performance optimization
  static const Duration animationDuration = Duration(milliseconds: 800);
  static const Duration weatherAnimationDuration = Duration(seconds: 3);
  static const Duration confettiDuration = Duration(seconds: 1);
  static const Duration effectSoundDuration = Duration(seconds: 2);
  
  // Audio settings
  static const bool enableBackgroundMusic = true;
  static const double defaultVolume = 0.7;
  static const int maxSongVariants = 33;
  
  // Security and validation
  static const bool enableActionValidation = true;
  static const bool enableTimeValidation = true;
  static const bool enableInventoryLimits = true;
  static const Duration actionCooldown = Duration(seconds: 1);
  
  // Garden themes and seasons
  static const List<String> availableThemes = [
    'classic', 'enchanted', 'tropical', 'desert', 'arctic'
  ];
  
  static const List<String> availableSeasons = [
    'spring', 'summer', 'autumn', 'winter'
  ];
  
  // Visitor rewards
  static const Map<String, Map<String, dynamic>> visitorRewards = {
    'fairy': {'coins': 10, 'message': 'A fairy left you 10 coins! ✨'},
    'unicorn': {'gems': 1, 'message': 'A unicorn left you 1 gem! 🦄'},
    'gnome': {'fertilizer': 1, 'message': 'A gnome left you fertilizer! 🧙‍♂️'},
    'rain_cloud': {'water': 2, 'message': 'Rain clouds left you water! ☁️'},
    'bee': {'coins': 5, 'message': 'Bee gave you 5 coins! 🐝'},
    'snail': {'fertilizer': 1, 'message': 'Snail gave you fertilizer! 🐌'},
  };
  
  // Level progression
  static int getRequiredExperience(int level) {
    return level * 100; // Linear progression for simplicity
  }
  
  static Map<String, int> getLevelUpRewards(int level) {
    return {
      'coins': level * 50,
      'gems': level,
    };
  }
}

/// Production-safe debug utilities for garden system
class GardenDebugUtils {
  static void log(String component, String message) {
    if (GardenProductionConfig.enableDebugLogging) {
      debugPrint('🌸 Garden[$component]: $message');
    }
  }
  
  static void logError(String component, String error) {
    if (GardenProductionConfig.enableDebugLogging) {
      debugPrint('🔴 Garden[$component] ERROR: $error');
    }
    // In production, you might want to send to crash reporting service
    // CrashReporting.recordError('Garden[$component]', error);
  }
  
  static void logWarning(String component, String warning) {
    if (GardenProductionConfig.enableDebugLogging) {
      debugPrint('🟡 Garden[$component] WARNING: $warning');
    }
  }
  
  static void logSuccess(String component, String message) {
    if (GardenProductionConfig.enableDebugLogging) {
      debugPrint('🟢 Garden[$component] SUCCESS: $message');
    }
  }
  
  static void logPerformance(String component, String operation, Duration duration) {
    if (GardenProductionConfig.enablePerformanceMonitoring) {
      debugPrint('⚡ Garden[$component] PERF: $operation took ${duration.inMilliseconds}ms');
    }
  }
  
  static void logFlowerAction(String component, String action, String flowerType) {
    if (GardenProductionConfig.enableDebugLogging) {
      debugPrint('🌺 Garden[$component] ACTION: $action on $flowerType');
    }
  }
  
  static void logAudio(String component, String audioType, String status) {
    if (GardenProductionConfig.enableDebugLogging) {
      debugPrint('🎵 Garden[$component] AUDIO: $audioType - $status');
    }
  }
}

/// Error handling utilities for garden system
class GardenErrorHandler {
  static void handleAudioError(String context, dynamic error) {
    GardenDebugUtils.logError(context, 'Audio error: $error');
    
    // Handle different types of audio errors
    if (error.toString().contains('404') || error.toString().contains('not found')) {
      GardenDebugUtils.logWarning(context, 'Audio file not found - using fallback');
    } else if (error.toString().contains('permission')) {
      GardenDebugUtils.logWarning(context, 'Audio permission denied');
    } else {
      GardenDebugUtils.logWarning(context, 'Generic audio error');
    }
  }
  
  static void handleGardenError(String context, dynamic error) {
    GardenDebugUtils.logError(context, error.toString());
    
    // Handle different types of garden errors
    if (error is RangeError) {
      GardenDebugUtils.logWarning(context, 'Index out of range error');
    } else if (error is StateError) {
      GardenDebugUtils.logWarning(context, 'State error - widget disposed?');
    } else {
      GardenDebugUtils.logWarning(context, 'Unexpected garden error');
    }
  }
  
  static void handleFileError(String context, dynamic error) {
    GardenDebugUtils.logError(context, 'File error: $error');
    // Provide fallback asset loading
  }
}

/// Production configuration validator for garden system
class GardenConfigValidator {
  static bool validateConfiguration() {
    try {
      // Validate flower rarity rates sum to approximately 1.0
      final totalRarityRate = GardenProductionConfig.flowerRarityRates.values
          .fold(0.0, (sum, rate) => sum + rate);
      
      if ((totalRarityRate - 1.0).abs() > 0.01) {
        GardenDebugUtils.logWarning('ConfigValidator', 
            'Flower rarity rates sum to $totalRarityRate, expected ~1.0');
        return false;
      }
      
      // Validate reasonable limits
      if (GardenProductionConfig.maxGardensPerUser <= 0 ||
          GardenProductionConfig.maxFlowersPerGarden <= 0) {
        GardenDebugUtils.logWarning('ConfigValidator', 'Invalid garden limits');
        return false;
      }
      
      // Validate reward values
      if (GardenProductionConfig.flowerRewards.isEmpty ||
          GardenProductionConfig.flowerExperienceRewards.isEmpty) {
        GardenDebugUtils.logWarning('ConfigValidator', 'Invalid reward configuration');
        return false;
      }
      
      GardenDebugUtils.logSuccess('ConfigValidator', 'Configuration validation passed');
      return true;
    } catch (e) {
      GardenDebugUtils.logError('ConfigValidator', 'Validation failed: $e');
      return false;
    }
  }
}
