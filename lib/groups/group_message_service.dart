// File: group_message_service.dart
// Enhanced messaging service for groups with integrated analysis and enhanced bubbles

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/message_bubble.dart';
import 'group_message_analyzer.dart';
import '../services/enhanced_push_notification_integration.dart';
import 'groups_production_config.dart';
import 'dart:async';
import 'dart:io';

/// Enhanced group messaging service with integrated analysis
class GroupMessageService extends ChangeNotifier {
  final String groupId;
  final String currentUserId;
  final BuildContext context;
  
  late final GroupMessageAnalyzer _analyzer;
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Message state
  final List<Map<String, dynamic>> _messages = [];
  final Map<String, Timer> _typingTimers = {};
  final Set<String> _currentlyTyping = {};
  
  // Enhanced features
  bool _smartReactionsEnabled = true;
  bool _autoGemUnlockEnabled = true;
  bool _groupAnalyticsEnabled = true;
  bool _enhancedBubblesEnabled = true;
  
  // Subscription
  StreamSubscription? _messageSubscription;
  StreamSubscription? _typingSubscription;

  GroupMessageService({
    required this.groupId,
    required this.currentUserId,
    required this.context,
  }) {
    _analyzer = GroupMessageAnalyzer(
      groupId: groupId,
      currentUserId: currentUserId,
      context: context,
    );
    _initializeService();
  }

  // Getters
  List<Map<String, dynamic>> get messages => _messages;
  Set<String> get currentlyTyping => _currentlyTyping;
  bool get smartReactionsEnabled => _smartReactionsEnabled;
  bool get autoGemUnlockEnabled => _autoGemUnlockEnabled;
  bool get groupAnalyticsEnabled => _groupAnalyticsEnabled;
  bool get enhancedBubblesEnabled => _enhancedBubblesEnabled;

  /// Initialize the service
  Future<void> _initializeService() async {
    try {
      await _loadExistingMessages();
      await _setupRealtimeSubscriptions();
    } catch (e) {
      GroupsDebugUtils.logError('MessageService', 'Error initializing group message service: $e');
    }
  }

  /// Load existing messages from database
  Future<void> _loadExistingMessages() async {
    try {
      final response = await _supabase
          .from('messages')
          .select('''
            id, sender_id, text, timestamp, reactions, 
            reply_to_id, media_url, media_type, mentions,
            edited_at, deleted_at
          ''')
          .eq('chat_id', groupId)
          .order('timestamp', ascending: true)
          .limit(50);

      _messages.clear();
      for (final messageData in response) {
        _messages.add(_processMessageData(messageData));
      }

      notifyListeners();
    } catch (e) {
      GroupsDebugUtils.logError('MessageService', 'Error loading messages: $e');
    }
  }

  /// Setup realtime subscriptions
  Future<void> _setupRealtimeSubscriptions() async {
    try {
      // Message subscription
      _messageSubscription = _supabase
          .from('messages')
          .stream(primaryKey: ['id'])
          .eq('chat_id', groupId)
          .listen(_handleRealtimeMessage);

      // Typing indicators subscription
      _typingSubscription = _supabase
          .from('typing_indicators')
          .stream(primaryKey: ['id'])
          .eq('chat_id', groupId)
          .listen(_handleTypingIndicator);
    } catch (e) {
      GroupsDebugUtils.logError('MessageService', 'Error setting up subscriptions: $e');
    }
  }

  /// Handle realtime message updates
  void _handleRealtimeMessage(List<Map<String, dynamic>> data) {
    for (final messageData in data) {
      final processedMessage = _processMessageData(messageData);
      
      // Find existing message index
      final existingIndex = _messages.indexWhere(
        (m) => m['id'] == processedMessage['id']
      );

      if (existingIndex != -1) {
        // Update existing message
        _messages[existingIndex] = processedMessage;
      } else {
        // Add new message
        _insertMessageInOrder(processedMessage);
        
        // Analyze new message if it's not from current user
        if (messageData['sender_id'] != currentUserId && _groupAnalyticsEnabled) {
          _analyzeNewMessage(processedMessage);
        }
      }
    }

    notifyListeners();
  }

