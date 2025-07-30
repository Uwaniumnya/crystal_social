# Unified Rewards System Integration - Complete Documentation

This document provides a comprehensive guide to the integrated rewards system that smoothly coordinates all rewards-related functionality.

## Overview

The unified rewards system consists of several integrated components working together seamlessly:

### Core Integration Components

- **RewardsIntegrationHelper** - Easy-to-use static methods for common operations
- **UnifiedRewardsInitializer** - Proper initialization sequence coordinator  
- **RewardsConfig** - Centralized configuration and constants
- **Core Services** - RewardsService, RewardsManager, AuraService, ShopItemSync

### Key Benefits

✅ **Unified API** - Single entry point for all rewards operations  
✅ **Automatic Error Handling** - Built-in error management and user feedback  
✅ **Consistent Logging** - Comprehensive debugging and monitoring  
✅ **Performance Optimized** - Coordinated caching and efficient database usage  
✅ **Health Monitoring** - System status checking and maintenance  
✅ **Easy Integration** - Drop-in replacement for existing reward code  

## Quick Start Guide

### 1. Initialize the Rewards System

```dart
import 'package:crystal_social/rewards/rewards.dart';

// Initialize for a user (typically in app startup or login)
final result = await UnifiedRewardsInitializer.instance.initializeRewardsSystem(
  userId: 'user_123',
  syncShopItems: true, // Optional: sync shop items on init
);

if (result['success']) {
  print('✅ Rewards system initialized successfully!');
  print('User status: ${result['user_status']}');
} else {
  print('❌ Initialization failed: ${result['error']}');
}
```

### 2. Purchase Items (Complete Flow)

```dart
// Complete purchase flow with automatic error handling
final purchaseResult = await RewardsIntegrationHelper.completePurchaseFlow(
  item: shopItem, // Map with item details (id, name, price, etc.)
  userId: 'user_123',
  context: context, // BuildContext for UI feedback
);

if (purchaseResult['success']) {
  // Purchase successful - UI will show success message
  print('Purchase successful: ${purchaseResult['message']}');
} else {
  // Purchase failed - UI will show error message  
  print('Purchase failed: ${purchaseResult['error']}');
}
```

### 3. Manage Auras

```dart
// Equip an aura with automatic validation
final auraResult = await RewardsIntegrationHelper.manageAuraFlow(
  userId: 'user_123',
  auraColor: 'golden_radiance',
  action: 'equip', // or 'unequip'
);

// Get currently equipped aura
final currentAura = await RewardsIntegrationHelper.getCurrentEquippedAura('user_123');
print('Currently equipped: $currentAura');
```

### 4. Track User Activities

```dart
// Award coins for activities (with automatic achievement checking)
await RewardsIntegrationHelper.awardActivityCoins(
  userId: 'user_123',
  activityType: 'message_sent',
  context: context,
  customAmount: 10, // Optional custom amount
);

// Track general activities with points
await RewardsIntegrationHelper.trackActivity(
  userId: 'user_123',
  activityType: 'post_created',
  context: context,
  customPoints: 50,
);

// Record message activity (includes achievement progress)
await RewardsIntegrationHelper.recordMessageActivity('user_123', context);

// Record login activity (includes daily bonuses)
final loginResult = await RewardsIntegrationHelper.recordLoginActivity('user_123');
```

### 5. Get Comprehensive User Status

```dart
final userStatus = await RewardsIntegrationHelper.getComprehensiveUserStatus('user_123');

print('💰 Coins: ${userStatus['coins']}');
print('🎯 Level: ${userStatus['level']}');
print('🏆 Achievements: ${userStatus['achievements_unlocked']}/${userStatus['total_achievements']}');
print('✨ Equipped Aura: ${userStatus['equipped_aura']}');
print('📦 Total Items: ${userStatus['total_items_owned']}');
```

## Advanced Features

### System Health Monitoring

```dart
// Quick health check
final isHealthy = await UnifiedRewardsInitializer.instance.isSystemHealthy();

// Detailed system status
final status = await UnifiedRewardsInitializer.instance.getDetailedSystemStatus();
print('System Status: ${status['health']['status']}');
print('Initialization Log: ${status['initialization_log']}');
```

