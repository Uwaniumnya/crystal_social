import 'package:flutter/foundation.dart';
import 'unified_service_manager.dart';
import 'service_integration_helper.dart';
import 'device_registration_service.dart';
import 'push_notification_service.dart';
import 'enhanced_push_notification_integration.dart';
import 'device_user_tracking_service.dart';
import 'glimmer_service.dart';

/// Service Initializer
/// Ensures all services are properly initialized and configured
/// Call this once at app startup
class ServiceInitializer {
  static bool _isInitialized = false;
  static final List<String> _initializationLog = [];

  /// Initialize all services in the correct order
  static Future<bool> initializeAllServices() async {
    if (_isInitialized) {
      debugPrint('✅ Services already initialized');
      return true;
    }

    try {
      debugPrint('🚀 Starting service initialization...');
      _logStep('Service initialization started');

      // Step 1: Initialize core services
      await _initializeCoreServices();

      // Step 2: Initialize unified service manager
      await _initializeUnifiedManager();

      // Step 3: Initialize helper services
      await _initializeHelperServices();

      // Step 4: Verify all services are working
      await _verifyServices();

      _isInitialized = true;
      _logStep('All services initialized successfully');
      debugPrint('✅ All services initialized successfully');
      
      return true;

    } catch (e) {
      _logStep('Service initialization failed: $e');
      debugPrint('❌ Service initialization failed: $e');
      return false;
    }
  }

  /// Initialize core individual services
  static Future<void> _initializeCoreServices() async {
    debugPrint('📱 Initializing core services...');
    
    try {
      // Initialize device registration service
      final deviceService = DeviceRegistrationService.instance;
      await deviceService.initialize();
      _logStep('Device registration service initialized');

      // Initialize push notification service
      final pushService = PushNotificationService.instance;
      await pushService.initialize();
      _logStep('Push notification service initialized');

      // Initialize device user tracking service
      DeviceUserTrackingService.instance;
      // Note: This service doesn't have an initialize method
      _logStep('Device user tracking service ready');

      // Initialize glimmer service
      GlimmerService();
      // Note: This service doesn't have an initialize method
      _logStep('Glimmer service ready');

    } catch (e) {
      throw Exception('Failed to initialize core services: $e');
    }
  }

  /// Initialize unified service manager
  static Future<void> _initializeUnifiedManager() async {
    debugPrint('🔗 Initializing unified service manager...');
    
    try {
      final unifiedManager = UnifiedServiceManager.instance;
      await unifiedManager.initialize();
      _logStep('Unified service manager initialized');

    } catch (e) {
      throw Exception('Failed to initialize unified service manager: $e');
    }
  }

  /// Initialize helper services
  static Future<void> _initializeHelperServices() async {
    debugPrint('🛠️ Initializing helper services...');
    
    try {
      final helperService = ServiceIntegrationHelper.instance;
      await helperService.initializeAll();
      _logStep('Service integration helper initialized');

    } catch (e) {
      throw Exception('Failed to initialize helper services: $e');
    }
  }

  /// Verify all services are working correctly
  static Future<void> _verifyServices() async {
    debugPrint('✅ Verifying services...');
    
    try {
      final helperService = ServiceIntegrationHelper.instance;
      
      // Get system health status
      final healthStatus = await helperService.getSystemHealthStatus();
      
      if (healthStatus['status'] == 'healthy') {
        _logStep('Service verification passed');
      } else {
        throw Exception('Service verification failed: ${healthStatus['error']}');
      }

    } catch (e) {
      throw Exception('Service verification failed: $e');
    }
  }

  /// Get initialization status
  static bool get isInitialized => _isInitialized;

  /// Get initialization log for debugging
  static List<String> get initializationLog => List.unmodifiable(_initializationLog);

  /// Reset initialization status (for testing purposes)
  static void resetInitialization() {
    _isInitialized = false;
    _initializationLog.clear();
  }

  /// Quick check if services are ready
  static Future<bool> areServicesReady() async {
    if (!_isInitialized) {
      return await initializeAllServices();
    }
    return true;
  }

  /// Get comprehensive service status
  static Future<Map<String, dynamic>> getServiceStatus() async {
    try {
      final helperService = ServiceIntegrationHelper.instance;
      final healthStatus = await helperService.getSystemHealthStatus();
      
      return {
        'initialized': _isInitialized,
        'health_status': healthStatus,
        'initialization_log': _initializationLog,
        'timestamp': DateTime.now().toIso8601String(),
      };

    } catch (e) {
      return {
        'initialized': _isInitialized,
        'error': e.toString(),
        'initialization_log': _initializationLog,
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Private helper method to log initialization steps
  static void _logStep(String step) {
    final timestamp = DateTime.now().toIso8601String();
    final logEntry = '[$timestamp] $step';
    _initializationLog.add(logEntry);
    debugPrint('🔧 $step');
  }
}

/// Service Integration Wrapper
/// Provides static methods for easy access to integrated services
class Services {
  /// Get the unified service manager
  static UnifiedServiceManager get unified => UnifiedServiceManager.instance;

  /// Get the service integration helper
  static ServiceIntegrationHelper get helper => ServiceIntegrationHelper.instance;

  /// Get individual services
  static DeviceRegistrationService get deviceRegistration => DeviceRegistrationService.instance;
  static PushNotificationService get pushNotification => PushNotificationService.instance;
  static EnhancedPushNotificationIntegration get enhancedNotification => EnhancedPushNotificationIntegration.instance;
  static DeviceUserTrackingService get deviceUserTracking => DeviceUserTrackingService.instance;
  static GlimmerService get glimmer => GlimmerService();

  /// Initialize all services (convenience method)
  static Future<bool> initialize() async {
    return await ServiceInitializer.initializeAllServices();
  }

  /// Check if services are ready
  static Future<bool> isReady() async {
    return await ServiceInitializer.areServicesReady();
  }

  /// Get service status
  static Future<Map<String, dynamic>> getStatus() async {
    return await ServiceInitializer.getServiceStatus();
  }

  /// Quick login flow
  static Future<void> login(String userId) async {
    await helper.completeLoginFlow(userId);
  }

  /// Quick logout flow
  static Future<void> logout(String userId) async {
    await helper.completeLogoutFlow(userId);
  }

  /// Quick message notification
  static Future<bool> notifyMessage({
    required String receiverUserId,
    required String senderUsername,
    String? messagePreview,
  }) async {
    return await helper.sendChatMessageWithNotification(
      receiverUserId: receiverUserId,
      senderUsername: senderUsername,
      messageContent: messagePreview ?? '',
      messagePreview: messagePreview,
    );
  }
}
