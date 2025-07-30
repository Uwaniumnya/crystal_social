import 'dart:io';
import 'package:flutter/foundation.dart';
import 'pets_production_config.dart';

/// Validation result container
class ValidationResult {
  final bool isValid;
  final String component;
  final List<String> errors;
  final List<String> warnings;
  final Map<String, dynamic> metadata;
  
  const ValidationResult({
    required this.isValid,
    required this.component,
    this.errors = const [],
    this.warnings = const [],
    this.metadata = const {},
  });
  
  Map<String, dynamic> toJson() {
    return {
      'is_valid': isValid,
      'component': component,
      'errors': errors,
      'warnings': warnings,
      'metadata': metadata,
    };
  }
}

/// Comprehensive validator for pets system production readiness
class PetsValidator {
  static const String version = '1.0.0';
  
  /// Validate complete pets system
  static Future<ValidationResult> validatePetsSystem() async {
    final errors = <String>[];
    final warnings = <String>[];
    final metadata = <String, dynamic>{};
    
    try {
      // Validate configuration
      final configResult = await validateConfiguration();
      if (!configResult.isValid) {
        errors.addAll(configResult.errors.map((e) => 'Config: $e'));
      }
      warnings.addAll(configResult.warnings.map((w) => 'Config: $w'));
      
      // Validate assets
      final assetResult = await validateAssets();
      if (!assetResult.isValid) {
        errors.addAll(assetResult.errors.map((e) => 'Assets: $e'));
      }
      warnings.addAll(assetResult.warnings.map((w) => 'Assets: $w'));
      
      // Validate game mechanics
      final gameResult = await validateGameMechanics();
      if (!gameResult.isValid) {
        errors.addAll(gameResult.errors.map((e) => 'Game: $e'));
      }
      warnings.addAll(gameResult.warnings.map((w) => 'Game: $w'));
      
      // Validate performance
      final performanceResult = await validatePerformance();
      if (!performanceResult.isValid) {
        errors.addAll(performanceResult.errors.map((e) => 'Performance: $e'));
      }
      warnings.addAll(performanceResult.warnings.map((w) => 'Performance: $w'));
      
      metadata.addAll({
        'config_valid': configResult.isValid,
        'assets_valid': assetResult.isValid,
        'game_valid': gameResult.isValid,
        'performance_valid': performanceResult.isValid,
        'total_components_checked': 4,
        'validation_timestamp': DateTime.now().toIso8601String(),
      });
      
    } catch (e) {
      errors.add('System validation failed: $e');
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      component: 'PetsSystem',
      errors: errors,
      warnings: warnings,
      metadata: metadata,
    );
  }
  
  /// Validate production configuration
  static Future<ValidationResult> validateConfiguration() async {
    final errors = <String>[];
    final warnings = <String>[];
    final metadata = <String, dynamic>{};
    
    try {
      // Check production config validation
      if (!PetsProductionConfig.validateProductionConfig()) {
        errors.add('Production configuration validation failed');
      }
      
      // Check environment settings
      if (PetsProductionConfig.enableDebugLogging && kReleaseMode) {
        warnings.add('Debug logging enabled in release mode');
      }
      
      // Check pet limits
      if (PetsProductionConfig.maxPets <= 0) {
        errors.add('Invalid max pets limit');
      }
      
      if (PetsProductionConfig.maxAccessories <= 0) {
        errors.add('Invalid max accessories limit');
      }
      
      // Check level settings
      if (PetsProductionConfig.maxPetLevel <= 0) {
        errors.add('Invalid max pet level');
      }
      
      if (PetsProductionConfig.xpPerLevel <= 0) {
        errors.add('Invalid XP per level');
      }
      
      // Check audio settings
      if (PetsProductionConfig.defaultVolume < 0.0 || PetsProductionConfig.defaultVolume > 1.0) {
        errors.add('Invalid default volume (must be 0.0-1.0)');
      }
      
      if (PetsProductionConfig.soundCacheSize <= 0) {
        errors.add('Invalid sound cache size');
      }
      
      // Check happiness bounds
      if (PetsProductionConfig.minHappiness < 0.0 || PetsProductionConfig.maxHappiness > 1.0) {
        errors.add('Invalid happiness bounds');
      }
      
      if (PetsProductionConfig.minHappiness >= PetsProductionConfig.maxHappiness) {
        errors.add('Min happiness must be less than max happiness');
      }
      
      // Check performance settings
      if (PetsProductionConfig.maxConcurrentAnimations <= 0) {
        errors.add('Invalid max concurrent animations');
      }
      
      if (PetsProductionConfig.maxCacheSize <= 0) {
        errors.add('Invalid max cache size');
      }
      
      // Check timeout values
      if (PetsProductionConfig.networkTimeout.inSeconds <= 0) {
        errors.add('Invalid network timeout');
      }
      
      if (PetsProductionConfig.gameSessionTimeout.inMinutes <= 0) {
        errors.add('Invalid game session timeout');
      }
      
      metadata.addAll(PetsProductionConfig.getConfigSummary());
      
    } catch (e) {
      errors.add('Configuration validation error: $e');
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      component: 'Configuration',
      errors: errors,
      warnings: warnings,
      metadata: metadata,
    );
  }
  