### Maintenance Operations

```dart
// Perform comprehensive system maintenance
final maintenanceResult = await UnifiedRewardsInitializer.instance.performMaintenance(
  syncShopItems: true,     // Update shop database
  refreshUserData: true,   // Refresh all user data
  checkAchievements: true, // Check for new achievements
);

if (maintenanceResult['success']) {
  print('🔧 Maintenance completed successfully');
  print('Results: ${maintenanceResult['results']}');
} else {
  print('❌ Maintenance failed: ${maintenanceResult['error']}');
}
```

### User Switching

```dart
// Switch to a different user (useful for multi-user scenarios)
final switchResult = await UnifiedRewardsInitializer.instance.switchUser('new_user_456');

if (switchResult['success']) {
  print('👤 Successfully switched to new user');
} else {
  print('❌ User switch failed: ${switchResult['error']}');
}
```

### Shop Item Synchronization

```dart
// Sync shop items to database (admin/maintenance operation)
final syncResult = await RewardsIntegrationHelper.syncShopItemsToDatabase();

print('🛒 Shop Sync Results:');
print('  Created: ${syncResult['created']}');
print('  Updated: ${syncResult['updated']}');
print('  Skipped: ${syncResult['skipped']}');
print('  Errors: ${syncResult['errors']}');
```

## Configuration System

### Using RewardsConfig

```dart
import 'package:crystal_social/rewards/rewards_config.dart';

// Access predefined rewards amounts
int dailyBonus = RewardsConfig.dailyLoginBonus; // 50 coins
int messageReward = RewardsConfig.messageReward; // 5 coins

// Activity-specific rewards
int postReward = RewardsConfig.activityRewards['post_created']!; // 10 points
int likeReward = RewardsConfig.activityRewards['like_given']!; // 1 point

// Level requirements
int level5Requirement = RewardsConfig.levelRequirements[5]!; // 1000 XP

// Cache settings
Duration cacheTime = RewardsConfig.cacheExpiration; // 5 minutes
int maxCacheSize = RewardsConfig.maxCacheSize; // 1000 entries

// Shop categories
String auraCategory = RewardsConfig.shopCategories[2]!; // "Auras"
String petCategory = RewardsConfig.shopCategories[3]!; // "Pets"
```

### Error and Success Messages

```dart
// Use predefined messages for consistency
String insufficientFundsMsg = RewardsConfig.errorMessages['insufficient_funds']!;
String levelRequirementMsg = RewardsConfig.errorMessages['level_requirement']!;

String purchaseSuccessMsg = RewardsConfig.successMessages['purchase_complete']!;
String achievementMsg = RewardsConfig.successMessages['achievement_unlocked']!;
```

### Enums for Type Safety

```dart
// Use typed enums for better code safety
CurrencyType coinType = CurrencyType.coins; // 💰 Coins
ItemRarity legendary = ItemRarity.legendary; // 3.0x multiplier
AchievementCategory social = AchievementCategory.social;
```

## Integration Patterns

### Main App Initialization

```dart
// In your main.dart or app initialization
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FutureBuilder<Map<String, dynamic>>(
        future: _initializeApp(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasData && snapshot.data!['success']) {
              return HomeScreen();
            } else {
              return ErrorScreen(error: snapshot.data?['error'] ?? 'Unknown error');
            }
          }
          return LoadingScreen();
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _initializeApp() async {
    try {
      // Initialize Supabase first
      await Supabase.initialize(
        url: 'https://zdsjtjbzhiejvpuahnlk.supabase.co',
        anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inpkc2p0amJ6aGllanZwdWFobmxrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM4MjAyMzYsImV4cCI6MjA2OTM5NjIzNn0.CSPzbngxKJHrHD8oNMFaYzvKXzNzMENFtaWu9Vy2rV0',
      );
      
      // Get current user
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        return {'success': false, 'error': 'No user logged in'};
      }
      
      // Initialize rewards system
      return await UnifiedRewardsInitializer.instance.initializeRewardsSystem(
        userId: user.id,
        syncShopItems: false, // Don't sync on every app start
      );
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
```

