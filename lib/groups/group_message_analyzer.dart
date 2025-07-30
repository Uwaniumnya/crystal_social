// File: group_message_analyzer.dart
// Enhanced message analyzer specifically optimized for group conversations

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/message_analyzer.dart';
import '../gems/gemstone_model.dart';
import 'groups_production_config.dart';
import 'dart:math';

/// Group-specific message analyzer with enhanced group dynamics detection
class GroupMessageAnalyzer extends ChangeNotifier {
  final String groupId;
  final String currentUserId;
  final BuildContext context;
  
  late final EnhancedMessageAnalyzer _baseAnalyzer;
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Group-specific tracking
  final Map<String, int> _memberMessageCounts = {};
  final Map<String, DateTime> _memberLastSeen = {};
  final Map<String, List<String>> _memberInteractionHistory = {};
  final Map<String, int> _groupTriggerCounts = {};
  
  // Conversation analytics
  final List<Map<String, dynamic>> _conversationFlow = [];
  final Map<String, dynamic> _groupDynamics = {};
  
  // Group-specific gem triggers
  static const Map<String, List<String>> _groupSpecificTriggers = {
    'community_building': [
      'let\'s all', 'everyone should', 'group activity', 'together we',
      'team effort', 'collaboration', 'unite', 'join forces'
    ],
    'leadership': [
      'i suggest', 'we should', 'let me organize', 'i\'ll coordinate',
      'follow my lead', 'let\'s plan', 'organizing', 'leadership'
    ],
    'mediator': [
      'let\'s all calm down', 'both sides', 'peaceful solution',
      'compromise', 'middle ground', 'mediation', 'resolve this'
    ],
    'group_celebrations': [
      'congrats everyone', 'we did it', 'group achievement',
      'collective win', 'team success', 'group milestone'
    ],
    'inclusive_language': [
      'everyone is welcome', 'all are invited', 'no one left out',
      'inclusive', 'diversity', 'belonging', 'acceptance'
    ],
  };

  GroupMessageAnalyzer({
    required this.groupId,
    required this.currentUserId,
    required this.context,
  }) {
    _baseAnalyzer = EnhancedMessageAnalyzer(context);
    _initializeGroupAnalytics();
  }

  /// Initialize group-specific analytics
  Future<void> _initializeGroupAnalytics() async {
    try {
      await _loadGroupHistory();
      await _loadMemberStats();
    } catch (e) {
      debugPrint('Error initializing group analytics: $e');
    }
  }

  /// Load recent group conversation history for context
  Future<void> _loadGroupHistory() async {
    try {
      final response = await _supabase
          .from('messages')
          .select('sender_id, text, timestamp, reactions')
          .eq('chat_id', groupId)
          .order('timestamp', ascending: false)
          .limit(50);

      for (final message in response) {
        _conversationFlow.add({
          'sender_id': message['sender_id'],
          'text': message['text'] ?? '',
          'timestamp': DateTime.parse(message['timestamp']),
          'reactions': message['reactions'] ?? {},
        });
      }

      _analyzeGroupDynamics();
    } catch (e) {
      debugPrint('Error loading group history: $e');
    }
  }

  /// Load member statistics and activity
  Future<void> _loadMemberStats() async {
    try {
      // Get member message counts
      final response = await _supabase
          .from('messages')
          .select('sender_id')
          .eq('chat_id', groupId);

      for (final message in response) {
        final senderId = message['sender_id'] as String;
        _memberMessageCounts[senderId] = (_memberMessageCounts[senderId] ?? 0) + 1;
      }

      // Get last seen data
      final members = await _supabase
          .from('chats')
          .select('members')
          .eq('id', groupId)
          .single();

      final memberIds = List<String>.from(members['members'] ?? []);
      
      final userResponse = await _supabase
          .from('users')
          .select('id, last_seen_at')
          .inFilter('id', memberIds);

      for (final user in userResponse) {
        if (user['last_seen_at'] != null) {
          _memberLastSeen[user['id']] = DateTime.parse(user['last_seen_at']);
        }
      }
    } catch (e) {
      debugPrint('Error loading member stats: $e');
    }
  }

