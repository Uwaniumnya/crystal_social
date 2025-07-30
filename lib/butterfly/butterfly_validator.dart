// File: butterfly_validator.dart
// Production readiness validation for the butterfly garden system

import 'package:flutter/services.dart';
import 'butterfly_production_config.dart';

/// Production readiness validator for butterfly system
class ButterflyValidator {
  static bool _hasRunValidation = false;
  static bool _lastValidationResult = false;
  
  /// Comprehensive validation of butterfly system for production readiness
  static Future<bool> validateProductionReadiness() async {
    if (_hasRunValidation && _lastValidationResult) {
      ButterflyDebugUtils.log('Validator', 'Using cached validation result: PASSED');
      return true;
    }
    
    ButterflyDebugUtils.log('Validator', 'Starting butterfly production readiness validation...');
    
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
    
    // 7. Animation system validation
    if (!_validateAnimationSystem()) {
      allValid = false;
    }
    
    _hasRunValidation = true;
    _lastValidationResult = allValid;
    
    if (allValid) {
      ButterflyDebugUtils.logSuccess('Validator', 'All butterfly validation checks PASSED');
    } else {
      ButterflyDebugUtils.logError('Validator', 'Some butterfly validation checks FAILED');
    }
    
    return allValid;
  }
  
  /// Validate production configuration
  static bool _validateConfiguration() {
    ButterflyDebugUtils.log('Validator', 'Validating configuration...');
    
    try {
      // Validate butterfly rarity rates
      final totalRarityRate = ButterflyProductionConfig.butterflyRarityRates.values
          .fold(0.0, (sum, rate) => sum + rate);
      
      if ((totalRarityRate - 1.0).abs() > 0.01) {
        ButterflyDebugUtils.logError('Validator', 
            'Butterfly rarity rates sum to $totalRarityRate, expected ~1.0');
        return false;
      }
      
      // Validate reasonable limits
      final checks = {
        'maxButterflyCollection': ButterflyProductionConfig.maxButterflyCollection > 0,
        'maxFavorites': ButterflyProductionConfig.maxFavorites > 0,
        'maxDailyDiscoveries': ButterflyProductionConfig.maxDailyDiscoveries > 0,
        'maxSearchResults': ButterflyProductionConfig.maxSearchResults > 0,
      };
      
      for (final entry in checks.entries) {
        if (!entry.value) {
          ButterflyDebugUtils.logError('Validator', 
              'Invalid configuration: ${entry.key} must be > 0');
          return false;
        }
      }
      
      // Validate progression rewards configuration
      if (ButterflyProductionConfig.progressionRewards.isEmpty) {
        ButterflyDebugUtils.logError('Validator', 'Progression rewards configuration is empty');
        return false;
      }
      
      // Validate audio files configuration
      if (ButterflyProductionConfig.audioFiles.isEmpty) {
        ButterflyDebugUtils.logError('Validator', 'Audio files configuration is empty');
        return false;
      }
      
      // Validate image cache settings
      final cacheSettings = ButterflyProductionConfig.imageCacheSettings;
      for (final entry in cacheSettings.entries) {
        if (entry.value <= 0) {
          ButterflyDebugUtils.logError('Validator', 
              'Invalid cache setting: ${entry.key} must be > 0');
          return false;
        }
      }
      
      // Validate butterfly categories
      if (ButterflyProductionConfig.butterflyCategories.isEmpty) {
        ButterflyDebugUtils.logError('Validator', 'Butterfly categories configuration is empty');
        return false;
      }
      
      ButterflyDebugUtils.logSuccess('Validator', 'Configuration validation passed');
      return true;
    } catch (e) {
      ButterflyDebugUtils.logError('Validator', 'Configuration validation failed: $e');
      return false;
    }
  }
  