  /// Handle typing indicators
  void _handleTypingIndicator(List<Map<String, dynamic>> data) {
    _currentlyTyping.clear();
    
    for (final indicator in data) {
      final userId = indicator['user_id'] as String;
      final isTyping = indicator['is_typing'] as bool? ?? false;
      final timestamp = DateTime.parse(indicator['timestamp']);
      
      // Only show recent typing indicators
      if (isTyping && 
          userId != currentUserId && 
          DateTime.now().difference(timestamp).inSeconds < 10) {
        _currentlyTyping.add(userId);
      }
    }

    notifyListeners();
  }

  /// Process raw message data
  Map<String, dynamic> _processMessageData(Map<String, dynamic> data) {
    return {
      'id': data['id'],
      'sender_id': data['sender_id'],
      'text': data['text'] ?? '',
      'timestamp': DateTime.parse(data['timestamp']),
      'reactions': data['reactions'] ?? {},
      'reply_to_id': data['reply_to_id'],
      'media_url': data['media_url'],
      'media_type': data['media_type'],
      'mentions': data['mentions'] ?? [],
      'edited_at': data['edited_at'] != null ? DateTime.parse(data['edited_at']) : null,
      'deleted_at': data['deleted_at'] != null ? DateTime.parse(data['deleted_at']) : null,
      'analysis_data': null, // Will be populated during analysis
      'enhanced_features': _getEnhancedFeatures(data),
    };
  }

  /// Get enhanced features for a message
  Map<String, dynamic> _getEnhancedFeatures(Map<String, dynamic> data) {
    return {
      'gem_triggers': [],
      'sentiment_score': 0.0,
      'creativity_score': 0.0,
      'group_context': {},
      'smart_reactions': [],
      'enhanced_display': _enhancedBubblesEnabled,
    };
  }

  /// Insert message in chronological order
  void _insertMessageInOrder(Map<String, dynamic> message) {
    final timestamp = message['timestamp'] as DateTime;
    
    int insertIndex = _messages.length;
    for (int i = _messages.length - 1; i >= 0; i--) {
      final existingTimestamp = _messages[i]['timestamp'] as DateTime;
      if (timestamp.isAfter(existingTimestamp)) {
        insertIndex = i + 1;
        break;
      }
    }
    
    _messages.insert(insertIndex, message);
  }

  /// Analyze new message
  Future<void> _analyzeNewMessage(Map<String, dynamic> message) async {
    try {
      await _analyzer.analyzeGroupMessage(
        message['text'],
        message['sender_id'],
        message['timestamp'],
        message['reactions'],
      );

      // Update message with analysis results
      final index = _messages.indexWhere((m) => m['id'] == message['id']);
      if (index != -1) {
        _messages[index]['analysis_data'] = _analyzer.getGroupAnalyticsReport();
        notifyListeners();
      }
    } catch (e) {
      GroupsDebugUtils.logError('MessageService', 'Error analyzing message: $e');
    }
  }

  /// Send a text message with enhanced analysis
  Future<bool> sendMessage(String text, {String? replyToId}) async {
    if (text.trim().isEmpty) return false;

    try {
      // Pre-process message
      final processedText = _preprocessMessage(text);
      final mentions = _extractMentions(processedText);
      
      // Send to database
      await _supabase.from('messages').insert({
        'chat_id': groupId,
        'sender_id': currentUserId,
        'text': processedText,
        'timestamp': DateTime.now().toIso8601String(),
        'reply_to_id': replyToId,
        'mentions': mentions,
        'reactions': {},
      });

      // 🔔 SEND GROUP PUSH NOTIFICATIONS
      // Get all group members except the sender
      await _sendGroupNotifications(processedText);

      // Analyze message for current user
      if (_autoGemUnlockEnabled) {
        await _analyzer.analyzeGroupMessage(
          processedText,
          currentUserId,
          DateTime.now(),
          {},
        );
      }

      return true;
    } catch (e) {
      GroupsDebugUtils.logError('MessageService', 'Error sending message: $e');
      return false;
    }
  }

  /// Send media message
  Future<bool> sendMediaMessage(
    File mediaFile,
    String mediaType, {
    String? caption,
    String? replyToId,
  }) async {
    try {
      // Upload media file
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${mediaFile.path.split('/').last}';
      final uploadPath = 'group_media/$groupId/$fileName';
      
      await _supabase.storage
          .from('chat_media')
          .upload(uploadPath, mediaFile);

      final mediaUrl = _supabase.storage
          .from('chat_media')
          .getPublicUrl(uploadPath);

      // Send message with media
      final mentions = caption != null ? _extractMentions(caption) : <String>[];
      
      await _supabase.from('messages').insert({
        'chat_id': groupId,
        'sender_id': currentUserId,
        'text': caption ?? '',
        'media_url': mediaUrl,
        'media_type': mediaType,
        'timestamp': DateTime.now().toIso8601String(),
        'reply_to_id': replyToId,
        'mentions': mentions,
        'reactions': {},
      });

      // 🔔 SEND GROUP PUSH NOTIFICATIONS FOR MEDIA
      final mediaMessage = caption?.isNotEmpty == true 
          ? caption! 
          : 'Sent a ${mediaType.toLowerCase()}';
      await _sendGroupNotifications(mediaMessage);

      return true;
    } catch (e) {
      debugPrint('Error sending media message: $e');
      return false;
    }
  }

