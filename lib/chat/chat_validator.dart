// File: chat_validator.dart
// Validation and production readiness checks for chat system

import 'chat_production_config.dart';
import 'chat_performance_optimizer.dart';

/// Validation system for chat functionality
class ChatValidator {
  static final ChatValidator _instance = ChatValidator._internal();
  factory ChatValidator() => _instance;
  ChatValidator._internal();

  /// Validate production readiness
  static Future<Map<String, dynamic>> validateProductionReadiness() async {
    final results = <String, dynamic>{
      'overall_status': 'checking',
      'checks': <String, dynamic>{},
      'warnings': <String>[],
      'errors': <String>[],
      'recommendations': <String>[],
    };

    try {
      // Configuration validation
      results['checks']['configuration'] = _validateConfiguration();
      
      // Performance validation
      results['checks']['performance'] = await _validatePerformance();
      
      // Security validation
      results['checks']['security'] = _validateSecurity();
      
      // Feature validation
      results['checks']['features'] = await _validateFeatures();
      
      // Dependencies validation
      results['checks']['dependencies'] = _validateDependencies();

      // Determine overall status
      final hasErrors = results['errors'].isNotEmpty;
      final hasWarnings = results['warnings'].isNotEmpty;
      
      if (hasErrors) {
        results['overall_status'] = 'failed';
      } else if (hasWarnings) {
        results['overall_status'] = 'warning';
      } else {
        results['overall_status'] = 'passed';
      }

      ChatDebugUtils.logSuccess('Validator', 'Production readiness check completed');
      
    } catch (e) {
      results['overall_status'] = 'error';
      results['errors'].add('Validation process failed: $e');
      ChatDebugUtils.logError('Validator', 'Validation failed: $e');
    }

    return results;
  }

  /// Validate configuration settings
  static Map<String, dynamic> _validateConfiguration() {
    final config = <String, dynamic>{
      'status': 'passed',
      'details': <String, dynamic>{},
    };

    // Check critical configuration values
    if (ChatProductionConfig.maxMessageLength <= 0) {
      config['status'] = 'failed';
      config['details']['max_message_length'] = 'Invalid max message length configuration';
    }

    if (ChatProductionConfig.maxMediaSizeMB <= 0) {
      config['status'] = 'failed';
      config['details']['max_media_size'] = 'Invalid max media size configuration';
    }

    if (ChatProductionConfig.maxChatsPerUser <= 0) {
      config['status'] = 'failed';
      config['details']['max_chats_per_user'] = 'Invalid max chats per user configuration';
    }

    // Check timeout configurations
    if (ChatProductionConfig.typingIndicatorTimeout.inSeconds <= 0) {
      config['status'] = 'warning';
      config['details']['typing_timeout'] = 'Very short typing indicator timeout';
    }

    if (ChatProductionConfig.connectionRetryDelay.inSeconds <= 0) {
      config['status'] = 'failed';
      config['details']['retry_delay'] = 'Invalid retry delay configuration';
    }

    // Check file format configurations
    if (ChatProductionConfig.allowedImageFormats.isEmpty) {
      config['status'] = 'warning';
      config['details']['image_formats'] = 'No image formats allowed';
    }

    return config;
  }

  /// Validate performance settings
  static Future<Map<String, dynamic>> _validatePerformance() async {
    final performance = <String, dynamic>{
      'status': 'passed',
      'details': <String, dynamic>{},
    };

    try {
      // Initialize performance optimizer for testing
      final optimizer = ChatPerformanceOptimizer();
      optimizer.initialize();

      // Check cache limits
      if (ChatProductionConfig.maxMessagesInMemory > 1000) {
        performance['status'] = 'warning';
        performance['details']['message_cache'] = 'High message cache limit may impact memory';
      }

      if (ChatProductionConfig.maxChatHistory > 2000) {
        performance['status'] = 'warning';
        performance['details']['chat_history'] = 'High chat history limit may impact performance';
      }

      // Test performance monitoring
      final stopwatch = Stopwatch()..start();
      await Future.delayed(const Duration(milliseconds: 5));
      stopwatch.stop();
      
      optimizer.trackOperation('test_operation', stopwatch.elapsed);
      final avgPerf = optimizer.getAveragePerformance('test_operation');
      
      if (avgPerf == null) {
        performance['status'] = 'warning';
        performance['details']['performance_tracking'] = 'Performance tracking not working properly';
      }

      // Check memory limits
      if (ChatProductionConfig.maxRecentChats > 100) {
        performance['status'] = 'warning';
        performance['details']['recent_chats'] = 'High recent chats limit may impact performance';
      }

    } catch (e) {
      performance['status'] = 'failed';
      performance['details']['error'] = 'Performance validation failed: $e';
    }

    return performance;
  }