  /// Validate required assets exist
  static Future<bool> _validateAssets() async {
    ButterflyDebugUtils.log('Validator', 'Validating assets...');
    
    try {
      final requiredAssets = [
        'assets/butterfly/',
        'assets/butterfly/jar.png',
      ];
      
      int foundAssets = 0;
      for (final assetPath in requiredAssets) {
        try {
          await rootBundle.load(assetPath);
          foundAssets++;
          ButterflyDebugUtils.logSuccess('Validator', 'Found asset: $assetPath');
        } catch (e) {
          ButterflyDebugUtils.logWarning('Validator', 'Asset not found: $assetPath');
        }
      }
      
      // Validate butterfly images (sample)
      final sampleButterflyImages = [
        'assets/butterfly/butterfly1.webp',
        'assets/butterfly/butterfly2.webp',
        'assets/butterfly/butterfly3.webp',
      ];
      
      int foundButterflyImages = 0;
      for (final imagePath in sampleButterflyImages) {
        try {
          await rootBundle.load(imagePath);
          foundButterflyImages++;
          ButterflyDebugUtils.logSuccess('Validator', 'Found butterfly image: $imagePath');
        } catch (e) {
          ButterflyDebugUtils.logWarning('Validator', 'Butterfly image not found: $imagePath');
        }
      }
      
      if (foundButterflyImages == 0) {
        ButterflyDebugUtils.logWarning('Validator', 
            'No butterfly images found - collection will be empty');
      }
      
      ButterflyDebugUtils.logSuccess('Validator', 'Asset validation completed');
      return true;
    } catch (e) {
      ButterflyDebugUtils.logError('Validator', 'Asset validation failed: $e');
      return false;
    }
  }
  
  /// Validate audio system compatibility
  static Future<bool> _validateAudioSystem() async {
    ButterflyDebugUtils.log('Validator', 'Validating audio system...');
    
    try {
      // Check audio configuration
      if (ButterflyProductionConfig.defaultVolume < 0.0 || 
          ButterflyProductionConfig.defaultVolume > 1.0) {
        ButterflyDebugUtils.logError('Validator', 'Invalid defaultVolume configuration');
        return false;
      }
      
      if (ButterflyProductionConfig.maxAudioRetries <= 0) {
        ButterflyDebugUtils.logError('Validator', 'Invalid maxAudioRetries configuration');
        return false;
      }
      
      // Test audio file loading (basic check)
      final audioFiles = ButterflyProductionConfig.audioFiles.values.toList();
      int foundAudioFiles = 0;
      
      for (final audioFile in audioFiles) {
        try {
          await rootBundle.load(audioFile);
          foundAudioFiles++;
          ButterflyDebugUtils.logSuccess('Validator', 'Audio file found: $audioFile');
        } catch (e) {
          ButterflyDebugUtils.logWarning('Validator', 'Audio file not found: $audioFile');
        }
      }
      
      if (foundAudioFiles == 0) {
        ButterflyDebugUtils.logWarning('Validator', 
            'No audio files found - audio features may not work');
      }
      
      ButterflyDebugUtils.logSuccess('Validator', 'Audio system validation completed');
      return true;
    } catch (e) {
      ButterflyDebugUtils.logError('Validator', 'Audio system validation failed: $e');
      return false;
    }
  }
  
