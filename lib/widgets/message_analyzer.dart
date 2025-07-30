import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import '../gems/gemstone_model.dart';

// Enhanced Gemstone service with caching and analytics
class EnhancedGemstoneService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Map<String, Gemstone> _gemCache = {};
  final Map<String, bool> _userGemCache = {};

  // Clear cache when needed
  void clearCache() {
    _gemCache.clear();
    _userGemCache.clear();
  }

  Future<Gemstone?> getGemByName(String name) async {
    // Check cache first
    if (_gemCache.containsKey(name)) {
      return _gemCache[name];
    }

    try {
      final response = await _supabase
          .from('gemstones')
          .select()
          .eq('name', name)
          .maybeSingle();

      if (response == null) return null;
      
      final gem = Gemstone.fromMap(response);
      _gemCache[name] = gem; // Cache the result
      return gem;
    } catch (e) {
      // Log error in production-safe way
      debugPrint('Error fetching gem $name: $e');
      return null;
    }
  }

  Future<bool> userHasGem(String userId, String gemId) async {
    final cacheKey = '${userId}_$gemId';
    
    // Check cache first
    if (_userGemCache.containsKey(cacheKey)) {
      return _userGemCache[cacheKey]!;
    }

    try {
      final response = await _supabase
          .from('user_gemstones')
          .select('gem_id')
          .eq('user_id', userId)
          .eq('gem_id', gemId)
          .maybeSingle();

      final hasGem = response != null;
      _userGemCache[cacheKey] = hasGem; // Cache the result
      return hasGem;
    } catch (e) {
      // Log error in production-safe way
      debugPrint('Error checking user gem $gemId for user $userId: $e');
      return false;
    }
  }

  Future<void> unlockGem(String userId, Gemstone gem, Map<String, dynamic> unlockContext) async {
    try {
      await _supabase.from('user_gemstones').insert({
        'user_id': userId,
        'gem_id': gem.id,
        'unlocked_at': DateTime.now().toIso8601String(),
        'unlock_context': unlockContext, // Store context for analytics
      });
      
      // Update cache
      final cacheKey = '${userId}_${gem.id}';
      _userGemCache[cacheKey] = true;
      
      // Log analytics
      await _logGemUnlock(userId, gem, unlockContext);
      
      // Log success in production-safe way
      debugPrint('Successfully unlocked ${gem.name} for user $userId');
    } catch (e) {
      debugPrint('Error unlocking gem ${gem.name} for user $userId: $e');
      rethrow;
    }
  }

  Future<void> _logGemUnlock(String userId, Gemstone gem, Map<String, dynamic> context) async {
    try {
      await _supabase.from('gem_unlock_analytics').insert({
        'user_id': userId,
        'gem_id': gem.id,
        'gem_name': gem.name,
        'trigger_type': context['trigger_type'],
        'message_content': context['message_snippet'],
        'unlock_timestamp': DateTime.now().toIso8601String(),
        'analysis_metadata': context,
      });
    } catch (e) {
      debugPrint('Error logging gem unlock analytics: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getUserGemStats(String userId) async {
    try {
      final response = await _supabase
          .from('user_gemstones')
          .select('gem_id, unlocked_at, unlock_context')
          .eq('user_id', userId)
          .order('unlocked_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching user gem stats: $e');
      return [];
    }
  }
}

// Enhanced Message Analysis with ML-like features
class EnhancedMessageAnalyzer {
  final BuildContext context;
  final EnhancedGemstoneService _gemService = EnhancedGemstoneService();
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Analytics tracking
  final Map<String, int> _triggerCounts = {};
  final List<String> _recentMessages = [];
  static const int _maxRecentMessages = 50;

  EnhancedMessageAnalyzer(this.context);

  Future<void> analyze(String message, DateTime timestamp) async {
    try {
      if (message.trim().isEmpty) return;
      
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Store recent message for context analysis
      _recentMessages.add(message);
      if (_recentMessages.length > _maxRecentMessages) {
        _recentMessages.removeAt(0);
      }

      final analysisResult = _performDeepAnalysis(message, timestamp);
      await _processAnalysisResults(user.id, message, analysisResult);
    } catch (e) {
      debugPrint('Error during message analysis: $e');
      // Continue execution without throwing - analysis is not critical for app functionality
    }
  }

  Map<String, dynamic> _performDeepAnalysis(String message, DateTime timestamp) {
    final lowerMsg = message.toLowerCase().trim();
    final analysis = <String, dynamic>{
      'triggers': <String>[],
      'sentiment': _analyzeSentiment(message),
      'complexity': _analyzeComplexity(message),
      'time_context': _analyzeTimeContext(timestamp),
      'emoji_analysis': _analyzeEmojis(message),
      'linguistic_features': _analyzeLinguisticFeatures(message),
      'conversation_context': _analyzeConversationContext(),
    };

    // Enhanced trigger detection with scoring
    _detectSupportiveTriggers(lowerMsg, analysis);
    _detectEmotionalTriggers(lowerMsg, analysis);
    _detectCreativeTriggers(lowerMsg, analysis);
    _detectTimeTriggers(timestamp, lowerMsg, analysis);
    _detectSocialTriggers(lowerMsg, analysis);
    _detectAdvancedPatterns(lowerMsg, message, analysis);

    return analysis;
  }

  void _detectSupportiveTriggers(String lowerMsg, Map<String, dynamic> analysis) {
    final supportivePatterns = {
      'encouragement': [
        'you got this', 'i believe in you', 'i\'m proud of you', 'you\'re amazing',
        'keep going', 'don\'t give up', 'you\'re strong', 'you can do it'
      ],
      'love_expression': ['💖', '💗', '💕', '💓', '❤️', '🥰', '😍'],
      'comfort': [
        'sending hugs', 'here for you', 'it\'ll be okay', 'virtual hug',
        'you\'re not alone', 'i understand', 'that sounds tough'
      ],
      'celebration': ['congratulations', 'congrats', 'well done', 'amazing job'],
    };

    for (final category in supportivePatterns.keys) {
      if (_containsAny(lowerMsg, supportivePatterns[category]!)) {
        analysis['triggers'].add('supportive_$category');
        _addGemTrigger(analysis, 'Amethyst', 'supportive', category);
        _addGemTrigger(analysis, 'Rose Quartz', 'love', category);
      }
    }
  }

  void _detectEmotionalTriggers(String lowerMsg, Map<String, dynamic> analysis) {
    final emotionalPatterns = {
      'drama': [
        'drama', 'omg', 'what did they say', 'spill the tea', 'that\'s wild',
        'no way', 'seriously?', 'can you believe', 'plot twist'
      ],
      'calm': [
        'let\'s not fight', 'stay calm', 'we can talk', 'deep breath',
        'peaceful', 'serenity', 'meditation', 'zen'
      ],
      'excitement': [
        'woohoo', 'yay', 'awesome', 'amazing', 'fantastic', 'incredible',
        'mind-blowing', 'epic', 'legendary'
      ],
      'sadness': [
        'feeling sad', 'depressed', 'down', 'blue', 'melancholy',
        'heartbroken', 'disappointed'
      ],
    };

    for (final category in emotionalPatterns.keys) {
      if (_containsAny(lowerMsg, emotionalPatterns[category]!)) {
        analysis['triggers'].add('emotional_$category');
        
        switch (category) {
          case 'drama':
            _addGemTrigger(analysis, 'Ruby', 'drama', 'high_energy');
            _addGemTrigger(analysis, 'Obsidian', 'intensity', 'emotional_depth');
            break;
          case 'calm':
            _addGemTrigger(analysis, 'Pearl', 'peace', 'harmony');
            _addGemTrigger(analysis, 'Aquamarine', 'calm', 'tranquility');
            break;
          case 'excitement':
            _addGemTrigger(analysis, 'Diamond', 'celebration', 'joy');
            _addGemTrigger(analysis, 'Citrine', 'positivity', 'energy');
            break;
          case 'sadness':
            _addGemTrigger(analysis, 'Labradorite', 'introspection', 'depth');
            break;
        }
      }
    }
  }

  void _detectCreativeTriggers(String lowerMsg, Map<String, dynamic> analysis) {
    // Enhanced creativity detection
    final creativityScore = _calculateCreativityScore(lowerMsg);
    if (creativityScore > 0.6) {
      analysis['triggers'].add('creative_expression');
      _addGemTrigger(analysis, 'Emerald', 'creativity', 'artistic_expression');
    }

    // Wordplay and puns
    if (_hasPunOrWittyPattern(lowerMsg)) {
      analysis['triggers'].add('wordplay');
      _addGemTrigger(analysis, 'Emerald', 'wit', 'linguistic_creativity');
    }

    // Poetry detection
    if (_isPoeticContent(lowerMsg)) {
      analysis['triggers'].add('poetic');
      _addGemTrigger(analysis, 'Moonstone', 'poetry', 'artistic_beauty');
    }
  }

  void _detectTimeTriggers(DateTime timestamp, String lowerMsg, Map<String, dynamic> analysis) {
    final hour = timestamp.hour;
    
    // Night owl (midnight to 4 AM)
    if (hour >= 0 && hour <= 4) {
      analysis['triggers'].add('night_owl');
      _addGemTrigger(analysis, 'Sapphire', 'night_activity', 'late_hours');
      
      if (_containsAny(lowerMsg, ['dream', 'moon', 'stars', 'sleep', 'insomnia'])) {
        _addGemTrigger(analysis, 'Moonstone', 'nocturnal', 'dream_state');
      }
    }
    
    // Early bird (5 AM to 9 AM)
    if (hour >= 5 && hour <= 9) {
      if (_containsAny(lowerMsg, ['good morning', 'rise and shine', '☀️', 'morning coffee'])) {
        analysis['triggers'].add('early_bird');
        _addGemTrigger(analysis, 'Sunstone', 'morning_energy', 'new_beginnings');
      }
    }
    
    // Golden hour (6 PM to 8 PM)
    if (hour >= 18 && hour <= 20) {
      if (_containsAny(lowerMsg, ['sunset', 'golden hour', 'beautiful evening'])) {
        analysis['triggers'].add('golden_hour');
        _addGemTrigger(analysis, 'Amber', 'twilight', 'golden_beauty');
      }
    }
  }

  void _detectSocialTriggers(String lowerMsg, Map<String, dynamic> analysis) {
    // Loneliness detection
    if (_containsAny(lowerMsg, [
      'is anyone here?', 'where did everyone go?', 'feeling lonely',
      'so quiet', 'empty chat', 'anyone online?', 'anyone awake?'
    ])) {
      analysis['triggers'].add('loneliness');
      _addGemTrigger(analysis, 'Frost Garnet', 'solitude', 'seeking_connection');
    }

    // Community building
    if (_containsAny(lowerMsg, [
      'let\'s all', 'everyone should', 'group activity', 'together we',
      'community', 'friendship', 'we should hangout'
    ])) {
      analysis['triggers'].add('community_building');
      _addGemTrigger(analysis, 'Amethyst', 'unity', 'social_harmony');
    }

    // Wisdom sharing
    if (_containsAny(lowerMsg, [
      'i learned', 'did you know', 'fun fact', 'pro tip',
      'in my experience', 'wisdom', 'knowledge'
    ])) {
      analysis['triggers'].add('wisdom_sharing');
      _addGemTrigger(analysis, 'Sapphire', 'wisdom', 'knowledge_sharing');
    }
  }

  void _detectAdvancedPatterns(String lowerMsg, String originalMsg, Map<String, dynamic> analysis) {
    // Emoji mastery
    final emojiCount = _emojiCount(originalMsg);
    if (emojiCount >= 6) {
      analysis['triggers'].add('emoji_wizard');
      _addGemTrigger(analysis, 'Topaz', 'expression', 'emoji_mastery');
    }

    // Long-form content
    if (originalMsg.length >= 300) {
      analysis['triggers'].add('long_form');
      _addGemTrigger(analysis, 'Citrine', 'elaboration', 'detailed_expression');
    }

    // Mystical language
    if (_containsAny(lowerMsg, [
      'portal', 'shimmer', 'stardust', 'floating', 'liminal', 'mystic',
      'ethereal', 'transcendent', 'cosmic', 'astral', 'celestial'
    ])) {
      analysis['triggers'].add('mystical');
      _addGemTrigger(analysis, 'Labradorite', 'mysticism', 'otherworldly');
    }

    // Philosophical content
    if (_containsAny(lowerMsg, [
      'i wonder', 'what if', 'have you ever thought', 'philosophy',
      'meaning of life', 'deep thoughts', 'existential', 'consciousness'
    ])) {
      analysis['triggers'].add('philosophical');
      _addGemTrigger(analysis, 'Sapphire', 'philosophy', 'deep_thinking');
    }

    // Technical/Geeky content
    if (_containsAny(lowerMsg, [
      'algorithm', 'data structure', 'programming', 'code', 'debug',
      'api', 'database', 'server', 'blockchain', 'ai', 'machine learning'
    ])) {
      analysis['triggers'].add('technical');
      _addGemTrigger(analysis, 'Quartz', 'technology', 'technical_knowledge');
    }
  }

  void _addGemTrigger(Map<String, dynamic> analysis, String gemName, String triggerType, String context) {
    if (!analysis.containsKey('gem_triggers')) {
      analysis['gem_triggers'] = <Map<String, dynamic>>[];
    }
    
    analysis['gem_triggers'].add({
      'gem': gemName,
      'trigger_type': triggerType,
      'context': context,
      'confidence': _calculateConfidence(triggerType, context),
    });
  }

  double _calculateConfidence(String triggerType, String context) {
    // Simple confidence calculation based on trigger type and context
    const baseConfidence = 0.7;
    const contextBonus = 0.2;
    final random = Random().nextDouble() * 0.1; // Small randomness
    
    return (baseConfidence + contextBonus + random).clamp(0.0, 1.0);
  }

  Future<void> _processAnalysisResults(String userId, String message, Map<String, dynamic> analysis) async {
    if (!analysis.containsKey('gem_triggers')) return;

    final gemTriggers = analysis['gem_triggers'] as List<Map<String, dynamic>>;
    
    for (final trigger in gemTriggers) {
      final gemName = trigger['gem'] as String;
      await _tryUnlockGem(userId, gemName, message, trigger, analysis);
    }
  }

  Future<void> _tryUnlockGem(
    String userId, 
    String gemName, 
    String message,
    Map<String, dynamic> trigger,
    Map<String, dynamic> fullAnalysis
  ) async {
    try {
      final gem = await _gemService.getGemByName(gemName);
      if (gem != null) {
        final hasGem = await _gemService.userHasGem(userId, gem.id);
        if (!hasGem) {
          final unlockContext = {
            'trigger_type': trigger['trigger_type'],
            'context': trigger['context'],
            'confidence': trigger['confidence'],
            'message_snippet': message.length > 100 ? message.substring(0, 100) : message,
            'full_analysis': fullAnalysis,
            'timestamp': DateTime.now().toIso8601String(),
          };

          await _gemService.unlockGem(userId, gem, unlockContext);
          
          if (context.mounted) {
            _showEnhancedUnlockPopup(gem, trigger);
          }
          
          // Track successful unlock
          _triggerCounts[gemName] = (_triggerCounts[gemName] ?? 0) + 1;
        }
      }
    } catch (e) {
      debugPrint('Error unlocking gem $gemName: $e');
    }
  }

  void _showEnhancedUnlockPopup(Gemstone gem, Map<String, dynamic> trigger) {
    showDialog(
      context: context,
      builder: (_) => EnhancedGemUnlockPopup(
        gem: gem,
        triggerType: trigger['trigger_type'],
        context: trigger['context'],
        confidence: trigger['confidence'],
      ),
    );
  }

  // Analysis helper methods
  Map<String, dynamic> _analyzeSentiment(String message) {
    final positive = ['happy', 'joy', 'love', 'amazing', 'wonderful', 'great', '😊', '😍', '❤️'];
    final negative = ['sad', 'angry', 'hate', 'terrible', 'awful', 'worst', '😢', '😠', '💔'];
    
    final lowerMsg = message.toLowerCase();
    final positiveScore = positive.where((word) => lowerMsg.contains(word)).length;
    final negativeScore = negative.where((word) => lowerMsg.contains(word)).length;
    
    return {
      'positive_score': positiveScore,
      'negative_score': negativeScore,
      'overall': positiveScore > negativeScore ? 'positive' : 
                 negativeScore > positiveScore ? 'negative' : 'neutral',
    };
  }

  Map<String, dynamic> _analyzeComplexity(String message) {
    if (message.trim().isEmpty) {
      return {
        'word_count': 0,
        'avg_word_length': 0.0,
        'sentence_count': 0,
        'complexity_score': 0.0,
      };
    }
    
    final words = message.trim().split(' ').where((w) => w.trim().isNotEmpty).toList();
    final avgWordLength = words.isEmpty ? 0.0 : words.map((w) => w.length).reduce((a, b) => a + b) / words.length;
    final sentenceCount = message.split(RegExp(r'[.!?]')).where((s) => s.trim().isNotEmpty).length;
    
    return {
      'word_count': words.length,
      'avg_word_length': avgWordLength,
      'sentence_count': sentenceCount,
      'complexity_score': words.isEmpty ? 0.0 : (words.length * 0.3 + avgWordLength * 0.4 + sentenceCount * 0.3) / 10,
    };
  }

  Map<String, dynamic> _analyzeTimeContext(DateTime timestamp) {
    final hour = timestamp.hour;
    String timeCategory;
    
    if (hour >= 6 && hour < 12) timeCategory = 'morning';
    else if (hour >= 12 && hour < 17) timeCategory = 'afternoon';
    else if (hour >= 17 && hour < 21) timeCategory = 'evening';
    else timeCategory = 'night';
    
    return {
      'hour': hour,
      'category': timeCategory,
      'is_weekend': timestamp.weekday >= 6,
      'day_of_week': timestamp.weekday,
    };
  }

  Map<String, dynamic> _analyzeEmojis(String message) {
    final emojiRegex = RegExp(
      r'(\u00a9|\u00ae|[\u2000-\u3300]|\ud83c[\ud000-\udfff]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff])',
      unicode: true,
    );
    
    final matches = emojiRegex.allMatches(message);
    final emojis = matches.map((m) => m.group(0)!).toList();
    
    return {
      'count': emojis.length,
      'unique_emojis': emojis.toSet().toList(),
      'emoji_density': message.isEmpty ? 0 : emojis.length / message.length,
    };
  }

  Map<String, dynamic> _analyzeLinguisticFeatures(String message) {
    final questions = message.split('?').length - 1;
    final exclamations = message.split('!').length - 1;
    final capsWords = RegExp(r'\b[A-Z]{2,}\b').allMatches(message).length;
    
    return {
      'question_count': questions,
      'exclamation_count': exclamations,
      'caps_words': capsWords,
      'has_repetition': _hasRepetition(message),
      'alliteration_score': _calculateAlliteration(message),
    };
  }

  Map<String, dynamic> _analyzeConversationContext() {
    if (_recentMessages.length < 2) return {'context': 'insufficient_data'};
    
    final recentCount = _recentMessages.length;
    final avgLength = _recentMessages.map((m) => m.length).reduce((a, b) => a + b) / recentCount;
    
    return {
      'recent_message_count': recentCount,
      'avg_recent_length': avgLength,
      'conversation_flow': recentCount > 10 ? 'active' : 'moderate',
    };
  }

  double _calculateCreativityScore(String message) {
    if (message.trim().isEmpty) return 0.0;
    
    double score = 0.0;
    
    // Unique word usage
    final words = message.toLowerCase().trim().split(' ').where((w) => w.trim().isNotEmpty).toList();
    if (words.isEmpty) return 0.0;
    
    final uniqueWords = words.toSet().length;
    score += (uniqueWords / words.length) * 0.3;
    
    // Metaphorical language
    final metaphors = ['like', 'as if', 'reminds me of', 'similar to'];
    if (metaphors.any((m) => message.toLowerCase().contains(m))) score += 0.2;
    
    // Creative punctuation
    if (message.contains('...') || message.contains('~')) score += 0.1;
    
    // Mixed case creativity
    if (RegExp(r'[a-z][A-Z]').hasMatch(message)) score += 0.1;
    
    return score.clamp(0.0, 1.0);
  }

  bool _isPoeticContent(String message) {
    final poeticIndicators = [
      'verse', 'rhyme', 'stanza', 'poem', 'poetry',
      'haiku', 'sonnet', 'ballad', 'ode'
    ];
    
    final lowerMsg = message.toLowerCase();
    if (poeticIndicators.any((indicator) => lowerMsg.contains(indicator))) {
      return true;
    }
    
    // Simple rhyme detection
    final lines = message.split('\n');
    if (lines.length >= 2) {
      for (int i = 0; i < lines.length - 1; i++) {
        if (_linesRhyme(lines[i], lines[i + 1])) {
          return true;
        }
      }
    }
    
    return false;
  }

  bool _linesRhyme(String line1, String line2) {
    final words1 = line1.trim().split(' ').where((w) => w.isNotEmpty).toList();
    final words2 = line2.trim().split(' ').where((w) => w.isNotEmpty).toList();
    
    if (words1.isEmpty || words2.isEmpty) return false;
    
    final lastWord1 = words1.last.toLowerCase().replaceAll(RegExp(r'[^\w]'), '');
    final lastWord2 = words2.last.toLowerCase().replaceAll(RegExp(r'[^\w]'), '');
    
    // Ensure we have valid words to compare
    if (lastWord1.isEmpty || lastWord2.isEmpty) return false;
    
    if (lastWord1.length > 2 && lastWord2.length > 2) {
      final suffix1 = lastWord1.length >= 2 ? lastWord1.substring(lastWord1.length - 2) : lastWord1;
      final suffix2 = lastWord2.length >= 2 ? lastWord2.substring(lastWord2.length - 2) : lastWord2;
      
      return lastWord1.endsWith(suffix2) || lastWord2.endsWith(suffix1);
    }
    
    return false;
  }

  bool _hasRepetition(String message) {
    final words = message.toLowerCase().split(' ');
    final wordCounts = <String, int>{};
    
    for (final word in words) {
      if (word.length > 2) {
        wordCounts[word] = (wordCounts[word] ?? 0) + 1;
      }
    }
    
    return wordCounts.values.any((count) => count > 1);
  }

  double _calculateAlliteration(String message) {
    final words = message.toLowerCase().split(' ');
    if (words.length < 2) return 0.0;
    
    int alliterationCount = 0;
    for (int i = 0; i < words.length - 1; i++) {
      if (words[i].isNotEmpty && words[i + 1].isNotEmpty) {
        if (words[i][0] == words[i + 1][0]) {
          alliterationCount++;
        }
      }
    }
    
    return alliterationCount / (words.length - 1);
  }

  bool _containsAny(String msg, List<String> triggers) {
    return triggers.any((t) => msg.contains(t));
  }

  bool _hasPunOrWittyPattern(String msg) {
    if (msg.trim().isEmpty) return false;
    
    final punIndicators = [
      'pun', 'wordplay', 'that was clever', 'nice one',
      'i see what you did there', 'haha', 'lol', 'witty', 'funny'
    ];
    
    if (punIndicators.any((indicator) => msg.contains(indicator))) {
      return true;
    }
    
    final words = msg.split(' ').where((w) => w.trim().isNotEmpty).toList();
    if (words.length < 2) return false;
    
    for (int i = 0; i < words.length - 1; i++) {
      final word1 = words[i].replaceAll(RegExp(r'[^\w]'), '');
      final word2 = words[i + 1].replaceAll(RegExp(r'[^\w]'), '');
      
      if (word1.length > 2 && word2.length > 2) {
        final suffix1 = word1.length >= 2 ? word1.substring(word1.length - 2) : word1;
        final suffix2 = word2.length >= 2 ? word2.substring(word2.length - 2) : word2;
        
        if (word1.endsWith(suffix2) || word2.endsWith(suffix1)) {
          return true;
        }
      }
    }
    
    return false;
  }

  int _emojiCount(String text) {
    final emojiRegex = RegExp(
      r'(\u00a9|\u00ae|[\u2000-\u3300]|\ud83c[\ud000-\udfff]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff])',
      unicode: true,
    );
    return emojiRegex.allMatches(text).length;
  }

  // Analytics and reporting
  Map<String, dynamic> getAnalyticsReport() {
    return {
      'trigger_counts': Map.from(_triggerCounts),
      'recent_message_count': _recentMessages.length,
      'analysis_session_start': DateTime.now().toIso8601String(),
    };
  }

  void resetAnalytics() {
    _triggerCounts.clear();
    _recentMessages.clear();
    _gemService.clearCache();
  }
}

// Enhanced Gem Unlock Popup with more details
class EnhancedGemUnlockPopup extends StatelessWidget {
  final Gemstone gem;
  final String triggerType;
  final String context;
  final double confidence;

  const EnhancedGemUnlockPopup({
    super.key,
    required this.gem,
    required this.triggerType,
    required this.context,
    required this.confidence,
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
            // Gem icon with glow effect
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.8),
                    blurRadius: 20,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Icon(
                Icons.diamond,
                size: 60,
                color: _getGemColor(gem.name),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Unlock title
            Text(
              '✨ Gemstone Unlocked! ✨',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.purple.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            // Gem name
            Text(
              gem.name,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: _getGemColor(gem.name),
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            // Trigger context
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Unlocked through: ${_formatTriggerType(triggerType)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Confidence indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.psychology, color: Colors.purple.shade600, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Confidence: ${(confidence * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.purple.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Close button
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade400,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Amazing!'),
            ),
          ],
        ),
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
