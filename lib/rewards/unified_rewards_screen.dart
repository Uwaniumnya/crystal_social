import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'rewards_provider.dart';
import 'shop_screen.dart';
import 'inventory_screen.dart';
import 'reward_archivement.dart';

/// Unified rewards screen that integrates all reward-related functionality
class UnifiedRewardsScreen extends StatefulWidget {
  final String userId;

  const UnifiedRewardsScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<UnifiedRewardsScreen> createState() => _UnifiedRewardsScreenState();
}

class _UnifiedRewardsScreenState extends State<UnifiedRewardsScreen>
    with TickerProviderStateMixin, RewardsMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  bool _showDailyReward = false;
  Map<String, dynamic>? _dailyRewardResult;

  final List<Map<String, dynamic>> _tabs = [
    {
      'title': 'Shop',
      'icon': Icons.shopping_cart,
      'color': Colors.blue,
    },
    {
      'title': 'Inventory',
      'icon': Icons.inventory,
      'color': Colors.green,
    },
    {
      'title': 'Achievements',
      'icon': Icons.emoji_events,
      'color': Colors.amber,
    },
    {
      'title': 'Stats',
      'icon': Icons.analytics,
      'color': Colors.purple,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
    _checkDailyReward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkDailyReward() async {
    try {
      final result = await rewardsService.claimDailyReward();
      if (mounted && result != null && !result['already_claimed']) {
        setState(() {
          _showDailyReward = true;
          _dailyRewardResult = result;
        });
      }
    } catch (e) {
      debugPrint('Error checking daily reward: $e');
    }
  }

  void _claimDailyReward() {
    setState(() {
      _showDailyReward = false;
    });
    
    HapticFeedback.lightImpact();
    
    final reward = _dailyRewardResult?['reward'] ?? {};
    final coins = reward['coins'] ?? 0;
    final points = reward['points'] ?? 0;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.star, color: Colors.yellow),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Daily reward claimed! +$coins coins, +$points points',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              _buildHeader(),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    ShopScreen(
                      userId: widget.userId,
                      supabase: rewardsService.rewardsManager.supabase,
                    ),
                    InventoryScreen(
                      userId: widget.userId,
                      supabase: rewardsService.rewardsManager.supabase,
                    ),
                    AchievementsScreen(
                      userId: widget.userId,
                      supabase: rewardsService.rewardsManager.supabase,
                    ),
                    _buildStatsTab(),
                  ],
                ),
              ),
            ],
          ),
          
          // Daily reward overlay
          if (_showDailyReward) _buildDailyRewardOverlay(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 16, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rewards',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  LevelProgressWidget(
                    progressColor: Colors.white,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                CoinBalanceWidget(
                  textStyle: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  iconColor: Colors.yellow,
                  iconSize: 24,
                ),
                SizedBox(height: 8),
                RewardsBuilder(
                  builder: (context, rewards) {
                    final points = rewards.userRewards['points'] ?? 0;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, color: Colors.white, size: 20),
                        SizedBox(width: 4),
                        Text(
                          '$points',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: TabBar(
        controller: _tabController,
        isScrollable: false,
        labelColor: Theme.of(context).primaryColor,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Theme.of(context).primaryColor,
        tabs: _tabs.map((tab) {
          return Tab(
            icon: Icon(tab['icon']),
            text: tab['title'],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatsTab() {
    return RewardsBuilder(
      builder: (context, rewards) {
        final stats = rewards.userStats;
        
        return ListView(
          padding: EdgeInsets.all(16),
          children: [
            _buildStatCard(
              'Total Purchases',
              '${stats['totalPurchases'] ?? 0}',
              Icons.shopping_bag,
              Colors.blue,
            ),
            SizedBox(height: 16),
            _buildStatCard(
              'Total Spent',
              '${stats['totalSpent'] ?? 0} coins',
              Icons.monetization_on,
              Colors.green,
            ),
            SizedBox(height: 16),
            _buildStatCard(
              'Achievements Unlocked',
              '${stats['achievementsUnlocked'] ?? 0}',
              Icons.emoji_events,
              Colors.amber,
            ),
            SizedBox(height: 16),
            _buildStatCard(
              'Login Streak',
              '${stats['loginStreak'] ?? 0} days',
              Icons.local_fire_department,
              Colors.red,
            ),
          ],
        );
      },
      loadingWidget: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(
                icon,
                color: color,
                size: 30,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyRewardOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Card(
            margin: EdgeInsets.all(32),
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.card_giftcard,
                    size: 64,
                    color: Colors.amber,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Daily Reward!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'You\'ve earned your daily login reward!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _claimDailyReward,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Claim Reward',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