  /// Validate performance settings
  static bool _validatePerformanceSettings() {
    ButterflyDebugUtils.log('Validator', 'Validating performance settings...');
    
    try {
      // Validate animation durations are reasonable
      final durations = [
        ButterflyProductionConfig.discoveryAnimation.inMilliseconds,
        ButterflyProductionConfig.shakeAnimationDuration.inMilliseconds,
        ButterflyProductionConfig.sparkleAnimationDuration.inMilliseconds,
      ];
      
      for (final duration in durations) {
        if (duration <= 0 || duration > 10000) { // Max 10 seconds
          ButterflyDebugUtils.logError('Validator', 
              'Invalid animation duration: ${duration}ms');
          return false;
        }
      }
      
      // Validate timing intervals are reasonable
      final intervals = [
        ButterflyProductionConfig.interactionCooldown.inMilliseconds,
        ButterflyProductionConfig.searchDebounceDelay.inMilliseconds,
      ];
      
      for (final interval in intervals) {
        if (interval <= 0 || interval > 5000) { // Max 5 seconds
          ButterflyDebugUtils.logError('Validator', 
              'Invalid timing interval: ${interval}ms');
          return false;
        }
      }
      
      // Validate cache settings
      final cacheExpiration = ButterflyProductionConfig.cacheExpiration.inMinutes;
      if (cacheExpiration <= 0 || cacheExpiration > 1440) { // Max 24 hours
        ButterflyDebugUtils.logError('Validator', 
            'Invalid cache expiration: ${cacheExpiration} minutes');
        return false;
      }
      
      // Validate cache sizes
      if (ButterflyProductionConfig.imageCacheSize <= 0) {
        ButterflyDebugUtils.logError('Validator', 'Invalid image cache size');
        return false;
      }
      
      ButterflyDebugUtils.logSuccess('Validator', 'Performance settings validation passed');
      return true;
    } catch (e) {
      ButterflyDebugUtils.logError('Validator', 'Performance settings validation failed: $e');
      return false;
    }
  }
  
  /// Validate security settings
  static bool _validateSecurity() {
    ButterflyDebugUtils.log('Validator', 'Validating security settings...');
    
    try {
      // Validate security features are enabled
      if (!ButterflyProductionConfig.enableInputValidation) {
        ButterflyDebugUtils.logWarning('Validator', 
            'Input validation is disabled - security risk');
      }
      
      if (!ButterflyProductionConfig.enableRateLimiting) {
        ButterflyDebugUtils.logWarning('Validator', 
            'Rate limiting is disabled - security risk');
      }
      
      if (!ButterflyProductionConfig.enableDataIntegrityChecks) {
        ButterflyDebugUtils.logWarning('Validator', 
            'Data integrity checks are disabled - security risk');
      }
      
      // Validate limits are reasonable (prevent exploits)
      if (ButterflyProductionConfig.maxButterflyCollection > 1000) {
        ButterflyDebugUtils.logError('Validator', 
            'maxButterflyCollection too high - potential resource abuse');
        return false;
      }
      
      if (ButterflyProductionConfig.maxFavorites > 100) {
        ButterflyDebugUtils.logError('Validator', 
            'maxFavorites too high - potential performance issue');
        return false;
      }
      
      if (ButterflyProductionConfig.maxDailyDiscoveries > 50) {
        ButterflyDebugUtils.logError('Validator', 
            'maxDailyDiscoveries too high - potential exploitation');
        return false;
      }
      
      // Validate search query length limit
      if (ButterflyProductionConfig.maxSearchQueryLength <= 0 || 
          ButterflyProductionConfig.maxSearchQueryLength > 100) {
        ButterflyDebugUtils.logError('Validator', 
            'Invalid search query length limit');
        return false;
      }
      
      ButterflyDebugUtils.logSuccess('Validator', 'Security validation passed');
      return true;
    } catch (e) {
      ButterflyDebugUtils.logError('Validator', 'Security validation failed: $e');
      return false;
    }
  }
  
