import 'dart:io';
import 'package:flutter/foundation.dart';
import 'profile_production_config.dart';

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

/// Comprehensive validator for profile system production readiness
class ProfileValidator {
  static const String version = '1.0.0';
  
  /// Validate complete profile system
  static Future<ValidationResult> validateProfileSystem() async {
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
      
      // Validate security
      final securityResult = await validateSecurity();
      if (!securityResult.isValid) {
        errors.addAll(securityResult.errors.map((e) => 'Security: $e'));
      }
      warnings.addAll(securityResult.warnings.map((w) => 'Security: $w'));
      
      // Validate performance
      final performanceResult = await validatePerformance();
      if (!performanceResult.isValid) {
        errors.addAll(performanceResult.errors.map((e) => 'Performance: $e'));
      }
      warnings.addAll(performanceResult.warnings.map((w) => 'Performance: $w'));
      
      metadata.addAll({
        'config_valid': configResult.isValid,
        'assets_valid': assetResult.isValid,
        'security_valid': securityResult.isValid,
        'performance_valid': performanceResult.isValid,
        'total_components_checked': 4,
        'validation_timestamp': DateTime.now().toIso8601String(),
      });
      
    } catch (e) {
      errors.add('System validation failed: $e');
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      component: 'ProfileSystem',
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
      if (!ProfileProductionConfig.validateProductionConfig()) {
        errors.add('Production configuration validation failed');
      }
      
      // Check environment settings
      if (ProfileProductionConfig.enableDebugLogging && kReleaseMode) {
        warnings.add('Debug logging enabled in release mode');
      }
      
      // Check cache settings
      if (ProfileProductionConfig.cacheTimeout <= 0) {
        errors.add('Invalid cache timeout');
      }
      
      if (ProfileProductionConfig.maxCacheSize <= 0) {
        errors.add('Invalid max cache size');
      }
      
      // Check file size limits
      if (ProfileProductionConfig.maxAvatarSize <= 0) {
        errors.add('Invalid max avatar size');
      }
      
      if (ProfileProductionConfig.maxSoundFileSize <= 0) {
        errors.add('Invalid max sound file size');
      }
      
      // Check supported formats
      if (ProfileProductionConfig.supportedImageFormats.isEmpty) {
        errors.add('No supported image formats defined');
      }
      
      if (ProfileProductionConfig.supportedAudioFormats.isEmpty) {
        errors.add('No supported audio formats defined');
      }
      
      // Check timeout values
      if (ProfileProductionConfig.requestTimeout.inSeconds <= 0) {
        errors.add('Invalid request timeout');
      }
      
      if (ProfileProductionConfig.profileLoadTimeoutMs <= 0) {
        errors.add('Invalid profile load timeout');
      }
      
      metadata.addAll(ProfileProductionConfig.getConfigSummary());
      
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
        'assets/decorations',
        'assets/notification_sounds',
        'assets/icons',
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
      
      metadata.addAll({
        'total_assets_found': foundAssets,
        'missing_asset_directories': missingAssets,
        'asset_directories_checked': assetPaths.length,
      });
      
      if (foundAssets == 0) {
        warnings.add('No assets found in any directory');
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
  
  /// Validate security settings
  static Future<ValidationResult> validateSecurity() async {
    final errors = <String>[];
    final warnings = <String>[];
    final metadata = <String, dynamic>{};
    
    try {
      // Check encryption settings
      if (!ProfileProductionConfig.enableDataEncryption && kReleaseMode) {
        warnings.add('Data encryption disabled in release mode');
      }
      
      // Check privacy enforcement
      if (!ProfileProductionConfig.enforcePrivacySettings) {
        errors.add('Privacy settings enforcement is disabled');
      }
      
      // Check session timeout
      if (ProfileProductionConfig.sessionTimeoutMinutes <= 0) {
        errors.add('Invalid session timeout');
      }
      
      // Check bio and username length limits
      if (ProfileProductionConfig.maxBioLength <= 0) {
        errors.add('Invalid max bio length');
      }
      
      if (ProfileProductionConfig.maxUsernameLength <= 0) {
        errors.add('Invalid max username length');
      }
      
      metadata.addAll({
        'encryption_enabled': ProfileProductionConfig.enableDataEncryption,
        'privacy_enforced': ProfileProductionConfig.enforcePrivacySettings,
        'session_timeout_minutes': ProfileProductionConfig.sessionTimeoutMinutes,
        'max_bio_length': ProfileProductionConfig.maxBioLength,
        'max_username_length': ProfileProductionConfig.maxUsernameLength,
      });
      
    } catch (e) {
      errors.add('Security validation error: $e');
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      component: 'Security',
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
      // Check timeout values
      if (ProfileProductionConfig.imageLoadTimeoutMs <= 0) {
        errors.add('Invalid image load timeout');
      }
      
      // Check concurrent upload limits
      if (ProfileProductionConfig.maxConcurrentUploads <= 0) {
        errors.add('Invalid max concurrent uploads');
      }
      
      // Check animation settings
      if (ProfileProductionConfig.animationDuration.inMilliseconds <= 0) {
        errors.add('Invalid animation duration');
      }
      
      // Check stats update interval
      if (ProfileProductionConfig.statsUpdateInterval <= 0) {
        errors.add('Invalid stats update interval');
      }
      
      // Performance warnings
      if (ProfileProductionConfig.maxCacheSize > 200) {
        warnings.add('Large cache size may impact memory usage');
      }
      
      if (ProfileProductionConfig.maxDecorationCacheSize > 100) {
        warnings.add('Large decoration cache may impact memory usage');
      }
      
      metadata.addAll({
        'image_load_timeout_ms': ProfileProductionConfig.imageLoadTimeoutMs,
        'max_concurrent_uploads': ProfileProductionConfig.maxConcurrentUploads,
        'animation_duration_ms': ProfileProductionConfig.animationDuration.inMilliseconds,
        'stats_update_interval_s': ProfileProductionConfig.statsUpdateInterval,
        'max_cache_size': ProfileProductionConfig.maxCacheSize,
        'max_decoration_cache_size': ProfileProductionConfig.maxDecorationCacheSize,
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
  
  /// Validate profile data structure
  static ValidationResult validateProfileData(Map<String, dynamic> profileData) {
    final errors = <String>[];
    final warnings = <String>[];
    final metadata = <String, dynamic>{};
    
    try {
      // Required fields
      final requiredFields = ['user_id', 'username'];
      for (final field in requiredFields) {
        if (!profileData.containsKey(field) || profileData[field] == null) {
          errors.add('Missing required field: $field');
        }
      }
      
      // Validate username length
      final username = profileData['username'] as String?;
      if (username != null && username.length > ProfileProductionConfig.maxUsernameLength) {
        errors.add('Username exceeds maximum length');
      }
      
      // Validate bio length
      final bio = profileData['bio'] as String?;
      if (bio != null && bio.length > ProfileProductionConfig.maxBioLength) {
        errors.add('Bio exceeds maximum length');
      }
      
      // Validate data types
      final stringFields = ['username', 'bio', 'display_name', 'location', 'website'];
      for (final field in stringFields) {
        if (profileData.containsKey(field) && profileData[field] != null && profileData[field] is! String) {
          errors.add('Field $field must be a string');
        }
      }
      
      metadata.addAll({
        'total_fields': profileData.length,
        'required_fields_present': requiredFields.where((f) => profileData.containsKey(f)).length,
        'username_length': username?.length ?? 0,
        'bio_length': bio?.length ?? 0,
      });
      
    } catch (e) {
      errors.add('Profile data validation error: $e');
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      component: 'ProfileData',
      errors: errors,
      warnings: warnings,
      metadata: metadata,
    );
  }
  
  /// Generate validation report
  static Future<Map<String, dynamic>> generateValidationReport() async {
    final systemResult = await validateProfileSystem();
    
    return {
      'validator_version': version,
      'validation_timestamp': DateTime.now().toIso8601String(),
      'system_validation': systemResult.toJson(),
      'production_ready': systemResult.isValid,
      'total_errors': systemResult.errors.length,
      'total_warnings': systemResult.warnings.length,
      'configuration': ProfileProductionConfig.getConfigSummary(),
    };
  }
}