  /// Validate asset availability and integrity
  static Future<ValidationResult> validateAssets() async {
    final errors = <String>[];
    final warnings = <String>[];
    final metadata = <String, dynamic>{};
    
    try {
      final assetPaths = [
        'assets/pets',
        'assets/pet_sounds',
        'assets/pet_accessories',
        'assets/animations',
      ];
      
      int foundAssets = 0;
      int missingAssets = 0;
      
      for (final path in assetPaths) {
        try {
          final directory = Directory(path);
          if (await directory.exists()) {
            final files = await directory.list().toList();
            foundAssets += files.length;
            metadata['${path.replaceAll('/', '_')}_count'] = files.length;
          } else {
            warnings.add('Asset directory not found: $path');
            missingAssets++;
          }
        } catch (e) {
          warnings.add('Error checking asset directory $path: $e');
        }
      }
      
      // Check for critical pet assets
      final criticalAssets = [
        'assets/pets/default_pet.gif',
        'assets/pet_sounds/default_sound.mp3',
      ];
      
      for (final asset in criticalAssets) {
        try {
          final file = File(asset);
          if (!await file.exists()) {
            warnings.add('Critical asset missing: $asset');
          }
        } catch (e) {
          warnings.add('Error checking critical asset $asset: $e');
        }
      }
      
      metadata.addAll({
        'total_assets_found': foundAssets,
        'missing_asset_directories': missingAssets,
        'asset_directories_checked': assetPaths.length,
        'critical_assets_checked': criticalAssets.length,
      });
      
      if (foundAssets == 0) {
        warnings.add('No pet assets found in any directory');
      }
      
    } catch (e) {
      errors.add('Asset validation error: $e');
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      component: 'Assets',
      errors: errors,
      warnings: warnings,
      metadata: metadata,
    );
  }
  
  /// Validate game mechanics
  static Future<ValidationResult> validateGameMechanics() async {
    final errors = <String>[];
    final warnings = <String>[];
    final metadata = <String, dynamic>{};
    
    try {
      // Check XP system
      if (PetsProductionConfig.maxDailyXP <= 0) {
        errors.add('Invalid max daily XP');
      }
      
      if (PetsProductionConfig.maxStreak <= 0) {
        errors.add('Invalid max streak');
      }
      
      // Check mini-game settings
      if (PetsProductionConfig.maxMiniGameDuration <= 0) {
        errors.add('Invalid mini-game duration');
      }
      
      // Check care intervals
      if (PetsProductionConfig.hungerInterval.inHours <= 0) {
        errors.add('Invalid hunger interval');
      }
      
      if (PetsProductionConfig.playInterval.inHours <= 0) {
        errors.add('Invalid play interval');
      }
      
      // Check sound cooldown
      if (PetsProductionConfig.petSoundCooldown.inSeconds <= 0) {
        errors.add('Invalid pet sound cooldown');
      }
      
      // Validate game balance
      if (PetsProductionConfig.maxDailyXP < PetsProductionConfig.xpPerLevel) {
        warnings.add('Max daily XP is less than XP per level - may slow progression');
      }
      
      if (PetsProductionConfig.hungerInterval < PetsProductionConfig.playInterval) {
        warnings.add('Hunger interval is shorter than play interval - pets may get hungry frequently');
      }
      
      metadata.addAll({
        'max_daily_xp': PetsProductionConfig.maxDailyXP,
        'xp_per_level': PetsProductionConfig.xpPerLevel,
        'max_pet_level': PetsProductionConfig.maxPetLevel,
        'max_streak': PetsProductionConfig.maxStreak,
        'mini_game_duration_seconds': PetsProductionConfig.maxMiniGameDuration,
        'hunger_interval_hours': PetsProductionConfig.hungerInterval.inHours,
        'play_interval_hours': PetsProductionConfig.playInterval.inHours,
        'sound_cooldown_seconds': PetsProductionConfig.petSoundCooldown.inSeconds,
      });
      
    } catch (e) {
      errors.add('Game mechanics validation error: $e');
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      component: 'GameMechanics',
      errors: errors,
      warnings: warnings,
      metadata: metadata,
    );
  }
  
