import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

// Cache entry for temporary data storage
class _CacheEntry {
  final dynamic data;
  final DateTime timestamp;

  _CacheEntry(this.data) : timestamp = DateTime.now();

  bool get isExpired => DateTime.now().difference(timestamp) > Duration(minutes: 5);
}

// Enhanced reward tracking model
class RewardTransaction {
  final String id;
  final String userId;
  final String type; // 'coins', 'points', 'item', 'achievement'
  final int amount;
  final String? itemId;
  final String? source; // 'purchase', 'achievement', 'daily_login', etc.
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  RewardTransaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    this.itemId,
    this.source,
    required this.timestamp,
    this.metadata,
  });

  factory RewardTransaction.fromJson(Map<String, dynamic> json) {
    return RewardTransaction(
      id: json['id'],
      userId: json['user_id'],
      type: json['type'],
      amount: json['amount'],
      itemId: json['item_id'],
      source: json['source'],
      timestamp: DateTime.parse(json['timestamp']),
      metadata: json['metadata'],
    );
  }
}

// User statistics model
class UserStats {
  final int totalPurchases;
  final int totalSpent;
  final int achievementsUnlocked;
  final int levelUps;
  final DateTime? lastLogin;
  final int loginStreak;
  final String favoriteCategory;
  final double averageSessionTime;

  UserStats({
    required this.totalPurchases,
    required this.totalSpent,
    required this.achievementsUnlocked,
    required this.levelUps,
    this.lastLogin,
    required this.loginStreak,
    required this.favoriteCategory,
    required this.averageSessionTime,
  });
}

class RewardsManager {
  final SupabaseClient supabase;
  static final Map<String, _CacheEntry> _cache = {};

  RewardsManager(this.supabase);

  // Enhanced category mapping with more detailed types
  String _mapCategoryIdToType(int id) {
    switch (id) {
      case 1:
        return 'aura';
      case 2:
        return 'background';
      case 3:
        return 'pet_accessory';
      case 4:
        return 'emote';
      case 5:
        return 'badge';
      case 6:
        return 'decoration';
      case 7:
        return 'booster_pack';
      case 8:
        return 'theme';
      case 9:
        return 'effect';
      case 10:
        return 'sound_pack';
      default:
        return 'unknown';
    }
  }

  // Cache management
  T? _getCachedData<T>(String key) {
    final entry = _cache[key];
    if (entry != null && !entry.isExpired) {
      return entry.data as T?;
    }
    _cache.remove(key);
    return null;
  }

  void _setCachedData(String key, dynamic data) {
    _cache[key] = _CacheEntry(data);
  }

  void clearCache() {
    _cache.clear();
  }

  // Enhanced user rewards with caching
  Future<Map<String, dynamic>> getUserRewards(String userId) async {
    final cacheKey = 'user_rewards_$userId';
    final cached = _getCachedData<Map<String, dynamic>>(cacheKey);
    if (cached != null) return cached;

    try {
      final response = await supabase
          .from('users_rewards')
          .select('*, last_login, login_streak, total_spent, achievements_count')
          .eq('user_id', userId)
          .single();
      
      _setCachedData(cacheKey, response);
      return response;
    } catch (e) {
      // Create default user rewards if not exists
      final defaultRewards = {
        'user_id': userId,
        'points': 0,
        'coins': 100, // Starting coins
        'level': 1,
        'last_login': DateTime.now().toIso8601String(),
        'login_streak': 1,
        'total_spent': 0,
        'achievements_count': 0,
        'messages_sent': 0, // Track messages sent for leveling
      };
      
      await supabase.from('users_rewards').upsert(defaultRewards);
      _setCachedData(cacheKey, defaultRewards);
      return defaultRewards;
    }
  }

  Future<void> updateUserRewards(
      String userId, int points, int coins, int level) async {
    await supabase.from('users_rewards').upsert({
      'user_id': userId,
      'points': points,
      'coins': coins,
      'level': level,
    });
  }

  // Enhanced level calculation with exponential growth
  int calculateLevel(int points) {
    if (points <= 0) return 1;
    
    // Exponential level calculation: level = floor(sqrt(points / 100)) + 1
    final level = (math.sqrt(points / 100).floor() + 1).clamp(1, 100);
    return level;
  }

  // Calculate points needed for next level
  int getPointsForNextLevel(int currentLevel) {
    if (currentLevel >= 100) return 0;
    return ((currentLevel * currentLevel) * 100) - (((currentLevel - 1) * (currentLevel - 1)) * 100);
  }

  // Calculate progress to next level (0.0 to 1.0)
  double getLevelProgress(int points, int currentLevel) {
    if (currentLevel >= 100) return 1.0;
    
    final currentLevelPoints = ((currentLevel - 1) * (currentLevel - 1)) * 100;
    final nextLevelPoints = (currentLevel * currentLevel) * 100;
    final progressPoints = points - currentLevelPoints;
    final requiredPoints = nextLevelPoints - currentLevelPoints;
    
    return (progressPoints / requiredPoints).clamp(0.0, 1.0);
  }

  // Daily login rewards
  Future<Map<String, dynamic>> handleDailyLogin(String userId) async {
    final userRewards = await getUserRewards(userId);
    final lastLogin = userRewards['last_login'];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    DateTime lastLoginDate;
    if (lastLogin != null) {
      final lastLoginDateTime = DateTime.parse(lastLogin);
      lastLoginDate = DateTime(lastLoginDateTime.year, lastLoginDateTime.month, lastLoginDateTime.day);
    } else {
      lastLoginDate = today.subtract(Duration(days: 1));
    }
    
    // Check if already claimed today
    if (lastLoginDate.isAtSameMomentAs(today)) {
      return {
        'already_claimed': true,
        'next_reward_in': Duration(days: 1),
      };
    }
    
    // Calculate streak
    int newStreak = 1;
    if (lastLoginDate.isAtSameMomentAs(today.subtract(Duration(days: 1)))) {
      newStreak = (userRewards['login_streak'] ?? 0) + 1;
    }
    
    // Calculate rewards based on streak
    final baseCoins = 10;
    final streakBonus = math.min(newStreak * 2, 50); // Max 50 bonus coins
    final totalCoins = baseCoins + streakBonus;
    final bonusPoints = newStreak >= 7 ? 50 : 0; // Weekly bonus
    
    // Update user rewards
    final newPoints = userRewards['points'] + bonusPoints;
    final newCoins = userRewards['coins'] + totalCoins;
    final newLevel = calculateLevel(newPoints);
    
    await updateUserRewards(userId, newPoints, newCoins, newLevel);
    await supabase.from('users_rewards').update({
      'last_login': now.toIso8601String(),
      'login_streak': newStreak,
    }).eq('user_id', userId);
    
    // Track transaction
    await _recordTransaction(
      userId: userId,
      type: 'coins',
      amount: totalCoins,
      source: 'daily_login',
      metadata: {'streak': newStreak, 'streak_bonus': streakBonus},
    );
    
    if (bonusPoints > 0) {
      await _recordTransaction(
        userId: userId,
        type: 'points',
        amount: bonusPoints,
        source: 'weekly_streak',
        metadata: {'streak': newStreak},
      );
    }
    
    return {
      'coins_earned': totalCoins,
      'points_earned': bonusPoints,
      'streak': newStreak,
      'is_milestone': newStreak % 7 == 0,
    };
  }