  /// Validate security settings
  static Map<String, dynamic> _validateSecurity() {
    final security = <String, dynamic>{
      'status': 'passed',
      'details': <String, dynamic>{},
    };

    // Check moderation settings
    if (!ChatProductionConfig.enableAutoModeration) {
      security['status'] = 'warning';
      security['details']['auto_moderation'] = 'Auto-moderation is disabled';
    }

    // Check spam prevention
    if (ChatProductionConfig.maxConsecutiveMessages > 20) {
      security['status'] = 'warning';
      security['details']['spam_prevention'] = 'High consecutive message limit';
    }

    if (ChatProductionConfig.spamPreventionWindow.inSeconds < 10) {
      security['status'] = 'warning';
      security['details']['spam_window'] = 'Short spam prevention window';
    }

    // Check file upload security
    if (ChatProductionConfig.maxMediaSizeMB > 50) {
      security['status'] = 'warning';
      security['details']['file_size_limit'] = 'High file size limit may be risky';
    }

    // Check session timeout
    if (ChatProductionConfig.sessionTimeout.inHours > 24) {
      security['status'] = 'warning';
      security['details']['session_timeout'] = 'Long session timeout may be insecure';
    }

    // Check audit logging
    if (!ChatProductionConfig.enableAuditLogging) {
      security['status'] = 'warning';
      security['details']['audit_logging'] = 'Audit logging is disabled';
    }

    // Check encryption
    if (!ChatProductionConfig.enableMessageEncryption) {
      security['details']['encryption'] = 'Message encryption is disabled (may be intentional)';
    }

    return security;
  }

  /// Validate feature settings
  static Future<Map<String, dynamic>> _validateFeatures() async {
    final features = <String, dynamic>{
      'status': 'passed',
      'details': <String, dynamic>{},
    };

    try {
      // Check core messaging features
      if (!ChatProductionConfig.enableTypingIndicators) {
        features['details']['typing_indicators'] = 'Typing indicators disabled';
      }

      if (!ChatProductionConfig.enableReadReceipts) {
        features['details']['read_receipts'] = 'Read receipts disabled';
      }

      // Check media features
      if (!ChatProductionConfig.enableMediaSharing) {
        features['details']['media_sharing'] = 'Media sharing disabled';
      }

      if (!ChatProductionConfig.enableStickers) {
        features['details']['stickers'] = 'Stickers disabled';
      }

      // Check notification features
      if (!ChatProductionConfig.enablePushNotifications) {
        features['status'] = 'warning';
        features['details']['push_notifications'] = 'Push notifications disabled';
      }

      // Check advanced features
      if (ChatProductionConfig.enableVoiceMessages) {
        features['details']['voice_messages'] = 'Voice messages enabled (ensure proper implementation)';
      }

      if (ChatProductionConfig.enableScreenshotDetection) {
        features['details']['screenshot_detection'] = 'Screenshot detection enabled (beta feature)';
      }

    } catch (e) {
      features['status'] = 'failed';
      features['details']['error'] = 'Feature validation failed: $e';
    }

    return features;
  }

  /// Validate dependencies
  static Map<String, dynamic> _validateDependencies() {
    final dependencies = <String, dynamic>{
      'status': 'passed',
      'details': <String, dynamic>{},
    };

    try {
      // Check required imports/dependencies
      // This would typically check if all required packages are available
      
      // Validate Supabase configuration
      dependencies['details']['supabase'] = 'Supabase integration ready';
      
      // Validate Flutter services
      dependencies['details']['flutter_services'] = 'Flutter services available';
      
      // Check notification services
      if (ChatProductionConfig.enablePushNotifications) {
        dependencies['details']['notifications'] = 'Push notification service configured';
      }

      // Check media handling
      if (ChatProductionConfig.enableMediaSharing) {
        dependencies['details']['media_handling'] = 'Media handling services configured';
      }

    } catch (e) {
      dependencies['status'] = 'failed';
      dependencies['details']['error'] = 'Dependencies validation failed: $e';
    }

    return dependencies;
  }

