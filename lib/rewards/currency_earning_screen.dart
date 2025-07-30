import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../rewards/rewards_manager.dart';
import 'dart:async';

/// Enhanced Currency Earning Hub
/// Provides multiple ways for users to earn coins easily
class CurrencyEarningScreen extends StatefulWidget {
  final String userId;

  const CurrencyEarningScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _CurrencyEarningScreenState createState() => _CurrencyEarningScreenState();
}

class _CurrencyEarningScreenState extends State<CurrencyEarningScreen>
    with TickerProviderStateMixin {
  late RewardsManager _rewardsManager;
  late AnimationController _coinAnimationController;
  late AnimationController _spinWheelController;
  Timer? _refreshTimer;
  
  Map<String, dynamic> userRewards = {};
  Map<String, DateTime?> nextAvailableTimes = {};
  List<Map<String, dynamic>> availableQuests = [];
  List<Map<String, dynamic>> weeklyProgress = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _rewardsManager = RewardsManager(Supabase.instance.client);
    _setupAnimations();
    _loadUserData();
    _startRefreshTimer();
  }

  void _setupAnimations() {
    _coinAnimationController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    
    _spinWheelController = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    );
  }

  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(Duration(minutes: 1), (_) {
      if (mounted) _loadUserData();
    });
  }

  Future<void> _loadUserData() async {
    try {
      final rewards = await _rewardsManager.getUserRewards(widget.userId);
      
      setState(() {
        userRewards = rewards;
        isLoading = false;
      });
      
      await _loadAvailabilityTimes();
      await _loadQuests();
      await _loadWeeklyProgress();
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadAvailabilityTimes() async {
    // Calculate next available times for different activities
    final now = DateTime.now();
    
    // Daily spin wheel
    final lastSpin = userRewards['last_spin_wheel'];
    if (lastSpin != null) {
      final lastSpinTime = DateTime.parse(lastSpin);
      final tomorrow = DateTime(lastSpinTime.year, lastSpinTime.month, lastSpinTime.day + 1);
      nextAvailableTimes['spin_wheel'] = tomorrow.isAfter(now) ? tomorrow : null;
    }
    
    // Hourly bonus
    final lastHourly = userRewards['last_hourly_bonus'];
    if (lastHourly != null) {
      final lastHourlyTime = DateTime.parse(lastHourly);
      final nextHour = lastHourlyTime.add(Duration(hours: 1));
      nextAvailableTimes['hourly_bonus'] = nextHour.isAfter(now) ? nextHour : null;
    }
  }

  Future<void> _loadQuests() async {
    // Mock quest data - in real app, load from database
    availableQuests = [
      {
        'id': 'send_10_messages',
        'name': 'Chatter',
        'description': 'Send 10 messages today',
        'progress': (userRewards['messages_sent'] ?? 0) % 10,
        'required': 10,
        'coins': 50,
        'points': 25,
        'completed': false,
      },
      {
        'id': 'make_5_friends',
        'name': 'Social Butterfly',
        'description': 'Add 5 new friends',
        'progress': 2, // Mock progress
        'required': 5,
        'coins': 100,
        'points': 50,
        'completed': false,
      },
      {
        'id': 'post_first_glitter',
        'name': 'Glitter Newbie',
        'description': 'Post your first glitter board content',
        'progress': 0,
        'required': 1,
        'coins': 60,
        'points': 25,
        'completed': false,
      },
    ];
  }

  Future<void> _loadWeeklyProgress() async {
    weeklyProgress = [
      {
        'type': 'message_marathon',
        'name': 'Message Marathon',
        'description': 'Send 100 messages this week',
        'progress': 45, // Mock data
        'required': 100,
        'coins': 500,
        'points': 200,
      },
      {
        'type': 'social_star',
        'name': 'Social Star',
        'description': 'Receive 50 likes this week',
        'progress': 23,
        'required': 50,
        'coins': 400,
        'points': 150,
      },
    ];
  }

  String _formatTimeRemaining(DateTime? nextTime) {
    if (nextTime == null) return 'Available now!';
    
    final now = DateTime.now();
    final diff = nextTime.difference(now);
    
    if (diff.inDays > 0) {
      return '${diff.inDays}d ${diff.inHours % 24}h';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ${diff.inMinutes % 60}m';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m';
    } else {
      return 'Available now!';
    }
  }

  Future<void> _claimDailySpinWheel() async {
    _spinWheelController.forward();
    final result = await _rewardsManager.claimDailySpinWheel(widget.userId, context);
    
    if (result['success']) {
      _coinAnimationController.forward().then((_) => _coinAnimationController.reverse());
      await _loadUserData();
    }
    
    _spinWheelController.reverse();
  }

  Future<void> _claimHourlyBonus() async {
    final result = await _rewardsManager.claimHourlyBonus(widget.userId, context);
    
    if (result['success']) {
      _coinAnimationController.forward().then((_) => _coinAnimationController.reverse());
      await _loadUserData();
    }
  }

  Future<void> _completeQuest(String questId) async {
    final result = await _rewardsManager.completeQuest(widget.userId, questId, context);
    
    if (result['success']) {
      _coinAnimationController.forward().then((_) => _coinAnimationController.reverse());
      await _loadUserData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      appBar: AppBar(
        title: Text('💰 Earn Coins'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          AnimatedBuilder(
            animation: _coinAnimationController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_coinAnimationController.value * 0.2),
                child: Container(
                  margin: EdgeInsets.only(right: 16),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.monetization_on, color: Colors.white, size: 20),
                      SizedBox(width: 4),
                      Text(
                        '${userRewards['coins'] ?? 0}',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUserData,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDailyRewards(),
                    SizedBox(height: 24),
                    _buildQuickEarning(),
                    SizedBox(height: 24),
                    _buildQuests(),
                    SizedBox(height: 24),
                    _buildWeeklyChallenges(),
                    SizedBox(height: 24),
                    _buildEarningTips(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDailyRewards() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.purple.shade400, Colors.blue.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🎰 Daily Spin Wheel',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Spin once per day for 25-1500 coins!',
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 16),
            AnimatedBuilder(
              animation: _spinWheelController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _spinWheelController.value * 6.28 * 3, // 3 full rotations
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [Colors.yellow, Colors.orange, Colors.red],
                      ),
                    ),
                    child: Icon(
                      Icons.casino,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: nextAvailableTimes['spin_wheel'] == null
                    ? _claimDailySpinWheel
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.purple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  nextAvailableTimes['spin_wheel'] == null
                      ? 'SPIN NOW!'
                      : 'Next: ${_formatTimeRemaining(nextAvailableTimes['spin_wheel'])}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickEarning() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '⏰ Hourly Bonus',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.access_time, color: Colors.blue, size: 32),
                      SizedBox(height: 8),
                      Text(
                        'Hourly Bonus',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('5-15 coins', style: TextStyle(color: Colors.grey)),
                      SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: nextAvailableTimes['hourly_bonus'] == null
                            ? _claimHourlyBonus
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          nextAvailableTimes['hourly_bonus'] == null
                              ? 'Claim'
                              : _formatTimeRemaining(nextAvailableTimes['hourly_bonus']),
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuests() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🎯 Daily Quests',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
        SizedBox(height: 12),
        ...availableQuests.map((quest) => Card(
          margin: EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.orange,
              child: Text('${quest['coins']}', style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
            title: Text(quest['name'], style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(quest['description']),
                SizedBox(height: 4),
                LinearProgressIndicator(
                  value: quest['progress'] / quest['required'],
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                ),
                SizedBox(height: 4),
                Text('${quest['progress']}/${quest['required']}', style: TextStyle(fontSize: 12)),
              ],
            ),
            trailing: quest['progress'] >= quest['required']
                ? ElevatedButton(
                    onPressed: () => _completeQuest(quest['id']),
                    child: Text('Claim'),
                  )
                : Text('${quest['coins']} coins'),
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildWeeklyChallenges() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🏆 Weekly Challenges',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
        SizedBox(height: 12),
        ...weeklyProgress.map((challenge) => Card(
          margin: EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.red,
              child: Text('${challenge['coins']}', style: TextStyle(color: Colors.white, fontSize: 10)),
            ),
            title: Text(challenge['name'], style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(challenge['description']),
                SizedBox(height: 4),
                LinearProgressIndicator(
                  value: challenge['progress'] / challenge['required'],
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                ),
                SizedBox(height: 4),
                Text('${challenge['progress']}/${challenge['required']}', style: TextStyle(fontSize: 12)),
              ],
            ),
            trailing: challenge['progress'] >= challenge['required']
                ? ElevatedButton(
                    onPressed: () {}, // Implement weekly challenge claim
                    child: Text('Claim'),
                  )
                : Text('${challenge['coins']} coins'),
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildEarningTips() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '💡 Earning Tips',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            SizedBox(height: 12),
            _buildTip('💬', 'Send messages: 2 points each (leads to level ups!)'),
            _buildTip('❤️', 'Like posts: 1 point each'),
            _buildTip('📝', 'Post content: 8 points each'),
            _buildTip('👥', 'Add friends: 15 coins when they accept'),
            _buildTip('🏠', 'Decorate home: 6 coins per item placed'),
            _buildTip('🔮', 'Complete tarot readings: 20 coins each'),
            _buildTip('💎', 'Discover gems: 40 coins each'),
            _buildTip('🦋', 'Catch butterflies: 12 coins each'),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(String emoji, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(emoji, style: TextStyle(fontSize: 16)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _coinAnimationController.dispose();
    _spinWheelController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }
}
