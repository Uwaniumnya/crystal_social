import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'rewards_integration_helper.dart';
import 'dart:async';

/// Unified Rewards Initializer
/// Handles the proper initialization sequence for all rewards system components
class UnifiedRewardsInitializer {
  static UnifiedRewardsInitializer? _instance;
  static UnifiedRewardsInitializer get instance {
    _instance ??= UnifiedRewardsInitializer._internal();
    return _instance!;
  }

  UnifiedRewardsInitializer._internal();

  bool _isInitialized = false;
  String? _currentUserId;
  final List<String> _initializationLog = [];

  bool get isInitialized => _isInitialized;
  String? get currentUserId => _currentUserId;
  List<String> get initializationLog => List.unmodifiable(_initializationLog);

  /// Complete initialization sequence for rewards system
  Future<Map<String, dynamic>> initializeRewardsSystem({
    required String userId,
    bool forceReinitialization = false,
    bool syncShopItems = false,
  }) async {
    if (_isInitialized && _currentUserId == userId && !forceReinitialization) {
      return {
        'success': true,
        'message': 'Rewards system already initialized',
        'user_id': userId,
      };
    }

    _addToLog('🎯 Starting rewards system initialization for user: $userId');

    try {
      // Step 1: Initialize core rewards service
      _addToLog('📦 Initializing core rewards service...');
      final rewardsInitSuccess = await RewardsIntegrationHelper.initializeUserRewards(userId);
      
      if (!rewardsInitSuccess) {
        throw Exception('Failed to initialize core rewards service');
      }
      _addToLog('✅ Core rewards service initialized');

      // Step 2: Sync shop items if requested
      if (syncShopItems) {
        _addToLog('🛒 Syncing shop items to database...');
        final syncResult = await RewardsIntegrationHelper.syncShopItemsToDatabase();
        if (syncResult['success'] == true) {
          _addToLog('✅ Shop items synced: ${syncResult['created']} created, ${syncResult['updated']} updated');
        } else {
          _addToLog('⚠️ Shop sync warning: ${syncResult['error']}');
        }
      }

      // Step 3: Verify system health
      _addToLog('🔍 Verifying system health...');
      final healthCheck = await RewardsIntegrationHelper.getSystemHealth();
      
      if (healthCheck['status'] != 'healthy') {
        _addToLog('⚠️ System health check warning: ${healthCheck['status']}');
      } else {
        _addToLog('✅ System health verified');
      }

      // Step 4: Load initial user data
      _addToLog('📊 Loading comprehensive user status...');
      final userStatus = await RewardsIntegrationHelper.getComprehensiveUserStatus(userId);
      
      if (userStatus.containsKey('error')) {
        throw Exception('Failed to load user status: ${userStatus['error']}');
      }
      _addToLog('✅ User status loaded: Level ${userStatus['level']}, ${userStatus['coins']} coins');

      // Step 5: Check for achievement progress
      _addToLog('🏆 Checking achievement progress...');
      await RewardsIntegrationHelper.checkAchievementProgress(userId);
      _addToLog('✅ Achievement progress checked');

      // Step 6: Record login activity
      _addToLog('👋 Recording login activity...');
      final loginResult = await RewardsIntegrationHelper.recordLoginActivity(userId);
      
      if (loginResult['success'] == true) {
        final rewards = loginResult['rewards'];
        if (rewards != null && rewards.isNotEmpty) {
          _addToLog('✅ Login rewards granted: ${rewards.join(', ')}');
        } else {
          _addToLog('✅ Login activity recorded');
        }
      }

      // Mark as initialized
      _isInitialized = true;
      _currentUserId = userId;
      _addToLog('🎉 Rewards system initialization completed successfully');

      return {
        'success': true,
        'message': 'Rewards system initialized successfully',
        'user_id': userId,
        'user_status': userStatus,
        'health': healthCheck,
        'initialization_log': _initializationLog,
      };

    } catch (e) {
      _addToLog('❌ Initialization failed: $e');
      debugPrint('❌ Rewards system initialization failed: $e');
      
      return {
        'success': false,
        'error': e.toString(),
        'user_id': userId,
        'initialization_log': _initializationLog,
      };
    }
  }