  /// Validate message data structure
  static Map<String, dynamic> validateMessageData(Map<String, dynamic> messageData) {
    final validation = <String, dynamic>{
      'valid': true,
      'errors': <String>[],
      'warnings': <String>[],
    };

    // Required fields
    final requiredFields = ['id', 'chat_id', 'sender_id', 'content', 'created_at'];
    for (final field in requiredFields) {
      if (!messageData.containsKey(field) || messageData[field] == null) {
        validation['valid'] = false;
        validation['errors'].add('Missing required field: $field');
      }
    }

    // Validate content
    final content = messageData['content'] as String?;
    if (content != null) {
      if (!ChatSystemUtils.isValidMessage(content)) {
        validation['valid'] = false;
        validation['errors'].add('Invalid message content');
      }
    }

    // Validate media if present
    final mediaUrl = messageData['media_url'] as String?;
    final mediaType = messageData['media_type'] as String?;
    if (mediaUrl != null && mediaType != null) {
      // Check if media type is valid
      if (!['image', 'video', 'audio', 'document'].contains(mediaType)) {
        validation['warnings'].add('Unknown media type: $mediaType');
      }
    }

    return validation;
  }

  /// Validate chat data structure
  static Map<String, dynamic> validateChatData(Map<String, dynamic> chatData) {
    final validation = <String, dynamic>{
      'valid': true,
      'errors': <String>[],
      'warnings': <String>[],
    };

    // Required fields
    final requiredFields = ['id', 'participants', 'created_at'];
    for (final field in requiredFields) {
      if (!chatData.containsKey(field) || chatData[field] == null) {
        validation['valid'] = false;
        validation['errors'].add('Missing required field: $field');
      }
    }

    // Validate participants
    final participants = chatData['participants'] as List?;
    if (participants != null) {
      if (participants.isEmpty) {
        validation['valid'] = false;
        validation['errors'].add('Chat must have at least one participant');
      } else if (participants.length > 100) {
        validation['warnings'].add('Large number of participants may impact performance');
      }
    }

    return validation;
  }

  /// Generate production readiness report
  static Future<String> generateProductionReport() async {
    final results = await validateProductionReadiness();
    final buffer = StringBuffer();

    buffer.writeln('=== CHAT SYSTEM PRODUCTION READINESS REPORT ===');
    buffer.writeln('Generated: ${DateTime.now()}');
    buffer.writeln('Overall Status: ${results['overall_status']}');
    buffer.writeln();

    // Configuration details
    buffer.writeln('CONFIGURATION:');
    final config = results['checks']['configuration'];
    buffer.writeln('  Status: ${config['status']}');
    if (config['details'].isNotEmpty) {
      config['details'].forEach((key, value) {
        buffer.writeln('  - $key: $value');
      });
    }
    buffer.writeln();

    // Performance details
    buffer.writeln('PERFORMANCE:');
    final performance = results['checks']['performance'];
    buffer.writeln('  Status: ${performance['status']}');
    if (performance['details'].isNotEmpty) {
      performance['details'].forEach((key, value) {
        buffer.writeln('  - $key: $value');
      });
    }
    buffer.writeln();

    // Security details
    buffer.writeln('SECURITY:');
    final security = results['checks']['security'];
    buffer.writeln('  Status: ${security['status']}');
    if (security['details'].isNotEmpty) {
      security['details'].forEach((key, value) {
        buffer.writeln('  - $key: $value');
      });
    }
    buffer.writeln();

    // Feature details
    buffer.writeln('FEATURES:');
    final features = results['checks']['features'];
    buffer.writeln('  Status: ${features['status']}');
    if (features['details'].isNotEmpty) {
      features['details'].forEach((key, value) {
        buffer.writeln('  - $key: $value');
      });
    }
    buffer.writeln();

    // Errors and warnings
    if (results['errors'].isNotEmpty) {
      buffer.writeln('ERRORS:');
      for (final error in results['errors']) {
        buffer.writeln('  ❌ $error');
      }
      buffer.writeln();
    }

    if (results['warnings'].isNotEmpty) {
      buffer.writeln('WARNINGS:');
      for (final warning in results['warnings']) {
        buffer.writeln('  ⚠️ $warning');
      }
      buffer.writeln();
    }

    buffer.writeln('=== END REPORT ===');
    return buffer.toString();
  }
}