  /// Analyze group dynamics and conversation patterns
  void _analyzeGroupDynamics() {
    if (_conversationFlow.isEmpty) return;

    // Analyze conversation velocity
    final recentMessages = _conversationFlow.take(20).toList();
    final averageTimeBetweenMessages = _calculateAverageTimeBetween(recentMessages);
    
    // Analyze member participation
    final participationRates = _calculateParticipationRates();
    
    // Analyze reaction patterns
    final reactionPatterns = _analyzeReactionPatterns();
    
    // Detect conversation themes
    final themes = _detectConversationThemes();

    _groupDynamics.addAll({
      'velocity': averageTimeBetweenMessages,
      'participation': participationRates,
      'reactions': reactionPatterns,
      'themes': themes,
      'activity_level': _calculateActivityLevel(),
      'engagement_score': _calculateEngagementScore(),
    });
  }

  /// Analyze a message with group-specific context
  Future<void> analyzeGroupMessage(
    String message,
    String senderId,
    DateTime timestamp,
    Map<String, dynamic>? reactions,
  ) async {
    try {
      // Run base analysis
      await _baseAnalyzer.analyze(message, timestamp);

      // Add group-specific analysis
      final groupAnalysis = await _performGroupSpecificAnalysis(
        message,
        senderId,
        timestamp,
        reactions,
      );

      // Process group-specific triggers
      await _processGroupTriggers(senderId, message, groupAnalysis);

      // Update member tracking
      _updateMemberTracking(senderId, message, timestamp);

      // Update conversation flow
      _updateConversationFlow(senderId, message, timestamp, reactions);

      notifyListeners();
    } catch (e) {
      debugPrint('Error in group message analysis: $e');
    }
  }

  /// Perform group-specific analysis
  Future<Map<String, dynamic>> _performGroupSpecificAnalysis(
    String message,
    String senderId,
    DateTime timestamp,
    Map<String, dynamic>? reactions,
  ) async {
    final lowerMsg = message.toLowerCase().trim();
    final analysis = <String, dynamic>{
      'group_triggers': <String>[],
      'social_dynamics': {},
      'member_interaction': {},
      'conversation_context': {},
    };

    // Detect group-specific patterns
    _detectGroupSpecificTriggers(lowerMsg, analysis);
    _analyzeSocialDynamics(senderId, message, analysis);
    _analyzeMemberInteractions(senderId, message, analysis);
    _analyzeConversationContext(message, timestamp, analysis);

    return analysis;
  }

  /// Detect group-specific triggers
  void _detectGroupSpecificTriggers(String lowerMsg, Map<String, dynamic> analysis) {
    for (final category in _groupSpecificTriggers.keys) {
      final triggers = _groupSpecificTriggers[category]!;
      if (triggers.any((trigger) => lowerMsg.contains(trigger))) {
        analysis['group_triggers'].add(category);
        _addGroupGemTrigger(analysis, category, lowerMsg);
      }
    }

    // Detect group milestone celebrations
    if (_isGroupMilestone(lowerMsg)) {
      analysis['group_triggers'].add('milestone_celebration');
      _addGroupGemTrigger(analysis, 'milestone_celebration', lowerMsg);
    }

    // Detect group support patterns
    if (_isGroupSupport(lowerMsg)) {
      analysis['group_triggers'].add('group_support');
      _addGroupGemTrigger(analysis, 'group_support', lowerMsg);
    }

    // Detect conversation starters
    if (_isConversationStarter(lowerMsg)) {
      analysis['group_triggers'].add('conversation_starter');
      _addGroupGemTrigger(analysis, 'conversation_starter', lowerMsg);
    }
  }

  /// Add group-specific gem triggers
  void _addGroupGemTrigger(Map<String, dynamic> analysis, String category, String message) {
    if (!analysis.containsKey('gem_triggers')) {
      analysis['gem_triggers'] = <Map<String, dynamic>>[];
    }

    String gemName;
    String triggerType;
    String context;

    switch (category) {
      case 'community_building':
        gemName = 'Amethyst';
        triggerType = 'group_unity';
        context = 'building_community';
        break;
      case 'leadership':
        gemName = 'Diamond';
        triggerType = 'leadership';
        context = 'taking_charge';
        break;
      case 'mediator':
        gemName = 'Pearl';
        triggerType = 'mediation';
        context = 'conflict_resolution';
        break;
      case 'group_celebrations':
        gemName = 'Citrine';
        triggerType = 'celebration';
        context = 'group_achievement';
        break;
      case 'inclusive_language':
        gemName = 'Rose Quartz';
        triggerType = 'inclusion';
        context = 'welcoming_others';
        break;
      case 'milestone_celebration':
        gemName = 'Topaz';
        triggerType = 'milestone';
        context = 'group_milestone';
        break;
      case 'group_support':
        gemName = 'Emerald';
        triggerType = 'support';
        context = 'helping_others';
        break;
      case 'conversation_starter':
        gemName = 'Sapphire';
        triggerType = 'engagement';
        context = 'starting_conversations';
        break;
      default:
        return;
    }

    analysis['gem_triggers'].add({
      'gem': gemName,
      'trigger_type': triggerType,
      'context': context,
      'confidence': _calculateGroupConfidence(category, message),
      'group_context': true,
    });
  }