  /// Validate performance settings
  static Future<ValidationResult> validatePerformance() async {
    final errors = <String>[];
    final warnings = <String>[];
    final metadata = <String, dynamic>{};
    
    try {
      // Check animation settings
      if (PetsProductionConfig.maxAnimationFrames <= 0) {
        errors.add('Invalid max animation frames');
      }
      
      if (PetsProductionConfig.petStateUpdateInterval <= 0) {
        errors.add('Invalid pet state update interval');
      }
      
      // Check cache settings
      if (PetsProductionConfig.maxCacheSize <= 0) {
        errors.add('Invalid max cache size');
      }
      
      if (PetsProductionConfig.soundCacheSize <= 0) {
        errors.add('Invalid sound cache size');
      }
      
      // Check network settings
      if (PetsProductionConfig.maxRetryAttempts <= 0) {
        errors.add('Invalid max retry attempts');
      }
      
      // Performance warnings
      if (PetsProductionConfig.maxConcurrentAnimations > 10) {
        warnings.add('High concurrent animation limit may impact performance');
      }
      
      if (PetsProductionConfig.maxCacheSize > 200) {
        warnings.add('Large cache size may impact memory usage');
      }
      
      if (PetsProductionConfig.petStateUpdateInterval < 500) {
        warnings.add('Very frequent state updates may impact performance');
      }
      
      metadata.addAll({
        'max_animation_frames': PetsProductionConfig.maxAnimationFrames,
        'max_concurrent_animations': PetsProductionConfig.maxConcurrentAnimations,
        'state_update_interval_ms': PetsProductionConfig.petStateUpdateInterval,
        'max_cache_size': PetsProductionConfig.maxCacheSize,
        'sound_cache_size': PetsProductionConfig.soundCacheSize,
        'network_timeout_seconds': PetsProductionConfig.networkTimeout.inSeconds,
        'max_retry_attempts': PetsProductionConfig.maxRetryAttempts,
      });
      
    } catch (e) {
      errors.add('Performance validation error: $e');
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      component: 'Performance',
      errors: errors,
      warnings: warnings,
      metadata: metadata,
    );
  }
  
  /// Validate pet data structure
  static ValidationResult validatePetData(Map<String, dynamic> petData) {
    final errors = <String>[];
    final warnings = <String>[];
    final metadata = <String, dynamic>{};
    
    try {
      // Required fields
      final requiredFields = ['pet_id', 'name', 'type'];
      for (final field in requiredFields) {
        if (!petData.containsKey(field) || petData[field] == null) {
          errors.add('Missing required field: $field');
        }
      }
      
      // Validate pet name length
      final name = petData['name'] as String?;
      if (name != null && name.length > PetsProductionConfig.maxNameLength) {
        errors.add('Pet name exceeds maximum length');
      }
      
      // Validate happiness bounds
      final happiness = petData['happiness'] as double?;
      if (happiness != null) {
        if (happiness < PetsProductionConfig.minHappiness || happiness > PetsProductionConfig.maxHappiness) {
          errors.add('Happiness value out of bounds');
        }
      }
      
      // Validate XP and level
      final xp = petData['xp'] as int?;
      final level = petData['level'] as int?;
      if (level != null && level > PetsProductionConfig.maxPetLevel) {
        errors.add('Pet level exceeds maximum');
      }
      
      if (xp != null && xp < 0) {
        errors.add('XP cannot be negative');
      }
      
      // Validate data types
      final numericFields = ['happiness', 'energy', 'health'];
      for (final field in numericFields) {
        if (petData.containsKey(field) && petData[field] != null && petData[field] is! num) {
          errors.add('Field $field must be numeric');
        }
      }
      
      metadata.addAll({
        'total_fields': petData.length,
        'required_fields_present': requiredFields.where((f) => petData.containsKey(f)).length,
        'name_length': name?.length ?? 0,
        'happiness_value': happiness ?? 0.0,
        'xp_value': xp ?? 0,
        'level_value': level ?? 0,
      });
      
    } catch (e) {
      errors.add('Pet data validation error: $e');
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      component: 'PetData',
      errors: errors,
      warnings: warnings,
      metadata: metadata,
    );
  }
  
  /// Generate validation report
  static Future<Map<String, dynamic>> generateValidationReport() async {
    final systemResult = await validatePetsSystem();
    
    return {
      'validator_version': version,
      'validation_timestamp': DateTime.now().toIso8601String(),
      'system_validation': systemResult.toJson(),
      'production_ready': systemResult.isValid,
      'total_errors': systemResult.errors.length,
      'total_warnings': systemResult.warnings.length,
      'configuration': PetsProductionConfig.getConfigSummary(),
    };
  }
}