### Login Flow Integration

```dart
// After successful user authentication
Future<void> handleUserLogin(String userId) async {
  try {
    // Initialize/switch rewards system for the user
    final result = await UnifiedRewardsInitializer.instance.initializeRewardsSystem(
      userId: userId,
      forceReinitialization: true,
    );
    
    if (result['success']) {
      // Show login rewards if any
      final userStatus = result['user_status'];
      _showWelcomeMessage(userStatus);
    } else {
      print('⚠️ Rewards initialization warning: ${result['error']}');
      // App can continue without rewards functionality
    }
  } catch (e) {
    print('❌ Login rewards error: $e');
    // Handle gracefully - don't block user login
  }
}

void _showWelcomeMessage(Map<String, dynamic> userStatus) {
  final level = userStatus['level'] ?? 1;
  final coins = userStatus['coins'] ?? 0;
  final achievementCount = userStatus['achievements_unlocked'] ?? 0;
  
  print('🎉 Welcome back! Level $level • $coins coins • $achievementCount achievements');
}
```

### Shopping Screen Integration

```dart
class ShopScreen extends StatefulWidget {
  @override
  _ShopScreenState createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  late Future<Map<String, dynamic>> _userStatusFuture;
  
  @override
  void initState() {
    super.initState();
    _loadUserStatus();
  }
  
  void _loadUserStatus() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _userStatusFuture = RewardsIntegrationHelper.getComprehensiveUserStatus(user.id);
    }
  }
  
  Future<void> _handlePurchase(Map<String, dynamic> item) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );
    
    try {
      final result = await RewardsIntegrationHelper.completePurchaseFlow(
        item: item,
        userId: user.id,
        context: context,
      );
      
      // Hide loading indicator
      Navigator.of(context).pop();
      
      if (result['success']) {
        // Show success feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(RewardsConfig.successMessages['purchase_complete']!),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'View Item',
              onPressed: () => _navigateToInventory(),
            ),
          ),
        );
        
        // Refresh user status and shop
        setState(() {
          _loadUserStatus();
        });
      } else {
        // Show error feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Purchase failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Hide loading indicator
      Navigator.of(context).pop();
      
      // Show generic error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An unexpected error occurred'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _navigateToInventory() {
    // Navigate to inventory screen
  }
}
```

### Activity Tracking Integration

