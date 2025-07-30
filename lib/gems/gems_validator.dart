// File: gems_validator.dart
// Production readiness validation for gems system

import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'gems_production_config.dart';
import 'gem_service.dart';
import 'gems_performance_optimizer.dart';

/// Comprehensive validator for gems system production readiness
class GemsValidator {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Validate complete gems system for production readiness
  static Future<Map<String, dynamic>> validateProductionReadiness() async {
    final results = <String, dynamic>{
      'isValid': false,
      'timestamp': DateTime.now().toIso8601String(),
      'checks': <String, dynamic>{},
      'errors': <String>[],
      'warnings': <String>[],
      'recommendations': <String>[],
    };

    try {
      GemsDebugUtils.log('Validator', 'Starting production readiness validation...');

      // Database connectivity and structure validation
      results['checks']['database'] = await _validateDatabase();
      
      // Gems system configuration validation
      results['checks']['configuration'] = await _validateConfiguration();
      
      // Service functionality validation
      results['checks']['service'] = await _validateGemService();
      
      // Performance validation
      results['checks']['performance'] = await _validatePerformance();
      
      // Security validation
      results['checks']['security'] = await _validateSecurity();
      
      // Data integrity validation
      results['checks']['dataIntegrity'] = await _validateDataIntegrity();

      // Aggregate results
      final allPassed = results['checks'].values.every((check) => 
          check is Map && check['passed'] == true);
      
      results['isValid'] = allPassed;
      
      if (allPassed) {
        GemsDebugUtils.logSuccess('Validator', 'Production readiness check completed successfully');
      } else {
        GemsDebugUtils.logWarning('Validator', 'Production readiness check found issues');
      }

    } catch (e) {
      results['errors'].add('Validation process failed: $e');
      GemsDebugUtils.logError('Validator', 'Validation failed: $e');
    }

    return results;
  }

  /// Validate database connectivity and table structure
  static Future<Map<String, dynamic>> _validateDatabase() async {
    final result = <String, dynamic>{
      'passed': false,
      'details': <String, dynamic>{},
      'issues': <String>[],
    };

    try {
      // Test basic connectivity
      await _supabase
          .from('gems')
          .select('count')
          .limit(1)
          .timeout(Duration(seconds: 10));
      
      result['details']['connectivity'] = 'Connected successfully';

      // Validate required tables exist
      final tables = ['gems', 'user_gems', 'gem_stats'];
      for (final table in tables) {
        try {
          await _supabase
              .from(table)
              .select('*')
              .limit(1)
              .timeout(Duration(seconds: 5));
          result['details']['table_$table'] = 'Available';
        } catch (e) {
          result['issues'].add('Table $table not accessible: $e');
        }
      }

      result['passed'] = result['issues'].isEmpty;

    } catch (e) {
      result['issues'].add('Database validation failed: $e');
    }

    return result;
  }

  /// Validate gems system configuration
  static Future<Map<String, dynamic>> _validateConfiguration() async {
    final result = <String, dynamic>{
      'passed': false,
      'details': <String, dynamic>{},
      'issues': <String>[],
    };

    try {
      // Validate configuration consistency
      final configValid = GemsConfigValidator.validateConfiguration();
      result['details']['configValidation'] = configValid;
      
      if (!configValid) {
        result['issues'].add('Configuration validation failed');
      }

      // Check production flags
      result['details']['isProduction'] = GemsProductionConfig.isProduction;
      result['details']['debugLogging'] = GemsProductionConfig.enableDebugLogging;
      
      // Validate rarity system
      final totalDropRate = GemsProductionConfig.rarityDropRates.values
          .fold(0.0, (sum, rate) => sum + rate);
      result['details']['dropRateSum'] = totalDropRate;
      
      if ((totalDropRate - 1.0).abs() > 0.01) {
        result['issues'].add('Drop rates sum to $totalDropRate, should be ~1.0');
      }

      // Check reasonable limits
      if (GemsProductionConfig.maxGemsPerUser <= 0) {
        result['issues'].add('Invalid maxGemsPerUser setting');
      }
      
      if (GemsProductionConfig.maxGemUnlocksPerDay <= 0) {
        result['issues'].add('Invalid maxGemUnlocksPerDay setting');
      }

      result['passed'] = result['issues'].isEmpty;

    } catch (e) {
      result['issues'].add('Configuration validation error: $e');
    }

    return result;
  }