  /// Add reaction to message
  Future<void> addReaction(String messageId, String emoji) async {
    try {
      // Get current message
      final messageIndex = _messages.indexWhere((m) => m['id'] == messageId);
      if (messageIndex == -1) return;

      final message = _messages[messageIndex];
      final reactions = Map<String, dynamic>.from(message['reactions'] ?? {});
      
      // Add/update reaction
      if (!reactions.containsKey(emoji)) {
        reactions[emoji] = [];
      }
      
      final userReactions = List<String>.from(reactions[emoji]);
      if (!userReactions.contains(currentUserId)) {
        userReactions.add(currentUserId);
        reactions[emoji] = userReactions;
      }

      // Update in database
      await _supabase
          .from('messages')
          .update({'reactions': reactions})
          .eq('id', messageId);

      // Smart reaction suggestions
      if (_smartReactionsEnabled) {
        _generateSmartReactionSuggestions(message, emoji);
      }
    } catch (e) {
      debugPrint('Error adding reaction: $e');
    }
  }

  /// Remove reaction from message
  Future<void> removeReaction(String messageId, String emoji) async {
    try {
      final messageIndex = _messages.indexWhere((m) => m['id'] == messageId);
      if (messageIndex == -1) return;

      final message = _messages[messageIndex];
      final reactions = Map<String, dynamic>.from(message['reactions'] ?? {});
      
      if (reactions.containsKey(emoji)) {
        final userReactions = List<String>.from(reactions[emoji]);
        userReactions.remove(currentUserId);
        
        if (userReactions.isEmpty) {
          reactions.remove(emoji);
        } else {
          reactions[emoji] = userReactions;
        }

        // Update in database
        await _supabase
            .from('messages')
            .update({'reactions': reactions})
            .eq('id', messageId);
      }
    } catch (e) {
      debugPrint('Error removing reaction: $e');
    }
  }

  /// Edit message
  Future<bool> editMessage(String messageId, String newText) async {
    try {
      final processedText = _preprocessMessage(newText);
      final mentions = _extractMentions(processedText);
      
      await _supabase
          .from('messages')
          .update({
            'text': processedText,
            'mentions': mentions,
            'edited_at': DateTime.now().toIso8601String(),
          })
          .eq('id', messageId)
          .eq('sender_id', currentUserId);

      return true;
    } catch (e) {
      debugPrint('Error editing message: $e');
      return false;
    }
  }

  /// Delete message
  Future<bool> deleteMessage(String messageId) async {
    try {
      await _supabase
          .from('messages')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', messageId)
          .eq('sender_id', currentUserId);

      return true;
    } catch (e) {
      debugPrint('Error deleting message: $e');
      return false;
    }
  }