  /// Validate data integrity
  static bool _validateDataIntegrity() {
    ButterflyDebugUtils.log('Validator', 'Validating data integrity...');
    
    try {
      // Validate progression rewards structure
      final progressionRewards = ButterflyProductionConfig.progressionRewards;
      for (final entry in progressionRewards.entries) {
        final milestone = entry.key;
        final reward = entry.value;
        
        if (milestone <= 0 || milestone > ButterflyProductionConfig.maxButterflyCollection) {
          ButterflyDebugUtils.logError('Validator', 
              'Invalid progression milestone: $milestone');
          return false;
        }
        
        if (!reward.containsKey('type') || !reward.containsKey('amount') || !reward.containsKey('message')) {
          ButterflyDebugUtils.logError('Validator', 
              'Incomplete progression reward data for milestone: $milestone');
          return false;
        }
        
        final amount = reward['amount'] as int?;
        if (amount == null || amount <= 0) {
          ButterflyDebugUtils.logError('Validator', 
              'Invalid reward amount for milestone: $milestone');
          return false;
        }
      }
      
      // Validate audio files paths
      final audioFiles = ButterflyProductionConfig.audioFiles;
      for (final entry in audioFiles.entries) {
        final key = entry.key;
        final path = entry.value;
        
        if (path.isEmpty || !path.startsWith('assets/')) {
          ButterflyDebugUtils.logError('Validator', 
              'Invalid audio file path for $key: $path');
          return false;
        }
      }
      
      // Validate image cache settings consistency
      final cacheSettings = ButterflyProductionConfig.imageCacheSettings;
      final requiredKeys = ['cacheWidth', 'cacheHeight', 'jarCacheWidth', 'jarCacheHeight'];
      
      for (final key in requiredKeys) {
        if (!cacheSettings.containsKey(key)) {
          ButterflyDebugUtils.logError('Validator', 
              'Missing image cache setting: $key');
          return false;
        }
      }
      
      // Validate shake animation settings
      if (ButterflyProductionConfig.minShakeInterval >= ButterflyProductionConfig.maxShakeInterval) {
        ButterflyDebugUtils.logError('Validator', 
            'Invalid shake interval range');
        return false;
      }
      
      if (ButterflyProductionConfig.shakeAmplitude <= 0) {
        ButterflyDebugUtils.logError('Validator', 
            'Invalid shake amplitude');
        return false;
      }
      
      ButterflyDebugUtils.logSuccess('Validator', 'Data integrity validation passed');
      return true;
    } catch (e) {
      ButterflyDebugUtils.logError('Validator', 'Data integrity validation failed: $e');
      return false;
    }
  }
  
  /// Validate animation system
  static bool _validateAnimationSystem() {
    ButterflyDebugUtils.log('Validator', 'Validating animation system...');
    
    try {
      // Validate grid layout settings
      if (ButterflyProductionConfig.gridCrossAxisCount <= 0) {
        ButterflyDebugUtils.logError('Validator', 'Invalid grid cross axis count');
        return false;
      }
      
      if (ButterflyProductionConfig.gridChildAspectRatio <= 0) {
        ButterflyDebugUtils.logError('Validator', 'Invalid grid child aspect ratio');
        return false;
      }
      
      // Validate UI dimensions
      if (ButterflyProductionConfig.cardBorderRadius < 0) {
        ButterflyDebugUtils.logError('Validator', 'Invalid card border radius');
        return false;
      }
      
      if (ButterflyProductionConfig.jarImageHeight <= 0) {
        ButterflyDebugUtils.logError('Validator', 'Invalid jar image height');
        return false;
      }
      
      if (ButterflyProductionConfig.butterflyImageSize <= 0) {
        ButterflyDebugUtils.logError('Validator', 'Invalid butterfly image size');
        return false;
      }
      
      // Validate daily reward settings
      if (ButterflyProductionConfig.dailyDiscoveryLimit <= 0) {
        ButterflyDebugUtils.logError('Validator', 'Invalid daily discovery limit');
        return false;
      }
      
      final dailyResetInterval = ButterflyProductionConfig.dailyResetInterval.inHours;
      if (dailyResetInterval <= 0 || dailyResetInterval > 48) { // Max 2 days
        ButterflyDebugUtils.logError('Validator', 
            'Invalid daily reset interval: ${dailyResetInterval} hours');
        return false;
      }
      
      ButterflyDebugUtils.logSuccess('Validator', 'Animation system validation passed');
      return true;
    } catch (e) {
      ButterflyDebugUtils.logError('Validator', 'Animation system validation failed: $e');
      return false;
    }
  }
  
