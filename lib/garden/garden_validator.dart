// File: garden_validator.dart
// Production readiness validation for the crystal garden system

import 'package:flutter/services.dart';
import 'garden_production_config.dart';

/// Production readiness validator for garden system
class GardenValidator {
  static bool _hasRunValidation = false;
  static bool _lastValidationResult = false;
  
  /// Comprehensive validation of garden system for production readiness
  static Future<bool> validateProductionReadiness() async {
    if (_hasRunValidation && _lastValidationResult) {
      GardenDebugUtils.log('Validator', 'Using cached validation result: PASSED');
      return true;
    }
    
    GardenDebugUtils.log('Validator', 'Starting garden production readiness validation...');
    
    bool allValid = true;
    
    // 1. Configuration validation
    if (!_validateConfiguration()) {
      allValid = false;
    }
    
    // 2. Asset validation
    if (!await _validateAssets()) {
      allValid = false;
    }
    
    // 3. Audio system validation
    if (!await _validateAudioSystem()) {
      allValid = false;
    }
    
    // 4. Performance validation
    if (!_validatePerformanceSettings()) {
      allValid = false;
    }
    
    // 5. Security validation
    if (!_validateSecurity()) {
      allValid = false;
    }
    
    // 6. Data integrity validation
    if (!_validateDataIntegrity()) {
      allValid = false;
    }
    
    _hasRunValidation = true;
    _lastValidationResult = allValid;
    
    if (allValid) {
      GardenDebugUtils.logSuccess('Validator', 'All garden validation checks PASSED');
    } else {
      GardenDebugUtils.logError('Validator', 'Some garden validation checks FAILED');
    }
    
    return allValid;
  }
  
  /// Validate production configuration
  static bool _validateConfiguration() {
    GardenDebugUtils.log('Validator', 'Validating configuration...');
    
    try {
      // Validate flower rarity rates
      final totalRarityRate = GardenProductionConfig.flowerRarityRates.values
          .fold(0.0, (sum, rate) => sum + rate);
      
      if ((totalRarityRate - 1.0).abs() > 0.01) {
        GardenDebugUtils.logError('Validator', 
            'Flower rarity rates sum to $totalRarityRate, expected ~1.0');
        return false;
      }
      
      // Validate reasonable limits
      final checks = {
        'maxGardensPerUser': GardenProductionConfig.maxGardensPerUser > 0,
        'maxFlowersPerGarden': GardenProductionConfig.maxFlowersPerGarden > 0,
        'maxInventorySize': GardenProductionConfig.maxInventorySize > 0,
        'maxVisitorsPerGarden': GardenProductionConfig.maxVisitorsPerGarden > 0,
        'maxGardenLevel': GardenProductionConfig.maxGardenLevel > 0,
      };
      
      for (final entry in checks.entries) {
        if (!entry.value) {
          GardenDebugUtils.logError('Validator', 
              'Invalid configuration: ${entry.key} must be > 0');
          return false;
        }
      }
      
      // Validate rewards configuration
      if (GardenProductionConfig.flowerRewards.isEmpty) {
        GardenDebugUtils.logError('Validator', 'Flower rewards configuration is empty');
        return false;
      }
      
      if (GardenProductionConfig.flowerExperienceRewards.isEmpty) {
        GardenDebugUtils.logError('Validator', 'Flower experience rewards configuration is empty');
        return false;
      }
      
      // Validate shop configuration
      if (GardenProductionConfig.shopItems.isEmpty) {
        GardenDebugUtils.logError('Validator', 'Shop items configuration is empty');
        return false;
      }
      
      // Validate weather effects
      if (GardenProductionConfig.weatherEffects.isEmpty) {
        GardenDebugUtils.logError('Validator', 'Weather effects configuration is empty');
        return false;
      }
      
      // Validate visitor rewards
      if (GardenProductionConfig.visitorRewards.isEmpty) {
        GardenDebugUtils.logError('Validator', 'Visitor rewards configuration is empty');
        return false;
      }
      
      GardenDebugUtils.logSuccess('Validator', 'Configuration validation passed');
      return true;
    } catch (e) {
      GardenDebugUtils.logError('Validator', 'Configuration validation failed: $e');
      return false;
    }
  }
  