  /// Validate gem service functionality
  static Future<Map<String, dynamic>> _validateGemService() async {
    final result = <String, dynamic>{
      'passed': false,
      'details': <String, dynamic>{},
      'issues': <String>[],
    };

    try {
      final gemService = GemService();
      
      // Test service initialization
      try {
        await gemService.initialize('test_user_${DateTime.now().millisecondsSinceEpoch}');
        result['details']['initialization'] = 'Success';
      } catch (e) {
        result['issues'].add('Service initialization failed: $e');
      }

      // Test loading all gems
      try {
        await gemService.initialize('test_user_validation');
        final allGems = gemService.allGems;
        result['details']['loadAllGems'] = '${allGems.length} gems loaded';
        
        if (allGems.isEmpty) {
          result['issues'].add('No gems found in database');
        }
      } catch (e) {
        result['issues'].add('Loading all gems failed: $e');
      }

      // Test streams
      try {
        await gemService.gemsStream.first
            .timeout(Duration(seconds: 5));
        result['details']['streams'] = 'Gems stream functional';
      } catch (e) {
        result['issues'].add('Gems stream test failed: $e');
      }

      result['passed'] = result['issues'].isEmpty;

    } catch (e) {
      result['issues'].add('Service validation error: $e');
    }

    return result;
  }

  /// Validate performance characteristics
  static Future<Map<String, dynamic>> _validatePerformance() async {
    final result = <String, dynamic>{
      'passed': false,
      'details': <String, dynamic>{},
      'issues': <String>[],
    };

    try {
      final stopwatch = Stopwatch()..start();
      
      // Test gem loading performance
      final gemService = GemService();
      await gemService.initialize('test_user_perf');
      
      stopwatch.stop();
      final loadTime = stopwatch.elapsedMilliseconds;
      result['details']['gemLoadTimeMs'] = loadTime;
      
      // Performance thresholds
      if (loadTime > 5000) {
        result['issues'].add('Gem loading too slow: ${loadTime}ms (should be < 5000ms)');
      } else if (loadTime > 2000) {
        result['details']['performance'] = 'Acceptable but could be optimized';
      } else {
        result['details']['performance'] = 'Good performance';
      }

      // Test cache functionality
      final optimizer = GemsPerformanceOptimizer();
      optimizer.initialize();
      
      final testGems = gemService.allGems;
      if (testGems.isNotEmpty) {
        optimizer.cacheUserGems('test_user', testGems);
        final cached = optimizer.getCachedUserGems('test_user');
        
        if (cached != null && cached.length == testGems.length) {
          result['details']['caching'] = 'Cache system functional';
        } else {
          result['issues'].add('Cache system not working properly');
        }
      }

      result['passed'] = result['issues'].isEmpty;

    } catch (e) {
      result['issues'].add('Performance validation error: $e');
    }

    return result;
  }

  /// Validate security configurations
  static Future<Map<String, dynamic>> _validateSecurity() async {
    final result = <String, dynamic>{
      'passed': false,
      'details': <String, dynamic>{},
      'issues': <String>[],
    };

    try {
      // Check security settings
      result['details']['unlockValidation'] = GemsProductionConfig.enableUnlockValidation;
      result['details']['rateLimiting'] = GemsProductionConfig.enableRateLimiting;
      
      if (!GemsProductionConfig.enableUnlockValidation) {
        result['issues'].add('Unlock validation is disabled');
      }
      
      if (!GemsProductionConfig.enableRateLimiting) {
        result['issues'].add('Rate limiting is disabled');
      }

      // Check unlock cooldown
      final cooldown = GemsProductionConfig.unlockCooldown.inSeconds;
      result['details']['unlockCooldownSeconds'] = cooldown;
      
      if (cooldown < 1) {
        result['issues'].add('Unlock cooldown too short');
      }

      // Check rate limits
      final maxUnlocksPerMinute = GemsProductionConfig.maxUnlocksPerMinute;
      result['details']['maxUnlocksPerMinute'] = maxUnlocksPerMinute;
      
      if (maxUnlocksPerMinute > 20) {
        result['issues'].add('Max unlocks per minute too high');
      }

      result['passed'] = result['issues'].isEmpty;

    } catch (e) {
      result['issues'].add('Security validation error: $e');
    }

    return result;
  }

