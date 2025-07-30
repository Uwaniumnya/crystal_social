# Rewards System Integration

This document explains how the rewards system has been integrated to work smoothly across all components.

## Overview

The rewards system has been completely refactored to provide a centralized, type-safe, and efficient way to handle all reward-related functionality including:

- **Shop Management**: Browse and purchase items
- **Inventory System**: Manage owned items and equipment
- **Achievement Tracking**: Monitor progress and unlock rewards
- **User Statistics**: Track spending, purchases, and activity
- **Aura System**: Special visual effects management
- **Booster Packs**: Random item generation
- **Daily Rewards**: Login bonuses and streaks

## Architecture

### Core Components

1. **RewardsService** (`rewards_service.dart`)
   - Centralized service managing all rewards functionality
   - Singleton pattern for consistent state across the app
   - Real-time data synchronization with streams
   - Comprehensive error handling and caching

2. **RewardsProvider** (`rewards_provider.dart`)
   - Flutter Provider wrapper for state management
   - Context extensions for easy access
   - Pre-built UI components (CoinBalanceWidget, LevelProgressWidget)
   - RewardsMixin for stateful widgets

3. **UnifiedRewardsScreen** (`unified_rewards_screen.dart`)
   - Main interface combining all reward features
   - Tabbed navigation between Shop, Inventory, Achievements, and Stats
   - Integrated daily reward system
   - Responsive design with animations

### Integration Files

- **rewards_integration.dart**: Main export file with constants and helpers
- **rewards_example.dart**: Complete example implementation
- **rewards_provider.dart**: Provider and UI components

## How to Use

### 1. Basic Setup

Wrap your app or specific sections with the RewardsProvider:

```dart
import 'package:crystal_social/rewards/rewards_integration.dart';

// In your app
RewardsProvider(
  userId: currentUserId,
  child: YourMainWidget(),
)
```

### 2. Main Rewards Interface

Use the UnifiedRewardsScreen as your primary rewards interface:

```dart
UnifiedRewardsScreen(userId: currentUserId)
```

### 3. Accessing Rewards Data

Use context extensions for easy access:

```dart
// Get rewards service (doesn't rebuild on changes)
final rewards = context.rewards;

// Watch rewards service (rebuilds on changes)
final rewards = context.watchRewards;

// Access specific data
final userCoins = rewards.userRewards['coins'];
final userLevel = rewards.userRewards['level'];
final inventory = rewards.userInventory;
```

### 4. Using Pre-built Components

```dart
// Show current coin balance
CoinBalanceWidget()

// Show level and progress
LevelProgressWidget(
  showProgressBar: true,
  progressColor: Colors.blue,
)

// Reactive builder for custom UI
RewardsBuilder(
  builder: (context, rewards) {
    return Text('You have ${rewards.userRewards['coins']} coins');
  },
  loadingWidget: CircularProgressIndicator(),
  errorWidget: Text('Failed to load'),
)
```

### 5. Implementing Rewards Functionality

Use the RewardsMixin for easy integration in stateful widgets:

```dart
class MyShopWidget extends StatefulWidget {
  @override
  State<MyShopWidget> createState() => _MyShopWidgetState();
}

class _MyShopWidgetState extends State<MyShopWidget> with RewardsMixin {
  
  Future<void> purchaseItem(Map<String, dynamic> item) async {
    final success = await rewardsService.purchaseItem(item, context);
    
    if (success) {
      showPurchaseSuccess(item['name']);
    } else {
      showPurchaseError('Not enough coins');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return RewardsBuilder(
      builder: (context, rewards) {
        return ListView.builder(
          itemCount: rewards.shopItems.length,
          itemBuilder: (context, index) {
            final item = rewards.shopItems[index];
            return ListTile(
              title: Text(item['name']),
              subtitle: Text('${item['price']} coins'),
              trailing: ElevatedButton(
                onPressed: rewards.canAffordItem(item) 
                  ? () => purchaseItem(item)
                  : null,
                child: Text('Buy'),
              ),
            );
          },
        );
      },
    );
  }
}
```