  /// Validate required assets exist
  static Future<bool> _validateAssets() async {
    GardenDebugUtils.log('Validator', 'Validating assets...');
    
    try {
      final requiredAssets = [
        'assets/garden/flowers/',
        'assets/garden/backgrounds/',
        'assets/garden/weather/',
        'assets/garden/visitors/',
        'assets/garden/ui/',
        'assets/audio/garden/',
      ];
      
      for (final assetPath in requiredAssets) {
        try {
          // Check if asset directory exists by trying to load a common file
          await rootBundle.load('$assetPath.gitkeep');
        } catch (e) {
          // Try alternative check - this is expected for most assets
          GardenDebugUtils.logWarning('Validator', 
              'Asset directory $assetPath may not exist or be empty');
        }
      }
      
      // Validate specific critical assets
      final criticalAssets = [
        'assets/garden/flowers/common_flower.png',
        'assets/garden/backgrounds/default_garden.png',
        'assets/audio/garden/background_music.mp3',
      ];
      
      int foundCriticalAssets = 0;
      for (final asset in criticalAssets) {
        try {
          await rootBundle.load(asset);
          foundCriticalAssets++;
          GardenDebugUtils.logSuccess('Validator', 'Found critical asset: $asset');
        } catch (e) {
          GardenDebugUtils.logWarning('Validator', 'Critical asset not found: $asset');
        }
      }
      
      if (foundCriticalAssets == 0) {
        GardenDebugUtils.logWarning('Validator', 
            'No critical assets found - may affect garden functionality');
      }
      
      GardenDebugUtils.logSuccess('Validator', 'Asset validation completed');
      return true;
    } catch (e) {
      GardenDebugUtils.logError('Validator', 'Asset validation failed: $e');
      return false;
    }
  }
  
  /// Validate audio system compatibility
  static Future<bool> _validateAudioSystem() async {
    GardenDebugUtils.log('Validator', 'Validating audio system...');
    
    try {
      // Check audio configuration
      if (GardenProductionConfig.maxSongVariants <= 0) {
        GardenDebugUtils.logError('Validator', 'Invalid maxSongVariants configuration');
        return false;
      }
      
      if (GardenProductionConfig.defaultVolume < 0.0 || 
          GardenProductionConfig.defaultVolume > 1.0) {
        GardenDebugUtils.logError('Validator', 'Invalid defaultVolume configuration');
        return false;
      }
      
      // Test audio file loading (basic check)
      final testAudioFiles = [
        'assets/audio/garden/background_music.mp3',
        'assets/audio/garden/flower_bloom.mp3',
        'assets/audio/garden/water_sound.mp3',
      ];
      
      int foundAudioFiles = 0;
      for (final audioFile in testAudioFiles) {
        try {
          await rootBundle.load(audioFile);
          foundAudioFiles++;
          GardenDebugUtils.logSuccess('Validator', 'Audio file found: $audioFile');
        } catch (e) {
          GardenDebugUtils.logWarning('Validator', 'Audio file not found: $audioFile');
        }
      }
      
      if (foundAudioFiles == 0) {
        GardenDebugUtils.logWarning('Validator', 
            'No audio files found - audio features may not work');
      }
      
      GardenDebugUtils.logSuccess('Validator', 'Audio system validation completed');
      return true;
    } catch (e) {
      GardenDebugUtils.logError('Validator', 'Audio system validation failed: $e');
      return false;
    }
  }
  
  /// Validate performance settings
  static bool _validatePerformanceSettings() {
    GardenDebugUtils.log('Validator', 'Validating performance settings...');
    
    try {
      // Validate animation durations are reasonable
      final durations = [
        GardenProductionConfig.animationDuration.inMilliseconds,
        GardenProductionConfig.weatherAnimationDuration.inMilliseconds,
        GardenProductionConfig.confettiDuration.inMilliseconds,
        GardenProductionConfig.effectSoundDuration.inMilliseconds,
      ];
      
      for (final duration in durations) {
        if (duration <= 0 || duration > 30000) { // Max 30 seconds
          GardenDebugUtils.logError('Validator', 
              'Invalid animation duration: ${duration}ms');
          return false;
        }
      }
      
      // Validate timing intervals are reasonable
      final intervals = [
        GardenProductionConfig.flowerGrowthInterval.inMinutes,
        GardenProductionConfig.wateringCooldown.inMinutes,
        GardenProductionConfig.fertilizingCooldown.inMinutes,
        GardenProductionConfig.pestCheckInterval.inMinutes,
        GardenProductionConfig.visitorInterval.inMinutes,
        GardenProductionConfig.weatherChangeInterval.inMinutes,
      ];
      
      for (final interval in intervals) {
        if (interval <= 0 || interval > 1440) { // Max 24 hours
          GardenDebugUtils.logError('Validator', 
              'Invalid timing interval: ${interval} minutes');
          return false;
        }
      }
      
      // Validate cooldown duration is reasonable
      final cooldownMs = GardenProductionConfig.actionCooldown.inMilliseconds;
      if (cooldownMs < 100 || cooldownMs > 10000) { // 100ms to 10s
        GardenDebugUtils.logError('Validator', 
            'Invalid action cooldown: ${cooldownMs}ms');
        return false;
      }
      
      GardenDebugUtils.logSuccess('Validator', 'Performance settings validation passed');
      return true;
    } catch (e) {
      GardenDebugUtils.logError('Validator', 'Performance settings validation failed: $e');
      return false;
    }
  }
  