  /// Calculate confidence for group-specific triggers
  double _calculateGroupConfidence(String category, String message) {
    double baseConfidence = 0.8;
    
    // Boost confidence based on group context
    if (_memberMessageCounts[currentUserId] != null) {
      final userActivity = _memberMessageCounts[currentUserId]! / 
                          (_memberMessageCounts.values.reduce((a, b) => a + b) / _memberMessageCounts.length);
      baseConfidence += (userActivity * 0.1).clamp(0.0, 0.2);
    }

    // Add random factor
    final random = Random().nextDouble() * 0.1;
    return (baseConfidence + random).clamp(0.0, 1.0);
  }

  /// Analyze social dynamics in the message
  void _analyzeSocialDynamics(String senderId, String message, Map<String, dynamic> analysis) {
    final dynamics = <String, dynamic>{};

    // Check if this user is dominating the conversation
    final userMessageRatio = (_memberMessageCounts[senderId] ?? 0) / 
                            _conversationFlow.length.clamp(1, double.infinity);
    
    if (userMessageRatio > 0.5) {
      dynamics['conversation_dominance'] = 'high';
    } else if (userMessageRatio > 0.3) {
      dynamics['conversation_dominance'] = 'moderate';
    } else {
      dynamics['conversation_dominance'] = 'balanced';
    }

    // Check for mentions (engaging others)
    final mentions = RegExp(r'@(\w+)').allMatches(message);
    if (mentions.isNotEmpty) {
      dynamics['engaging_others'] = true;
      dynamics['mention_count'] = mentions.length;
    }

    // Check for questions (encouraging participation)
    final questionCount = message.split('?').length - 1;
    if (questionCount > 0) {
      dynamics['encouraging_participation'] = true;
      dynamics['question_count'] = questionCount;
    }

    analysis['social_dynamics'] = dynamics;
  }

  /// Analyze member interactions
  void _analyzeMemberInteractions(String senderId, String message, Map<String, dynamic> analysis) {
    final interactions = <String, dynamic>{};

    // Track interaction history
    if (!_memberInteractionHistory.containsKey(senderId)) {
      _memberInteractionHistory[senderId] = [];
    }

    // Add this message to history
    _memberInteractionHistory[senderId]!.add(message);
    
    // Keep only recent interactions
    if (_memberInteractionHistory[senderId]!.length > 20) {
      _memberInteractionHistory[senderId]!.removeAt(0);
    }

    // Analyze conversation patterns
    final recentMessages = _memberInteractionHistory[senderId]!;
    if (recentMessages.length >= 3) {
      interactions['conversation_thread'] = _analyzeConversationThread(recentMessages);
    }

    // Check for direct responses
    if (_isDirectResponse(message)) {
      interactions['direct_response'] = true;
    }

    analysis['member_interaction'] = interactions;
  }

  /// Analyze conversation context
  void _analyzeConversationContext(String message, DateTime timestamp, Map<String, dynamic> analysis) {
    final context = <String, dynamic>{};

    // Time context within group
    final hoursSinceLastMessage = _getHoursSinceLastGroupMessage();
    if (hoursSinceLastMessage > 12) {
      context['conversation_revival'] = true;
    }

    // Check if this continues a topic
    if (_continuesCurrentTopic(message)) {
      context['topic_continuation'] = true;
    }

    // Check if this starts a new topic
    if (_startsNewTopic(message)) {
      context['topic_starter'] = true;
    }

    analysis['conversation_context'] = context;
  }