  // Record transaction for analytics
  Future<void> _recordTransaction({
    required String userId,
    required String type,
    required int amount,
    String? itemId,
    String? source,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await supabase.from('reward_transactions').insert({
        'user_id': userId,
        'type': type,
        'amount': amount,
        'item_id': itemId,
        'source': source,
        'metadata': metadata,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Fail silently for analytics - don't break user flow
      print('Failed to record transaction: $e');
    }
  }

  Future<void> trackAction(
      String userId, String actionType, BuildContext context) async {
    final actionResponse = await supabase
        .from('actions_rewards')
        .select('points')
        .eq('action_type', actionType)
        .single();

    int pointsForAction = actionResponse['points'];
    final userRewards = await getUserRewards(userId);
    int newPoints = userRewards['points'] + pointsForAction;
    int newLevel = calculateLevel(newPoints);

    await updateUserRewards(userId, newPoints, userRewards['coins'], newLevel);
    await checkLevelUp(userId, context);
    await checkAchievements(userId);
  }

  // New method to track message sending and award points
  Future<void> trackMessageSent(String userId, BuildContext context) async {
    try {
      const pointsPerMessage = 2; // 2 points per message sent
      final userRewards = await getUserRewards(userId);
      
      // Update points and message count
      final newPoints = userRewards['points'] + pointsPerMessage;
      final newMessageCount = (userRewards['messages_sent'] ?? 0) + 1;
      final newLevel = calculateLevel(newPoints);
      
      // Update user rewards including message count
      await supabase.from('users_rewards').update({
        'points': newPoints,
        'level': newLevel,
        'messages_sent': newMessageCount,
      }).eq('user_id', userId);
      
      // Record transaction for points earned
      await _recordTransaction(
        userId: userId,
        type: 'points',
        amount: pointsPerMessage,
        source: 'message_sent',
        metadata: {'total_messages': newMessageCount},
      );
      
      // Check for level up
      await checkLevelUp(userId, context);
      
      // Check achievements (especially message-related ones)
      await checkAchievements(userId);
      
      // Clear cache
      _cache.removeWhere((key, value) => key.contains(userId));
    } catch (e) {
      // Fail silently to not interrupt messaging flow
      print('Failed to track message sent: $e');
    }
  }

  // Additional method to track other common activities for easier leveling
  Future<void> trackActivity(String userId, String activityType, BuildContext context, {int customPoints = 0}) async {
    try {
      int pointsToAward = customPoints;
      
      // Define points for different activities
      if (customPoints == 0) {
        switch (activityType) {
          case 'profile_update':
            pointsToAward = 10;
            break;
          case 'friend_added':
            pointsToAward = 5;
            break;
          case 'daily_check_in':
            pointsToAward = 15;
            break;
          case 'photo_shared':
            pointsToAward = 8;
            break;
          case 'group_joined':
            pointsToAward = 12;
            break;
          case 'content_liked':
            pointsToAward = 1;
            break;
          case 'comment_posted':
            pointsToAward = 3;
            break;
          default:
            pointsToAward = 1;
        }
      }
      
      final userRewards = await getUserRewards(userId);
      final newPoints = userRewards['points'] + pointsToAward;
      final newLevel = calculateLevel(newPoints);
      
      await updateUserRewards(userId, newPoints, userRewards['coins'], newLevel);
      
      // Record transaction
      await _recordTransaction(
        userId: userId,
        type: 'points',
        amount: pointsToAward,
        source: activityType,
        metadata: {'activity_type': activityType},
      );
      
      // Check for level up
      await checkLevelUp(userId, context);
      
      // Check achievements
      await checkAchievements(userId);
      
      // Clear cache
      _cache.removeWhere((key, value) => key.contains(userId));
    } catch (e) {
      print('Failed to track activity $activityType: $e');
    }
  }

  // =================== ENHANCED CURRENCY EARNING SYSTEM ===================
  
  // Daily spin wheel for coins (can be called once per day)
  Future<Map<String, dynamic>> claimDailySpinWheel(String userId, BuildContext context) async {
    try {
      final userRewards = await getUserRewards(userId);
      final lastSpin = userRewards['last_spin_wheel'];
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      DateTime? lastSpinDate;
      if (lastSpin != null) {
        final lastSpinDateTime = DateTime.parse(lastSpin);
        lastSpinDate = DateTime(lastSpinDateTime.year, lastSpinDateTime.month, lastSpinDateTime.day);
      }
      
      // Check if already spun today
      if (lastSpinDate != null && lastSpinDate.isAtSameMomentAs(today)) {
        return {
          'success': false,
          'error': 'Already spun today! Come back tomorrow.',
          'next_spin_in': Duration(days: 1),
        };
      }
      
      // Generate random reward (weighted)
      final random = math.Random();
      final roll = random.nextDouble();
      
      int coinsWon = 0;
      String prize = '';
      
      if (roll < 0.4) { // 40% chance
        coinsWon = 25 + random.nextInt(26); // 25-50 coins
        prize = 'Small Coin Pouch';
      } else if (roll < 0.7) { // 30% chance
        coinsWon = 75 + random.nextInt(51); // 75-125 coins
        prize = 'Medium Coin Bag';
      } else if (roll < 0.9) { // 20% chance
        coinsWon = 150 + random.nextInt(101); // 150-250 coins
        prize = 'Large Coin Chest';
      } else if (roll < 0.98) { // 8% chance
        coinsWon = 300 + random.nextInt(201); // 300-500 coins
        prize = 'Treasure Vault';
      } else { // 2% chance - JACKPOT!
        coinsWon = 1000 + random.nextInt(501); // 1000-1500 coins
        prize = '🎰 JACKPOT! 🎰';
      }
      
      // Award the coins
      final newCoins = userRewards['coins'] + coinsWon;
      await supabase.from('users_rewards').update({
        'coins': newCoins,
        'last_spin_wheel': now.toIso8601String(),
      }).eq('user_id', userId);
      
      // Record transaction
      await _recordTransaction(
        userId: userId,
        type: 'coins',
        amount: coinsWon,
        source: 'daily_spin_wheel',
        metadata: {'prize': prize, 'roll': roll},
      );
      
      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎰 $prize! You won $coinsWon coins! 🎰'),
            backgroundColor: roll >= 0.98 ? Colors.amber.shade600 : Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
      
      return {
        'success': true,
        'coins_won': coinsWon,
        'prize': prize,
        'is_jackpot': roll >= 0.98,
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Hourly mini-rewards (small amounts every hour)
  Future<Map<String, dynamic>> claimHourlyBonus(String userId, BuildContext context) async {
    try {
      final userRewards = await getUserRewards(userId);
      final lastHourly = userRewards['last_hourly_bonus'];
      final now = DateTime.now();
      
      if (lastHourly != null) {
        final lastHourlyTime = DateTime.parse(lastHourly);
        final timeDiff = now.difference(lastHourlyTime);
        
        if (timeDiff.inHours < 1) {
          final remainingMinutes = 60 - timeDiff.inMinutes;
          return {
            'success': false,
            'error': 'Next bonus in $remainingMinutes minutes',
            'next_bonus_in': Duration(minutes: remainingMinutes),
          };
        }
      }
      
      // Award 5-15 coins every hour
      final random = math.Random();
      final coinsWon = 5 + random.nextInt(11);
      
      final newCoins = userRewards['coins'] + coinsWon;
      await supabase.from('users_rewards').update({
        'coins': newCoins,
        'last_hourly_bonus': now.toIso8601String(),
      }).eq('user_id', userId);
      
      await _recordTransaction(
        userId: userId,
        type: 'coins',
        amount: coinsWon,
        source: 'hourly_bonus',
        metadata: {'timestamp': now.toIso8601String()},
      );
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⏰ Hourly bonus! +$coinsWon coins'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      return {'success': true, 'coins_won': coinsWon};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Complete mini-quests for bigger rewards
  Future<Map<String, dynamic>> completeQuest(String userId, String questId, BuildContext context) async {
    try {
      // Check if quest is already completed
      final completedQuest = await supabase
          .from('completed_quests')
          .select('id')
          .eq('user_id', userId)
          .eq('quest_id', questId)
          .maybeSingle();
      
      if (completedQuest != null) {
        return {'success': false, 'error': 'Quest already completed'};
      }
      
      // Get quest details
      final questData = await _getQuestReward(questId);
      final coinsReward = questData['coins'];
      final pointsReward = questData['points'];
      final questName = questData['name'];
      
      // Award rewards
      final userRewards = await getUserRewards(userId);
      final newCoins = userRewards['coins'] + coinsReward;
      final newPoints = userRewards['points'] + pointsReward;
      final newLevel = calculateLevel(newPoints);
      
      await updateUserRewards(userId, newPoints, newCoins, newLevel);
      
      // Mark quest as completed
      await supabase.from('completed_quests').insert({
        'user_id': userId,
        'quest_id': questId,
        'completed_at': DateTime.now().toIso8601String(),
      });
      
      await _recordTransaction(
        userId: userId,
        type: 'quest_completion',
        amount: coinsReward,
        source: 'quest',
        metadata: {'quest_id': questId, 'quest_name': questName, 'points_earned': pointsReward},
      );
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎯 Quest Complete: $questName!\n+$coinsReward coins, +$pointsReward points'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
      
      await checkLevelUp(userId, context);
      
      return {
        'success': true,
        'coins_won': coinsReward,
        'points_won': pointsReward,
        'quest_name': questName,
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Weekly challenges with bigger rewards
  Future<Map<String, dynamic>> claimWeeklyChallenge(String userId, String challengeType, BuildContext context) async {
    try {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekKey = '${weekStart.year}_${weekStart.month}_${weekStart.day}';
      
      // Check if already claimed this week
      final existingClaim = await supabase
          .from('weekly_challenges')
          .select('id')
          .eq('user_id', userId)
          .eq('challenge_type', challengeType)
          .eq('week_key', weekKey)
          .maybeSingle();
      
      if (existingClaim != null) {
        return {'success': false, 'error': 'Challenge already completed this week'};
      }
      
      // Get challenge requirements and check if met
      final challengeData = await _getWeeklyChallengeData(userId, challengeType);
      if (!challengeData['requirements_met']) {
        return {
          'success': false,
          'error': 'Requirements not met: ${challengeData['requirement_text']}',
          'progress': challengeData['progress'],
          'required': challengeData['required'],
        };
      }
      
      final coinsReward = challengeData['coins_reward'];
      final pointsReward = challengeData['points_reward'];
      
      // Award rewards
      final userRewards = await getUserRewards(userId);
      final newCoins = userRewards['coins'] + coinsReward;
      final newPoints = userRewards['points'] + pointsReward;
      final newLevel = calculateLevel(newPoints);
      
      await updateUserRewards(userId, newPoints, newCoins, newLevel);
      
      // Mark challenge as completed
      await supabase.from('weekly_challenges').insert({
        'user_id': userId,
        'challenge_type': challengeType,
        'week_key': weekKey,
        'completed_at': now.toIso8601String(),
      });
      
      await _recordTransaction(
        userId: userId,
        type: 'weekly_challenge',
        amount: coinsReward,
        source: 'weekly_challenge',
        metadata: {
          'challenge_type': challengeType,
          'week_key': weekKey,
          'points_earned': pointsReward,
        },
      );
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🏆 Weekly Challenge Complete!\n+$coinsReward coins, +$pointsReward points'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }
      
      await checkLevelUp(userId, context);
      
      return {
        'success': true,
        'coins_won': coinsReward,
        'points_won': pointsReward,
        'challenge_type': challengeType,
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Enhanced coin rewards for specific activities
  Future<void> awardActivityCoins(String userId, String activityType, BuildContext context, {int? customAmount}) async {
    try {
      int coinsToAward = customAmount ?? 0;
      
      // Define coin rewards for different activities
      if (customAmount == null) {
        switch (activityType) {
          case 'first_message_daily':
            coinsToAward = 10;
            break;
          case 'profile_photo_update':
            coinsToAward = 25;
            break;
          case 'friend_request_sent':
            coinsToAward = 5;
            break;
          case 'friend_request_accepted':
            coinsToAward = 15;
            break;
          case 'group_created':
            coinsToAward = 50;
            break;
          case 'event_attended':
            coinsToAward = 30;
            break;
          case 'pet_interaction':
            coinsToAward = 8;
            break;
          case 'tarot_reading_completed':
            coinsToAward = 20;
            break;
          case 'gem_discovered':
            coinsToAward = 40;
            break;
          case 'butterfly_caught':
            coinsToAward = 12;
            break;
          case 'home_decoration_placed':
            coinsToAward = 6;
            break;
          case 'perfect_mood_match':
            coinsToAward = 25;
            break;
          case 'streak_milestone':
            coinsToAward = 100;
            break;
          default:
            coinsToAward = 2;
        }
      }
      
      final userRewards = await getUserRewards(userId);
      final newCoins = userRewards['coins'] + coinsToAward;
      
      await supabase.from('users_rewards').update({
        'coins': newCoins,
      }).eq('user_id', userId);
      
      await _recordTransaction(
        userId: userId,
        type: 'coins',
        amount: coinsToAward,
        source: 'activity_reward',
        metadata: {'activity_type': activityType},
      );
      
      // Clear cache
      _cache.removeWhere((key, value) => key.contains(userId));
      
      // Show notification for bigger rewards
      if (coinsToAward >= 20 && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('💰 Activity bonus! +$coinsToAward coins'),
            backgroundColor: Colors.amber,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Failed to award activity coins: $e');
    }
  }

  // =================== HELPER METHODS FOR NEW SYSTEMS ===================

  // Get quest reward data
  Map<String, dynamic> _getQuestReward(String questId) {
    final quests = {
      'send_10_messages': {'name': 'Chatter', 'coins': 50, 'points': 25},
      'make_5_friends': {'name': 'Social Butterfly', 'coins': 100, 'points': 50},
      'update_profile': {'name': 'Profile Perfect', 'coins': 75, 'points': 30},
      'join_3_groups': {'name': 'Group Explorer', 'coins': 120, 'points': 60},
      'post_first_glitter': {'name': 'Glitter Newbie', 'coins': 60, 'points': 25},
      'get_10_likes': {'name': 'Popular Post', 'coins': 80, 'points': 40},
      'complete_tarot_reading': {'name': 'Fortune Seeker', 'coins': 90, 'points': 45},
      'discover_gem': {'name': 'Gem Hunter', 'coins': 150, 'points': 75},
      'decorate_home': {'name': 'Interior Designer', 'coins': 110, 'points': 55},
      'catch_butterfly': {'name': 'Nature Lover', 'coins': 70, 'points': 35},
      
      // New enhanced quests
      'send_100_messages': {'name': 'Chatty Champion', 'coins': 200, 'points': 100},
      'reach_level_10': {'name': 'Rising Star', 'coins': 300, 'points': 150},
      'spend_1000_coins': {'name': 'Big Spender', 'coins': 250, 'points': 125},
      'login_streak_7': {'name': 'Dedicated User', 'coins': 180, 'points': 90},
      'post_10_content': {'name': 'Content Creator', 'coins': 160, 'points': 80},
      'receive_50_likes': {'name': 'Influencer', 'coins': 220, 'points': 110},
      'complete_daily_spin_30': {'name': 'Lucky Spinner', 'coins': 400, 'points': 200},
      'collect_aura_10': {'name': 'Aura Collector', 'coins': 350, 'points': 175},
      'befriend_butterfly_5': {'name': 'Butterfly Whisperer', 'coins': 280, 'points': 140},
      'discover_all_gems': {'name': 'Gem Master', 'coins': 500, 'points': 250},
    };
    
    return quests[questId] ?? {'name': 'Unknown Quest', 'coins': 20, 'points': 10};
  }

  // Get weekly challenge data and check requirements
  Future<Map<String, dynamic>> _getWeeklyChallengeData(String userId, String challengeType) async {
    switch (challengeType) {
      case 'message_marathon':
        // Send 100 messages this week
        final messageCount = await _getWeeklyMessageCount(userId);
        return {
          'requirements_met': messageCount >= 100,
          'requirement_text': 'Send 100 messages this week',
          'progress': messageCount,
          'required': 100,
          'coins_reward': 500,
          'points_reward': 200,
        };
        
      case 'social_star':
        // Get 50 likes this week
        final likeCount = await _getWeeklyLikeCount(userId);
        return {
          'requirements_met': likeCount >= 50,
          'requirement_text': 'Receive 50 likes this week',
          'progress': likeCount,
          'required': 50,
          'coins_reward': 400,
          'points_reward': 150,
        };
        
      case 'content_creator':
        // Post 20 pieces of content this week
        final postCount = await _getWeeklyPostCount(userId);
        return {
          'requirements_met': postCount >= 20,
          'requirement_text': 'Create 20 posts this week',
          'progress': postCount,
          'required': 20,
          'coins_reward': 600,
          'points_reward': 250,
        };
        
      case 'level_climber':
        // Gain 2 levels this week
        final levelGain = await _getWeeklyLevelGain(userId);
        return {
          'requirements_met': levelGain >= 2,
          'requirement_text': 'Gain 2 levels this week',
          'progress': levelGain,
          'required': 2,
          'coins_reward': 800,
          'points_reward': 300,
        };
        
      default:
        return {
          'requirements_met': false,
          'requirement_text': 'Unknown challenge',
          'progress': 0,
          'required': 1,
          'coins_reward': 100,
          'points_reward': 50,
        };
    }
  }

  // Helper methods to check weekly stats
  Future<int> _getWeeklyMessageCount(String userId) async {
    final weekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
    try {
      final result = await supabase
          .from('reward_transactions')
          .select('amount')
          .eq('user_id', userId)
          .eq('source', 'message_sent')
          .gte('timestamp', weekStart.toIso8601String());
      return result.length;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _getWeeklyLikeCount(String userId) async {
    final weekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
    try {
      final result = await supabase
          .from('reward_transactions')
          .select('amount')
          .eq('user_id', userId)
          .eq('source', 'content_liked')
          .gte('timestamp', weekStart.toIso8601String());
      return result.length;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _getWeeklyPostCount(String userId) async {
    final weekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
    try {
      final result = await supabase
          .from('reward_transactions')
          .select('amount')
          .eq('user_id', userId)
          .eq('source', 'content_posted')
          .gte('timestamp', weekStart.toIso8601String());
      return result.length;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _getWeeklyLevelGain(String userId) async {
    final weekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
    try {
      final result = await supabase
          .from('reward_transactions')
          .select('amount')
          .eq('user_id', userId)
          .eq('source', 'level_up')
          .gte('timestamp', weekStart.toIso8601String());
      return result.length;
    } catch (e) {
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> getShopItemsByCategoryWithPagination(
    int categoryId,
    int page,
    int itemsPerPage,
  ) async {
    final response = await supabase
        .from('shop_items')
        .select()
        .eq('category_id', categoryId)
        .range((page - 1) * itemsPerPage, page * itemsPerPage - 1);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getShopItems(int categoryId) async {
    final response = await supabase
        .from('shop_items')
        .select()
        .eq('category_id', categoryId);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getShopItemsWithPagination(
    int page,
    int itemsPerPage,
  ) async {
    final response = await supabase
        .from('aura_items')
        .select('*')
        .range((page - 1) * itemsPerPage, page * itemsPerPage - 1);

    return List<Map<String, dynamic>>.from(response);
  }

  // Enhanced purchase system with validation and analytics
  Future<Map<String, dynamic>> purchaseItem(
      String userId, int itemId, BuildContext context) async {
    try {
      final userRewards = await getUserRewards(userId);
      final itemResponse = await supabase
          .from('shop_items')
          .select('*, stock_quantity, max_per_user, is_limited_time, expiry_date')
          .eq('id', itemId)
          .single();

      final item = itemResponse;
      
      // Validation checks
      final validationResult = await _validatePurchase(userId, item, userRewards);
      if (!validationResult['valid']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(validationResult['error']),
            backgroundColor: Colors.red,
          ),
        );
        return {'success': false, 'error': validationResult['error']};
      }

      // Check if user already owns this item
      final existingItem = await supabase
          .from('user_inventory')
          .select('id')
          .eq('user_id', userId)
          .eq('item_id', itemId)
          .maybeSingle();

      if (existingItem != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("You already own this item!")),
        );
        return {'success': false, 'error': 'Already owned'};
      }

      // Perform purchase transaction
      final purchaseResult = await _executePurchase(userId, item, userRewards);
      
      if (purchaseResult['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${item['name']} purchased successfully!"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Clear cache for user data
        _cache.removeWhere((key, value) => key.contains(userId));
        
        await checkAchievements(userId);
        await _updateUserPurchaseStats(userId, item['price']);
      }
      
      return purchaseResult;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Purchase failed: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
      return {'success': false, 'error': e.toString()};
    }
  }

  // Purchase validation
  Future<Map<String, dynamic>> _validatePurchase(
    String userId,
    Map<String, dynamic> item,
    Map<String, dynamic> userRewards,
  ) async {
    // Check if user has enough coins
    if (userRewards['coins'] < item['price']) {
      return {
        'valid': false,
        'error': 'Not enough coins! You need ${item['price'] - userRewards['coins']} more coins.'
      };
    }

    // Check stock quantity
    if (item['stock_quantity'] != null && item['stock_quantity'] <= 0) {
      return {'valid': false, 'error': 'This item is out of stock!'};
    }

    // Check if it's a limited time item and hasn't expired
    if (item['is_limited_time'] == true && item['expiry_date'] != null) {
      final expiryDate = DateTime.parse(item['expiry_date']);
      if (DateTime.now().isAfter(expiryDate)) {
        return {'valid': false, 'error': 'This limited-time item has expired!'};
      }
    }

    // Check max per user limit
    if (item['max_per_user'] != null) {
      final userPurchases = await supabase
          .from('user_inventory')
          .select('id')
          .eq('user_id', userId)
          .eq('item_id', item['id']);
      
      if (userPurchases.length >= item['max_per_user']) {
        return {
          'valid': false,
          'error': 'You\'ve reached the maximum purchase limit for this item!'
        };
      }
    }

    return {'valid': true};
  }

  // Execute the actual purchase
  Future<Map<String, dynamic>> _executePurchase(
    String userId,
    Map<String, dynamic> item,
    Map<String, dynamic> userRewards,
  ) async {
    try {
      // Start transaction-like operation
      final newCoins = userRewards['coins'] - item['price'];
      final pointsEarned = (item['price'] * 0.1).round(); // 10% of price as points
      final newPoints = userRewards['points'] + pointsEarned;
      final newLevel = calculateLevel(newPoints);
      
      // Update user rewards
      await supabase
          .from('users_rewards')
          .update({
            'coins': newCoins,
            'points': newPoints,
            'level': newLevel,
            'total_spent': (userRewards['total_spent'] ?? 0) + item['price'],
          })
          .eq('user_id', userId);

      // Add item to inventory
      await supabase
          .from('user_inventory')
          .insert({
            'user_id': userId,
            'item_id': item['id'],
            'purchased_at': DateTime.now().toIso8601String(),
            'purchase_price': item['price'],
            'source': 'shop',
          });

      // Update stock if applicable
      if (item['stock_quantity'] != null) {
        await supabase
            .from('shop_items')
            .update({'stock_quantity': item['stock_quantity'] - 1})
            .eq('id', item['id']);
      }

      // Record transaction
      await _recordTransaction(
        userId: userId,
        type: 'purchase',
        amount: -item['price'],
        itemId: item['id'].toString(),
        source: 'shop',
        metadata: {
          'item_name': item['name'],
          'category_id': item['category_id'],
          'points_earned': pointsEarned,
        },
      );

      // Record points earned
      if (pointsEarned > 0) {
        await _recordTransaction(
          userId: userId,
          type: 'points',
          amount: pointsEarned,
          source: 'purchase_bonus',
          metadata: {'purchase_amount': item['price']},
        );
      }

      return {
        'success': true,
        'points_earned': pointsEarned,
        'new_level': newLevel,
        'level_up': newLevel > userRewards['level'],
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Update user purchase statistics
  Future<void> _updateUserPurchaseStats(String userId, int amount) async {
    try {
      await supabase.rpc('increment_user_purchases', params: {
        'user_id': userId,
        'amount': amount,
      });
    } catch (e) {
      // Fail silently for stats
      print('Failed to update purchase stats: $e');
    }
  }

  // Get user inventory with enhanced details
  Future<List<Map<String, dynamic>>> getUserInventory(String userId) async {
    final cacheKey = 'user_inventory_$userId';
    final cached = _getCachedData<List<Map<String, dynamic>>>(cacheKey);
    if (cached != null) return cached;

    try {
      final response = await supabase
          .from('user_inventory')
          .select('''
            item_id,
            purchased_at,
            purchase_price,
            source,
            shop_items (
              id,
              name,
              description,
              price,
              image_url,
              category_id,
              rarity,
              accessory_type
            )
          ''')
          .eq('user_id', userId)
          .order('purchased_at', ascending: false);

      List<Map<String, dynamic>> inventoryItems = [];
      for (var inventoryItem in response) {
        final shopItem = inventoryItem['shop_items'];
        if (shopItem != null) {
          final itemData = Map<String, dynamic>.from(shopItem);
          itemData['type'] = _mapCategoryIdToType(itemData['category_id'] ?? 0);
          itemData['purchased_at'] = inventoryItem['purchased_at'];
          itemData['purchase_price'] = inventoryItem['purchase_price'];
          itemData['source'] = inventoryItem['source'];
          inventoryItems.add(itemData);
        }
      }

      _setCachedData(cacheKey, inventoryItems);
      return inventoryItems;
    } catch (e) {
      // Fallback to original method
      return await _getUserInventoryFallback(userId);
    }
  }

  // Fallback method for inventory
  Future<List<Map<String, dynamic>>> _getUserInventoryFallback(String userId) async {
    final response = await supabase
        .from('user_inventory')
        .select('item_id')
        .eq('user_id', userId);

    List<Map<String, dynamic>> inventoryItems = [];
    for (var inventoryItem in response) {
      final itemResponse = await supabase
          .from('shop_items')
          .select()
          .eq('id', inventoryItem['item_id'])
          .single();

      final itemData = itemResponse;
      itemData['type'] = _mapCategoryIdToType(itemData['category_id'] ?? 0);
      inventoryItems.add(itemData);
    }

    return inventoryItems;
  }

  // Get user statistics
  Future<UserStats> getUserStats(String userId) async {
    try {
      final transactions = await supabase
          .from('reward_transactions')
          .select('*')
          .eq('user_id', userId);

      final userRewards = await getUserRewards(userId);
      
      int totalPurchases = 0;
      int totalSpent = 0;
      Map<String, int> categoryPurchases = {};
      
      for (var transaction in transactions) {
        if (transaction['type'] == 'purchase') {
          totalPurchases++;
          totalSpent += (transaction['amount'] as int).abs();
          
          final metadata = transaction['metadata'] as Map<String, dynamic>?;
          if (metadata != null && metadata['category_id'] != null) {
            final categoryType = _mapCategoryIdToType(metadata['category_id']);
            categoryPurchases[categoryType] = (categoryPurchases[categoryType] ?? 0) + 1;
          }
        }
      }

      final favoriteCategory = categoryPurchases.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;

      return UserStats(
        totalPurchases: totalPurchases,
        totalSpent: totalSpent,
        achievementsUnlocked: userRewards['achievements_count'] ?? 0,
        levelUps: userRewards['level'] - 1,
        lastLogin: userRewards['last_login'] != null 
            ? DateTime.parse(userRewards['last_login']) 
            : null,
        loginStreak: userRewards['login_streak'] ?? 0,
        favoriteCategory: favoriteCategory,
        averageSessionTime: 15.0, // TODO: Implement session tracking
      );
    } catch (e) {
      // Return default stats
      return UserStats(
        totalPurchases: 0,
        totalSpent: 0,
        achievementsUnlocked: 0,
        levelUps: 0,
        loginStreak: 0,
        favoriteCategory: 'unknown',
        averageSessionTime: 0.0,
      );
    }
  }

  // Get transaction history
  Future<List<RewardTransaction>> getTransactionHistory(String userId, {int limit = 50}) async {
    try {
      final response = await supabase
          .from('reward_transactions')
          .select('*')
          .eq('user_id', userId)
          .order('timestamp', ascending: false)
          .limit(limit);

      return response.map<RewardTransaction>((json) => RewardTransaction.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  // Generate personalized recommendations
  Future<List<Map<String, dynamic>>> getPersonalizedRecommendations(String userId) async {
    try {
      final userStats = await getUserStats(userId);
      final userRewards = await getUserRewards(userId);
      final inventory = await getUserInventory(userId);
      final ownedItemIds = inventory.map((item) => item['id']).toSet();

      // Get items from favorite category that user doesn't own
      final favoriteCategory = userStats.favoriteCategory;
      final categoryId = _getCategoryIdFromType(favoriteCategory);
      
      final recommendations = await supabase
          .from('shop_items')
          .select('*')
          .eq('category_id', categoryId)
          .lte('price', userRewards['coins'])
          .limit(5);

      // Filter out owned items
      final filteredRecommendations = recommendations
          .where((item) => !ownedItemIds.contains(item['id']))
          .toList();

      // If not enough from favorite category, add some popular items
      if (filteredRecommendations.length < 3) {
        final popularItems = await supabase
            .from('shop_items')
            .select('*')
            .lte('price', userRewards['coins'])
            .order('purchase_count', ascending: false)
            .limit(10);

        for (var item in popularItems) {
          if (!ownedItemIds.contains(item['id']) && 
              !filteredRecommendations.any((rec) => rec['id'] == item['id'])) {
            filteredRecommendations.add(item);
            if (filteredRecommendations.length >= 5) break;
          }
        }
      }

      return filteredRecommendations;
    } catch (e) {
      return [];
    }
  }

  // Helper method to get category ID from type
  int _getCategoryIdFromType(String type) {
    switch (type) {
      case 'aura': return 1;
      case 'background': return 2;
      case 'pet_accessory': return 3;
      case 'emote': return 4;
      case 'badge': return 5;
      case 'decoration': return 6;
      case 'booster_pack': return 7;
      case 'theme': return 8;
      case 'effect': return 9;
      case 'sound_pack': return 10;
      default: return 1;
    }
  }

  // Apply discount codes
  Future<Map<String, dynamic>> applyDiscountCode(String userId, String code) async {
    try {
      final discount = await supabase
          .from('discount_codes')
          .select('*')
          .eq('code', code.toUpperCase())
          .eq('is_active', true)
          .single();

      // Check if code is still valid
      if (discount['expiry_date'] != null) {
        final expiryDate = DateTime.parse(discount['expiry_date']);
        if (DateTime.now().isAfter(expiryDate)) {
          return {'success': false, 'error': 'This discount code has expired.'};
        }
      }

      // Check usage limit
      if (discount['usage_limit'] != null) {
        final usageCount = await supabase
            .from('discount_usage')
            .select('id')
            .eq('code_id', discount['id']);
        
        if (usageCount.length >= discount['usage_limit']) {
          return {'success': false, 'error': 'This discount code has reached its usage limit.'};
        }
      }

      // Check if user already used this code
      final userUsage = await supabase
          .from('discount_usage')
          .select('id')
          .eq('code_id', discount['id'])
          .eq('user_id', userId)
          .maybeSingle();

      if (userUsage != null && !discount['allow_multiple_use']) {
        return {'success': false, 'error': 'You have already used this discount code.'};
      }

      // Apply the discount
      final userRewards = await getUserRewards(userId);
      final rewardAmount = discount['reward_amount'] ?? 0;
      final rewardType = discount['reward_type'] ?? 'coins';

      if (rewardType == 'coins') {
        await supabase
            .from('users_rewards')
            .update({'coins': userRewards['coins'] + rewardAmount})
            .eq('user_id', userId);
      } else if (rewardType == 'points') {
        final newPoints = userRewards['points'] + rewardAmount;
        final newLevel = calculateLevel(newPoints);
        await updateUserRewards(userId, newPoints, userRewards['coins'], newLevel);
      }

      // Record usage
      await supabase.from('discount_usage').insert({
        'code_id': discount['id'],
        'user_id': userId,
        'used_at': DateTime.now().toIso8601String(),
      });

      // Record transaction
      await _recordTransaction(
        userId: userId,
        type: rewardType,
        amount: rewardAmount,
        source: 'discount_code',
        metadata: {'code': code, 'discount_name': discount['name']},
      );

      return {
        'success': true,
        'reward_type': rewardType,
        'reward_amount': rewardAmount,
        'message': 'Discount code applied successfully!',
      };
    } catch (e) {
      return {'success': false, 'error': 'Invalid discount code.'};
    }
  }

  // Enhanced achievements system with dynamic conditions
  Future<void> checkAchievements(String userId) async {
    final userRewards = await getUserRewards(userId);
    final userStats = await getUserStats(userId);

    final achievementsResponse = await supabase
        .from('achievements')
        .select('*')
        .eq('unlocked', false);

    for (var achievement in achievementsResponse) {
      bool conditionMet = await _checkCondition(
        achievement['condition'], 
        userRewards, 
        userStats,
      );

      if (conditionMet) {
        await supabase
            .from('achievements')
            .update({'unlocked': true, 'unlocked_at': DateTime.now().toIso8601String()})
            .eq('id', achievement['id']);

        await _rewardUser(userId, achievement);
        
        // Update achievements count
        await supabase
            .from('users_rewards')
            .update({'achievements_count': (userRewards['achievements_count'] ?? 0) + 1})
            .eq('user_id', userId);
      }
    }
  }

  // Enhanced condition checking
  Future<bool> _checkCondition(
    String condition, 
    Map<String, dynamic> userRewards,
    UserStats userStats,
  ) async {
    final parts = condition.split('_');
    
    switch (parts[0]) {
      case 'send':
        if (parts[1] == 'messages' && parts.length > 2) {
          final required = int.tryParse(parts[2]) ?? 0;
          return (userRewards['messages_sent'] ?? 0) >= required;
        }
        break;
        
      case 'reach':
        if (parts[1] == 'level' && parts.length > 2) {
          final required = int.tryParse(parts[2]) ?? 0;
          return userRewards['level'] >= required;
        }
        break;
        
      case 'spend':
        if (parts[1] == 'coins' && parts.length > 2) {
          final required = int.tryParse(parts[2]) ?? 0;
          return userStats.totalSpent >= required;
        }
        break;
        
      case 'login':
        if (parts[1] == 'streak' && parts.length > 2) {
          final required = int.tryParse(parts[2]) ?? 0;
          return userStats.loginStreak >= required;
        }
        break;
        
      case 'purchase':
        if (parts[1] == 'items' && parts.length > 2) {
          final required = int.tryParse(parts[2]) ?? 0;
          return userStats.totalPurchases >= required;
        }
        break;
        
      case 'collect':
        if (parts[1] == 'category' && parts.length > 3) {
          final category = parts[2];
          final required = int.tryParse(parts[3]) ?? 0;
          // Check how many items from a specific category the user owns
          final inventory = await getUserInventory(userRewards['user_id']);
          final categoryItems = inventory.where((item) => item['type'] == category).length;
          return categoryItems >= required;
        }
        break;
        
      case 'earn':
        if (parts[1] == 'points' && parts.length > 2) {
          final required = int.tryParse(parts[2]) ?? 0;
          return (userRewards['points'] ?? 0) >= required;
        }
        break;
    }
    
    // Legacy conditions for backward compatibility
    if (condition == "send_100_messages") {
      return (userRewards['messages_sent'] ?? 0) >= 100;
    }
    if (condition == "send_500_messages") {
      return (userRewards['messages_sent'] ?? 0) >= 500;
    }
    if (condition == "send_1000_messages") {
      return (userRewards['messages_sent'] ?? 0) >= 1000;
    }
    if (condition == "reach_level_10") {
      return userRewards['level'] >= 10;
    }
    if (condition == "reach_level_25") {
      return userRewards['level'] >= 25;
    }
    if (condition == "reach_level_50") {
      return userRewards['level'] >= 50;
    }
    if (condition == "earn_points_1000") {
      return (userRewards['points'] ?? 0) >= 1000;
    }
    if (condition == "earn_points_5000") {
      return (userRewards['points'] ?? 0) >= 5000;
    }
    
    return false;
  }

  // Enhanced reward system
  Future<void> _rewardUser(String userId, Map<String, dynamic> achievement) async {
    final rewardType = achievement['reward_type'];
    final rewardValue = achievement['reward_value'];
    final itemId = achievement['item_id'];

    if (rewardType == 'coins') {
      final userRewards = await getUserRewards(userId);
      await updateUserRewards(
        userId, 
        userRewards['points'],
        userRewards['coins'] + rewardValue, 
        userRewards['level'],
      );
      
      await _recordTransaction(
        userId: userId,
        type: 'coins',
        amount: rewardValue,
        source: 'achievement',
        metadata: {
          'achievement_id': achievement['id'],
          'achievement_name': achievement['name'],
        },
      );
      
      print("Achievement Unlocked! You received $rewardValue coins!");
    } else if (rewardType == 'points') {
      final userRewards = await getUserRewards(userId);
      final newPoints = userRewards['points'] + rewardValue;
      final newLevel = calculateLevel(newPoints);
      
      await updateUserRewards(userId, newPoints, userRewards['coins'], newLevel);
      
      await _recordTransaction(
        userId: userId,
        type: 'points',
        amount: rewardValue,
        source: 'achievement',
        metadata: {
          'achievement_id': achievement['id'],
          'achievement_name': achievement['name'],
        },
      );
      
      print("Achievement Unlocked! You received $rewardValue points!");
    } else if (rewardType == 'items' && itemId != null) {
      await supabase
          .from('user_inventory')
          .insert({
            'user_id': userId, 
            'item_id': itemId,
            'source': 'achievement',
            'purchased_at': DateTime.now().toIso8601String(),
          });
      
      await _recordTransaction(
        userId: userId,
        type: 'item',
        amount: 1,
        itemId: itemId.toString(),
        source: 'achievement',
        metadata: {
          'achievement_id': achievement['id'],
          'achievement_name': achievement['name'],
        },
      );
      
      print("Achievement Unlocked! You received a new item!");
    }

    print("Achievement unlocked: ${achievement['name']}! Reward: $rewardValue $rewardType");
  }

  // Enhanced level up checking with better rewards
  Future<void> checkLevelUp(String userId, BuildContext context) async {
    final userRewards = await getUserRewards(userId);
    final newLevel = calculateLevel(userRewards['points']);

    if (newLevel > userRewards['level']) {
      // Calculate level up rewards - Progressive rewards: 100, 200, 300, etc.
      final coinReward = newLevel * 100; // 100 coins per level
      final bonusPoints = newLevel >= 10 ? 50 : 0; // Bonus for reaching level 10+
      
      await supabase
          .from('users_rewards')
          .update({
            'level': newLevel,
            'coins': userRewards['coins'] + coinReward,
          })
          .eq('user_id', userId);
      
      // Record level up transaction
      await _recordTransaction(
        userId: userId,
        type: 'coins',
        amount: coinReward,
        source: 'level_up',
        metadata: {'new_level': newLevel, 'old_level': userRewards['level']},
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("🎉 Level Up! Welcome to Level $newLevel! 🎉"),
              Text("You earned $coinReward coins!"),
              if (bonusPoints > 0) Text("Bonus: $bonusPoints points!"),
            ],
          ),
          backgroundColor: Colors.purple.shade400,
          duration: Duration(seconds: 4),
        ),
      );
      
      // Clear cache
      _cache.removeWhere((key, value) => key.contains(userId));
    }
  }

  // Gift items to users (admin function)
  Future<bool> giftItemToUser(
    String targetUserId, 
    int itemId, 
    String reason, 
    {String? fromUserId}
  ) async {
    try {
      await supabase.from('user_inventory').insert({
        'user_id': targetUserId,
        'item_id': itemId,
        'source': 'gift',
        'purchased_at': DateTime.now().toIso8601String(),
      });
      
      await _recordTransaction(
        userId: targetUserId,
        type: 'item',
        amount: 1,
        itemId: itemId.toString(),
        source: 'gift',
        metadata: {
          'reason': reason,
          'from_user_id': fromUserId,
        },
      );
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get leaderboard
  Future<List<Map<String, dynamic>>> getLeaderboard({
    String sortBy = 'level',
    int limit = 100,
  }) async {
    try {
      String orderBy = sortBy;
      if (sortBy == 'level') orderBy = 'level';
      else if (sortBy == 'points') orderBy = 'points';
      else if (sortBy == 'coins') orderBy = 'coins';
      
      final response = await supabase
          .from('users_rewards')
          .select('''
            user_id,
            level,
            points,
            coins,
            login_streak,
            achievements_count,
            users (username, avatar_url)
          ''')
          .order(orderBy, ascending: false)
          .limit(limit);

      return response;
    } catch (e) {
      return [];
    }
  }

  // Handle booster pack purchases - give items from the associated category
  Future<void> purchaseBoosterPack(
    String userId, 
    Map<String, dynamic> boosterItem, 
    BuildContext context
  ) async {
    try {
      final categoryReferenceId = boosterItem['category_reference_id'];
      if (categoryReferenceId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid booster pack!")),
        );
        return;
      }

      // Get items from the referenced category
      final items = await supabase
          .from('shop_items')
          .select('*')
          .eq('category_id', categoryReferenceId)
          .neq('category_id', 7); // Exclude other booster packs

      if (items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No items available in this category!")),
        );
        return;
      }

      // Shuffle and give 1-3 random items
      final shuffledItems = List<Map<String, dynamic>>.from(items);
      shuffledItems.shuffle();
      final itemsToGive = shuffledItems.take(3).toList();

      // Add items to user's inventory
      for (final item in itemsToGive) {
        await supabase.from('user_inventory').upsert({
          'user_id': userId,
          'item_id': item['id'],
          'quantity': 1,
          'obtained_from': 'booster_pack',
          'obtained_at': DateTime.now().toIso8601String(),
        });
      }

      // Show success message with items received
      final itemNames = itemsToGive.map((item) => item['name']).join(', ');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Booster pack opened! You received: $itemNames"),
          duration: const Duration(seconds: 4),
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error opening booster pack: $e")),
      );
    }
  }

  // Achievement System Methods
  Future<List<Map<String, dynamic>>> getAvailableAchievements() async {
    try {
      final cacheKey = 'available_achievements';
      if (_cache.containsKey(cacheKey) && !_cache[cacheKey]!.isExpired) {
        return _cache[cacheKey]!.data;
      }

      final response = await supabase
          .from('achievements')
          .select('*')
          .order('category')
          .order('target_value');

      final achievements = List<Map<String, dynamic>>.from(response);
      _cache[cacheKey] = _CacheEntry(achievements);
      
      return achievements;
    } catch (e) {
      debugPrint('Error fetching achievements: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getUserAchievementProgress(String userId) async {
    try {
      final cacheKey = 'user_achievement_progress_$userId';
      if (_cache.containsKey(cacheKey) && !_cache[cacheKey]!.isExpired) {
        return _cache[cacheKey]!.data;
      }

      final response = await supabase
          .from('user_achievements')
          .select('*')
          .eq('user_id', userId);

      // Convert list to map with achievement_id as key
      final progressMap = <String, dynamic>{};
      for (final achievement in response) {
        progressMap[achievement['achievement_id'].toString()] = {
          'completed': achievement['completed'] ?? false,
          'progress': achievement['progress'] ?? 0.0,
          'current_value': achievement['current_value'] ?? 0,
          'completed_at': achievement['completed_at'],
        };
      }

      _cache[cacheKey] = _CacheEntry(progressMap);
      return progressMap;
    } catch (e) {
      debugPrint('Error fetching user achievement progress: $e');
      return {};
    }
  }

  Future<bool> updateAchievementProgress(
    String userId, 
    String achievementId, 
    int newValue,
  ) async {
    try {
      // Get achievement details
      final achievementResponse = await supabase
          .from('achievements')
          .select('target_value, reward_coins, reward_points')
          .eq('id', achievementId)
          .single();

      final targetValue = achievementResponse['target_value'];
      final isCompleted = newValue >= targetValue;
      final progress = targetValue > 0 ? (newValue / targetValue).clamp(0.0, 1.0) : 0.0;

      // Update user achievement progress
      await supabase
          .from('user_achievements')
          .upsert({
            'user_id': userId,
            'achievement_id': achievementId,
            'current_value': newValue,
            'progress': progress,
            'completed': isCompleted,
            'completed_at': isCompleted ? DateTime.now().toIso8601String() : null,
          });

      // If completed, award rewards
      if (isCompleted) {
        final rewardCoins = achievementResponse['reward_coins'] ?? 0;
        final rewardPoints = achievementResponse['reward_points'] ?? 0;

        if (rewardCoins > 0 || rewardPoints > 0) {
          // Get current user rewards
          final currentRewards = await getUserRewards(userId);
          final newCoins = (currentRewards['coins'] ?? 0) + rewardCoins;
          final newPoints = (currentRewards['points'] ?? 0) + rewardPoints;
          final newLevel = _calculateLevel(newPoints);
          
          await updateUserRewards(userId, newPoints, newCoins, newLevel);
        }

        // Record achievement transaction
        await _recordTransaction(
          userId: userId,
          type: 'achievement',
          amount: 1,
          source: 'achievement_completion',
          metadata: {
            'achievement_id': achievementId,
            'reward_coins': rewardCoins,
            'reward_points': rewardPoints,
          },
        );
      }

      // Clear cache
      _cache.removeWhere((key, value) => key.startsWith('user_achievement_progress_'));
      
      return isCompleted;
    } catch (e) {
      debugPrint('Error updating achievement progress: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getUserCompletedAchievements(String userId) async {
    try {
      final response = await supabase
          .from('user_achievements')
          .select('''
            *,
            achievements (
              name,
              description,
              category,
              reward_coins,
              reward_points
            )
          ''')
          .eq('user_id', userId)
          .eq('completed', true)
          .order('completed_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching completed achievements: $e');
      return [];
    }
  }

  Future<Map<String, int>> getAchievementStats(String userId) async {
    try {
      final allAchievements = await getAvailableAchievements();
      final userProgress = await getUserAchievementProgress(userId);
      
      final totalAchievements = allAchievements.length;
      final completedAchievements = userProgress.values
          .where((progress) => progress['completed'] == true)
          .length;
      
      final completionRate = totalAchievements > 0 
          ? ((completedAchievements / totalAchievements) * 100).round()
          : 0;

      return {
        'total': totalAchievements,
        'completed': completedAchievements,
        'completion_rate': completionRate,
      };
    } catch (e) {
      debugPrint('Error calculating achievement stats: $e');
      return {
        'total': 0,
        'completed': 0,
        'completion_rate': 0,
      };
    }
  }

  // Helper method to check and update common achievements
  Future<void> checkCommonAchievements(String userId, String action, {int value = 1}) async {
    try {
      final achievements = await getAvailableAchievements();
      
      for (final achievement in achievements) {
        final condition = achievement['condition'];
        if (condition != null && condition.contains(action)) {
          final currentProgress = await getUserAchievementProgress(userId);
          final currentValue = currentProgress[achievement['id'].toString()]?['current_value'] ?? 0;
          
          await updateAchievementProgress(
            userId, 
            achievement['id'].toString(), 
            currentValue + value,
          );
        }
      }
    } catch (e) {
      debugPrint('Error checking common achievements: $e');
    }
  }

  // Helper method to calculate level from points
  int _calculateLevel(int points) {
    return (points / 200).floor() + 1;
  }

  // Initialize comprehensive achievement system
  Future<void> initializeAchievements() async {
    final achievements = [
      // === SOCIAL ACHIEVEMENTS ===
      {
        'id': 'first_friend',
        'name': 'Making Friends',
        'description': 'Add your first friend',
        'category': 'Social',
        'condition': 'make_friends_1',
        'target_value': 1,
        'reward_coins': 50,
        'reward_points': 25,
        'icon': 'people',
        'rarity': 'common',
      },
      {
        'id': 'social_butterfly',
        'name': 'Social Butterfly',
        'description': 'Add 10 friends',
        'category': 'Social', 
        'condition': 'make_friends_10',
        'target_value': 10,
        'reward_coins': 200,
        'reward_points': 100,
        'icon': 'groups',
        'rarity': 'uncommon',
      },
      {
        'id': 'popular_user',
        'name': 'Popular User',
        'description': 'Have 25 friends',
        'category': 'Social',
        'condition': 'make_friends_25',
        'target_value': 25,
        'reward_coins': 500,
        'reward_points': 250,
        'icon': 'star',
        'rarity': 'rare',
      },
      {
        'id': 'community_leader',
        'name': 'Community Leader',
        'description': 'Have 50 friends',
        'category': 'Social',
        'condition': 'make_friends_50',
        'target_value': 50,
        'reward_coins': 1000,
        'reward_points': 500,
        'icon': 'emoji_events',
        'rarity': 'epic',
      },

      // === MESSAGING ACHIEVEMENTS ===
      {
        'id': 'first_message',
        'name': 'Breaking the Ice',
        'description': 'Send your first message',
        'category': 'Social',
        'condition': 'send_messages_1',
        'target_value': 1,
        'reward_coins': 25,
        'reward_points': 10,
        'icon': 'chat',
        'rarity': 'common',
      },
      {
        'id': 'chatty',
        'name': 'Chatty',
        'description': 'Send 50 messages',
        'category': 'Social',
        'condition': 'send_messages_50',
        'target_value': 50,
        'reward_coins': 100,
        'reward_points': 50,
        'icon': 'chat_bubble',
        'rarity': 'common',
      },
      {
        'id': 'chatter',
        'name': 'Chatter',
        'description': 'Send 100 messages',
        'category': 'Social',
        'condition': 'send_messages_100',
        'target_value': 100,
        'reward_coins': 200,
        'reward_points': 100,
        'icon': 'forum',
        'rarity': 'uncommon',
      },
      {
        'id': 'conversation_master',
        'name': 'Conversation Master',
        'description': 'Send 500 messages',
        'category': 'Social',
        'condition': 'send_messages_500',
        'target_value': 500,
        'reward_coins': 750,
        'reward_points': 375,
        'icon': 'record_voice_over',
        'rarity': 'rare',
      },
      {
        'id': 'communication_legend',
        'name': 'Communication Legend',
        'description': 'Send 1000 messages',
        'category': 'Social',
        'condition': 'send_messages_1000',
        'target_value': 1000,
        'reward_coins': 1500,
        'reward_points': 750,
        'icon': 'speaker_phone',
        'rarity': 'epic',
      },

      // === LEVEL PROGRESSION ACHIEVEMENTS ===
      {
        'id': 'level_up_first',
        'name': 'First Steps',
        'description': 'Reach level 2',
        'category': 'Progress',
        'condition': 'reach_level_2',
        'target_value': 2,
        'reward_coins': 75,
        'reward_points': 35,
        'icon': 'trending_up',
        'rarity': 'common',
      },
      {
        'id': 'rising_star',
        'name': 'Rising Star',
        'description': 'Reach level 10',
        'category': 'Progress',
        'condition': 'reach_level_10',
        'target_value': 10,
        'reward_coins': 300,
        'reward_points': 150,
        'icon': 'star_border',
        'rarity': 'uncommon',
      },
      {
        'id': 'experienced_user',
        'name': 'Experienced User',
        'description': 'Reach level 25',
        'category': 'Progress',
        'condition': 'reach_level_25',
        'target_value': 25,
        'reward_coins': 750,
        'reward_points': 375,
        'icon': 'star_half',
        'rarity': 'rare',
      },
      {
        'id': 'expert_user',
        'name': 'Expert User',
        'description': 'Reach level 50',
        'category': 'Progress',
        'condition': 'reach_level_50',
        'target_value': 50,
        'reward_coins': 1500,
        'reward_points': 750,
        'icon': 'star',
        'rarity': 'epic',
      },
      {
        'id': 'legendary_user',
        'name': 'Legendary User',
        'description': 'Reach level 100',
        'category': 'Progress',
        'condition': 'reach_level_100',
        'target_value': 100,
        'reward_coins': 5000,
        'reward_points': 2500,
        'icon': 'emoji_events',
        'rarity': 'legendary',
      },

      // === CONTENT CREATION ACHIEVEMENTS ===
      {
        'id': 'first_post',
        'name': 'Content Creator',
        'description': 'Post your first glitter board content',
        'category': 'Gaming',
        'condition': 'post_content_1',
        'target_value': 1,
        'reward_coins': 60,
        'reward_points': 30,
        'icon': 'create',
        'rarity': 'common',
      },
      {
        'id': 'regular_poster',
        'name': 'Regular Poster',
        'description': 'Post 10 pieces of content',
        'category': 'Gaming',
        'condition': 'post_content_10',
        'target_value': 10,
        'reward_coins': 300,
        'reward_points': 150,
        'icon': 'edit',
        'rarity': 'uncommon',
      },
      {
        'id': 'content_machine',
        'name': 'Content Machine',
        'description': 'Post 50 pieces of content',
        'category': 'Gaming',
        'condition': 'post_content_50',
        'target_value': 50,
        'reward_coins': 1000,
        'reward_points': 500,
        'icon': 'auto_awesome',
        'rarity': 'rare',
      },
      {
        'id': 'viral_creator',
        'name': 'Viral Creator',
        'description': 'Get 100 total likes on your posts',
        'category': 'Gaming',
        'condition': 'receive_likes_100',
        'target_value': 100,
        'reward_coins': 800,
        'reward_points': 400,
        'icon': 'thumb_up',
        'rarity': 'rare',
      },

      // === COLLECTING ACHIEVEMENTS ===
      {
        'id': 'first_purchase',
        'name': 'First Purchase',
        'description': 'Buy your first item from the shop',
        'category': 'Collecting',
        'condition': 'purchase_items_1',
        'target_value': 1,
        'reward_coins': 100,
        'reward_points': 50,
        'icon': 'shopping_cart',
        'rarity': 'common',
      },
      {
        'id': 'collector',
        'name': 'Collector',
        'description': 'Purchase 10 items',
        'category': 'Collecting',
        'condition': 'purchase_items_10',
        'target_value': 10,
        'reward_coins': 400,
        'reward_points': 200,
        'icon': 'collections',
        'rarity': 'uncommon',
      },
      {
        'id': 'shopaholic',
        'name': 'Shopaholic',
        'description': 'Purchase 25 items',
        'category': 'Collecting',
        'condition': 'purchase_items_25',
        'target_value': 25,
        'reward_coins': 1000,
        'reward_points': 500,
        'icon': 'shopping_bag',
        'rarity': 'rare',
      },
      {
        'id': 'aura_collector',
        'name': 'Aura Collector',
        'description': 'Collect 5 different auras',
        'category': 'Collecting',
        'condition': 'collect_category_aura_5',
        'target_value': 5,
        'reward_coins': 350,
        'reward_points': 175,
        'icon': 'auto_awesome',
        'rarity': 'uncommon',
      },
      {
        'id': 'pet_lover',
        'name': 'Pet Lover',
        'description': 'Collect 3 different pets',
        'category': 'Collecting',
        'condition': 'collect_category_pet_3',
        'target_value': 3,
        'reward_coins': 500,
        'reward_points': 250,
        'icon': 'pets',
        'rarity': 'rare',
      },

      // === SPECIAL/ACTIVITY ACHIEVEMENTS ===
      {
        'id': 'daily_user',
        'name': 'Daily User',
        'description': 'Login for 7 consecutive days',
        'category': 'Special',
        'condition': 'login_streak_7',
        'target_value': 7,
        'reward_coins': 350,
        'reward_points': 175,
        'icon': 'calendar_today',
        'rarity': 'uncommon',
      },
      {
        'id': 'dedicated_user',
        'name': 'Dedicated User',
        'description': 'Login for 30 consecutive days',
        'category': 'Special',
        'condition': 'login_streak_30',
        'target_value': 30,
        'reward_coins': 1200,
        'reward_points': 600,
        'icon': 'event_available',
        'rarity': 'epic',
      },
      {
        'id': 'fortune_seeker',
        'name': 'Fortune Seeker',
        'description': 'Complete your first tarot reading',
        'category': 'Gaming',
        'condition': 'tarot_readings_1',
        'target_value': 1,
        'reward_coins': 90,
        'reward_points': 45,
        'icon': 'auto_fix_high',
        'rarity': 'common',
      },
      {
        'id': 'mystic_reader',
        'name': 'Mystic Reader',
        'description': 'Complete 10 tarot readings',
        'category': 'Gaming',
        'condition': 'tarot_readings_10',
        'target_value': 10,
        'reward_coins': 450,
        'reward_points': 225,
        'icon': 'psychology',
        'rarity': 'uncommon',
      },
      {
        'id': 'gem_hunter',
        'name': 'Gem Hunter',
        'description': 'Discover your first gem',
        'category': 'Gaming',
        'condition': 'discover_gems_1',
        'target_value': 1,
        'reward_coins': 150,
        'reward_points': 75,
        'icon': 'diamond',
        'rarity': 'uncommon',
      },
      {
        'id': 'gem_master',
        'name': 'Gem Master',
        'description': 'Discover 10 different gems',
        'category': 'Gaming',
        'condition': 'discover_gems_10',
        'target_value': 10,
        'reward_coins': 800,
        'reward_points': 400,
        'icon': 'local_fire_department',
        'rarity': 'rare',
      },
      {
        'id': 'butterfly_whisperer',
        'name': 'Butterfly Whisperer',
        'description': 'Catch 5 different butterflies',
        'category': 'Gaming',
        'condition': 'catch_butterflies_5',
        'target_value': 5,
        'reward_coins': 280,
        'reward_points': 140,
        'icon': 'flutter_dash',
        'rarity': 'uncommon',
      },
      {
        'id': 'interior_designer',
        'name': 'Interior Designer',
        'description': 'Place 10 decorations in your home',
        'category': 'Gaming',
        'condition': 'home_decorations_10',
        'target_value': 10,
        'reward_coins': 400,
        'reward_points': 200,
        'icon': 'home',
        'rarity': 'uncommon',
      },

      // === SPENDING ACHIEVEMENTS ===
      {
        'id': 'big_spender',
        'name': 'Big Spender',
        'description': 'Spend 1000 coins in the shop',
        'category': 'Progress',
        'condition': 'spend_coins_1000',
        'target_value': 1000,
        'reward_coins': 250,
        'reward_points': 125,
        'icon': 'monetization_on',
        'rarity': 'uncommon',
      },
      {
        'id': 'high_roller',
        'name': 'High Roller',
        'description': 'Spend 5000 coins in the shop',
        'category': 'Progress',
        'condition': 'spend_coins_5000',
        'target_value': 5000,
        'reward_coins': 1000,
        'reward_points': 500,
        'icon': 'savings',
        'rarity': 'rare',
      },

      // === POINT EARNING ACHIEVEMENTS ===
      {
        'id': 'point_collector',
        'name': 'Point Collector',
        'description': 'Earn 1000 total points',
        'category': 'Progress',
        'condition': 'earn_points_1000',
        'target_value': 1000,
        'reward_coins': 300,
        'reward_points': 150,
        'icon': 'stars',
        'rarity': 'uncommon',
      },
      {
        'id': 'point_master',
        'name': 'Point Master',
        'description': 'Earn 5000 total points',
        'category': 'Progress',
        'condition': 'earn_points_5000',
        'target_value': 5000,
        'reward_coins': 1200,
        'reward_points': 600,
        'icon': 'grade',
        'rarity': 'rare',
      },

      // === SPECIAL MILESTONE ACHIEVEMENTS ===
      {
        'id': 'early_adopter',
        'name': 'Early Adopter',
        'description': 'Join during the first month',
        'category': 'Special',
        'condition': 'early_adopter',
        'target_value': 1,
        'reward_coins': 500,
        'reward_points': 250,
        'icon': 'verified',
        'rarity': 'legendary',
      },
      {
        'id': 'perfectionist',
        'name': 'Perfectionist',
        'description': 'Complete all other achievements',
        'category': 'Special',
        'condition': 'complete_all_achievements',
        'target_value': 1,
        'reward_coins': 10000,
        'reward_points': 5000,
        'icon': 'workspace_premium',
        'rarity': 'legendary',
      },

      // === ENHANCED SOCIAL ACHIEVEMENTS ===
      {
        'id': 'super_social',
        'name': 'Super Social',
        'description': 'Have 100 friends',
        'category': 'Social',
        'condition': 'make_friends_100',
        'target_value': 100,
        'reward_coins': 2500,
        'reward_points': 1500,
        'icon': 'diversity_3',
        'rarity': 'legendary',
      },
      {
        'id': 'message_marathon',
        'name': 'Message Marathon',
        'description': 'Send 2500 messages',
        'category': 'Social',
        'condition': 'send_messages_2500',
        'target_value': 2500,
        'reward_coins': 3000,
        'reward_points': 2000,
        'icon': 'campaign',
        'rarity': 'legendary',
      },
      {
        'id': 'daily_chatter',
        'name': 'Daily Chatter',
        'description': 'Send messages for 30 consecutive days',
        'category': 'Social',
        'condition': 'daily_message_streak_30',
        'target_value': 30,
        'reward_coins': 800,
        'reward_points': 600,
        'icon': 'event_repeat',
        'rarity': 'epic',
      },

      // === ADVANCED PROGRESSION ACHIEVEMENTS ===
      {
        'id': 'ultimate_user',
        'name': 'Ultimate User',
        'description': 'Reach level 200',
        'category': 'Progress',
        'condition': 'reach_level_200',
        'target_value': 200,
        'reward_coins': 15000,
        'reward_points': 8000,
        'icon': 'workspace_premium',
        'rarity': 'legendary',
      },
      {
        'id': 'point_emperor',
        'name': 'Point Emperor',
        'description': 'Earn 25000 total points',
        'category': 'Progress',
        'condition': 'earn_points_25000',
        'target_value': 25000,
        'reward_coins': 5000,
        'reward_points': 3000,
        'icon': 'military_tech',
        'rarity': 'legendary',
      },
      {
        'id': 'coin_magnate',
        'name': 'Coin Magnate',
        'description': 'Accumulate 50000 coins (total earned)',
        'category': 'Progress',
        'condition': 'total_coins_earned_50000',
        'target_value': 50000,
        'reward_coins': 8000,
        'reward_points': 4000,
        'icon': 'account_balance',
        'rarity': 'legendary',
      },

      // === PREMIUM COLLECTING ACHIEVEMENTS ===
      {
        'id': 'master_collector',
        'name': 'Master Collector',
        'description': 'Purchase 100 items',
        'category': 'Collecting',
        'condition': 'purchase_items_100',
        'target_value': 100,
        'reward_coins': 3000,
        'reward_points': 2000,
        'icon': 'inventory_2',
        'rarity': 'legendary',
      },
      {
        'id': 'aura_master',
        'name': 'Aura Master',
        'description': 'Collect 15 different auras',
        'category': 'Collecting',
        'condition': 'collect_category_aura_15',
        'target_value': 15,
        'reward_coins': 1200,
        'reward_points': 800,
        'icon': 'auto_awesome_motion',
        'rarity': 'epic',
      },
      {
        'id': 'decoration_designer',
        'name': 'Decoration Designer',
        'description': 'Collect 20 different decorations',
        'category': 'Collecting',
        'condition': 'collect_category_decoration_20',
        'target_value': 20,
        'reward_coins': 1500,
        'reward_points': 1000,
        'icon': 'architecture',
        'rarity': 'epic',
      },
      {
        'id': 'complete_collection',
        'name': 'Complete Collection',
        'description': 'Own at least 5 items from every category',
        'category': 'Collecting',
        'condition': 'complete_category_collection',
        'target_value': 1,
        'reward_coins': 5000,
        'reward_points': 3000,
        'icon': 'check_circle',
        'rarity': 'legendary',
      },

      // === ELITE GAMING ACHIEVEMENTS ===
      {
        'id': 'content_king',
        'name': 'Content King',
        'description': 'Post 100 pieces of content',
        'category': 'Gaming',
        'condition': 'post_content_100',
        'target_value': 100,
        'reward_coins': 2500,
        'reward_points': 1500,
        'icon': 'crown',
        'rarity': 'legendary',
      },
      {
        'id': 'viral_sensation',
        'name': 'Viral Sensation',
        'description': 'Get 500 total likes on your posts',
        'category': 'Gaming',
        'condition': 'receive_likes_500',
        'target_value': 500,
        'reward_coins': 2000,
        'reward_points': 1200,
        'icon': 'trending_up',
        'rarity': 'epic',
      },
      {
        'id': 'tarot_master',
        'name': 'Tarot Master',
        'description': 'Complete 100 tarot readings',
        'category': 'Gaming',
        'condition': 'tarot_readings_100',
        'target_value': 100,
        'reward_coins': 1800,
        'reward_points': 1200,
        'icon': 'auto_fix_high',
        'rarity': 'epic',
      },
      {
        'id': 'gem_lord',
        'name': 'Gem Lord',
        'description': 'Discover 25 different gems',
        'category': 'Gaming',
        'condition': 'discover_gems_25',
        'target_value': 25,
        'reward_coins': 2200,
        'reward_points': 1500,
        'icon': 'diamond',
        'rarity': 'epic',
      },
      {
        'id': 'butterfly_monarch',
        'name': 'Butterfly Monarch',
        'description': 'Catch 20 different butterflies',
        'category': 'Gaming',
        'condition': 'catch_butterflies_20',
        'target_value': 20,
        'reward_coins': 1600,
        'reward_points': 1000,
        'icon': 'flutter_dash',
        'rarity': 'epic',
      },

      // === PREMIUM SPENDING ACHIEVEMENTS ===
      {
        'id': 'whale_spender',
        'name': 'Whale Spender',
        'description': 'Spend 25000 coins in the shop',
        'category': 'Progress',
        'condition': 'spend_coins_25000',
        'target_value': 25000,
        'reward_coins': 3000,
        'reward_points': 2000,
        'icon': 'account_balance_wallet',
        'rarity': 'legendary',
      },
      {
        'id': 'luxury_shopper',
        'name': 'Luxury Shopper',
        'description': 'Purchase 10 items worth 500+ coins each',
        'category': 'Collecting',
        'condition': 'purchase_expensive_items_10',
        'target_value': 10,
        'reward_coins': 1500,
        'reward_points': 1000,
        'icon': 'diamond',
        'rarity': 'rare',
      },

      // === CONSISTENCY ACHIEVEMENTS ===
      {
        'id': 'loyal_user',
        'name': 'Loyal User',
        'description': 'Login for 100 consecutive days',
        'category': 'Special',
        'condition': 'login_streak_100',
        'target_value': 100,
        'reward_coins': 5000,
        'reward_points': 3000,
        'icon': 'stars',
        'rarity': 'legendary',
      },
      {
        'id': 'weekly_warrior',
        'name': 'Weekly Warrior',
        'description': 'Complete 25 weekly challenges',
        'category': 'Special',
        'condition': 'weekly_challenges_25',
        'target_value': 25,
        'reward_coins': 2000,
        'reward_points': 1500,
        'icon': 'emoji_events',
        'rarity': 'epic',
      },
      {
        'id': 'quest_master',
        'name': 'Quest Master',
        'description': 'Complete 100 quests',
        'category': 'Special',
        'condition': 'complete_quests_100',
        'target_value': 100,
        'reward_coins': 3000,
        'reward_points': 2000,
        'icon': 'assignment_turned_in',
        'rarity': 'epic',
      },

      // === ACTIVITY MASTERY ACHIEVEMENTS ===
      {
        'id': 'spin_champion',
        'name': 'Spin Champion',
        'description': 'Use daily spin wheel 100 times',
        'category': 'Gaming',
        'condition': 'daily_spin_100',
        'target_value': 100,
        'reward_coins': 1500,
        'reward_points': 1000,
        'icon': 'casino',
        'rarity': 'rare',
      },
      {
        'id': 'home_designer',
        'name': 'Home Designer',
        'description': 'Place 50 decorations in your home',
        'category': 'Gaming',
        'condition': 'home_decorations_50',
        'target_value': 50,
        'reward_coins': 1800,
        'reward_points': 1200,
        'icon': 'home_work',
        'rarity': 'epic',
      },
      {
        'id': 'engagement_expert',
        'name': 'Engagement Expert',
        'description': 'Like 1000 posts from other users',
        'category': 'Social',
        'condition': 'give_likes_1000',
        'target_value': 1000,
        'reward_coins': 1000,
        'reward_points': 800,
        'icon': 'thumb_up',
        'rarity': 'rare',
      },

      // === SEASONAL/TIME-BASED ACHIEVEMENTS ===
      {
        'id': 'night_owl',
        'name': 'Night Owl',
        'description': 'Send 100 messages between 10PM-6AM',
        'category': 'Special',
        'condition': 'night_messages_100',
        'target_value': 100,
        'reward_coins': 600,
        'reward_points': 400,
        'icon': 'bedtime',
        'rarity': 'uncommon',
      },
      {
        'id': 'early_bird',
        'name': 'Early Bird',
        'description': 'Send 100 messages between 5AM-9AM',
        'category': 'Special',
        'condition': 'morning_messages_100',
        'target_value': 100,
        'reward_coins': 600,
        'reward_points': 400,
        'icon': 'wb_sunny',
        'rarity': 'uncommon',
      },
      {
        'id': 'weekend_warrior',
        'name': 'Weekend Warrior',
        'description': 'Be active for 20 consecutive weekends',
        'category': 'Special',
        'condition': 'weekend_activity_20',
        'target_value': 20,
        'reward_coins': 1200,
        'reward_points': 800,
        'icon': 'weekend',
        'rarity': 'rare',
      },

      // === COMMUNITY ACHIEVEMENTS ===
      {
        'id': 'helper',
        'name': 'Helper',
        'description': 'Help 50 new users (mentor program)',
        'category': 'Social',
        'condition': 'help_users_50',
        'target_value': 50,
        'reward_coins': 2000,
        'reward_points': 1500,
        'icon': 'support_agent',
        'rarity': 'epic',
      },
      {
        'id': 'group_creator',
        'name': 'Group Creator',
        'description': 'Create 5 groups',
        'category': 'Social',
        'condition': 'create_groups_5',
        'target_value': 5,
        'reward_coins': 800,
        'reward_points': 600,
        'icon': 'group_add',
        'rarity': 'rare',
      },
      {
        'id': 'influencer',
        'name': 'Influencer',
        'description': 'Have 100 followers',
        'category': 'Social',
        'condition': 'followers_100',
        'target_value': 100,
        'reward_coins': 1500,
        'reward_points': 1000,
        'icon': 'star',
        'rarity': 'epic',
      },

      // === EXPLORATION ACHIEVEMENTS ===
      {
        'id': 'explorer',
        'name': 'Explorer',
        'description': 'Visit all areas of the app at least 10 times each',
        'category': 'Gaming',
        'condition': 'explore_all_areas',
        'target_value': 1,
        'reward_coins': 1000,
        'reward_points': 800,
        'icon': 'explore',
        'rarity': 'rare',
      },
      {
        'id': 'feature_finder',
        'name': 'Feature Finder',
        'description': 'Use 20 different app features',
        'category': 'Gaming',
        'condition': 'use_features_20',
        'target_value': 20,
        'reward_coins': 800,
        'reward_points': 600,
        'icon': 'psychology',
        'rarity': 'uncommon',
      },

      // === MILESTONE CELEBRATIONS ===
      {
        'id': 'first_week',
        'name': 'First Week',
        'description': 'Complete your first week in the app',
        'category': 'Special',
        'condition': 'active_days_7',
        'target_value': 7,
        'reward_coins': 200,
        'reward_points': 150,
        'icon': 'celebration',
        'rarity': 'common',
      },
      {
        'id': 'first_month',
        'name': 'First Month',
        'description': 'Complete your first month in the app',
        'category': 'Special',
        'condition': 'active_days_30',
        'target_value': 30,
        'reward_coins': 800,
        'reward_points': 600,
        'icon': 'cake',
        'rarity': 'uncommon',
      },
      {
        'id': 'anniversary',
        'name': 'Anniversary',
        'description': 'Celebrate your first year in the app',
        'category': 'Special',
        'condition': 'active_days_365',
        'target_value': 365,
        'reward_coins': 10000,
        'reward_points': 5000,
        'icon': 'anniversary',
        'rarity': 'legendary',
      },
    ];

    // Insert achievements into database (only if they don't exist)
    for (final achievement in achievements) {
      try {
        await supabase.from('achievements').upsert(achievement);
      } catch (e) {
        print('Error inserting achievement ${achievement['id']}: $e');
      }
    }
  }
}
