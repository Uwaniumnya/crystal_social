import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import 'profile_production_config.dart';

class StatsDashboardScreen extends StatefulWidget {
  final SupabaseClient supabaseClient;

  const StatsDashboardScreen({super.key, required this.supabaseClient});

  @override
  State<StatsDashboardScreen> createState() => _StatsDashboardScreenState();
}

class _StatsDashboardScreenState extends State<StatsDashboardScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isLoading = false;
  String _selectedTimeFrame = 'All Time';
  bool _showDetailedView = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Centralized method for updating stats
  Future<void> updateUserStats(
      String userId, Map<String, dynamic> updatedStats) async {
    try {
      await Supabase.instance.client.from('user_activity_stats').upsert({
        'user_id': userId,
        ...updatedStats,
      });
    } catch (e) {
      ProfileDebugUtils.logError('updateUserStats', e);
    }
  }

  // Helper function to count emojis in the message content
  int _countEmojis(String content) {
    final emojiRegExp =
        RegExp(r'(\p{Emoji_Presentation}|\p{Emoji})', unicode: true);
    return emojiRegExp.allMatches(content).length;
  }

  // Get user stats from Supabase
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      final response = await widget.supabaseClient
          .from('user_activity_stats')
          .select()
          .eq('user_id', userId)
          .single();

      return response;
    } catch (e) {
      ProfileDebugUtils.logError('fetchUserStats', e);
      // Return default stats if user doesn't exist yet
      return {
        'total_messages_sent': 0,
        'messages_sent_per_day': 0,
        'active_chat_hours': '0 hours',
        'messages_with_emojis': 0,
        'messages_with_reactions': 0,
        'messages_replied_to': 0,
        'longest_streak': 0,
        'average_response_time': '0 seconds',
        'most_used_emojis': 'None',
        'most_common_word_or_phrase': 'None',
        'most_frequent_conversations': 'None',
        'total_stickers_sent': 0,
        'total_images_sent': 0,
        'total_voice_messages': 0,
        'most_active_day_of_week': 'None',
      };
    }
  }

  // Get aggregated stats for different time periods
  Future<Map<String, dynamic>> getAggregatedStats(String userId, String timeFrame) async {
    try {
      String dateFilter = '';
      DateTime now = DateTime.now();
      
      switch (timeFrame) {
        case 'Today':
          dateFilter = "timestamp >= '${DateTime(now.year, now.month, now.day).toUtc().toIso8601String()}'";
          break;
        case 'This Week':
          DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          dateFilter = "timestamp >= '${DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day).toUtc().toIso8601String()}'";
          break;
        case 'This Month':
          dateFilter = "timestamp >= '${DateTime(now.year, now.month, 1).toUtc().toIso8601String()}'";
          break;
        default:
          // All Time - no filter needed
          break;
      }

      // Get message stats
      final messageQuery = widget.supabaseClient
          .from('messages')
          .select('count(), emoji_count.sum()')
          .eq('sender_id', userId);
      
      if (dateFilter.isNotEmpty) {
        messageQuery.filter('timestamp', 'gte', dateFilter);
      }

      final messageStats = await messageQuery.single();
      
      // Get reaction stats
      final reactionQuery = widget.supabaseClient
          .from('reactions')
          .select('count()')
          .eq('user_id', userId);
      
      if (dateFilter.isNotEmpty) {
        reactionQuery.filter('timestamp', 'gte', dateFilter);
      }

      final reactionStats = await reactionQuery.single();

      return {
        'total_messages': messageStats['count'] ?? 0,
        'total_emojis': messageStats['emoji_count'] ?? 0,
        'total_reactions': reactionStats['count'] ?? 0,
      };
    } catch (e) {
      ProfileDebugUtils.logError('fetchAggregatedStats', e);
      return {
        'total_messages': 0,
        'total_emojis': 0,
        'total_reactions': 0,
      };
    }
  }

  // Calculate engagement rate
  double _calculateEngagementRate(Map<String, dynamic> stats) {
    final messagesWithReactions = stats['messages_with_reactions'] ?? 0;
    final totalMessages = stats['total_messages_sent'] ?? 0;
    if (totalMessages == 0) return 0.0;
    return (messagesWithReactions / totalMessages) * 100;
  }

  // Get activity trend data for the past week
  Future<List<Map<String, dynamic>>> getWeeklyActivityTrend(String userId) async {
    try {
      List<Map<String, dynamic>> weekData = [];
      DateTime now = DateTime.now();
      
      for (int i = 6; i >= 0; i--) {
        DateTime date = now.subtract(Duration(days: i));
        String startOfDay = DateTime(date.year, date.month, date.day).toUtc().toIso8601String();
        String endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59).toUtc().toIso8601String();
        
        final response = await widget.supabaseClient
            .from('messages')
            .select('count()')
            .eq('sender_id', userId)
            .gte('timestamp', startOfDay)
            .lte('timestamp', endOfDay)
            .single();
            
        weekData.add({
          'day': ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][date.weekday % 7],
          'messages': response['count'] ?? 0,
        });
      }
      
      return weekData;
    } catch (e) {
      ProfileDebugUtils.logError('fetchWeeklyTrend', e);
      return [];
    }
  }

  // Refresh stats
  Future<void> _refreshStats() async {
    setState(() {
      _isLoading = true;
    });
    
    // Add a small delay for smooth animation
    await Future.delayed(Duration(milliseconds: 500));
    
    setState(() {
      _isLoading = false;
    });
  }

  // Send a message and update stats
  Future<void> sendMessage(String content, String senderId) async {
    try {
      await Supabase.instance.client.from('messages').insert({
        'sender_id': senderId,
        'content': content,
        'emoji_count': _countEmojis(content),
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });

      // Update total messages sent
      await updateUserStats(senderId, {'total_messages_sent': 1});
    } catch (e) {
      ProfileDebugUtils.logError('sendMessage', e);
    }
  }

  // Add a reaction and update stats
  Future<void> addReaction(
      String messageId, String userId, String emoji) async {
    try {
      await Supabase.instance.client.from('reactions').insert({
        'message_id': messageId,
        'user_id': userId,
        'emoji': emoji,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });

      // Increment reaction count in the messages table
      await Supabase.instance.client
          .from('messages')
          .update({'reaction_count': 1})
          .eq('id', messageId);

      // Increment messages_with_reactions in the user_activity_stats table
      await updateUserStats(userId, {'messages_with_reactions': 1});
    } catch (e) {
      ProfileDebugUtils.logError('addReaction', e);
    }
  }

  // Send a sticker and update stats
  Future<void> sendSticker(String stickerUrl, String senderId) async {
    try {
      await Supabase.instance.client.from('stickers').insert({
        'sender_id': senderId,
        'sticker_url': stickerUrl,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });

      // Increment total stickers sent
      await updateUserStats(senderId, {'total_stickers_sent': 1});
    } catch (e) {
      ProfileDebugUtils.logError('sendSticker', e);
    }
  }

  // Send an image and update stats
  Future<void> sendImage(String imageUrl, String senderId) async {
    try {
      await Supabase.instance.client.from('images').insert({
        'sender_id': senderId,
        'image_url': imageUrl,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });

      // Increment total images sent
      await updateUserStats(senderId, {'total_images_sent': 1});
    } catch (e) {
      ProfileDebugUtils.logError('sendImage', e);
    }
  }

  // Send a voice message and update stats
  Future<void> sendVoiceMessage(int duration, String senderId) async {
    try {
      await Supabase.instance.client.from('voice_messages').insert({
        'sender_id': senderId,
        'duration': duration, // duration in seconds
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });

      // Increment total voice messages sent
      await updateUserStats(senderId, {'total_voice_messages': 1});
    } catch (e) {
      ProfileDebugUtils.logError('sendVoiceMessage', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (userId == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('User not logged in.', style: TextStyle(fontSize: 18)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Crystal Stats Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedTimeFrame = value;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'All Time', child: Text('All Time')),
              PopupMenuItem(value: 'Today', child: Text('Today')),
              PopupMenuItem(value: 'This Week', child: Text('This Week')),
              PopupMenuItem(value: 'This Month', child: Text('This Month')),
            ],
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_selectedTimeFrame, style: TextStyle(color: Colors.white)),
                  Icon(Icons.arrow_drop_down, color: Colors.white),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshStats,
          ),
          IconButton(
            icon: Icon(_showDetailedView ? Icons.view_list : Icons.view_module),
            onPressed: () {
              setState(() {
                _showDetailedView = !_showDetailedView;
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.pink),
                  SizedBox(height: 16),
                  Text('Refreshing stats...', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: RefreshIndicator(
                onRefresh: _refreshStats,
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary Card with Engagement Rate
                      _buildEngagementSummaryCard(userId),
                      SizedBox(height: 20),
                      
                      // Activity Trend Chart
                      _buildActivityTrendCard(userId),
                      SizedBox(height: 20),
                      
                      // Time Frame Specific Stats
                      if (_selectedTimeFrame != 'All Time')
                        _buildTimeFrameStatsCard(userId),
                      if (_selectedTimeFrame != 'All Time')
                        SizedBox(height: 20),
                      
                      // Main Stats Grid/List
                      Text(
                        'Detailed Statistics',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 16),
                      _buildMainStatsSection(userId),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildEngagementSummaryCard(String userId) {
    return FutureBuilder<Map<String, dynamic>>(
      future: getUserStats(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Card(
            child: Container(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final stats = snapshot.data!;
        final engagementRate = _calculateEngagementRate(stats);
        final totalMessages = stats['total_messages_sent'] ?? 0;

        return Card(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [Colors.pink.shade400, Colors.purple.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Engagement Overview',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(Icons.trending_up, color: Colors.white),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${engagementRate.toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Engagement Rate',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    Container(height: 40, width: 1, color: Colors.white30),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$totalMessages',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Total Messages',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActivityTrendCard(String userId) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.show_chart, color: Colors.pink),
                SizedBox(width: 8),
                Text(
                  'Weekly Activity Trend',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 16),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: getWeeklyActivityTrend(userId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Container(
                    height: 100,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final weekData = snapshot.data!;
                final maxMessages = weekData.isEmpty ? 1 : weekData.map((e) => e['messages'] as int).reduce(max);

                return Container(
                  height: 100,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: weekData.map((day) {
                      final messages = day['messages'] as int;
                      final height = maxMessages == 0 ? 5.0 : (messages / maxMessages) * 80;
                      
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            width: 24,
                            height: height,
                            decoration: BoxDecoration(
                              color: Colors.pink.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            day['day'],
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeFrameStatsCard(String userId) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.access_time, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  '$_selectedTimeFrame Stats',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 16),
            FutureBuilder<Map<String, dynamic>>(
              future: getAggregatedStats(userId, _selectedTimeFrame),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final stats = snapshot.data!;
                
                return Row(
                  children: [
                    Expanded(
                      child: _buildQuickStat('Messages', stats['total_messages'].toString(), Icons.message, Colors.blue),
                    ),
                    Expanded(
                      child: _buildQuickStat('Emojis', stats['total_emojis'].toString(), Icons.emoji_emotions, Colors.orange),
                    ),
                    Expanded(
                      child: _buildQuickStat('Reactions', stats['total_reactions'].toString(), Icons.thumb_up, Colors.green),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildMainStatsSection(String userId) {
    return FutureBuilder<Map<String, dynamic>>(
      future: getUserStats(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Error loading stats: ${snapshot.error}'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshStats,
                    child: Text('Try Again'),
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return Center(child: Text('No data available.'));
        }

        final stats = snapshot.data!;

        if (_showDetailedView) {
          return _buildDetailedStatsGrid(stats);
        } else {
          return _buildCompactStatsList(stats);
        }
      },
    );
  }

  Widget _buildDetailedStatsGrid(Map<String, dynamic> stats) {
    final statItems = [
      {'title': 'Total Messages Sent', 'value': (stats['total_messages_sent'] ?? 0).toString(), 'icon': Icons.message, 'color': Colors.pink},
      {'title': 'Messages per Day', 'value': (stats['messages_sent_per_day'] ?? 0).toString(), 'icon': Icons.today, 'color': Colors.purple},
      {'title': 'Active Chat Hours', 'value': stats['active_chat_hours']?.toString() ?? '0 hours', 'icon': Icons.access_time, 'color': Colors.green},
      {'title': 'Messages with Emojis', 'value': (stats['messages_with_emojis'] ?? 0).toString(), 'icon': Icons.emoji_emotions, 'color': Colors.orange},
      {'title': 'Messages with Reactions', 'value': (stats['messages_with_reactions'] ?? 0).toString(), 'icon': Icons.thumb_up, 'color': Colors.blue},
      {'title': 'Messages Replied To', 'value': (stats['messages_replied_to'] ?? 0).toString(), 'icon': Icons.reply, 'color': Colors.red},
      {'title': 'Longest Streak', 'value': (stats['longest_streak'] ?? 0).toString() + ' days', 'icon': Icons.local_fire_department, 'color': Colors.deepOrange},
      {'title': 'Average Response Time', 'value': stats['average_response_time']?.toString() ?? '0 seconds', 'icon': Icons.speed, 'color': Colors.teal},
      {'title': 'Total Stickers Sent', 'value': (stats['total_stickers_sent'] ?? 0).toString(), 'icon': Icons.face, 'color': Colors.lightBlue},
      {'title': 'Total Images Sent', 'value': (stats['total_images_sent'] ?? 0).toString(), 'icon': Icons.image, 'color': Colors.deepOrange},
      {'title': 'Voice Messages', 'value': (stats['total_voice_messages'] ?? 0).toString(), 'icon': Icons.mic, 'color': Colors.cyan},
      {'title': 'Most Active Day', 'value': stats['most_active_day_of_week']?.toString() ?? 'None', 'icon': Icons.calendar_today, 'color': Colors.greenAccent},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: statItems.length,
      itemBuilder: (context, index) {
        final item = statItems[index];
        return _buildEnhancedStatCard(
          item['title'] as String,
          item['value'] as String,
          item['icon'] as IconData,
          item['color'] as Color,
        );
      },
    );
  }

  Widget _buildCompactStatsList(Map<String, dynamic> stats) {
    return Column(
      children: [
        _buildStatCard('Total Messages Sent', (stats['total_messages_sent'] ?? 0).toString(), Colors.pink),
        _buildStatCard('Messages Sent per Day', (stats['messages_sent_per_day'] ?? 0).toString(), Colors.purple),
        _buildStatCard('Active Chat Hours', stats['active_chat_hours']?.toString() ?? '0 hours', Colors.green),
        _buildStatCard('Messages with Emojis', (stats['messages_with_emojis'] ?? 0).toString(), Colors.orange),
        _buildStatCard('Messages with Reactions', (stats['messages_with_reactions'] ?? 0).toString(), Colors.blue),
        _buildStatCard('Messages Replied To', (stats['messages_replied_to'] ?? 0).toString(), Colors.red),
        _buildStatCard('Longest Streak of Consecutive Days Active', (stats['longest_streak'] ?? 0).toString(), Colors.yellow),
        _buildStatCard('Average Response Time', stats['average_response_time']?.toString() ?? '0 seconds', Colors.teal),
        _buildStatCard('Most Used Emojis', stats['most_used_emojis']?.toString() ?? 'None', Colors.indigo),
        _buildStatCard('Most Common Word or Phrase', stats['most_common_word_or_phrase']?.toString() ?? 'None', Colors.brown),
        _buildStatCard('Most Frequent Conversations', stats['most_frequent_conversations']?.toString() ?? 'None', Colors.purpleAccent),
        _buildStatCard('Total Stickers Sent', (stats['total_stickers_sent'] ?? 0).toString(), Colors.lightBlue),
        _buildStatCard('Total Images Sent', (stats['total_images_sent'] ?? 0).toString(), Colors.deepOrange),
        _buildStatCard('Total Voice Messages Recorded', (stats['total_voice_messages'] ?? 0).toString(), Colors.cyan),
        _buildStatCard('Most Active Day of the Week', stats['most_active_day_of_week']?.toString() ?? 'None', Colors.greenAccent),
      ],
    );
  }

  Widget _buildEnhancedStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      color: color.withValues(alpha: 0.1),
      margin: EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Text(value, style: TextStyle(fontSize: 16)),
        contentPadding: EdgeInsets.all(16),
      ),
    );
  }
}