## Key Features

### Centralized State Management
- Single source of truth for all rewards data
- Automatic synchronization across components
- Efficient caching and data loading

### Type Safety
- Comprehensive error handling
- Null safety throughout
- Clear API contracts

### Performance Optimized
- Lazy loading and pagination
- Smart caching strategies
- Minimal unnecessary rebuilds

### User Experience
- Smooth animations and transitions
- Haptic feedback
- Clear success/error messaging
- Offline capability with cached data

## API Reference

### RewardsService Methods

```dart
// Initialization
await rewardsService.initialize(userId);
await rewardsService.refresh();

// Purchasing
final success = await rewardsService.purchaseItem(item, context);
final items = await rewardsService.openBoosterPack(boosterPack);

// Equipment
await rewardsService.equipAura(auraColor);

// Daily rewards
final result = await rewardsService.claimDailyReward();

// Achievements
await rewardsService.awardAchievement(achievementId);

// Data access
final coins = rewardsService.userRewards['coins'];
final inventory = rewardsService.userInventory;
final shopItems = rewardsService.getFilteredShopItems(
  categoryId: RewardsConstants.CATEGORY_AURA,
  searchQuery: 'rainbow',
  minPrice: 100,
  maxPrice: 500,
);
```

### Constants

```dart
// Categories
RewardsConstants.CATEGORY_AURA
RewardsConstants.CATEGORY_BACKGROUND
RewardsConstants.CATEGORY_PET
RewardsConstants.CATEGORY_BOOSTER

// Rarities
RewardsConstants.RARITY_COMMON
RewardsConstants.RARITY_RARE
RewardsConstants.RARITY_LEGENDARY
```

### Helper Functions

```dart
// Get rarity color
final color = RewardsHelper.getRarityColor('legendary');

// Get category icon
final icon = RewardsHelper.getCategoryIcon(RewardsConstants.CATEGORY_AURA);

// Format currency
final formatted = RewardsHelper.formatCurrency(1500); // "1.5K"

// Level calculations
final level = RewardsHelper.calculateLevel(points);
final progress = RewardsHelper.calculateLevelProgress(points, level);
```

## Migration Guide

If you're updating from the old system:

1. Replace individual imports with `import 'rewards_integration.dart'`
2. Wrap your widgets with `RewardsProvider`
3. Replace `RewardsManager` usage with `RewardsService.instance`
4. Use context extensions instead of passing services around
5. Replace custom UI with pre-built components where possible

## Best Practices

1. **Always initialize**: Call `rewardsService.initialize(userId)` before using other methods
2. **Use providers**: Wrap relevant sections with `RewardsProvider` for automatic state management
3. **Handle errors**: Use try-catch blocks and display user-friendly error messages
4. **Cache efficiently**: The service handles caching automatically, avoid manual cache management
5. **Use mixins**: Implement `RewardsMixin` for consistent patterns across widgets
6. **Reactive UI**: Use `RewardsBuilder` for UI that needs to update with rewards data

## Troubleshooting

### Common Issues

1. **Service not initialized**: Ensure `RewardsProvider` wraps your widget tree
2. **Data not updating**: Use `context.watchRewards` instead of `context.rewards` for reactive updates
3. **Purchase failures**: Check user balance and item availability before purchasing
4. **Performance issues**: Use `RewardsBuilder` with appropriate loading states

### Debug Information

Enable debug prints by setting:
```dart
RewardsService.debugMode = true;
```

The service will log initialization, API calls, and state changes to help with debugging.

## Future Enhancements

The integrated system is designed to be extensible. Planned features include:

- **Social Features**: Friend rewards and gifting
- **Seasonal Events**: Limited-time items and bonuses
- **Advanced Analytics**: Detailed user behavior tracking
- **Cross-Platform Sync**: Share rewards across devices
- **Marketplace**: User-to-user trading

## Support

For issues or questions about the rewards system integration, please check:

1. This documentation
2. The example implementation in `rewards_example.dart`
3. Individual component documentation
4. Create an issue in the project repository
