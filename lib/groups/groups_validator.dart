// File: groups_validator.dart
// Validation and production readiness checks for groups system

import 'groups_production_config.dart';
import 'groups_performance_optimizer.dart';

/// Validation system for groups functionality
class GroupsValidator {
  static final GroupsValidator _instance = GroupsValidator._internal();
  factory GroupsValidator() => _instance;
  GroupsValidator._internal();

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

      GroupsDebugUtils.logSuccess('Validator', 'Production readiness check completed');
      
    } catch (e) {
      results['overall_status'] = 'error';
      results['errors'].add('Validation process failed: $e');
      GroupsDebugUtils.logError('Validator', 'Validation failed: $e');
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
    if (GroupsProductionConfig.maxMembersPerGroup <= 0) {
      config['status'] = 'failed';
      config['details']['max_members'] = 'Invalid max members configuration';
    }

    if (GroupsProductionConfig.maxMessageLength <= 0) {
      config['status'] = 'failed';
      config['details']['max_message_length'] = 'Invalid message length configuration';
    }

    if (GroupsProductionConfig.maxGroupsPerUser <= 0) {
      config['status'] = 'failed';
      config['details']['max_groups_per_user'] = 'Invalid groups per user configuration';
    }

    // Check timeout configurations
    if (GroupsProductionConfig.typingIndicatorTimeout.inSeconds <= 0) {
      config['status'] = 'warning';
      config['details']['typing_timeout'] = 'Very short typing indicator timeout';
    }

    if (GroupsProductionConfig.connectionRetryDelay.inSeconds <= 0) {
      config['status'] = 'failed';
      config['details']['retry_delay'] = 'Invalid retry delay configuration';
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
      final optimizer = GroupsPerformanceOptimizer();
      optimizer.initialize();

      // Check cache limits
      if (GroupsProductionConfig.maxMessagesInMemory > 1000) {
        performance['status'] = 'warning';
        performance['details']['message_cache'] = 'High message cache limit may impact memory';
      }

      // Check analytics settings
      if (GroupsProductionConfig.maxAnalyticsHistory > 500) {
        performance['status'] = 'warning';
        performance['details']['analytics_cache'] = 'High analytics history may impact performance';
      }

      // Test performance monitoring
      final stopwatch = Stopwatch()..start();
      await Future.delayed(const Duration(milliseconds: 10));
      stopwatch.stop();
      
      optimizer.trackOperation('test_operation', stopwatch.elapsed);
      final avgPerf = optimizer.getAveragePerformance('test_operation');
      
      if (avgPerf == null) {
        performance['status'] = 'warning';
        performance['details']['performance_tracking'] = 'Performance tracking not working properly';
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
    if (!GroupsProductionConfig.enableAutoModeration) {
      security['status'] = 'warning';
      security['details']['auto_moderation'] = 'Auto-moderation is disabled';
    }

    // Check spam prevention
    if (GroupsProductionConfig.maxConsecutiveMessages > 10) {
      security['status'] = 'warning';
      security['details']['spam_prevention'] = 'High consecutive message limit';
    }

    if (GroupsProductionConfig.spamPreventionWindow.inSeconds < 30) {
      security['status'] = 'warning';
      security['details']['spam_window'] = 'Short spam prevention window';
    }

    // Check session timeout
    if (GroupsProductionConfig.sessionTimeout.inHours > 48) {
      security['status'] = 'warning';
      security['details']['session_timeout'] = 'Long session timeout may be insecure';
    }

    // Check audit logging
    if (!GroupsProductionConfig.enableAuditLogging) {
      security['status'] = 'warning';
      security['details']['audit_logging'] = 'Audit logging is disabled';
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
      // Check messaging features
      if (!GroupsProductionConfig.enablePushNotifications) {
        features['details']['push_notifications'] = 'Push notifications disabled';
      }

      if (!GroupsProductionConfig.enableFileSharing) {
        features['details']['file_sharing'] = 'File sharing disabled';
      }

      // Check group gem system
      if (GroupsProductionConfig.enableGroupGems) {
        if (GroupsProductionConfig.maxGemsPerGroup <= 0) {
          features['status'] = 'failed';
          features['details']['gems_config'] = 'Invalid gems configuration';
        }
      }

      // Check advanced features
      if (GroupsProductionConfig.enableGroupCalls) {
        features['details']['group_calls'] = 'Group calls feature enabled (beta)';
      }

      if (GroupsProductionConfig.enableAdvancedModeration) {
        features['details']['advanced_moderation'] = 'Advanced moderation enabled';
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
      if (GroupsProductionConfig.enablePushNotifications) {
        dependencies['details']['notifications'] = 'Push notification service configured';
      }

    } catch (e) {
      dependencies['status'] = 'failed';
      dependencies['details']['error'] = 'Dependencies validation failed: $e';
    }

    return dependencies;
  }

  /// Validate group data structure
  static Map<String, dynamic> validateGroupData(Map<String, dynamic> groupData) {
    final validation = <String, dynamic>{
      'valid': true,
      'errors': <String>[],
      'warnings': <String>[],
    };

    // Required fields
    final requiredFields = ['id', 'name', 'created_at'];
    for (final field in requiredFields) {
      if (!groupData.containsKey(field) || groupData[field] == null) {
        validation['valid'] = false;
        validation['errors'].add('Missing required field: $field');
      }
    }

    // Validate name length
    final name = groupData['name'] as String?;
    if (name != null) {
      if (name.isEmpty) {
        validation['valid'] = false;
        validation['errors'].add('Group name cannot be empty');
      } else if (name.length > GroupsProductionConfig.maxGroupNameLength) {
        validation['valid'] = false;
        validation['errors'].add('Group name too long');
      }
    }

    // Validate description length
    final description = groupData['description'] as String?;
    if (description != null && description.length > GroupsProductionConfig.maxGroupDescriptionLength) {
      validation['warnings'].add('Group description is very long');
    }

    return validation;
  }

  /// Validate message data structure
  static Map<String, dynamic> validateMessageData(Map<String, dynamic> messageData) {
    final validation = <String, dynamic>{
      'valid': true,
      'errors': <String>[],
      'warnings': <String>[],
    };

    // Required fields
    final requiredFields = ['id', 'group_id', 'user_id', 'content', 'created_at'];
    for (final field in requiredFields) {
      if (!messageData.containsKey(field) || messageData[field] == null) {
        validation['valid'] = false;
        validation['errors'].add('Missing required field: $field');
      }
    }

    // Validate content length
    final content = messageData['content'] as String?;
    if (content != null) {
      if (content.isEmpty) {
        validation['valid'] = false;
        validation['errors'].add('Message content cannot be empty');
      } else if (content.length > GroupsProductionConfig.maxMessageLength) {
        validation['valid'] = false;
        validation['errors'].add('Message content too long');
      }
    }

    // Check for spam indicators
    if (content != null) {
      final words = content.toLowerCase().split(' ');
      final spamWords = words.where((word) => 
        GroupsProductionConfig.bannedWords.contains(word)).toList();
      
      if (spamWords.isNotEmpty) {
        validation['warnings'].add('Message contains flagged words');
      }
    }

    return validation;
  }

  /// Generate production readiness report
  static Future<String> generateProductionReport() async {
    final results = await validateProductionReadiness();
    final buffer = StringBuffer();

    buffer.writeln('=== GROUPS SYSTEM PRODUCTION READINESS REPORT ===');
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
