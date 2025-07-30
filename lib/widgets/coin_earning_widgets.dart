import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../rewards/rewards_manager.dart';
import '../rewards/currency_earning_screen.dart';

/// Quick access widget for earning coins
/// Can be added to any screen to provide easy coin earning
class CoinEarningWidget extends StatelessWidget {
  final String userId;
  final RewardsManager rewardsManager;

  const CoinEarningWidget({
    Key? key,
    required this.userId,
    required this.rewardsManager,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(8),
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CurrencyEarningScreen(userId: userId),
            ),
          );
        },
        icon: Icon(Icons.monetization_on, color: Colors.white),
        label: Text('Earn Coins', style: TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber.shade600,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
    );
  }
}

/// Floating action button for coin earning
class CoinEarningFAB extends StatefulWidget {
  final String userId;

  const CoinEarningFAB({Key? key, required this.userId}) : super(key: key);

  @override
  _CoinEarningFABState createState() => _CoinEarningFABState();
}

class _CoinEarningFABState extends State<CoinEarningFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late RewardsManager _rewardsManager;
  bool _canClaimHourly = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _rewardsManager = RewardsManager(Supabase.instance.client);
    _checkHourlyAvailability();
  }

  Future<void> _checkHourlyAvailability() async {
    try {
      final userRewards = await _rewardsManager.getUserRewards(widget.userId);
      final lastHourly = userRewards['last_hourly_bonus'];
      
      if (lastHourly != null) {
        final lastHourlyTime = DateTime.parse(lastHourly);
        final timeDiff = DateTime.now().difference(lastHourlyTime);
        setState(() {
          _canClaimHourly = timeDiff.inHours >= 1;
        });
      } else {
        setState(() {
          _canClaimHourly = true;
        });
      }
    } catch (e) {
      setState(() {
        _canClaimHourly = false;
      });
    }
  }

  Future<void> _quickClaimHourly() async {
    final result = await _rewardsManager.claimHourlyBonus(widget.userId, context);
    if (result['success']) {
      setState(() {
        _canClaimHourly = false;
      });
      // Check again in an hour
      Future.delayed(Duration(hours: 1), () {
        if (mounted) {
          setState(() {
            _canClaimHourly = true;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Hourly bonus button (if available)
        if (_canClaimHourly)
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (0.1 * (1.0 - _animationController.value)),
                child: FloatingActionButton.small(
                  onPressed: _quickClaimHourly,
                  backgroundColor: Colors.blue,
                  heroTag: "hourly_bonus",
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.white),
                      Text('FREE', style: TextStyle(fontSize: 8, color: Colors.white)),
                    ],
                  ),
                ),
              );
            },
          ),
        
        if (_canClaimHourly) SizedBox(height: 8),
        
        // Main earn coins button
        FloatingActionButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => CurrencyEarningScreen(userId: widget.userId),
              ),
            );
          },
          backgroundColor: Colors.amber.shade600,
          heroTag: "earn_coins",
          child: Icon(Icons.monetization_on, color: Colors.white),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

/// Simple coin display widget
class CoinDisplayWidget extends StatefulWidget {
  final String userId;

  const CoinDisplayWidget({Key? key, required this.userId}) : super(key: key);

  @override
  _CoinDisplayWidgetState createState() => _CoinDisplayWidgetState();
}

class _CoinDisplayWidgetState extends State<CoinDisplayWidget> {
  late RewardsManager _rewardsManager;
  int coins = 0;

  @override
  void initState() {
    super.initState();
    _rewardsManager = RewardsManager(Supabase.instance.client);
    _loadCoins();
  }

  Future<void> _loadCoins() async {
    try {
      final userRewards = await _rewardsManager.getUserRewards(widget.userId);
      setState(() {
        coins = userRewards['coins'] ?? 0;
      });
    } catch (e) {
      debugPrint('Error loading coins: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.amber.shade600,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.monetization_on, color: Colors.white, size: 18),
          SizedBox(width: 4),
          Text(
            '$coins',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

/// Activity reward helper functions for easy integration
class ActivityRewardHelper {
  static Future<void> awardProfileUpdate(String userId, BuildContext context) async {
    final rewardsManager = RewardsManager(Supabase.instance.client);
    await rewardsManager.awardActivityCoins(userId, 'profile_photo_update', context);
  }

  static Future<void> awardFriendRequest(String userId, BuildContext context) async {
    final rewardsManager = RewardsManager(Supabase.instance.client);
    await rewardsManager.awardActivityCoins(userId, 'friend_request_sent', context);
  }

  static Future<void> awardFriendAccepted(String userId, BuildContext context) async {
    final rewardsManager = RewardsManager(Supabase.instance.client);
    await rewardsManager.awardActivityCoins(userId, 'friend_request_accepted', context);
  }

  static Future<void> awardGroupCreated(String userId, BuildContext context) async {
    final rewardsManager = RewardsManager(Supabase.instance.client);
    await rewardsManager.awardActivityCoins(userId, 'group_created', context);
  }

  static Future<void> awardTarotReading(String userId, BuildContext context) async {
    final rewardsManager = RewardsManager(Supabase.instance.client);
    await rewardsManager.awardActivityCoins(userId, 'tarot_reading_completed', context);
  }

  static Future<void> awardGemDiscovery(String userId, BuildContext context) async {
    final rewardsManager = RewardsManager(Supabase.instance.client);
    await rewardsManager.awardActivityCoins(userId, 'gem_discovered', context);
  }

  static Future<void> awardButterflyInteraction(String userId, BuildContext context) async {
    final rewardsManager = RewardsManager(Supabase.instance.client);
    await rewardsManager.awardActivityCoins(userId, 'butterfly_caught', context);
  }

  static Future<void> awardHomeDecoration(String userId, BuildContext context) async {
    final rewardsManager = RewardsManager(Supabase.instance.client);
    await rewardsManager.awardActivityCoins(userId, 'home_decoration_placed', context);
  }

  static Future<void> awardPetInteraction(String userId, BuildContext context) async {
    final rewardsManager = RewardsManager(Supabase.instance.client);
    await rewardsManager.awardActivityCoins(userId, 'pet_interaction', context);
  }

  static Future<void> awardFirstMessageDaily(String userId, BuildContext context) async {
    final rewardsManager = RewardsManager(Supabase.instance.client);
    await rewardsManager.awardActivityCoins(userId, 'first_message_daily', context);
  }
}