  /// Process group-specific gem triggers
  Future<void> _processGroupTriggers(
    String senderId,
    String message,
    Map<String, dynamic> analysis,
  ) async {
    if (!analysis.containsKey('gem_triggers')) return;

    final gemTriggers = analysis['gem_triggers'] as List<Map<String, dynamic>>;
    
    for (final trigger in gemTriggers) {
      final isGroupContext = trigger['group_context'] == true;
      if (isGroupContext) {
        await _tryUnlockGroupGem(senderId, trigger, message, analysis);
      }
    }
  }

  /// Try to unlock a group-specific gem
  Future<void> _tryUnlockGroupGem(
    String userId,
    Map<String, dynamic> trigger,
    String message,
    Map<String, dynamic> fullAnalysis,
  ) async {
    try {
      final gemName = trigger['gem'] as String;
      final gemService = EnhancedGemstoneService();
      
      final gem = await gemService.getGemByName(gemName);
      if (gem != null) {
        final hasGem = await gemService.userHasGem(userId, gem.id);
        if (!hasGem) {
          final unlockContext = {
            'trigger_type': trigger['trigger_type'],
            'context': trigger['context'],
            'confidence': trigger['confidence'],
            'group_id': groupId,
            'group_context': true,
            'message_snippet': message.length > 100 ? message.substring(0, 100) : message,
            'group_dynamics': _groupDynamics,
            'timestamp': DateTime.now().toIso8601String(),
          };

          await gemService.unlockGem(userId, gem, unlockContext);
          
          // Track group-specific unlock
          _groupTriggerCounts[gemName] = (_groupTriggerCounts[gemName] ?? 0) + 1;
          
          if (context.mounted && userId == currentUserId) {
            _showGroupGemUnlockPopup(gem, trigger);
          }
        }
      }
    } catch (e) {
      debugPrint('Error unlocking group gem: $e');
    }
  }

  /// Show group-specific gem unlock popup
  void _showGroupGemUnlockPopup(Gemstone gem, Map<String, dynamic> trigger) {
    showDialog(
      context: context,
      builder: (_) => GroupGemUnlockPopup(
        gem: gem,
        triggerType: trigger['trigger_type'],
        context: trigger['context'],
        confidence: trigger['confidence'],
        groupId: groupId,
      ),
    );
  }

  /// Update member tracking
  void _updateMemberTracking(String senderId, String message, DateTime timestamp) {
    _memberMessageCounts[senderId] = (_memberMessageCounts[senderId] ?? 0) + 1;
    _memberLastSeen[senderId] = timestamp;
  }

  /// Update conversation flow
  void _updateConversationFlow(
    String senderId,
    String message,
    DateTime timestamp,
    Map<String, dynamic>? reactions,
  ) {
    _conversationFlow.insert(0, {
      'sender_id': senderId,
      'text': message,
      'timestamp': timestamp,
      'reactions': reactions ?? {},
    });

    // Keep only recent messages
    if (_conversationFlow.length > 100) {
      _conversationFlow.removeLast();
    }

    // Re-analyze dynamics periodically
    if (_conversationFlow.length % 10 == 0) {
      _analyzeGroupDynamics();
    }
  }

  // Helper methods for analysis
  double _calculateAverageTimeBetween(List<Map<String, dynamic>> messages) {
    if (messages.length < 2) return 0.0;
    
    double totalMinutes = 0;
    for (int i = 0; i < messages.length - 1; i++) {
      final current = messages[i]['timestamp'] as DateTime;
      final next = messages[i + 1]['timestamp'] as DateTime;
      totalMinutes += current.difference(next).inMinutes.abs();
    }
    
    return totalMinutes / (messages.length - 1);
  }

  Map<String, double> _calculateParticipationRates() {
    final total = _memberMessageCounts.values.fold(0, (sum, count) => sum + count);
    if (total == 0) return {};
    
    return _memberMessageCounts.map((userId, count) => 
        MapEntry(userId, count / total));
  }

  Map<String, dynamic> _analyzeReactionPatterns() {
    final allReactions = <String, int>{};
    for (final message in _conversationFlow) {
      final reactions = message['reactions'] as Map<String, dynamic>? ?? {};
      for (final emoji in reactions.keys) {
        final count = (reactions[emoji] as List?)?.length ?? 0;
        allReactions[emoji] = (allReactions[emoji] ?? 0) + count;
      }
    }
    
    return {
      'most_used': allReactions.entries
          .fold<MapEntry<String, int>?>(null, (prev, curr) => 
              prev == null || curr.value > prev.value ? curr : prev)
          ?.key,
      'total_reactions': allReactions.values.fold(0, (sum, count) => sum + count),
      'reaction_diversity': allReactions.length,
    };
  }