  /// Validate security settings
  static bool _validateSecurity() {
    GardenDebugUtils.log('Validator', 'Validating security settings...');
    
    try {
      // Validate security features are enabled
      if (!GardenProductionConfig.enableActionValidation) {
        GardenDebugUtils.logWarning('Validator', 
            'Action validation is disabled - security risk');
      }
      
      if (!GardenProductionConfig.enableTimeValidation) {
        GardenDebugUtils.logWarning('Validator', 
            'Time validation is disabled - security risk');
      }
      
      if (!GardenProductionConfig.enableInventoryLimits) {
        GardenDebugUtils.logWarning('Validator', 
            'Inventory limits are disabled - potential exploit');
      }
      
      // Validate limits are reasonable (prevent exploits)
      if (GardenProductionConfig.maxGardensPerUser > 1000) {
        GardenDebugUtils.logError('Validator', 
            'maxGardensPerUser too high - potential resource abuse');
        return false;
      }
      
      if (GardenProductionConfig.maxFlowersPerGarden > 100) {
        GardenDebugUtils.logError('Validator', 
            'maxFlowersPerGarden too high - potential performance issue');
        return false;
      }
      
      if (GardenProductionConfig.maxInventorySize > 10000) {
        GardenDebugUtils.logError('Validator', 
            'maxInventorySize too high - potential memory issue');
        return false;
      }
      
      GardenDebugUtils.logSuccess('Validator', 'Security validation passed');
      return true;
    } catch (e) {
      GardenDebugUtils.logError('Validator', 'Security validation failed: $e');
      return false;
    }
  }
  
  /// Validate data integrity
  static bool _validateDataIntegrity() {
    GardenDebugUtils.log('Validator', 'Validating data integrity...');
    
    try {
      // Validate flower rarity consistency
      final rarityKeys = GardenProductionConfig.flowerRarityRates.keys.toSet();
      final rewardKeys = GardenProductionConfig.flowerRewards.keys.toSet();
      final experienceKeys = GardenProductionConfig.flowerExperienceRewards.keys.toSet();
      final growthKeys = GardenProductionConfig.flowerGrowthRates.keys.toSet();
      
      if (!rarityKeys.containsAll(rewardKeys) || 
          !rarityKeys.containsAll(experienceKeys) ||
          !rarityKeys.containsAll(growthKeys)) {
        GardenDebugUtils.logError('Validator', 
            'Inconsistent flower rarity keys across configurations');
        return false;
      }
      
      // Validate reward values are positive
      for (final reward in GardenProductionConfig.flowerRewards.values) {
        if (reward <= 0) {
          GardenDebugUtils.logError('Validator', 'Invalid flower reward value: $reward');
          return false;
        }
      }
      
      for (final experience in GardenProductionConfig.flowerExperienceRewards.values) {
        if (experience <= 0) {
          GardenDebugUtils.logError('Validator', 'Invalid experience reward value: $experience');
          return false;
        }
      }
      
      // Validate growth rates are between 0 and 1
      for (final rate in GardenProductionConfig.flowerGrowthRates.values) {
        if (rate <= 0.0 || rate > 1.0) {
          GardenDebugUtils.logError('Validator', 'Invalid growth rate: $rate');
          return false;
        }
      }
      
      // Validate shop item prices are positive
      for (final item in GardenProductionConfig.shopItems.values) {
        final price = item['price'] as int?;
        final quantity = item['quantity'] as int?;
        
        if (price == null || price <= 0) {
          GardenDebugUtils.logError('Validator', 'Invalid shop item price: $price');
          return false;
        }
        
        if (quantity == null || quantity <= 0) {
          GardenDebugUtils.logError('Validator', 'Invalid shop item quantity: $quantity');
          return false;
        }
      }
      
      // Validate weather effects have required keys
      for (final entry in GardenProductionConfig.weatherEffects.entries) {
        final effects = entry.value;
        if (!effects.containsKey('growthBonus')) {
          GardenDebugUtils.logError('Validator', 
              'Weather effect ${entry.key} missing growthBonus');
          return false;
        }
      }
      
      // Validate visitor rewards
      for (final entry in GardenProductionConfig.visitorRewards.entries) {
        final reward = entry.value;
        if (!reward.containsKey('message')) {
          GardenDebugUtils.logError('Validator', 
              'Visitor reward ${entry.key} missing message');
          return false;
        }
      }
      
      GardenDebugUtils.logSuccess('Validator', 'Data integrity validation passed');
      return true;
    } catch (e) {
      GardenDebugUtils.logError('Validator', 'Data integrity validation failed: $e');
      return false;
    }
  }
  
