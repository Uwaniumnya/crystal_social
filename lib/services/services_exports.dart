/// Crystal Social Services - Production-Ready Exports
/// 
/// This file provides a centralized export system for all Crystal Social services
/// with production configurations, performance optimizations, and validation utilities.
/// 
/// Usage in production:
/// ```dart
/// import 'package:crystal_social/services/services_exports.dart';
/// 
/// // Initialize all services with production configurations
/// await ServicesBootstrap.initializeForProduction();
/// 
/// // Use services through the unified manager
/// await UnifiedServiceManager.instance.handleUserLogin(userId);
/// 
/// // Validate production readiness
/// final report = await ServicesValidator.instance.generateProductionReadinessReport();
/// ```

// ============================================================================
// CORE SERVICES EXPORTS
// ============================================================================

/// Main service implementations
export 'device_registration_service.dart';
export 'push_notification_service.dart';
export 'enhanced_push_notification_integration.dart';
export 'device_user_tracking_service.dart';
export 'glimmer_service.dart';

/// Service management and integration
export 'unified_service_manager.dart';
export 'service_integration_helper.dart';
export 'service_initializer.dart';

/// Configuration and examples
export 'service_config.dart';
export 'service_integration_example.dart';

// ============================================================================
// PRODUCTION OPTIMIZATION EXPORTS
// ============================================================================

/// Production configuration and optimization
export 'services_production_config.dart';
export 'services_performance_optimizer.dart';
export 'services_validator.dart';

/// Legacy services export (for backward compatibility)
export 'services.dart';

// ============================================================================
// PRODUCTION BOOTSTRAP
// ============================================================================

import 'package:flutter/foundation.dart';
import 'services_production_config.dart';
import 'services_performance_optimizer.dart';
import 'services_validator.dart';
import 'service_initializer.dart';
import 'unified_service_manager.dart';

/// Services Bootstrap
/// Production-ready initialization and management for all Crystal Social services
class ServicesBootstrap {
  
  static bool _isInitialized = false;
  static bool _isProductionReady = false;
  
  /// Initialize all services for production use
  static Future<bool> initializeForProduction() async {
    if (_isInitialized) {
      if (kDebugMode) {
        debugPrint('✅ Services already initialized for production');
      }
      return _isProductionReady;
    }
    
    try {
      if (kDebugMode) {
        debugPrint('🚀 Initializing Crystal Social services for production...');
      }
      
      // Step 1: Validate production configuration
      if (!ServicesProductionConfig.validateProductionConfig()) {
        if (kDebugMode) {
          debugPrint('❌ Production configuration validation failed');
        }
        return false;
      }
      
      // Step 2: Initialize performance optimizer
      final optimizer = ServicesPerformanceOptimizer.instance;
      optimizer.startOperation('services_bootstrap');
      
      // Step 3: Initialize all services
      final initSuccess = await ServiceInitializer.initializeAllServices();
      if (!initSuccess) {
        if (kDebugMode) {
          debugPrint('❌ Service initialization failed');
        }
        optimizer.endOperation('services_bootstrap');
        return false;
      }
      
      // Step 4: Initialize unified service manager
      await UnifiedServiceManager.instance.initialize();
      
      // Step 5: Perform comprehensive validation
      final validator = ServicesValidator.instance;
      final healthCheck = await validator.quickHealthCheck();
      
      if (!healthCheck) {
        if (kDebugMode) {
          debugPrint('❌ Service health check failed');
        }
        optimizer.endOperation('services_bootstrap');
        return false;
      }
      
      // Step 6: Generate production readiness report
      if (kDebugMode) {
        final report = await validator.generateProductionReadinessReport();
        debugPrint('📊 Production readiness: ${report['overall_status']}');
        debugPrint('📈 Services summary: ${report['summary']}');
      }
      
      optimizer.endOperation('services_bootstrap');
      
      _isInitialized = true;
      _isProductionReady = true;
      
      if (kDebugMode) {
        debugPrint('✅ Crystal Social services initialized successfully for production');
      }
      
      return true;
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error initializing services for production: $e');
      }
      
      _isInitialized = false;
      _isProductionReady = false;
      return false;
    }
  }
  
  /// Quick health check for all services
  static Future<bool> performHealthCheck() async {
    if (!_isInitialized) {
      if (kDebugMode) {
        debugPrint('⚠️ Services not initialized - performing health check anyway');
      }
    }
    
    try {
      final validator = ServicesValidator.instance;
      return await validator.quickHealthCheck();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Health check failed: $e');
      }
      return false;
    }
  }
  
  /// Get comprehensive production status
  static Future<Map<String, dynamic>> getProductionStatus() async {
    try {
      final validator = ServicesValidator.instance;
      final report = await validator.generateProductionReadinessReport();
      
      return {
        'bootstrap_initialized': _isInitialized,
        'production_ready': _isProductionReady,
        'environment': kReleaseMode ? 'production' : 'development',
        'config_valid': ServicesProductionConfig.validateProductionConfig(),
        'detailed_report': report,
      };
      
    } catch (e) {
      return {
        'bootstrap_initialized': _isInitialized,
        'production_ready': false,
        'error': e.toString(),
      };
    }
  }
  
  /// Optimize service performance
  static Future<void> optimizePerformance() async {
    try {
      final optimizer = ServicesPerformanceOptimizer.instance;
      optimizer.optimizeResources();
      
      if (kDebugMode) {
        final metrics = optimizer.getPerformanceReport();
        debugPrint('🔧 Performance optimization completed');
        debugPrint('📊 Cache stats: ${metrics['cache_stats']}');
        debugPrint('📈 Batch stats: ${metrics['batch_stats']}');
      }
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error during performance optimization: $e');
      }
    }
  }
  
  /// Check if services are production ready
  static bool get isProductionReady => _isProductionReady;
  
  /// Check if services are initialized
  static bool get isInitialized => _isInitialized;
}