  List<String> _detectConversationThemes() {
    final themes = <String>[];
    final allText = _conversationFlow
        .map((m) => m['text'] as String? ?? '')
        .join(' ')
        .toLowerCase();

    final themeKeywords = {
      'gaming': ['game', 'play', 'gaming', 'stream', 'esports'],
      'work': ['work', 'job', 'office', 'meeting', 'project'],
      'relationships': ['love', 'relationship', 'dating', 'partner'],
      'food': ['food', 'cooking', 'recipe', 'restaurant', 'eat'],
      'entertainment': ['movie', 'show', 'music', 'concert', 'netflix'],
      'technology': ['tech', 'computer', 'app', 'software', 'coding'],
    };

    for (final theme in themeKeywords.keys) {
      final keywords = themeKeywords[theme]!;
      if (keywords.any((keyword) => allText.contains(keyword))) {
        themes.add(theme);
      }
    }

    return themes;
  }

  String _calculateActivityLevel() {
    if (_conversationFlow.length < 10) return 'low';
    
    final recentMessages = _conversationFlow.take(20).toList();
    final averageTime = _calculateAverageTimeBetween(recentMessages);
    
    if (averageTime < 5) return 'very_high';
    if (averageTime < 15) return 'high';
    if (averageTime < 60) return 'moderate';
    return 'low';
  }

  double _calculateEngagementScore() {
    if (_conversationFlow.isEmpty) return 0.0;
    
    double score = 0.0;
    final recentMessages = _conversationFlow.take(20).toList();
    
    for (final message in recentMessages) {
      final reactions = message['reactions'] as Map<String, dynamic>? ?? {};
      final reactionCount = reactions.values
          .fold<int>(0, (sum, list) => sum + ((list as List?)?.length ?? 0));
      
      score += reactionCount * 0.5; // Reactions contribute to engagement
      
      final text = message['text'] as String? ?? '';
      if (text.contains('?')) score += 0.3; // Questions encourage engagement
      if (text.contains('@')) score += 0.2; // Mentions show engagement
    }
    
    return (score / recentMessages.length).clamp(0.0, 10.0);
  }

  double _getHoursSinceLastGroupMessage() {
    if (_conversationFlow.length < 2) return 0.0;
    
    final lastMessage = _conversationFlow[1]['timestamp'] as DateTime;
    return DateTime.now().difference(lastMessage).inHours.toDouble();
  }

  bool _isGroupMilestone(String message) {
    final milestoneKeywords = [
      'milestone', 'achievement', 'anniversary', 'celebration',
      'reached', 'accomplished', 'success', 'victory'
    ];
    return milestoneKeywords.any((keyword) => message.contains(keyword));
  }

  bool _isGroupSupport(String message) {
    final supportKeywords = [
      'here for you', 'support', 'help', 'assistance',
      'we got you', 'backing you', 'solidarity'
    ];
    return supportKeywords.any((keyword) => message.contains(keyword));
  }

  bool _isConversationStarter(String message) {
    final starterPatterns = [
      'hey everyone', 'good morning all', 'anyone else',
      'what do you think about', 'has anyone', 'quick question'
    ];
    return starterPatterns.any((pattern) => message.contains(pattern));
  }

  bool _continuesCurrentTopic(String message) {
    if (_conversationFlow.length < 3) return false;
    
    // Simple topic continuation detection based on shared keywords
    final recentMessages = _conversationFlow.take(3)
        .map((m) => m['text'] as String? ?? '')
        .join(' ')
        .toLowerCase()
        .split(' ');
    
    final currentWords = message.toLowerCase().split(' ');
    final sharedWords = currentWords.where((word) => 
        word.length > 3 && recentMessages.contains(word)).length;
    
    return sharedWords >= 2;
  }

  bool _startsNewTopic(String message) {
    final topicStarters = [
      'by the way', 'speaking of', 'random question',
      'off topic', 'new subject', 'changing topics'
    ];
    return topicStarters.any((starter) => message.toLowerCase().contains(starter));
  }