  /// Get validation summary
  static Map<String, dynamic> getValidationSummary() {
    return {
      'has_run_validation': _hasRunValidation,
      'last_validation_result': _lastValidationResult,
      'configuration_valid': GardenConfigValidator.validateConfiguration(),
      'production_mode': GardenProductionConfig.isProduction,
      'debug_logging_enabled': GardenProductionConfig.enableDebugLogging,
      'performance_monitoring_enabled': GardenProductionConfig.enablePerformanceMonitoring,
      'validation_timestamp': DateTime.now().toIso8601String(),
    };
  }
  
  /// Reset validation state (for testing)
  static void resetValidationState() {
    _hasRunValidation = false;
    _lastValidationResult = false;
    GardenDebugUtils.log('Validator', 'Validation state reset');
  }
}

/// Specific garden feature validators
class GardenFeatureValidator {
  /// Validate weather system configuration
  static bool validateWeatherSystem() {
    if (!GardenProductionConfig.enableWeatherSystem) {
      GardenDebugUtils.logWarning('FeatureValidator', 'Weather system is disabled');
      return false;
    }
    
    final requiredWeatherTypes = ['sunny', 'rainy', 'snowy', 'windy', 'misty'];
    final configuredWeatherTypes = GardenProductionConfig.weatherEffects.keys.toSet();
    
    for (final weatherType in requiredWeatherTypes) {
      if (!configuredWeatherTypes.contains(weatherType)) {
        GardenDebugUtils.logError('FeatureValidator', 
            'Missing weather configuration: $weatherType');
        return false;
      }
    }
    
    GardenDebugUtils.logSuccess('FeatureValidator', 'Weather system validation passed');
    return true;
  }
  
  /// Validate visitor system configuration
  static bool validateVisitorSystem() {
    if (!GardenProductionConfig.enableGardenVisitors) {
      GardenDebugUtils.logWarning('FeatureValidator', 'Visitor system is disabled');
      return false;
    }
    
    if (GardenProductionConfig.visitorRewards.isEmpty) {
      GardenDebugUtils.logError('FeatureValidator', 'No visitor rewards configured');
      return false;
    }
    
    final requiredVisitors = ['fairy', 'unicorn', 'gnome', 'rain_cloud', 'bee', 'snail'];
    final configuredVisitors = GardenProductionConfig.visitorRewards.keys.toSet();
    
    for (final visitor in requiredVisitors) {
      if (!configuredVisitors.contains(visitor)) {
        GardenDebugUtils.logWarning('FeatureValidator', 
            'Missing visitor configuration: $visitor');
      }
    }
    
    GardenDebugUtils.logSuccess('FeatureValidator', 'Visitor system validation passed');
    return true;
  }
  
  /// Validate seasonal system configuration
  static bool validateSeasonalSystem() {
    if (!GardenProductionConfig.enableSeasonalChanges) {
      GardenDebugUtils.logWarning('FeatureValidator', 'Seasonal system is disabled');
      return false;
    }
    
    final requiredSeasons = ['spring', 'summer', 'autumn', 'winter'];
    final configuredSeasons = GardenProductionConfig.availableSeasons;
    
    for (final season in requiredSeasons) {
      if (!configuredSeasons.contains(season)) {
        GardenDebugUtils.logError('FeatureValidator', 
            'Missing season configuration: $season');
        return false;
      }
    }
    
    GardenDebugUtils.logSuccess('FeatureValidator', 'Seasonal system validation passed');
    return true;
  }
}