  /// Get validation summary
  static Map<String, dynamic> getValidationSummary() {
    return {
      'has_run_validation': _hasRunValidation,
      'last_validation_result': _lastValidationResult,
      'configuration_valid': ButterflyConfigValidator.validateConfiguration(),
      'production_mode': ButterflyProductionConfig.isProduction,
      'debug_logging_enabled': ButterflyProductionConfig.enableDebugLogging,
      'performance_monitoring_enabled': ButterflyProductionConfig.enablePerformanceMonitoring,
      'validation_timestamp': DateTime.now().toIso8601String(),
    };
  }
  
  /// Reset validation state (for testing)
  static void resetValidationState() {
    _hasRunValidation = false;
    _lastValidationResult = false;
    ButterflyDebugUtils.log('Validator', 'Validation state reset');
  }
}

/// Specific butterfly feature validators
class ButterflyFeatureValidator {
  /// Validate discovery system configuration
  static bool validateDiscoverySystem() {
    if (!ButterflyProductionConfig.enableDailyRewards) {
      ButterflyDebugUtils.logWarning('FeatureValidator', 'Daily rewards system is disabled');
      return false;
    }
    
    final rarityRates = ButterflyProductionConfig.butterflyRarityRates;
    if (rarityRates.isEmpty) {
      ButterflyDebugUtils.logError('FeatureValidator', 'No rarity rates configured');
      return false;
    }
    
    // Check that all rarities have positive rates
    for (final entry in rarityRates.entries) {
      if (entry.value <= 0.0 || entry.value > 1.0) {
        ButterflyDebugUtils.logError('FeatureValidator', 
            'Invalid rarity rate for ${entry.key}: ${entry.value}');
        return false;
      }
    }
    
    ButterflyDebugUtils.logSuccess('FeatureValidator', 'Discovery system validation passed');
    return true;
  }
  
  /// Validate search system configuration
  static bool validateSearchSystem() {
    if (!ButterflyProductionConfig.enableSearchSystem) {
      ButterflyDebugUtils.logWarning('FeatureValidator', 'Search system is disabled');
      return false;
    }
    
    if (!ButterflyProductionConfig.enableRarityFilters) {
      ButterflyDebugUtils.logWarning('FeatureValidator', 'Rarity filters are disabled');
    }
    
    if (ButterflyProductionConfig.searchDebounceDelay.inMilliseconds <= 0) {
      ButterflyDebugUtils.logError('FeatureValidator', 'Invalid search debounce delay');
      return false;
    }
    
    ButterflyDebugUtils.logSuccess('FeatureValidator', 'Search system validation passed');
    return true;
  }
  
  /// Validate favorite system configuration
  static bool validateFavoriteSystem() {
    if (!ButterflyProductionConfig.enableFavoriteSystem) {
      ButterflyDebugUtils.logWarning('FeatureValidator', 'Favorite system is disabled');
      return false;
    }
    
    if (ButterflyProductionConfig.maxFavorites <= 0) {
      ButterflyDebugUtils.logError('FeatureValidator', 'Invalid max favorites limit');
      return false;
    }
    
    ButterflyDebugUtils.logSuccess('FeatureValidator', 'Favorite system validation passed');
    return true;
  }
  
  /// Validate collection stats system
  static bool validateCollectionStatsSystem() {
    if (!ButterflyProductionConfig.enableCollectionStats) {
      ButterflyDebugUtils.logWarning('FeatureValidator', 'Collection stats system is disabled');
      return false;
    }
    
    if (ButterflyProductionConfig.progressionRewards.isEmpty) {
      ButterflyDebugUtils.logError('FeatureValidator', 'No progression rewards configured');
      return false;
    }
    
    ButterflyDebugUtils.logSuccess('FeatureValidator', 'Collection stats system validation passed');
    return true;
  }
}