  bool _isDirectResponse(String message) {
    final responsePatterns = [
      'yes', 'no', 'exactly', 'totally', 'i agree',
      'disagree', 'that\'s right', 'definitely'
    ];
    return responsePatterns.any((pattern) => 
        message.toLowerCase().startsWith(pattern));
  }

  Map<String, dynamic> _analyzeConversationThread(List<String> messages) {
    return {
      'length': messages.length,
      'avg_length': messages.map((m) => m.length).reduce((a, b) => a + b) / messages.length,
      'topic_consistency': _calculateTopicConsistency(messages),
    };
  }

  double _calculateTopicConsistency(List<String> messages) {
    if (messages.length < 2) return 1.0;
    
    final allWords = messages.join(' ').toLowerCase().split(' ');
    final wordCounts = <String, int>{};
    
    for (final word in allWords) {
      if (word.length > 3) {
        wordCounts[word] = (wordCounts[word] ?? 0) + 1;
      }
    }
    
    final repeatedWords = wordCounts.values.where((count) => count > 1).length;
    return repeatedWords / wordCounts.length.clamp(1, double.infinity);
  }

  /// Get group analytics report
  Map<String, dynamic> getGroupAnalyticsReport() {
    return {
      'group_id': groupId,
      'member_message_counts': Map.from(_memberMessageCounts),
      'group_dynamics': Map.from(_groupDynamics),
      'trigger_counts': Map.from(_groupTriggerCounts),
      'conversation_flow_length': _conversationFlow.length,
      'active_members': _memberLastSeen.length,
      'analysis_timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Reset group analytics
  void resetGroupAnalytics() {
    _memberMessageCounts.clear();
    _memberLastSeen.clear();
    _memberInteractionHistory.clear();
    _groupTriggerCounts.clear();
    _conversationFlow.clear();
    _groupDynamics.clear();
  }

  @override
  void dispose() {
    _baseAnalyzer.resetAnalytics();
    super.dispose();
  }
}

/// Group-specific gem unlock popup
class GroupGemUnlockPopup extends StatelessWidget {
  final Gemstone gem;
  final String triggerType;
  final String context;
  final double confidence;
  final String groupId;

  const GroupGemUnlockPopup({
    super.key,
    required this.gem,
    required this.triggerType,
    required this.context,
    required this.confidence,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.purple.shade100,
              Colors.pink.shade100,
              Colors.orange.shade100,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Group gem icon with special effect
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _getGemColor(gem.name).withOpacity(0.3),
                    _getGemColor(gem.name).withOpacity(0.1),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _getGemColor(gem.name).withOpacity(0.5),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.diamond,
                    size: 60,
                    color: _getGemColor(gem.name),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade400,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.group,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Group unlock title
            Text(
              '🌟 Group Gemstone Unlocked! 🌟',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.purple.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            // Gem name with group indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  gem.name,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _getGemColor(gem.name),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Text(
                    'GROUP',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Trigger context with group info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Column(
                children: [
                  Text(
                    'Unlocked for: ${_formatTriggerType(triggerType)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.purple.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your group participation shows great ${this.context.replaceAll('_', ' ')}!',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Confidence and group stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatChip(
                  'Confidence',
                  '${(confidence * 100).round()}%',
                  Colors.green,
                ),
                _buildStatChip(
                  'Group Boost',
                  '+20%',
                  Colors.orange,
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Close button
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.star),
              label: const Text('Awesome!'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade400,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Color _getGemColor(String gemName) {
    const gemColors = {
      'Ruby': Colors.red,
      'Emerald': Colors.green,
      'Sapphire': Colors.blue,
      'Diamond': Colors.grey,
      'Amethyst': Colors.purple,
      'Rose Quartz': Colors.pink,
      'Citrine': Colors.orange,
      'Pearl': Colors.white,
      'Topaz': Colors.amber,
      'Obsidian': Colors.black,
      'Moonstone': Colors.indigo,
      'Sunstone': Colors.yellow,
      'Labradorite': Colors.teal,
      'Frost Garnet': Colors.cyan,
    };
    
    return gemColors[gemName] ?? Colors.purple;
  }

  String _formatTriggerType(String triggerType) {
    return triggerType.replaceAll('_', ' ').split(' ').map((word) {
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }
}