```dart
class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  Future<void> _sendMessage(String messageText) async {
    try {
      // Send the actual message first
      await _sendMessageToServer(messageText);
      
      // Track the messaging activity for rewards (non-blocking)
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        // Don't await - let it run in background
        RewardsIntegrationHelper.recordMessageActivity(user.id, context).catchError((e) {
          print('⚠️ Message reward tracking failed: $e');
          // Don't show error to user - message was sent successfully
        });
      }
    } catch (e) {
      // Handle message sending error
      print('❌ Message send failed: $e');
      _showErrorSnackBar('Failed to send message');
    }
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

### Aura Management Integration

```dart
class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _currentAura;
  
  @override
  void initState() {
    super.initState();
    _loadCurrentAura();
  }
  
  Future<void> _loadCurrentAura() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final aura = await RewardsIntegrationHelper.getCurrentEquippedAura(user.id);
        setState(() {
          _currentAura = aura;
        });
      } catch (e) {
        print('⚠️ Failed to load current aura: $e');
      }
    }
  }
  
  Future<void> _equipAura(String auraColor) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    
    try {
      final result = await RewardsIntegrationHelper.manageAuraFlow(
        userId: user.id,
        auraColor: auraColor,
        action: 'equip',
      );
      
      if (result['success']) {
        setState(() {
          _currentAura = auraColor;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(RewardsConfig.successMessages['aura_equipped']!),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _showErrorSnackBar(result['error'] ?? 'Failed to equip aura');
      }
    } catch (e) {
      _showErrorSnackBar('An unexpected error occurred');
    }
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

## Error Handling Best Practices

### Graceful Degradation

```dart
// Always check system health before critical operations
Future<void> performCriticalRewardsOperation() async {
  // Check if system is healthy
  final isHealthy = await UnifiedRewardsInitializer.instance.isSystemHealthy();
  
  if (!isHealthy) {
    // Try to reinitialize
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      print('🔄 Attempting to reinitialize rewards system...');
      final result = await UnifiedRewardsInitializer.instance.initializeRewardsSystem(
        userId: user.id,
        forceReinitialization: true,
      );
      
      if (!result['success']) {
        print('❌ Rewards system unavailable - continuing without rewards');
        return; // Gracefully degrade
      }
    } else {
      print('❌ No user available - skipping rewards operation');
      return;
    }
  }
  
  // System is healthy - proceed with operation
  // ...
}
```

### Comprehensive Error Logging

```dart
Future<void> performRewardsOperationWithLogging() async {
  try {
    final result = await RewardsIntegrationHelper.completePurchaseFlow(
      item: item,
      userId: userId,
      context: context,
    );
    
    if (!result['success']) {
      // Log the business logic error
      _logRewardsError('Purchase failed', {
        'error': result['error'],
        'item_id': item['id'],
        'user_id': userId,
        'error_code': result['code'],
      });
    }
  } catch (e, stackTrace) {
    // Log unexpected technical errors
    _logRewardsError('Unexpected rewards error', {
      'error': e.toString(),
      'stack_trace': stackTrace.toString(),
      'operation': 'purchase_flow',
    });
  }
}

void _logRewardsError(String message, Map<String, dynamic> details) {
  // In development
  debugPrint('🚨 $message: $details');
  
  // In production, send to your logging service
  // FirebaseCrashlytics.instance.recordError(message, null, fatal: false);
  // or your preferred logging solution
}
```

### User-Friendly Error Messages

```dart
String _getUserFriendlyErrorMessage(String errorCode) {
  switch (errorCode) {
    case 'INSUFFICIENT_FUNDS':
      return 'You don\'t have enough coins for this purchase. Complete activities to earn more!';
    case 'LEVEL_REQUIREMENT':
      return 'This item requires a higher level. Keep playing to level up!';
    case 'ALREADY_OWNED':
      return 'You already own this item. Check your inventory!';
    case 'NETWORK_ERROR':
      return 'Connection issue. Please check your internet and try again.';
    case 'SYSTEM_ERROR':
      return 'Something went wrong. Please try again in a moment.';
    default:
      return 'An unexpected error occurred. Please try again.';
  }
}
```

## Performance Considerations

### Caching Strategy

The integrated rewards system implements intelligent caching:

```dart
// Automatic caching with configurable expiration
Duration cacheExpiration = RewardsConfig.cacheExpiration; // 5 minutes
int maxCacheSize = RewardsConfig.maxCacheSize; // 1000 entries

// Cache is automatically managed:
// - User rewards cached for quick access
// - Shop items cached to reduce database calls  
// - Achievement progress cached during sessions
// - Automatic cleanup of expired entries
```

### Initialization Performance

```dart
// Initialize once per session for optimal performance
await UnifiedRewardsInitializer.instance.initializeRewardsSystem(
  userId: userId,
  forceReinitialization: false, // Default - only reinit if needed
  syncShopItems: false, // Don't sync every time for better performance
);

// For background initialization (better UX)
Future<void> preInitializeRewards(String userId) async {
  // Start initialization in background without waiting
  UnifiedRewardsInitializer.instance.initializeRewardsSystem(
    userId: userId,
  ).catchError((e) {
    print('Background rewards init failed: $e');
  });
}
```

### Batch Operations

```dart
// The system automatically batches related operations for efficiency:
// - Multiple achievement checks are batched
// - Shop item queries use pagination
// - User data refreshes are coordinated
// - Cache updates are batched when possible
```

## Troubleshooting Guide

### Common Issues and Solutions

#### 1. "Rewards system not initialized"
```dart
// Check initialization status
final summary = UnifiedRewardsInitializer.instance.getInitializationSummary();
print('Initialized: ${summary['initialized']}');
print('Current User: ${summary['current_user']}');

// Reinitialize if needed
if (!summary['initialized']) {
  await UnifiedRewardsInitializer.instance.initializeRewardsSystem(
    userId: currentUserId,
    forceReinitialization: true,
  );
}
```

#### 2. "Purchase failed - insufficient funds"
```dart
// Check user balance before purchase
final userStatus = await RewardsIntegrationHelper.getComprehensiveUserStatus(userId);
final userCoins = userStatus['coins'] ?? 0;
final itemPrice = item['price'] ?? 0;

if (userCoins < itemPrice) {
  // Show specific message about how to earn more coins
  _showInsufficientFundsDialog(itemPrice - userCoins);
}
```

#### 3. "System health check failed"
```dart
// Get detailed health information
final health = await RewardsIntegrationHelper.getSystemHealth();
print('Health Status: ${health['status']}');
print('Details: ${health['details']}');

// Check specific components
if (health['details']['rewards_service_error'] != null) {
  print('RewardsService Error: ${health['details']['rewards_service_error']}');
}
```

### Debug Information

```dart
// Get comprehensive debug information
Future<void> printDebugInfo() async {
  // System status
  final status = await UnifiedRewardsInitializer.instance.getDetailedSystemStatus();
  print('=== REWARDS SYSTEM DEBUG ===');
  print('Initialized: ${status['initialized']}');
  print('Current User: ${status['current_user']}');
  print('Health: ${status['health']['status']}');
  
  // Initialization logs
  print('\\n=== INITIALIZATION LOG ===');
  for (final logEntry in status['initialization_log']) {
    print(logEntry);
  }
  
  // User status (if available)
  if (status['user_status'] != null) {
    print('\\n=== USER STATUS ===');
    final user = status['user_status'];
    print('Level: ${user['level']}');
    print('Coins: ${user['coins']}');
    print('Items: ${user['total_items_owned']}');
    print('Achievements: ${user['achievements_unlocked']}/${user['total_achievements']}');
  }
}
```

## Migration from Individual Services

### Before (Individual Service Usage)
```dart
// Old approach - manual coordination required
final rewardsService = RewardsService.instance;
await rewardsService.initialize(userId);

final supabase = Supabase.instance.client;
final rewardsManager = RewardsManager(supabase);
final result = await rewardsManager.purchaseItem(userId, itemId, context);

final auraService = AuraService(supabase);
await auraService.updateEquippedAura(userId, auraColor);

// Manual error handling, no coordination between services
```

### After (Unified Integration)
```dart
// New approach - automatic coordination and error handling
await UnifiedRewardsInitializer.instance.initializeRewardsSystem(userId: userId);

final result = await RewardsIntegrationHelper.completePurchaseFlow(
  item: item,
  userId: userId,
  context: context,
);

await RewardsIntegrationHelper.manageAuraFlow(
  userId: userId,
  auraColor: auraColor,
  action: 'equip',
);

// Automatic error handling, logging, coordination, and health monitoring
```

### Migration Benefits

✅ **Reduced Code Complexity** - Single API instead of multiple service calls  
✅ **Automatic Error Handling** - Built-in user feedback and error recovery  
✅ **Better Performance** - Coordinated caching and database access  
✅ **Health Monitoring** - Automatic system status checking  
✅ **Consistent Logging** - Comprehensive debugging information  
✅ **Type Safety** - Enhanced with configuration enums and constants  

## Support and Troubleshooting

For issues with the unified rewards system:

1. **Check System Health** - Use the built-in health monitoring
2. **Review Initialization Logs** - Check the detailed status and logs
3. **Verify Configuration** - Ensure all required setup is complete
4. **Test Individual Components** - Use helper methods for isolated testing
5. **Monitor Performance** - Use the built-in performance monitoring

The unified rewards system provides comprehensive functionality while maintaining simplicity and reliability. All components work together seamlessly to provide a smooth user experience with robust error handling and performance optimization.
