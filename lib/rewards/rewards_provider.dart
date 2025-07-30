import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'rewards_service.dart';

/// Provider wrapper for the RewardsService to enable easy access across all rewards widgets
class RewardsProvider extends ChangeNotifierProvider<RewardsService> {
  RewardsProvider({
    Key? key,
    required Widget child,
    required String userId,
  }) : super(
    key: key,
    create: (_) {
      final service = RewardsService.instance;
      // Initialize the service with the user ID
      service.initialize(userId);
      return service;
    },
    child: child,
  );

  /// Helper method to get the RewardsService from context
  static RewardsService of(BuildContext context) {
    return Provider.of<RewardsService>(context, listen: false);
  }

  /// Helper method to watch the RewardsService from context
  static RewardsService watch(BuildContext context) {
    return Provider.of<RewardsService>(context, listen: true);
  }
}

/// Extension on BuildContext to make accessing RewardsService easier
extension RewardsContext on BuildContext {
  RewardsService get rewards => RewardsProvider.of(this);
  RewardsService get watchRewards => RewardsProvider.watch(this);
}

/// Mixin for widgets that need to interact with the rewards system
mixin RewardsMixin<T extends StatefulWidget> on State<T> {
  RewardsService get rewardsService => RewardsProvider.of(context);
  
  /// Initialize rewards for the current user
  Future<void> initializeRewards(String userId) async {
    await rewardsService.initialize(userId);
  }
  
  /// Refresh all rewards data
  Future<void> refreshRewards() async {
    await rewardsService.refresh();
  }
  
  /// Show a purchase success message
  void showPurchaseSuccess(String itemName) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('$itemName purchased successfully!')),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
  
  /// Show a purchase error message
  void showPurchaseError(String error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('Purchase failed: $error')),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
  
  /// Show a generic rewards error message
  void showRewardsError(String error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}

/// Widget that rebuilds when rewards data changes
class RewardsBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, RewardsService rewards) builder;
  final Widget? loadingWidget;
  final Widget? errorWidget;

  const RewardsBuilder({
    Key? key,
    required this.builder,
    this.loadingWidget,
    this.errorWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<RewardsService>(
      builder: (context, rewards, child) {
        if (rewards.error != null && errorWidget != null) {
          return errorWidget!;
        }
        
        if (rewards.isLoading && loadingWidget != null) {
          return loadingWidget!;
        }
        
        return builder(context, rewards);
      },
    );
  }
}

/// Widget that displays current user coin balance
class CoinBalanceWidget extends StatelessWidget {
  final TextStyle? textStyle;
  final Color? iconColor;
  final double? iconSize;

  const CoinBalanceWidget({
    Key? key,
    this.textStyle,
    this.iconColor,
    this.iconSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RewardsBuilder(
      builder: (context, rewards) {
        final coins = rewards.userRewards['coins'] ?? 0;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.monetization_on,
              color: iconColor ?? Colors.amber,
              size: iconSize ?? 20,
            ),
            SizedBox(width: 4),
            Text(
              coins.toString(),
              style: textStyle ?? TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        );
      },
      loadingWidget: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.monetization_on,
            color: iconColor ?? Colors.amber,
            size: iconSize ?? 20,
          ),
          SizedBox(width: 4),
          Text(
            '...',
            style: textStyle ?? TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget that displays current user level and progress
class LevelProgressWidget extends StatelessWidget {
  final bool showProgressBar;
  final Color? progressColor;

  const LevelProgressWidget({
    Key? key,
    this.showProgressBar = true,
    this.progressColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RewardsBuilder(
      builder: (context, rewards) {
        final level = rewards.userRewards['level'] ?? 1;
        
        // Calculate progress (this would need to be implemented in RewardsService)
        final progress = 0.5; // Placeholder
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Level $level',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (showProgressBar) ...[
              SizedBox(height: 4),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  progressColor ?? Theme.of(context).primaryColor,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