  /// Reinitialize with a different user
  Future<Map<String, dynamic>> switchUser(String newUserId) async {
    _addToLog('🔄 Switching to new user: $newUserId');
    
    // Reset state
    _isInitialized = false;
    _currentUserId = null;
    
    // Initialize with new user
    return await initializeRewardsSystem(
      userId: newUserId,
      forceReinitialization: true,
    );
  }

  /// Perform maintenance tasks
  Future<Map<String, dynamic>> performMaintenance({
    bool syncShopItems = true,
    bool refreshUserData = true,
    bool checkAchievements = true,
  }) async {
    if (!_isInitialized || _currentUserId == null) {
      return {
        'success': false,
        'error': 'Rewards system not initialized',
      };
    }

    _addToLog('🔧 Starting maintenance tasks...');
    final maintenanceResults = <String, dynamic>{};

    try {
      if (syncShopItems) {
        _addToLog('🛒 Performing shop items sync...');
        final syncResult = await RewardsIntegrationHelper.syncShopItemsToDatabase();
        maintenanceResults['shop_sync'] = syncResult;
        _addToLog('✅ Shop sync completed');
      }

      if (refreshUserData) {
        _addToLog('🔄 Refreshing user data...');
        await RewardsIntegrationHelper.refreshAllUserData();
        maintenanceResults['data_refresh'] = {'success': true};
        _addToLog('✅ User data refreshed');
      }

      if (checkAchievements) {
        _addToLog('🏆 Checking achievements...');
        await RewardsIntegrationHelper.checkAchievementProgress(_currentUserId!);
        maintenanceResults['achievement_check'] = {'success': true};
        _addToLog('✅ Achievements checked');
      }

      _addToLog('🎉 Maintenance completed successfully');

      return {
        'success': true,
        'message': 'Maintenance completed successfully',
        'results': maintenanceResults,
        'maintenance_log': _initializationLog,
      };

    } catch (e) {
      _addToLog('❌ Maintenance failed: $e');
      
      return {
        'success': false,
        'error': e.toString(),
        'results': maintenanceResults,
        'maintenance_log': _initializationLog,
      };
    }
  }

  /// Get detailed system status
  Future<Map<String, dynamic>> getDetailedSystemStatus() async {
    try {
      final healthCheck = await RewardsIntegrationHelper.getSystemHealth();
      
      Map<String, dynamic> userStatus = {};
      if (_currentUserId != null) {
        userStatus = await RewardsIntegrationHelper.getComprehensiveUserStatus(_currentUserId!);
      }

      return {
        'initialized': _isInitialized,
        'current_user': _currentUserId,
        'health': healthCheck,
        'user_status': userStatus,
        'initialization_log': _initializationLog,
        'timestamp': DateTime.now().toIso8601String(),
      };

    } catch (e) {
      return {
        'error': e.toString(),
        'initialized': _isInitialized,
        'current_user': _currentUserId,
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Quick health check
  Future<bool> isSystemHealthy() async {
    try {
      if (!_isInitialized) return false;
      
      final health = await RewardsIntegrationHelper.getSystemHealth();
      return health['status'] == 'healthy';
      
    } catch (e) {
      return false;
    }
  }

  /// Reset the initialization state (for testing or troubleshooting)
  void resetInitializationState() {
    _isInitialized = false;
    _currentUserId = null;
    _initializationLog.clear();
    debugPrint('🔄 Rewards system initialization state reset');
  }

  /// Get initialization summary
  Map<String, dynamic> getInitializationSummary() {
    return {
      'initialized': _isInitialized,
      'current_user': _currentUserId,
      'log_entries': _initializationLog.length,
      'last_log_entry': _initializationLog.isNotEmpty ? _initializationLog.last : null,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  void _addToLog(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    final logEntry = '[$timestamp] $message';
    _initializationLog.add(logEntry);
    debugPrint(logEntry);
    
    // Keep log size manageable
    if (_initializationLog.length > 100) {
      _initializationLog.removeAt(0);
    }
  }
}
