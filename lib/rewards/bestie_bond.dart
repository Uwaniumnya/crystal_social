import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:confetti/confetti.dart';

class BestieBondManager extends StatefulWidget {
  final String userId;
  final String? targetUserId; // The friend's user ID

  const BestieBondManager({super.key, required this.userId, this.targetUserId});

  @override
  State<BestieBondManager> createState() => _BestieBondManagerState();
}

class _BestieBondManagerState extends State<BestieBondManager>
    with TickerProviderStateMixin {
  final SupabaseClient _supabase = Supabase.instance.client;
  late AnimationController _progressController;
  late AnimationController _celebrationController;
  late AnimationController _pulseController;
  late Animation<double> _progressAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  
  final ConfettiController _confettiController = ConfettiController(
    duration: const Duration(seconds: 3),
  );

  Map<String, dynamic>? bondData;
  bool isLoading = true;
  bool showLevelUpDialog = false;
  List<Map<String, dynamic>> recentActivities = [];
  Map<String, dynamic>? friendProfile;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadBondData();
  }

  void _initializeAnimations() {
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _celebrationController, curve: Curves.elasticOut),
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _progressController.dispose();
    _celebrationController.dispose();
    _pulseController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadBondData() async {
    if (widget.targetUserId == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      setState(() => isLoading = true);
      
      // Load bond data
      await _loadBondLevel();
      
      // Load friend profile
      await _loadFriendProfile();
      
      // Load recent activities
      await _loadRecentActivities();
      
      // Start progress animation
      _progressController.forward();
      
    } catch (e) {
      print('Error loading bond data: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadBondLevel() async {
    try {
      final response = await _supabase
          .from('bestie_bonds')
          .select('*')
          .or('and(user_id_1.eq.${widget.userId},user_id_2.eq.${widget.targetUserId}),and(user_id_1.eq.${widget.targetUserId},user_id_2.eq.${widget.userId})')
          .maybeSingle();

      if (response != null) {
        setState(() {
          bondData = response;
        });
      } else {
        // Create initial bond
        await _createInitialBond();
      }
    } catch (e) {
      print('Error loading bond level: $e');
    }
  }

  Future<void> _createInitialBond() async {
    try {
      final newBond = {
        'user_id_1': widget.userId,
        'user_id_2': widget.targetUserId,
        'bond_level': 1,
        'message_count': 0,
        'activities_together': 0,
        'total_coins_earned': 0,
        'last_interaction': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'milestone_reached': false,
      };

      final response = await _supabase
          .from('bestie_bonds')
          .insert(newBond)
          .select()
          .single();

      setState(() {
        bondData = response;
      });
    } catch (e) {
      print('Error creating initial bond: $e');
    }
  }

  Future<void> _loadFriendProfile() async {
    if (widget.targetUserId == null) return;

    try {
      final response = await _supabase
          .from('user_profiles')
          .select('username, avatar_url, display_name')
          .eq('id', widget.targetUserId!)
          .single();

      setState(() {
        friendProfile = response;
      });
    } catch (e) {
      print('Error loading friend profile: $e');
    }
  }

  Future<void> _loadRecentActivities() async {
    try {
      // This would load recent shared activities like messages, games played together, etc.
      // For now, we'll create some sample data
      setState(() {
        recentActivities = [
          {
            'type': 'message',
            'description': 'Sent messages',
            'count': 5,
            'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
          },
          {
            'type': 'game',
            'description': 'Played games together',
            'count': 2,
            'timestamp': DateTime.now().subtract(const Duration(hours: 5)),
          },
          {
            'type': 'gift',
            'description': 'Exchanged gifts',
            'count': 1,
            'timestamp': DateTime.now().subtract(const Duration(days: 1)),
          },
        ];
      });
    } catch (e) {
      print('Error loading activities: $e');
    }
  }

  // Enhanced bond interaction methods
  Future<void> updateBestieBond(String interactionType, {int count = 1}) async {
    if (bondData == null || widget.targetUserId == null) return;

    try {
      final currentLevel = bondData!['bond_level'] as int;
      final currentMessages = bondData!['message_count'] as int;
      final currentActivities = bondData!['activities_together'] as int;
      
      int newMessages = currentMessages;
      int newActivities = currentActivities;
      
      // Update counts based on interaction type
      switch (interactionType) {
        case 'message':
          newMessages += count;
          break;
        case 'activity':
        case 'game':
        case 'gift':
          newActivities += count;
          break;
      }

      // Calculate if level up is needed
      final newLevel = _calculateLevel(newMessages, newActivities);
      final leveledUp = newLevel > currentLevel;
      
      // Update database
      await _supabase.from('bestie_bonds').update({
        'message_count': newMessages,
        'activities_together': newActivities,
        'bond_level': newLevel,
        'last_interaction': DateTime.now().toIso8601String(),
        'milestone_reached': leveledUp,
      }).eq('id', bondData!['id']);

      // Award coins for level up
      if (leveledUp) {
        await _awardLevelUpCoins(newLevel);
        _celebrateLevelUp(newLevel);
      }

      // Reload data
      await _loadBondData();
      
    } catch (e) {
      print('Error updating bestie bond: $e');
    }
  }

  int _calculateLevel(int messages, int activities) {
    final totalInteractions = messages + (activities * 2); // Activities worth 2x
    
    if (totalInteractions >= 1000) return 10;
    if (totalInteractions >= 750) return 9;
    if (totalInteractions >= 500) return 8;
    if (totalInteractions >= 350) return 7;
    if (totalInteractions >= 250) return 6;
    if (totalInteractions >= 150) return 5;
    if (totalInteractions >= 100) return 4;
    if (totalInteractions >= 50) return 3;
    if (totalInteractions >= 20) return 2;
    return 1;
  }

  Future<void> _awardLevelUpCoins(int newLevel) async {
    final coinsToAward = getCoinsForLevel(newLevel);
    
    try {
      // Award coins to both users
      await _supabase.rpc('increment_user_coins', params: {
        'user_id': widget.userId,
        'coin_amount': coinsToAward,
      });
      
      if (widget.targetUserId != null) {
        await _supabase.rpc('increment_user_coins', params: {
          'user_id': widget.targetUserId,
          'coin_amount': coinsToAward,
        });
      }

      // Update total coins earned
      await _supabase.from('bestie_bonds').update({
        'total_coins_earned': (bondData!['total_coins_earned'] as int) + (coinsToAward * 2),
      }).eq('id', bondData!['id']);
      
    } catch (e) {
      print('Error awarding coins: $e');
    }
  }

  void _celebrateLevelUp(int newLevel) {
    HapticFeedback.heavyImpact();
    _confettiController.play();
    _celebrationController.forward().then((_) {
      _celebrationController.reverse();
    });
    
    // Show level up dialog
    _showLevelUpDialog(newLevel);
  }

  void _showLevelUpDialog(int newLevel) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.celebration,
              size: 60,
              color: Colors.amber,
            ),
            const SizedBox(height: 20),
            Text(
              'Level Up! 🎉',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'You reached ${getLevelTitle(newLevel)}!',
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'You both earned ${getCoinsForLevel(newLevel)} coins!',
                style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            child: const Text('Awesome!', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  double _getProgressToNextLevel() {
    if (bondData == null) return 0.0;
    
    final currentLevel = bondData!['bond_level'] as int;
    if (currentLevel >= 10) return 1.0;
    
    final messages = bondData!['message_count'] as int;
    final activities = bondData!['activities_together'] as int;
    final currentInteractions = messages + (activities * 2);
    
    final currentLevelThreshold = _getLevelThreshold(currentLevel);
    final nextLevelThreshold = _getLevelThreshold(currentLevel + 1);
    
    final progress = (currentInteractions - currentLevelThreshold) / 
                    (nextLevelThreshold - currentLevelThreshold);
    
    return progress.clamp(0.0, 1.0);
  }

  int _getLevelThreshold(int level) {
    switch (level) {
      case 1: return 0;
      case 2: return 20;
      case 3: return 50;
      case 4: return 100;
      case 5: return 150;
      case 6: return 250;
      case 7: return 350;
      case 8: return 500;
      case 9: return 750;
      case 10: return 1000;
      default: return 1000;
    }
  }
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFFF1F5),
        body: Center(
          child: CircularProgressIndicator(color: Colors.pink),
        ),
      );
    }

    if (widget.targetUserId == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFFFF1F5),
        appBar: AppBar(
          title: const Text('Bestie Bonds', style: TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFFFFC1D9),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline, size: 80, color: Colors.grey),
              SizedBox(height: 20),
              Text(
                'Select a friend to view your bond!',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFF1F5),
      appBar: AppBar(
        title: Text(
          'Bond with ${friendProfile?['display_name'] ?? friendProfile?['username'] ?? 'Friend'}',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFFFC1D9),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadBondData,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Confetti overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Colors.pink, Colors.purple, Colors.blue, Colors.yellow],
            ),
          ),
          
          // Main content
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildBondLevelCard(),
                const SizedBox(height: 20),
                _buildProgressCard(),
                const SizedBox(height: 20),
                _buildStatsCard(),
                const SizedBox(height: 20),
                _buildRecentActivitiesCard(),
                const SizedBox(height: 20),
                _buildInteractionButtons(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBondLevelCard() {
    if (bondData == null) return const SizedBox();
    
    final level = bondData!['bond_level'] as int;
    final levelTitle = getLevelTitle(level);
    
    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _pulseAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value * _pulseAnimation.value,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.pink.withOpacity(0.8),
                  Colors.purple.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.pink.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                // Friend avatar
                if (friendProfile?['avatar_url'] != null)
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      image: DecorationImage(
                        image: NetworkImage(friendProfile!['avatar_url']),
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                else
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const Icon(Icons.person, size: 40, color: Colors.white),
                  ),
                
                const SizedBox(height: 15),
                
                Text(
                  'Level $level',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  levelTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 15),
                
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    'Total Coins Earned: ${bondData!['total_coins_earned'] ?? 0}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressCard() {
    if (bondData == null) return const SizedBox();
    
    final progress = _getProgressToNextLevel();
    final currentLevel = bondData!['bond_level'] as int;
    final nextLevel = currentLevel + 1;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progress to Next Level',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (currentLevel < 10)
                Text(
                  'Level $nextLevel',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 15),
          
          if (currentLevel >= 10)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber, width: 2),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emoji_events, color: Colors.amber, size: 24),
                  SizedBox(width: 10),
                  Text(
                    'Maximum Level Reached! 👑',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    return LinearProgressIndicator(
                      value: progress * _progressAnimation.value,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.pink),
                      minHeight: 8,
                    );
                  },
                ),
                
                const SizedBox(height: 10),
                
                Text(
                  '${(progress * 100).toInt()}% Complete',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    if (bondData == null) return const SizedBox();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bond Statistics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          
          const SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Messages',
                  '${bondData!['message_count'] ?? 0}',
                  Icons.message,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildStatItem(
                  'Activities',
                  '${bondData!['activities_together'] ?? 0}',
                  Icons.sports_esports,
                  Colors.green,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 15),
          
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Days Together',
                  _calculateDaysTogether().toString(),
                  Icons.calendar_today,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildStatItem(
                  'Coins Earned',
                  '${bondData!['total_coins_earned'] ?? 0}',
                  Icons.monetization_on,
                  Colors.amber,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitiesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Activities',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          
          const SizedBox(height: 15),
          
          if (recentActivities.isEmpty)
            const Text(
              'No recent activities',
              style: TextStyle(color: Colors.grey),
            )
          else
            ...recentActivities.map((activity) => _buildActivityItem(activity)),
        ],
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    IconData icon;
    Color color;
    
    switch (activity['type']) {
      case 'message':
        icon = Icons.message;
        color = Colors.blue;
        break;
      case 'game':
        icon = Icons.sports_esports;
        color = Colors.green;
        break;
      case 'gift':
        icon = Icons.card_giftcard;
        color = Colors.pink;
        break;
      default:
        icon = Icons.star;
        color = Colors.grey;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              activity['description'],
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            _formatTimeAgo(activity['timestamp']),
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => updateBestieBond('message', count: 1),
            icon: const Icon(Icons.message, color: Colors.white),
            label: const Text('Send Message', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        
        const SizedBox(width: 15),
        
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => updateBestieBond('activity', count: 1),
            icon: const Icon(Icons.sports_esports, color: Colors.white),
            label: const Text('Play Game', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }

  int _calculateDaysTogether() {
    if (bondData?['created_at'] == null) return 0;
    
    final createdAt = DateTime.parse(bondData!['created_at']);
    final now = DateTime.now();
    return now.difference(createdAt).inDays + 1;
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
    return 'Just now';
  }

  // Utility methods for level titles and coins
  String getLevelTitle(int level) {
    switch (level) {
      case 1:
        return '💞 Budding Buddies';
      case 2:
        return '💫 Sparkling Companions';
      case 3:
        return '🌸 Close Confidants';
      case 4:
        return '🌟 Glimmering Souls';
      case 5:
        return '👯 Eternal Sparkle Twins';
      case 6:
        return '🦋 Cosmic Co-Conspirators';
      case 7:
        return '✨ Radiant Allies';
      case 8:
        return '🌙 Stellar Sidekicks';
      case 9:
        return '💎 Diamond Duo';
      case 10:
        return '👑 Cosmic Partners';
      default:
        return '💞 Budding Buddies';
    }
  }

  int getCoinsForLevel(int level) {
    switch (level) {
      case 1:
        return 50;
      case 2:
        return 75;
      case 3:
        return 100;
      case 4:
        return 150;
      case 5:
        return 200;
      case 6:
        return 250;
      case 7:
        return 300;
      case 8:
        return 350;
      case 9:
        return 400;
      case 10:
        return 500;
      default:
        return 50;
    }
  }
}