// ============================================================================
// PRODUCTION CONVENIENCE METHODS
// ============================================================================

/// Production Services Helper
/// Convenience methods for common production operations
class ProductionServicesHelper {
  
  /// Easy login with all service integrations
  static Future<bool> performUserLogin(String userId) async {
    if (!ServicesBootstrap.isProductionReady) {
      if (kDebugMode) {
        debugPrint('⚠️ Services not production ready - initializing...');
      }
      final initSuccess = await ServicesBootstrap.initializeForProduction();
      if (!initSuccess) return false;
    }
    
    try {
      await UnifiedServiceManager.instance.handleUserLogin(userId);
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ User login failed: $e');
      }
      return false;
    }
  }
  
  /// Easy logout with cleanup
  static Future<bool> performUserLogout(String userId) async {
    if (!ServicesBootstrap.isInitialized) {
      if (kDebugMode) {
        debugPrint('⚠️ Services not initialized');
      }
      return false;
    }
    
    try {
      await UnifiedServiceManager.instance.handleUserLogout(userId);
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ User logout failed: $e');
      }
      return false;
    }
  }
  
  /// Send notification with production optimizations
  static Future<bool> sendNotification({
    required String receiverUserId,
    required String senderUsername,
    required String title,
    required String body,
    String type = 'message',
  }) async {
    if (!ServicesBootstrap.isProductionReady) {
      if (kDebugMode) {
        debugPrint('⚠️ Services not production ready');
      }
      return false;
    }
    
    try {
      // Use batch processing if enabled
      if (ServicesProductionConfig.isFeatureEnabled('batch_processing')) {
        final optimizer = ServicesPerformanceOptimizer.instance;
        optimizer.addToBatch('notifications', {
          'receiver_user_id': receiverUserId,
          'sender_username': senderUsername,
          'title': title,
          'body': body,
          'type': type,
        });
        return true;
      } else {
        // Direct send
        final result = await UnifiedServiceManager.instance.sendMessageNotification(
          receiverUserId: receiverUserId,
          senderUsername: senderUsername,
          messagePreview: body,
        );
        return result;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Send notification failed: $e');
      }
      return false;
    }
  }
}
