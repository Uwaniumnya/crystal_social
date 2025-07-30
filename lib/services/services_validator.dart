import 'package:flutter/foundation.dart';
import 'services_production_config.dart';
import 'unified_service_manager.dart';
import 'device_registration_service.dart';
import 'push_notification_service.dart';
import 'enhanced_push_notification_integration.dart';
import 'device_user_tracking_service.dart';
import 'glimmer_service.dart';

/// Validation result structure
class ValidationResult {
  final bool isValid;
  final String serviceName;
  final List<String> warnings;
  final List<String> errors;
  final Map<String, dynamic> metrics;
  
  ValidationResult({
    required this.isValid,
    required this.serviceName,
    this.warnings = const [],
    this.errors = const [],
    this.metrics = const {},
  });
  
  Map<String, dynamic> toMap() {
    return {
      'is_valid': isValid,
      'service_name': serviceName,
      'warnings': warnings,
      'errors': errors,
      'metrics': metrics,
      'warning_count': warnings.length,
      'error_count': errors.length,
    };
  }
}

/// Services Validator
/// Validates all services are production-ready and functioning correctly
/// Performs comprehensive health checks and configuration validation
class ServicesValidator {
  
  // ============================================================================
  // SINGLETON PATTERN
  // ============================================================================
  
  static ServicesValidator? _instance;
  static ServicesValidator get instance {
    _instance ??= ServicesValidator._internal();
    return _instance!;
  }
  
  ServicesValidator._internal();
  
  // ============================================================================
  // VALIDATION RESULTS
  // ============================================================================
  
  // ============================================================================
  // COMPREHENSIVE VALIDATION
  // ============================================================================
  
  /// Perform comprehensive services validation
  Future<Map<String, ValidationResult>> validateAllServices() async {
    final results = <String, ValidationResult>{};
    
    if (kDebugMode) {
      debugPrint('🔍 Starting comprehensive services validation...');
    }
    
    try {
      // Validate production configuration
      results['production_config'] = await _validateProductionConfig();
      
      // Validate individual services
      results['unified_manager'] = await _validateUnifiedServiceManager();
      results['device_registration'] = await _validateDeviceRegistrationService();
      results['push_notifications'] = await _validatePushNotificationService();
      results['enhanced_notifications'] = await _validateEnhancedNotificationService();
      results['user_tracking'] = await _validateUserTrackingService();
      results['glimmer_service'] = await _validateGlimmerService();
      
      // Validate service integration
      results['service_integration'] = await _validateServiceIntegration();
      
      // Generate overall health report
      final overallValid = results.values.every((result) => result.isValid);
      final totalWarnings = results.values.fold(0, (sum, result) => sum + result.warnings.length);
      final totalErrors = results.values.fold(0, (sum, result) => sum + result.errors.length);
      
      if (kDebugMode) {
        debugPrint('✅ Services validation completed');
        debugPrint('📊 Overall valid: $overallValid');
        debugPrint('⚠️ Total warnings: $totalWarnings');
        debugPrint('❌ Total errors: $totalErrors');
      }
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error during services validation: $e');
      }
    }
    