  /// Validate data integrity
  static Future<Map<String, dynamic>> _validateDataIntegrity() async {
    final result = <String, dynamic>{
      'passed': false,
      'details': <String, dynamic>{},
      'issues': <String>[],
    };

    try {
      // Test gem data consistency
      final gemService = GemService();
      await gemService.initialize('test_user_data');
      final allGems = gemService.allGems;
      
      result['details']['totalGems'] = allGems.length;
      
      // Check for duplicate IDs
      final gemIds = allGems.map((g) => g.id).toList();
      final uniqueIds = gemIds.toSet();
      
      if (gemIds.length != uniqueIds.length) {
        result['issues'].add('Duplicate gem IDs found');
      } else {
        result['details']['uniqueIds'] = 'All gem IDs are unique';
      }

      // Check rarity distribution
      final rarityCount = <String, int>{};
      for (final gem in allGems) {
        rarityCount[gem.rarity] = (rarityCount[gem.rarity] ?? 0) + 1;
      }
      result['details']['rarityDistribution'] = rarityCount;

      // Validate gem properties
      int invalidGems = 0;
      for (final gem in allGems) {
        if (gem.name.isEmpty || gem.rarity.isEmpty || gem.description.isEmpty) {
          invalidGems++;
        }
      }
      
      if (invalidGems > 0) {
        result['issues'].add('$invalidGems gems have invalid properties');
      } else {
        result['details']['gemProperties'] = 'All gems have valid properties';
      }

      result['passed'] = result['issues'].isEmpty;

    } catch (e) {
      result['issues'].add('Data integrity validation error: $e');
    }

    return result;
  }

  /// Quick health check for monitoring
  static Future<bool> quickHealthCheck() async {
    try {
      // Quick database connectivity test
      await _supabase
          .from('gems')
          .select('count')
          .limit(1)
          .timeout(Duration(seconds: 5));
      
      // Quick service test
      final gemService = GemService();
      await gemService.initialize('health_check_user');
      final gems = gemService.allGems;
      
      return gems.isNotEmpty;
      
    } catch (e) {
      GemsDebugUtils.logError('Validator', 'Health check failed: $e');
      return false;
    }
  }

  /// Generate production readiness report
  static String generateReadinessReport(Map<String, dynamic> validationResults) {
    final buffer = StringBuffer();
    buffer.writeln('=== GEMS SYSTEM PRODUCTION READINESS REPORT ===');
    buffer.writeln('Timestamp: ${validationResults['timestamp']}');
    buffer.writeln('Overall Status: ${validationResults['isValid'] ? 'READY' : 'NOT READY'}');
    buffer.writeln();

    final checks = validationResults['checks'] as Map<String, dynamic>;
    for (final entry in checks.entries) {
      final checkName = entry.key;
      final checkResult = entry.value as Map<String, dynamic>;
      final passed = checkResult['passed'] ?? false;
      
      buffer.writeln('[$checkName]: ${passed ? 'PASS' : 'FAIL'}');
      
      if (checkResult['details'] != null) {
        final details = checkResult['details'] as Map<String, dynamic>;
        for (final detail in details.entries) {
          buffer.writeln('  - ${detail.key}: ${detail.value}');
        }
      }
      
      if (checkResult['issues'] != null) {
        final issues = checkResult['issues'] as List;
        for (final issue in issues) {
          buffer.writeln('  ⚠️ $issue');
        }
      }
      buffer.writeln();
    }

    final errors = validationResults['errors'] as List;
    if (errors.isNotEmpty) {
      buffer.writeln('ERRORS:');
      for (final error in errors) {
        buffer.writeln('  ❌ $error');
      }
      buffer.writeln();
    }

    final warnings = validationResults['warnings'] as List;
    if (warnings.isNotEmpty) {
      buffer.writeln('WARNINGS:');
      for (final warning in warnings) {
        buffer.writeln('  ⚠️ $warning');
      }
      buffer.writeln();
    }

    return buffer.toString();
  }
}