  /// Update typing indicator
  Future<void> updateTypingIndicator(bool isTyping) async {
    try {
      await _supabase
          .from('typing_indicators')
          .upsert({
            'chat_id': groupId,
            'user_id': currentUserId,
            'is_typing': isTyping,
            'timestamp': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      debugPrint('Error updating typing indicator: $e');
    }
  }

  /// Build enhanced message bubble widget
  Widget buildEnhancedMessageBubble(Map<String, dynamic> message) {
    final enhancedFeatures = message['enhanced_features'] as Map<String, dynamic>? ?? {};
    final isMe = message['sender_id'] == currentUserId;
    
    if (_enhancedBubblesEnabled && enhancedFeatures['enhanced_display'] == true) {
      return MessageBubbleEnhanced(
        messageId: message['id'],
        text: message['text'],
        isMe: isMe,
        timestamp: message['timestamp'],
        reactions: Map<String, List<String>>.from(
          (message['reactions'] ?? {}).map((k, v) => 
              MapEntry(k, List<String>.from(v ?? [])))
        ),
        replyToMessageId: message['reply_to_id'],
        imageUrl: message['media_type'] == 'image' ? message['media_url'] : null,
        videoUrl: message['media_type'] == 'video' ? message['media_url'] : null,
        audioUrl: message['media_type'] == 'audio' ? message['media_url'] : null,
        mentions: List<String>.from(message['mentions'] ?? []),
        isEdited: message['edited_at'] != null,
        auraColor: _getAuraColor(enhancedFeatures),
        
        // Enhanced features in metadata
        metadata: {
          'gem_triggers': List<Map<String, dynamic>>.from(
            enhancedFeatures['gem_triggers'] ?? []
          ),
          'sentiment_score': enhancedFeatures['sentiment_score'] ?? 0.0,
          'creativity_score': enhancedFeatures['creativity_score'] ?? 0.0,
          'group_context': Map<String, dynamic>.from(
            enhancedFeatures['group_context'] ?? {}
          ),
          'smart_reactions': List<String>.from(
            enhancedFeatures['smart_reactions'] ?? []
          ),
          'is_deleted': message['deleted_at'] != null,
        },
        
        // Callbacks
        onReactTap: (emoji) => addReaction(message['id'], emoji),
        onReply: (_) => _handleReply(message['id']),
        onEdit: (_) async => await editMessage(message['id'], message['text']),
        onDelete: (_) async => await deleteMessage(message['id']),
        onCopy: (_) => _copyMessageText(message['text']),
      );
    } else {
      // Fall back to basic enhanced bubble without special features
      return MessageBubbleEnhanced(
        messageId: message['id'],
        text: message['text'],
        isMe: isMe,
        timestamp: message['timestamp'],
        reactions: Map<String, List<String>>.from(
          (message['reactions'] ?? {}).map((k, v) => 
              MapEntry(k, List<String>.from(v ?? [])))
        ),
        replyToMessageId: message['reply_to_id'],
        imageUrl: message['media_type'] == 'image' ? message['media_url'] : null,
        videoUrl: message['media_type'] == 'video' ? message['media_url'] : null,
        audioUrl: message['media_type'] == 'audio' ? message['media_url'] : null,
        mentions: List<String>.from(message['mentions'] ?? []),
        isEdited: message['edited_at'] != null,
        auraColor: 'purple',
        
        // Basic callbacks
        onReactTap: (emoji) => addReaction(message['id'], emoji),
        onReply: (_) => _handleReply(message['id']),
        onEdit: (_) async => await editMessage(message['id'], message['text']),
        onDelete: (_) async => await deleteMessage(message['id']),
        onCopy: (_) => _copyMessageText(message['text']),
      );
    }
  }

  /// Handle reply action
  void _handleReply(String messageId) {
    // Implementation depends on your UI structure
    // This could trigger a callback to the parent widget
    debugPrint('Reply to message: $messageId');
  }

  /// Get aura color based on enhanced features
  String _getAuraColor(Map<String, dynamic> enhancedFeatures) {
    final sentimentScore = enhancedFeatures['sentiment_score'] ?? 0.0;
    final creativityScore = enhancedFeatures['creativity_score'] ?? 0.0;
    final gemTriggers = enhancedFeatures['gem_triggers'] ?? [];
    
    // Color based on gem triggers
    if (gemTriggers.isNotEmpty) {
      final firstTrigger = gemTriggers.first;
      final gemName = firstTrigger['gem'] ?? '';
      
      switch (gemName) {
        case 'Ruby':
          return 'red';
        case 'Emerald':
          return 'green';
        case 'Sapphire':
          return 'blue';
        case 'Diamond':
          return 'white';
        case 'Amethyst':
          return 'purple';
        case 'Rose Quartz':
          return 'pink';
        case 'Citrine':
          return 'orange';
        case 'Topaz':
          return 'yellow';
        default:
          return 'purple';
      }
    }
    
    // Color based on sentiment/creativity
    if (sentimentScore > 0.7) {
      return 'gold';
    } else if (sentimentScore < -0.3) {
      return 'gray';
    } else if (creativityScore > 0.8) {
      return 'rainbow';
    }
    
    return 'purple'; // Default
  }

  /// Copy message text to clipboard
  void _copyMessageText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    // Could show a snackbar here if context is available
  }

  /// Preprocess message text
  String _preprocessMessage(String text) {
    // Remove excessive whitespace
    text = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    
    // Handle special formatting
    // You can add custom preprocessing here
    
    return text;
  }

  /// Extract mentions from message text
  List<String> _extractMentions(String text) {
    final mentions = <String>[];
    final mentionPattern = RegExp(r'@(\w+)');
    final matches = mentionPattern.allMatches(text);
    
    for (final match in matches) {
      final username = match.group(1);
      if (username != null) {
        mentions.add(username);
      }
    }
    
    return mentions;
  }

  /// Generate smart reaction suggestions
  void _generateSmartReactionSuggestions(Map<String, dynamic> message, String addedEmoji) {
    // This could use ML or rule-based suggestions
    final smartReactions = <String>[];
    final text = (message['text'] as String).toLowerCase();
    
    // Basic smart suggestions based on content
    if (text.contains('happy') || text.contains('excited')) {
      smartReactions.addAll(['�E', '🎉', '👏']);
    } else if (text.contains('sad') || text.contains('disappointed')) {
      smartReactions.addAll(['😢', '�E�', '💙']);
    } else if (text.contains('funny') || text.contains('lol')) {
      smartReactions.addAll(['�E', '🤣', '�E']);
    }
    
    // Update message with suggestions
    final messageIndex = _messages.indexWhere((m) => m['id'] == message['id']);
    if (messageIndex != -1) {
      final enhancedFeatures = _messages[messageIndex]['enhanced_features'] as Map<String, dynamic>;
      enhancedFeatures['smart_reactions'] = smartReactions;
      notifyListeners();
    }
  }

  /// Toggle feature settings
  void toggleSmartReactions(bool enabled) {
    _smartReactionsEnabled = enabled;
    notifyListeners();
  }

  void toggleAutoGemUnlock(bool enabled) {
    _autoGemUnlockEnabled = enabled;
    notifyListeners();
  }

  void toggleGroupAnalytics(bool enabled) {
    _groupAnalyticsEnabled = enabled;
    notifyListeners();
  }

  void toggleEnhancedBubbles(bool enabled) {
    _enhancedBubblesEnabled = enabled;
    notifyListeners();
  }

  /// Get group analytics report
  Map<String, dynamic> getGroupAnalyticsReport() {
    return _analyzer.getGroupAnalyticsReport();
  }

  /// Search messages
  List<Map<String, dynamic>> searchMessages(String query) {
    if (query.trim().isEmpty) return _messages;
    
    final lowerQuery = query.toLowerCase();
    return _messages.where((message) {
      final text = (message['text'] as String).toLowerCase();
      return text.contains(lowerQuery);
    }).toList();
  }

  /// Get messages by date range
  List<Map<String, dynamic>> getMessagesByDateRange(DateTime start, DateTime end) {
    return _messages.where((message) {
      final timestamp = message['timestamp'] as DateTime;
      return timestamp.isAfter(start) && timestamp.isBefore(end);
    }).toList();
  }

  /// Clear messages cache
  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  /// Refresh messages
  Future<void> refreshMessages() async {
    await _loadExistingMessages();
  }

  /// Send push notifications to all group members
  Future<void> _sendGroupNotifications(String messageText) async {
    try {
      // Get sender's username
      final senderData = await _supabase
          .from('users')
          .select('username')
          .eq('id', currentUserId)
          .maybeSingle();

      if (senderData == null) return;
      
      final senderUsername = senderData['username'] as String;

      // Get all group members except the sender
      final groupMembersResponse = await _supabase
          .from('group_members')
          .select('user_id')
          .eq('group_id', groupId)
          .neq('user_id', currentUserId);

      final memberIds = groupMembersResponse
          .map((member) => member['user_id'] as String)
          .toList();

      // Send notification to each member
      for (final memberId in memberIds) {
        await EnhancedPushNotificationIntegration.instance.sendMessageNotification(
          receiverUserId: memberId,
          senderUsername: senderUsername,
          messagePreview: messageText.length > 50 
              ? '${messageText.substring(0, 50)}...' 
              : messageText,
        );
      }

      GroupsDebugUtils.logSuccess('MessageService', 'Group notifications sent to ${memberIds.length} members');
    } catch (e) {
      GroupsDebugUtils.logError('MessageService', 'Failed to send group notifications: $e');
    }
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _typingSubscription?.cancel();
    _analyzer.dispose();
    
    // Clear typing timers
    for (final timer in _typingTimers.values) {
      timer.cancel();
    }
    _typingTimers.clear();
    
    super.dispose();
  }
}