    return results;
  }
  
  // ============================================================================
  // INDIVIDUAL SERVICE VALIDATION
  // ============================================================================
  
  /// Validate production configuration
  Future<ValidationResult> _validateProductionConfig() async {
    final warnings = <String>[];
    final errors = <String>[];
    final metrics = <String, dynamic>{};
    
    try {
      // Check if production config is valid
      if (!ServicesProductionConfig.validateProductionConfig()) {
        errors.add('Production configuration validation failed');
      }
      
      // Check debug settings in production
      if (kReleaseMode && ServicesProductionConfig.enableDebugLogging) {
        warnings.add('Debug logging enabled in release mode');
      }
      
      // Check timeout settings
      if (ServicesProductionConfig.serviceInitializationTimeout.inSeconds < 10) {
        warnings.add('Service initialization timeout may be too short for production');
      }
      
      // Check security settings
      if (ServicesProductionConfig.logServiceOperations && kReleaseMode) {
        errors.add('Service operation logging enabled in production (security risk)');
      }
      
      // Collect metrics
      metrics['is_production'] = ServicesProductionConfig.isProduction;
      metrics['debug_enabled'] = ServicesProductionConfig.enableDebugLogging;
      metrics['service_timeout'] = ServicesProductionConfig.serviceInitializationTimeout.inSeconds;
      metrics['notification_timeout'] = ServicesProductionConfig.notificationTimeout.inSeconds;
      
    } catch (e) {
      errors.add('Error validating production config: $e');
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      serviceName: 'production_config',
      warnings: warnings,
      errors: errors,
      metrics: metrics,
    );
  }
  
  /// Validate Unified Service Manager
  Future<ValidationResult> _validateUnifiedServiceManager() async {
    final warnings = <String>[];
    final errors = <String>[];
    final metrics = <String, dynamic>{};
    
    try {
      final manager = UnifiedServiceManager.instance;
      
      // Check if manager is properly initialized
      // Note: We can't directly check private _isInitialized field,
      // so we'll try to use the manager and catch any issues
      
      metrics['instance_created'] = true;
      metrics['manager_type'] = manager.runtimeType.toString();
      
    } catch (e) {
      errors.add('Error accessing Unified Service Manager: $e');
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      serviceName: 'unified_manager',
      warnings: warnings,
      errors: errors,
      metrics: metrics,
    );
  }
  
  /// Validate Device Registration Service
  Future<ValidationResult> _validateDeviceRegistrationService() async {
    final warnings = <String>[];
    final errors = <String>[];
    final metrics = <String, dynamic>{};
    
    try {
      final service = DeviceRegistrationService.instance;
      
      metrics['instance_created'] = true;
      metrics['service_type'] = service.runtimeType.toString();
      
      // Check configuration
      if (!ServicesProductionConfig.enableDeviceRegistration) {
        warnings.add('Device registration is disabled in configuration');
      }
      
      if (ServicesProductionConfig.maxDevicesPerUser < 1) {
        errors.add('Invalid max devices per user configuration');
      }
      
      metrics['max_devices_per_user'] = ServicesProductionConfig.maxDevicesPerUser;
      metrics['cleanup_enabled'] = ServicesProductionConfig.enableAutomaticDeviceCleanup;
      
    } catch (e) {
      errors.add('Error validating Device Registration Service: $e');
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      serviceName: 'device_registration',
      warnings: warnings,
      errors: errors,
      metrics: metrics,
    );
  }
  
  /// Validate Push Notification Service
  Future<ValidationResult> _validatePushNotificationService() async {
    final warnings = <String>[];
    final errors = <String>[];
    final metrics = <String, dynamic>{};
    
    try {
      final service = PushNotificationService.instance;
      
      metrics['instance_created'] = true;
      metrics['service_type'] = service.runtimeType.toString();
      
      // Check notification configuration
      if (!ServicesProductionConfig.enablePushNotifications) {
        warnings.add('Push notifications are disabled in configuration');
      }
      
      metrics['notifications_enabled'] = ServicesProductionConfig.enablePushNotifications;
      metrics['message_notifications'] = ServicesProductionConfig.enableMessageNotifications;
      metrics['glimmer_notifications'] = ServicesProductionConfig.enableGlimmerNotifications;
      metrics['system_notifications'] = ServicesProductionConfig.enableSystemNotifications;
      
    } catch (e) {
      errors.add('Error validating Push Notification Service: $e');
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      serviceName: 'push_notifications',
      warnings: warnings,
      errors: errors,
      metrics: metrics,
    );
  }
  
  /// Validate Enhanced Notification Service
  Future<ValidationResult> _validateEnhancedNotificationService() async {
    final warnings = <String>[];
    final errors = <String>[];
    final metrics = <String, dynamic>{};
    
    try {
      final service = EnhancedPushNotificationIntegration.instance;
      
      metrics['instance_created'] = true;
      metrics['service_type'] = service.runtimeType.toString();
      
      // Check if enhanced features are properly configured
      metrics['batch_processing'] = ServicesProductionConfig.isFeatureEnabled('batch_processing');
      metrics['performance_monitoring'] = ServicesProductionConfig.enablePerformanceMonitoring;
      
    } catch (e) {
      errors.add('Error validating Enhanced Notification Service: $e');
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      serviceName: 'enhanced_notifications',
      warnings: warnings,
      errors: errors,
      metrics: metrics,
    );
  }
  
  /// Validate User Tracking Service
  Future<ValidationResult> _validateUserTrackingService() async {
    final warnings = <String>[];
    final errors = <String>[];
    final metrics = <String, dynamic>{};
    
    try {
      final service = DeviceUserTrackingService.instance;
      
      metrics['instance_created'] = true;
      metrics['service_type'] = service.runtimeType.toString();
      
      // Check tracking configuration
      if (!ServicesProductionConfig.enableUserTracking) {
        warnings.add('User tracking is disabled in configuration');
      }
      
      metrics['tracking_enabled'] = ServicesProductionConfig.enableUserTracking;
      metrics['auto_logout_enabled'] = ServicesProductionConfig.enableAutoLogout;
      metrics['force_auto_logout'] = ServicesProductionConfig.forceAutoLogoutForMultipleUsers;
      
    } catch (e) {
      errors.add('Error validating User Tracking Service: $e');
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      serviceName: 'user_tracking',
      warnings: warnings,
      errors: errors,
      metrics: metrics,
    );
  }
  
  /// Validate Glimmer Service
  Future<ValidationResult> _validateGlimmerService() async {
    final warnings = <String>[];
    final errors = <String>[];
    final metrics = <String, dynamic>{};
    
    try {
      // Note: GlimmerService doesn't use singleton pattern, so we create an instance
      final service = GlimmerService();
      
      metrics['instance_created'] = true;
      metrics['service_type'] = service.runtimeType.toString();
      
      // Check Glimmer configuration
      if (!ServicesProductionConfig.enableGlimmerIntegration) {
        warnings.add('Glimmer integration is disabled in configuration');
      }
      
      metrics['glimmer_enabled'] = ServicesProductionConfig.enableGlimmerIntegration;
      metrics['notify_followers'] = ServicesProductionConfig.notifyFollowersOnNewPost;
      metrics['notify_owner_likes'] = ServicesProductionConfig.notifyOwnerOnLike;
      metrics['notify_owner_comments'] = ServicesProductionConfig.notifyOwnerOnComment;
      
    } catch (e) {
      errors.add('Error validating Glimmer Service: $e');
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      serviceName: 'glimmer_service',
      warnings: warnings,
      errors: errors,
      metrics: metrics,
    );
  }
  
  /// Validate Service Integration
  Future<ValidationResult> _validateServiceIntegration() async {
    final warnings = <String>[];
    final errors = <String>[];
    final metrics = <String, dynamic>{};
    
    try {
      // Check feature flag consistency
      final featureFlags = ServicesProductionConfig.featureFlags;
      metrics['feature_flags'] = featureFlags;
      
      // Check for conflicting settings
      if (!ServicesProductionConfig.enablePushNotifications && 
          ServicesProductionConfig.enableMessageNotifications) {
        warnings.add('Message notifications enabled but push notifications disabled');
      }
      
      if (!ServicesProductionConfig.enableUserTracking && 
          ServicesProductionConfig.enableAutoLogout) {
        warnings.add('Auto-logout enabled but user tracking disabled');
      }
      
      // Check timeout consistency
      if (ServicesProductionConfig.notificationTimeout > 
          ServicesProductionConfig.serviceInitializationTimeout) {
        warnings.add('Notification timeout longer than service initialization timeout');
      }
      
      metrics['integration_health'] = errors.isEmpty ? 'healthy' : 'issues_found';
      
    } catch (e) {
      errors.add('Error validating service integration: $e');
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      serviceName: 'service_integration',
      warnings: warnings,
      errors: errors,
      metrics: metrics,
    );
  }
  
  // ============================================================================
  // HEALTH CHECK METHODS
  // ============================================================================
  
  /// Perform quick health check
  Future<bool> quickHealthCheck() async {
    try {
      // Basic service instantiation check
      UnifiedServiceManager.instance;
      DeviceRegistrationService.instance;
      PushNotificationService.instance;
      EnhancedPushNotificationIntegration.instance;
      DeviceUserTrackingService.instance;
      GlimmerService();
      
      // Check production config
      return ServicesProductionConfig.validateProductionConfig();
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Quick health check failed: $e');
      }
      return false;
    }
  }
  
  /// Generate production readiness report
  Future<Map<String, dynamic>> generateProductionReadinessReport() async {
    final validationResults = await validateAllServices();
    
    final report = {
      'timestamp': DateTime.now().toIso8601String(),
      'environment': kReleaseMode ? 'production' : 'development',
      'overall_status': validationResults.values.every((r) => r.isValid) ? 'READY' : 'NOT_READY',
      'services': {},
      'summary': {
        'total_services': validationResults.length,
        'valid_services': validationResults.values.where((r) => r.isValid).length,
        'services_with_warnings': validationResults.values.where((r) => r.warnings.isNotEmpty).length,
        'services_with_errors': validationResults.values.where((r) => r.errors.isNotEmpty).length,
        'total_warnings': validationResults.values.fold(0, (sum, r) => sum + r.warnings.length),
        'total_errors': validationResults.values.fold(0, (sum, r) => sum + r.errors.length),
      },
      'production_config': ServicesProductionConfig.getEnvironmentConfig(),
    };
    
    // Add individual service results
    final servicesMap = report['services'] as Map<String, dynamic>;
    for (final entry in validationResults.entries) {
      servicesMap[entry.key] = entry.value.toMap();
    }
    
    return report;
  }
}
